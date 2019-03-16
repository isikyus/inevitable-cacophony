# Knows how to parse Dwarf Fortress rhythm notation, like | x x - X |

class Rhythm

        # Amount of silence before a note, as a fraction of the note's duration
        START_DELAY = 0.3

        # Amount of silence after notes, as a fraction  of duration.
        AFTER_DELAY = 0.3

	# Amplitude -- how loud the beat is, on a scale from silent to MAX VOLUME.
	# Duration -- how long it is, in arbitrary beat units (think metronome ticks)
	# Timing -- how early or late the beat is, relative to the same metaphorical metronome.
	class Beat < Struct.new(:amplitude, :duration, :timing)

		# How much silence there is before this note starts,
		# after the previous note has finished its time (like padding in CSS).
		#
		# @return [Float]
		def start_delay
			start_and_after_delays.first * duration
		end

		# How much silence there is after this note ends,
		# before the next note's timeslot.
		#
		# @return [Float]
		def after_delay
			start_and_after_delays.last * duration
		end

		private

		# Calculate the before-note and after-note delays together,
		# to ensure they add up correctly.
		def start_and_after_delays
			@start_and_after_delays ||= begin

				# Positive values from 0 to 1.
				# Higher numbers mean move more of this offset to the other side of the note
				# (e.g. start earlier for start offset).
				start_offset = -[timing, 0].min
				end_offset = [timing, 0].max

				# This is basically matrix multiplication; multiply [START_DELAY, END_DELAY]
				# by [
				#	(1 - start_offset)	end_offset
				#	start_offset		(1 - end_offset)
				# ]
				[
					((1 - start_offset) * START_DELAY) + (end_offset * AFTER_DELAY),
					(start_offset * START_DELAY) +       ((1 - end_offset) * AFTER_DELAY)
				]
			end
		end
	end

	# The "canonical" version of a rhythm, with space between notes spelled out
	# explicitly rather than implied by timing values.
	class Canonical < Rhythm

		# @return [Rhythm::Canonical] This same rhythm; already canonical.
		def canonical
			self
		end
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

	# @return [Array<Numeric,NilClass>] An array where a[i] is the amplitude of the beat at time-step i,
	# 					or nil if no beat is played then (due to rests or it not
	# 					being in the rhythm at all).
	# 				    This will be as long as necessary to represent the rhythm accurately.
	def canonical
		if duration != duration.to_i
			raise "Cannot yet canonicalise rhythms with non-integer length"
		end

		self.beats.map do |beat|
			if beat.amplitude.zero?
				nil
			else
				beat.amplitude
			end
		end
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
