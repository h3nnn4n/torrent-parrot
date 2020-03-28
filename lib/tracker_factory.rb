# frozen_string_literal: true

require_relative 'tracker'

class TrackerFactory
  def initialize(torrent)
    @torrent = torrent
  end

  def build
    @torrent.trackers.map do |tracker_uri|
      Tracker.new(tracker_uri)
    end
  end
end
