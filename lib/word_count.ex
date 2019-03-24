defmodule WordCount do
  @doc ~s"""

      iex> 1
      1
  """
  def eager_count(file) do
    File.read!(file)
    |> String.split("\n")
    |> Enum.flat_map(&String.split(&1, " "))
    |> Enum.reduce(%{}, fn word, acc ->
      Map.update(acc, word, 1, &(&1 + 1))
    end)
  end

  def lazy_count(file) do
    File.stream!(file, [], :line)
    |> Stream.flat_map(&String.split(&1, " "))
    |> Enum.reduce(%{}, fn word, acc ->
      Map.update(acc, word, 1, &(&1 + 1))
    end)
  end

  def concurrent_count(file) do
    File.stream!(file)
    |> Flow.from_enumerable()
    |> Flow.flat_map(&String.split(&1, " "))
    |> Flow.partition()
    |> Flow.reduce(fn -> %{} end, fn word, acc ->
      Map.update(acc, word, 1, &(&1 + 1))
    end)
    |> Enum.to_list()
  end

  @doc """
  Example usage (not a doc test!). These are results on a machine with 4 cores,
  so the expected speed-up of the concurrent implementation is around 4
  WordCount.time(&WordCount.eager_count/1, file)
  "Total number of words: 4999193. Calculation took 5719.693ms"
  file = "/Users/ivan/big.txt"
  "/Users/ivan/big.txt"
  WordCount.time(&WordCount.concurrent_count/1, file)
  "Calculation took 1299.879ms"
  WordCount.time(&WordCount.lazy_count/1, file)
  "Total number of words: 4999193. Calculation took 4830.532ms"
  "Concurrent count is #{5739 / 1299} times faster than eager"
  "Concurrent count is 4.4 times faster than eager"
  "Concurrent count is #{4830 / 1299} times faster than lazy"
  "Concurrent count is 3.7 times faster than lazy"
  """
  def time(fun, file) when is_function(fun, 1) do
    {t, counts} = :timer.tc(fn -> fun.(file) end)
    total_words = Enum.reduce(counts, 0, fn {_, count}, counter -> count + counter end)
    "Total number of words: #{total_words}. Calculation took #{t / 1000}ms"
  end
end
