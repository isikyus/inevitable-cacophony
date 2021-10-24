# frozen_string_literal: true

require 'inevitable_cacophony/parser/errors'

module InevitableCacophony
  module Parser

    # Knows how to extract the name and context of use from a musical form.
    # And maybe stuff like parent culture in future?
    class Metadata
      NAME_REGEXP = /\A(?<name>[A-Za-z ]+) is a ([a-z]+ )?form of music/

      def parse(form)
        match = form.match NAME_REGEXP
        {
          name: match[:name]
        }
      end
    end
  end
end
