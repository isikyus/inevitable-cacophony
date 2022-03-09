# frozen_string_literal: true

require 'midilib/sequence'
require 'midilib/consts'

require 'inevitable_cacophony/midi_generator/frequency_table'

module InevitableCacophony
  # Converts Inevitable Cacophony internal note representation
  # into MIDI messages usable by an external synthesizer.
  # Based on examples in the `midilib` gem.
  class MidiGenerator
    # Set up a MIDI generator for a specific octave structure and tonic
    # We need to know the octave structure because it determines
    # how we allocate MIDI note indices to frequencies.
    def initialize(octave_structure, tonic)
      @frequency_table = FrequencyTable.new(octave_structure, tonic)
    end

    attr_reader :frequency_table

    # Add a phrase to the MIDI output we will generate.
    def add_phrase(phrase)
      @phrases ||= []
      @phrases << phrase
    end

    # @return [Midi::Track] Notes to be output to MIDI; mainly for testing.
    def notes_track(sequence = build_sequence)
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

    private

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

      track.instrument = MIDI::GM_PATCH_NAMES[24]

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
      midi_note = @frequency_table.index_for_ratio(note.ratio)
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
  end
end
