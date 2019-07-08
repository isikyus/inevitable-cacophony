# Represents a rhythm that combines two or more simpler rhythms.

require 'set'

require 'rhythm'

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

		unscaled_beats = beats_from_canonical(canonical)
		scaled_beats = scale_beats(unscaled_beats, @primary.duration)
		super(scaled_beats)
	end

	attr_accessor :primary, :secondaries

	# @return [Array<Rhythm>] All the component rhythms that make up this polyrhythm
	def components
		[primary, *secondaries]
	end

	# Calculates the canonical form by combining the two component rhythms.
	# @return [Array<Float>]
	def canonical

		sounding = Set.new
		first, *rest = aligned_components
		first.zip(*rest).map do |beats_at_tick|
			beat, sounding = update_sounding_beats(sounding, beats_at_tick)
			beat
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

	# Given several channels and the set of beats currently playing,
	# calculate the beat that should now start/stop/continue playing.
	#
	# @param sounding [Set{Integer}] The channels with a beat currently playing.
	# @param current_channel_state [Array<Float>] The beat each channel has at this tick.
	# 						(+nil+) means continuing an earlier beat.
	# @return [Array<[Float, NilClass],Set{Integer}] A two-element array like +[beat, sounding]+,
	# 		where +beat+ is the amplitude to play now (+nil+ to hold last note; 0 to stop),
	# 		and +sounding+ is the Set of channels still playing.
	def update_sounding_beats(sounding, current_channel_states)

		beat = nil

		# If we're starting new beats, they interrupt whatever came before.
		new_beats = indices_of(current_channel_states) { |b| b && b > 0 }
		if new_beats.any?
			sounding = new_beats.to_set
			beat = current_channel_states.compact.sum
		else

			# If every beat has now stopped, go silent.
			# Otherwise, keep playing what's still sounding.
			finished_beats = indices_of(current_channel_states, 0)
			sounding.subtract(finished_beats)

			if finished_beats.any? && sounding.empty?
				beat = 0
			end
		end

		[beat, sounding]
	end

	# TODO: should really be in some other class.
	# Returns all indices of an array where the given value can be found,
	# or all that match the given block
	#
	# @param array An object responding to #each_index and #[<index>]
	# @param condition The object we're looking for in the array
	# @return Array<Integer> indices into `array` matching the conditions.
	#
	# Source: steenslag at Stack Overflow (https://stackoverflow.com/a/13660352/10955118); CC-BY-SA
	def indices_of(array, condition=nil, &block)
		block ||= condition.method(:==)

		array.each_index.select do |index|
			block.call(array[index])
		end
	end

	# Scales each beat in the given list so the list has the given total duration.
	#
	# @param beats [Array<Beat>]
	# @param duration [Float]
	def scale_beats(beats, total_duration)
		scale_factor = total_duration.to_f / beats.map(&:duration).sum

		beats.map do |beat|
			Beat.new(beat.amplitude, beat.duration * scale_factor, beat.timing)
		end
	end
end
