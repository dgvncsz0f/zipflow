defmodule Zipflow.Stream do

  @moduledoc """
  high-level module to creat a zip archive.

  # example #

  this example streams the zip file to stdout. notice it uses
  `Zipflow.DataEntry` but any entry module will do
  [e.g. `Zipflow.FileEntry`]

  iex> alias Zipflow.DataEntry
  ...>
  ...> printer = &IO.binwrite/1
  ...>
  ...> Zipflow.Stream.init
  ...> |> Zipflow.Stream.entry(DataEntry.encode(printer, "foobar", "foobar"))
  ...> |> Zipflow.Stream.entry(DataEntry.encode(printer, "foobaz", "foobaz"))
  ...> |> Zipflow.Stream.flush(printer)
  """

  alias Zipflow.Spec.LFH
  alias Zipflow.Spec.CDH
  alias Zipflow.Spec.Entry

  @type entry     :: {LFH.t, Entry.t}
  @opaque context :: [entry]

  @doc """
  initializes the stream. notice that you must invoke `entry` at least
  once and possibly multiple times and `flush` exactly one time at the
  end.
  """
  @spec init :: context
  def init do
    []
  end

  @doc """
  includes an entry to this zip archive. refer to implementations of
  `Zipflow.Spec.Entry` like `Zipflow.DataEntry` or
  `Zipflow.FileEntry` for more information

  # example #

  iex> Zipflow.Stream.init
  ...> |> Zipflow.Stream.entry(ctx, Zipflow.DataEntry(&IO.binwrite/1, "foo", "bar"))
  """
  @spec entry(context, entry) :: context
  def entry(context, entry) do
    [entry | context]
  end

  @doc """
  terminates the stream by including the central directory header
  """
  @spec flush(context, (binary -> any)) :: any
  def flush(context, printer) do
    CDH.encode(printer, Enum.reverse(context))
  end

end
