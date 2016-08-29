defmodule DiscordEx.Voice.Encoder do
  @moduledoc """
  Voice Encoder
  """
  alias Porcelain.Process, as: Proc

  @doc "Encode audio file to proper format"
  @spec encode_file(String.t, map) :: binary
  def encode_file(file_path, opts) do
    dca_rs_path = Application.get_env(:discord_ex, :dca_rs_path)
    %Proc{out: audio_stream} = Porcelain.spawn(dca_rs_path,["--vol","#{opts[:volume]}","--ac","2","--ar","48000","--as","960","--ab","128","--raw","-i","#{file_path}"],[out: :stream])
    audio_stream
  end
end
