defmodule DiscordEx.Connections.REST do
  @moduledoc """
  Discord uses a REST interface to send data to the API.
  """
  use HTTPoison.Base

  def process_url(target_url) do
    DiscordEx.discord_url <> target_url
  end

  #Overrides

  defp standard_headers do
    %{
      "User-Agent" => "DiscordBot (discord-ex, 1.1.4)"
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
    case body do
           {:form, _} -> body
      {:multipart, _} -> body
                   "" -> body
                    _ -> Poison.encode!(body)

    end
  end

  defp process_response_body(body) do
    case Poison.decode(body) do
             {:ok, res} -> res
      {:error, message} -> message
    end
  end
end
