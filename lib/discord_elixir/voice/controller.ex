defmodule DiscordElixir.Voice.Controller do
  @moduledoc """
  Voice control to make voice interaction a lot easier.
  """
  alias DiscordElixir.Voice.Buffer
  alias DiscordElixir.Voice.Encoder
  alias DiscordElixir.Voice.UDP

  require Logger

  def listen_socket(voice_client) do
    task = Task.async fn ->
      send(voice_client, {:get_state, :udp_socket_recv, self})
      receive do
        {:udp_socket_recv, socket} -> socket
      end
    end
    Task.await(task, 5000)
  end

  def start(voice_client) do
    {:ok, seq} = Agent.start_link(fn -> :random.uniform(93_920_290) end)
    {:ok, time} = Agent.start_link(fn -> :random.uniform(83_290_239) end)

    %{buffer: Buffer.start(),
      voice_client: voice_client,
      sequence: seq,
      time: time}
  end

  @doc """
  Stop audio from playing in channel and clear buffer

  ## Parameters

    - voice_client: The voice client so the library knows how to play it and where to

  ## Examples

      DiscordElixir.Controller.stop(voice_client)
  """
  def stop(voice_client) do
    controller = _get_controller(voice_client)
    Buffer.dump(controller.buffer)
    send(controller.voice_client, {:speaking, false})
  end

  @doc """
  Play some audio to a channel

  ## Parameters

    - voice_client: The voice client so the library knows how to play it and where to
    - path: The path where your audio file lives
    - opts: Options like volume

  ## Examples

      DiscordElixir.Controller.play(voice_client, "/my/awesome/audio.wav", %{volume: 128})
  """
  def play(voice_client, path, opts \\ %{}) when is_bitstring(path) do
    controller = _get_controller(voice_client)

    if Buffer.size(controller.buffer) == 0 do
      options = %{volume: 128}
      merged_options = Map.merge(options, opts)
      _play_io(controller, Encoder.encode_file(path, merged_options))
    else
      Logger.info "Tried to play audio but audio already playing."
    end
  end

  defp _play_io(controller, io_data) do
    # Fill Buffer
    Enum.each io_data, fn(d) -> Buffer.write(controller.buffer, d) end

    try do
      send(controller.voice_client, {:speaking, true})

      Buffer.drain_dca controller.buffer, fn(data, _time) ->
        last_time = :os.system_time(:milli_seconds)
        UDP.send_audio(data,
                       controller.voice_client,
                       _read_agent(controller.sequence),
                       _read_agent(controller.time))
        _increment_agent(controller.sequence, 1)
        _increment_agent(controller.time, 960)
        :timer.sleep _sleep_timer(:os.system_time(:milli_seconds), last_time)
      end

      # Send 5 frames of silence
      Enum.each (0..5), fn(_) ->
        silence = <<0xF8, 0xFF, 0xFE>>
        UDP.send_audio(silence,
                       controller.voice_client,
                       _read_agent(controller.sequence),
                       _read_agent(controller.time))
        _increment_agent(controller.sequence, 1)
        _increment_agent(controller.time, 960)
        :timer.sleep 20
      end

      send(controller.voice_client, {:speaking, false})
    rescue
      Error ->
        Logger.error("Something went wrong while playing audio!")
        send(controller.voice_client, {:speaking, false})
    end
  end

  defp _sleep_timer(now_time, last_time, delay_time \\ 17) do
    if (now_time - last_time) < delay_time do
      delay_time - (now_time - last_time)
    else
      0
    end
  end

  defp _read_agent(pid) do
    Agent.get(pid, fn data -> data end)
  end

  defp _increment_agent(pid, incr) do
    Agent.update(pid, fn(current_number) -> (current_number + incr) end)
  end

  defp _get_controller(vc) do
    task = Task.async fn ->
      send(vc, {:get_controller, self()})
      receive do controller -> controller end
    end
    Task.await(task, 5000)
  end
end
