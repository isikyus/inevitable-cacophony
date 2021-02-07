# frozen_string_literal: true

require 'inevitable_cacophony/rhythm'

module InevitableCacophony
  module Parser
    # Parses Dwarf Fortress rhythm lines, like | x x'X - |,
    # into Inevitable Cacophony's own internal rhythm representation.
    class RhythmLine
      # Amplitude symbols used by Dwarf Fortress
      # These are in no particular scale; the maximum volume will be whatever's
      # loudest in any particular string.
      BEAT_VALUES = {

        # Silence
        '-' => 0,

        # Regular beat
        'x' => 4,

        # Accented beat
        'X' => 6,

        # Primary accent
        '!' => 9
      }.freeze

      # Values for each kind of timing symbol.
      # By default a beat is in the middle of its time-slice (0.0);
      # a value of 1.0 means to play it as late as possible,
      # and -1.0 means play as early as possible.
      #
      # Technically position of these matters,
      # but we handle that in the parser regexp.
      TIMING_VALUES = {

        # Normal beat (no special timing)
        '' => 0.0,

        # Early beat
        '`' => -1.0,

        # Late beat
        '\'' => 1.0
      }.freeze

      BAR_LINE = '|'

      # @param rhythm_string [String] In the notation Dwarf Fortress produces,
      #                               like | X x ! x |
      # @return [Rhythm]
      def parse(rhythm_string)
        # TODO: should I be ignoring bar lines?
        # Is there anything I can do with them?
        # TODO: extract split regexp to a constant
        raw_beats = rhythm_string
                    .split(/ |(?=`)|(?<=')/)
                    .reject { |beat| beat == BAR_LINE }
                    .map { |beat| parse_beat(beat) }

        # Ensure all our amplitudes are between 0.0 and 1.0
        # TODO: find a way to do this without creating beats twice.
        highest_volume = raw_beats.map(&:amplitude).max
        scaled_beats = raw_beats.map do |beat|
          scaled = beat.amplitude.to_f / highest_volume
          Rhythm::Beat.new(scaled, 1, beat.timing)
        end

        Rhythm.new(scaled_beats)
      end

      def parse_beat(beat_string)
        timing_symbol = beat_string
                        .chars
                        .reject { |char| BEAT_VALUES.key?(char) }
                        .join
        timing = TIMING_VALUES[timing_symbol]
        raise "Unknown timing symbol #{timing_symbol}" unless timing

        accent_symbol = beat_string.delete(timing_symbol)
        amplitude = BEAT_VALUES[accent_symbol]
        raise "Unknown beat symbol #{accent_symbol}" unless amplitude

        Rhythm::Beat.new(amplitude, 1, timing)
      end

      def self.parse(rhythm_string)
        new.parse(rhythm_string)
      end
    end
  end
end
