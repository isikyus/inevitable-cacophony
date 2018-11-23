require 'spec_helper'
require 'open3'

RSpec.describe 'Inevitable Cacophony' do

	context 'generating known files from given scores' do
		let(:known_data) { File.open(fixture_file).read }
		let(:generated_data) do
			data, status = Open3.capture2('ruby', '-Ilib', 'cacophony.rb', score)
			expect(status).to eq 0
			data
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

		specify 'generates a known file in 4/4 time' do
			known_data = File.open('spec/fixtures/4-4.wav').read
			score = '| x X x ! |'

			# Command here should match README.
			generated_data, status = Open3.capture2("ruby -Ilib cacophony.rb '#{score}'")

			expect(status).to eq 0
			expect(generated_data).to eq known_data
		end
	end
end
