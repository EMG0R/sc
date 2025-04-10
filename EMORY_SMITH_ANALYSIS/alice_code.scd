/*
This is the code for my 491 and final project at Berklee. Below you will find the code for a multichannel installation. I have tried to comment  as much as possible to allow for it to be easily installed. The code consists of two synthesized sounds, a looper, a series of input synths for looper, and a 8 channel convolution reverb.
*/


ServerOptions.inDevices
ServerOptions.outDevices

( Server.killAll;
Server.default.options.memSize = 8192 *8;
Server.default.options.numOutputBusChannels = (16);
Server.default.options.numInputBusChannels =(16);
Server.default.options.outDevice_("24Ao");
Server.default.options.inDevice_("Soundcraft Signature 12 MTK");
~sampleRate = s.sampleRate;
s.boot;
)

s.meter
///initialize this part first for reverb
((
//init file paths
~folder=PathName.new("/Users/nathanielcohen/Desktop/-Desktop/SCVerbIR");
~iRs = Array.new;

~folder.entries.do({
	arg path;
	~iRs = ~iRs.add(Buffer.read(s, path.fullPath));})
);

s.waitForBoot{{
	var bufsize, irbuf;
	~fftsize = 4096;
	//select IR
	irbuf =  ~iRs.at(2).postln;
	s.sync;
	//set convolution parameters
	bufsize = PartConv.calcBufSize(~fftsize, irbuf);
    ~irspectrum = Buffer.alloc(s, bufsize, 2);
	~irspectrum.preparePartConv(irbuf, ~fftsize);
	s.sync;
}.fork; }
);


//execte this block of code to add synth defs

