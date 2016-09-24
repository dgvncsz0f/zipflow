defmodule Zipflow.StreamTest do
  use ExUnit.Case, async: true

  alias Zipflow.Stream
  alias Zipflow.DataEntry
  alias Zipflow.FileEntry

  import Test.Zipflow.Support.Helpers

  test "stream data_entry" do
    ramdev fn contents, printer ->
      rnddata = :rand.uniform |> Float.to_string

      Stream.init
      |> Stream.entry(DataEntry.encode(printer, "foobar", rnddata))
      |> Stream.flush(printer)

      assert {:ok, [{'foobar', rnddata}]} == :zip.extract(contents.(), [:memory])
    end
  end

  test "stream file_entry" do
    ramdev fn contents, printer ->
      path = __ENV__.file
      data = File.read!(path)

      {:ok, _} = File.open(path, [:read, :raw, :binary], fn fh ->
        Stream.init
        |> Stream.entry(FileEntry.encode(printer, "foobar", fh))
        |> Stream.flush(printer)
      end)

      assert {:ok, [{'foobar', data}]} == :zip.extract(contents.(), [:memory])
    end
  end

end
