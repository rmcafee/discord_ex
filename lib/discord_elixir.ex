defmodule DiscordEx do
  @moduledoc """
  Base Discord Elixir Module
  """

  @doc "Discord API URL"
  @spec discord_url :: String.t
  def discord_url do
    "https://discordapp.com/api"
  end

  @doc "Discord Bot Authorization URL"
  @spec bot_auth_url(number, number) :: String.t
  def bot_auth_url(client_id, permissions) do
    "https://discordapp.com/oauth2/authorize?client_id=#{client_id}&scope=bot&permissions=#{permissions}"
  end
end
