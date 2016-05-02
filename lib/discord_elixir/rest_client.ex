defmodule DiscordElixir.RestClient do
  @moduledoc """
  Discord RestClient server. Used a GenServer so that you can have multiple
  clients in one application.
  """
  use GenServer

  alias DiscordElixir.Connections.REST

  # GenServer API

  @doc """
  Start process and HTTP Client.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def resource(connection,  method, res, payload \\ nil) do
    GenServer.call connection, {:resource, method, res, payload}
  end

  # Server Callbacks

  def init(:ok, opts) do
    REST.start
    opts
  end

  def handle_call({:resource, :get, res, nil}, _from, opts) do
    response = REST.get!("/#{res}",%{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :post, res, payload}, _from, opts) do
    response = REST.post!("/#{res}", payload, %{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :patch, res, payload}, _from, opts) do
    response = REST.patch!("/#{res}", payload)
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :put, res, payload}, _from, opts) do
    response = REST.put!("/#{res}", payload)
    {:reply, response.body, opts}
  end

  def handle_call({:resource, :delete, res, nil}, _from, opts) do
    response = REST.delete!("/#{res}",%{"Authorization" => opts.token})
    {:reply, response.body, opts}
  end
end
