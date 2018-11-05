# Knows how to parse Dwarf Fortress rhythm notation, like | x x - X |
class Rhythm

	class Beat < Struct.new(:amplitude)
	end

	# Amplitude values for each Dwarf Fortress beat symbol.
	# These are in no particular scale; the maximum volume will be whatever's loudest in any particular string.
	BEAT_VALUES = {

		# Silence
		'-' => 0,

		# Regular beat
		'x' => 4,

		# Accented beat
		'X' => 6,

		# Primary accent
		'!' => 9
	}

	BAR_LINE = '|'

	def initialize(rhythm_string)
		@beats = parse(rhythm_string)
	end

	attr_reader :beats

	def each_beat(&block)
		@beats.each(&block)
	end

	private

	def parse(rhythm_string)

		# TODO: should I be ignoring bar lines? Is there anything I can do with them?
		raw_amplitudes = rhythm_string.split(' ').reject { |char| char == BAR_LINE }.map do |char|
			BEAT_VALUES[char] || raise("Unknown beat symbol #{char}")
		end

		# Ensure all our amplitudes are between 0.0 and 1.0
		highest_volume = raw_amplitudes.max
		raw_amplitudes.map do |amplitude|
			scaled = amplitude.to_f / highest_volume

			Beat.new(scaled)
		end
	end
end

