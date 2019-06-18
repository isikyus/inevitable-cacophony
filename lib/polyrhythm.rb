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
		@primary = primary
		@secondaries = secondaries

		# TODO: not very efficient to create then throw away a Rhythm just for #stretch
		unscaled_canon = Rhythm.new(beats_from_canonical(canonical))
		super(unscaled_canon.stretch(primary.duration).beats)
	end

	attr_accessor :primary, :secondaries

	# @return [Array<Rhythm>] All the component rhythms that make up this polyrhythm
	def components
		[primary, *secondaries]
	end

	# Calculates the canonical form by combining the two component rhythms.
	# @return [Array<Float>]
	def canonical

		# The new rhythm will need enough ticks to accurately represent both the old ones.
		canon_components = components.map(&:canonical)
		common_multiple = canon_components.map(&:length).inject(1, &:lcm)

		# Stretch each component rhythm to the right length, and sum them.
		Array.new(common_multiple).tap do |canonical|
			note_lengths = canonical.dup

			canon_components.each do |component|
				stretch_factor = common_multiple / component.length

				unless stretch_factor * component.length == common_multiple
					raise "Expected dividing LCM of lengths by one length to be an integer."
				end

				component.each_with_index do |amplitude, index|
					unless amplitude.nil?
						stretched_index = index * stretch_factor

						canonical[stretched_index] ||= 0
						canonical[stretched_index] += amplitude

						# Only count nonzero beats for note length
						if amplitude > 0
							note_lengths[stretched_index] ||= 0
							note_lengths[stretched_index] = [note_lengths[stretched_index], stretch_factor].max
						end
					end
				end
			end

			# Remove any 0-valued notes that are interrupting other rhythms
			duration_left = 0
			note_lengths.each_with_index do |length, index|

				# Track which note we're in
				if length
					duration_left = length
				else
					duration_left -= 1

					# If we aren't in a sounded note (as length is set only then),
					# are we in an unsounded one we should skip?
					if duration_left > 0 && canonical[index] && canonical[index].zero?
						canonical[index] = nil
					end
				end
			end
		end
	end

	private

	# Calculate a set of beats with timings from the given canonical rhythm.
	# TODO: properly account for pre-existing durations.
	#
	# @param canonical [Array<Float,NilClass>]
	# @return [Array<Beat>]
	def beats_from_canonical(canonical)
		[].tap do |beats|
			amplitude = canonical.shift || 0

			duration = 1 # to account for the first timeslot that we just shifted off.
			canonical.each do |this_beat|
				if this_beat.nil?
					duration += 1
				else
					beats << Beat.new(amplitude, duration, 0)

					# Now start collecting time for the next beat.
					duration = 1
					amplitude = this_beat
				end
			end

			beats << Beat.new(amplitude, duration, 0)
		end
	end
end
