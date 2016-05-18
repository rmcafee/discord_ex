defmodule DiscordElixir.EchoBot do
  @moduledoc """
  An all so original echo bot!
  """
  require Logger

  import DiscordElixir.RealtimeClient.Helpers

  alias DiscordElixir.RestClient

  # Message Handler
  def handle_event({:message_create, payload}, state) do
    spawn fn ->
      if actionable_message_for?("bk-tester-bot", payload, state) do
        command_parser(payload, state)
      end
    end
    {:ok, state}
  end

  # Fallback Handler
  def handle_event({event, _payload}, state) do
    Logger.info "Received Event: #{event}"
    {:ok, state}
  end

  # Select command to execute based off message payload
  def command_parser(payload, state) do
    case msg_command_parse(payload) do
      {"echo", msg} ->
        execute_command({"echo", msg}, payload, state)
      {nil, _} ->
        Logger.info("do nothing for message")
    end
  end

  # Echo response back to user or channel
  defp execute_command({"echo", message}, payload, state) do
    msg = String.upcase(message)
    # Knowing you can do this should be all you need.
    RestClient.resource(state[:rest_client], :post, "channels/#{payload.data["channel_id"]}/messages", %{content: "#{msg} yourself!"})
  end
end
