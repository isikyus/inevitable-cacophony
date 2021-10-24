require 'spec_helper.rb'

require 'inevitable_cacophony/parser/metadata.rb'

RSpec.describe InevitableCacophony::Parser::Metadata do
  let(:parser) { described_class.new }

  subject (:data) { parser.parse(form) }

  describe 'extracts name from form description' do
    let(:form) do
      <<~TEXT
      The Father of Idols is a devotional form of music directed toward the worship of Kadol originating in The Portals of Ticking.  The form guides musicians during improvised performances.  A singer recites any composition of The Scratches of Mastery.  The entire performance should be passionate.  The melody has long phrases throughout the form.  Only one pitch is ever played at a time.  It is performed without preference for a scale and in free rhythm.  Throughout, when possible, performers are to glide from note to note and play rapid runs.
      The singer always does the main melody and plays staccato.
      TEXT
    end

    specify 'extracts form name' do
      expect(data[:name]).to eq 'The Father of Idols'
    end
  end
end
