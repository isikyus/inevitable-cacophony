# Inevitable Cacophony

[![Build Status](https://travis-ci.com/isikyus/inevitable-cacophony.svg?branch=master)](https://travis-ci.com/isikyus/inevitable-cacophony) 

An attempt to automatically generate music in Dwarf Fortress' generated musical styles.

## Installation / Dev Setup

To use, or work on, Inevitable Cacophony you will need some Ruby development tools installed,
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

And view Inevitable Cacophony options, with:

	bundle exec ruby -Ilib cacophony.rb --help


See the next section for further instructions.

## Usage

All these commands may need `bundle exec` at the start to get them to work.
They seem to work without it for me, but your Ruby setup might be different.

To play a specific rhythm (in the notation used by the game):

	ruby -Ilib cacophony.rb --beat -e '| ! x X x |' | aplay


You can also play polyrhythms where each component rhythm is simply | x x ... x |.
(More complex rhythms are possible but you'll need to write out a full musical form to describe them.)

	ruby -Ilib cacophony.rb --beat --polyrhythm 7:11 | aplay


To generate a tune from a given form description (support is pretty limited so far):

	ruby -Ilib cacophony.rb < form_description.txt | aplay

At this stage you will need to type out the game's form description by hand to use as input.

### Output Format

Inevitable Cacophony generates output as uncompressed WAV files.
The examples above pipe this into `aplay`, but you could also send stdout
to a file and play it with a tool of your choice

## References

https://www.joelstrait.com/digital\_audio\_primer/
