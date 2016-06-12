defmodule Zipflow.Spec.LFHTest do
  use ExUnit.Case, async: true

  alias Zipflow.Spec.LFH

  test "encode return handle" do
    name   = :rand.uniform |> Float.to_string
    handle = LFH.encode(fn x -> assert is_binary(x) end, name)

    assert is_binary handle[:name]
    assert is_integer handle[:size]
    assert is_integer handle[:n_size]
  end

end