(
////////////////////////////////
//input for instruments//
////////////////////////////////
SynthDef.new(\xylo, {
	arg in=0 , out = 20;
	var sig;
	sig = SoundIn.ar([in, in+1]);
	sig = Limiter.ar(sig, 0.2);
	Out.ar(out, sig);
}).add;


SynthDef.new(\bells,{
	arg in=6, out = 22;
	var sig;
	sig = SoundIn.ar(in);
	sig = Limiter.ar(sig, 0.2);
	Out.ar(out,sig);
}).add;


SynthDef.new(\piano,{
	arg in=5 , out= 23;
	var sig;
	sig = SoundIn.ar(in);
	sig = Limiter.ar(sig, 0.2);
	Out.ar(out,sig);
}).add;

SynthDef.new(\kalimba,{
	arg in=7, out= 24;
	var sig;
	sig = SoundIn.ar(in);
	sig = Limiter.ar(sig, 0.2);
	Out.ar(out,sig);
}).add;

SynthDef.new(\cymbal,{
	arg in=4, out= 25;
	var sig;
	sig = SoundIn.ar(in);
	sig = Limiter.ar(sig, 0.2);
	Out.ar(out,sig);
}).add;

SynthDef.new(\vocal,{
	arg in=2, out= 26;
	var sig;
	sig = SoundIn.ar(in);
	sig = Limiter.ar(sig, 0.4);
	Out.ar(out,sig);
}).add;



////////////////////////
////////reverb///////
///////////////////////
SynthDef(\verb,{
	arg in=20, out = 30;
	var sig, bufsize, dry, verb1, verb2, verb3, verb4, verb5, verb6, verb7, verb8;
	//multimono
	verb1 = Limiter.ar(PartConv.ar(In.ar(in), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb2 = Limiter.ar(PartConv.ar(In.ar(in+1), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb3 = Limiter.ar(PartConv.ar(In.ar(in+2), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb4 = Limiter.ar(PartConv.ar(In.ar(in+3), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb5 = Limiter.ar(PartConv.ar(In.ar(in+4), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb6 = Limiter.ar(PartConv.ar(In.ar(in+5), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb7 = Limiter.ar(PartConv.ar(In.ar(in+6), ~fftsize, ~irspectrum.bufnum, 0.2));
	verb8 = Limiter.ar(PartConv.ar(In.ar(in+7), ~fftsize, ~irspectrum.bufnum, 0.2));

	Out.ar(out, verb1);
	Out.ar(out+1, verb2);
	Out.ar(out+2, verb3);
	Out.ar(out+3, verb4);
	Out.ar(out+4, verb5);
	Out.ar(out+5, verb6);
	Out.ar(out+6, verb7);
	Out.ar(out+7, verb8);
}).add;

///////////////////////
///////looper////////
///////////////////////

//allocate buffer for looper
~loopBuf = Buffer.alloc(s, (~sampleRate)*(80), 8);
~loopBuf.zero;
~sampleRate = s.sampleRate;
//synth def
SynthDef.new(\SoS, {
	arg in= 30, out= 0, fb= 0.8;
	var sig, vib, input, rate;
	rate = 1;
	input = In.ar(in, 8);
	input = input * 0.5;
	Out.ar(out, input);
	RecordBuf.ar(input, ~loopBuf, loop:1,recLevel:0.9,  preLevel:0.5);
	sig = LPF.ar(PlayBuf.ar(8, ~loopBuf, rate, loop:1), 15000);
	RecordBuf.ar(sig, ~loopBuf, recLevel:1,  preLevel:1);
	sig = Limiter.ar(sig);
	//stereo check
	// sig = NumChannels.ar(sig, 8);
	Out.ar(out, sig);
}).add;

/////////////////////
//Synthesizers//
/////////////////////
(SynthDef.new(\noiseSwells, {
	arg out=0;
	var lfo, sig;
	lfo = SinOsc.kr(0.1, 1.5pi);
	sig = WhiteNoise.ar();
	sig = LPF.ar(sig, 5000);
	sig = DynKlank.ar(`[([100, 350, 750, 1000]/2)*SinOsc.kr(0.01, [0, 0.5pi, pi, 1.5pi], 0.1, 2),
		[0.01, 0.01, 0.01, 0.01], [1, 1, 1,1]], sig);
	sig = Limiter.ar(sig, 0.5);
	sig = LPF.ar(sig, 10001+(lfo*5000));
	sig = sig * SinOsc.kr(0.1, 1.5*pi, 0.4, 0.6);
	sig = PanAz.ar(8, sig, SinOsc.kr(0.01).range(0, 7), 1, 2, 0 );
	sig = sig * 0.5;
	sig = sig * SinOsc.kr(0.05, 1.5pi).range(0.1, 1);
/*	sig = NumChannels.ar(sig, 8);*/
	Out.ar(out, sig)
}).add);

(SynthDef.new(\drone, {
	arg out=0, freq=82, freqCtrl, pan = 0;
	var sig, panLF, pluck;
	panLF = SinOsc.kr(0.1).range(0,7);
	freqCtrl = freq * LFNoise1.kr(0.5!8).range(-0.3, 0.3).midiratio;
	sig = LFTri.ar(freqCtrl);
	sig = LPF.ar(sig, 5000+SinOsc.kr(0.1, mul:4000));
	pluck = Pluck.ar(sig, Impulse.ar(SinOsc.ar(0.01).range(0.1, 4)), delaytime:((freqCtrl*2).reciprocal));
	sig = Mix([sig, pluck]);
	sig = NumChannels.ar(sig, 8);
	sig = LPF.ar(FreeVerb.ar(sig, mix:0.5, room:8, damp:0.5), 3000);
	sig = sig * 0.1;
	sig = sig * SinOsc.kr(0.04).range(0.1, 1);
/*	sig = NumChannels.ar(sig, 8);*/
	Out.ar(out, sig);
}).add;)


)


//execute this block of code to begin installation

(
//create groups for sends
~sounds = Group.new;
~verb = Group.after(~sounds);
~looper = Group.after(~verb);

//bring synths onto server
Synth(\SoS, target:~looper);
Synth(\verb, target:~verb);
Synth(\xylo, target:~sounds);
Synth(\bells, target:~sounds);
Synth(\piano, target:~sounds);
Synth(\cymbal, target:~sounds);
Synth(\kalimba, target:~sounds);
Synth(\vocal, target:~sounds);
~swells = Synth(\noiseSwells);
~drone = Synth(\drone) ;
)



Synth(\xylo, [\out, 0])

//little useful utilities
~loopBuf.plot
s.meter

~loopBuf.zero

(~recorder = Recorder(s);
~recorder.filePrefix_("Install");
~recorder.record(numChannels:8);)
~recorder.stop