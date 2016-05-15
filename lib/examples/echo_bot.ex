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
        execute_command(payload, payload.data["content"], state)
      end
    end
    {:ok, state}
  end

  # Fallback Handler
  def handle_event({event, _payload}, state) do
    Logger.info "Received Event: #{event}"
    {:ok, state}
  end

  defp execute_command(payload, msg, state) do
    msg = String.upcase(msg)
    # Knowing you can do this should be all you need.
    RestClient.resource(state[:rest_client], :post, "channels/#{payload.data["channel_id"]}/messages", %{content: "#{msg} yourself!"})
  end
end
