defmodule Zipflow.Spec.StoreEntry do

  @moduledoc """
  this includes data in a zip archive uncompressed. however, you
  hardly will use this directly. instead, refer to `Zipflow.DataEntry`
  and `Zipflow.FileEntry` as they are easier to use.
  """

  @behaviour Zipflow.Spec.Entry

  def init(printer) do
    z   = :zlib.open
    crc = :zlib.crc32(z, <<>>)
    %{crc: crc, csize: 0, usize: 0, private: %{z: z, printer: printer}}
  end

  def data(ctx, data) do
    size = byte_size(data)
    ctx[:private][:printer].(data)
    ctx
    |> Map.update!(:crc, & :zlib.crc32(ctx[:private][:z], &1, data))
    |> Map.update!(:usize, & &1 + size)
    |> Map.update!(:csize, & &1 + size)
  end

  def term(ctx) do
    :zlib.close(ctx[:private][:z])
    frame = << 0x08074b50  :: size(32)-little,
               ctx[:crc]   :: size(32)-little,
               ctx[:csize] :: size(32)-little,
               ctx[:usize] :: size(32)-little
    >>
    ctx[:private][:printer].(frame)
    Map.delete(ctx, :private)
    |> Map.put(:size, ctx[:csize] + byte_size(frame))
  end

end
