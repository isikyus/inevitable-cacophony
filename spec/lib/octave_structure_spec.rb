require 'spec_helper.rb'
require 'octave_structure'

RSpec.describe OctaveStructure do

	subject { OctaveStructure.new(scale_text) }

	describe 'parsing octave structures' do

		context 'with exact spacing' do
			let(:scale_text) do
				# Source: The Day Can Say
				# Musical form generated by Dwarf Fortress, copyright Bay 12 Games
				<<-SCALE
				Scales are constructed from nineteen notes dividing the octave.
				In quartertones, their spacing is roughly 1-xxxxx-xxx-xxxxx-x-xxxx0,
				where 1 is the tonic, 0 marks the octave, and x marks other notes.
				The tonic note is fixed only at the time of performance.
				SCALE
			end

			let(:expected_scalings) do
				[
					1,
					2 ** (2/24.0),
					2 ** (3/24.0),
					2 ** (4/24.0),
					2 ** (5/24.0),
					2 ** (6/24.0),

					2 ** (8/24.0),
					2 ** (9/24.0),
					2 ** (10/24.0),

					2 ** (12/24.0),
					2 ** (13/24.0),
					2 ** (14/24.0),
					2 ** (15/24.0),
					2 ** (16/24.0),

					2 ** (18/24.0),

					2 ** (20/24.0),
					2 ** (21/24.0),
					2 ** (22/24.0),
					2 ** (23/24.0),
				]
			end

			xspecify 'parses them correctly' do
				subject.octave_divisions.each_with_index do |scaling, index|
					expect(scaling).to be_within(0.0001).of(expected_scalings[index])
				end
			end
		end

		context 'with even spacing' do
			let(:scale_text) do
				# Source: The Bride of Trumpets
				# Musical form generated by Dwarf Fortress, copyright Bay 12 Games
				<<-SCALE
				Scales are constructed from twelve notes spaced evenly throughout the octave.
				The tonic note is a fixed note passed from teacher to student.
				Every note is named.
				The names are shato (spoken sha), almef (al), oñod (oñ), umo (um), rostfen (ro), hiñer (hi), ohe (oh), nazweng (na), tod (to), and zomuth (zo).

				The ani pentatonic scale is thought of as two disjoint chords spanning a perfect fifth and a major third. These chords are named ilpi and dik.

				The ilpi trichord is the 1st, the 3rd, and the 8th degrees of the semitone octave scale.

				The dik trichord is the 9th, the 10th, and the 13th (completing the octave) degrees of the semitone octave scale.
				SCALE
			end

			let(:chromatic_scale) { subject.chromatic_scale }

			specify 'starts at the tonic' do
				expect(chromatic_scale.note_scalings.first).to eq 1
			end

			specify 'increases in semitone increments through the scale' do
				chromatic_scale.note_scalings.each_cons(2) do |last, current|
					expect(current/last).to be_within(0.0001).of(2 ** (1/12.0))
				end
			end

			specify 'ends with the octave' do
				expect(chromatic_scale.note_scalings.last).to be_within(0.0001).of(2)
			end

			context 'and generating chords' do
				let(:ilpi_chord) { subject.chords[:ilpi] }
				let(:dik_chord) { subject.chords[:dik] }

                                specify 'uses the correct notes' do
                                        expect(ilpi_chord.note_scalings).to eq([
                                                1,

						# Note 0-based indexing; first note is the tonic (tonic * 2**0)
                                                2 ** (2/12.0),
                                                2 ** (7/12.0)
					])

					expect(dik_chord.note_scalings).to eq([
                                                2 ** (8/12.0),
                                                2 ** (9/12.0),
                                                2
                                        ])
                                end
			end

			context 'and generating a scale' do
				let(:ani_scale) { subject.scales[:ani] }

				specify 'uses the correct notes' do
					expect(ani_scale.note_scalings).to eq([
						1,
						2 ** (2/12.0),
						2 ** (7/12.0),
						2 ** (8/12.0),
						2 ** (9/12.0),
						2
					])
				end

				specify 'excludes the octave when requested' do
					expect(ani_scale.open.note_scalings.last).to eq(2 ** (9/12.0))
				end
			end
		end
	end
end
