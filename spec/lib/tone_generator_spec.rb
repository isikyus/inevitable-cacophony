require 'spec_helper.rb'

require 'tone_generator'

RSpec.describe ToneGenerator do

	subject { ToneGenerator.new }

	describe '#note_buffer' do
		let(:duration) { 1.1 } # Seconds
		let(:buffer) { subject.note_buffer(note) }
		let(:samples) { buffer.samples }

		shared_examples_for 'adding any sound' do
			
			specify 'uses the correct duration' do
				expected_samples = duration * ToneGenerator::SAMPLE_RATE
				expect(samples.length).to be_within(0.1).of(expected_samples)
			end
		end

		context 'adding a rest' do
			let(:note) { Note.rest(duration) }

			specify 'creates a buffer of silence' do
				expect(samples.uniq).to eq([0.0])
			end

			it_should_behave_like 'adding any sound'
		end
	
		context 'adding a note' do
			let(:amplitude) { 0.8 } # Out of 1
			let(:note) { Note.new(frequency, amplitude, duration) }

			shared_examples_for 'frequency' do

				specify 'is correctly converted to cycle time' do
					# Count the number of fully-positive and fully-negative half-waves,
					# and divide by duration to get the frequency.
					# This should be less sensitive to rounding errors than counting peaks or troughs.
					half_waves = samples.slice_when { |was, is| was.positive? != is.positive? }

					# Take the middle 50% of the array to exclude outliers (e.g. silence before
					# and after the note)
					half_wave_times = half_waves.map(&:length)
					quarter = half_wave_times.length / 4
					typical_times = half_wave_times[quarter..-quarter]

					average_time = typical_times.sum / typical_times.length.to_f

					expect(ToneGenerator::SAMPLE_RATE / average_time).to be_within(1).of(frequency * 2)
				end
			end

			context 'with a standard frequency (middle A)' do
				let(:frequency) { 440 } # Middle A

				specify 'maxes out at the correct amplitude' do
					expect(samples.max).to be_within(0.001).of(amplitude)
					expect(samples.min).to be_within(0.001).of(-amplitude)
				end

				it_should_behave_like 'frequency'

				it_should_behave_like 'adding any sound'
			end

			context 'with a different frequency' do
				let(:frequency) { 1111 } # Hertz; some random note

				it_should_behave_like 'frequency'
			end
		end
	end
end
