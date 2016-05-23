# Discord Elixir

Discord library for Elixir. I needed it and figured I'd share.

This library is useful for making calls and implementing a bot as well.

Please always use [Discord Developer Docs](https://discordapp.com/developers/docs) as a reference.

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

## Realtime/Bot Client Usage

So you want to create a bot huh? Easy peezy.

1) Create a bot with a default handler to handle any event:

  	# Default Fallback Handler for all events!
  	# This way things don't blow up when you get an event you
  	# have not set up a handler for.

  	def handle_event({event, _payload}, state) do
      IO.puts "Received Event: #{event}"
      {:ok, state}
  	end

2) Setup an event handler to handle whatever event you want:
  	
  	def handle_event({:message_create, payload}, state) do
   	  # Your stuff happens here # 
      {:ok, state}
  	end

3) Now to start your client it is as easy as:

	{:ok, bot_client } = DiscordElixir.Client.start_link(%{
		token: <token>,
		handler: YourBotNameHere
	})

Alright you are done. Go forth and prosper!

**As a note your bot_client is a gen_server that will have state properties that contain:**
	
**:rest_client** - you can use this process to make calls without having to setup another rest client connection. So in your callback you can do this in your callback with ease:

	alias DiscordElixir.RestClient.Resources.User
	
	User.current(state[:rest_client])

## Voice Client Usage

To create a voice room just connect voice information to your bot.

1) Create the bot with connection preferences.

	{:ok, client} = DiscordElixir.Client.start_link(%{token: <token>, 
												       voice: %{
												         guild_id: <guild_id>,
												         channel_id: <channel_id>
												       }})
												       
This will move your bot into the proper channel and attach the "voice_client" pid to the client's state.

2) You can also create the connection with a bot attachment.

	{:ok, client} = DiscordElixir.Client.start_link(%{token: <token>,
											           handler: YourBotNameHere,
												       voice: %{
												         guild_id: <guild_id>,
												         channel_id: <channel_id>
												       }})


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


** The following Resources are supported - you can look at their docs for examples and more information: **
  ----

  	alias DiscordElixir.RestClient.Resources.Channel

	Channel.bulk_delete_messages/3
	Channel.create_invite/3
	Channel.delete/2
	Channel.delete_message/3
	Channel.delete_permissions/3
	Channel.edit_permissions/4
	Channel.get/2
	Channel.get_invites/2
	Channel.messages/2
	Channel.modify/3
	Channel.send_file/3
	Channel.send_message/3
	Channel.trigger_typing/2
	Channel.update_message/4
	
[channel-resource-doc](DiscordElixir.RestClient.Resources.Channel.html)

  ----
  
  	alias DiscordElixir.RestClient.Resources.Guild

	Guild.ban_member/4
	Guild.bans/2
	Guild.batch_modify_roles/3
	Guild.begin_prune/3
	Guild.channels/2
	Guild.create/2
	Guild.create_channel/3
	Guild.create_empty_role/2
	Guild.create_integration/3
	Guild.delete/2
	Guild.delete_integration/3
	Guild.delete_role/3
	Guild.embed/2
	Guild.get/2
	Guild.integrations/2
	Guild.invites/2
	Guild.kick_member/3
	Guild.member/3
	Guild.members/3
	Guild.modify/3
	Guild.modify_embed/2
	Guild.modify_integration/4
	Guild.modify_member/4
	Guild.modify_role/4
	Guild.prune_count/3
	Guild.roles/2
	Guild.sync_integration/3
	Guild.unban_member/3
	Guild.voice_regions/2

[guild-resource-doc](DiscordElixir.RestClient.Resources.Guild.html)

  ----

	alias DiscordElixir.RestClient.Resources.Image

  	Image.avatar_url/2
  	Image.icon_url/2

[image-resource-doc](DiscordElixir.RestClient.Resources.Image.html)

  ----

  	alias DiscordElixir.RestClient.Resources.Invite

	Invite.accept/2
	Invite.delete/2
	Invite.get/2

[invite-resource-doc](DiscordElixir.RestClient.Resources.Invite.html)

  ----

  	alias DiscordElixir.RestClient.Resources.User

	User.connections/1
	User.create_dm_channel/2
	User.current/1
	User.dm_channels/1
	User.get/2
	User.guilds/1
	User.leave_guild/2
	User.login/2
	User.logout/1
	User.modify/2
	User.query/3

[user-resource-doc](DiscordElixir.RestClient.Resources.User.html)


