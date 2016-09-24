defmodule Zipflow.Spec.Entry do

  @moduledoc """
  Represents an entry in a zip archive. For example, the `StoreEntry`
  module is used to include entries with no compression.

  The basic usage will be `init` followed by one or more `update` and
  then finally `finalize`
  """

  @type t :: %{crc: integer, size: non_neg_integer, csize: non_neg_integer, usize: non_neg_integer, private: any}

  @doc """
  Initializes the entry. You must provide the 'output' function.
  """
  @callback init((binary -> ())) :: t

  @doc """
  add data to this entry. this function may be invoked multiple times
  as long as you sequence the return values properly.
  """
  @callback data(t, bitstring) :: t

  @doc """
  finalize this entry. the return value must be kept as it is
  necessary to build the central directory header.
  """
  @callback term(t) :: t

end
