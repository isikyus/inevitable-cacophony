require 'spec_helper'
require 'open3'

RSpec.describe 'Inevitable Cacophony' do

	def generate_with_args(*args)
		data, status = Open3.capture2('ruby', '-Ilib', 'cacophony.rb', *args)
		expect(status).to eq 0
		data
	end

	context 'generating known files from given beats' do
		let(:known_data) { File.open(fixture_file).read }
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
end
