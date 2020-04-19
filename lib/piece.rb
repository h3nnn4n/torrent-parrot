# frozen_string_literal: true

require_relative 'chunk'
require_relative 'ninja_logger'

class Piece
  attr_accessor :piece_hash
  attr_reader :chunks

  CHUNK_SIZE = 16_384

  def initialize(piece_size, piece_index, piece_hash: nil)
    @piece_size = piece_size
    @piece_index = piece_index
    @chunks = {}
    @number_of_chunks = piece_size / 16_384
    @piece_hash = piece_hash
  end

  def index
    @piece_index
  end

  def completed?
    !missing_chunk?
  end

  def missing_chunk?
    return true if @chunks.size.zero?
    return true if @chunks.size < @number_of_chunks

    @chunks.values.none?(&:received?) || @chunks.values.any?(&:pending?)
  end

  def unrequested_chunk?
    return true if @chunks.size.zero?
    return true if @chunks.size < @number_of_chunks

    @chunks.values.none?(&:requested?)
  end

  def at_least_one_request?
    @chunks.size.positive?
  end

  def next_chunk_to_request
    # FIXME: This logic doenst account for gaps
    # It assumes all chunks are requested in a row
    return 0 if @chunks.empty?

    last_chunk = @chunks.keys.max
    next_chunk = (last_chunk + 1) * CHUNK_SIZE

    raise 'Requesting too many chunks for this piece!' if (last_chunk + 1) >= @number_of_chunks

    next_chunk
  end

  def request_chunk(chunk_offset)
    chunk_index = chunk_offset / CHUNK_SIZE
    @chunks[chunk_index] ||= Chunk.new
    @chunks[chunk_index].request

    raise 'Requested too many chunks for this piece!' if chunk_index >= @number_of_chunks
  end

  def receive_chunk(chunk_offset, payload)
    chunk_index = chunk_offset / CHUNK_SIZE
    @chunks[chunk_index].receive(payload)

    raise 'This chunk cant possibly exist!' if chunk_index >= @number_of_chunks
  end

  def integrity_check
    return false if @chunks.empty?

    data = @chunks.values.map(&:payload).join
    return false if data.nil?
    return false if piece_hash.nil?

    check = piece_hash.unpack1('H*') == Digest::SHA1.hexdigest(data)
    logger.warn "[PIECE_MANAGER] Integrity check failed for piece #{@piece_index}" unless check
    check
  end

  def reset_chunks
    logger.warn "[PIECE_MANAGER] Reseting all chunks for piece #{@piece_index}"
    @chunks = {}
  end

  def logger
    NinjaLogger.logger
  end
end
