# Represents a "phrase", by which I mean a sequence of notes
# with common performance instructions (tempo, volume, etc.)

module InevitableCacophony
        class Phrase
        
        	# @param notes [Array<Note>] The notes to play (what you'd write on the bar lines, mostly)
        	# @param tempo [Numeric] Tempo in beats per minute.
        	def initialize(*notes, tempo: raise)
        		@tempo = tempo
        		@notes = notes
        	end
        
        	attr_reader :notes, :tempo
        end
end
