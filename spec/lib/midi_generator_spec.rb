require 'spec_helper'

require 'midi_generator'
require 'phrase'
require 'note'
require 'rhythm'

RSpec.describe MidiGenerator do
        subject(:midi_generator) do
                MidiGenerator.new
        end

        let(:phrase) do
                Phrase.new(
                        *[
                                Note.new(440, beats[0]),
                                Note.new(550, beats[1]),
                                Note.new(660, beats[2]),
                                Note.new(770, beats[3]),
                                Note.new(880, beats[4])
                        ],
                        tempo: 120
                )
        end

        let(:track) do
                midi_generator.add_phrase(phrase)
                midi_generator.notes_track
        end

        context 'with a variety of note durations' do
                let(:beats) do
                        [
                                Rhythm::Beat.new(1, 1, 0),
                                Rhythm::Beat.new(1, 2, 0),
                                Rhythm::Beat.new(1, 1, 0),
                                Rhythm::Beat.new(1, 0.5, 0),
                                Rhythm::Beat.new(1, 1, 0)
                        ]
                end

                specify 'preserves them' do
                        # Note duration is time before the note-*off* event
                        note_offs = track.events.select { |e| e.is_a?(MIDI::NoteOff) }

                        # Assume the first note has the correct duration,
                        # and use it to check the rest.
                        expect(note_offs[1].delta_time).to eq(2 * note_offs[0].delta_time)
                        expect(note_offs[2].delta_time).to eq(note_offs[0].delta_time)
                        expect(note_offs[3].delta_time).to eq(0.5 * note_offs[0].delta_time)
                        expect(note_offs[4].delta_time).to eq(note_offs[0].delta_time)
                end
        end

        context 'with early and late beats' do
                let(:beats) do
                        [
                                Rhythm::Beat.new(1, 1, 0),
                                Rhythm::Beat.new(1, 1, 0),
                                Rhythm::Beat.new(1, 1, -1),
                                Rhythm::Beat.new(1, 1, 0),
                                Rhythm::Beat.new(1, 1, +1)
                        ]
                end

                specify 'creates early and late notes' do

                        # Ensure the `time_from_start` field is usable on these notes.
                        track.recalc_times
                        note_ons = track.events.select { |e| e.is_a?(MIDI::NoteOn) }
                        start_deltas = note_ons.each_cons(2).map do |first, second|
                                second.time_from_start - first.time_from_start
                        end

                        # start_deltas[0] is the space between notes 0 and 1
                        expect(start_deltas[1]).to be < start_deltas[0]
                       
                        expect(start_deltas[2]).to be > start_deltas[0]
                        expect(start_deltas[1..2].sum).to eq(2 * start_deltas[0])

                        expect(start_deltas[3]).to be > start_deltas[0]
                end
        end

        context 'with varying amplitude' do
                let(:beats) do
                        [
                                Rhythm::Beat.new(1, 1, 0),
                                Rhythm::Beat.new(0.5, 1, 0),
                                Rhythm::Beat.new(0.25, 1, 0),
                                Rhythm::Beat.new(0, 1, 0),
                                Rhythm::Beat.new(1, 1, 0)
                        ]
                end

                specify 'preserves the different volumes' do
                        note_ons = track.events.select { |e| e.is_a?(MIDI::NoteOn) }
                        velocities = note_ons.map { |n| n.velocity }

                        expect(velocities[0]).to eq 127
                        expect(velocities[1]).to eq 64
                        expect(velocities[2]).to eq 32
                        expect(velocities[3]).to eq 0
                        expect(velocities[4]).to eq 127
                end
        end

        specify 'preserves frequencies'
end
