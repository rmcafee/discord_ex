defmodule DiscordElixir.Voice.ControllerTest do
  use ExUnit.Case
  doctest DiscordElixir.Voice.Controller

  alias DiscordElixir.Voice.Controller

  test "start controller with a buffer, sequence, and agent process" do
    controller = Controller.start(spawn fn -> end)

    refute controller.buffer == nil
    refute controller.sequence == nil
    refute controller.time == nil
    refute controller.voice_client == nil
  end
end
