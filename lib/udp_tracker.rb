# frozen_string_literal: true

require_relative 'base_tracker'

class UdpTracker < BaseTracker
  attr_reader :connection_id

  def connect
    transaction_id = rand(2**16)
    logger.info "sending connect package with transaction_id #{transaction_id}"

    payload = connection_message(transaction_id)
    socket.send(payload, 0)
    response = socket.recvfrom(1024)
    action_r, transaction_id_r, conn0, conn1 = response.first.unpack('NNNN')

    @connection_id = conn0 << 32 | conn1

    logger.info "connection_id is #{@connection_id}"

    raise 'invalid transaction_id' unless transaction_id == transaction_id_r
    raise 'invalid action' unless action_r.zero?

    true
  end

  def announce(info_hash)
    transaction_id = rand(2**16)
    key_id = rand(2**16)
    action_id = 1

    payload = announce_message(transaction_id, action_id, info_hash, key_id)

    socket.send(payload, 0)
    response = socket.recvfrom(1024).first
    header = response[0..20]
    peers = response[20..response.size]
    n_peers = peers.size / 6

    action_r, transaction_id_r, interval, leechers, seeders = header.unpack('NNNNN')

    raise "got error #{response} #{action_r}" unless action_r == 1
    raise 'invalid transaction_id' unless transaction_id == transaction_id_r

    logger.info "announce interval is #{interval}"
    logger.info "leechers #{leechers} and seeders #{seeders}"
    logger.info "received #{n_peers} of the #{@wanted_peers} requested peers"

    decode_peers(peers)
  end

  def connection_message(transaction_id = nil)
    transaction_id = rand(2**32) if transaction_id.nil?

    magic_number = 0x41727101980
    [
      magic_number >> 32,
      magic_number & 0xffffffff,
      0, # Action 0 is connect
      transaction_id
    ].pack('NNNN')
  end

  def announce_message(transaction_id, action, info_hash, key_id)
    [
      connection_id >> 32,           # 64-bit integer
      connection_id & 0xffffffff,
      action,                        # 32-bit integer action 1 - announce
      transaction_id,                # 32-bit integer
      info_hash,                     # 20-byte string
      peer_id,                       # 20-byte string
      bytes_downloaded >> 32,        # 64-bit integer
      bytes_downloaded & 0xffffffff,
      bytes_left >> 32,              # 64-bit integer
      bytes_left & 0xffffffff,
      bytes_uploaded >> 32,          # 64-bit integer
      bytes_uploaded & 0xffffffff,
      0,                             # 32-bit integer - event
      0,                             # 32-bit integer - ip address, 0 is default
      key_id,                        # 32-bit integer key
      @wanted_peers,                 # 32-bit integer - desired number of peers
      listen_port                    # 16-bit integer - port
    ].pack('NNNNa20a20NNNNNNNNNNn')
  end

  private

  def decode_peers(peers)
    n_peers = peers.size / 6
    unpacker = 'CCCCn'

    (0..n_peers - 1).map do |index|
      data = peers[(index * 6)..((index * 6) + 5)].unpack(unpacker)
      ip = data[0..3].join('.')
      port = data.last

      logger.info "found peer #{index} #{ip} on port #{port}"

      [ip, port]
    end
  end

  def socket
    @socket ||= begin
                  s = UDPSocket.new
                  s.connect(
                    host,
                    port
                  )
                  s
                end
  end
end