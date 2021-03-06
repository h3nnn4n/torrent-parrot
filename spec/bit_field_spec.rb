# frozen_string_literal: true

require 'bit_field'

RSpec.describe BitField do
  def payload
    [5, 5, 0, 255, 0, 63].pack('NCCCCC')
  end

  def build_bitfield
    bitfield = described_class.new(30)
    bitfield.populate(payload)
    bitfield
  end

  describe '#set?' do
    it 'has bit #0 set' do
      bitfield = build_bitfield
      expect(bitfield.set?(8)).to be(true)
    end

    it 'has bit #221 not set' do
      bitfield = build_bitfield
      expect(bitfield.set?(0)).to be(false)
    end
  end

  describe '#all_bits_set_index' do
    def payload
      File.read('spec/files/peer_messages/pi6_bitfield.dat')
    end

    it 'has no set bits' do
      fake_payload = [2, 5, 0].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.all_bits_set_index.size).to be(0)
    end

    it 'has some set bits' do
      fake_payload = [2, 5, 7].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.all_bits_set_index).to eq([0, 1, 2])
    end

    it 'has all possible bits' do
      fake_payload = [2, 5, 255].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.all_bits_set_index).to eq([0, 1, 2, 3, 4, 5, 6, 7])
    end

    it 'populates with a real payload' do
      bit_field = described_class.new(torrent_pi6.number_of_pieces)
      bit_field.populate(payload)

      expect(bit_field.all_bits_set_index).to eq((0..33).to_a)
    end
  end

  describe '#any_bit_set?' do
    it 'has at least one set bit' do
      bitfield = build_bitfield
      expect(bitfield.any_bit_set?).to be(true)
    end

    it 'has no set bits' do
      fake_payload = [2, 5, 0].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.any_bit_set?).to be(false)
    end
  end

  describe '#random_unset_bit_index' do
    it 'returns the index of a unset bit' do
      bitfield = build_bitfield
      index = bitfield.random_unset_bit_index

      expect(bitfield.set?(index)).to be(false)
    end
  end

  describe '#random_set_bit_index' do
    it 'returns the index of a set bit' do
      bitfield = build_bitfield
      index = bitfield.random_set_bit_index

      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#set' do
    it 'sets a bit' do
      bitfield = build_bitfield
      index = bitfield.random_unset_bit_index
      bitfield.set(index)
      expect(bitfield.set?(index)).to be(true)
    end
  end

  describe '#unset' do
    it 'unsets a bit' do
      bitfield = build_bitfield
      index = bitfield.random_set_bit_index
      bitfield.unset(index)
      expect(bitfield.set?(index)).to be(false)
    end
  end

  describe '#length' do
    it 'has the correct length' do
      bitfield = build_bitfield
      expect(bitfield.length).to eq(30)
    end
  end

  describe '#bit_set_count' do
    it 'has the correct number of bits set' do
      bitfield = build_bitfield
      expect(bitfield.bit_set_count).to eq(14)
    end
  end

  describe '#everything_set?' do
    it 'has no set bits' do
      fake_payload = [2, 5, 0].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.everything_set?).to be(false)
    end

    it 'has all bits set' do
      fake_payload = [2, 5, 255].pack('NCC')
      bitfield = described_class.new(8)
      bitfield.populate(fake_payload)
      expect(bitfield.everything_set?).to be(true)
    end
  end

  describe '#populate' do
    def payload
      File.read('spec/files/peer_messages/pi6_bitfield.dat')
    end

    it 'populates with a real payload' do
      bit_field = described_class.new(torrent_pi6.number_of_pieces)
      bit_field.populate(payload)

      expect(bit_field.everything_set?).to be(true)
    end

    it 'raises with bitfield length is super long' do
      fake_payload = ([3_211_507_327, 5] + [255] * 10).pack('NC*')

      bit_field = described_class.new(torrent_pi6.number_of_pieces)

      expect { bit_field.populate(fake_payload) }.to raise_exception(RuntimeError)
    end

    it 'raises with bitfield length is too long' do
      fake_payload = ([10_000, 5] + [255] * 10_000).pack('NC*')

      bit_field = described_class.new(torrent_pi6.number_of_pieces)

      expect { bit_field.populate(fake_payload) }.to raise_exception(RuntimeError)
    end
  end

  describe '#byte_to_bits' do
    it 'works for 0' do
      bitfield = described_class.new(8)

      expect(bitfield.send(:byte_to_bits, 0)).to eq(
        [false, false, false, false, false, false, false, false]
      )
    end

    it 'works for 1' do
      bitfield = described_class.new(8)

      expect(bitfield.send(:byte_to_bits, 1)).to eq(
        [true, false, false, false, false, false, false, false]
      )
    end

    it 'works for 2' do
      bitfield = described_class.new(8)

      expect(bitfield.send(:byte_to_bits, 2)).to eq(
        [false, true, false, false, false, false, false, false]
      )
    end

    it 'works for 3' do
      bitfield = described_class.new(8)
      answer = [true, true, false, false, false, false, false, false]

      expect(bitfield.send(:byte_to_bits, 3)).to eq(answer)
    end

    it 'works for 16' do
      bitfield = described_class.new(8)
      answer = [false, false, false, false, true, false, false, false]

      expect(bitfield.send(:byte_to_bits, 16)).to eq(answer)
    end

    it 'works for 17' do
      bitfield = described_class.new(8)
      answer = [true, false, false, false, true, false, false, false]

      expect(bitfield.send(:byte_to_bits, 17)).to eq(answer)
    end
  end
end
