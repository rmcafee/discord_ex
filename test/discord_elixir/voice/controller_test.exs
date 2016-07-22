defmodule DiscordEx.Voice.ControllerTest do
  use ExUnit.Case
  doctest DiscordEx.Voice.Controller

  alias DiscordEx.Voice.Controller

  test "start controller with a buffer, sequence, and agent process" do
    controller = Controller.start(spawn fn -> IO.puts "mock voice_client" end)

    refute controller.buffer == nil
    refute controller.sequence == nil
    refute controller.time == nil
    refute controller.voice_client == nil
  end
end
