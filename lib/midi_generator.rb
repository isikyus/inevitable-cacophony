# Converts Inevitable Cacophony internal note representation
# into MIDI messages usable by an external synthesizer.
# Based on examples in the `midilib` gem.

require 'midilib/sequence'
require 'midilib/consts'

class MidiGenerator

        # Raised when there is no MIDI index available for
        # a note we're trying to output
        class OutOfRange < StandardError
                def initialize(frequency, table)
                        super("Not enough MIDI indices to represent #{frequency} Hz. "\
                              "Available range is  #{table.inspect}")
                end
        end

        # Middle A in MIDI
        MIDI_TONIC = 69

        # Standard western notes per octave assumed by MIDI
        MIDI_OCTAVE_NOTES = 12

        # Maximum increase/decrease between two frequencies we can consider
        # "equal". Approximately 1/30th of human Just Noticeable Difference
        # for pitch.
        FREQUENCY_FUDGE_FACTOR = (1.0/10_000)

        # Set up a MIDI generator for a specific octave structure and tonic
        # We need to know the octave structure because it determines
        # how we allocate MIDI note indices to frequencies.
        def initialize(octave_structure, tonic)
                @chromatic_scale = octave_structure.chromatic_scale.open
                @tonic = tonic
        end

        # Add a phrase to the MIDI output we will generate.
        def add_phrase(phrase)
                @phrases ||= []
                @phrases << phrase
        end

        # @return [Midi::Track] Notes to be output to MIDI; mainly for testing.
        def notes_track(sequence=build_sequence)
                build_notes_track(sequence, @phrases)
        end

        # Write MIDI output to the given stream.
        def write(io)
                sequence = build_sequence
                sequence.tracks << notes_track(sequence)

                # Buffer output so this method can be called on stdout.
                buffer = StringIO.new
                sequence.write(buffer)

                io.write(buffer.string)
        end

        # An array with frequencies in Hertz for each
        # MIDI note in the given octave structure.
        #
        # @param octave_structure [OctaveStructure]
        # @param tonic [Integer] The tonic frequency in Hertz.
        #                        This will correspond to Cacophony frequency 1,
        #                        and MIDI pitch 69
        def frequency_table

                # Use 12-note octaves where possible to maximise the chance of
                # working with regular 12TET-tuned instruments.
                @frequencies ||= if @chromatic_scale.length < MIDI_OCTAVE_NOTES
                        optimise_frequency_matches(@chromatic_scale, @tonic)
                else
                        use_every_midi_note(@chromatic_scale, @tonic)
                end
        end

        private

        # Build a frequency table that maps successive MIDI indices to
        # successive notes in the given scale, using MIDI index space as
        # efficiently as possible at the cost of octaves not lining up.
        def use_every_midi_note(scale, tonic)
                notes_per_octave = scale.length

                (0..127).map do |index|
                        tonic_offset = index - MIDI_TONIC
                        octave_offset, note = tonic_offset.divmod(notes_per_octave)

                        bottom_of_octave = tonic * OctaveStructure::OCTAVE_RATIO**octave_offset
                        bottom_of_octave * scale.note_scalings[note]
                end
        end

        # Build a frequency table that uses standard MIDI frequencies wherever possible,
        # maximising compatibility with 12TET at the cost of a reduced frequency range.
        def optimise_frequency_matches(scale, tonic)
                frequencies_to_cover = scale.note_scalings.dup
                standard_frequencies = MIDI_OCTAVE_NOTES.times.map do |index|
                        OctaveStructure::OCTAVE_RATIO ** (index / MIDI_OCTAVE_NOTES.to_f)
                end

                octave_breakdown = standard_frequencies.each_with_index.map do |standard, index|

                        # We've done all the special frequencies we need; fill gaps with 12TET.
                        next standard if frequencies_to_cover.empty?

                        next_frequency = frequencies_to_cover.first
                        at_or_past_match = next_frequency <= standard * (1 + FREQUENCY_FUDGE_FACTOR)
                        out_of_room = (standard_frequencies.length - index) <= frequencies_to_cover.length

                        if at_or_past_match || out_of_room

                                # Either this is a good spot for this frequency,
                                # or we're out of room to put it anywhere better.
                                frequencies_to_cover.shift
                        else
                                standard
                        end

                end

                (0..127).map do |index|
                        tonic_offset = index - MIDI_TONIC
                        octave_offset, note = tonic_offset.divmod(MIDI_OCTAVE_NOTES)

                        bottom_of_octave = tonic * OctaveStructure::OCTAVE_RATIO**octave_offset
                        bottom_of_octave * octave_breakdown[note]
                end
        end

        def build_sequence
                seq = MIDI::Sequence.new
                seq.tracks << meta_track(seq)
                seq
        end

        # TODO: why do I have to pass `seq` in,
        # when I'm then later adding the track back to seq.tracks?
        def meta_track(seq)
                track = MIDI::Track.new(seq)

                # TODO: handle tempo changes (how?)
                track.events << MIDI::Tempo.new(
                        MIDI::Tempo.bpm_to_mpq(@phrases.first.tempo)
                )
                track.events << MIDI::MetaEvent.new(
                        MIDI::META_SEQ_NAME,
                        'TODO: name sequence'
                )

                track
        end

        # TODO: multiple instruments?
        def build_notes_track(seq, phrases)
                track = MIDI::Track.new(seq)
                track.name = 'Cacophony'

                # TODO: why this particular instrument.
                track.instrument = MIDI::GM_PATCH_NAMES[0]

                # TODO: what's this for?
                track.events << MIDI::ProgramChange.new(0, 1, 0)

                # Inter-note delay from the end of the previous beat.
                leftover_delay = 0

                phrases.each do |phrase|
                        phrase.notes.each do |note|
                                track.events += midi_events_for_note(leftover_delay, note, seq)
                                leftover_delay = seq.length_to_delta(note.beat.after_delay)
                        end
                end

                track
        end

        # TODO: code smell to pass in seq
        def midi_events_for_note(delay_before, note, seq)
                midi_note = midi_index(note)
                beat = note.beat

                [
                        MIDI::NoteOn.new(
                                0,
                                midi_note,
                                (beat.amplitude * 127).ceil,
                                # TODO: can notes be out of order?
                                # Beat duration 1 conveniently matches
                                # midilib's quarter-note = 1.
                                seq.length_to_delta(beat.start_delay) + delay_before
                        ),
                        MIDI::NoteOff.new(
                                0,
                                midi_note,
                                127,
                                seq.length_to_delta(beat.sounding_time)
                        )
                ]
        end

        def midi_index(note)
                # TODO: not reliable for approximate matching
                frequency = @tonic * note.ratio

                if (match = frequency_table.index(frequency))
                        match
                else
                        raise OutOfRange.new(frequency, frequency_table)
                end
        end
end
