defmodule DiscordElixir.Voice.Controller do
  @moduledoc """
  Voice control to make voice interaction a lot easier.
  """
  alias DiscordElixir.Voice.Buffer
  alias DiscordElixir.Voice.Encoder
  alias DiscordElixir.Voice.UDP

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
    {:ok, seq} = Agent.start(fn -> :random.uniform(93920290) end)
    {:ok, time} = Agent.start(fn -> :random.uniform(83290239) end)

    %{buffer: Buffer.start(),
      voice_client: voice_client,
      sequence: seq,
      time: time}
  end

  def play(controls, path, opts \\ %{}) when is_bitstring(path) do
    options = %{volume: 128}
    complete_options = Map.merge(options, opts)
    play_io(controls, Encoder.encode_file(path, complete_options))
  end

  def play_io(controls, io_data) do
    # Fill Buffer
    Enum.each io_data, fn(d) -> Buffer.write(controls.buffer, d) end

    send(controls.voice_client, {:speaking, true})
    Buffer.drain_opus controls.buffer, fn(data, _time) ->
      last_time = :os.system_time(:milli_seconds)
      UDP.send_audio(data,
                     controls.voice_client,
                     _read_agent(controls.sequence),
                     _read_agent(controls.time))
      _increment_agent(controls.sequence, 1)
      _increment_agent(controls.time, 960)
      :timer.sleep _sleep_timer(:os.system_time(:milli_seconds), last_time)
    end

    # Send 5 frames of silence
    Enum.each (0..5), fn(_) ->
      silence = <<0xF8, 0xFF, 0xFE>>
      UDP.send_audio(silence,
                     controls.voice_client,
                     _read_agent(controls.sequence),
                     _read_agent(controls.time))
      _increment_agent(controls.sequence, 1)
      _increment_agent(controls.time, 960)
      :timer.sleep 20
    end

    send(controls.voice_client, {:speaking, false})
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
end
