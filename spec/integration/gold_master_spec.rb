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
				let(:score) { '| x X x ! |' }
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

		context 'from given basic polyrhythms' do
			let(:generated_data) do
				generate_with_args('--polyrhythm', '7:11', '--beat')
			end
			let(:fixture_file) { 'spec/fixtures/7-11-polyrhythm.wav' }

			specify 'works' do
				expect(generated_data).to eq known_data
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
			let(:form_description) { File.open(description_file) { |f| f.read } }
			let(:random_seed) { 314159 }
			let(:fixture_file) { 'spec/fixtures/cebela_and_two_three__seed-314159.wav' }

			let(:generated_data) do
				generate_with_args('--seed', random_seed.to_s, '-e', form_description)
	                        end

			specify 'honours both' do
				expect(generated_data).to eq known_data
			end
		end
	end
end
