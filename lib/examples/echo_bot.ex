defmodule DiscordElixir.EchoBot do
  @moduledoc """
  An all so original echo bot!
  """
  import DiscordElixir.RealtimeClient

  alias DiscordElixir.RealtimeClient
  alias DiscordElixir.RestClient

  def handle_event({:message_create, payload}, state) do
    spawn_link fn ->
      if actionable_message_for?("bk-tester-bot", payload) do
        execute_command(payload, payload.data["content"], state)
      end
    end

    agent_update(state[:agent_seq_num], payload.seq_num)
    {:ok, state}
  end

  defp actionable_message_for?(username, payload) do
    if String.contains?(payload.data["content"], "long") do
      :timer.sleep(15000)
    end

    payload.data["author"]["username"] != username && mentions_include?(payload.data["mentions"],username) 
  end

  defp mentions_include?(mentions, username) do
    Enum.find mentions, fn(m) -> m["username"] == username end
  end

  defp execute_command(payload, msg, state) do
    msg = String.upcase(msg)

    # Knowing you can do this should be all you need.
    RestClient.resource(state[:rest_client], :post, "channels/#{payload.data["channel_id"]}/messages", %{content: "#{msg} yourself!"})
  end

end
