require 'wavefile'

require 'rhythm'
require 'tone_generator'

tone = ToneGenerator.new

# Default to a basic 4-bar beat.
beats = Rhythm.new(ARGV.first || '| x x x X |')

3.times do
	beats.each_beat do |beat|
		tone.add_note(440, beat.amplitude, 0.5)
	end
end

# Have to buffer output so wavefile can seek back to the beginning to write format info
output_buffer = StringIO.new
tone.write(output_buffer)
$stdout.write(output_buffer.string)
