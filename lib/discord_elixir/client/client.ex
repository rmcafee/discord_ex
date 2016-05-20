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

  @opcodes %{
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
    data  = payload_decode(@opcodes, {:binary, payload})
    event = normalize_atom(data.event_name)

    # Update agent sequence to track state
    if state[:agent_seq_num] && data.seq_num do
      _agent_update(state[:agent_seq_num], data.seq_num)
    end

    # Call handler unless it is a static event
    if state[:handler] && !_static_event?(event) do
      state[:handler].handle_event({event, data}, state)
    else
      handle_event({event, data}, state)
    end
  end

  def websocket_terminate(reason, _conn_state, state) do
    Logger.info "Websocket closed in state #{inspect state} wih reason #{inspect reason}"
    Logger.info "Killing seq_num process!"
    Process.exit(state[:agent_seq_num], :kill)
    Logger.info "Killing rest_client process!"
    Process.exit(state[:rest_client], :kill)
    :ok
  end

  # Behavioural placeholder
  def websocket_info(:start, _connection, state) do
    {:ok, state}
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
    payload = payload_build(opcode(@opcodes, :identify), data)
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

  defp _static_event?(event) do
    Enum.find(@static_events, fn(e) -> e == event end)
  end

  # Sequence Tracking for Resuming and Heartbeat Tracking
  defp _agent_value(agent) do
    Agent.get(agent, fn a -> a end)
  end

  defp _agent_update(agent, n) do
    if n != nil do
      Agent.update(agent, fn _a -> n end)
    end
  end

  # Connection Heartbeat
  defp _heartbeat_loop(state, interval, socket_process) do
    spawn_link(fn -> _heartbeat(state, interval, socket_process) end)
    :ok
  end

  defp _heartbeat(state, interval, socket_process) do
    value = _agent_value(state[:agent_seq_num])
    payload = payload_build(opcode(@opcodes, :heartbeat), value)
    :websocket_client.cast(socket_process, {:binary, payload})
    :timer.sleep(interval)
    _heartbeat_loop(state, interval, socket_process)
  end
end
