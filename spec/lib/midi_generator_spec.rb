# frozen_string_literal: true

require 'spec_helper'

require 'inevitable_cacophony/midi_generator'
require 'inevitable_cacophony/phrase'
require 'inevitable_cacophony/note'
require 'inevitable_cacophony/rhythm'
require 'inevitable_cacophony/octave_structure'

RSpec.describe InevitableCacophony::MidiGenerator do
  subject(:midi_generator) do
    InevitableCacophony::MidiGenerator.new(octave_structure, tonic)
  end

  # Middle A - 440 Hertz
  let(:tonic) { 440.0 }

  let(:midi_tonic) do
    InevitableCacophony::MidiGenerator::FrequencyTable::MIDI_TONIC
  end

  let(:octave_structure) do
    InevitableCacophony::OctaveStructure.new(<<-OCTAVE)
    Scales are constructed from seven notes spaced evenly throughout the octave.
    (This guarantees our notes don't line up with 12TET)

    The test hexatonic scale is thought of as two disjoint chords spanning no
    particular interval.
    These chords are named alpha and beta.

    The alpha trichord is the 1st, the 2nd, and the 4th degrees of the
    seven-note octave scale.

    The beta trichord is the 5th, the 6th, and the 8th (completing the octave)
    degrees of the seven-note octave scale.
    OCTAVE
  end

  let(:scale) do
    octave_structure.scales[:test].open
  end

  let(:beats) do
    [InevitableCacophony::Rhythm::Beat.new(1, 1, 0)] * 5
  end

  let(:phrase) do
    InevitableCacophony::Phrase.new(
      # First two notes are in the previous octave
      InevitableCacophony::Note.new(scale.note_scalings[-2] / 2, beats[0]),
      InevitableCacophony::Note.new(scale.note_scalings[-1] / 2, beats[1]),
      InevitableCacophony::Note.new(scale.note_scalings[0], beats[2]),
      InevitableCacophony::Note.new(scale.note_scalings[1], beats[3]),
      InevitableCacophony::Note.new(scale.note_scalings[2], beats[4]),
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
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 2, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 0.5, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0)
      ]
    end

    specify 'preserves them' do
      # InevitableCacophony::Note duration is time before the note-*off* event
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
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 1, -1),
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 1, +1)
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
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(0.5, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(0.25, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(0, 1, 0),
        InevitableCacophony::Rhythm::Beat.new(1, 1, 0)
      ]
    end

    specify 'preserves the different volumes' do
      note_ons = track.events.select { |e| e.is_a?(MIDI::NoteOn) }
      velocities = note_ons.map(&:velocity)

      expect(velocities[0]).to eq 127
      expect(velocities[1]).to eq 64
      expect(velocities[2]).to eq 32
      expect(velocities[3]).to eq 0
      expect(velocities[4]).to eq 127
    end
  end

  context 'mapping scale information' do
    let(:note_ons) do
      track.select { |e| e.is_a?(MIDI::NoteOn) }
    end

    let(:midi_frequencies) do
      note_ons.map { |n| midi_generator.frequency_table.table[n.note] }
    end

    let(:out_of_range) do
      InevitableCacophony::MidiGenerator::FrequencyTable::OutOfRange
    end

    shared_examples_for 'scale mapping' do
      specify 'assigns MIDI notes that match the frequency table' do
        midi_frequencies.each_with_index do |frequency, index|
          expect(frequency)
            .to be_within(0.01)
            .of(tonic * phrase.notes[index].frequency)
        end
      end

      specify 'uses distinct MIDI notes for different frequencies' do
        expect(midi_frequencies.to_set)
          .to eq(phrase.notes.map { |n| tonic * n.frequency }.to_set)
      end
    end

    context 'with a 7-note scale that fits in the octave' do
      include_examples 'scale mapping'

      context 'with notes at the edges of MIDI range' do
        let(:last_note_in_midi) do
          # Scale note 5 (6th degree of the octave/7;
          # 1.64 times the tonic) in the 4th octave is
          # the highest note in our scale that's
          # less than MIDI's note 127 (G9).
          #
          # This is somewhere between 12TET's F9 and F#9
          InevitableCacophony::Note.new(
            scale.note_scalings[4] * 2**4,
            beats[1]
          )
        end

        let(:last_index_in_midi) do
          midi_tonic + (5 * 12) - 4
        end

        let(:phrase) do
          InevitableCacophony::Phrase.new(
            InevitableCacophony::Note.new(scale.note_scalings[0] / 2**5,
                                          beats[0]),
            last_note_in_midi,
            tempo: 120
          )
        end

        specify 'preserves relative position in the octave' do
          expect(note_ons[0].note).to eq(midi_tonic - (5 * 12))

          expect(note_ons[1].note).to be_between(
            last_index_in_midi,
            last_index_in_midi + 1
          )
        end

        specify 'assigns MIDI notes that match the frequency table' do
          expect(midi_frequencies[0])
            .to be_within(0.01)
            .of(tonic * phrase.notes[0].frequency)

          expect(midi_frequencies[1])
            .to be_within(0.01)
            .of(tonic * phrase.notes[1].frequency)
        end
      end

      context "with notes outside of MIDI's range" do
        let(:phrase) do
          InevitableCacophony::Phrase.new(
            InevitableCacophony::Note.new(scale.note_scalings[0] / 2**6,
                                          beats[0]),
            InevitableCacophony::Note.new(scale.note_scalings[0] * 2**6,
                                          beats[1]),
            tempo: 120
          )
        end

        specify 'fails cleanly' do
          expect do
            track
          end.to raise_error(out_of_range)
        end
      end
    end

    context 'with more notes per octave than 12TET' do
      let(:octave_structure) do
        InevitableCacophony::OctaveStructure.new(<<-OCTAVE)
        Scales are constructed from twenty-one notes spaced evenly throughout
        the octave.

        The test hexatonic scale is thought of as two disjoint chords spanning
        no particular interval.
        These chords are named alpha and beta.

        The alpha trichord is the 1st, the 5th, and the 9th degrees of the
        twenty-one-note octave scale.

        The beta trichord is the 11th, the 16th, and the 21st
        (completing the octave) degrees of the twenty-one-note octave scale.
        OCTAVE
      end

      include_examples 'scale mapping'

      context 'with notes at the edges of MIDI range' do
        let(:phrase) do
          InevitableCacophony::Phrase.new(
            InevitableCacophony::Note.new(scale.note_scalings[0] / 2**2,
                                          beats[0]),
            InevitableCacophony::Note.new(scale.note_scalings[0] * 2**2,
                                          beats[1]),
            tempo: 120
          )
        end

        specify 'uses nonstandard octave size to keep notes distinct' do
          expect(note_ons[0].note).to eq(midi_tonic - (2 * 21))
          expect(note_ons[1].note).to eq(midi_tonic + (2 * 21))
        end

        specify 'assigns MIDI notes that match the frequency table' do
          expect(midi_frequencies[0])
            .to be_within(0.01)
            .of(tonic * phrase.notes[0].frequency)

          expect(midi_frequencies[1])
            .to be_within(0.01)
            .of(tonic * phrase.notes[1].frequency)
        end
      end

      context "with notes outside of MIDI's range" do
        let(:phrase) do
          InevitableCacophony::Phrase.new(
            InevitableCacophony::Note.new(scale.note_scalings[0] / 2**4,
                                          beats[0]),
            InevitableCacophony::Note.new(scale.note_scalings[-1] * 2**4,
                                          beats[1]),
            tempo: 120
          )
        end

        specify 'fails cleanly' do
          expect { track }.to raise_error(out_of_range)
        end
      end
    end

    context 'with exactly a 12-tone scale' do
      let(:octave_structure) do
        InevitableCacophony::OctaveStructure.new(<<-OCTAVE)
        Scales are constructed from twelve notes spaced evenly throughout the
        octave.

        The test amajorishtonic scale is thought of as two disjoint chords
        spanning no particular interval.
        These chords are named alpha and beta.

        The alpha pentachord is the 1st, the 3rd, the 5th, and the 6th degrees
        of the twelve-note octave scale.

        The beta tetrachord is the 8th, the 10th, the 12th, and the 13th
        (completing the octave) degrees of the twelve-note octave scale.
        OCTAVE
      end

      specify 'assigns the correct MIDI notes' do
        expect(note_ons[0].note).to eq(midi_tonic - 3)
        expect(note_ons[1].note).to eq(midi_tonic - 1)
        expect(note_ons[2].note).to eq(midi_tonic + 0)
        expect(note_ons[3].note).to eq(midi_tonic + 2)
        expect(note_ons[4].note).to eq(midi_tonic + 4)
      end
    end

    context 'with a scale that is a subset of 12TET' do
      let(:octave_structure) do
        InevitableCacophony::OctaveStructure.new(<<-OCTAVE)
          Scales are constructed from nine notes dividing the octave.
          In quartertones, their spacing is roughly 1--x--x--x--x--x--x--x--0,
          where 1 is the tonic, 0 marks the octave, and x marks other notes.
        OCTAVE
      end

      let(:scale) { octave_structure.chromatic_scale.open }

      include_examples 'scale mapping'

      specify 'assigns matching MIDI notes where possible' do
        expect(note_ons[0].note).to eq(midi_tonic - 3)
        # expect(note_ons[1].note).to eq(midi_tonic - 1.5)
        expect(note_ons[2].note).to eq(midi_tonic + 0)
        # expect(note_ons[3].note).to eq(midi_tonic + 1.5)
        expect(note_ons[4].note).to eq(midi_tonic + 3)
      end
    end
  end
end
