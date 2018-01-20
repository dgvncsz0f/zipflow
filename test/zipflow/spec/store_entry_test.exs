defmodule Zipflow.Spec.StoreEntryTest do
  use ExUnit.Case, async: true

  alias Zipflow.Spec.StoreEntry

  test "encode return handle" do
    handle = StoreEntry.init(fn x -> assert is_binary(x); nil end)
    |> StoreEntry.term

    assert is_integer(handle[:crc])
    assert is_integer(handle[:size])
    assert is_integer(handle[:usize])
    assert is_integer(handle[:csize])
  end

end
