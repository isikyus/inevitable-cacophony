# Inevitable Cacophony

[![Build Status](https://travis-ci.com/isikyus/inevitable-cacophony.svg?branch=master)](https://travis-ci.com/isikyus/inevitable-cacophony)
[![Maintainability](https://api.codeclimate.com/v1/badges/61518f6cf2152aa336d9/maintainability)](https://codeclimate.com/github/isikyus/inevitable-cacophony/maintainability)

An attempt to automatically generate music in [Dwarf Fortress'][adams] generated musical styles.

## Usage

Installation:

    gem install inevitable_cacophony

Then run Inevitable Cacophony through the executable (there isn't a stable
Ruby API yet).
To play a specific rhythm (in the notation Dwarf Fortress uses):

    inevitable_cacophony --beat -e '| ! x X x |' > rhythm.wav


You can also play polyrhythms where each component rhythm is simply | x x ... x |.
(More complex rhythms are possible but you'll need to write out a full musical form to describe them.)

    inevitable_cacophony --beat --polyrhythm 7:11 > polyrhythm.wav


To generate a tune from a given form description (support is pretty limited so far):

    inevitable_cacophony form_description.txt > form.wav

At this stage you will need to type out the game's form description by hand to use as input.

See `inevitable_cacophony --help` for other options and features.

### Output Format

Inevitable Cacophony generates output as uncompressed WAV on standard output.
You could save this as a file (as shown), or pipe into a tool such as `aplay`
to hear it immediately.

MIDI (`-m` option) and Scala tuning files (`-M`) are of course not generated as WAV.

## Dev Setup

To work on Inevitable Cacophony you will need some Ruby development tools installed,
starting with the Ruby language itself. Normally you'd install Ruby using a version manager,
such as [RVM](https://rvm.io/rvm/basics). (I believe that only works on Unix systems;
I'm not sure what you'd do on Windows, sorry.)

Once you have RVM installed, running `rvm use` will read the `.ruby_version` file,
and enable the correct Ruby in your shell (or tell you how to install it, if needed).

You will then need to install the Ruby gems Cacophony depends on, which is done through
[Bundler](https://bundler.io/#getting-started). Once you have Bundler installed,
running `bundle install` will install all the necessary dependencies.

If everything's worked, you should be able to run the tests, with:

    bundle exec rspec

and run Inevitable Cacophony with:

    bundle exec inevitable_cacophony [options] [filename]

## Acknowledgements and References

Everything in Inevitable Cacophony is motivated by the impressively
thorough musical-form generation of Tarn and Zach Adams'
[Dwarf Fortress][adams].

More personally, I'm indebted to Laurence Walker (Ohokwy) and Toby Walker (Wonkyth) for
letting me pick their brains on music theory.

I've also consulted various pages on music theory and file formats,
including but not limited to:

* ["Digital Audio Primer", Joel Strait][strait], documentation for the
  WaveFile gem
* ["Scala scale file format", Manuel op de Cool][de_cool]

[adams]: http://www.bay12games.com/dwarves/
[strait]: https://www.joelstrait.com/digital_audio_primer/
[de_cool]: http://www.huygens-fokker.org/scala/scl_format.html
