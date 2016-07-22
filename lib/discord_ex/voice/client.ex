defmodule DiscordEx.Voice.Client do
  @moduledoc """
  This client is for specifically working with voice. You can pass this process
  to your regular client if you wish to use it with your bot.

  ## Examples

      token = "<your-token>"
      DiscordEx.Voice.Client.connect(base_client, %{guild_id: 392090239, channel_id: 23208203092390)
      #=> {:ok, #PID<0.180.0>}
  """
  import DiscordEx.Client.Utility

  alias DiscordEx.Voice.Controller
  alias DiscordEx.Voice.UDP

  require Logger

  def opcodes do
    %{
      :identify             => 0,
      :select_protocol      => 1,
      :ready                => 2,
      :heartbeat            => 3,
      :session_description  => 4,
      :speaking             => 5,
    }
  end

  @behaviour :websocket_client

  @doc "Initialize a voice connection"
  @spec connect(pid, map) :: {:ok, pid}
  def connect(base_client, options \\ %{}) do
    task = Task.async fn ->
      send(base_client, {:start_voice_connection_listener, self})
      send(base_client, {:start_voice_connection, options})
      receive do opts -> opts end
    end
    results = Task.await(task, 10_000)
    start_link(results)
  end

  @doc "Kill a voice connection"
  @spec disconnect(pid) :: atom
  def disconnect(voice_client) do
    send(voice_client, :disconnect)
    :ok
  end

  @doc "Reconnect or initiate voice connection"
  @spec reconnect(pid, map) :: {:ok, pid}
  def reconnect(client_pid, options) do
    {:ok, voice_client} = connect(client_pid, options)
    send(client_pid, {:update_state, %{voice_client: voice_client}})
    {:ok, voice_client}
  end

  def start_link(opts) do
    task = Task.async fn ->
      url = socket_url(opts[:endpoint])
      :crypto.start()
      :ssl.start()
      :websocket_client.start_link(url, __MODULE__, opts)
    end
    Task.await(task, 10_000)
  end

  # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
  def init(state) do
    controller = Controller.start(self)
    new_state = Map.merge(state, %{controller: controller})
    {:once, new_state}
  end

  def onconnect(_WSReq, state) do
    identify(state)
    {:ok, state}
  end

  def ondisconnect({:remote, :closed}, _state) do
    # Stub for beter actions later
  end

  def websocket_info(:start, _conn_state, state) do
    {:ok, state}
  end

  @doc "Look into state - grab key value and pass it back to calling process"
  def websocket_info({:get_state, key, pid}, _connection, state) do
    value = if state[key], do: state[key], else: state.data[Atom.to_string(key)]
    send(pid, {key, value})
    {:ok, state}
  end

  @doc "Ability to update state"
  def websocket_info({:update_state, update_values}, _connection, state) do
    {:ok,  Map.merge(state, update_values)}
  end

  @doc "Send all the information over to base client in order to kill this client"
  def websocket_info(:disconnect, _connection, state) do
    # Disconnect form Server
    DiscordEx.Client.voice_state_update(state[:client_pid],
                                            state[:guild_id],
                                            nil,
                                            state[:user_id],
                                            %{self_deaf: true, self_mute: false})

    # Make sure the state for the base client is cleared
    send(state[:client_pid], {:clear_from_state, [:voice,
                                                  :voice_client,
                                                  :start_voice_connection_listener,
                                                  :voice_token,
                                                  :start_voice_connection]})

    # Get rid of any controller process that feels it wants to go rogue
    Process.exit(state[:controller][:buffer], :kill)
    Process.exit(state[:controller][:sequence], :kill)
    Process.exit(state[:controller][:time], :kill)

    # Kill thyself
    Process.exit(self(), "Killing voice client process ...")
    :ok
  end

  @doc "Send all the information over to base client in order to kill this client"
  def websocket_info({:get_controller, calling_pid}, _connection, state) do
    send(calling_pid, state[:controller])
    {:ok, state}
  end

  @doc "Ability to update speaking state"
  def websocket_info({:speaking, value}, _connection, state) do
    data = %{
      "delay" => 0,
      "speaking" => value
    }
    payload = payload_build_json(opcode(opcodes, :speaking), data)
    :websocket_client.cast(self, {:text, payload})
    {:ok, state}
  end

  def websocket_handle({:text, payload}, _socket, state) do
    data  = payload_decode(opcodes, {:text, payload})
    event = data.op
    handle_event({event, data}, state)
  end

  def websocket_terminate(reason, _conn_state, state) do
    Logger.info "Websocket closed in state #{inspect state} wih reason #{inspect reason}"
    if state[:udp_send_socket], do: :gen_udp.close(state[:udp_send_socket])
    if state[:udp_recv_socket], do: :gen_udp.close(state[:udp_recv_socket])
    :ok
  end

  def handle_event({:ready, payload}, state) do
    new_state = Map.merge(state, payload.data)
    _heartbeat_loop(state, payload.data["heartbeat_interval"], self)
    _establish_udp_connect(state, payload)
    {:ok, new_state}
  end

  def handle_event({:session_description, payload}, state) do
    new_state = Map.merge(state, payload)
    {:ok, new_state}
  end

  def handle_event({event, _payload}, state) do
    # Heartbeat and Speaking will destroy logs :)
    unless event == :heartbeat || event == :speaking do
      Logger.info "Voice Connection Received Event: #{event}"
    end
    {:ok, state}
  end

  @spec socket_url(map) :: String.t
  def socket_url(url) do
    full_url = "wss://" <> url
    full_url |> String.replace(":80","") |> String.to_charlist
  end

  def identify(state) do
    data = %{
      "server_id" => state[:guild_id],
      "user_id" => state[:user_id],
      "session_id" => state[:session_id],
      "token" => state[:token]
    }
    payload = payload_build_json(opcode(opcodes, :identify), data)
    :websocket_client.cast(self, {:text, payload})
  end

  # Establish UDP Connection
  defp _establish_udp_connect(state, ready_payload) do
    {my_ip, my_port, discord_ip, discord_port, send_socket} = UDP.self_discovery(state.endpoint, ready_payload.data["port"], ready_payload.data["ssrc"])
    Logger.warn "Make sure you open '#{my_ip}:#{my_port}' in your firewall to receive messages!"

    # Set UDP Sockets on state for reuse
    _update_udp_connection_state(my_port, discord_ip, discord_port, send_socket)

    # Send payload to client on local udp information
    load = %{"protocol" => "udp", "data" => %{"address" => my_ip, "port" => my_port, "mode" => "xsalsa20_poly1305"}}
    payload = payload_build_json(opcode(DiscordEx.Voice.Client.opcodes, :select_protocol), load)
    :websocket_client.cast(self, {:text, payload})
  end

  defp _update_udp_connection_state(my_port, discord_ip, discord_port, send_socket) do
    udp_recv_options = [:binary, active: false, reuseaddr: true]
    {:ok, recv_socket} = :gen_udp.open(my_port, udp_recv_options)
    send(self, {:update_state, %{udp_ip_send: discord_ip,
                                 udp_port_send: discord_port,
                                 udp_socket_send: send_socket,
                                 udp_socket_recv: recv_socket}})
  end

  # Connection Heartbeat
  defp _heartbeat_loop(state, interval, socket_process) do
    spawn_link(fn -> _heartbeat(state, interval, socket_process) end)
    :ok
  end

  defp _heartbeat(state, interval, socket_process) do
    payload = payload_build_json(opcode(opcodes, :heartbeat), nil)
    :websocket_client.cast(socket_process, {:text, payload})
    :timer.sleep(interval)
    _heartbeat_loop(state, interval, socket_process)
  end
end
