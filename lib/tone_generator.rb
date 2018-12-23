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

        # Create a buffer representing a given phrase as an audio sample
        #
        # @param phrase [Phrase]
	def phrase_buffer(phrase)
		samples = phrase.notes.map { |note| note_samples(note, phrase.tempo) }
                WaveFile::Buffer.new(samples.flatten, WaveFile::Format.new(:mono, :float, SAMPLE_RATE))
	end

	def add_phrase(phrase)
		@phrases << phrase_buffer(phrase)
        end

        def write(io)
                WaveFile::Writer.new(io, WaveFile::Format.new(:mono, :pcm_16, SAMPLE_RATE)) do |writer|
                        @phrases.each do |phrase|
                                writer.write(phrase)
                        end
                end
        end

        def initialize
                @phrases = []
        end

	private

	# Create a array of amplitudes representing a single note as a sample.
	#
	# @param note [Note]
	# @param tempo [Numeric] Tempo in BPM to play the note at
	# 			 (exact duration will also depend on the beat).
        def note_samples(note, tempo)
		samples_per_wave = SAMPLE_RATE / note.frequency.to_f

		# Decide how much space to allow before and after the note.
		# TODO: should maybe depend on staccato/legato-ness
		samples_per_beat = (60.0 / tempo) * SAMPLE_RATE

		# TODO: Law of Demeter violation; notes should know their own length at this point.
		timeslot = note.beat.duration * samples_per_beat
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
		samples.flatten
        end
end

