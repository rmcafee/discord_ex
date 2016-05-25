defmodule DiscordElixir.Voice.Client do
  @moduledoc """
  This client is for specifically working with voice. You can pass this process
  to your regular client if you wish to use it with your bot.

  ## Examples

      token = "<your-token>"
      DiscordElixir.Voice.Client.connect(base_client, %{guild_id: 392090239, channel_id: 23208203092390)
      #=> {:ok, #PID<0.180.0>}
  """
  import DiscordElixir.Client.Utility

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

  @behaviour :websocket_client_handler

  @doc "Initialize a voice connection"
  @spec connect(pid, map) :: {:ok, pid}
  def connect(base_client, opts) do
    task = Task.async fn ->
      send(base_client, {:start_voice_connection_listener, self})
      send(base_client, {:start_voice_connection, opts})
      receive do opts -> opts end
    end
    response  = Task.await(task, 10000)
    start_link(response)
  end

  def start_link(opts) do
    url = socket_url(opts[:endpoint])
    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(url, __MODULE__, opts)
  end

  # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
  def init(state, _socket) do
    identify(state)
    {:ok, state}
  end

  def websocket_info(:start, _conn_state, state) do
    {:ok, state}
  end

  def websocket_handle({:text, payload}, _socket, state) do
    data  = payload_decode(opcodes, {:text, payload})
    event = data.op
    handle_event({event, data}, state)
  end

  def websocket_terminate(reason, _conn_state, state) do
    Logger.info "Websocket closed in state #{inspect state} wih reason #{inspect reason}"
    #Process.exit(state[:udp_connection], :kill)
    :ok
  end

  def handle_event({:ready, payload}, state) do
    _heartbeat_loop(state, payload.data["heartbeat_interval"], self)
    _establish_udp_connect(state, payload)
    {:ok, state}
  end

  def handle_event({event, _payload}, state) do
  # Just because it will destroy log
    unless event == :heartbeat do
      Logger.info "Voice Connection Received Event: #{event}"
    end
    {:ok, state}
  end

  @spec socket_url(map) :: String.t
  def socket_url(url) do
    full_url = "wss://" <> url
    full_url |> String.replace(":80","")
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
