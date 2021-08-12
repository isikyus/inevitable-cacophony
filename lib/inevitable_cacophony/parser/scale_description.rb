# frozen_string_literal: true

require 'inevitable_cacophony/parser/sectioned_text'

module InevitableCacophony
  module Parser
    # Parses Dwarf Fortress scale descriptions:
    # scale construction, scales, and chords
    class ScaleDescription
      # Regular expressions used in parsing
      OCTAVE_STRUCTURE_SENTENCE = /Scales are (constructed|conceived)/.freeze
      PERFECT_FOURTH_STRUCTURE =
          /Scales are conceived of as two chords built using a division of the perfect fourth interval into ([a-z ]+) notes/
      EVENLY_SPACED_STRUCTURE =
          /Scales are constructed from ([-a-z ]+) notes spaced evenly throughout the octave/
          
      CHORD_PARAGRAPH_REGEXP = /The ([^ ]+) [a-z]*chord is/
      
      # @param scale_text [String] 
      def parse(scale_text)
        description = Parser::SectionedText.new(scale_text)
        octave_description = description.find_paragraph(OCTAVE_STRUCTURE_SENTENCE)
        
        {
          octave_divisions: parse_octave_divisions(octave_description),
          chords: parse_chords(description),
          scales: parse_scales(description)
        }
      end

      private

      def parse_octave_divisions(octave_paragraph)
        octave_sentence = octave_paragraph.find(OCTAVE_STRUCTURE_SENTENCE)
        construction_type = octave_sentence.match(OCTAVE_STRUCTURE_SENTENCE).captures.first

        if construction_type == 'conceived'
          note_count_match = octave_sentence.match(PERFECT_FOURTH_STRUCTURE)
          if note_count_match
            note_count_word = note_count_match.captures.first
            [:perfect_fourth_division, parse_number_word(note_count_word)]
          else
            raise 'Unrecognised way to conceive a scale.'
          end

        elsif construction_type == 'constructed'
          note_count_match = octave_sentence.match(EVENLY_SPACED_STRUCTURE)
          if note_count_match
            note_count_word = note_count_match.captures.first
            [:evenly_spaced, parse_number_word(note_count_word)]
          else
            parse_exact_notes(octave_paragraph)
          end
        else
          raise "Don't know what it means for a scale to be '#{construction_type}'"
        end
      end

      def parse_exact_notes(octave_paragraph)
        exact_spacing_sentence = octave_paragraph.find(/their spacing is roughly/)
        spacing_match = exact_spacing_sentence.match(
          /In quartertones, their spacing is roughly 1((-|x){23})0/
        )

        raise 'Cannot parse octave text' unless spacing_match

        # TODO: Law of Demeter?
        spacing_symbols = spacing_match.captures.first.each_char
        [
          :specific_quartertones,
          spacing_symbols.map(&method(:parse_note_scaling_symbol))
        ]
      end

      def parse_note_scaling_symbol(char)
        case char
        when 'x'
          true
        when '-'
          false
        else
          raise "Unexpected note position symbol #{pos.inspect}"
        end
      end

      # @param description [Parser::SectionedText]
      #        The description text from which to extract chord data.
      def parse_chords(description)
        {}.tap do |chords|
          chord_paragraphs =
            description.find_all_paragraphs(CHORD_PARAGRAPH_REGEXP)

          chord_paragraphs.each do |paragraph|
            degrees_sentence = paragraph.find(CHORD_PARAGRAPH_REGEXP)

            name, degrees, _division_text = degrees_sentence.match(
              /The ([^ ]+) [a-z]*chord is the (.*) degrees of the (fundamental perfect fourth division|.* scale)/
            ).captures
            
            # We don't actually care whether it's a division of the fourth or the octave at this point, because
            # the (say) 8 degrees of the perfect fourth division are the same as the first half of the
            # two-perfect-fourth scale.
            #division = (division_text == 'fundamental perfect fourth division') ? :fourth : :octave
            chords[name.to_sym] = parse_chord(degrees)
          end
        end
      end

      # @param degrees[String] The list of degrees used by this particular scale
      # @param division[Symbol] What the degrees are degrees of:
      #                         :fourth for the fundamental perfect fourth division, or
      #                         :octave for the usual division of the octave
      def parse_chord(degrees)
        ordinals = degrees.split(/(?:,| and) the/)

        chord_notes = ordinals.map do |ordinal|
          # ordinal is like "4th",
          # or may be like "13th (completing the octave)"
          # in which case it's not in our list of notes,
          # but always has a factor of 2
          # (the tonic, an octave higher)

          # TODO: Can I avoid the special case here?
          if ordinal.include?('(completing the octave)')
            :octave
          else
            # Convert to 0-based indexing for use by code
            ordinal.strip.to_i - 1
          end
        end
      end
      
      SCALE_TOPIC_REGEX = /(As always, )?[Tt]he [^ ]+ [^ ]+ scale is/
      SCALE_TYPE_SENTENCE = /[Tt]he ([^ ]+) [a-z]+tonic scale is (thought of as .*|constructed by)/

      # @param description [Parser::SectionedText]
      def parse_scales(description)
        {}.tap do |scales|
          description
            .find_all_paragraphs(SCALE_TOPIC_REGEX)
            .each do |scale_paragraph|
              # TODO: don't need both regexp lookups here
              scale_sentence = scale_paragraph.find(SCALE_TOPIC_REGEX)
              name, scale_type = scale_sentence.match(SCALE_TYPE_SENTENCE).captures

              case scale_type
              when /thought of as ([a-z]+ )?(disjoint|joined) chords spanning/
                scales[name.to_sym] = [:disjoint, chord_names(scale_paragraph)]
              when /thought of as two disjoint chords drawn from the fundamental division of the perfect fourth/
                scales[name.to_sym] = [:fourth_division, chord_names(scale_paragraph)]
              else
                raise "Unknown scale type #{scale_type} in #{scale_sentence}"
              end
            end
        end
      end

      def chord_names(scale_paragraph)
        # TODO: don't need both regexp lookups here
        chords_sentence = scale_paragraph.find(/These chords are/)
        chord_list = chords_sentence
                     .match(/These chords are named ([^.]+)\.?/)
                     .captures
                     .first
        chord_list.split(/,|and/).map(&:strip).map(&:to_sym)\
      end

      WORDS_TO_NUMBERS = {
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
        'nineteen' => 19
      }.freeze

      # Convert a number word to text -- rough approximation for now.
      # TODO: Rails or something may do this.
      #
      # @param word [String]
      # @return [Fixnum]
      def parse_number_word(word)
        if WORDS_TO_NUMBERS[word]
          WORDS_TO_NUMBERS[word]
        elsif word.start_with?('twenty-')
          WORDS_TO_NUMBERS[word.delete_prefix('twenty-')] + 20
        else
          "Unsupported number name #{word}"
        end
      end
    end
  end
end