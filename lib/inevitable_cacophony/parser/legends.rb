# Reads musical forms from DF's legends.xml format and converts
# to the format the rest of InevitableCacophony expects.

require 'nokogiri'

module InevitableCacophony
  module Parser
    class Legends

      # @param xml [String] Legends file XML
      def parse(xml)
        legends = Nokogiri::XML(xml)
        
        forms = []
        legends.css('df_world musical_forms musical_form').each do |form|
          id, form_text = parse_form(form)
          forms[id] = form_text
        end

        forms
      end

      private

      # @param form [Nokogiri::Node]
      def parse_form(form)
        # Form IDs are sequential integers,
        # probaby due to how DF generates forms externally.
        id = form.at_css('id').content.to_i
        content = form.at_css('description').content

        [id, unescape_newlines(content)]
      end

      # Convert the [B] escapes in DF's output into double
      # newlines as Cacophony expects, and clean up various
      # other extraneious whitespace.
      def unescape_newlines(text)
        text
          .split('[B]')
          .map { |s| s.chomp('  ') }
          .join("\n\n")
      end
    end
  end
end  
