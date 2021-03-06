# frozen_string_literal: true

require 'forwardable'
require 'logger'
require 'socket'
require 'uri'

require_relative 'http_tracker'
require_relative 'udp_tracker'

class Tracker
  extend Forwardable

  def_delegators :middleware, :connect, :announce, :peer_id

  def initialize(tracker_s, owner_hash)
    @tracker_s = tracker_s
    @uri = URI(tracker_s)
    @owner_hash = owner_hash

    middleware
  end

  def scheme
    @uri.scheme
  end

  private

  def middleware
    return @middleware unless @middleware.nil?

    case scheme
    when 'udp'
      @middleware = UdpTracker.new(@tracker_s)
    when 'http', 'https'
      @middleware = HttpTracker.new(@tracker_s)
    else
      raise "#{scheme} is not supported!"
    end
  end
end
