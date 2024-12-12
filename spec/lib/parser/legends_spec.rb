require 'spec_helper.rb'

require 'inevitable_cacophony/parser/legends.rb'

RSpec.describe InevitableCacophony::Parser::Legends do
	let(:parser) { InevitableCacophony::Parser::Legends.new }

	subject (:forms) { parser.parse(legends_xml) }

  describe 'extracts forms and IDs' do
    let(:legends_xml) do
      <<~XML
        <?xml version="1.0" encoding='CP437'?>
        <df_world>
         <musical_forms>
          <musical_form>
            <id>0</id>
            <description>The Father of Idols is a devotional form of music directed toward the worship of Kadol originating in The Portals of Ticking.  The form guides musicians during improvised performances.  A singer recites any composition of The Scratches of Mastery.  The entire performance should be passionate.  The melody has long phrases throughout the form.  Only one pitch is ever played at a time.  It is performed without preference for a scale and in free rhythm.  Throughout, when possible, performers are to glide from note to note and play rapid runs.  [B]The singer always does the main melody and plays staccato.  [B]The Father of Idols has a well-defined multi-passage structure: a verse and a chorus possibly all repeated, a bridge-passage and a finale.  [B]The verse is fast, and it is to be moderately soft.  The singer's voice ranges from the low register to the middle register.  [B]The chorus is half the tempo of the last passage, and it is to be very loud.  The singer's voice ranges from the low register to the middle register.  [B]The bridge-passage is consistently slowing, and it is to be moderately soft.  The singer's voice covers its entire range.  [B]The finale is moderately fast, and it is to be very loud.  The singer's voice stays in the middle register.  </description>
          </musical_form>
          <musical_form>
            <id>1</id>
            <description>The other musical form</description>
          </musical_form>
         </musical_forms>
        </df_world>
      XML
		end

    specify 'extracts basic text' do
      expect(forms.length).to be 2
      expect(forms[1]).to eq 'The other musical form'
    end

    specify 'properly converts newline markers' do
      expect(forms[0]).to eq <<~FATHER_OF_IDOLS.chomp
        The Father of Idols is a devotional form of music directed toward the worship of Kadol originating in The Portals of Ticking.  The form guides musicians during improvised performances.  A singer recites any composition of The Scratches of Mastery.  The entire performance should be passionate.  The melody has long phrases throughout the form.  Only one pitch is ever played at a time.  It is performed without preference for a scale and in free rhythm.  Throughout, when possible, performers are to glide from note to note and play rapid runs.

        The singer always does the main melody and plays staccato.

        The Father of Idols has a well-defined multi-passage structure: a verse and a chorus possibly all repeated, a bridge-passage and a finale.

        The verse is fast, and it is to be moderately soft.  The singer's voice ranges from the low register to the middle register.

        The chorus is half the tempo of the last passage, and it is to be very loud.  The singer's voice ranges from the low register to the middle register.

        The bridge-passage is consistently slowing, and it is to be moderately soft.  The singer's voice covers its entire range.

        The finale is moderately fast, and it is to be very loud.  The singer's voice stays in the middle register.
      FATHER_OF_IDOLS
    end
	end
end
