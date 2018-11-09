defmodule Boss do
  def main(args) do
    tuple = parse_args(args)
	  Boss.helper(tuple)
	  |> IO.inspect
  #end_program()
  end

  def parse_args(args) do
	   case args do
	      [n,k] -> {n, k ,0}
  	end
  end

  def to_int(s) do
    {i, _} = Integer.parse(s)
    i
  end

  def helper({n,k,offset}) when n <= 590 do
    process((590*offset+1)..(590*offset+n), k)
  end

  def helper({n,k,offset}) do
    process((590*offset+1)..(590*offset+590), k)
    helper({n-590, k, offset+1})
  end

  def process(n,k) do
    range_list = Enum.map(n, fn (x) -> x..x+k-1 end)
    pid_list = Enum.map(n, fn (x) -> spawn(Worker,:listen_messages, []) end)
    range_pid = Enum.zip(pid_list, range_list)
    Enum.each(range_pid, fn {x, y} -> send(x, {self(), y}) end)
    listen_messages(length(range_list))
  end

  def end_program() do
    cond do
       :undefined == :global.whereis_name("client") -> :completed
       pid = :global.whereis_name("client") -> send(pid,{:complete})
     end
  end

  def listen_messages(count) do
  if count > 0 do
		receive do
		  {true, first..last} ->
        cond do
          :undefined == :global.whereis_name("client") -> :ok
  		    pid = :global.whereis_name("client") -> send(pid,{:start_point, first})
        end
        IO.puts ("value #{first}")
		    listen_messages(count-1)
		  {false, first..last} ->
		    listen_messages(count-1)
		end
	end
  :completed
end

end


defmodule Worker do
  def listen_messages() do
    receive do
      {sender, range } -> send(sender,
      {calculate_squares(range) |> check_perfect_square, range})
      true -> IO.puts "Here"
    end
  end
## calcuate squares
  def calculate_squares(range) do
    Enum.reduce(range, 0 , fn(x, acc) -> x*x + acc end)
  end
  ## TODO: calculate Perfect Squares
  def check_perfect_square(value) do
      import :math
      (sqrt(value) - floor(sqrt(value))) == 0
  end
end
