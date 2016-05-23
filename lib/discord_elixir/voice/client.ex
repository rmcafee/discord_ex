defmodule DiscordElixir.Voice.Client do
  @moduledoc """
  This client is for specifically working with voice. You can pass this process
  to your regular client if you wish to use it with your bot.

  ## Examples

      token = "<your-token>"
      DiscordElixir.Voice.start_link(%{token: token,
                                       guild_id: 392090239,
                                       user_id: 48304803480,
                                       session_id: 328083029,
                                       token: "e403f8330"})
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

  def setup(setup_data \\ %{}) do
    new_data = receive do
      {from, :voice_state_update, data} ->
        Logger.info "Setup Voice State Update ..."
        Map.merge(data, %{voice_state_update: data[:data], from: from})
      {from, :voice_server_update, data} ->
        Logger.info "Setup Voice Server Update ..."
        Map.merge(data, %{voice_server_update: data[:data], from: from})
    end

    merge_data = if new_data, do: new_data, else: %{}
    merged_data = Map.merge(setup_data, merge_data)

    if merged_data[:voice_state_update] && merged_data[:voice_server_update] do
      Logger.info("All Setup Voice Data Received!")
      init_data = Map.merge(merged_data[:voice_state_update], merged_data[:voice_server_update])
      spawn(fn -> start_link(Map.merge(init_data, %{parent_pid: merged_data[:from]})) end)
    else
      setup(merged_data)
    end
  end

  # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
  def start_link(opts) do
    url = socket_url(opts[:endpoint])
    :crypto.start()
    :ssl.start()
    :websocket_client.start_link(url, __MODULE__, opts)
  end

  def init(state, _socket) do
    identify(state)
    {:ok, state}
  end

  def websocket_info(:start, _conn_state, state) do
    {:reply, {:text, "message received"}, state}
  end

  @doc "Ability to output state information"
  def websocket_info(:inspect_state, _connection, state) do
    IO.inspect state
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
    send(state[:parent_pid], {:update_state, %{voice_client: self}})
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
    "wss://" <> url |> String.replace(":80","")
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
