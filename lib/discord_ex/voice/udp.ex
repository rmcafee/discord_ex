defmodule DiscordEx.Voice.UDP do
  @moduledoc """
  Voice UDP Setup functions
  """
  @spec self_discovery(String.t, number, number) :: {tuple, number}
  def self_discovery(endpoint, discord_port, ssrc) do
    discord_ip = resolve(endpoint)

    # Setup to send discovery packet
    data = << ssrc :: size(560) >>

    # Random UDP for connection and send discovery packet
    udp_options = [:binary, active: false, reuseaddr: true]
    {:ok, send_socket} = :gen_udp.open(0, udp_options)
    :gen_udp.send(send_socket, discord_ip, discord_port, data)

    # Receive the returned discovery data
    {:ok, discovery_data} = :gen_udp.recv(send_socket,70)
    discord_data = discovery_data |> Tuple.to_list |> List.last

    <<   _padding :: size(32),
            my_ip :: bitstring-size(112),
       _null_data :: size(400),
          my_port :: size(16) >> = discord_data

    {my_ip, my_port, discord_ip, discord_port, send_socket}
  end

  @spec send_audio(binary, pid, number, number) :: atom
  def send_audio(data, voice_client, sequence, time) do
    settings = _extract_voice_settings(voice_client)
    header = _header(sequence, time, settings[:ssrc])
    packet = header <> _encrypt_audio_packet(header, data, settings[:secret])
    :gen_udp.send(settings[:send_socket], settings[:address], settings[:port], packet)
  end

  defp resolve(endpoint) do
    try do
        endpoint |> String.replace(":80","") |> DNS.resolve
    rescue
      _e -> resolve(endpoint)
    end
  end

  defp _extract_voice_settings(vc) do
    %{send_socket: _send_socket(vc),
          address: _address(vc),
             port: _port(vc),
             ssrc: _ssrc(vc),
           secret: _secret_key(vc)}
  end

  defp _header(sequence, time, ssrc) do
    <<0x80::size(8), 0x78::size(8), sequence::size(16), time::size(32), ssrc::size(32)>>
  end

  defp _encrypt_audio_packet(header, data, secret) do
    nonce = (header <> <<0::size(96)>>)
    Kcl.secretbox(data, nonce, secret)
  end

  defp _secret_key(voice_client) do
    task = Task.async fn ->
      send(voice_client, {:get_state, :secret_key, self})
      receive do
        {:secret_key, value} -> :erlang.list_to_binary(value)
      end
    end
    Task.await(task, 10_000)
  end

  defp _port(voice_client) do
    task = Task.async fn ->
      send(voice_client, {:get_state, "port", self})
      receive do
        {"port", value} -> value
      end
    end
    Task.await(task, 10_000)
  end

  defp _address(voice_client) do
    task = Task.async fn ->
      send(voice_client, {:get_state, :udp_ip_send, self})
      receive do
        {:udp_ip_send, value} -> Socket.Address.parse(value)
      end
    end
    Task.await(task, 10_000)
  end

  defp _ssrc(voice_client) do
    task = Task.async fn ->
      send(voice_client, {:get_state, "ssrc", self})
      receive do
        {"ssrc", value} -> value
      end
    end
    Task.await(task, 10_000)
  end

  def _send_socket(voice_client) do
    task = Task.async fn ->
      send(voice_client, {:get_state, :udp_socket_send, self})
      receive do
        {:udp_socket_send, socket} -> socket
      end
    end
    Task.await(task, 5000)
  end

end
