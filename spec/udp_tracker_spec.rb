# frozen_string_literal: true

require 'udp_tracker'

RSpec.describe UdpTracker do
  def connect_response
    [File.read('spec/files/udp_tracker/udp_connect_response.dat'), nil]
  end

  def announce_response
    [File.read('spec/files/udp_tracker/udp_announce_response.dat'), nil]
  end

  describe 'connect' do
    it 'receives a connection_id' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: connect_response)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(63_040) # Random

      tracker.connect

      expect(tracker.connection_id).to eq(0x92804b684d0725d8)
    end

    it 'returns true on success' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: connect_response)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(63_040) # Random

      expect(tracker.connect).to be(true)
    end

    it 'returns false on SocketError' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      allow(tracker).to receive(:socket).and_raise(SocketError)

      expect(tracker.connect).to be(false)
    end

    it 'returns false on ECONNREFUSED' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      allow(tracker).to receive(:socket).and_raise(Errno::ECONNREFUSED)

      expect(tracker.connect).to be(false)
    end

    it 'returns false if transaction_id doesnt match' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: connect_response)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(43_702) # Random

      expect(tracker.connect).to be(false)
    end
  end

  describe '#announce' do
    it 'returns a list of peers on success' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: announce_response)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(19_553) # Random
      allow(tracker).to receive(:connection_id).and_return(0x92804b684d0725d8)

      expect(tracker.announce(torrent)).to eq([['186.232.38.137', 6_881]])
    end

    it 'returns false on ECONNREFUSED' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      allow(tracker).to receive(:socket).and_raise(Errno::ECONNREFUSED)
      allow(tracker).to receive(:connection_id).and_return(0x92804b684d0725d8)

      expect(tracker.announce(torrent)).to be(false)
    end

    it 'returns false if transaction_id doesnt match' do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      tracker = described_class.new(tracker_url)

      socket = double(send: true, recvfrom: announce_response)
      allow(tracker).to receive(:socket).and_return(socket)
      allow(tracker).to receive(:transaction_id).and_return(12_345)
      allow(tracker).to receive(:connection_id).and_return(0x92804b684d0725d8)

      expect(tracker.announce(torrent)).to be(false)
    end
  end

  describe '#announce_response' do
    let(:info_hash) { torrent.info_hash }
    let(:message) { tracker.send(:announce_message, 123, 1, info_hash, 321) }
    let(:tracker) do
      tracker_url = 'udp://tracker.opentrackr.org:1337/announce'
      t = described_class.new(tracker_url)

      allow(t).to receive(:transaction_id).and_return(12_345)
      allow(t).to receive(:connection_id).and_return(0x92804b684d0725d8)

      t
    end

    it 'has the correct connection_id' do
      conn0, conn1 = message.unpack('NN')

      connection_id = conn0 << 32 | conn1

      expect(connection_id).to eq(0x92804b684d0725d8)
    end

    it 'has the correct action_id' do
      _, _, action = message.unpack('NNN')

      expect(action).to eq(1)
    end

    it 'has the correct transaction_id' do
      _, _, _, transaction_id = message.unpack('NNNN')

      expect(transaction_id).to eq(123)
    end

    context 'all_parrots' do
      let(:torrent) { torrent_all_parrots }

      it 'has the correct info_hash' do
        _, _, _, _, info_hash_ = message.unpack('NNNNH40')

        expect(info_hash_).to eq(torrent.info_hash)
      end
    end

    context 'debian' do
      let(:torrent) { torrent_debian }

      it 'has the correct info_hash 2' do
        _, _, _, _, info_hash_ = message.unpack('NNNNH40')

        expect(info_hash_).to eq(torrent.info_hash)
      end
    end
  end
end
