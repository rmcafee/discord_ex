# Discord Elixir

Discord library for Elixir. I needed it and figured I'd share.

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

## Connect and use REST API Client with Token
  ```
  {:ok, conn} = DiscordElixir.RestClient.start_link(%{token: <your-token>})
  DiscordElixir.RestClient.resource(conn, :get, "users/@me")
  ```