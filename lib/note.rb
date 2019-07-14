# Represents a single note of a tune

# TODO: only for Beat class
require 'rhythm'

class Note < Struct.new(:frequency, :beat)

	# @param frequency [Numeric] Note frequency in Hertz.
        # @param amplitude [Rhythm::Beat] A Beat object defining amplitude and timing
	def initialize(frequency, beat)
		super(frequency, beat)
	end

	# Create a rest for the duration of the given beat.
	# @param beat [Beat]
	def self.rest(beat)

		# Can't set frequency to 0 as it causes divide-by-zero errors
		new(1, Rhythm::Beat.new(0, beat.duration, beat.timing))
	end

	def start_delay
		beat.start_delay
	end

	def after_delay
		beat.after_delay
	end

	def duration
		beat.duration
	end
end
