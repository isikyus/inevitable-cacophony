require 'wavefile'

# Based on examples in {http://wavefilegem.com/examples}

class Cacophony

	SAMPLE_RATE = 44100 # Hertz

	# One full revolution of a circle (or one full cycle of a sine wave)
	TAU = Math::PI * 2

	# Create a buffer containing a tone of the given frequency and duration.
	#
	# @param frequency [Numeric] Note frequency in Hertz.
	# @param duration [Numeric] Length of the note in seconds.
	def note_buffer(frequency, duration)
		samples_per_wave = SAMPLE_RATE / frequency
		note_length = duration * SAMPLE_RATE

		samples = note_length.to_i.times.map do |index|
			wave_fraction = index / samples_per_wave.to_f
			Math.sin(wave_fraction * TAU)
		end

		WaveFile::Buffer.new(samples, WaveFile::Format.new(:mono, :float, SAMPLE_RATE))
	end

	def add_note(frequency, duration)
		@notes << note_buffer(frequency, duration)
	end

	def write(filename)
		WaveFile::Writer.new(filename, WaveFile::Format.new(:mono, :pcm_16, SAMPLE_RATE)) do |writer|
			@notes.each do |note|
				writer.write(note)
			end
		end
	end

	def initialize
		@notes = []
	end
end


# Write a single note
caco = Cacophony.new
caco.add_note(440, 3)
caco.write("sound.wav")
