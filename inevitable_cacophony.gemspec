# frozen_string_literal: true

require_relative 'lib/inevitable_cacophony/version'

Gem::Specification.new do |s|
  s.name          = 'inevitable_cacophony'
  s.version       = InevitableCacophony::VERSION
  s.summary       = 'Generates audio from Dwarf Fortress musical forms'
  s.description   = <<-DESC
    Inevitable Cacophony processes the musical form descriptions
    generated by Dwarf Fortress. It can parse a form to Ruby data
    structures, and in turn use that data to generate (simple)
    MIDI or WAV audio in that style.
  DESC
  s.authors       = ['Isikyus']
  s.files         = Dir['lib/*.rb', 'lib/**/*.rb']
  s.bindir        = 'bin'
  s.executables   << 'inevitable_cacophony'
  s.homepage      = 'https://github.com/isikyus/inevitable-cacophony'
  s.metadata      = {
    'source_code_uri' => 'https://github.com/isikyus/inevitable-cacophony',
    'changelog_uri' => 'https://github.com/isikyus/inevitable-cacophony/tree/master/CHANGELOG.md'
  }
  s.license       = 'MIT'
  s.required_ruby_version = '>= 2.5.3'

  # Gems for parsing
  s.add_runtime_dependency 'nokogiri', ['~> 1.11.7']

  # Gems for musical output
  s.add_runtime_dependency 'midilib', ['~> 2.0.5']
  s.add_runtime_dependency 'wavefile', ['~> 1.0.1']

  s.add_development_dependency 'byebug', ['11.1.3']
  s.add_development_dependency 'rspec', ['3.8.0']
end
