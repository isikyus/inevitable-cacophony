require 'optparse'
require 'parser/rhythms'
require 'octave_structure'
require 'midi_generator'
require 'tone_generator'
require 'phrase'

command = -> {
	octave = OctaveStructure.new(input)

        3.times.map do
		chord_notes = []
                rhythm.each_beat.map do |beat|
			chords = octave.chords.values
			if chord_notes.empty?
				chord_notes = chords.sample(random: rng).note_scalings.dup
			end

			note = Note.new(chord_notes.shift, beat)
			Phrase.new(note, tempo: options[:tempo])
		end
        end.flatten
}

render = -> (phrases) {
        tone = ToneGenerator.new(options[:tonic])
        phrases.each { |phrase| tone.add_phrase(phrase) }

        # Have to buffer output so wavefile can seek back to the beginning to write format info
        output_buffer = StringIO.new
        tone.write(output_buffer)
        $stdout.write(output_buffer.string)
}

def input
	@input ||= $stdin.read
end

def options
	@options ||= {
                tempo: 120, # beats per minute
                tonic: 440 # Hz; middle A
	}
end

def rng
	@rng ||= Random.new(options[:seed] || Random.new_seed)
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
					Note.new(1, beat)
				end
			end.flatten

			[Phrase.new(*notes, tempo: options[:tempo])]
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
		        notes = rising_and_falling.map do |factor|
				Note.new(factor, Rhythm::Beat.new(1, 1, 0))
		        end

			[Phrase.new(*notes, tempo: options[:tempo])]
		}
	end

	opts.on('-p', '--polyrhythm RATIO', "Rather than loading rhythm normally, use a polyrhythm in the given ratio (e.g 7:11, 2:3:4). The first number will be 'primary' and determine the tempo.") do |ratio|
		components = ratio.split(':').map do |length|
			Rhythm.new([Rhythm::Beat.new(1, 1, 0)] * length.to_i)
		end

		primary, *secondaries = components
		@rhythm = Polyrhythm.new(primary, secondaries)
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

	opts.on('-S', '--seed SEED', 'Generate random melodies with the given seed, for repeatable results.') do |seed|
		int_seed = seed.to_i
		raise "Expected seed to be a number" unless seed == int_seed.to_s

		options[:seed] = int_seed
	end

        opts.on('-m', '--midi', 'Generate output in MIDI rather than WAV format (TODO: needs tuning file)') do
                render = -> (phrases) {
                        midi = MidiGenerator.new
                        phrases.each do |phrase|
                                midi.add_phrase(phrase)
                        end
                        midi.write($stdout)
                }
        end

        opts.on('-M', '--midi-tuning', 'Instead of music, generate a Scala (Timidity-compatible) tuning file for use with MIDI output from --midi') do
                command = -> {
                        midi = MidiGenerator.new
                        octave_structure = OctaveStructure.new(input)
                        midi.write_frequencies(octave_structure, options[:tonic], $stdout)
                }
        end
end.parse!

render.call(command.call)
