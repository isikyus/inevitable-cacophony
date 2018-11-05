require 'spec_helper'
require 'open3'

RSpec.describe 'Inevitable Cacophony' do

	specify 'generates a known file in 4/4 time' do
		known_data = File.open('spec/fixtures/4-4.wav').read
		score = '| x X x ! |'

		# Command here should match README.
		generated_data, status = Open3.capture2("ruby -Ilib cacophony.rb '#{score}'")

		expect(status).to eq 0
		expect(generated_data).to eq known_data
	end
end
