# A frequency table maps Dwarf fortress notes (specific frequencies) to
# MIDI indices for use in MIDI indexes.
#
# Where possible we use the standard MIDI values for DF notes; where that
# won't work, we try to keep as close to the MIDI structure as the DF scale
# system will allow.

# Using for OctaveStructure::OCTAVE_RATIO; may be better to just use +2+.
require 'octave_structure'

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
                        OctaveStructure::OCTAVE_RATIO ** (index / MIDI_OCTAVE_NOTES.to_f)
                end

                # Maximum increase/decrease between two frequencies we still treat as
                # "equal". Approximately 1/30th of human Just Noticeable Difference
                # for pitch.
                FREQUENCY_FUDGE_FACTOR = (1.0/10_000)

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
                        octave_breakdown = (chromatic.length <= MIDI_OCTAVE_NOTES) ?
                                                best_match_ratios(chromatic) :
                                                chromatic

                        MIDI_RANGE.map do |index|
                                tonic_offset = index - MIDI_TONIC
                                octave_offset, note = tonic_offset.divmod(octave_breakdown.length)

                                bottom_of_octave = tonic * OctaveStructure::OCTAVE_RATIO**octave_offset
                                bottom_of_octave * octave_breakdown[note]
                        end
                end

                # Pick a MIDI index within the octave (0..11) for each given frequency.
                # (Ideally one close to the actual target frequency, or the exact match
                # if there is one).
                # Assumes there are 12 or fewer target frequencies (if not there's no point
                # trying to match them because they won't match up after one octave anyway).
                #
                # The remaining space is left as the default MIDI frequencies, not that it
                # matters for our purposes.
                #
                # @return [Array] Re-tuned ratios for each position in the MIDI octave.
                def best_match_ratios(frequencies_to_cover)
                        STANDARD_MIDI_FREQUENCIES.each_with_index.map do |standard, index|

                                # We've done all the special frequencies we need; fill gaps with 12TET.
                                next standard if frequencies_to_cover.empty?

                                next_frequency = frequencies_to_cover.first
                                at_or_past_match = next_frequency <= standard * (1 + FREQUENCY_FUDGE_FACTOR)
                                out_of_room = (STANDARD_MIDI_FREQUENCIES.length - index) <= frequencies_to_cover.length

                                if at_or_past_match || out_of_room

                                        # Either this is a good spot for this frequency,
                                        # or we're out of room to put it anywhere better.
                                        frequencies_to_cover.shift
                                else
                                        standard
                                end
                        end
                end
        end
end
