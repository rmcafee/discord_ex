defmodule DiscordElixir.RestClient.Resources.Invite do
  @moduledoc """
  Convience helper for invites
  """

  @doc """
  Get invite object

  ## Parameters

    - conn: User connection for REST holding auth info
    - invite_id: Invite id

  ## Examples

      Invite.get(conn, "99999999993832")
  """
  @spec get(pid, String.t) :: map
  def get(conn, invite_id) do
    DiscordElixir.RestClient.resource(conn, :get, "invites/#{invite_id}")
  end

  @doc """
  Delete invite object

  Requires the MANAGE_CHANNELS permission. Returns an invite object on success.

  ## Parameters

    - conn: User connection for REST holding auth info
    - invite_id: Invite id

  ## Examples

      Invite.delete(conn, "99999999993832")
  """
  @spec delete(pid, String.t) :: map
  def delete(conn, invite_id) do
    DiscordElixir.RestClient.resource(conn, :delete, "invites/#{invite_id}")
  end

  @doc """
  Accept invite

  Accept an invite. This is not available to bot accounts, and requires the guilds.join OAuth2 scope to accept on behalf of normal users.

  ## Parameters

    - conn: User connection for REST holding auth info
    - invite_id: Invite id

  ## Examples

      Invite.accept(conn, "99999999993832")
  """
  @spec accept(pid, String.t) :: map
  def accept(conn, invite_id) do
    DiscordElixir.RestClient.resource(conn, :post, "invites/#{invite_id}")
  end
end
