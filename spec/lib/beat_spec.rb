# frozen_string_literal: true

require 'spec_helper.rb'

require 'inevitable_cacophony/rhythm'

RSpec.describe InevitableCacophony::Rhythm::Beat do
  let(:start_delay) { InevitableCacophony::Rhythm::START_DELAY }
  let(:after_delay) { InevitableCacophony::Rhythm::AFTER_DELAY }
  let(:total_delay) { after_delay + start_delay }

  context 'without special timing' do
    subject(:beat) { InevitableCacophony::Rhythm::Beat.new(1, 2, 0) }

    specify 'multiplies delays by duration' do
      expect(subject.start_delay).to eq start_delay * 2
      expect(subject.after_delay).to eq after_delay * 2
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
