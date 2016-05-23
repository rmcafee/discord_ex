defmodule DiscordElixir.Client do
  @moduledoc """
  Connect to Discord to recieve and send data in realtime
  You shouldn't be using this directly. You should shold pass it to a handler.

  ## Examples

      token = "<your-token>"
      DiscordElixir.Client.start_link(%{token: token, handler: DiscordElixir.EchoBot})
      #=> {:ok, #PID<0.178.0>}
  """
  require Logger

  import DiscordElixir.Client.Utility

  @behaviour :websocket_client_handler

  def opcodes do
    %{
      :dispatch               => 0,
      :heartbeat              => 1,
      :identify               => 2,
      :status_update          => 3,
      :voice_state_update     => 4,
      :voice_server_ping      => 5,
      :resume                 => 6,
      :reconnect              => 7,
      :request_guild_members  => 8,
      :invalid_session        => 9
    }
  end

  @static_events [:ready]

  # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
  def start_link(opts) do
    # We go ahead and add this to the state early as we use it to get the websocket gateway to start.
    {:ok, rest_client} = DiscordElixir.RestClient.start_link(%{token: opts[:token]})
    opts = Map.put(opts, :rest_client, rest_client)

    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(socket_url(opts), __MODULE__,opts)
  end

  def init(state, _socket) do
    # State sequence management process and set it's state
    {:ok, agent_seq_num} = Agent.start_link fn -> 0 end
    state = Map.put state, :agent_seq_num, agent_seq_num

    # Send identifier to discord gateway
    identify(state)

    # Return state
    {:ok, state}
  end

  def websocket_handle({:binary, payload}, _socket, state) do
    data  = payload_decode(opcodes, {:binary, payload})
    event = normalize_atom(data.event_name)

    # Keeps the sequence tracker process updated
    _update_agent_sequence(data, state)

    # This will setup the voice_client if it is not already setup
    if state[:voice] && state[:voice_client] == nil do
      _setup_voice(event, data, state)
    end

    # Call handler unless it is a static event
    if state[:handler] && !_static_event?(event) do
      state[:handler].handle_event({event, data}, state)
    else
      handle_event({event, data}, state)
    end
  end

  # Behavioural placeholder
  def websocket_info(:start, _connection, state) do
    {:ok, state}
  end

  @doc "Ability to output state information"
  def websocket_info(:inspect_state, _connection, state) do
    IO.inspect state
    {:ok, state}
  end

  @doc "Ability to update state"
  def websocket_info({:update_state, update_values}, _connection, state) do
    {:ok,  Map.merge(state, update_values)}
  end

  @doc "Remove key from state"
  def websocket_info({:clear_from_state, keys}, _connection, state) do
    new_state = Map.drop(state, keys)
    {:ok, new_state}
  end

  def websocket_terminate(reason, _conn_state, state) do
    Logger.info "Websocket closed in state #{inspect state} wih reason #{inspect reason}"
    Logger.info "Killing seq_num process!"
    Process.exit(state[:agent_seq_num], :kill)
    Logger.info "Killing rest_client process!"
    Process.exit(state[:rest_client], :kill)
    :ok
  end

  def handle_event({:ready, payload}, state) do
    _heartbeat_loop(state, payload.data.heartbeat_interval, self)
    new_state = Map.put(state, :session_id, payload.data[:session_id])
    {:ok, new_state}
  end

  def handle_event({event, _payload}, state) do
    Logger.info "Received Event: #{event}"
    {:ok, state}
  end

  def identify(state) do
    data = %{
      "token" => state[:token],
      "properties" => %{
        "$os" => "erlang-vm",
        "$browser" => "discord-elixir",
        "$device" => "discord-elixir",
        "$referrer" => "",
        "$referring_domain" => ""
      },
      "compress" => false,
      "large_threshold" => 250
    }
    payload = payload_build(opcode(opcodes, :identify), data)
    :websocket_client.cast(self, {:binary, payload})
  end

  @spec socket_url(map) :: String.t
  def socket_url(opts) do
    version  = opts[:version] || 4
    url = DiscordElixir.RestClient.resource(opts[:rest_client], :get, "gateway")["url"]
    url = String.replace(url, "gg/", "")
    url = url <> "?v=#{version}&encoding=etf"
    url
  end

  # Spin off a process to make a voice call and handle setup
  # You have to receive 2 event types before starting voice client
  defp _setup_voice(event, data, state) do
    setup_process = unless state[:voice_setup_process] do
                      setup_pid = spawn(DiscordElixir.Voice.Client, :setup, [])
                      send(self, {:update_state, %{voice_setup_process: setup_pid}})
                      _init_voice_call(state)
                      setup_pid
                    else
                      state[:voice_setup_process]
                    end
    valid_event = Enum.find([:voice_server_update, :voice_state_update], fn(e) -> e == event end)
    if valid_event, do: send(setup_process, {self, event, data})
  end

  defp _init_voice_call(state) do
    data = %{ "channel_id" => state[:voice][:channel_id], "guild_id" => state[:voice][:guild_id], "self_mute" => false, "self_deaf" => true}
	  payload = payload_build(opcode(opcodes, :voice_state_update), data)
	  :websocket_client.cast(self, {:binary, payload})
  end

  defp _update_agent_sequence(data, state) do
    if state[:agent_seq_num] && data.seq_num do
      agent_update(state[:agent_seq_num], data.seq_num)
    end
  end

  defp _static_event?(event) do
    Enum.find(@static_events, fn(e) -> e == event end)
  end

  # Connection Heartbeat
  defp _heartbeat_loop(state, interval, socket_process) do
    spawn_link(fn -> _heartbeat(state, interval, socket_process) end)
    :ok
  end

  defp _heartbeat(state, interval, socket_process) do
    value = agent_value(state[:agent_seq_num])
    IO.puts value
    payload = payload_build(opcode(opcodes, :heartbeat), value)
    :websocket_client.cast(socket_process, {:binary, payload})
    :timer.sleep(interval)
    _heartbeat_loop(state, interval, socket_process)
  end
end
