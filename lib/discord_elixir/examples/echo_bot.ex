defmodule DiscordElixir.EchoBot do
  @moduledoc """
  An all so original echo bot!
  """
  alias DiscordElixir.RestClient

  def handle_event({:message_create, payload}, state) do
    if String.starts_with?(payload.data["content"],"test-bot") do
      command = String.replace(payload.data["content"], "test-bot ", "")
      execute_command(payload, command, state)
    end

    agent_update(state[:agent_seq_num], payload.seq_num)
    {:ok, state}
  end

  defp execute_command(payload, msg, state) do
    msg = String.upcase(msg)
    RestClient.resource(state[:rest_client], :post, "channels/#{payload.data["channel_id"]}/messages", %{content: "#{msg} yourself!"})
  end

  use DiscordElixir.RealtimeClient
end
