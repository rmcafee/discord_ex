defmodule DiscordElixir.RestClient.Resources.Channel do
  @moduledoc """
  Convience helper for channel
  """

  @doc """
  Get channel

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id

  ## Examples

      Channel.get(conn, 99999999993832)
  """
  @spec get(pid, number) :: map
  def get(conn, channel_id) do
    DiscordElixir.RestClient.resource(conn, :get, "channels/#{channel_id}")
  end

  @doc """
  Update a channels settings

  Requires the 'MANAGE_GUILD' permission for the guild containing the channel.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - options: Updateable options which include (name, position, topic, bitrate)

  ## Examples

      Channel.modify(conn, 3290293092093, %{name: "my-channel", topic" "we all are friends here"})
  """
  @spec modify(pid, number, map) :: map
  def modify(conn, channel_id, options) do
    DiscordElixir.RestClient.resource(conn, :patch, "channels/#{channel_id}", options)
  end

  @doc """
  Delete a guild channel, or close a private message

  Requires the 'MANAGE_GUILD' permission for the guild containing the channel.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id

  ## Examples

      Channel.delete(conn, 93209293090239)
  """
  @spec delete(pid, number) :: map
  def delete(conn, channel_id) do
    DiscordElixir.RestClient.resource(conn, :delete, "channels/#{channel_id}")
  end

  @doc """
  Retrieve messages for a channel

  Requires the 'READ_MESSAGES' permission for the guild containing the channel.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id

  ## Examples

      Channel.messages(conn, 439093409304934)
  """
  @spec messages(pid, number) :: map
  def messages(conn, channel_id) do
    DiscordElixir.RestClient.resource(conn, :get, "channels/#{channel_id}/messages")
  end

  @doc """
  Post a message to a guild text or DM channel

  Requires the 'SEND_MESSAGES' permission to be present on the current user.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - message_data: message data which include (content, nonce, tts)

  ## Examples

      Channel.send_message(conn, 439093409304934, %{content: "Hi! Friends!"})
  """
  @spec send_message(pid, number, String.t) :: map
  def send_message(conn, channel_id, message_data) do
    DiscordElixir.RestClient.resource(conn, :post, "channels/#{channel_id}/messages", message_data)
  end

  @doc """
  Post a message to a guild text or DM channel

  Requires the 'SEND_MESSAGES' permission to be present on the current user.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - file_data: filed data which include (content, nonce, tts, file)

  ## Examples

      Channel.send_messages(conn, 439093409304934, %{content: "Check this out!", file: "/local/path/to/file.jpg"})
  """
  @spec send_file(pid, number, map) :: map
  def send_file(conn, channel_id, file_data) do
    DiscordElixir.RestClient.resource(conn, :post_multipart, "channels/#{channel_id}/messages", file_data)
  end
end
