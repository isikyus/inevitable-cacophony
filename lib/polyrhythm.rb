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

		# Sum the beats at each tick of the component rhythms,
		# but only add 0's (stop current beat and be silent)
		# when _all_ components are silent.
		#
		# We always stop the existing beat if the new one _isn't_ silent,
		# since it would interrupt the existing sound anyway.

		sounding = Set.new
		first, *rest = aligned_components
		first.zip(*rest).map do |beats_at_tick|

			# Any channels with nonzero amplitude start sounding a new beat.
			# Any zeroes stop sounding the existing beat.
			# Other channels (at `nil`) keep their current sound.
			new_beats = Set.new
			finished_beats = Set.new
			beats_at_tick.each_with_index do |amplitude, index|
				if amplitude.nil?
					next
				elsif amplitude > 0
					new_beats.add(index)
				else
					finished_beats.add(index)
				end
			end

			# If we're playing new beats, they interrupt whatever came before.
			# If every beat has now stopped, go silent.
			# Otherwise, keep playing what's still sounding.
			if new_beats.any?
				sounding = new_beats
				beats_at_tick.compact.sum
			else
				sounding.subtract(finished_beats)

				if finished_beats.any? && sounding.empty?
					0
				else
					nil
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

	# Returns the "canonical" forms of the component rhythms, but stretched
	# all to the same length, so corresponding beats in each rhythm have the
	# same index.
	# @return [Array<Array<Float, NilClass>>]
	def aligned_components
		canon_components = components.map(&:canonical)
		common_multiple = canon_components.map(&:length).inject(1, &:lcm)

		# Stretch each component rhythm to the right length, and return them.
		canon_components.map do |component|
			stretch_factor = common_multiple / component.length

			unless stretch_factor == stretch_factor.to_i
				raise "Expected dividing LCM of lengths by one length to be an integer."
			end

			space_between_beats = stretch_factor - 1

			component.map { |beat| [beat] + Array.new(space_between_beats) }.flatten
		end
	end
end
