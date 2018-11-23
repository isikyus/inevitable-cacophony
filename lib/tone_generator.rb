# Converts note information into raw WAV file data
# Based on examples in {http://wavefilegem.com/examples}

require 'wavefile'
require 'note'

class ToneGenerator

        SAMPLE_RATE = 44100 # Hertz

	# Amount of silence before a note, as a fraction of the note's duration
	START_DELAY = 0.3

	# Amount of silence after notes, as a fraction  of duration.
	AFTER_DELAY = 0.3

        # One full revolution of a circle (or one full cycle of a sine wave)
        TAU = Math::PI * 2

        # Create a buffer representing a given note as an audio sample
        #
        # @param note [Note]
        def note_buffer(note)
		samples_per_wave = SAMPLE_RATE / note.frequency.to_f
		
		# Decide how much space to allow before and after the note.
		# TODO: should depend on note duration and maybe staccato/legato-ness
		timeslot = note.duration * SAMPLE_RATE
		start_delay = timeslot * START_DELAY
		after_delay = timeslot * AFTER_DELAY

		# Adjust delays to account for early/late beats
		delay_adjustment = start_delay * note.beat.timing
		start_delay += delay_adjustment
		after_delay -= delay_adjustment

		note_length = timeslot - start_delay - after_delay

                samples = []
		
		samples << ([0.0] * start_delay)
		samples << note_length.to_i.times.map do |index|
                        wave_fraction = index / samples_per_wave.to_f
			note.beat.amplitude * Math.sin(wave_fraction * TAU)
                end
		samples << ([0.0] * after_delay)

                WaveFile::Buffer.new(samples.flatten, WaveFile::Format.new(:mono, :float, SAMPLE_RATE))
        end

	def add_note(frequency, amplitude, duration)
		@notes << note_buffer(Note.new(frequency, amplitude, duration))
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

