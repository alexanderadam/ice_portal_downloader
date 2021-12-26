require 'mp3info'

# Begin of monkey patch to avoid issue https://github.com/moumar/ruby-mp3info/issues/67
Mp3Info.class_eval do
  ### reads through @io from current pos until it finds a valid MPEG header
  ### returns the MPEG header as FixNum
  def find_next_frame
    # @io will now be sitting at the best guess for where the MPEG frame is.
    # It should be at byte 0 when there's no id3v2 tag.
    # It should be at the end of the id3v2 tag or the zero padding if there
    #   is a id3v2 tag.
    # dummyproof = @io.stat.size - @io.pos => WAS TOO MUCH

    dummyproof = [@io_size - @io.pos, 39_000_000].min
    dummyproof.times do |_i|
      next unless @io.getbyte == 0xff

      data = @io.read(3)
      raise Mp3InfoEOFError if @io.eof?

      head = 0xff000000 + (data.getbyte(0) << 16) + (data.getbyte(1) << 8) + data.getbyte(2)
      begin
        return Mp3Info.get_frames_infos(head)
      rescue Mp3InfoInternalError
        @io.seek(-3, IO::SEEK_CUR)
      end
    end
    if @io.eof?
      raise Mp3InfoEOFError
    else
      raise Mp3InfoError, "cannot find a valid frame after reading #{dummyproof} bytes"
    end
  end
end
# end of monkey patch
