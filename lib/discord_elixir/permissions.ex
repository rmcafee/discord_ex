defmodule DiscordElixir.Permissions do
  @moduledoc """
  Easily assign permissions with this helper module.
  """
  use Bitwise

  @flags %{
    0 => :create_instant_invite, # 1
    1 => :kick_members,          # 2
    2 => :ban_members,           # 4
    3 => :manage_roles,          # 8,
    4 => :manage_channels,       # 16
    5 => :manage_server,         # 32
    10 => :read_messages,        # 1024
    11 => :send_messages,        # 2048
    12 => :send_tts_messages,    # 4096
    13 => :manage_messages,      # 8192
    14 => :embed_links,          # 16384
    15 => :attach_files,         # 32768
    16 => :read_message_history, # 65536
    17 => :mention_everyone,     # 131072
    20 => :connect,              # 1048576
    21 => :speak,                # 2097152
    22 => :mute_members,         # 4194304
    23 => :deafen_members,       # 8388608
    24 => :move_members,         # 16777216
    25 => :use_voice_activity    # 33554432
  }

  @doc "Add any permission to an existing set of permissions and return the complete permission value."
  @spec add(integer, atom) :: integer
  def add(existing_permissions \\ 0, new_permission) do
    permission = perm_to_value(new_permission)
    existing_permissions |> bor(permission)
  end

  @doc "Remove any permission from an existing set of permissions and return updated value."
  @spec remove(integer, atom) :: integer
  def remove(existing_permissions, new_permission) do
    permission = perm_to_value(new_permission)
    existing_permissions |> band(bnot(permission))
  end

  @doc "Take current permission value and convert it to a map of permissions."
  @spec to_map(integer) :: map
  def to_map(permissions) do
    Enum.into @flags, %{}, fn(val) ->
      { v, k } = val
      value = permissions |> bsr(v) |> band(0x1)
      { k, value == 1 }
    end
  end

  @spec perm_to_value(atom) :: integer
  defp perm_to_value(permission_key) do
    { value, _ } = Enum.find @flags,
      fn({_k, v}) -> v == permission_key
    end
    bsl(1,value)
  end
end
