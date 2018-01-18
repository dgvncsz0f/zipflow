defmodule Zipflow.Spec.CDH do
  @moduledoc """
  The central directory header, the last bits of a zip archive. Each
  entry in a zipfile contains a local header which is accompanied by a
  corresponding central header within the central directory header.
  """

  @doc """
  encode the central directory headers and the end of central
  directory header. each entry you add to a zip archive using
  `Zipflow.Spec.LFH` and `Zipflow.Spec.Entry` [one of its
  implementation] generates a value that must be kept and used here
  in the `contents` arguments. you must provide them in order, as a
  list of tuple `{LFH, Entry}`.

  # example #

  ```
  iex> entry = Zipflow.DataEntry.encode(&IO.binwrite/1, "foobar", "foobar")
  ...> Zipflow.Spec.CDH.encode(&IO.binwrite/1, [entry])
  ```
  """
  @spec encode((binary -> any), [{Zipflow.Spec.LFH.t, Zipflow.Spec.Entry.t}]) :: any
  def encode(printer, contents) do
    ctx = Enum.reduce(contents, %{entries: 0, offset: 0, size: 0}, fn {hframe, dframe}, acc ->
      hdr = header(printer, acc, hframe, dframe)
      acc
      |> Map.update!(:size, & &1 + hdr[:size])
      |> Map.update!(:offset, & &1 + hdr[:offset])
      |> Map.update!(:entries, & &1 + 1)
    end)
    frame = << 0x06054b50    :: size(32)-little, # signature
               0             :: size(16)-little, # number of this disk
               0             :: size(16)-little, # number of the disk w/ ECD
               ctx[:entries] :: size(16)-little, # total number of entries in this disk
               ctx[:entries] :: size(16)-little, # total number of entries in the ECD
               ctx[:size]    :: size(32)-little, # size central directory
               ctx[:offset]  :: size(32)-little, # offset central directory
               0             :: size(16)-little
            >>
     printer.(frame)
  end

  defp header(printer, ctx, hframe, dframe) do
    frame = <<
       0x02014b50            :: size(32)-little, # central file header signature
       20                    :: size(16)-little, # version made by
       0x0a                  :: size(16)-little, # version to extract
       8                     :: size(16)-little, # general purpose flag
       0                     :: size(16)-little, # compression method
       0                     :: size(16)-little, # last mod file time
       0                     :: size(16)-little, # last mod file date
       dframe[:crc]          :: size(32)-little, # crc-32
       dframe[:csize]        :: size(32)-little, # compressed size
       dframe[:usize]        :: size(32)-little, # uncompressed size
       hframe[:n_size]       :: size(16)-little, # file name length
       0                     :: size(16)-little, # extra field length
       0                     :: size(16)-little, # file comment length
       0                     :: size(16)-little, # disk number start
       0                     :: size(16)-little, # internal file attribute
       0                     :: size(32)-little, # external file attribute
       ctx[:offset]          :: size(32)-little, # relative offset header
    >>
    printer.(frame)
    printer.(hframe[:name])
    %{size: byte_size(frame) + hframe[:n_size],
      offset: hframe[:size] + dframe[:size]}
  end

end
