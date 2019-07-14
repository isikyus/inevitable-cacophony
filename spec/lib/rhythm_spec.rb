require 'spec_helper.rb'
require 'support/eq_array_with_delta'

# TODO: shouldn't need parser to test things like #canonical
require 'parser/rhythm_line'

RSpec.describe Rhythm do

	subject { Parser::RhythmLine.new.parse(score) }
	let(:canonical_durations) { subject.canonical.map(&:duration) }

	INTER_NOTE_DELAY = Rhythm::START_DELAY + Rhythm::AFTER_DELAY
	NOTE_LENGTH = 1 - INTER_NOTE_DELAY

	# Allowable error in note durations.
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
end
