defmodule DiscordEx.Heartbeat do
  @moduledoc """
  Heartbeat service for Discord websocket connection.
  Sends heartbeat on interval and detects stale connection if heartbeat ack
  is not received.
  """
  use GenServer
  require Logger
  import DiscordEx.Client, only: [opcodes: 0]
  import DiscordEx.Client.Utility

  # API

  def start_link(agent_seq_num, interval, socket_pid, opts \\ []) do
    GenServer.start_link(__MODULE__, {agent_seq_num, interval, socket_pid}, opts)
  end

  def reset(pid) do
    GenServer.call(pid, :reset)
  end

  def ack(pid) do
    GenServer.call(pid, :ack)
  end

  # Server

  def init({agent_seq_num, interval, socket_pid}) do
    state = %{
      agent_seq_num: agent_seq_num,
      interval: interval,
      socket_pid: socket_pid,
      timer: nil,
      ack?: true,
    }
    # initial beat with ack?=true
    send(self(), :beat)
    {:ok, state}
  end

  @doc "Heartbeat ACK has been received, sends new heartbeat down the wire"
  def handle_info(:beat, %{interval: interval, socket_pid: socket_pid, ack?: true} = state) do
    value = agent_value(state[:agent_seq_num])
    payload = payload_build(opcode(opcodes(), :heartbeat), value)
    :websocket_client.cast(socket_pid, {:binary, payload})
    timer = Process.send_after(self(), :beat, interval)
    {:noreply, %{state | ack?: false, timer: timer}}
  end

  @doc "Heartbeat ACK not received, connection is stale. Stop heartbeat."
  def handle_info(:beat, %{socket_pid: socket_pid, ack?: false} = state) do
    send(socket_pid, :heartbeat_stale)
    {:noreply, %{state | timer: nil}}
  end

  @doc "Receive heartbeat ACK"
  def handle_call(:ack, _from, state) do
    {:reply, :ok, %{state | ack?: true}}
  end

  @doc "Reset heartbeat"
  def handle_call(:reset, _from, %{timer: nil} = state) do
    send(self(), :beat)
    {:reply, :ok, %{state | ack?: true}}
  end
  def handle_call(:reset, _from, %{timer: timer} = state) do
    Process.cancel_timer(timer)
    send(self(), :beat)
    {:reply, :ok, %{state | ack?: true, timer: nil}}
  end

  def handle_call(msg, _from, state) do
    Logger.debug(fn -> "Heartbeat called with invalid message #{inspect msg}" end)
    {:noreply, state}
  end

end
