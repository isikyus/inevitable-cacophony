require 'spec_helper.rb'
require 'rhythm'

RSpec.describe Rhythm do

	subject { Rhythm.new(score) }

	context 'pitch-accented beats' do
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
			context 'parsing #{score}' do
				let(:score) { score }

				specify 'produces the correct pitches' do
					expect(subject.beats.map(&:amplitude)).to eq beats
				end
			end
		end
	end
end
