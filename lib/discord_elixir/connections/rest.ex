defmodule DiscordElixir.Connections.REST do
  @moduledoc """
  Discord uses a rest API to send data to the API
  """
  use HTTPoison.Base

  def process_url(url) do
    DiscordElixir.discord_url <> url
  end

  "Overrides"

  defp standard_headers do
    %{
      "Content-Type" => "application/json",
      "User-Agent" => "DiscordBot (discord-elixir, 1.0)"
    }
  end

  defp process_request_headers(headers) when is_map(headers) do
    merged_headers = Map.merge(standard_headers, headers)
    Map.to_list(merged_headers)
  end

  defp process_request_headers(headers) do
    Map.to_list(standard_headers) ++ headers
  end

  defp process_request_body(body) do
    if body == "" do
      body
    else
      body |> Poison.encode!
    end
  end

  defp process_response_body(body) do
    case Poison.decode(body) do
             {:ok, res} -> res
      {:error, message} -> message
    end
  end
end
