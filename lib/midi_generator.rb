# Converts Inevitable Cacophony internal note representation
# into MIDI messages usable by an external synthesizer.
# Based on examples in the `midilib` gem.

require 'midilib/sequence'
require 'midilib/consts'

class MidiGenerator

        # Add a phrase to the MIDI output we will generate.
        def add_phrase(phrase)
                @phrases ||= []
                @phrases << phrase
        end

        # @return [Midi::Track] Notes to be output to MIDI; mainly for testing.
        def notes_track
                build_notes_track(sequence, @phrases)
        end

        # Write MIDI output to the given stream.
        def write(io)
                sequence.tracks << notes_track

                # Buffer output so we can send to stdout.
                buffer = StringIO.new
                sequence.write(buffer)

                io.write(buffer.string)
        end

        private

        def sequence
                @sequence ||= begin
                                 seq = MIDI::Sequence.new
                                 seq.tracks << meta_track(seq)
                                 seq
                         end
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
                # Guess based on closest 12TET frequency.
                # TODO: need to know about the scale.
                ((Math.log(note.frequency / 440.0, 2) * 12) + 64).round.to_i
        end
end
