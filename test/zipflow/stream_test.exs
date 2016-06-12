defmodule Zipflow.StreamTest do
  use ExUnit.Case, async: true

  alias Zipflow.Stream
  alias Zipflow.DataEntry
  alias Zipflow.FileEntry

  setup do
    {:ok, dev} = StringIO.open("")

    readdev = fn -> case StringIO.contents(dev) do
                      {"", data} -> data
                    end
              end

    {:ok, %{readdev: readdev, printer: &IO.binwrite(dev, &1)}}
  end

  test "stream data_entry", %{readdev: readdev, printer: printer} do
    rnddata = :rand.uniform |> Float.to_string
    Stream.init
    |> Stream.entry(DataEntry.encode(printer, "foobar", rnddata))
    |> Stream.flush(printer)

    assert {:ok, [{'foobar', rnddata}]} == :zip.extract(readdev.(), [:memory])
  end

  test "stream file_entry", %{readdev: readdev, printer: printer} do
    path     = __ENV__.file
    data     = File.read!(path)
    {:ok, _} = File.open(path, [:read, :raw, :binary], fn fh ->
      Stream.init
      |> Stream.entry(FileEntry.encode(printer, "foobar", fh))
      |> Stream.flush(printer)
    end)

    assert {:ok, [{'foobar', data}]} == :zip.extract(readdev.(), [:memory])
  end

end
