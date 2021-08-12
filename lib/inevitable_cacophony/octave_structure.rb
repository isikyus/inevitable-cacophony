# frozen_string_literal: true

require 'inevitable_cacophony/parser/scale_description'

module InevitableCacophony
  # Represents Dwarf Fortress scales, and the chords and understanding
  # of octaves used to build them.
  class OctaveStructure
    # Frequency scaling for a difference of one whole octave
    OCTAVE_RATIO = 2

    PERFECT_FOURTH = 4 / 3.0

    # Represent a sequence of notes from an octave -- either a chord,
    # or the notes of a scale.
    # TODO: call this something more useful
    class NoteSequence
      # @param note_scalings [Array<Float>]
      #   The frequencies of each note in the scale,
      #   as multiples of the tonic.
      def initialize(note_scalings)
        @note_scalings = note_scalings
      end

      attr_accessor :note_scalings

      def length
        note_scalings.length
      end

      # Returns a new note sequence transposed up or down by the given ratio
      def transpose(ratio)
        self.class.new(transposed_notes(ratio))
      end

      private

      def transposed_notes(ratio)
        @note_scalings.map { |ns| ns * ratio }
      end
    end

    class Chord < NoteSequence
    end

    # As above, but also tracks the chords that make up the scale.
    class Scale < NoteSequence
      # Build a scale from two chords based on a perfect-fourth division.
      # This requires a different method because the second chord of a
      # perfect-fourth scale is implicitly transposed up a perfect fourth.
      #
      # @param low_fourth [Chord]
      # @param high_fourth [Chord]
      def self.fourth_division(low_fourth, high_fourth)
        new([low_fourth, high_fourth.transpose(OCTAVE_RATIO / PERFECT_FOURTH)])
      end

      # @param chords [Array<Chord>]
      #        The chords that make up the scale, in order.
      # @param note_scalings [Array<Fixnum>]
      #        Specific note scalings to use; for internal use.
      def initialize(chords, note_scalings = nil)
        @chords = chords
        super(note_scalings || chords.map(&:note_scalings).flatten)
      end

      def transpose(ratio)
        Scale.new(
          chords.map { |ch| ch.transpose(ratio) },
          transposed_notes(ratio)
        )
      end

      # Convert this scale to an "open" one -- i.e. one not including
      # the last note of the octave.
      #
      # This form is more convenient when concatenating scales together.
      #
      # @return [Scale]
      def open
        if note_scalings.last == OCTAVE_RATIO

          # -1 is the last note; we want to end on the one before that, so -2
          Scale.new(@chords, note_scalings[0..-2])
        else
          # This scale is already open.
          self
        end
      end
    end

    # @param scale_text [String] Dwarf Fortress musical form description
    #                   including scale information.
    # TODO: Allow contructing these without parsing text
    def initialize(scale_text)
      parser = Parser::ScaleDescription.new
      scale_data = parser.parse(scale_text)

      @octave_divisions = build_octave_structure(scale_data[:octave_divisions])
      @chords = build_chords(scale_data[:chords], @octave_divisions)
      @scales = build_scales(scale_data[:scales], @chords)
    end

    attr_reader :chords, :scales

    # @return [Scale] A scale including all available notes in the octave.
    #                 (As the chromatic scale does for pianos etc.)
    def chromatic_scale
      Scale.new([], @octave_divisions + [2])
    end

    private

    def build_octave_structure(octave_divisions)
      type, data = octave_divisions

      # TODO: consider destructuring, and/or maybe union types.
      case type
      when :perfect_fourth_division
        perfect_fourth_division(data)

      when :evenly_spaced
        divisions = data
        numerator = divisions.to_f
        (0...divisions).map { |index| 2**(index / numerator) }

      when :specific_quartertones
        selected_divisions(data)
      else
        raise "Unknown octave division type #{type}"
      end
    end

    def perfect_fourth_division(notes_per_fourth)
      # Unlike the octave-based divisions, I _believe_ divisions of the perfect
      # fourth include the perfect fourth as the last division (otherwise you'd
      # be missing that really-good-sounding perfect fourth above the tonic).
      divisions = notes_per_fourth - 1
      numerator = divisions.to_f

      fourth_structure = (0...divisions).map do |index|
        PERFECT_FOURTH**(index / numerator)
      end

      [
        fourth_structure,
        PERFECT_FOURTH,
        fourth_structure.map { |ratio| (OCTAVE_RATIO / PERFECT_FOURTH) * ratio }
      ].flatten
    end

    # @param divisions [Array<TrueClass,FalseClass>] Which specific quartertones
    #         (or other points on an equal division; this method doesn't care
    #         how long the array is) make up the scale. Only entries with 'true'
    #         will become notes in the scale; the rest are left out but still
    #         count for the spacing of the used entries.
    def selected_divisions(divisions)
      # Always include the tonic
      note_scalings = [1]
      step_size = 2**(1.0 / divisions.length.succ)
      ratio = 1
      divisions.each do |pos|
        ratio *= step_size
        note_scalings << ratio if pos
      end
      note_scalings
    end

    # @param chord_data [Hash{Symbol,Array<Integer>}
    # @param octave_divisions [OctaveStructure]
    def build_chords(chord_data, octave_divisions)
      chord_data.transform_values do |degrees|
        chord_notes = degrees.map do |d|
          d == :octave ? 2 : octave_divisions[d]
        end
        Chord.new(chord_notes)
      end
    end

    # @param scale_data [Hash{Symbol,Array[Symbol]}]
    # @param chords [Hash{Symbol,Chord}]
    def build_scales(scale_data, chords)
      scale_data.transform_values do |type, chords_used|
        scale_chords = chords.values_at(*chords_used)

        case type
        when :disjoint
          Scale.new(scale_chords)
        when :fourth_division
          Scale.fourth_division(*scale_chords)
        else
          raise "Unknown scale type #{type}"
        end
      end
    end
  end
end
