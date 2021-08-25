# frozen_string_literal: true

module InevitableCacophony
  module Parser
    # Converts words in text ("two", "ninety-three", etc.) to Integers
    class WordToNumber
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
      def self.call(word)
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
