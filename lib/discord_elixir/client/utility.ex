defmodule DiscordElixir.Client.Utility do
  @moduledoc """
  Utilty methods to be used for discord clients.

  Normalizers, Encoders, and Decoders
  """

  @doc "Convert atom to string"
  @spec normalize_atom(atom) :: String.t
  def normalize_atom(atom) do
    atom |> Atom.to_string |> String.downcase |> String.to_atom
  end

  @doc "Build a pinary payload for discord communication"
  @spec payload_build(number, map, number, String.t) :: binary
  def payload_build(op, data, seq_num \\ nil, event_name \\ nil) do
    load = %{"op" => op, "d" => data}
    if seq_num, do: load = Map.put(load, "s", seq_num)
    if event_name, do: load = Map.put(load, "t", event_name)
    load |> :erlang.term_to_binary
  end

  @doc "Decode binary payload received from discord into a map"
  @spec payload_decode(list, {atom, binary}) :: map
  def payload_decode(codes, {:binary, payload}) do
    payload = :erlang.binary_to_term(payload)
    %{op: opcode(codes, payload[:op] || payload["op"]), data: (payload[:d] || payload["d"]), seq_num: (payload[:s] || payload["s"]), event_name: (payload[:t] || payload["t"])}
  end

  @doc "Get the integer value for an opcode using it's name"
  @spec opcode(map, atom) :: integer
  def opcode(codes, value) when is_atom(value) do
    codes[value]
  end

  @doc "Get the atom value of and opcode using an integer value"
  @spec opcode(map, integer) :: atom
  def opcode(codes, value) when is_integer(value) do
    {k, _value} = Enum.find codes, fn({_key, v}) -> v == value end
    k
  end
end
