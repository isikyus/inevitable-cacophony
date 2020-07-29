# A rhythm, represented as a sequence of beats of varying length and volume.
# Beats may be "early" or "late", but internally this is represented by
# adjusting the durations of surrounding beats.

module InevitableCacophony
        class Rhythm
        
                # Amount of silence before a note, as a fraction of the note's duration
        	START_DELAY = (0.3).rationalize
        
                # Amount of silence after notes, as a fraction  of duration.
        	AFTER_DELAY = (0.3).rationalize
        
        	# Amplitude -- how loud the beat is, on a scale from silent to MAX VOLUME.
        	# Duration -- how long it is, in arbitrary beat units (think metronome ticks)
        	# Timing -- how early or late the beat is, relative to the same metaphorical metronome.
        	class Beat < Struct.new(:amplitude, :duration, :timing)
        
        		# How much earlier or later than normal this beat's time slice should start,
        		# accounting for the standard start/end delays, timing, and duration.
        		# Negative numbers start earlier, positive ones later.
        		#
        		# @return [Float]
        		def start_offset
        			standard_start_delay = START_DELAY * duration
        			start_delay - standard_start_delay
        		end
        
        		# How much silence there is before this note starts,
        		# after the previous note has finished its time (like padding in CSS).
        		#
        		# @return [Float]
        		def start_delay
        			start_and_after_delays.first * duration
        		end
        
        		# How much silence there is after this note ends,
        		# before the next note's timeslot.
        		#
        		# @return [Float]
        		def after_delay
        			start_and_after_delays.last * duration
        		end
        
                        # How long this note sounds for,
                        # excluding any start/end delays.
                        def sounding_time
                                duration * (1 - start_and_after_delays.sum)
                        end
        
        		private
        
        		# Calculate the before-note and after-note delays together,
        		# to ensure they add up correctly.
        		def start_and_after_delays
        			@start_and_after_delays ||= begin
        
        				# Positive values from 0 to 1.
        				# Higher numbers mean move more of this offset to the other side of the note
        				# (e.g. start earlier for start offset).
        				start_offset = -[timing, 0].min
        				end_offset = [timing, 0].max
        
        				# This is basically matrix multiplication; multiply [START_DELAY, END_DELAY]
        				# by [
        				#	(1 - start_offset)	end_offset
        				#	start_offset		(1 - end_offset)
        				# ]
        				[
        					((1 - start_offset) * START_DELAY) + (end_offset * AFTER_DELAY),
        					(start_offset * START_DELAY) +       ((1 - end_offset) * AFTER_DELAY)
        				]
        			end
        		end
        	end
        
        	def initialize(beats)
        		@beats = beats
        	end
        
        	attr_reader :beats
        
        	def each_beat(&block)
        		@beats.each(&block)
        	end
        
        	# @return [Integer] Total duration of all beats in this rhythm.
        	def duration
        		each_beat.sum(&:duration)
        	end
        
        	# @return [Array<Numeric,NilClass>] An array where a[i] is the amplitude of the beat at time-step i
        	# 				    (rests are 0), or nil if no beat is played then.
        	# 				    This will be as long as necessary to represent the rhythm accurately,
        	# 				    including early and late beats.
        	def canonical
        		if duration != duration.to_i
        			raise "Cannot yet canonicalise rhythms with non-integer length"
        		end
        
        		# Figure out the timing offset we need to allow for,
        		# and space the beats enough to make it work.
        		timing_offset_denominators = self.beats.map do |beat|
        			beat.start_offset.rationalize.denominator
        		end
        		denominator = timing_offset_denominators.inject(1, &:lcm)
        
        		scaled_duration = duration * denominator
        		Array.new(scaled_duration).tap do |spaced_beats|
        			self.beats.each_with_index do |beat, index|
        				offset_index = index + beat.start_offset
        				scaled_index = offset_index * denominator
        				spaced_beats[scaled_index] = beat.amplitude
        			end
        		end
        	end
        
        	def inspect
        		"<#Rhythm duration=#{duration} @beats=#{beats.inspect}>"
        	end
        
        	def == other
        		self.class == other.class &&
        			self.beats == other.beats
        	end
        end
end
