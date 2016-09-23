defmodule Zipflow.DataEntry do

  @moduledoc """
  a zip archive entry that fits in memory. if you have large data to
  store you may use `Zipflow.Spec.StoreEntry` directly.

  # example #

  the following example adds an entry with name and value set to
  `foobar`.

  ```
  iex> Zipflow.DataEntry.encode(&IO.binwrite/1, "foobar", "foobar")
  ```
  """

  alias Zipflow.Spec.LFH
  alias Zipflow.Spec.Entry
  alias Zipflow.Spec.StoreEntry

  @doc """
  Add a entry to a zip archive. the name of the entry is given by the
  `name` argument and the contents goes into `data`. Notice you
  shouldn't use this to store large data. Consider using
  `Zipflow.Spec.StoreEntry` directly.
  """
  @spec encode((binary -> ()), String.t, bitstring) :: {LFH.t, Entry.t}
  def encode(printer, name, data) do
    header  = LFH.encode(printer, name)
    payload = StoreEntry.init(printer)
    |> StoreEntry.data(data)
    |> StoreEntry.term
    {header, payload}
  end

end
