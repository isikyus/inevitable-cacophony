require 'spec_helper'
require 'open3'

RSpec.describe 'Inevitable Cacophony' do

	def generate_with_args(*args)
		data, status = Open3.capture2('ruby', '-Ilib', 'cacophony.rb', *args)
		expect(status).to eq 0
		data
	end

	describe 'generating known files' do
		let(:known_data) { File.open(fixture_file).read }

		context 'from given beats' do
			let(:generated_data) do
				generate_with_args('beat', score)
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

		context 'from a given scale' do
			let(:fixture_file) { 'spec/fixtures/bride-of-trumpets-scale.wav' }
			let(:description_file) { 'spec/fixtures/bride-of-trumpets-scale.txt' }
			let(:generated_data) do
				scale_description = File.open(description_file) { |f| f.read }
                                generate_with_args('scale', scale_description)
                        end

			specify 'works' do
				expect(generated_data).to eq known_data
			end
		end
	end
end
