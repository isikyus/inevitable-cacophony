require 'wavefile'

# Based on examples in {http://wavefilegem.com/examples}

class Cacophony

	SAMPLE_RATE = 44100 # Hertz

	# One full revolution of a circle (or one full cycle of a sine wave)
	TAU = Math::PI * 2

	# Create a buffer containing a tone of the given frequency and duration.
	#
	# @param frequency [Numeric] Note frequency in Hertz.
	# @param amplitude [Float] Note amplitude as a fraction of maximum volume (0 to 1)
	# @param duration [Numeric] Length of the note in seconds.
	def note_buffer(frequency, amplitude, duration)
		samples_per_wave = SAMPLE_RATE / frequency
		note_length = duration * SAMPLE_RATE

		samples = note_length.to_i.times.map do |index|
			wave_fraction = index / samples_per_wave.to_f
			amplitude * Math.sin(wave_fraction * TAU)
		end

		WaveFile::Buffer.new(samples, WaveFile::Format.new(:mono, :float, SAMPLE_RATE))
	end

	def add_legato_note(frequency, amplitude, duration)
		@notes << note_buffer(frequency, amplitude, duration)
	end

	# As above, but adds a brief period of silence after the note.
	def add_note(frequency, amplitude, duration)
		add_legato_note(frequency, amplitude, duration * 0.9)
		add_legato_note(1, 0, duration * 0.1)
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

# Knows how to parse Dwarf Fortress rhythm notation, like | x x - X |
class Rhythm

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
		@amplitudes = parse(rhythm_string)
	end

	def each_beat(&block)
		@amplitudes.each(&block)
	end

	private

	def parse(rhythm_string)

		# TODO: should I be ignoring bar lines? Is there anything I can do with them?
		raw_amplitudes = rhythm_string.split(' ').reject { |char| char == BAR_LINE }.map do |char|
			BEAT_VALUES[char] || raise("Unknown beat symbol #{char}")
		end

		# Ensure all our amplitudes are between 0.0 and 1.0
		highest_volume = raw_amplitudes.max
		raw_amplitudes.map { |amplitude| amplitude.to_f / highest_volume }
	end
end

caco = Cacophony.new

# Default to a basic 4-bar beat.
beats = Rhythm.new(ARGV.first || '| x x x X |')

3.times do
	beats.each_beat do |amplitude|
		caco.add_note(440, amplitude, 0.5)
	end
end
caco.write("sound.wav")
