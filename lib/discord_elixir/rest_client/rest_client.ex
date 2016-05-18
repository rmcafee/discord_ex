defmodule DiscordElixir.RestClient do
  @moduledoc """
  Discord RestClient. Used a GenServer so that you can have multiple
  clients in one application.
  """
  use GenServer

  alias DiscordElixir.Connections.REST

  @typedoc """
  Response body with  related options
  """
  @type request_reply :: {atom, map, map}

  # GenServer API

  @doc """
  Start process and HTTP Client.
  {:ok, conn} = DiscordElixir.RestClient.start_link(%{token: token})
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  @spec resource(pid, atom, String.t, map) :: request_reply
  def resource(connection, method, path, payload \\ nil) do
    GenServer.call connection, {:resource, method, path, payload}
  end

  # Server Callbacks

  def init(:ok, opts) do
    REST.start
    opts
  end

  def handle_call({:resource, :get, path, nil}, _from, opts) do
    response = REST.get!("/#{path}",%{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :get, path, payload}, _from, opts) do
    response = REST.get!("/#{path}", %{"Authorization" => opts.token}, params: payload)
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :post, path, nil}, _from, opts) do
    response = REST.post!("/#{path}", %{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :post, path, payload}, _from, opts) do
    response = REST.post!("/#{path}", payload, %{"Authorization" => opts.token, "Content-Type" => "application/json"})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :post_multipart, path, payload}, _from, opts) do
    payload_no_file = payload
                      |> Map.drop([:file])
                      |> _map_atom_to_string
                      |> Enum.into(Keyword.new)

    file_formatted = _format_file(payload[:file])
    combined_data = Enum.concat(payload_no_file, file_formatted)

    response = REST.post!("/#{path}", {:multipart, combined_data}, %{"Authorization" => opts.token, "Content-type" => "multipart/form-data"})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :patch_form, path, payload}, _from, opts) do
    response = REST.patch!("/#{path}", {:form, Enum.into(payload, Keyword.new)}, %{"Authorization" => opts.token, "Content-type" => "application/x-www-form-urlencoded"})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :patch, path, payload}, _from, opts) do
    response = REST.patch!("/#{path}", payload, %{"Authorization" => opts.token, "Content-type" => "application/json"})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :put, path, payload}, _from, opts) do
    response = REST.put!("/#{path}", payload, %{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :delete, path, nil}, _from, opts) do
    response = REST.delete!("/#{path}",%{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end

  defp _format_file(file_path) do
    filename_full = file_path |> String.split("/") |> List.last
    filename = filename_full |> String.split(".") |> List.first
    [
      {:file, file_path, {["form-data"], [name: filename, filename: filename_full]},[]}
    ]
  end

  defp _map_atom_to_string(atom_key_map) do
    for {key, val} <- atom_key_map, into: %{}, do: {Atom.to_string(key), val}
  end
end
