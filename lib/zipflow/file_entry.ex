defmodule Zipflow.FileEntry do

  @moduledoc """
  a zip archive entry that reads from a file handle.
  """

  alias Zipflow.Spec.LFH
  alias Zipflow.Spec.Entry
  alias Zipflow.Spec.StoreEntry

  defp loop(ctx, fh) do
    case IO.binread(fh, 4096) do
      :eof                      -> ctx
      data when is_binary(data) -> loop(StoreEntry.data(ctx, data), fh)
      error                     -> error
    end
  end

  @doc """
  adds an entry from a file handle. the file mode when opening should
  be at least `[:read, :binary]` or if possible `[:read, :binary,
  :raw]`. it will read the file completely, in chunks, before
  returning to the caller.

  # example #

  this example adds an entry name `foobar` from hypothetical file stored
  at `/foo/bar`:

  ```
  iex> File.open("/foo/bar", [:read, :raw, :binary], fn fh ->
    Zipflow.FileEntry.encode(&IO.binwrite/1, "foobar", fh)
  end)
  ```
  """
  @spec encode((binary -> ()), String.t, File.io_device) :: {LFH.t, Entry.t} | {:error, String.t}
  def encode(printer, name, fh) do
    header = LFH.encode(printer, name)
    StoreEntry.init(printer)
    |> loop(fh)
    |> case do
         {:error, reason} -> {:error, reason}
         context          -> {header, StoreEntry.term(context)}
       end
  end

end
