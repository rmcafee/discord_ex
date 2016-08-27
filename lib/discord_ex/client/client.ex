defmodule DiscordEx.Client do
  @moduledoc """
  Connect to Discord to recieve and send data in realtime
  You shouldn't be using this directly. You should pass it to a handler.

  ## Examples

      token = "<your-token>"
      DiscordEx.Client.start_link(%{token: token, handler: DiscordEx.EchoBot})
      #=> {:ok, #PID<0.178.0>}
  """
  require Logger

  import DiscordEx.Client.Utility

  alias DiscordEx.RestClient.Resources.User

  @behaviour :websocket_client

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

  @static_events [:ready, :guild_create, :voice_state_update]

  def start_link(opts) do
    # We go ahead and add this to the state early as we use it to get the websocket gateway to start.
    {:ok, rest_client} = DiscordEx.RestClient.start_link(%{token: opts[:token]})
    opts = Map.put(opts, :rest_client, rest_client)

    opts = Map.put(opts, :guilds, [])

    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(socket_url(opts), __MODULE__,opts)
  end

  # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
  def init(state) do
    # State sequence management process and set it's state
    {:ok, agent_seq_num} = Agent.start_link fn -> 0 end

    new_state = state
      |> Map.put(:client_pid, self()) # Pass the client state to use it
      |> Map.put(:agent_seq_num, agent_seq_num) # Pass agent sequence num

    {:once, new_state}
  end

  def onconnect(_WSReq, state) do
    # Send identifier to discord gateway
    identify(state)
    {:ok, state}
  end

  def ondisconnect({:remote, :closed}, _state) do
    # Stub for beter actions later
  end

  @doc """
  Voice State Update for Users ( move users around voice channels )

  ## Parameters

    - client_pid: Base client process
    - guild_id: Which guild to move this user in
    - channel_id: Which channel the user is in or you want to move them to
    - user_id: User to manipulate
    - options: Options to set on the user

  ## Examples

      DiscordEx.Client.voice_state_update(client, guild_id, user_id, channel_id, %{self_deaf: true, self_mute: false})
  """
  @spec voice_state_update(pid, String.t, String.t, String.t, map) :: atom
  def voice_state_update(client_pid, guild_id, channel_id, user_id, options \\ %{}) do
    data = options |> Map.merge(%{guild_id: guild_id, channel_id: channel_id, user_id: user_id})
    send(client_pid, {:voice_state_update, data})
    :ok
  end

  def websocket_handle({:binary, payload}, _socket, state) do
    data  = payload_decode(opcodes, {:binary, payload})
    event = normalize_atom(data.event_name)

    # Keeps the sequence tracker process updated
    _update_agent_sequence(data, state)

    # This will setup the voice_client if it is not already setup
    if state[:voice_setup] && _voice_valid_event(event, data, state) do
      send(state[:voice_setup], {self(), data, state})
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

  @doc "Look into state - grab key value and pass it back to calling process"
  def websocket_info({:get_state, key, pid}, _connection, state) do
    send(pid, {key, state[key]})
    {:ok, state}
  end

  @doc "Ability to update websocket client state"
  def websocket_info({:update_state, update_values}, _connection, state) do
    {:ok,  Map.merge(state, update_values)}
  end

  @doc "Remove key from state"
  def websocket_info({:clear_from_state, keys}, _connection, state) do
    new_state = Map.drop(state, keys)
    {:ok, new_state}
  end

  @doc "Initiate voice connection update state call"
  def websocket_info({:start_voice_connection, options}, _connection, state) do
    self_mute = if (options[:self_mute] == nil), do: false, else: options[:self_mute]
    self_deaf = if (options[:self_deaf] == nil), do: true, else: options[:self_mute]
    data = %{
      "channel_id" => options[:channel_id],
      "guild_id"   => options[:guild_id],
      "self_mute"  => self_mute,
      "self_deaf"  => self_deaf
    }
    payload = payload_build(opcode(opcodes, :voice_state_update), data)
    :websocket_client.cast(self, {:binary, payload})
    {:ok, state}
  end

  def websocket_info({:start_voice_connection_listener, caller}, _connection, state) do
    setup_pid = spawn(fn -> _voice_setup_gather_data(caller, %{}, state) end)
    updated_state = Map.merge(state, %{voice_setup: setup_pid})
    {:ok, updated_state}
  end

  def websocket_info({:voice_state_update, opts}, _connection, state) do
    data = for {key, val} <- opts, into: %{}, do: {Atom.to_string(key), val}
    payload = payload_build(opcode(opcodes, :voice_state_update), data)
    :websocket_client.cast(self, {:binary, payload})
    {:ok, state}
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

    if state[:voice] do
      _connect_voice_to_client(self(), state)
    end

    {:ok, new_state}
  end

  def handle_event({:guild_create, payload}, state) do

    guild = %{guild_id: payload.data[:id],
              voice_states: payload.data[:voice_states]}
    new_guilds = state[:guilds] ++ [guild]
    new_state = Map.merge(state, %{guilds: new_guilds})

    {:ok, new_state}
  end

  def handle_event({:voice_state_update, payload}, state) do
    new_voice_states = state[:voice_states]
                      |> Enum.filter(fn(m) -> m.user_id != payload.data.user_id end)
                      |> List.insert_at(-1, payload.data)
    new_state = Map.merge(state, %{voice_states: new_voice_states})
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
        "$browser" => "discord-ex",
        "$device" => "discord-ex",
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
    url = DiscordEx.RestClient.resource(opts[:rest_client], :get, "gateway")["url"]
      |> String.replace("gg/", "")
    url <> "?v=#{version}&encoding=etf" |> String.to_char_list
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
    payload = payload_build(opcode(opcodes, :heartbeat), value)
    :websocket_client.cast(socket_process, {:binary, payload})
    :timer.sleep(interval)
    _heartbeat_loop(state, interval, socket_process)
  end

  defp _connect_voice_to_client(client_pid, state) do
    spawn fn ->
      :timer.sleep 2000
      # Setup voice - this makes it easier to access voice in a handler
      {:ok, voice_client} = DiscordEx.Voice.Client.connect(client_pid, state[:voice])
      send(client_pid, {:clear_from_state, [:voice]})
      send(client_pid, {:update_state, %{voice_client: voice_client}})
    end
  end

  ### VOICE SETUP FUNCTIONS ###
  @doc "Start a voice connection listener process"
  def _voice_setup_gather_data(caller_pid, data \\ %{}, state) do
    new_data = receive do
      {client_pid, received_data, _state} ->
        data
          |> Map.merge(received_data[:data])
          |> Map.merge(%{client_pid: client_pid})
    end

    voice_token = new_data[:token] || state[:voice_token]
    endpoint = new_data[:endpoint] || state[:endpoint]

    if voice_token && new_data[:session_id] && endpoint do
      send(new_data[:client_pid], {:update_state, %{endpoint: endpoint, voice_token: voice_token}})
      send(new_data[:client_pid], {:clear_from_state, [:voice_setup]})
      send(caller_pid, Map.merge(new_data, %{endpoint: endpoint, token: voice_token}))
    else
      _voice_setup_gather_data(caller_pid, new_data, state)
    end
  end

  def _voice_valid_event(event, data, state) do
    event = Enum.find([:voice_server_update, :voice_state_update], fn(e) -> e == event end)
    case event do
      :voice_state_update  ->
        (User.current(state[:rest_client])["id"] == "#{data[:data][:user_id]}")
      :voice_server_update -> true
                         _ -> false
    end
  end
end
