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
        listData[i] = lookups[entry]
    end

    return listData
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

        vocalsData[i] = voiceData
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

        formsData[i] = form
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
