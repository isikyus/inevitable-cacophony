# frozen_string_literal: true

module IneveitableCacophony
  module Parser
    # Error parsing a musical form
    class Error < StandardError
    end

    # A polyrhythm or polymeter defnition is referencing another rhythm
    # that doesn't exist.
    class UnknownBaseRhythm < Error
      def initialize(base)
        @base = base
        super("Could not find base rhythm #{base} for polyrhythm")
      end

      attr_accessor :base
    end

    # Unable to parse form description
    class UnrecognisedFormSyntax < Error
    end

    # For all the Americans out there, following Webster rather than Johnson :-)
    # {@see UnrecognisedFormSyntax}
    UnrecognizedFormSyntax = UnrecognisedFormSyntax
  end
end
