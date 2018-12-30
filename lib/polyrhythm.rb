# Represents a rhythm that combines two or more simpler rhythms.

class Polyrhythm < Rhythm

        # Creates a new polyrhythm by combining two simpler component rhythms.
	# It will have the same duration as the primary rhythm, but include
	# beats from both it and all the secondaries.
	#
	# TODO: do I want to emphasise the primary rhythm more?
        #
        # @param primary [Rhythm] The rhythm that will be considered the primary.
        # @param secondaries [Array<Rhythm>] The other component rhythms.
	def initialize(primary, secondaries)
		combined_rhythm = [primary, *secondaries].inject do |r1, r2|
			rhythm_product(r1, r2)
		end

		@primary = primary
		@secondaries = secondaries.map { |s| s.stretch(primary.duration) }

		# TODO: not very efficient to create then throw away a Rhythm just for #stretch
		super(combined_rhythm.stretch(primary.duration).beats)
	end

	attr_accessor :primary, :secondaries

	private

	# Calculate a "product" of two rhythms, by stretching each one by intervals
	# of the other rhythms duration, and then 'adding' them to produce a monophonic
	# rhythm which is always playing whichever beat most recently started.
	# If two beats would start simultaneously, they are replaced with a single
	# double-amplitude beat.
	#
	# This should be associative, and have the one-rest rhythm | - | as an identity;
	# not sure if it's commutative. (TODO: test this)
	#
	# @param rhythm1 [Rhythm]
	# @param rhythm2 [Rhythm]
	# @return [Rhythm]
	def rhythm_product(rhythm1, rhythm2)

		if (rhythm1.beats + rhythm2.beats).map(&:duration).any? { |d| d != d.to_f }
			raise 'Can only accurately multiple beats of integer lengths'
		end


		# Figure out the starting count of each beat,
		# by counting both rhythms together using a common multiple.
		common_multiple = rhythm1.duration.lcm(rhythm2.duration)
		beats_by_count = Array.new(common_multiple)

		[rhythm1, rhythm2].each do |rhythm|
			offset = 0
			rhythm.stretch(common_multiple).each_beat do |beat|
				beats_by_count[offset] ||= []
				beats_by_count[offset] << beat

				offset += beat.duration
			end
		end

		# Use the spaces in `beats_by_count` to set beat durations for the new rhythm.
		current_beats = beats_by_count.shift
		raise 'Expected a beat at offset 0' unless current_beats

		duration = 1 # to account for the first timeslot that we just shifted off.
		new_beats = []
		beats_by_count.each do |tick|
			if tick.nil? # No beats on this tick
				duration += 1
			else
				# TODO: add differently-timed beats as separate "grace notes"
				timing = current_beats.map(&:timing).sum / current_beats.length
				amplitude = current_beats.map(&:amplitude).sum

				new_beats << Beat.new(amplitude, duration, timing)

				# Now start collecting time for the next beat.
				duration = 1
				current_beats = tick
			end
		end

		# Add the last beat left at the end.
		timing = current_beats.map(&:timing).sum / current_beats.length
		amplitude = current_beats.map(&:amplitude).sum
		new_beats << Beat.new(amplitude, duration, timing)

		Rhythm.new(new_beats)
	end
end
