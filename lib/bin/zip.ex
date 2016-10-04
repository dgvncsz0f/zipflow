defmodule Zip do

  alias Zipflow.OS
  alias Zipflow.Stream

  def main([output, directory]) do
    File.open(output, [:raw, :binary, :write], fn fh ->
      printer = & IO.binwrite(fh, &1)
      Stream.init
      |> OS.dir_entry(printer, directory)
      |> Stream.flush(printer)
    end)
  end

end
