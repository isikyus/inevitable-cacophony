# Inevitable Cacophony

[![Build Status](https://travis-ci.com/isikyus/inevitable-cacophony.svg?branch=master)](https://travis-ci.com/isikyus/inevitable-cacophony)
[![Maintainability](https://api.codeclimate.com/v1/badges/61518f6cf2152aa336d9/maintainability)](https://codeclimate.com/github/isikyus/inevitable-cacophony/maintainability)

An attempt to automatically generate music in Dwarf Fortress' generated musical styles.

## Installation / Dev Setup

To work on, Inevitable Cacophony you will need some Ruby development tools installed,
starting with the Ruby language itself. Normally you'd install Ruby using a version manager,
such as [RVM](https://rvm.io/rvm/basics). (I believe that only works on Unix systems;
I'm not sure what you'd do on Windows, sorry.)

Once you have RVM installed, running `rvm use` will read the `.ruby_version` file,
and enable the correct Ruby in your shell (or tell you how to install it, if needed).

You will then need to install the Ruby "gems" Cacophony depends on, which is done through
[Bundler](https://bundler.io/#getting-started). Once you have Bundler installed,
running `bundle install` will install all the necessary dependencies.

If everything's worked, you should be able to run the tests, with:

	bundle exec rspec

and view Inevitable Cacophony options, with:

	bundle exec inevitable_cacophony --help


See the next section for further instructions.

## Usage

Unless you've installed Inevitable Cacophony as a system-wide gem,
these commands may need `rvm <version> do` and/or `bundle exec`
at the start to get them to work.

To play a specific rhythm (in the notation used by the game):

	inevitable_cacophony --beat -e '| ! x X x |' | aplay


You can also play polyrhythms where each component rhythm is simply | x x ... x |.
(More complex rhythms are possible but you'll need to write out a full musical form to describe them.)

	inevitable_cacophony --beat --polyrhythm 7:11 | aplay


To generate a tune from a given form description (support is pretty limited so far):

	inevitable_cacophony < form_description.txt | aplay

At this stage you will need to type out the game's form description by hand to use as input.

### Output Format

Inevitable Cacophony generates output as uncompressed WAV files.
The examples above pipe this into `aplay`, but you could also send stdout
to a file and play it with a tool of your choice.

MIDI (`-m` option) and Scala tuning files (`-M`) are of course not generated as WAV.

## References

https://www.joelstrait.com/digital\_audio\_primer/
