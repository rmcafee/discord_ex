defmodule DiscordEx.RestClient.Resources.Channel do
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
    DiscordEx.RestClient.resource(conn, :get, "channels/#{channel_id}")
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
    DiscordEx.RestClient.resource(conn, :patch, "channels/#{channel_id}", options)
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
    DiscordEx.RestClient.resource(conn, :delete, "channels/#{channel_id}")
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
    DiscordEx.RestClient.resource(conn, :get, "channels/#{channel_id}/messages")
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
    DiscordEx.RestClient.resource(conn, :post, "channels/#{channel_id}/messages", message_data)
  end

  @doc """
  Post a file and message to a guild text or DM channel

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
    DiscordEx.RestClient.resource(conn, :post_multipart, "channels/#{channel_id}/messages", file_data)
  end

  @doc """
  Edit a previously sent message

  You can only edit messages that have been sent by the current user. 

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - message_id: The message id that you want to edit
    - message: Message you wish to update the sent message with

  ## Examples

      Channel.update_message(conn, 439093409304934, 32892398238, "Updating this message!")
  """
  @spec update_message(pid, number, number, String.t) :: map
  def update_message(conn, channel_id, message_id, message) do
    DiscordEx.RestClient.resource(conn, :patch, "channels/#{channel_id}/messages/#{message_id}", %{content:  message})
  end

  @doc """
  Delete a previously sent message

  This endpoint can only be used on guild channels and requires the 'MANAGE_MESSAGES' permission. 

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - message_id: The message id that you want to edit

  ## Examples

      Channel.delete_message(conn, 439093409304934, 32892398238)
  """
  @spec delete_message(pid, number, number) :: atom
  def delete_message(conn, channel_id, message_id) do
    response = DiscordEx.RestClient.resource(conn, :delete, "channels/#{channel_id}/messages/#{message_id}")
    case response do
      :invalid -> :ok
            _  -> :error
    end
  end

  @doc """
  Bulk Delete previously sent messages

  This endpoint can only be used on guild channels and requires the 'MANAGE_MESSAGES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - message_ids: list of msssage ids to delete

  ## Examples

      Channel.bulk_delete_messages(conn, 439093409304934, [32902930920932,3290239832023,237727828932])
  """
  @spec bulk_delete_messages(pid, number, list) :: atom
  def bulk_delete_messages(conn, channel_id, message_ids) do
    response = DiscordEx.RestClient.resource(conn, :post, "channels/#{channel_id}/messages/bulk_delete", %{messages: message_ids})
    case response do
                 :invalid -> :ok
                     data -> data
    end
  end

  @doc """
  Edit channel permissions

  Edit the channel permission overwrites for a user or role in a channel. Only usable for guild channels. Requires the 'MANAGE_ROLES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - overwrite_id: The role or user to override permissions in channel for
    - options: The permissions to allow or deny

  ## Examples

      Channel.edit_permissions(conn, 9999999999383, 2382830923, %{allow: 66321471})
  """
  @spec edit_permissions(pid, number, number, map) :: map
  def edit_permissions(conn, channel_id, overwrite_id, options) do
    DiscordEx.RestClient.resource(conn, :post, "channels/#{channel_id}/permissions/#{overwrite_id}", options)
  end

  @doc """
  Delete channel permissions

  Delete a channel permission overwrite for a user or role in a channel. Only usable for guild channels. Requires the 'MANAGE_ROLES' permission. 

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - overwrite_id: The role or user to override permissions in channel for

  ## Examples

      Channel.delete_permissions(conn, 9999999999383, 3279283989823)
  """
  @spec delete_permissions(pid, number, number) :: map
  def delete_permissions(conn, channel_id, overwrite_id) do
    response = DiscordEx.RestClient.resource(conn, :delete, "channels/#{channel_id}/permissions/#{overwrite_id}")
    case response do
      :invalid -> :ok
            _  -> :error
    end
  end

  @doc """
  Get channel invites

  Requires the 'MANAGE_CHANNELS' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id

  ## Examples

      Channel.get_invites(conn, 9999999999383)
  """
  @spec get_invites(pid, number) :: list
  def get_invites(conn, channel_id) do
    DiscordEx.RestClient.resource(conn, :get, "channels/#{channel_id}/invites")
  end

  @doc """
  Create channel invites

  Requires the CREATE_INSTANT_INVITE permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id
    - options: Invite creation options which include (max_age [default 24 hours], max_uses, temporary, xkcdpass)

  ## Examples

      Channel.create_invite(conn, 3290293092093, %{max_age: 86400, max_uses: 1, temporary: false, xkcdpass: false})
  """
  @spec create_invite(pid, number, map) :: map
  def create_invite(conn, channel_id, options) do
    DiscordEx.RestClient.resource(conn, :post, "channels/#{channel_id}/invites", options)
  end

  @doc """
  Trigger typing indicator

  Post a typing indicator for the specified channel. Generally bots should not implement this route.
  However, if a bot is responding to a command and expects the computation to take a few seconds, this
  endpoint may be called to let the user know that the bot is processing their message.

  ## Parameters

    - conn: User connection for REST holding auth info
    - channel_id: Channel id

  ## Examples

      Channel.trigger_typing(conn, 3290293092093)
  """
  @spec trigger_typing(pid, number) :: atom
  def trigger_typing(conn, channel_id) do
   response = DiscordEx.RestClient.resource(conn, :post, "channels/#{channel_id}/typing")
   case response do
     :invalid -> :ok
     _  -> :error
   end
  end

end
