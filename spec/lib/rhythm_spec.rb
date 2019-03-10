require 'spec_helper.rb'
require 'support/eq_array_with_delta'

require 'rhythm'

RSpec.describe Rhythm do

	subject { Rhythm.from_string(score) }
	let(:canonical_durations) { subject.canonical.beats.map(&:duration) }

	INTER_NOTE_DELAY = ToneGenerator::START_DELAY + ToneGenerator::AFTER_DELAY
	NOTE_LENGTH = 1 - INTER_NOTE_DELAY

	# Allowable delay in note durations.
	# Set by trial and error to get tests to pass
	LENGTH_DELTA = 2 ** -50

	describe 'pitch-accented beats' do
		SCORES_TO_BEATS = {
			'| x |' => [1],
			'| x X |' => [2/3.0, 1],
			'| x X x ! |' => [4/9.0, 2/3.0, 4/9.0, 1],
			'| x - x X |' => [2/3.0, 0, 2/3.0, 1],
			'| x x x |' => [1, 1, 1],
			'| x X | x ! x |' => [4/9.0, 2/3.0, 4/9.0, 1, 4/9.0],
			'| x - - x |' => [1, 0, 0, 1],
		}

		SCORES_TO_BEATS.each do |score, beats|
			context "parsing #{score}" do
				let(:score) { score }

				specify 'produces the correct pitches' do
					expect(subject.beats.map(&:amplitude)).to eq beats
				end

				# TODO: not testing this for scores with 0's because it's trickier
				if !beats.include?(0)
					specify 'preserves pitches when canonicalized' do
						expect(subject.canonical.beats.map(&:amplitude).reject(&:zero?)).to eq beats
					end
				end

				specify 'Inserts spacing between notes appropriately' do
					odd_beats, even_beats = subject.canonical.beats.
						each_with_index.
						group_by { |_beat, index| index.odd? }.
						values_at(true, false).

						# Remove the indexes again.
						map { |values| values.map(&:first) }

					odd_durations = odd_beats.map(&:duration)
					even_durations = even_beats.map(&:duration)

					# Remove first and last off-duty beats as they'll be half-gaps to center the note.
					expect(even_durations.shift).to eq ToneGenerator::START_DELAY
					expect(even_durations.pop).to eq ToneGenerator::AFTER_DELAY

					expect(odd_durations).to eq_array_with_delta(LENGTH_DELTA,
										     [NOTE_LENGTH] * beats.length)
					expect(even_durations).to eq_array_with_delta(LENGTH_DELTA,
									      [INTER_NOTE_DELAY] * (beats.length - 1))
				end
			end
		end
	end

	describe 'beat timing' do
		let(:timings) { subject.beats.map(&:timing) }

		context 'with no special timing marks' do
			let(:score) { '| x - X !' }

			specify 'is normal' do
				expect(timings).to eq([0.0, 0.0, 0.0, 0.0])
			end

			specify 'spaces before and after delays equally' do
				expect(canonical_durations).to eq_array_with_delta(LENGTH_DELTA, [
					ToneGenerator::START_DELAY,
					NOTE_LENGTH, INTER_NOTE_DELAY,
					NOTE_LENGTH, INTER_NOTE_DELAY,
					NOTE_LENGTH, INTER_NOTE_DELAY,
					NOTE_LENGTH, ToneGenerator::AFTER_DELAY
				])
			end
		end

		context 'with marked early beats' do
			let(:score) { '| x`x x |' }

			specify 'makes just those beats early' do
				expect(timings).to eq([0.0, -1.0, 0.0])
			end

			specify 'adjusts spacing around those beats in canonical form' do
				expect(canonical_durations).to eq_array_with_delta(LENGTH_DELTA, [
					ToneGenerator::START_DELAY,
					NOTE_LENGTH, ToneGenerator::AFTER_DELAY,
					NOTE_LENGTH, INTER_NOTE_DELAY + ToneGenerator::START_DELAY,
					NOTE_LENGTH, ToneGenerator::AFTER_DELAY
				])
			end
		end

		context 'with marked late beats' do
			let(:score) { '| x x\'x |' }

			specify 'makes just those beats late' do
				expect(timings).to eq([0.0, 1.0, 0.0])
			end

			specify 'adjusts spacing around those beats in canonical form' do
				expect(canonical_durations).to eq_array_with_delta(LENGTH_DELTA, [
					ToneGenerator::START_DELAY,
					NOTE_LENGTH, INTER_NOTE_DELAY + ToneGenerator::AFTER_DELAY,
					NOTE_LENGTH, ToneGenerator::START_DELAY,
					NOTE_LENGTH, ToneGenerator::AFTER_DELAY
				])
			end
		end
	end

	describe 'polyrhythms' do
		let(:base_rhythms) do
			scores.map { |score| Rhythm.from_string(score) }
		end
		let(:primary) { base_rhythms.first }
		let(:secondaries) { base_rhythms - [primary] }

		subject { Rhythm.poly(primary, secondaries) }

		shared_examples_for 'a 4-3 polyrhythm' do

			specify 'retains the primary rhythm' do
				expect(subject.primary).to eq primary
			end

			specify 'speeds up or slows down the secondary to fit' do
				expect(subject.secondaries.length).to eq 1

				scaled_secondary = subject.secondaries.first
				expect(scaled_secondary.beats.sum(&:timing)).to eq subject.primary.beats.sum(&:timing)
			end

			specify 'defines its own beats that combine the two rhythms' do

				# This test only works for a 4:3 ratio, for now.
				expect(subject.primary.beats.length).to eq 4
				expect(subject.secondaries.first.beats.length).to eq 3

				durations = subject.beats.map(&:duration)
				expect(durations).to eq([1, 1/3.0, 2/3.0, 2/3.0, 1/3.0, 1])
			end

			specify 'builds canonical durations to suit the combined beats' do
				expect(canonical_durations).to eq_array_with_delta(LENGTH_DELTA, [
					ToneGenerator::START_DELAY,
					NOTE_LENGTH, 		ToneGenerator::AFTER_DELAY + ToneGenerator::START_DELAY/3.0,
					NOTE_LENGTH/3.0, 	ToneGenerator::AFTER_DELAY/3.0 + (ToneGenerator::START_DELAY * 2/3.0),
					(NOTE_LENGTH * 02/3.0), (ToneGenerator::AFTER_DELAY * 2/3.0) + (ToneGenerator::START_DELAY * 2/3.0),
					(NOTE_LENGTH * 02/3.0), (ToneGenerator::AFTER_DELAY * 2/3.0) + (ToneGenerator::START_DELAY/3.0),
					NOTE_LENGTH/3.0, 	(ToneGenerator::AFTER_DELAY/3.0) + ToneGenerator::START_DELAY,
					NOTE_LENGTH, 		ToneGenerator::AFTER_DELAY,
				])
			end
		end

		describe '4-3 without accenting' do
			let(:scores) do
				[
					'x x x x',
					'x x x'
				]
			end

			specify 'doubles amplitude when beats stack' do
				stacked, *unstacked = subject.beats.map(&:amplitude)

				expect(unstacked.uniq.length).to eq 1
				expect(stacked).to eq(unstacked.uniq.first * 2)
			end

                        it_should_behave_like 'a 4-3 polyrhythm'
		end

		describe '4-3 with accented beats' do
			let(:scores) do
				[
					'! x X x',
					'x - X'
				]
			end

			specify 'adds and possibly scales amplitudes of the original beats' do
				combined_amplitudes = subject.beats.map(&:amplitude)
				primary_amplitudes = primary.beats.map(&:amplitude)
				secondary_amplitudes = secondaries.first.beats.map(&:amplitude)

				expected_amplitudes  = [
					(primary_amplitudes[0] + secondary_amplitudes[0]),
					primary_amplitudes[1],
					secondary_amplitudes[1],
					primary_amplitudes[2],
					secondary_amplitudes[2],
					primary_amplitudes[3],
				]

				expect(subject.beats.map(&:amplitude)).to eq expected_amplitudes
			end

                        it_should_behave_like 'a 4-3 polyrhythm'
		end
	end
end
