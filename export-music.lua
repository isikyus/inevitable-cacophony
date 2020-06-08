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

MELODY_STYLES = { 'rising', 'falling', 'rising-falling', 'falling-rising' }
MELODY_FREQUENCIES = { 'always', 'often', 'sometimes' }

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

local function MelodiesData(melodies)
    local melodiesData = {}

    for i, melody in ipairs(melodies) do
        melodyData = {}

        melodyData['style'] = MELODY_STYLES[melody.style]
        melodyData['frequency'] = MELODY_FREQUENCIES[melody.frequency]
        melodyData['intervals'] = IntervalsData(melody.intervals)
        melodyData['features'] = {
            GlideFromNoteToNote = melody.features.GlideFromNoteToNote,
            UseGraceNotes = melody.features.UseGraceNotes,
            UseMordents = melody.features.UseMordents,
            MakeTrills = melody.features.MakeTrills,
            PlayRapidRuns = melody.features.PlayRapidRuns,
            LocallyImprovise = melody.features.LocallyImprovise,
            SpreadSyllablesOverManyNotes = melody.features.SpreadSyllablesOverManyNotes,
            MatchNotesAndSyllables = melody.features.MatchNotesAndSyllables,

            Syncopate = melody.features.Syncopate,
            AddFills = melody.features.AddFills,
            AlternateTensionAndRepose = melody.features.AlternateTensionAndRepose,
            ModulateFrequently = melody.features.ModulateFrequently,
            PlayArpeggios = melody.features.PlayArpeggios,
            PlayStaccato = melody.features.PlayStaccato,
            PlayLegato = melody.features.PlayLegato,
            FreelyAdjustBeats = melody.features.FreelyAdjustBeats,
        }

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

        formsData[i + 1] = form
    end

    return formsData
end

function ExportForms()
    local savePath = dfhack.getSavePath()
    local filename = savePath .. "/musical-forms.json"
    local file = json.open(filename)
    file.data = MusicalFormsData()
    file:write()

    print('Exported musical forms to ' .. filename)
end

ExportForms()
