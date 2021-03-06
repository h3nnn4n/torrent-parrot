# frozen_string_literal: true

require 'timeout'

require_relative 'base_tracker'

class UdpTracker < BaseTracker
  attr_reader :connection_id

  def connect
    logger.info "[UDP_TRACKER] sending connect package with transaction_id #{transaction_id} to #{@tracker_s}"

    payload = connection_message(transaction_id)
    response = nil

    max_retries = 3
    (0..max_retries).each do |retry_n|
      socket.send(payload, 0)

      Timeout.timeout(1.5) do
        response = socket.recvfrom(1024)
      end
    rescue Timeout::Error
      return false if retry_n >= max_retries
    end

    action_r, transaction_id_r, conn0, conn1 = response.first.unpack('NNNN')

    @connection_id = conn0 << 32 | conn1

    # logger.info "[UDP_TRACKER] connection_id is #{@connection_id}"

    return false unless transaction_id == transaction_id_r
    raise 'invalid action' unless action_r.zero?

    true
  rescue SocketError, Errno::ECONNREFUSED
    false
  end

  def announce(torrent)
    info_hash = torrent.info_hash
    key_id = rand(2**16)
    action_id = 1

    @bytes_left = torrent.size

    payload = announce_message(transaction_id, action_id, info_hash, key_id)

    # logger.info "[UDP_TRACKER] sending annound with transaction_id #{transaction_id}"

    response_full = nil
    max_retries = 3

    (0..max_retries).each do |retry_n|
      socket.send(payload, 0)

      Timeout.timeout(1.5) do
        response_full = socket.recvfrom(1024)
      end
    rescue Timeout::Error
      return false if retry_n >= max_retries
    end

    response = response_full.first

    if response.size <= 20
      logger.warn "[UDP_TRACKER] Received a response only #{response.size} bytes long"
      logger.warn "[UDP_TRACKER] #{response_full}"
      logger.warn "[UDP_TRACKER] #{response.first.unpack('NNNNN')}"
      return false
    end

    header = response[0..20]
    peers = response[20..response.size]
    _n_peers = peers.size / 6

    action_r, transaction_id_r, _interval, _leechers, _seeders = header.unpack('NNNNN')

    return false unless transaction_id == transaction_id_r
    raise "got error #{response} #{action_r}" unless action_r == 1

    # logger.info "[UDP_TRACKER] announce interval is #{interval}"
    # logger.info "[UDP_TRACKER] leechers #{leechers} and seeders #{seeders}"
    # logger.info "[UDP_TRACKER] received #{n_peers} of the #{@wanted_peers} requested peers"

    decode_peers(peers)
  rescue SocketError, Errno::ECONNREFUSED
    false
  end

  private

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
    ].pack('NNNNH40a20NNNNNNNNNNn')
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

  def transaction_id
    @transaction_id ||= rand(2**16)
  end
end
