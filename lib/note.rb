# Represents a single note of a tune

# TODO: only for Beat class
require 'rhythm'

class Note < Struct.new(:frequency, :beat, :duration)

	# @param frequency [Numeric] Note frequency in Hertz.
        # @param amplitude [Rhythm::Beat] A Beat object defining amplitude and timing
        # @param duration [Numeric] Length of the note in seconds.
	def initialize(frequency, beat, duration)
		super(frequency, beat, duration)
	end

	# Create a rest with the given duration.
	# @param duration [Numeric]`
	def self.rest(duration)

		# Can't set frequency to 0 as it causes divide-by-zero errors
		new(1, Rhythm::Beat.new(0, 0), duration)
	end
end
