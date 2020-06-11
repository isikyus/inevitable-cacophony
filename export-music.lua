-- DFHack script to export musical forms as JSON, for use with Inevitable Cacophony
-- Install into `hack/scripts` directory of your Dwarf Fortress/DFHack installation.
--
--[====[

hacks/export-music
=========================
Exports all musical forms as JSON, for use with Inevitable Cacophony

]====]

json = require('json')

local function MapList(lookups, list)
    local listData = {}
    for i, entry in ipairs(list) do
        listData[i + 1] = lookups[entry]
    end

    return listData
end

local MELODY_STYLES = { 'rising', 'falling', 'rising-falling', 'falling-rising' }
local MELODY_FREQUENCIES = { 'always', 'often', 'sometimes' }

local function IntervalsData(intervals)
    local intervalsData = {}

    for i, interval in ipairs(intervals) do
        local intervalData = {}

        intervalData['degree'] = interval.degree
        intervalData['rising'] = interval.flags.rising
        intervalData['flattened'] = interval.flags.flattened
        intervalData['sharpened'] = interval.flags.sharpened

        intervalsData[i+1] = intervalData
    end

    return intervalsData
end

local function MapFeatures(features)
     return {
        GlideFromNoteToNote = features.GlideFromNoteToNote,
        UseGraceNotes = features.UseGraceNotes,
        UseMordents = features.UseMordents,
        MakeTrills = features.MakeTrills,
        PlayRapidRuns = features.PlayRapidRuns,
        LocallyImprovise = features.LocallyImprovise,
        SpreadSyllablesOverManyNotes = features.SpreadSyllablesOverManyNotes,
        MatchNotesAndSyllables = features.MatchNotesAndSyllables,

        Syncopate = features.Syncopate,
        AddFills = features.AddFills,
        AlternateTensionAndRepose = features.AlternateTensionAndRepose,
        ModulateFrequently = features.ModulateFrequently,
        PlayArpeggios = features.PlayArpeggios,
        PlayStaccato = features.PlayStaccato,
        PlayLegato = features.PlayLegato,
        FreelyAdjustBeats = features.FreelyAdjustBeats,
    }
end

local function MelodiesData(melodies)
    local melodiesData = {}

    for i, melody in ipairs(melodies) do
        melodyData = {}

        melodyData['style'] = MELODY_STYLES[melody.style]
        melodyData['frequency'] = MELODY_FREQUENCIES[melody.frequency]
        melodyData['intervals'] = IntervalsData(melody.intervals)
        melodyData['features'] = MapFeatures(melody.features)

        melodiesData[i + 1] = melodyData
    end

    return melodiesData
end

local function VocalsData(vocals)
    local vocalsData = {}

    for i, voice in ipairs(vocals) do
        local voiceData = {}

        voiceData['vocal_components'] = MapList(
            { 'melody', 'counterpoint', 'harmony', 'rhythm' },
            voice.vocal_components
        )
        voiceData['phrase_lengths'] = MapList(
            { 'short', 'mid-length', 'long', 'varied-length' },
            voice.phrase_lengths
        )
        voiceData['melodies'] = MelodiesData(voice.anon_21)

        vocalsData[i + 1] = voiceData
    end

    return vocalsData
end

local function InstrumentsData(instruments)
    local style = df.musical_form_style
    local instrumentsData = {}

    for i, instrument in ipairs(instruments) do
        local instrumentData = {}

        instrumentData['instrument'] = instrument_subtype
        instrumentData['substitutions'] = {
            singer = instrument.substitutions.singer,
            speaker = instrument.substitutions.speaker,
            chanter = instrument.substitutions.chanter
        }
        instrumentData['features'] = MapFeatures(instrument.features)
        instrumentData['minimum_required'] = instrument.minimum_required
        instrumentData['maximum_permitted'] = instrument.maximum_permitted
        instrumentData['dynamic_style'] = style[instrument.dynamic_style]
        instrumentData['overall_style'] = style[instrument.overall_style]

        instrumentsData[i + 1] = instrumentData
    end

    return instrumentsData
end

local function MusicalFormsData()
    local style = df.musical_form_style
    local formsData = {}

    for i,v in ipairs(df.global.world.musical_forms.all) do
        local form = {}

        form['name'] = dfhack.TranslateName(v.name, 1)
        form['tempo_style'] = style[v.tempo_style]
        form['dynamic_style'] = style[v.dynamic_style]
        form['pitch_style'] = style[v.pitch_style]
        form['overall_style'] = style[v.overall_style]
        form['purpose'] = df.musical_form_purpose[v.purpose]
        form['produces_individual_songs'] = v.flags.produces_individual_songs
        form['repeats_as_necessary'] = v.flags.repeats_as_necessary
        form['vocals'] = VocalsData(v.scales)
        form['melodies'] = MelodiesData(v.melodies)
        form['instruments'] = InstrumentsData(v.instruments)

        formsData[i + 1] = form
    end

    return formsData
end

local function ScaleData()
        local scalesData = {}

        for i, scale in ipairs(df.global.world.scales.all) do
                local scaleData = {}

                scaleData['id'] = scale.id
                scaleData['flags'] = scale.flags
                scaleData['unk_enum'] = scale.unk_enum

                if scale.unk_enum == 1 then
                        -- "Degrees of the quartertone octave scale",
                        -- used when the scale doesn't have evenly spaced notes.
                        scaleData['quartertone_degrees'] = {}
                        for unkIdx = 1, scale.unk_indices_used do
                                scaleData['quartertone_degrees'][unkIdx] = scale.unk_indices[unkIdx - 1]
                        end
                end

                -- scale_data['sub1'] = MapScaleSub1(scale.scale_sub1)
                scaleData['unk1_unk_1'] = scale.unk1.unk_1
                scaleData['notes'] = {}
                for noteIdx = 1, scale.unk1.length do
                        scaleData['notes'][noteIdx] = {
                                name = scale.unk1.name[noteIdx - 1],
                                abbreviation = scale.unk1.abreviation[noteIdx - 1],
                                number = scale.unk1.number[noteIdx - 1],
                        }
                end

                scalesData[i+1] = scaleData
        end

        return scalesData
end

function ExportForms()
    local savePath = dfhack.getSavePath()
    local filename = savePath .. "/musical-forms.json"
    local file = json.open(filename)

    file.data = {}
    file.data.music = MusicalFormsData()
    file.data.scales = ScaleData()

    file:write()

    print('Exported musical forms to ' .. filename)
end

ExportForms()
