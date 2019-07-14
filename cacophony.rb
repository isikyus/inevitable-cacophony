require 'optparse'

require 'parser/rhythms'
require 'octave_structure'
require 'tone_generator'
require 'phrase'

tone = ToneGenerator.new

command = -> {
	octave = OctaveStructure.new(input)

	tonic = 440 # Middle A

	3.times do
		chord_notes = []
		rhythm.each_beat do |beat|
			if chord_notes.empty?
				chord_notes = octave.chords.values.sample.note_scalings.dup
			end

			note = Note.new(tonic * chord_notes.shift, beat)
			tone.add_phrase(Phrase.new(note, tempo: options[:tempo]))
		end
	end
}

def input
	@input ||= $stdin.read
end

def options
	@options ||= {
		tempo: 120 # beats per minute
	}
end

def rhythm
	@rhythm ||= begin
		all_rhythms = Parser::Rhythms.new.parse(input)

		# Pick the first rhythm mentioned in the file, which should be the one
		# used by the first section of the piece.
		rhythm_name = all_rhythms.keys.sort_by { |name| input.index(name.to_s) }.first

		if all_rhythms[rhythm_name]
			all_rhythms[rhythm_name]
		else

			# If no rhythms are mentioned, parse any rhythm string we can find in the input.
			rhythm_score = input.match(/(\|( |\`)((-|x|X|!)( |\`|\'))+)+\|/).to_s
			Parser::RhythmLine.new.parse(rhythm_score)
		end
	end
end

OptionParser.new do |opts|

	opts.banner = 'Usage: ruby -Ilib cacophony.rb [options]'

	opts.on('-b', '--beat', 'Play a beat in the given rhythm') do
		command = -> {
			notes = 3.times.map do
				rhythm.each_beat.map do |beat|
					Note.new(440, beat)
				end
			end.flatten

			tone.add_phrase(Phrase.new(*notes, tempo: options[:tempo]))
		}
	end

	opts.on('-s', '--scale', 'Play a scale in the given style') do
		command = -> {
			octave = OctaveStructure.new(input)

			scale = if options[:chromatic]
					octave.chromatic_scale
				else
					octave.scales.values.first
				end

			rising_and_falling = scale.open.note_scalings + scale.note_scalings.reverse
		        tonic = 440 # Hz; Middle A

		        notes = rising_and_falling.map do |factor|
				Note.new(factor * tonic, Rhythm::Beat.new(1, 1, 0))
		        end

			tone.add_phrase(Phrase.new(*notes, tempo: options[:tempo]))
		}
	end

	opts.on('-7', '--seven-eleven', 'Play a 7:11 Polyrhythm') do
		command = -> {
			seven = Parser::RhythmLine.new.parse('| x x x x x x x |')
			eleven = Parser::RhythmLine.new.parse('| x x x x x x x x x x x |')
			seven_eleven = Polyrhythm.new(seven, eleven)

                        notes = 3.times.map do
                                seven_eleven.each_beat.map do |beat|
                                        Note.new(440, beat)
                                end
                        end.flatten

                        tone.add_phrase(Phrase.new(*notes, tempo: options[:tempo]))
		}
	end

	opts.on('-e', '--eval FORM', 'Parse FORM rather than reading a form description from stdin') do |form|
		@input = form
	end

	opts.on('--chromatic', 'Use "chromatic" scales (all notes in the form) rather than the named scales typical of the form') do
		options[:chromatic] = true
	end

	opts.on('-h', '--help', 'Prints this help') do
		puts opts
		exit
	end

	opts.on('-t', '--tempo TEMPO', "Play at the given tempo in beats per minute (default #{options[:tempo]})") do |tempo|
		options[:tempo] = tempo.to_i
	end
end.parse!

command.call

# Have to buffer output so wavefile can seek back to the beginning to write format info
output_buffer = StringIO.new
tone.write(output_buffer)
$stdout.write(output_buffer.string)
