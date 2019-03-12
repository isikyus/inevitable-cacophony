# Knows how to parse Dwarf Fortress rhythm notation, like | x x - X |

# TODO: remove once we've moved the constants we need across
require 'tone_generator'

class Rhythm

	# Amplitude -- how loud the beat is, on a scale from silent to MAX VOLUME.
	# Duration -- how long it is, in arbitrary beat units (think metronome ticks)
	# Timing -- how early or late the beat is, relative to the same metaphorical metronome.
	class Beat < Struct.new(:amplitude, :duration, :timing)
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

	# Values for each kind of timing symbol.
	# By default a beat is in the middle of its time-slice (0.0);
	# a value of 1.0 means to play it as late as possible,
	# and -1.0 means play as early as possible.
	#
	# Technically position of these matters, but we handle that in the parser regexp.
	TIMING_VALUES = {

		# Normal beat (no special timing)
		'' => 0.0,

		# Early beat
		'`' => -1.0,

		# Late beat
		'\'' => 1.0
	}

	BAR_LINE = '|'

	def self.from_string(rhythm_string)
		new(parse(rhythm_string))
	end

	# Creates a new polyrhythm by combining two simpler component rhythms.
	#
	# @param primary [Rhythm] The rhythm that will be considered the primary.
	#                         Defines the timing of the combined rhythm.
	# @param secondaries [Array<Rhythm>] The other component rhythms.
	def self.poly(primary, *secondaries)
		Polyrhythm.new(primary, *secondaries)
	end

	def initialize(beats)
		@beats = beats
	end

	attr_reader :beats

	def each_beat(&block)
		@beats.each(&block)
	end

	# @return [Numeric] Total duration of all beats in this rhythm.
	def duration
		each_beat.sum(&:duration)
	end

	# @param new_duration [Numeric] The new number of time steps to take (in total, not per bar).
	# @return [Rhythm] This rhythm, but re-scaled to take up the given amount of time steps.
	def stretch(new_duration)
		scale_factor = new_duration / duration.to_f

		Rhythm.new(beats.map do |beat|
			Beat.new(beat.amplitude, beat.duration * scale_factor, beat.timing)
		end)
	end

	# @return [Rhythm] A "canonical" form of this rhythm, with all beats lasting 100% of their time slice,
	#                  and silent periods due to incomplete beats or timing always represented as beats.
	def canonical
		new_beats = []
		spacing = 0

		each_beat do |beat|

			# Positive values from 0 to 1.
			# Higher numbers mean move more of this offset to the other side of the note
			# (e.g. start earlier for start offset).
			start_offset = -[beat.timing, 0].min
			end_offset = [beat.timing, 0].max

			start_delay = ((1 - start_offset) * ToneGenerator::START_DELAY) +
				(end_offset * ToneGenerator::AFTER_DELAY)

			after_delay = (start_offset * ToneGenerator::START_DELAY) +
				((1 - end_offset) * ToneGenerator::AFTER_DELAY)

			spacing += start_delay * beat.duration
			new_beats << Beat.new(0, spacing, 0)

			duty_cycle = 1 - start_delay - after_delay
			new_beats << Beat.new(beat.amplitude, beat.duration * duty_cycle, 0)

			# Save after spacing so we can combine it with the start delay of the next note.
			spacing = after_delay * beat.duration
		end

		# Add the extra time at the end of the rhythm.
		new_beats << Beat.new(0, spacing, 0)

		Rhythm.new(new_beats)
	end

	private

	# @param rhythm_string [String] In the notation Dwarf Fortress produces, like | X x ! x |
	# @return [Array<Beat>]
	def self.parse(rhythm_string)

		# TODO: should I be ignoring bar lines? Is there anything I can do with them?
		raw_beats = rhythm_string.split(/ |(?=`)|(?<=')/).reject { |beat| beat == BAR_LINE }.map do |beat|
			timing_symbol = beat.chars.reject { |char| BEAT_VALUES.keys.include?(char) }.join
			timing = TIMING_VALUES[timing_symbol] || raise("Unknown timing symbol #{timing_symbol}")

			accent_symbol = beat.delete(timing_symbol)
			amplitude = BEAT_VALUES[accent_symbol] || raise("Unknown beat symbol #{accent_symbol}")

			Beat.new(amplitude, 1, timing)
		end

		# Ensure all our amplitudes are between 0.0 and 1.0
		# TODO: find a way to do this without creating twice as many beats as we need.
		highest_volume = raw_beats.map(&:amplitude).max
		raw_beats.map do |beat|
			scaled = beat.amplitude.to_f / highest_volume

			Beat.new(scaled, 1, beat.timing)
		end
	end
end

# Require subclasses only once parent class has been defined.
# TODO: probably not the ideal way to do this.
require 'polyrhythm'
