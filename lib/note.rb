# Represents a single note of a tune

class Note < Struct.new(:frequency, :amplitude, :duration)

	# @param frequency [Numeric] Note frequency in Hertz.
        # @param amplitude [Float] Note amplitude as a fraction of maximum volume (0 to 1)
        # @param duration [Numeric] Length of the note in seconds.
	def initialize(frequency, amplitude, duration)
		super(frequency, amplitude, duration)
	end

	# Create a rest with the given duration.
	# @param duration [Numeric]`
	def self.rest(duration)

		# Can't set frequency to 0 as it causes divide-by-zero errors
		new(1, 0, duration)
	end
end
