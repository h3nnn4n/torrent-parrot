# frozen_string_literal: true

require 'bencode'
require 'torrent'

RSpec.describe Torrent do
  describe '#main_tracker' do
    it 'returns the main treacker' do
      tracker_uri = 'udp://tracker.opentrackr.org:1337/announce'
      expect(torrent.main_tracker).to eq(tracker_uri)
    end
  end

  describe '#trackers' do
    it 'returns main tracker when "announce-list" is empty' do
      tracker_uri = 'udp://tracker.opentrackr.org:1337/announce'

      expect(torrent.trackers).to eq([tracker_uri])
    end

    it 'returns all trackers' do
      tracker_uri1 = 'udp://tracker.opentrackr.org:1337/announce'
      tracker_uri2 = 'udp://open.nyap2p.com:6969/announce'
      tracker_uri3 = 'udp://opentracker.i2p.rocks:6969/announce'

      expect(torrent2.trackers.size).to eq(3)
      expect(torrent2.trackers).to include(tracker_uri1)
      expect(torrent2.trackers).to include(tracker_uri2)
      expect(torrent2.trackers).to include(tracker_uri3)
    end
  end

  describe '#info_hash' do
    it 'returns the info_hash' do
      info_hash = '04c24ad70a7f1bbefe347297bedc1475e6b2daf1'
      expect(torrent.info_hash).to eq(info_hash)
    end
  end

  describe '#size' do
    it 'returns the total file size for single file torrent' do
      expect(torrent.size).to eq(42)
    end

    it 'returns the total file size for multiple files torrent' do
      expect(torrent2.size).to eq(44)
    end
  end
end
