# Converts note information into raw WAV file data
# Based on examples in {http://wavefilegem.com/examples}

require 'wavefile'
require 'note'

class ToneGenerator

        SAMPLE_RATE = 44100 # Hertz

        # One full revolution of a circle (or one full cycle of a sine wave)
        TAU = Math::PI * 2

        # Create a buffer representing a given note as an audio sample
        #
        # @param note [Note]
        def note_buffer(note)
		samples_per_wave = SAMPLE_RATE / note.frequency.to_f
		note_length = note.duration * SAMPLE_RATE

                samples = note_length.to_i.times.map do |index|
                        wave_fraction = index / samples_per_wave.to_f
			note.amplitude * Math.sin(wave_fraction * TAU)
                end

                WaveFile::Buffer.new(samples, WaveFile::Format.new(:mono, :float, SAMPLE_RATE))
        end

        def add_legato_note(frequency, amplitude, duration)
		@notes << note_buffer(Note.new(frequency, amplitude, duration))
        end

        # As above, but adds a brief period of silence after the note.
        def add_note(frequency, amplitude, duration)
                add_legato_note(frequency, amplitude, duration * 0.9)
                add_legato_note(1, 0, duration * 0.1)
        end

        def write(io)
                WaveFile::Writer.new(io, WaveFile::Format.new(:mono, :pcm_16, SAMPLE_RATE)) do |writer|
                        @notes.each do |note|
                                writer.write(note)
                        end
                end
        end

        def initialize
                @notes = []
        end
end

