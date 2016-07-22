defmodule DiscordEx.RestClient.Resources.Image do
  @moduledoc """
  Convience helper for images
  """

  @doc """
  Get the guild icon URL

  ## Parameters

    - server_id: The server_id to retrieve the icon URL for
    - icon_id: The icon_id for the user to retrieve the icon URL for

  ## Examples

      Image.icon_url("99999999993832","f3e8329c329020329")
  """
  @spec icon_url(String.t, String.t) :: String.t
  def icon_url(server_id, icon_id) do
    "#{DiscordEx.discord_url}/guilds/#{server_id}/icons/#{icon_id}.jpg"
  end

  @doc """
  Get the user avatar URL

  ## Parameters

    - user_id: The user_id to retrieve the avatar URL for
    - avatar_id: The avatar_id for the user to retrieve the avatar URL for

  ## Examples

      Image.avatar_url("99999999993832","f3e8329c329020329")
  """
  @spec avatar_url(String.t, String.t) :: String.t
  def avatar_url(user_id, avatar_id) do
    "#{DiscordEx.discord_url}/users/#{user_id}/avatars/#{avatar_id}.jpg"
  end
end
