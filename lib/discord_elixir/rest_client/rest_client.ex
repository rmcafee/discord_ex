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

  def handle_call({:resource, :patch, path, payload}, _from, opts) do
    response = REST.patch!("/#{path}", {:form, Enum.into(payload, Keyword.new)}, %{"Authorization" => opts.token, "Content-type" => "application/x-www-form-urlencoded"})
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
end
