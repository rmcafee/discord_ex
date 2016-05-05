defmodule DiscordElixir.RealtimeClient do
  @moduledoc """
  Connect to Discord to recieve and send data in realtime.
  """
  defmacro __using__(_) do
    quote do
      require Logger

      @opcodes %{
        :dispatch               => 0,
        :heartbeat              => 1,
        :identify               => 2,
        :status_update          => 3,
        :voice_status_udpate    => 4,
        :voice_server_ping      => 5,
        :resume                 => 6,
        :reconnect              => 7,
        :request_guild_members  => 8,
        :invalid_session        => 9
      }

      @behaviour :websocket_client_handler

      # Required Functions and Default Callbacks ( you shouldn't need to touch these to use client)
      def start_link(opts) do
        {:ok, rest_client} = DiscordElixir.RestClient.start_link(%{token: opts[:token]})
        opts = Map.put(opts, :rest_client, rest_client)

        :crypto.start()
        :ssl.start()
        :websocket_client.start_link(socket_url(opts), __MODULE__,opts)
      end

      def init(state, _socket) do
        {:ok, agent_seq_num} = Agent.start_link fn -> 0 end
        state = Map.put state, :agent_seq_num, agent_seq_num
        identify(state)
        {:ok, state}
      end

      def websocket_info(:start, _conn_state, state) do
        {:reply, {:text, "message received"}, state}
      end

      def websocket_terminate(reason, _conn_state, state) do
        Logger.info "Websocket closed in state #{inspect state} wih reason #{inspect reason}"
        Logger.info "Killing seq_num process!"
        Process.exit(state[:agent_seq_num], :kill)
        Logger.info "Killing rest_client process!"
        Process.exit(state[:rest_client], :kill)
        :ok
      end

      def websocket_handle({:binary, payload}, _socket, state) do
        data  = payload_decode({:binary, payload})
        event = normalize_atom(data.event_name)
        handle_event({event, data}, state)
      end

      def handle_event({:ready, payload}, state) do
        agent_update(state[:agent_seq_num], payload.seq_num)
        heartbeat_loop(state, payload.data.heartbeat_interval, self)
        {:ok, state}
      end

      def handle_event({event, payload}, state) do
        Logger.info "Received Event: #{event}"
        agent_update(state[:agent_seq_num], payload.seq_num)
        {:ok, state}
      end

      defp identify(state) do
        data = %{
          "token" => state[:token],
          "properties" => %{
            "$os" => "erlang-vm",
            "$browser" => "discord-elixir",
            "$device" => "discord-elixir",
            "$referrer" => "",
            "$referring_domain" => ""
          },
          "compress" => false,
          "large_threshold" => 250
        }

        payload = payload_build(opcode(:identify), data)
        :websocket_client.cast(self, {:binary, payload})
      end

      # Helper Functions
      @spec opcode(atom) :: integer
      def opcode(value) when is_atom(value) do
        @opcodes[value]
      end

      @spec opcode(integer) :: atom
      def opcode(value) when is_integer(value) do
        { k, _value } = Enum.find @opcodes, fn({_key, v}) -> v == value end
        k
      end


      # Sequence Tracking for Resuming and Heartbeat Tracking
      defp agent_value(agent) do
        Agent.get(agent, fn a -> a end)
      end

      defp agent_update(agent, n) do
        if n != nil do
          Agent.update(agent, fn _a -> n end)
        end
      end

      # Connection Heartbeat
      defp heartbeat_loop(state, interval, socket_process) do
        spawn_link(fn -> heartbeat(state, interval, socket_process) end)
        :ok
      end

      defp heartbeat(state, interval, socket_process) do
        value = agent_value(state[:agent_seq_num])
        payload = payload_build(opcode(:heartbeat), value)
        :websocket_client.cast(socket_process, {:binary, payload})
        :timer.sleep(interval)
        heartbeat_loop(state, interval, socket_process)
      end

      # Normalizers, Encoders, and Decoders
      defp normalize_atom(atom) do
        atom |> Atom.to_string |> String.downcase |> String.to_atom
      end

      defp payload_build(opcode, data, seq_num \\ nil, event_name \\ nil) do
        load = %{ "op" => opcode, "d" => data }
        if seq_num, do: load = Map.put(load, "s", seq_num)
        if event_name, do: load = Map.put(load, "t", event_name)
        load |> :erlang.term_to_binary
      end

      defp payload_decode({:binary, payload}) do
        payload = :erlang.binary_to_term(payload)
        %{op: opcode(payload[:op] || payload["op"]), data: (payload[:d] || payload["d"]), seq_num: (payload[:s] || payload["s"]), event_name: (payload[:t] || payload["t"])}
      end

      defp socket_url(opts) do
        version  = opts[:version] || 4
        url = DiscordElixir.RestClient.resource(opts[:rest_client], :get, "gateway")["url"]
        url = String.replace(url, "gg/", "")
        url = url <> "?v=#{version}&encoding=etf"
        url
      end
    end
  end
end
