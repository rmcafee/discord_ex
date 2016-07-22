defmodule DiscordEx.Voice.BufferTest do
  use ExUnit.Case
  doctest DiscordEx.Voice.Buffer

  alias DiscordEx.Voice.Buffer

  setup do
    buffer = Buffer.start
    {:ok, buffer: buffer}
  end

  test "write and read from buffer", state do
    binary = <<1,2,3,4>>
    Buffer.write(state[:buffer], binary)
    assert Buffer.read(state[:buffer], bit_size(binary)) == <<1,2,3,4>>
    assert Buffer.read(state[:buffer], 8) == ""
  end

  test "write and read from buffer with result size in bytes", state do
    Buffer.write(state[:buffer], <<130, 35>>)
    Buffer.write(state[:buffer], <<0::size(72720)>>)
    assert Buffer.read(state[:buffer], 16, :integer) == 9090
  end

  test "buffer size", state do
    Buffer.write(state[:buffer], <<0::size(32)>>)
    assert Buffer.size(state[:buffer]) == 32
  end

  test "buffer dump", state do
    Buffer.write(state[:buffer], <<0::size(32)>>)
    result = Buffer.dump(state[:buffer])
    assert Buffer.size(state[:buffer]) == 0
    assert result, <<0::size(32)>>
  end

  test "buffer drain", state do
    Buffer.write(state[:buffer], <<1>>)
    Buffer.write(state[:buffer], <<2>>)
    Buffer.write(state[:buffer], <<3>>)
    Buffer.drain state[:buffer], 8, fn(data, time) ->
      send self, {data, time}
    end

    assert_received {<<1>>, 0}
    assert_received {<<2>>, 0}
    assert_received {<<3>>, 0}

    assert Buffer.read(state[:buffer], 8) == ""
  end

  test "buffer drain on a dca file", state do
    p1_size_in_bits = 2500 * 8
    p2_size_in_bits = 5000 * 8
    p1_header = 2500
    p2_header = 5000
    packet_1 = :binary.encode_unsigned(p1_header, :little) <> <<0::size(p1_size_in_bits)>>
    packet_2 = :binary.encode_unsigned(p2_header, :little) <> <<0::size(p2_size_in_bits)>>

    Buffer.write(state[:buffer], packet_1)
    Buffer.write(state[:buffer], packet_2)

    assert Buffer.size(state[:buffer]) == 60032 

    Buffer.drain_dca state[:buffer], fn(data, time) ->
      send self, {data, time}
    end

    assert_received {<<0::size(p1_size_in_bits)>>, 0}
    assert_received {<<0::size(p2_size_in_bits)>>, 0}

    assert Buffer.size(state[:buffer]) == 0
  end
end
