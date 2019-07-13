# Knows how to parse the rhythm-description paragraphs
# of a Dwarf Fortress musical form

require 'parser/sectioned_text'
require 'parser/rhythm_line'
require 'polyrhythm'

module Parser

	# TODO: maybe move errors elsewhere
	class Error < StandardError
	end

	class UnknownBaseRhythm < Error
		def initialize(base)
			@base = base

			super("Could not find base rhythm #{base} for polyrhythm")
		end

		attr_accessor :base
	end

	class UnrecognisedFormSyntax < Error
	end

	# For all the Americans out there, following Webster rather than Johnson :-)
	UnrecognizedFormSyntax = UnrecognisedFormSyntax

	class Rhythms

		# Regular expressions used in parsing
		SIMPLE_RHYTHM_SENTENCE = /The (?<name>[[:alpha:]]+) rhythm is a single line with [-a-z ]+ beats?( divided into [-a-z ]+ bars in a [-0-9]+ pattern)?(\.|$)/
		COMPOSITE_RHYTHM_SENTENCE = /The (?<name>[[:alpha:]]+) rhythm is made from [-a-z ]+ patterns: (?<patterns>[^.]+)(\.|$)/

		# "the <rhythm>". Used to match individual components in COMPOSITE_RHYTHM_SENTENCE
		THE_RHYTHM = /the (?<rhythm_name>[[:alpha:]]+)( \((?<reference_comment>[^)]+)\))?/
		IS_PRIMARY_COMMENT = 'considered the primary'

		# Used to recognise how multiple rhythms are to be combined
		COMBINATION_TYPE_SENTENCE = /The patterns are to be played (?<type_summary>[^.,]+), [^.]+\./
		POLYRHYTHM_TYPE_SUMMARY = 'over the same period of time'


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

			composite_rhythms = {}
			parser.find_all_paragraphs(COMPOSITE_RHYTHM_SENTENCE).each do |paragraph|

				# TODO: write something that handles named matches a bit better
				intro_sentence = paragraph.find(COMPOSITE_RHYTHM_SENTENCE).match(COMPOSITE_RHYTHM_SENTENCE)

				# TODO: assumes the first rhythm in the list is always the primary.
				primary = nil
				secondaries = []
				intro_sentence[:patterns].scan(THE_RHYTHM).map do |rhythm_name, comment|
					component = base_rhythms[rhythm_name.to_sym]
					raise(UnknownBaseRhythm.new(rhythm_name)) unless component

					if comment.nil?
						secondaries << component
					elsif comment == IS_PRIMARY_COMMENT

						if primary
							raise Error.new("Setting primary rhythm to #{comment} but was already #{primary}")
						else
							primary = component
						end

					else
						raise UnrecognisedFormSyntax.new("Unrecognised rhythm comment #{comment} in #{intro_sentence}")
					end
				end

				combination_type = paragraph.find(COMBINATION_TYPE_SENTENCE).match(COMBINATION_TYPE_SENTENCE)[:type_summary]

				unless combination_type == POLYRHYTHM_TYPE_SUMMARY
					raise UnrecognisedFormSyntax.new("Unrecognised polyrhythm type #{combination_type}")
				end

				polyrhythm_key = intro_sentence[:name].to_sym
				composite_rhythms[polyrhythm_key] = Polyrhythm.new(primary, secondaries)
			end

			composite_rhythms
		end
	end
end
