# Inevitable Cacophony

[![Build Status](https://travis-ci.com/isikyus/inevitable-cacophony.svg?branch=master)](https://travis-ci.com/isikyus/inevitable-cacophony) 

An attempt to automatically generate music in Dwarf Fortress' generated musical styles.

## Usage

To play a specific rhythm (in the notation used by the game):

	ruby -Ilib cacophony.rb --beat -e '| ! x X x |' | aplay


To generate a tune from a given form description (support is pretty limited so far):

	ruby -Ilib cacophony.rb < form_description.txt | aplay

At this stage you will need to type out the game's form description by hand to use as input.

### Output Format

Inevitable Cacophony generates output as uncompressed WAV files.
The examples above pipe this into `aplay`, but you could also send stdout
to a file and play it with a tool of your choice

## References

https://www.joelstrait.com/digital\_audio\_primer/
