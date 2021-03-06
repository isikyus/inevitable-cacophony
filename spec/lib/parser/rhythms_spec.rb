# frozen_string_literal: true

require 'spec_helper.rb'

require 'inevitable_cacophony/parser/rhythms.rb'

RSpec.describe InevitableCacophony::Parser::Rhythms do
  let(:parser) { InevitableCacophony::Parser::Rhythms.new }

  subject { parser.parse(rhythm_text) }

  describe 'parsing a polyrhythm and its components' do
    let(:rhythm_text) do
      # Source: The Day Can Say
      # Musical form generated by Dwarf Fortress, copyright Bay 12 Games
      <<-RHYTHM
      The sluste rhythm is made from two patterns: the bepa
      (considered the primary) and the nek.
      The patterns are to be played over the same period of time,
      concluding together regardless of beat number.

      The bepa rhythm is a single line with thirty-two beats divided into eight
      bars in a 4-4-4-4-4-4-4-4 pattern.
      The beats are named noloc (spoken no), kes (ke), suku (su) and rorec (ro).
      The beat is stressed as follows:

      | x - - - | x - - - | - - x - | x - x X | x x - - | x - x - | - x - - | x - - x |

      where X marks an accented beat, x is a beat, - is silent
      and | indicates a bar.

      The nek rhythm is a single line with two beats.
      The beat is stressed as follows:

      | - x |

      where x is a beat, - is silent, and | indicates a bar.
      RHYTHM
    end

    let(:bepa) do
      InevitableCacophony::Rhythm.new(
        [
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(1.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0)
        ]
      )
    end

    let(:nek) do
      InevitableCacophony::Rhythm.new(
        [
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(1.0, 1, 0.0)
        ]
      )
    end

    specify 'parses the simple rhythms' do
      expect(subject[:bepa]).to eq(bepa)
      expect(subject[:nek]).to eq(nek)
    end

    specify 'combines them into the correct polyrhythm' do
      expect(subject[:sluste]).to be_a InevitableCacophony::Polyrhythm
      expect(subject[:sluste].primary).to eq bepa
      expect(subject[:sluste].secondaries).to eq [nek]
    end
  end

  describe 'parsing rhythms with non-ASCII names' do
    let(:rhythm_text) do
      # Source: The Velvety Phrases
      # Musical form generated by Dwarf Fortress, copyright Bay 12 Games
      <<-RHYTHM
      The itho rhythm is made from three patterns: the èle
      (considered the primary), the aríle, and the amama. The patterns are to
      be played over the same period of time, concluding together regardless
      of beat number.

      The èle rhythm is a single line with three beats.
      The beats are named timafi (spoken ti), emu (wm), and úpe (úp).
      The beat is stressed as follows:

      | - - x |

      The aríle rhythm is a single line with twenty-four beats divided into
      eight bars in a 3-3-3-3-3-3-3-3 pattern. The beat is stressed as folows:

      | - - x | x X x | - x - | x x'! | x X x | x - - | x - x | X x`x |

      The amama rhythm is a single line with sixteen beats divided into two bars
      in a 8-8 pattern. The beat is stressed as follows:

      | X x x x'- x - x | - - - - x - - - |
      RHYTHM
    end

    let(:ele) do
      InevitableCacophony::Rhythm.new(
        [
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(1.0, 1, 0.0)
        ]
      )
    end

    let(:arile) do
      InevitableCacophony::Rhythm.new(
        [
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(6 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 1.0),
          InevitableCacophony::Rhythm::Beat.new(1.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(6 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(6 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 9.0, 1, -1.0)
        ]
      )
    end

    let(:amama) do
      InevitableCacophony::Rhythm.new(
        [
          InevitableCacophony::Rhythm::Beat.new(1.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 1.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),

          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(4 / 6.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0),
          InevitableCacophony::Rhythm::Beat.new(0.0, 1, 0.0)
        ]
      )
    end

    specify 'uses the correct names for simple rhythms' do
      expect(subject[:èle]).to eq ele
      expect(subject[:aríle]).to eq arile
      expect(subject[:amama]).to eq amama
    end

    specify 'Properly combines them into polyrhythms' do
      expect(subject[:itho].primary).to eq ele
      expect(subject[:itho].secondaries).to eq [arile, amama]
    end
  end
end
