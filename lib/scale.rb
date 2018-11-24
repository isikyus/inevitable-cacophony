# Represents and parses Dwarf Fortress scale descriptions

class Scale

	# Used to break up Dwarf Fortress's text descriptions and find the text we want.
	class Description

		PARAGRAPH_DELIMITER = "\n\n"
		SENTENCE_DELIMITER = /\.\s+/

		# @param description [String] The description to parse
		# @param delimiter [String,Regex] The delimiter between string sections. Defaults to splitting by paragraphs.
		def initialize(description, delimiter=PARAGRAPH_DELIMITER)
			@sections = description.split(delimiter).map(&:strip)
		end

		# Find a section (paragraph, sentence, etc.) of the description
		# matching a given regular expression.
		# @param key [Regex]
		# @return [String]
		def find(key)
			@sections.detect { |s| key.match?(s) } || raise("No match for #{key.inspect} in #{@sections.inspect}")
		end

		# Find a paragraph within the description, and break it up into sentences.
		# @param key [Regex]
		# @return [Description] The paragraph, split into sentences.
		def find_paragraph(key)
			Description.new(find(key), SENTENCE_DELIMITER)
		end

		def to_s
			"<Description: #{@sections.inspect}>"
		end
	end

	# @param scale_text [String] Dwarf Fortress musical form description including scale information.
	def initialize(scale_text)
		description = Description.new(scale_text)
		octave_description = description.find_paragraph(/^Scales are constructed/)
		@octave_divisions = parse_octave_structure(octave_description)
	end

	attr_reader :octave_divisions

	private

	def parse_octave_structure(octave_paragraph)
		octave_sentence = octave_paragraph.find(/^Scales are constructed.*/)
		note_count_word = octave_sentence.match(/Scales are constructed from ([-a-z ]+) notes spaced evenly throughout the octave/).captures.first

		if note_count_word
			divisions = parse_number_word(note_count_word)
			numerator = divisions.to_f

			(0...divisions).map { |index| 2 ** (index/numerator) }
		else
			 raise("Cannot parse octave description:\n#{octave_paragraph}")
		end
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
			words_to_numbers[word.delete('twenty-')] + 20
		else
			"Unsupported number name #{word}"
		end
	end
end
