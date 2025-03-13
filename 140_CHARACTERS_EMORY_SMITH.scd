// 140 characters

// synth definition named \x.
// f is frequency
// perc envelope
// SinOsc.ar() generates ddat frequency f
// multiply SinOsc by perc env EnvGen.kr()
// Out.ar() sends to channel 0

// Pbind(\instrument,\x,\f,Pwhite(20,700),\dur,Pwhite(0.1,0.9)).play establishes composition
// \instrument,\x uses SynthDef named \x.
// \f,Pwhite(20,700) picks random frequency (20-700) each time the note triggers
// \dur,Pwhite(0.1,0.9) makes the time between notes random from 0.1 seconds up to 0.9 seconds.



---------------------------------------------------------------------------------------------------------------------------------------------

SynthDef(\x,{|f|Out.ar(0,EnvGen.kr(Env.perc(0.1,2))*SinOsc.ar(f)*0.2)}).add;Pbind(\instrument,\x,\f,Pwhite(9,466),\dur,Pwhite(0.1,0.7)).play

---------------------------------------------------------------------------------------------------------------------------------------------
