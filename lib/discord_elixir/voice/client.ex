defmodule DiscordElixir.Voice.Client do
  @moduledoc """
  This client is for specifically working with voice. You can pass this process
  to your regular client if you wish to use it with your bot.
  ## Examples

      token = "<your-token>"
      DiscordElixir.Voice.start_link(%{token: token, guild_id: 392090239})
      #=> {:ok, #PID<0.180.0>}
  """
  require Logger

  @opcodes %{
    :identify             => 0,
    :select_protocol      => 1,
    :ready                => 2,
    :heartbeat            => 3,
    :session_description  => 4,
    :speaking             => 5,
  }

  @behaviour :websocket_client_handler

  # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
  def start_link(opts) do
    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(opts[:gateway], __MODULE__,opts)
  end

  def init(state, _socket) do
    identify(state)
    {:ok, state}
  end

  def websocket_info(:start, _conn_state, state) do
    {:reply, {:text, "message received"}, state}
  end

  def websocket_terminate(reason, _conn_state, state) do
    Logger.info "Websocket closed in state #{inspect state} wih reason #{inspect reason}"
    #Process.exit(state[:udp_connection], :kill)
    :ok
  end

  def websocket_handle({:binary, payload}, _socket, state) do
    data  = payload_decode({:binary, payload})
    event = normalize_atom(data.event_name)
    handle_event({event, data}, state)
  end

  def handle_event({:ready, payload}, state) do
    heartbeat_loop(state, payload.data.heartbeat_interval, self)
    {:ok, state}
  end

  def handle_event({event, payload}, state) do
    Logger.info "Voice Connection Received Event: #{event}"
    agent_update(state[:agent_seq_num], payload.seq_num)
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

    payload = payload_build(opcode(:identify), data)
    :websocket_client.cast(self, {:binary, payload})
  end

  # Helper Functions
  @spec opcode(atom) :: integer
  def opcode(value) when is_atom(value) do
    @opcodes[value]
  end

  @spec opcode(integer) :: atom
  def opcode(value) when is_integer(value) do
    {k, _value} = Enum.find @opcodes, fn({_key, v}) -> v == value end
    k
  end

  # Sequence Tracking for Resuming and Heartbeat Tracking
  def agent_value(agent) do
    Agent.get(agent, fn a -> a end)
  end

  def agent_update(agent, n) do
    if n != nil do
      Agent.update(agent, fn _a -> n end)
    end
  end

  # Connection Heartbeat
  def heartbeat_loop(state, interval, socket_process) do
    spawn_link(fn -> heartbeat(state, interval, socket_process) end)
    :ok
  end

  def heartbeat(state, interval, socket_process) do
    value = agent_value(state[:agent_seq_num])
    payload = payload_build(opcode(:heartbeat), value)
    :websocket_client.cast(socket_process, {:binary, payload})
    :timer.sleep(interval)
    heartbeat_loop(state, interval, socket_process)
  end

  # Normalizers, Encoders, and Decoders
  def normalize_atom(atom) do
    atom |> Atom.to_string |> String.downcase |> String.to_atom
  end

  def payload_build(op, data, seq_num \\ nil, event_name \\ nil) do
    load = %{"op" => op, "d" => data}
    if seq_num, do: load = Map.put(load, "s", seq_num)
    if event_name, do: load = Map.put(load, "t", event_name)
    load |> :erlang.term_to_binary
  end

  def payload_decode({:binary, payload}) do
    payload = :erlang.binary_to_term(payload)
    %{op: opcode(payload[:op] || payload["op"]), data: (payload[:d] || payload["d"]), seq_num: (payload[:s] || payload["s"]), event_name: (payload[:t] || payload["t"])}
  end
end
