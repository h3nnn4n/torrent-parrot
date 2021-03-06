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
      expect(torrent2.trackers.size).to eq(3)
    end

    it 'includes all trackers' do
      tracker_uri1 = 'udp://tracker.opentrackr.org:1337/announce'
      tracker_uri2 = 'udp://open.nyap2p.com:6969/announce'
      tracker_uri3 = 'udp://opentracker.i2p.rocks:6969/announce'

      expect(torrent2.trackers).to eq([tracker_uri1, tracker_uri2, tracker_uri3])
    end
  end

  describe '#info_hash' do
    it 'returns the info_hash for torrent' do
      info_hash = '9fc6c0759cf7f7614ae25f5293d6bf7638115321'
      expect(torrent.info_hash).to eq(info_hash)
    end

    it 'returns the info_hash for torrent2' do
      info_hash = 'cdae19ff30af2e5f6f71ecbab8155f384a300148'
      expect(torrent2.info_hash).to eq(info_hash)
    end

    it 'returns the info_hash for archlinux' do
      info_hash = '1027de87dc168253781f83b183ece4dffa402f40'
      expect(torrent_archlinux.info_hash).to eq(info_hash)
    end

    it 'returns the info_hash for debian' do
      info_hash = '5a8062c076fa85e8056451c0d9aa04349ae27909'
      expect(torrent_debian.info_hash).to eq(info_hash)
    end

    it 'returns the info_hash for all_parrots' do
      info_hash = '597bb7dfd675711b8c313e295d0451705670dc52'
      expect(torrent_all_parrots.info_hash).to eq(info_hash)
    end
  end

  describe '#number_of_pieces' do
    it 'returns the total file size for single file torrent' do
      expect(torrent.number_of_pieces).to eq(1)
    end

    it 'returns the total file size for big single file torrent' do
      expect(torrent_debian.number_of_pieces).to eq(1340)
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

  describe '#hash_for_piece' do
    it 'returns the hash of a correct size' do
      expect(torrent.hash_for_piece(0).size).to be(20)
    end

    it 'returns the hash for a given index' do
      hash = "\xC1\xD5\xCD\xD7m\xB4\v\xB4\xD1|\xF5O\xFC\xEBY\xD5\fdd\n"

      expect(torrent.hash_for_piece(0).unpack('h*')).to eq(hash.unpack('h*'))
    end
  end

  describe '#file_name' do
    it 'returns the file name for single file torrent' do
      expect(torrent.file_name).to eq('potato.txt')
    end
  end

  describe '#single_file?' do
    it 'returns true for single file torrents' do
      expect(torrent.single_file?).to be(true)
    end

    it 'returns true for single file torrents' do
      expect(torrent2.single_file?).to be(false)
    end
  end
end
