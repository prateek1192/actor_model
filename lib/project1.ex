defmodule Server do
	def main(args) do
		args_parse = parse_args(args)

		case args_parse do
			[ip]   -> start_server(args_parse)
			[n,k]  -> Boss.main([n,k])
			[ip, n, k]  -> contact_client(args_parse)
		end
	end

	def contact_client([ip,n,k]) do
		Client.contact_server(ip,n,k)
	end

	def parse_args(args) when length(args) > 3 or length(args) <1 do
		IO.puts "Error in arguments"
		System.halt(0)
	end

	def parse_args(args) do
		case args do
			[ip, n, k] -> [ip, Boss.to_int(n), Boss.to_int(k)]
			[n,k] -> [Boss.to_int(n), Boss.to_int(k)]
			[ip] -> [ip]
		end
	end

	def start_server([ip]) do
		if(is_valid_ip(ip)) do
			IO.puts "Server Starting"
	 		_ = System.cmd("epmd", ["-daemon"])
			isStarted = Node.start String.to_atom("server_node@"<>ip)
			case isStarted do
			{:ok, _} ->
			IO.puts "Server started"
			:global.register_name("server", self())
			receiver()
			{_, _} ->
			IO.puts("Failed to start server")
			end
		else
			IO.puts "Error starting the sever"
		end
	end

	def is_valid_ip(ip) do
		true
	end

	def receiver() do
		receive do
			{:request, n, k, client_node} ->
				Node.spawn(client_node, Boss, :main, [[n, k]])
		end
		receiver()
	end
end

defmodule Client do
	def contact_server(ip, n ,k) do
		id = :rand.uniform(100)
		client_node = String.to_atom("client_node"<>to_string(id)<> "@127.0.0.1")
		_ = System.cmd("epmd", ["-daemon"])

		{:ok, _} = Node.start client_node
		:global.register_name("client", self())
		b = Node.connect(String.to_atom("server_node@"<>ip))

		if b do
			:global.sync()
			:global.registered_names()
      Client.request_work(n,k)
			true
		else
			IO.puts "failed to connect to head_node"
			false
		end
	end

	def request_work(n,k) do
		pid = :global.whereis_name("server")
		send(pid, {:request, n,k, Node.self()})
		receiver()
	end

	def receiver do
		receive do
			{:start_point, first} -> IO.puts(first)
				receiver()
			{:complete} -> IO.puts "Completed"
											System.halt(0)
		end
	end
end
