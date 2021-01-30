# Represents and parses Dwarf Fortress scale descriptions

require 'inevitable_cacophony/parser/sectioned_text'

module InevitableCacophony
  class OctaveStructure

    # Frequency scaling for a difference of one whole octave
    OCTAVE_RATIO = 2

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
    end

    class Chord < NoteSequence
    end

    # As above, but also tracks the chords that make up the scale.
    class Scale < NoteSequence

      # @param chords [Array<Chord>]
      #        The chords that make up the scale, in order.
      # @param note_scalings [Array<Fixnum>]
      #        Specific note scalings to use; for internal use.
      def initialize(chords, note_scalings=nil)
        @chords = chords
        super(note_scalings || chords.map(&:note_scalings).flatten)
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

    # Regular expressions used in parsing
    OCTAVE_STRUCTURE_SENTENCE = /Scales are constructed/

    # @param scale_text [String] Dwarf Fortress musical form description
    #                   including scale information.
    # TODO: Allow contructing these without parsing text
    def initialize(scale_text)
      description = Parser::SectionedText.new(scale_text)
      octave_description = description.find_paragraph(OCTAVE_STRUCTURE_SENTENCE)
      @octave_divisions = parse_octave_structure(octave_description)

      @chords = parse_chords(description)
      @scales = parse_scales(description, chords)
    end

    attr_reader :chords, :scales

    # @return [Scale] A scale including all available notes in the octave.
    #                 (As the chromatic scale does for pianos etc.)
    def chromatic_scale
      Scale.new([], @octave_divisions + [2])
    end

    private

    def parse_octave_structure(octave_paragraph)
      octave_sentence = octave_paragraph.find(OCTAVE_STRUCTURE_SENTENCE)
      note_count_match = octave_sentence.match(/Scales are constructed from ([-a-z ]+) notes spaced evenly throughout the octave/)

      if note_count_match
        note_count_word = note_count_match.captures.first
        divisions = parse_number_word(note_count_word)
        numerator = divisions.to_f

        (0...divisions).map { |index| 2**(index / numerator) }
      else
        parse_exact_notes(octave_paragraph)
      end
    end

    def parse_exact_notes(octave_paragraph)
      exact_spacing_sentence = octave_paragraph.find(/their spacing is roughly/)
      spacing_match = exact_spacing_sentence.match(/In quartertones, their spacing is roughly 1((-|x){23})0/)

      if spacing_match
        # Always include the tonic
        note_scalings = [1]

        note_positions = spacing_match.captures.first
        step_size = 2**(1.0 / note_positions.length.succ)
        ratio = 1
        note_positions.each_char do |pos|
          ratio *= step_size

          case pos
          when 'x'
            note_scalings << ratio
          when '-'
            # Do nothing; no note here
          else
            raise "Unexpected note position symbol #{pos.inspect}"
          end
        end

        note_scalings
      else
        raise "Cannot parse octave text"
      end
    end

    # @param description [Parser::SectionedText]
    #        The description text from which to extract chord data.
    def parse_chords(description)

      # TODO: extract to constant
      chord_paragraph_regex = /The ([^ ]+) [a-z]*chord is/

      {}.tap do |chords|
        chord_paragraphs =
          description.find_all_paragraphs(chord_paragraph_regex)

        chord_paragraphs.each do |paragraph|
          degrees_sentence = paragraph.find(chord_paragraph_regex)

          name, degrees = degrees_sentence.match(
            /The ([^ ]+) [a-z]*chord is the (.*) degrees of the .* scale/
          ).captures
          chords[name.to_sym] = parse_chord(degrees)
        end
      end
    end

    # @param degrees[String] The list of degrees used by this particular scale
    def parse_chord(degrees)
      ordinals = degrees.split(/(?:,| and) the/)

      chord_notes = ordinals.map do |degree_ordinal|
        # degree_ordinal is like "4th",
        # or may be like "13th (completing the octave)"
        # in which case it's not in our list of notes,
        # but always has a factor of 2
        # (the tonic, an octave higher)

        if degree_ordinal.include?('(completing the octave)')
          2
        else
          index = degree_ordinal.strip.to_i
          @octave_divisions[index - 1]
        end
      end

      Chord.new(chord_notes)
    end

    # @param description [Parser::SectionedText]
    # @param chords [Hash{Symbol,Chord}]
    def parse_scales(description, chords)
      scale_topic_regex = /The [^ ]+ [^ ]+ scale is/

      {}.tap do |scales|
        description
          .find_all_paragraphs(scale_topic_regex)
          .each do |scale_paragraph|
            scale_sentence = scale_paragraph.find(scale_topic_regex)
            name, scale_type = scale_sentence.match(
              /The ([^ ]+) [a-z]+tonic scale is (thought of as .*|constructed by)/
            ).captures

            case scale_type
            when /thought of as ([a-z]+ )?(disjoint|joined) chords/
              scales[name.to_sym] = parse_disjoint_chords_scale(scale_paragraph,
                                                                chords)
            else
              raise "Unknown scale type #{scale_type} in #{scale_sentence}"
            end
          end
      end
    end

    def parse_disjoint_chords_scale(scale_paragraph, chords)
      chords_sentence = scale_paragraph.find(/These chords are/)
      chord_list = chords_sentence
        .match(/These chords are named ([^.]+)\.?/)
        .captures
        .first
      chord_names = chord_list.split(/,|and/).map(&:strip).map(&:to_sym)

      Scale.new(chords.values_at(*chord_names))
    end

    # Convert a number word to text -- rough approximation for now.
    # TODO: Rails or something may do this.
    #
    # @param word [String]
    # @return [Fixnum]
    def parse_number_word(word)
      words_to_numbers = {
        'one' => 1,
        'two' => 2,
        'three' => 3,
        'four' => 4,
        'five' => 5,
        'six' => 6,
        'seven' => 7,
        'eight' => 8,
        'nine' => 9,
        'ten' => 10,
        'eleven' => 11,
        'twelve' => 12,
        'thirteen' => 13,
        'fourteen' => 14,
        'fifteen' => 15,
        'sixteen' => 16,
        'seventeen' => 17,
        'eighteen' => 18,
        'nineteen' => 19,
      }

      if words_to_numbers[word]
        words_to_numbers[word]
      elsif word.start_with?('twenty-')
        words_to_numbers[word.delete_prefix('twenty-')] + 20
      else
        "Unsupported number name #{word}"
      end
    end
  end
end
