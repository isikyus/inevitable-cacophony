require 'spec_helper'
require 'open3'

RSpec.describe 'Inevitable Cacophony' do

	def generate_with_args(*args)
		data, error, status = Open3.capture3('ruby', '-Ilib', 'cacophony.rb', *args)
		expect(error).to be_empty
		expect(status).to eq 0
		data
	end

	describe 'generating known files' do
		let(:known_data) { File.open(fixture_file).read }

		context 'from given beats' do
			let(:generated_data) do
				generate_with_args('-b', '-e', score)
			end

			context 'in 4/4 time' do
				let(:score) { '| x X x !' }
				let(:fixture_file) { 'spec/fixtures/4-4.wav' }

				specify 'works' do
					expect(generated_data).to eq known_data
				end
			end

			context 'using early and late beats' do
				let(:score) { "| x x'x`x |" }
				let(:fixture_file) { 'spec/fixtures/1-and-3.wav' }

				specify 'works' do
					expect(generated_data).to eq known_data
				end
			end
		end

		context 'from a given octave structure' do
			let(:description_file) { 'spec/fixtures/bride-of-trumpets-scale.txt' }
			let(:form_description) { File.open(description_file) { |f| f.read } }
			let(:generated_data) do
                                generate_with_args('-s', *extra_options, '-e', form_description)
                        end

			context 'in a chromatic scale' do
				let(:extra_options) { %w[ --chromatic ] }
				let(:fixture_file) { 'spec/fixtures/bride-of-trumpets_chromatic-scale.wav' }

				specify 'works' do
					expect(generated_data).to eq known_data
				end

				context 'when reading from stdin' do
					let(:generated_data) do
						generate_with_args('-s', '--chromatic', stdin_data: form_description)
					end

					specify 'works' do
						expect(generated_data).to eq known_data
					end
				end
			end

			context 'in a normal scale for the form' do
				let(:extra_options) { [] }
				let(:fixture_file) { 'spec/fixtures/bride-of-trumpets_ani-scale.wav' }

				specify 'works' do
					expect(generated_data).to eq known_data
				end
			end
		end
	end
end
