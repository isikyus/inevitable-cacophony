# A frequency table maps Dwarf fortress notes (specific frequencies) to
# MIDI indices for use in MIDI indexes.
#
# Where possible we use the standard MIDI values for DF notes; where that
# won't work, we try to keep as close to the MIDI structure as the DF scale
# system will allow.

# Using for OctaveStructure::OCTAVE_RATIO; may be better to just use +2+.
require 'inevitable_cacophony/octave_structure'

module InevitableCacophony
  class MidiGenerator
    class FrequencyTable

      # Raised when there is no MIDI index available for
      # a note we're trying to output
      class OutOfRange < StandardError
        def initialize(frequency, table)
          super("Not enough MIDI indices to represent #{frequency} Hz. "\
                "Available range is  #{table.inspect}")
        end
      end

      # Range of allowed MIDI 1 indices.
      MIDI_RANGE = 0..127

      # Middle A in MIDI
      MIDI_TONIC = 69

      # Standard western notes per octave assumed by MIDI
      MIDI_OCTAVE_NOTES = 12

      # 12TET values of those notes.
      STANDARD_MIDI_FREQUENCIES = MIDI_OCTAVE_NOTES.times.map do |index|
        OctaveStructure::OCTAVE_RATIO**(index / MIDI_OCTAVE_NOTES.to_f)
      end

      # Maximum increase/decrease between two frequencies we still treat as
      # "equal". Approximately 1/30th of human Just Noticeable Difference
      # for pitch.
      FREQUENCY_FUDGE_FACTOR = (1.0 / 10_000)

      # Create a frequency table with a given structure and tonic.
      #
      # @param octave_structure [OctaveStructure]
      # @param tonic [Integer] The tonic frequency in Hertz.
      #                        This will correspond to Cacophony frequency 1,
      #                        and MIDI pitch 69
      def initialize(octave_structure, tonic)
        @tonic = tonic
        @table = build_table(octave_structure, tonic)
      end

      attr_reader :table

      # @param ratio [Float] The given note as a ratio to the tonic
      #                       (e.g. A above middle A = 2.0)
      def index_for_ratio(ratio)
        # TODO: not reliable for approximate matching
        frequency = @tonic * ratio

        if (match = table.index(frequency))
          match
        else
          raise OutOfRange.new(frequency, table)
        end
      end

      private

      def build_table(octave_structure, tonic)
        chromatic = octave_structure.chromatic_scale.open.note_scalings
        octave_breakdown = best_match_ratios(chromatic)

        MIDI_RANGE.map do |index|
          tonic_offset = index - MIDI_TONIC
          octave_offset, note = tonic_offset.divmod(octave_breakdown.length)

          bottom_of_octave = tonic * OctaveStructure::OCTAVE_RATIO**octave_offset
          bottom_of_octave * octave_breakdown[note]
        end
      end

      # Pick a MIDI index within the octave for each given frequency.
      #
      # If there are few enough (<12) frequencies in the generated scale,
      # we try to keep as much of the normal MIDI tuning as possible, and
      # only re-tune what we need. If the DF scale is a subset of 12TET,
      # this should return the standard MIDI tuning.
      #
      # Other than that it isn't guaranteed to be optimal; currently it's
      # a fairly naieve greedy algorithm.
      #
      # @return [Array] Re-tuned ratios for each position in the MIDI octave.
      def best_match_ratios(frequencies_to_cover)
        standard_octave = STANDARD_MIDI_FREQUENCIES.dup
        ratios = []

        while (next_frequency = frequencies_to_cover.shift)

          # Skip ahead (padding slots with 12TET frequencies from low to high) until:
          #
          # * the next 12TET frequency would be sharper, or
          # * any more padding will leave us without enough space.
          while (standard = standard_octave.shift) &&
                sounds_flatter?(standard, next_frequency) &&
                standard_octave.length > frequencies_to_cover.length

            ratios << standard
          end

          # Use this frequency in this slot.
          ratios << next_frequency
        end

        ratios
      end

      # Like < but considers values within FREQUENCY_FUDGE_FACTOR equal
      def sounds_flatter?(a, b)
        threshold = b * (1 - FREQUENCY_FUDGE_FACTOR)
        a < threshold
      end
    end
  end
end
