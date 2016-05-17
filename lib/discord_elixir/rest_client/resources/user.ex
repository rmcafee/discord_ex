defmodule DiscordElixir.RestClient.Resources.User do
  @moduledoc """
  Convience helper for User Resource
  """

  @doc """
  User login that returns connection

  ## Parameters

    - email: User's email
    - password: User's password

  ## Examples

      User.login("user39023@discordapp.com","password")
      #=> {:ok, #PID<0.200.0>}
  """
  @spec login(String.t, String.t) :: map
  def login(email, password) do
    HTTPoison.start
    response = HTTPoison.post!("#{DiscordElixir.discord_url}/auth/login", {:form, [email: email, password: password]}, %{"Content-type" => "application/x-www-form-urlencoded"})
    data = response.body |> Poison.decode!
    cond do
      data["token"] -> DiscordElixir.RestClient.start_link(%{token: data["token"]})
               true -> {:error, data}
    end
  end

  @doc """
  User logout which kills the connection process

  ## Parameters

    - conn: User connection for REST holding auth info

  ## Examples

      User.logout(conn)
      #=> :ok
  """
  @spec logout(pid) :: atom
  def logout(conn) do
    response = DiscordElixir.RestClient.resource(conn, :post, "/auth/logout")
    case response do
      :invalid ->
        Process.exit(conn, "Logout")
        :ok
      _ -> :error
    end
  end

  @doc """
  Query users with results from mutual guilds

  ## Parameters

    - conn: User connection for REST holding auth info
    - username: Nick of user who you are looking up
    - limit: How many results to return. (default: 25)

  ## Examples

      User.query(conn, username, limit)
  """
  @spec query(pid, String.t, number) :: list
  def query(conn, username, limit \\ 25) do
    DiscordElixir.RestClient.resource(conn, :get, "users", %{q: username, limit: limit})
  end

  @doc """
  Get currrent user

  ## Parameters

    - conn: User connection for REST holding auth info

  ## Examples

      User.current(conn)
  """
  @spec current(pid) :: map
  def current(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me")
  end

  @doc """
  Get user data for a specific user id

  ## Parameters

    - conn: User connection for REST holding auth info
    - user_id: User ID

  ## Examples

      User.get(conn, user_id)
  """
  @spec get(pid, number) :: map
  def get(conn, user_id) do
    DiscordElixir.RestClient.resource(conn, :get, "users/#{user_id}")
  end

  @doc """
  Modify the current user

  ## Parameters

    - conn: User connection for REST holding auth info
    - options: Updateable options which include (username, avatar) and email, password.

  ## Examples

      User.modify(conn, options)
  """
  @spec modify(pid, map) :: map
  def modify(conn, options) do
    email     = options[:email]
    password  = options[:password]
    username  = options[:username]
    avatar    = options[:avatar]
    DiscordElixir.RestClient.resource(conn, :patch, "users/@me", %{username: username, avatar: avatar, email: email, password: password})
  end

  @doc """
  Current user guilds

  ## Parameters

    - conn: User connection for REST holding auth info

  ## Examples

      User.guilds(conn)
  """
  @spec guilds(pid) :: list
  def guilds(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me/guilds")
  end

  @doc """
  Leave guild

  ## Parameters

    - conn: User connection for REST holding auth info
    - guild_id: The identifier for the guild in which the user wishes to leave

  ## Examples

      User.guilds(conn, guild_id)
  """
  @spec leave_guild(pid, number) :: nil
  def leave_guild(conn, guild_id) do
    response = DiscordElixir.RestClient.resource(conn, :delete, "users/@me/guilds/#{guild_id}")
    case response do
      :invalid -> :ok
            _  -> :error
    end
  end

  @doc """
  Get user direct message channels

  ## Parameters

    - conn: User connection for REST holding auth info

  ## Examples

      User.dm_channels(conn)
  """
  @spec dm_channels(pid) :: map
  def dm_channels(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me/channels")
  end

  @doc """
  Create direct message channel for user

  ## Parameters

    - conn: User connection for REST holding auth info
    - recipient_id: The user id in which a direct message channel should be open

  ## Examples

      User.create_dm_channel(conn, recipient_id)
  """
  @spec create_dm_channel(pid, number) :: map
  def create_dm_channel(conn, recipient_id) do
    DiscordElixir.RestClient.resource(conn, :post, "users/@me/channels", %{recipient_id: recipient_id})
  end

  @doc """
  Get all user connections

  ## Parameters

    - conn: User connection for REST holding auth info

  ## Examples

      User.connections(conn)
  """
  @spec connections(pid) :: list
  def connections(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me/connections")
  end
end
