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

        # Write MIDI output to the given stream.
        def write(io)
                seq = MIDI::Sequence.new
                seq.tracks << meta_track(seq)
                seq.tracks << notes_track(seq, @phrases)

                # Buffer output so we can send to stdout.
                buffer = StringIO.new
                seq.write(buffer)

                io.write(buffer.string)
        end

        private

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
        def notes_track(seq, phrases)
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
                                midi_note = midi_index(note)
                                beat = note.beat

                                track.events << MIDI::NoteOn.new(
                                        0,
                                        midi_note,
                                        127,
                                        # TODO: can notes be out of order?
                                        # TODO: code smell to refer to seq
                                        # Beat duration 1 conveniently matches
                                        # midilib's quarter-note = 1.
                                        seq.length_to_delta(beat.start_delay) + leftover_delay
                                )

                                track.events << MIDI::NoteOff.new(
                                        0,
                                        midi_note,
                                        127,
                                        seq.length_to_delta(beat.sounding_time)
                                )

                                leftover_delay = seq.length_to_delta(beat.after_delay)
                        end
                end

                track
        end

        def midi_index(note)
                # Guess based on closest 12TET frequency.
                # TODO: need to know about the scale.
                ((Math.log(note.frequency / 440.0, 2) * 12) + 64).round.to_i
        end
end
