require 'spec_helper.rb'
require 'support/eq_array_with_delta'

require 'rhythm'

RSpec.describe Rhythm do

	subject { Rhythm.from_string(score) }
	let(:canonical_durations) { subject.canonical.map(&:duration) }

	INTER_NOTE_DELAY = Rhythm::START_DELAY + Rhythm::AFTER_DELAY
	NOTE_LENGTH = 1 - INTER_NOTE_DELAY

	# Allowable delay in note durations.
	# Set by trial and error to get tests to pass
	LENGTH_DELTA = 2 ** -50

	shared_examples_for 'beats without special timing' do
                describe 'canonical form' do
                        let(:canonical) { subject.canonical }

                        specify 'puts each non-zero beat in the correct spot' do
                                beats.each_with_index do |amplitude, index|
                                        expect(canonical[index]).to eq amplitude
                                end
                        end
                end

		specify 'does not have special timing' do
			expect(subject.beats.map(&:timing).uniq).to eq [0]
		end
	end

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
				let(:beats) { beats }

				specify 'produces the correct pitches' do
					expect(subject.beats.map(&:amplitude)).to eq beats
				end

				# Separate odd and even canonical since the even-indexed ones are spacing between notes.
				let(:canonical) do
					odd_beats, even_beats = subject.canonical.
                                                each_with_index.
                                                group_by { |_beat, index| index.odd? }.
                                                values_at(true, false).

                                                # Remove the indexes again.
                                                map { |values| values.map(&:first) }

					{
						spacing: even_beats,
						notes: odd_beats
					}
				end

				include_examples 'beats without special timing'
			end
		end
	end

	describe 'beat timing' do
		let(:timings) { subject.beats.map(&:timing) }

		context 'with no special timing marks' do
			let(:score) { '| x - X !' }
			let(:beats) { [4/9.0, 0, 2/3.0, 1] }

			include_examples 'beats without special timing'
		end

		context 'with marked early beats' do
			let(:score) { '| x`x x |' }

			specify 'makes just those beats early' do
				expect(timings).to eq([0.0, -1.0, 0.0])
			end

			describe 'canonical form' do
				let(:canonical) { subject.canonical }

				specify 'is stretched enough to place those beats earlier' do

					# TODO: assuming particular start/end offsets
					expect(Rhythm::START_DELAY).to eq 0.3

					expect(canonical.length).to eq 30

					# Should sound on the first/30th, seventh (10 * (1 - 0.3)) and 20th ticks of the 30.
					expect(canonical).to eq ([1.0] + ([nil] * 6) + [1.0] + ([nil] * 12) + [1.0] + ([nil] * 9))
				end
			end
		end

		context 'with marked late beats' do
			let(:score) { '| x x\'x |' }

			specify 'makes just those beats late' do
				expect(timings).to eq([0.0, 1.0, 0.0])
			end

                        describe 'canonical form' do
                                let(:canonical) { subject.canonical }

                                specify 'is stretched enough to place those beats later' do

                                        # TODO: assuming particular start/end offsets
                                        expect(Rhythm::START_DELAY).to eq 0.3

                                        expect(canonical.length).to eq 30

                                        # Should sound on the first/30th, 13th (10 * 1.3) and 20th ticks of the 30.
                                        expect(canonical).to eq ([1.0] + ([nil] * 12) + [1.0] + ([nil] * 6) + [1.0] + ([nil] * 9))
                                end
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

			specify 'retains all components' do
				expect(subject.components).to eq base_rhythms
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

			describe 'canonical form' do
                                let(:canonical) { subject.canonical }

                                specify 'is stretched enough to place each beat correctly' do
                                        expect(canonical.length).to eq 12
				end

				specify 'does indeed place each beat correctly' do
					expect(canonical[0]).not_to be_nil
					expect(canonical[1]).to be_nil
					expect(canonical[2]).to be_nil
					expect(canonical[3]).not_to be_nil

					# This beat is nil in one test because it's a 0 amplitude
					# in the underlying rhythm.
					expect(canonical[4].nil?).to eq expected_amplitudes[2].zero?
					expect(canonical[5]).to be_nil
					expect(canonical[6]).not_to be_nil
					expect(canonical[7]).to be_nil
					expect(canonical[8]).not_to be_nil
					expect(canonical[9]).not_to be_nil
					expect(canonical[10]).to be_nil
					expect(canonical[11]).to be_nil
                                end

				specify 'uses expected amplitudes' do
					# Fetch only beats that existed in the parent rhythms
					parent_beats = canonical.
						values_at(0, 3, 4, 6, 8, 9).
						map { |b| b.nil? ? 0 : b }
					expect(parent_beats).to eq expected_amplitudes
				end
                        end
		end

		describe '4-3 without accenting' do
			let(:scores) do
				[
					'x x x x',
					'x x x'
				]
			end

			let(:expected_amplitudes) { [2, 1, 1, 1, 1, 1].map(&:to_f) }

			specify 'doubles amplitude when beats stack' do
				stacked, *unstacked = subject.beats.map(&:amplitude)

				expect(unstacked.uniq.length).to eq 1
				expect(stacked).to eq(unstacked.uniq.first * 2)

				expect([stacked] + unstacked).to eq expected_amplitudes
			end

                        it_should_behave_like 'a 4-3 polyrhythm'
		end

		describe '4-3 with accented beats' do
			let(:scores) do
				[
					'- x X x',
					'x ! X'
				]
			end
		end

		describe '4-3 with beats extended through silence of the other rhythm' do
			let(:scores) do
				[
					# Back to front just to test selection of primary duration.
					'x - x',
					'x - x -'
				]
			end

			specify 'keeps full length of uninterrupted beats' do
				expected_canonical = [
					2.0, nil, nil,

					# Nil rather than 0 because the 1st beat of the 3-beat rhythm continues
					# this tick. The 2nd of the other rhythm is silent and therefore doesn't
					# interrupt.
					nil,

					# 0 here because the sounding first beat wouldn't sound beyond this point
					# in either rhythm played alone.
					0, nil,
					1.0, nil,

					# Again, 3rd beat not interrupted because 4th beat is silent.
					1.0, nil, nil, nil
				]

				expect(subject.canonical).to eq(expected_canonical)
			end

			specify 'does not cut uninterrupted durations' do
				expect(subject.beats.map(&:duration)).to eq [1, 0.5, 0.5, 1]
			end

			specify 'still sums amplitudes where relevant' do
				expect(subject.beats.map(&:amplitude)).to eq [2.0, 0, 1.0, 1.0]
			end

			specify 'still keeps duration of primary' do
				expect(subject.duration).to eq 3
			end
		end

		describe 'with timing adjustments' do
			let(:scores) do
				[
					%q{| x x'x x'`x x' |},
					%q{| x'`x x'|}
				]
			end

			specify 'calculates canonical form correctly' do
				expected_canonical = Array.new(60)
				expected_canonical[0] = 1.0
				expected_canonical[6] = 1.0
				expected_canonical[13] = 1.0
				expected_canonical[14] = 1.0
				expected_canonical[20] = 1.0
				expected_canonical[33] = 1.0
				expected_canonical[37] = 1.0
				expected_canonical[46] = 1.0
				expected_canonical[53] = 1.0

				expect(subject.canonical).to eq(expected_canonical)
			end

			specify 'calculates durations correctly' do
				expect(subject.duration).to be_within(LENGTH_DELTA).of 6.0

				durations = subject.beats.map(&:duration)
				expect(durations).to eq_array_with_delta(LENGTH_DELTA, [
					0.6, 0.7, 0.1,
					0.6, 1.3, 0.4,
					0.9, 0.7, 0.7
				])
			end

			specify 'does not use timing offsets' do
				expect(subject.beats.map(&:timing).uniq).to eq([0])
			end

			specify 'sums amplitudes only when beats are actually combined' do
				expect(subject.beats.map(&:amplitude)).to eq([
					1, 1,
					1,

					1, 1,
					1,

					1, 1,
					1					
				])
			end
		end
	end
end
