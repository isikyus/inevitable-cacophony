require 'spec_helper'
require 'open3'

RSpec.describe 'Inevitable Cacophony -v' do

  specify 'outputs version when given -v option' do
    output, error, status = Open3.capture3('bundle', 'exec', 'inevitable_cacophony', '-v')

    expect(output).to match /Inevitable Cacophony version \d+\.\d+\.\d+/
    expect(error).to be_empty
    expect(status).to eq 0
  end
end
