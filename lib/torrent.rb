class Torrent
  def initialize(bdata, raw_data)
    @bdata = bdata
    @raw_data = raw_data
  end

  def main_tracker
    @bdata['announce']
  end

  def info_hash
    @info_hash ||= begin
      starter_index = @raw_data.index('4:info') + 6
      end_index = @raw_data.size - 1

      info_data = @raw_data[starter_index, end_index]

      Digest::SHA1.hexdigest(info_data)
    end
  end
end