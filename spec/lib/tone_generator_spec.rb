# frozen_string_literal: true

require 'spec_helper.rb'

require 'inevitable_cacophony/tone_generator'
require 'inevitable_cacophony/phrase'

RSpec.describe InevitableCacophony::ToneGenerator do
  # Middle A
  let(:tonic) { 440 }

  subject { InevitableCacophony::ToneGenerator.new(tonic) }

  describe '#phrase_buffer' do
    let(:amplitude) { 0.8 } # Out of 1
    let(:timing) { 0.0 }
    let(:note_length) { 1 }
    let(:beat) do
      InevitableCacophony::Rhythm::Beat.new(amplitude, note_length, timing)
    end

    let(:bpm) { 90 }
    let(:expected_duration) { 2.0 / 3 } # seconds
    let(:score) { InevitableCacophony::Phrase.new(note, tempo: bpm) }

    let(:buffer) { subject.phrase_buffer(score) }
    let(:samples) { buffer.samples }

    let(:expected_samples) do
      expected_duration * InevitableCacophony::ToneGenerator::SAMPLE_RATE
    end

    shared_examples_for 'adding any sound' do
      specify 'uses the correct duration' do
        expect(samples.length).to be_within(0.1).of(expected_samples)
      end
    end

    context 'adding a rest' do
      let(:note) { InevitableCacophony::Note.rest(beat) }

      specify 'creates a buffer of silence' do
        expect(samples.uniq).to eq([0.0])
      end

      it_should_behave_like 'adding any sound'
    end

    context 'adding a note' do
      let(:note) { InevitableCacophony::Note.new(ratio, beat) }

      shared_examples_for 'frequency' do
        specify 'is correctly converted to cycle time' do
          # Count the number of fully-positive and fully-negative half-waves,
          # and divide by duration to get the frequency. This should be less
          # sensitive to rounding errors than counting peaks or troughs.
          half_waves = samples.slice_when do |was, is|
            was.positive? != is.positive?
          end

          # Take the middle 50% of the array to exclude outliers
          # (e.g. silence before and after the note)
          half_wave_times = half_waves.map(&:length)
          quarter = half_wave_times.length / 4
          typical_times = half_wave_times[quarter..-quarter]

          average_time = typical_times.sum / typical_times.length.to_f

          expect(InevitableCacophony::ToneGenerator::SAMPLE_RATE / average_time)
            .to be_within(1).of(frequency * 2)
        end
      end

      context 'with a standard frequency (middle A)' do
        let(:ratio) { 1 }
        let(:frequency) { tonic }

        describe 'with a short beat' do
          let(:note_length) { 1 / 2.0 }
          let(:expected_duration) { 1.0 / 3.0 } # Half a beat, at 90 BPM

          it_should_behave_like 'adding any sound'
        end

        describe 'with a different tempo' do
          let(:bpm) { 210 }
          let(:expected_duration) { 1 / 3.5 } # seconds -- i.e. 3.5 notes/second

          it_should_behave_like 'adding any sound'
        end

        specify 'maxes out at the correct amplitude' do
          expect(samples.max).to be_within(0.001).of(amplitude)
          expect(samples.min).to be_within(0.001).of(-amplitude)
        end

        describe 'note timing' do
          let(:leading_silent_samples) do
            samples.slice_before { |s| !s.zero? }.first.length
          end
          let(:trailing_silent_samples) do
            samples.slice_after { |s| !s.zero? }.to_a.last.length
          end
          let(:normal_leading_silence) do
            InevitableCacophony::Rhythm::START_DELAY * expected_samples
          end

          specify 'includes silence before the note' do
            expect(leading_silent_samples)
              .to be_within(10)
              .of(normal_leading_silence)
          end

          specify 'includes silence after the note' do
            expected_trailing_silence =
              InevitableCacophony::Rhythm::AFTER_DELAY * expected_samples

            expect(trailing_silent_samples)
              .to be_within(10)
              .of(expected_trailing_silence)
          end

          context 'with an early beat' do
            let(:timing) { -1.0 }

            specify 'reduces lead-in' do
              expect(leading_silent_samples).to be_within(10).of(0)
            end

            # TODO: should probably rename this to mention duration.
            it_should_behave_like 'adding any sound'
          end

          context 'with a late beat' do
            let(:timing) { 1.0 }

            specify 'increases lead-in' do
              expect(leading_silent_samples)
                .to be_within(10)
                .of(normal_leading_silence * 2)
            end

            it_should_behave_like 'adding any sound'
          end
        end

        it_should_behave_like 'frequency'
        it_should_behave_like 'adding any sound'
      end

      context 'with a different frequency' do
        let(:frequency) { 1111 } # Some random note
        let(:ratio) { frequency / tonic.to_f }

        it_should_behave_like 'frequency'
      end
    end
  end
end
