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

  @doc "logout user"
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

  @doc "query users in mutual guilds"
  @spec query(pid, String.t, number) :: list
  def query(conn, username, limit \\ 25) do
    DiscordElixir.RestClient.resource(conn, :get, "users", %{q: username, limit: limit})
  end

  @doc "get current user"
  @spec current(pid) :: map
  def current(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me")
  end

  @doc "get user for a given user id"
  @spec get(pid, number) :: map
  def get(conn, user_id) do
    DiscordElixir.RestClient.resource(conn, :get, "users/#{user_id}")
  end

  @doc "modify the current user"
  @spec modify(pid, map) :: map
  def modify(conn, options) do
    email     = options[:email]
    password  = options[:password]
    username  = options[:username]
    avatar    = options[:avatar]
    DiscordElixir.RestClient.resource(conn, :patch, "users/@me", %{username: username, avatar: avatar, email: email, password: password})
  end

  @doc "get current user guilds"
  @spec guilds(pid) :: list
  def guilds(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me/guilds")
  end

  @doc "leave guild"
  @spec leave_guild(pid, number) :: nil
  def leave_guild(conn, guild_id) do
    response = DiscordElixir.RestClient.resource(conn, :delete, "users/@me/guilds/#{guild_id}")
    case response do
      :invalid -> :ok
            _  -> :error
    end
  end

  @doc "get user direct messages"
  @spec dm_channels(pid) :: map
  def dm_channels(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me/channels")
  end

  @doc "create a direct message channel"
  @spec create_dm_channel(pid, number) :: map
  def create_dm_channel(conn, recipient_id) do
    DiscordElixir.RestClient.resource(conn, :post, "users/@me/channels", %{recipient_id: recipient_id})
  end

  @doc "get all user connections"
  @spec connections(pid) :: list
  def connections(conn) do
    DiscordElixir.RestClient.resource(conn, :get, "users/@me/connections")
  end
end
