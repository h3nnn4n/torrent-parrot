# frozen_string_literal: true

require 'forwardable'
require 'logger'

require_relative 'peer_connection'

class Peer
  extend Forwardable

  def_delegators :connection, :connect

  def initialize(host, port, info_hash, peer_id)
    @host = host
    @port = port
    @info_hash = info_hash
    @peer_id = peer_id

    logger.info "[PEER] Created peer #{host}:#{port}"
  end

  private

  def connection
    @connection ||= PeerConnection.new(
      @host,
      @port,
      @info_hash,
      @peer_id
    )
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end
end