require 'spec_helper.rb'

require 'inevitable_cacophony/rhythm'

RSpec.describe InevitableCacophony::Rhythm::Beat do

  let(:total_delay) do
    InevitableCacophony::Rhythm::AFTER_DELAY +
      InevitableCacophony::Rhythm::START_DELAY
  end

  context 'without special timing' do
    subject(:beat) { InevitableCacophony::Rhythm::Beat.new(1, 2, 0) }

    specify 'multiplies delays by duration' do
      expect(subject.start_delay).to eq InevitableCacophony::Rhythm::START_DELAY * 2
      expect(subject.after_delay).to eq InevitableCacophony::Rhythm::AFTER_DELAY * 2
    end

    specify 'keeps total duration unchanged' do
      expect(subject.duration).to eq 2
    end

    specify 'calculates length of actual sound' do
      expect(beat.sounding_time).to eq(2 - (2 * total_delay))
    end
  end

  context 'with timing set early' do
    subject(:beat) { InevitableCacophony::Rhythm::Beat.new(1, 2, -1) }

    specify 'combines delays at the end' do
      expect(subject.start_delay).to eq 0
      expect(subject.after_delay)
        .to eq((2 * total_delay))
    end

    specify 'keeps total duration unchanged' do
      expect(subject.duration).to eq 2
    end

    specify 'calculates length of actual sound' do
      expect(beat.sounding_time).to eq(2 - (2 * total_delay))
    end
  end

  context 'with timing set late' do
    subject(:beat) { InevitableCacophony::Rhythm::Beat.new(1, 2, +1) }

    specify 'combines delays at the start' do
      expect(subject.start_delay)
        .to eq((2 * total_delay))
      expect(subject.after_delay).to eq 0
    end

    specify 'keeps total duration unchanged' do
      expect(subject.duration).to eq 2
    end

    specify 'calculates length of actual sound' do
      expect(beat.sounding_time).to eq(2 - (2 * total_delay))
    end
  end
end
