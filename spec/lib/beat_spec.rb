require 'spec_helper.rb'
require 'rhythm'

RSpec.describe Rhythm::Beat do

        context 'without special timing' do
                subject(:beat) { Rhythm::Beat.new(1, 2, 0) }

                specify 'multiplies delays by duration' do
                        expect(subject.start_delay).to eq Rhythm::START_DELAY * 2
                        expect(subject.after_delay).to eq Rhythm::AFTER_DELAY * 2
                end

                specify 'keeps total duration unchanged' do
                        expect(subject.duration).to eq 2
                end
        end

        context 'with timing set early' do
                subject(:beat) { Rhythm::Beat.new(1, 2, -1) }

                specify 'combines delays at the end' do
                        expect(subject.start_delay).to eq 0
                        expect(subject.after_delay)
                                .to eq((Rhythm::AFTER_DELAY + Rhythm::START_DELAY) * 2)
                end

                specify 'keeps total duration unchanged' do
                        expect(subject.duration).to eq 2
                end
        end

        context 'with timing set late' do
                subject(:beat) { Rhythm::Beat.new(1, 2, +1) }

                specify 'combines delays at the start' do
                        expect(subject.start_delay)
                                .to eq((Rhythm::AFTER_DELAY + Rhythm::START_DELAY) * 2)
                        expect(subject.after_delay).to eq 0
                end

                specify 'keeps total duration unchanged' do
                        expect(subject.duration).to eq 2
                end
        end
end
