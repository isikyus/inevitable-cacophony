# Splits text into a sequence of delimited sections,
# and knows how to find the one you want.
#
# Used to parse complex paragraph structures without
# having to handle every single paragraph type,
# and without crashing if an expected type is missing.

module Parser
	class SectionedText

		PARAGRAPH_DELIMITER = "\n\n"
		SENTENCE_DELIMITER = /\.\s+/

		# @param description [String] The description to parse
		# @param delimiter [String,Regex] The delimiter between string sections. Defaults to splitting by paragraphs.
		def initialize(description, delimiter=PARAGRAPH_DELIMITER)
		        @sections = description.split(delimiter).map(&:strip)
		end

		attr_accessor :sections

		# Find a section (paragraph, sentence, etc.) of the description
		# matching a given regular expression.
		# @param key [Regex]
		# @return [String]
		def find(key)
		        find_all(key).first
		end

		# Find all sections matching a given key
		# @param key [Regex]
		# @return [Array<String>]
		def find_all(key)
		        @sections.select { |s| key.match?(s) } || raise("No match for #{key.inspect} in #{@sections.inspect}")
		end

		# Find a paragraph within the description, and break it up into sentences.
		# @param key [Regex]
		# @return [SectionedText] The paragraph, split into sentences.
		def find_paragraph(key)
		        find_all_paragraphs(key).first
		        find_all_paragraphs(key).first
		end

		# As above but finds all matching paragraphs.
		# @param key [Regex]
		# @return [Array<SectionedText>]
		def find_all_paragraphs(key)
		        find_all(key).map do |string|
		                SectionedText.new(string, SENTENCE_DELIMITER)
		        end
		end

		def inspect
		        "<SectionedText: #{@sections.inspect}>"
		end
	end
end
