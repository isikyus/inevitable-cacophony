# Knows how to parse the rhythm-description paragraphs
# of a Dwarf Fortress musical form

require 'parser/sectioned_text'
require 'parser/rhythm_line'

module Parser
	class Rhythms

		# Regular expressions used in parsing
		SIMPLE_RHYTHM_SENTENCE = /The (?<name>[^ ]+) rhythm is a single line with [-a-z ]+ beats?( divided into [-a-z ]+ bars in a [-0-9]+ pattern)?\./

		# Parses the rhythms from the given form text.
		# TODO: is this the whole text or just the bit about rhythms?
		#
		# @param form_text [String]
		# @return [Hash{Symbol,Rhythm}]
		def parse(form_text)
			parser = Parser::SectionedText.new(form_text)

			simple_rhythms = parse_simple_rhythms(parser)
			composite_rhythms = parse_composite_rhythms(parser, simple_rhythms)

			simple_rhythms.merge(composite_rhythms)
		end

		private

		# @param parser [Parser::SectionedText]
		# @return [Hash{Symbol,Rhythm}]
		def parse_simple_rhythms(parser)

			rhythms = {}

			# Find the rhythm description and the following paragraph with the score.
			parser.sections.each_cons(2) do |rhythm, score|
				match = SIMPLE_RHYTHM_SENTENCE.match(rhythm)

				# Make sure we're actually dealing with a rhythm, not some other form element.
				next unless match

				rhythms[match[:name].to_sym] = RhythmLine.parse(score)
			end

			rhythms
		end

		# @param parser [Parser::SectionedText]
		# @param base_rhythms [Hash{Symbol,Rhythm}] Simpler rhythms that can be used by the composite forms we're parsing.
		# @return [Hash{Symbol,Rhythm}]
		def parse_composite_rhythms(parser, base_rhythms)
			{}
		end
	end
end
