defmodule DiscordEx.PermissionsTest do
  use ExUnit.Case
  doctest DiscordEx.Permissions

  alias DiscordEx.Permissions

  test "permissions are added correctly" do
    permissions =
      Permissions.add(:create_instant_invite)
      |> Permissions.add(:connect)
      |> Permissions.add(:speak)
      |> Permissions.add(:move_members)

    assert permissions == 19922945
  end

  test "permissions can be removed correctly" do
    permissions =
      Permissions.add(:create_instant_invite)
      |> Permissions.add(:connect)
      |> Permissions.add(:speak)
      |> Permissions.add(:move_members)
      |> Permissions.remove(:speak)
      |> Permissions.remove(:move_members)
      |> Permissions.remove(:create_instant_invite)

    assert permissions == 1048576
  end

  test "duplicate permissions don't alter final result" do
    permissions =
      Permissions.add(:deafen_members)
      |> Permissions.add(:deafen_members)
      |> Permissions.add(:connect)
      |> Permissions.add(:deafen_members)
      |> Permissions.add(:connect)

      assert permissions == 9437184
  end

  test "current permissions can be converted into a state map" do
    permissions =
      Permissions.add(:deafen_members)
      |> Permissions.add(:connect)
      |> Permissions.add(:read_messages)
      |> Permissions.add(:send_messages)
      |> Permissions.add(:embed_links)

    perm_map = Permissions.to_map(permissions)
    assert perm_map[:deafen_members]
    assert perm_map[:connect]
    assert perm_map[:read_messages]
    assert perm_map[:send_messages]
    assert perm_map[:embed_links]

    refute perm_map[:speak]
    refute perm_map[:move_members]
    refute perm_map[:create_instant_invite]
  end
end
