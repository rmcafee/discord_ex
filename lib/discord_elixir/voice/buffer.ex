defmodule DiscordElixir.Voice.Buffer do
  @moduledoc """
  Buffer Module for holding and reading audio.
  """
  @doc "Create a new queue"
  @spec start :: pid
  def start do
    {:ok, queue} = Agent.start_link fn -> <<>> end
    queue
  end

  @doc "Write to the buffer/queue binary data"
  @spec write(pid, binary) :: atom
  def write(queue, new_data) do
    data = new_data |> :erlang.binary_to_list |> Enum.reverse |> :erlang.list_to_binary
    Agent.update(queue, fn(existing_data) -> (data <> existing_data) end)
  end

  @doc "Read off of the buffer based on a set bit size"
  @spec read(pid, integer) :: binary
  def read(queue, size_in_bits) do
    data = Agent.get(queue, fn data -> data end)
    {remaining_data, capture_data} =  _slice_data_in_bits(data, size_in_bits)
    Agent.update(queue, fn(_existing_data) -> remaining_data end)
    capture_data |> :erlang.binary_to_list |> Enum.reverse |> :erlang.list_to_binary
  end

  @doc "Read off of the buffer based on a set bit size and return the integer format"
  @spec read(pid, integer, atom) :: binary
  def read(queue, size_in_bits, :integer) do
    data = Agent.get(queue, fn data -> data end)
    if data != "" do
      {remaining_data, capture_data} =  _slice_data_in_bits(data, size_in_bits, :integer)
      Agent.update(queue, fn(_existing_data) -> remaining_data end)
      capture_data
    else
      0
    end
  end

  @doc "Drain the buffer based off the bit size and apply the result to the function - you don't actually have to use time to make use of this"
  @spec drain(pid, integer, function) :: binary
  def drain(queue, size_in_bits, function, time \\ 0) do
    data = read(queue, size_in_bits)

    unless data == <<>> do
      function.(data, time)
      drain(queue, size_in_bits, function, time)
    end
  end

  @doc "Drain the buffer which is assumed to contain just opus packets which have a header that dictate the size of a frame and the packet is passed to the function"
  @spec drain_opus(pid, function, integer) :: binary
  def drain_opus(queue, function, time \\ 0) do
    packet_size_in_bytes = read(queue, 16, :integer)

    if packet_size_in_bytes != "" && packet_size_in_bytes != 0 do
      data = read(queue, packet_size_in_bytes * 8)
      unless data == <<>> do
        function.(data, time)
        drain_opus(queue, function, time)
      end
    else
      data = read(queue, 9_999_999_999_999)
      function.(data, time)
    end
  end

  @doc "Get the size of the buffer"
  @spec size(pid) :: integer
  def size(queue) do
    queue |> Agent.get(fn data -> data end) |> bit_size
  end

  @doc "Dump everything out of the buffer"
  @spec dump(pid) :: atom
  def dump(queue) do
    Agent.get(queue, fn data -> data end)
    Agent.update(queue, fn(_existing_data) -> <<>> end)
  end

  # For binary data
  defp _slice_data_in_bits(data, limit_in_bits) when (bit_size(data) >= limit_in_bits) do
    top_size = bit_size(data) - limit_in_bits
    << remaining_data::bitstring-size(top_size), capture_data::binary >> = data
    {remaining_data, capture_data}
  end

  # Use to handle empty data
  defp _slice_data_in_bits(data, _limit_in_bits) do
    {<<>>, data}
  end

  # For packet size information specifically using opus packets
  defp _slice_data_in_bits(data, limit_in_bits, :integer) do
    top_size = bit_size(data) - limit_in_bits
    << remaining_data::bitstring-size(top_size), capture_data::signed-integer-size(limit_in_bits) >> = data
    {remaining_data, capture_data}
  end
end
