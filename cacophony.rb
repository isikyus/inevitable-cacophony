require 'rhythm'
require 'scale'
require 'tone_generator'

tone = ToneGenerator.new

command = ARGV.shift

case command
when 'beat'

	# Default to a basic 4-bar beat.
	beats = Rhythm.new(ARGV.first || '| ! x X x |')

	3.times do
		beats.each_beat do |beat|
			tone.add_note(440, beat, 0.5)
		end
	end

else
	# TODO: usage etc.
	raise "Unrecognised command #{command}"
end

# Have to buffer output so wavefile can seek back to the beginning to write format info
output_buffer = StringIO.new
tone.write(output_buffer)
$stdout.write(output_buffer.string)
