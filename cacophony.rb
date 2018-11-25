require 'optparse'

require 'rhythm'
require 'octave_structure'
require 'tone_generator'

tone = ToneGenerator.new

command = -> {
	# Spike'd quick-and-dirty attempt at playing chords in rhythm.
	rhythm_score = input.match(/(\|( |\`)((-|x|X|!)( |\`|\'))+)+\|/).to_s
	rhythm = Rhythm.new(rhythm_score)

	octave = OctaveStructure.new(input)

	tonic = 440 # Middle A

	3.times do
		chord_notes = []
		rhythm.each_beat do |beat|
			if chord_notes.empty?
				chord_notes = octave.chords.values.sample.note_scalings.dup
			end

			tone.add_note(tonic * chord_notes.shift, beat, 0.5)
		end
	end		
}

def input
	@input ||= $stdin.read
end

options = {}
OptionParser.new do |opts|

	opts.banner = 'Usage: ruby -Ilib cacophony.rb [options]'

	opts.on('-b', '--beat', 'Play a beat in the given rhythm') do
		command = -> {
			beats = Rhythm.new(input)

			3.times do
				beats.each_beat do |beat|
					tone.add_note(440, beat, 0.5)
				end
			end
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

		        rising_and_falling.each do |factor|
		                tone.add_note(factor * tonic, Rhythm::Beat.new(1, 0), 0.5)
		        end
		}
	end

	opts.on('-e', '--eval FORM', 'Parse FORM rather than reading a form description stdin') do |form|
		@input = form
	end

	opts.on('--chromatic', 'Use "chromatic" scales (all notes in the form) rather than the named scales typical of the form') do
		options[:chromatic] = true
	end

	opts.on('-h', '--help', 'Prints this help') do
		puts opts
		exit
	end
end.parse!

command.call

# Have to buffer output so wavefile can seek back to the beginning to write format info
output_buffer = StringIO.new
tone.write(output_buffer)
$stdout.write(output_buffer.string)
