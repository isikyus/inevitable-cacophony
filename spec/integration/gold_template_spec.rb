# frozen_string_literal: true

require 'spec_helper'
require 'open3'
require 'wavefile'

MATCHER_SAMPLES_PER_BUFFER = 512
MATCHER_WAVEFILE_FORMAT_FIELDS = [:channels, :sample_format, :bits_per_sample, :sample_rate, :speaker_mapping]
RSpec::Matchers.define :equal_audio do |expected|

  match do |actual|
    actual_stream = WaveFile::Reader.new(StringIO.new(actual))
    expected_stream = WaveFile::Reader.new(StringIO.new(expected))
    begin

      # Read both streams to find the first mismatching buffer,
      # and report that; this avoids stupidly long matchers.
      expected_buffer = nil
      actual_buffer = nil
      while actual_stream.current_sample_frame < actual_stream.total_sample_frames &&
          expected_stream.current_sample_frame < expected_stream.total_sample_frames
        expected_buffer = expected_stream.read(MATCHER_SAMPLES_PER_BUFFER)
        actual_buffer = actual_stream.read(MATCHER_SAMPLES_PER_BUFFER)

        @expected = inspect_buffer_in_context(expected_stream, expected_buffer)
        @actual = inspect_buffer_in_context(actual_stream, actual_buffer)

        return false unless same_wave_data?(expected_buffer, actual_buffer)
      end
    ensure
      actual_stream.close
      expected_stream.close
    end

    true
  end

  diffable
  attr_reader :expected, :actual

  private

  def inspect_buffer_in_context(stream, buffer)
    index = stream.current_sample_frame
    length = stream.total_sample_frames
    window_end = [index + MATCHER_SAMPLES_PER_BUFFER, length].min
    [
      "Buffer at samples #{index}-#{window_end} of #{length}:",
      inspect_buffer(buffer)
    ].join("\n")
  end

  def inspect_buffer(buffer)
    [
      "<WaveFile::Buffer:#{buffer.__id__}",
      "  @format=#{buffer.instance_eval { @format }.inspect}",
      "  @samples=[",
      "    #{buffer.samples.join("\n    ")}",
      "  ]",
      ">"
    ].join("\n")
  end

  def same_wave_data?(expected, actual)
    # Hack, but there doesn't seem to be any way to extract this cleanly from the buffer.
    expected_format = expected.instance_eval { @format }
    actual_format = actual.instance_eval { @format }

    same_format?(expected_format, actual_format) &&
      expected.samples == actual.samples
  end

  def same_format?(expected, actual)
    MATCHER_WAVEFILE_FORMAT_FIELDS.each do |field|
      expected.send(field) == actual.send(field)
    end
  end
end

RSpec.describe 'Inevitable Cacophony' do
  def generate_with_args(*args)
    data, error, status = Open3.capture3('bundle',
                                         'exec',
                                         'inevitable_cacophony',
                                         *args)
    expect(error).to be_empty
    expect(status).to eq 0

    data
  end

  describe 'generating known files' do
    let(:known_data) { File.open(fixture_file, &:read) }

    context 'from given beats' do
      let(:generated_data) do
        generate_with_args('-b', '-e', score)
      end

      context 'in 4/4 time' do
        let(:score) { '| x X x ! |' }
        let(:fixture_file) { 'spec/fixtures/4-4.wav' }

        specify 'works' do
          expect(generated_data).to equal_audio known_data
        end
      end

      context 'using early and late beats' do
        let(:score) { "| x x'x`x |" }
        let(:fixture_file) { 'spec/fixtures/1-and-3.wav' }

        specify 'works' do
          expect(generated_data).to equal_audio known_data
        end
      end
    end

    context 'from given basic polyrhythms' do
      let(:generated_data) do
        generate_with_args('--polyrhythm', '7:11', '--beat')
      end
      let(:fixture_file) { 'spec/fixtures/7-11-polyrhythm.wav' }

      specify 'works' do
        expect(generated_data).to equal_audio known_data
      end
    end

    context 'from a given octave structure' do
      let(:description_file) { 'spec/fixtures/bride-of-trumpets-scale.txt' }
      let(:form_description) { File.open(description_file, &:read) }
      let(:generated_data) do
        generate_with_args('-s', *extra_options, '-e', form_description)
      end

      context 'in a chromatic scale' do
        let(:extra_options) { %w[ --chromatic ] }
        let(:fixture_file) do
          'spec/fixtures/bride-of-trumpets_chromatic-scale.wav'
        end

        specify 'works' do
          expect(generated_data).to equal_audio known_data
        end

        context 'when reading from stdin' do
          let(:generated_data) do
            generate_with_args('-s',
                               '--chromatic',
                               stdin_data: form_description)
          end

          specify 'works' do
            expect(generated_data).to equal_audio known_data
          end
        end
      end

      context 'in a normal scale for the form' do
        let(:extra_options) { [] }
        let(:fixture_file) { 'spec/fixtures/bride-of-trumpets_ani-scale.wav' }

        specify 'works' do
          expect(generated_data).to equal_audio known_data
        end
      end

      context 'generating MIDI' do
        let(:description_file) { 'spec/fixtures/eleven_note_scale.txt' }
        let(:generated_data) do
          generate_with_args('-s', *extra_args, '-e', form_description)
        end

        context 'MIDI file itself' do
          let(:fixture_file) { 'spec/fixtures/eleven_note_scale.midi' }
          let(:extra_args) { ['-m'] }

          specify 'generates' do
            expect(generated_data).to eq known_data
          end
        end

        context 'Scala tuning file' do
          let(:extra_args) { ['-M'] }
          let(:fixture_file) { 'spec/fixtures/eleven_note_scale.tuning' }

          specify 'generates a separate Scala tuning file' do
            expect(generated_data).to eq known_data
          end
        end
      end
    end

    context 'with a specified rhythm' do
      let(:description_file) { 'spec/fixtures/cebela_and_two_three.txt' }
      let(:form_description) { File.open(description_file, &:read) }
      let(:random_seed) { 3_14159 }
      let(:fixture_file) do
        'spec/fixtures/cebela_and_two_three__seed-314159.wav'
      end

      let(:generated_data) do
        generate_with_args('--seed', random_seed.to_s, '-e', form_description)
      end

      specify 'honours both' do
        expect(generated_data).to equal_audio known_data
      end
    end
  end
end
