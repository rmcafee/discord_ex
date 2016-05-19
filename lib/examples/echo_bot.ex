defmodule DiscordElixir.EchoBot do
  @moduledoc """
  An all so original echo bot!
  """
  require Logger

  alias DiscordElixir.RealtimeClient.Helpers.MessageHelper
  alias DiscordElixir.RestClient.Resources.Channel

  # Message Handler
  def handle_event({:message_create, payload}, state) do
    spawn fn ->
      if MessageHelper.actionable_message_for?("bk-tester-bot", payload, state) do
        _command_parser(payload, state)
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
  defp _command_parser(payload, state) do
    case MessageHelper.msg_command_parse(payload) do
      {nil, msg} ->
        Logger.info("do nothing for message #{msg}")
      {cmd, msg} ->
        _execute_command({cmd, msg}, payload, state)
    end
  end

  # Echo response back to user or channel
  defp _execute_command({"example:echo", message}, payload, state) do
    msg = String.upcase(message)
    Channel.send_message(state[:rest_client], payload.data["channel_id"], %{content: "#{msg} yourself!"})
  end

  # Pong response to ping
  defp _execute_command({"example:ping", _message}, payload, state) do
    Channel.send_message(state[:rest_client], payload.data["channel_id"], %{content: "Pong!"})
  end
end
