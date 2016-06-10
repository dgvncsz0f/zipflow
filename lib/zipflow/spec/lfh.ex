defmodule Zipflow.Spec.LFH do
  @type t :: %{size: integer, name: String.t, n_size: integer}


  @moduledoc """
  the very first entry of a zip archive. each entry in a zip file has
  a local file header which defines, among other things, the entry
  name. usually you don't have to use it as the *Entry modules
  [e.g. DataEntry] are easier to use.
  """

  @doc """
  encodes a local file header section. notice that you must keep the
  return value and use them, in order, to generate the central
  directory header.
  """
  @spec encode((binary -> ()), String.t) :: t
  def encode(printer, name) do
    nsize = byte_size(name)
    frame = <<
      0x04034b50 :: size(32)-little,  # local file header signature
      0x0a       :: size(16)-little,  # version needed to extract
      8          :: size(16)-little,  # general purpose bit flag
      0          :: size(16)-little,  # compression method
      0          :: size(16)-little,  # last mod time
      0          :: size(16)-little,  # last mod date
      0          :: size(32)-little,  # crc-32
      0          :: size(32)-little,  # compressed size
      0          :: size(32)-little,  # uncompressed size
      nsize      :: size(16)-little,  # file name length
      0          :: size(16)-little,  # extra field length
      name       :: binary
    >>
    printer.(frame)
    %{size: byte_size(frame), name: name, n_size: nsize}
  end

end
