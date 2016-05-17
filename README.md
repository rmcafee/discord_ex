# Discord Elixir

Discord library for Elixir. I needed it and figured I'd share.

This library is useful for making calls and implementing a bot as well.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add discord_elixir to your list of dependencies in `mix.exs`:

        def deps do
          [{:discord_elixir, "~> 1.0.0"}]
        end

  2. Ensure discord_elixir is started before your application:

        def application do
          [applications: [:discord_elixir]]
        end

  3. Look at the examples/echo_bot.ex file and you should honestly be
     good to go.

## REST Client Usage

The easy way to use discord resources is by doing the following.

	# alias the resource you wish to use to make it easy on yourself
	
	alias DiscordElixir.RestClient.Resources.User
	
	# Establish a connection
	{:ok, connection} = User.login("<username>","<password>")
	
	# Call on the resource and reap the results
	
	User.guilds(connection)
	
If you like going the longer route and obtained your token already - you can use resources like this:
	
	# Create a connection
	token = "<your-token>"
	{:ok, conn} = DiscordElixir.RestClient.start_link(%{token: token})
	
	# Get to using the resource function for the rest client
	DiscordElixir.RestClient.resource(conn, :get, "users/@me/channels")

	# You can also user other method resources like 'post':
	DiscordElixir.RestClient.resource(conn, :post, "users/@me/channels", %{recipient_id: <recipient_id>})
	
The 'resource' function makes it a lot easier to use the library. The following methods are supported.

	DiscordElixir.RestClient.resource(conn, :get, <url>)
	DiscordElixir.RestClient.resource(conn, :post, <url>, <map-of-data>)
	DiscordElixir.RestClient.resource(conn, :put, <url>, <map-of-data>)
	DiscordElixir.RestClient.resource(conn, :patch, <url>, <map-of-data>)
	DiscordElixir.RestClient.resource(conn, :delete, <url>)


The following Resources are supported - you can look at their docs for examples and more information:

	alias DiscordElixir.RestClient.Resources.User
  [user-resource-doc](DiscordElixir.RestClient.Resources.User.html)

	User.login
	User.logout
	User.query
	User.current
	User.get
	User.modify
	User.guilds
	User.leave_guild
	User.create_dm_channel
	User.dm_channels
	User.connections




