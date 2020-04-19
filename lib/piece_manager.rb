# frozen_string_literal: true

require_relative 'piece'

class PieceManager
  def initialize(torrent)
    @torrent = torrent
    @pieces = {}
  end

  def piece_size
    @torrent.piece_size
  end

  def started_piece_missing_chunks
    missing_chunks = @pieces.values.select do |piece|
      piece.at_least_one_request? && piece.missing_chunk?
    end

    missing_chunks.first
  end

  def request_chunk(piece_index, chunk_offset, chunk_size)
    @pieces[piece_index] ||= Piece.new(piece_size)
    @pieces[piece_index].tap do |piece|
      piece.request_chunk(chunk_offset, chunk_size)
    end
  end
end
