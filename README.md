# grain

the beginning of a grain instrument . . .
right now there are two buffers, one for live recording (1) and one for samples (2)
currently they won't play simultaneously

grain_2.lua: uses scales for pitch dispersion

-  load sample into buffer 2 (via parameters) or record into buffer 1
-  key 2: toggles record
-  key 3: starts play
-  enc 2: increment size
-  enc 3: scale select for pitch dispersion (set in parameters)

grain_3.lua: uses chords for pitch dispersion

-  load sample into buffer 2 (parameters) or record into buffer 1
-  key 1: alt
-  key 2: toggles record
-  key 3: starts play
-  enc 2: increment amount
-  enc 3: chord select for pitch dispersion 
-  enc 3 + alt: pitch dispersion
-  the higher the value of pitchDisp, the wider the span of notes from the chord
