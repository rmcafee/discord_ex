defmodule DiscordEx.Client.Helpers.MessageHelper do
  @moduledoc """
  Bot Message Helpers
  """
  alias DiscordEx.RestClient.Resources.User

  # Message Helper Functions

  @doc """
  Actionable Mention and DM Message

  This checks that an incoming message is private or is a mention to the defined user.

  ## Parameters

    - bot_name: Name of the bot you are using.
    - payload: Data from the triggered event.
    - state: Current state of bot.

  ## Example

      MessageHelper.actionable_message_for?("Mr.Botman", payload, state)
      #=> true
  """
  @spec actionable_message_for?(String.t, map, map) :: boolean
  def actionable_message_for?(bot_name, payload, state) do
    author_name = payload.data["author"]["username"]
    channel_id  = payload.data["channel_id"]
    mentions    = payload.data["mentions"]

    if author_name != bot_name do
      _message_in_private_channel?(channel_id, state) || _message_mentions_user?(mentions, bot_name)
    else
      false
    end
  end

  @doc """
  Actionable Mention and DM Message
  This checks that an incoming message is private or is a mention to the current user.
  ## Parameters
    - payload: Data from the triggered event.
    - state: Current state of bot.
  ## Example
      MessageHelper.actionable_message_for_me?(payload, state)
      #=> true
  """
  @spec actionable_message_for_me?(map, map) :: boolean
  def actionable_message_for_me?(payload, state) do

    author_id = payload.data["author"]["id"]
    channel_id  = payload.data["channel_id"]
    mentions    = payload.data["mentions"]

    if author_id != state[:client_id] do
      _message_in_private_channel?(channel_id, state) || _message_mentions_me?(mentions, state)
    else
      false
    end
  end

  @doc """
  Parses a message payload which is content leading with '!'.
  Returns a tuple with the command and the message.

  ## Parameters

    - payload: Data from the triggered event.

  ## Example

      MessageHelper.msg_command_parse(payload)
      #=> {"ping", "me please!"}
  """
  @spec msg_command_parse(map) :: {String.t, String.t}
  def msg_command_parse(payload) do
    cmd = case Regex.scan(~r/!(.\w*:\w*:\w*|.\w*:\w*|.\w*){1}/, payload.data["content"]) do
            []     -> nil
            result -> result |> List.last |> List.last
          end
    msg =
      payload.data["content"]
      |> String.replace("!#{cmd}", "")
      |> String.strip

    {cmd, msg}
  end

  # Private Functions

  defp _message_mentions_user?(mentions, username) do
    Enum.find mentions, fn(m) -> m["username"] == username end
  end

  defp _message_in_private_channel?(channel_id, state) do
    state[:rest_client]
      |> User.dm_channels
      |> Enum.find(fn(c) -> String.to_integer(c["id"]) == channel_id end)
  end

  defp _message_mentions_me?(mentions, state) do
    Enum.find mentions, fn(m) ->
      m["id"] == state[:client_id]
    end
  end
end
