defmodule DiscordEx.RestClient.Resources.Guild do
  @moduledoc """
  Convience helper for guild resource
  """

  @doc """
  Get guild object

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.get(conn, 9999999923792)
  """
  @spec get(pid, String.t) :: map
  def get(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}")
  end

  @doc """
  Create guild

  This endpoint is only available for whitelisted bots. If you believe
  you have a legitimate use case for automating guild creation, please
  contact support@discordapp.com.

  ## Parameters

    - conn: User connection for REST holding auth info
    - options: Options for creating a guild including (name, region, icon)

  ## Examples

      Guild.create(conn, %{name: "My Guild", region: "Amsterdam", icon: "/path/to/local/icon.jpg"})
  """
  @spec get(pid, map) :: map
  def create(conn, options) do
    DiscordEx.RestClient.resource(conn, :post, "guilds", _format_guild_options(options))
  end

  @doc """
  Modify guild

  Modify a guilds settings. Returns the updated guild object on success.

  ## Parameters

    - conn: User connection for REST holding auth info
    - options: Options for creating a guild  including
               (name, region, verification_level, afk_channel_id, afk_timeout, icon(128x128), owner_id, splash(128x128))

  ## Examples

      Guild.modify(conn, 320923099923,
        %{name: "My Guild", region: "Amsterdam", icon: "/path/to/local/icon.jpg", owner_id: 4930928030923})
  """
  @spec modify(pid, number, map) :: map
  def modify(conn, guild_id, options) do
    DiscordEx.RestClient.resource(conn, :patch, "guilds/#{guild_id}", _format_guild_options(options))
  end

  @doc """
  Delete guild

  BE CAREFUL - YOU CAN NOT UNDO! User must be owner.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.delete(conn, 9999999923792)
  """
  @spec delete(pid, number) :: map
  def delete(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :delete, "guilds/#{guild_id}")
  end

  @doc """
  Get guild channels

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.channels(conn, 9999999923792)
  """
  @spec channels(pid, number) :: map
  def channels(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/channels")
  end

  @doc """
  Create guild channel

  Requires the 'MANAGE_CHANNELS' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - options: Options for creating a guild channel including (name, type, bitrate)

  ## Examples

      Guild.create_channel(conn, 93209203902, %{name: "general-chat", type: "text"})
  """
  @spec create_channel(pid, number, map) :: map
  def create_channel(conn, guild_id, options) do
    DiscordEx.RestClient.resource(conn, :post, "guilds/#{guild_id}/channels", options)
  end

  @doc """
  Get guild members

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - options: Other options which include (limit, offset)

  ## Examples

      Guild.members(conn, 9999999923792, %{limit: 4})
  """
  @spec members(pid, number, map) :: map
  def members(conn, guild_id, options) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/members", options)
  end

  @doc """
  Get guild member

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - user_id: User id of guild member

  ## Examples

      Guild.member(conn, 9999999923792, 3290238023092309)
  """
  @spec member(pid, number, number) :: map
  def member(conn, guild_id, user_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/members/#{user_id}")
  end

  @doc """
  Modify guild member

  When moving members to channels, the API user must have permissions
  to both connect to the channel and have the MOVE_MEMBERS permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - user_id: User id of guild member
    - options: Options to update guild member which include (nick, roles, mute, deaf, channel_id)

  ## Examples

      Guild.modify_member(conn, 9999999923792, 3290238023092309, %{nick: "Jingo", mute: true, channel_id: 3920293092390})
  """
  @spec modify_member(pid, number, number, map) :: atom
  def modify_member(conn, guild_id, user_id, options) do
    response = DiscordEx.RestClient.resource(conn, :patch, "guilds/#{guild_id}/members/#{user_id}", options)
    case response do
                 :invalid -> :ok
                     data -> data
    end
  end

  @doc """
  Remove guild member (KICK)

  Remove a member from a guild. Requires 'KICK_MEMBERS' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - user_id: User id of guild member

  ## Examples

      Guild.kick_member(conn, 9999999923792, 3290238023092309)
  """
  @spec kick_member(pid, number, number) :: atom
  def kick_member(conn, guild_id, user_id) do
    response = DiscordEx.RestClient.resource(conn, :delete, "guilds/#{guild_id}/members/#{user_id}")
    case response do
                 :invalid -> :ok
                     data -> data
    end
  end

  @doc """
  Ban guild member

  Create a guild ban, and optionally delete previous messages sent by
  the banned user. Requires the 'BAN_MEMBERS' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - user_id: User id of guild member
    - options: Option for banning which includes (delete-message-days)

  ## Examples

      Guild.ban_member(conn, 9999999923792, 3290238023092309, %{delete-message-days: 3})
  """
  @spec ban_member(pid, number, number, map) :: atom
  def ban_member(conn, guild_id, user_id, options) do
    response = DiscordEx.RestClient.resource(conn, :put, "guilds/#{guild_id}/bans/#{user_id}", options)
    case response do
                 :invalid -> :ok
                     data -> data
    end
  end

  @doc """
  Remove or Lift Ban

  Remove the ban for a user. Requires the 'BAN_MEMBERS' permissions.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - user_id: User id of guild member

  ## Examples

      Guild.unban_member(conn, 9999999923792, 3290238023092309)
  """
  @spec unban_member(pid, number, number) :: atom
  def unban_member(conn, guild_id, user_id) do
    response = DiscordEx.RestClient.resource(conn, :delete, "guilds/#{guild_id}/bans/#{user_id}")
    case response do
                 :invalid -> :ok
                     data -> data
    end
  end

  @doc """
  List banned users

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.bans(conn, 9999999923792)
  """
  @spec bans(pid, number) :: map
  def bans(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/bans")
  end

  @doc """
  List guild roles

  Returns a list of role objects for the guild. Requires the 'MANAGE_ROLES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.roles(conn, 9999999923792)
  """
  @spec roles(pid, number) :: map
  def roles(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/roles")
  end

  @doc """
  Create guild role

  Create a new empty role object for the guild. Requires the 'MANAGE_ROLES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.create_empty_role(conn, 9999999923792)
  """
  @spec create_empty_role(pid, number) :: map
  def create_empty_role(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :post, "guilds/#{guild_id}/roles")
  end

  @doc """
  Batch modify roles

  Batch modify a set of role objects for the guild.
  Requires the 'MANAGE_ROLES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - user_id: User id of guild member
    - role_option_array: Options to update roles which include (id, name, permissions, position, color, hoist)

  ## Examples

      Guild.batch_modify_roles(conn, 9999999923792, 3290238023092309, [
        %{id: 392092390909032, position: 1},
        %{id: 392053390902324, position: 2}
      ])
  """
  @spec batch_modify_roles(pid, number, list) :: map
  def batch_modify_roles(conn, guild_id, role_option_array) do
    DiscordEx.RestClient.resource(conn, :patch, "guilds/#{guild_id}/roles", role_option_array)
  end

  @doc """
  Modify role

  Modify a guild role. Requires the 'MANAGE_ROLES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - role_id: Role id
    - options: Options to update roles which include (name, permissions, position, color, hoist)

  ## Examples

      Guild.modify_role(conn, 320923099923, 3290930290923, %{name: "super-administrator", color: 11830404, permissions: 66321471})
  """
  @spec modify_role(pid, number, number, map) :: map
  def modify_role(conn, guild_id, role_id, options) do
    DiscordEx.RestClient.resource(conn, :patch, "guilds/#{guild_id}/roles/#{role_id}", options)
  end


  @doc """
  Remove guild role

  Delete a guild role. Requires the 'MANAGE_ROLES' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - role_id: Role id of guild member

  ## Examples

      Guild.delete_role(conn, 9999999923792, 3290238023092309)
  """
  @spec delete_role(pid, number, number) :: atom
  def delete_role(conn, guild_id, role_id) do
    response = DiscordEx.RestClient.resource(conn, :delete, "guilds/#{guild_id}/roles/#{role_id}")
    case response do
                 :invalid -> :ok
                     data -> data
    end
  end

  @doc """
  Begin guild prune

  Begin a prune operation. Requires the 'KICK_MEMBERS' permission. 

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - options: Options to prune guild members which include (days)

  ## Examples

      Guild.begin_prune(conn, 9999999923792, %{days: 7})
  """
  @spec begin_prune(pid, number, map) :: map
  def begin_prune(conn, guild_id, options) do
    DiscordEx.RestClient.resource(conn, :post, "guilds/#{guild_id}/prune", options)
  end

  @doc """
  Get prune count

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - options: Options to prune guild members which include (days)

  ## Examples

      Guild.prune_count(conn, 9999999923792, %{days: 7})
  """
  @spec prune_count(pid, number, map) :: map
  def prune_count(conn, guild_id, options) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/prune", options)
  end

  @doc """
  Get voice regions

  Returns a list of voice region objects for the guild.
  Unlike the similar /voice route, this returns VIP servers when the guild is VIP-enabled.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.voice_regions(conn, 9999999923792)
  """
  @spec voice_regions(pid, number) :: map
  def voice_regions(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/regions")
  end

  @doc """
  Get invites

  Returns a list of invite objects (with invite metadata) for the guild.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.invites(conn, 9999999923792)
  """
  @spec invites(pid, number) :: map
  def invites(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/invites")
  end

  @doc """
  Get guild embed

  Returns the guild embed object.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.embed(conn, 9999999923792)
  """
  @spec embed(pid, number) :: map
  def embed(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/embed")
  end

  @doc """
  Get integrations

  Returns a list of integration objects for the guild.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.integrations(conn, 9999999923792)
  """
  @spec integrations(pid, number) :: map
  def integrations(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :get, "guilds/#{guild_id}/integrations")
  end

  @doc """
  Create guild integration

  Attach an integration object from the current user to the guild.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - options: Options for creating a guild integration including (type, id)

  ## Examples

      Guild.create_integration(conn, 93209203902, %{id: 3288823892398298293, type: "awesome-application"})
  """
  @spec create_integration(pid, number, map) :: atom
  def create_integration(conn, guild_id, options) do
    response = DiscordEx.RestClient.resource(conn, :post, "guilds/#{guild_id}/integrations", options)
    case response do
      :invalid -> :ok
          data -> data
    end
  end

  @doc """
  Modify guild integration

  Modify the behavior and settings of a integration object for the
  guild. Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - integration_id: Integration id
    - options: Options for modifying a guild integration including (expire_behavior, expire_grace_period, enable_emoticons)

  ## Examples

      Guild.modify_integration(conn, 93209203902, 3892898393, %{expire_grace_period: 300, enable_emoticons: true})
  """
  @spec modify_integration(pid, number, number, map) :: atom
  def modify_integration(conn, guild_id, integration_id, options) do
    response = DiscordEx.RestClient.resource(conn, :patch, "guilds/#{guild_id}/integrations/#{integration_id}", options)
    case response do
      :invalid -> :ok
          data -> data
    end
  end

  @doc """
  Delete guild integration

  Delete the attached integration object for the guild.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - integration_id: Integration id

  ## Examples

      Guild.delete_integration(conn, 93209203902, 3892898393)
  """
  @spec delete_integration(pid, number, number) :: atom
  def delete_integration(conn, guild_id, integration_id) do
    response = DiscordEx.RestClient.resource(conn, :delete, "guilds/#{guild_id}/integrations/#{integration_id}")
    case response do
      :invalid -> :ok
          data -> data
    end
  end

  @doc """
  Sync guild integration

  Sync an integration.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id
    - integration_id: Integration id

  ## Examples

      Guild.sync_integration(conn, 93209203902, 3892898393)
  """
  @spec sync_integration(pid, number, number) :: atom
  def sync_integration(conn, guild_id, integration_id) do
    response = DiscordEx.RestClient.resource(conn, :post, "guilds/#{guild_id}/integrations/#{integration_id}/sync")
    case response do
      :invalid -> :ok
          data -> data
    end
  end

  @doc """
  Modify guild embed

  Modify a guild embed object for the guild.
  Requires the 'MANAGE_GUILD' permission.

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: Guild id

  ## Examples

      Guild.modify_embed(conn, 93209203902, %{enabled: false})
  """
  @spec modify_embed(pid, number) :: map
  def modify_embed(conn, guild_id) do
    DiscordEx.RestClient.resource(conn, :patch, "guilds/#{guild_id}/embed")
  end

  # Private Methods

  defp _format_guild_options(options) do
    data_1 = if options[:icon] do
              Map.put(options, :icon, "data:image/jpeg;base64," <> _encode_image(options[:icon]))
            else
              options
            end
    data_2 = if data_1[:splash] do
              Map.put(data_1, :splash, "data:image/jpeg;base64," <> _encode_image(options[:splash]))
            else
              data_1
            end
    data_2
  end

  defp _encode_image(image_path) do
    image_path
      |> File.read!
      |> Base.encode64
  end
end
