# frozen_string_literal: true

require 'English'
require 'inevitable_cacophony/parser/sectioned_text'
require 'inevitable_cacophony/parser/word_to_number'

module InevitableCacophony
  module Parser
    # Parses Dwarf Fortress scale descriptions:
    # scale construction, scales, and chords
    class ScaleDescription
      # Regular expressions used in parsing
      OCTAVE_STRUCTURE = /Scales are (constructed|conceived)/
      PERFECT_FOURTH_STRUCTURE =
        /Scales are conceived of as two chords built using a division of the perfect fourth interval into ([a-z ]+) notes/
      EVENLY_SPACED_STRUCTURE =
        /Scales are constructed from ([-a-z ]+) notes spaced evenly throughout the octave/
      EXACT_NOTES_STRUCTURE =
        /Scales are constructed from ([a-z]+) notes dividing the octave/

      CHORD_PARAGRAPH_REGEXP = /The ([^ ]+) [a-z]*chord is/

      # @param scale_text [String]
      def parse(scale_text)
        description = Parser::SectionedText.new(scale_text)
        octave_description = description.find_paragraph(OCTAVE_STRUCTURE)

        {
          octave_divisions: parse_octave_divisions(octave_description),
          chords: parse_chords(description),
          scales: parse_scales(description)
        }
      end

      private

      def parse_octave_divisions(octave_paragraph)
        case octave_paragraph.find(OCTAVE_STRUCTURE)
        when PERFECT_FOURTH_STRUCTURE
          [:perfect_fourth_division, WordToNumber.call($LAST_PAREN_MATCH)]

        when EVENLY_SPACED_STRUCTURE
          [:evenly_spaced, WordToNumber.call($LAST_PAREN_MATCH)]

        when EXACT_NOTES_STRUCTURE
          parse_exact_notes(octave_paragraph)

        else
          raise "Don\'t know how a scale can be '#{octave_sentence}'"
        end
      end

      SPACING_SENTENCE =
        /In quartertones, their spacing is roughly 1((-|x){23})0/

      def parse_exact_notes(octave_paragraph)
        exact_spacing_sentence = octave_paragraph.find(SPACING_SENTENCE)
        spacing_match = exact_spacing_sentence.match(SPACING_SENTENCE)
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
        chord_paragraphs =
          description.find_all_paragraphs(CHORD_PARAGRAPH_REGEXP)

        Hash[
          chord_paragraphs.map(&method(:parse_chord))
        ]
      end

      # @param paragraph[String] The description of this particular chord
      def parse_chord(paragraph)
        degrees_sentence = paragraph.find(CHORD_PARAGRAPH_REGEXP)
        name, degrees, _division_text = degrees_sentence.match(
          /The ([^ ]+) [a-z]*chord is the (.*) degrees of the (fundamental perfect fourth division|.* scale)/
        ).captures

        chord = degrees
                .split(/(?:,| and) the/)
                .map(&method(:parse_chord_ordinal))

        [name.to_sym, chord]
      end

      # Recognise an ordinal like "4th" or "13th, completing the octave".
      # Normal ordinals are just a number, but the one that completes the
      # octave gets special handling as it might not exist in the
      # octave-structure object - we return it as the symbol :octave instead.
      #
      # @param ordinal [String]
      # @return [Integer,Symbol]
      def parse_chord_ordinal(ordinal)
        # TODO: Can I avoid the special case here?
        if ordinal.include?('(completing the octave)')
          :octave
        else
          # Convert to 0-based indexing for use by code
          ordinal.strip.to_i - 1
        end
      end

      SCALE_TOPIC_REGEX = /(As always, )?[Tt]he [^ ]+ [^ ]+ scale is/
      SCALE_TYPE =
        /[Tt]he ([^ ]+) [a-z]+tonic scale is (thought of as .*|constructed by)/

      # @param description [Parser::SectionedText]
      def parse_scales(description)
        {}.tap do |scales|
          description
            .find_all_paragraphs(SCALE_TOPIC_REGEX)
            .each do |scale_paragraph|
              # TODO: don't need both regexp lookups here
              scale_sentence = scale_paragraph.find(SCALE_TOPIC_REGEX)
              name, scale_type = scale_sentence.match(SCALE_TYPE).captures

              scales[name.to_sym] = parse_scale(scale_type, scale_paragraph)
            end
        end
      end

      # @param scale_type[String]
      # @param scale_paragraph[SectionedText]
      def parse_scale(scale_type, scale_paragraph)
        case scale_type
        when /thought of as ([a-z]+ )?(disjoint|joined) chords spanning/
          [:disjoint, chord_names(scale_paragraph)]
        when /thought of as two disjoint chords drawn from the fundamental division of the perfect fourth/
          [:fourth_division, chord_names(scale_paragraph)]
        else
          raise "Unknown scale type #{scale_type} in #{scale_sentence}"
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
    end
  end
end
