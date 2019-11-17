require 'spec_helper'

require 'midi_generator'
require 'phrase'
require 'note'
require 'rhythm'
require 'octave_structure'

RSpec.describe MidiGenerator do
        subject(:midi_generator) do
                MidiGenerator.new
        end

        let(:octave_structure) do
                octave = OctaveStructure.new(<<-OCTAVE)
                Scales are constructed from eleven notes spaced evenly throughout the octave.
                (This guarantees our notes don't line up with 12TET)

                The elven hexatonic scale is thought of as two disjoint chords spanning no particular interval.
                These chords are named alpha and beta.

                The alpha trichord is the 1st, the 3rd, and the 5th degrees of the eleven-note octave scale.

                The beta trichord is the 7th, the 9th, and the 12th (completing the octave) degrees of the eleven-note octave scale.
                OCTAVE
        end

        let(:scale) do
                octave_structure.scales[:elven]
        end

        let(:beats) do
                [Rhythm::Beat.new(1, 1, 0)] * 5
        end

        let(:phrase) do
                Phrase.new(
                        *[
                                # First two notes are in the previous octave
                                Note.new(scale.note_scalings[-2] / 2, beats[0]),
                                Note.new(scale.note_scalings[-1] / 2, beats[1]),
                                Note.new(scale.note_scalings[0], beats[2]),
                                Note.new(scale.note_scalings[1], beats[3]),
                                Note.new(scale.note_scalings[2], beats[4])
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

        context 'mapping scale information' do
                # Middle A - 440 Hertz
                let(:tonic) { 440.0 }

                specify 'assigns MIDI notes according to a consistent mapping' do
                        note_ons = track.select { |e| e.is_a?(MIDI::NoteOn) }
                        frequency_table = midi_generator.frequency_table(octave_structure, tonic)
                        midi_frequencies = note_ons.map { |n| frequency_table[n.note] }

                        expect(midi_frequencies[0]).to be_within(0.5).of(tonic * phrase.notes[0].frequency)
                        expect(midi_frequencies[1]).to be_within(0.5).of(tonic * phrase.notes[1].frequency)
                        expect(midi_frequencies[2]).to be_within(0.5).of(tonic * phrase.notes[2].frequency)
                        expect(midi_frequencies[3]).to be_within(0.5).of(tonic * phrase.notes[3].frequency)
                        expect(midi_frequencies[4]).to be_within(0.5).of(tonic * phrase.notes[4].frequency)
                end
        end
end
