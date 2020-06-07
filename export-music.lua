-- DFHack script to export musical forms as JSON, for use with Inevitable Cacophony
-- Install into `hack/scripts` directory of your Dwarf Fortress/DFHack installation.
--
--[====[

hacks/export-music
=========================
Exports all musical forms as JSON, for use with Inevitable Cacophony

]====]

local function format_bool(boolean)
  if boolean
  then
    return 'false'
  else
    return 'true'
  end
end

-- Print a JSON list.
local function print_list(list)
  print('[')
  for i, value in ipairs(list) do
    print('  '..value..',')
  end
  print('0]')
end

local function print_json_vocals(vocals)
  print('    "scales":[')
  for i, voice in ipairs(vocals) do
    print('      {')
    print('        "vocal_components":')
    print_list(voice.vocal_components)
    print('        "phrase_lengths":')
    print_list(voice.phrase_lengths)
    print('      },')
  end
  print('{}]')
end

print('[')
for i,v in ipairs(df.global.world.musical_forms.all) do
    local name = dfhack.TranslateName(v.name, 1)
    local style = df.musical_form_style

    print('  {')
    print('    "name":"'..name..'",')
    print('    "tempo_style":"'..style[v.tempo_style]..'",')
    print('    "dynamic_style":"'..style[v.dynamic_style]..'",')
    print('    "pitch_style":"'..style[v.pitch_style]..'",')
    print('    "overall_style":"'..style[v.overall_style]..'",')
    print('    "purpose":"'..df.musical_form_purpose[v.purpose]..'",')
    print('    "produces_individual_songs":'..format_bool(v.flags.produces_individual_songs)..',')
    print('    "repeats_as_necessary":'..format_bool(v.flags.repeats_as_necessary)..',')
    print_json_vocals(v.scales)
    print('  },')
end
print('{}]')
