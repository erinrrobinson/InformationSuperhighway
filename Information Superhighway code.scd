
Server.default.options.inDevice = "twitter"
Server.default.options.outDevice = "twitter"

// ALLOCATE SOUND FILES TO BUFFERS

(
r = Buffer.alloc(s, 44100 * 10.0, 1);
~stop =4;
~start = 2;
b = Dictionary.new;
PathName("/Users/erinrobinson/Desktop/supercollider/Buffers/").entries.do{
	arg subfolder;
	b.add(
		subfolder.folderName.asSymbol ->
		Array.fill(
			subfolder.entries.size,
			{arg i;
				Buffer.read(s, subfolder.entries[i].fullPath);
			}
		)
	);
};
)

// AMBIENT MUSIC

(
SynthDef.new(\ambient, {
	arg amp=1, out=2, buf, rate=1, freq=500, atk=1, sus=1, rel=1, rq=1, mix=0.33, room=0.5, damp=0.5, pos=1;
	var sig, env;
	sig = PlayBuf.ar(2, buf, rate.midiratio, loop:0, startPos:pos);
	sig = RLPF.ar(sig, freq, rq);
	env = EnvGen.kr(Env.linen(atk, sus, rel), doneAction:2);
	sig = FreeVerb.ar(sig, mix, room, damp);
	sig = sig * env;
	sig = sig * amp;
	Out.ar(out, sig);
}).add;

~amb = Pbind(
	\instrument, \ambient,
	\dur, Pexprand(5.0, 8.0, inf),
	\pos, Pexprand(100, 1000000, inf),
	\buf, Pxrand(b[\startupsounds][(0..3)], inf),
	\rate, Pfunc({|event| if (event[\buf] == b[\startupsounds][3], {[0, 2, 4, 7].choose}, {[0, 2, 7].choose}) }),
	\atk, Pexprand(2.0, 5.0, inf),
	\sus, Pexprand(3.0, 5.0, inf),
	\rel, Pexprand(7.0, 10.0, inf),
	\freq, Pexprand(200, 1000, inf),
	\rq, Pexprand(0.2, 0.6, inf),
	\amp, Pexprand(0.2, 0.5, inf),
	\room, Pexprand(0.3, 0.5, inf),
	\damp, Pexprand(0.25, 0.75, inf),
);


// RECORD, JUMBLE + PLAY TEXT TO SPEECH THROUGH PHONE

SynthDef(\recbuf, { arg out = 0, bufnum = 0, run=1;
	RecordBuf.ar(SoundIn.ar(2), bufnum, run, loop:0, doneAction:2);
}).add;

SynthDef.new(\phones, {
	arg buf, rate, amp=1, mx, rm, dmp, freq, rq, sus=1, pos=1, atk, rel, mix, room, damp;
	var sig, env;
	sig = PlayBuf.ar(1, r, rate, startPos:pos);
	env = EnvGen.kr(Env.linen(0.01, sus, 0.1), doneAction:2);
	sig = RHPF.ar(sig, freq, rq);
	sig = FreeVerb.ar(sig, mx, rm, dmp);
	sig = FreeVerb.ar(sig, mx, rm, dmp);
	sig = sig * env;
	sig = sig * amp;
	amp=0;
	Out.ar(0, sig);
}).add;

OSCdef(\startstop, { arg msg, time;
	if(msg[2] == 0,{
	"start rec".postln;
	a = Synth(\recbuf, [\bufnum, r]);});

	if(msg[2] == 1,{
	"stop rec".postln;
		Synth(\phones);
	a.set(\run,0);
	});
},'/tr', s.addr);

~voice = Pbind(
	\instrument, \phones,
	\dur, Pexprand(0.5, 1.0, inf),
	\buf, r,
	\sus, Pexprand(2.0, 10.0, inf),
	\rate, Pxrand([1, -1, 0.9, -0.9, 0.8, -0.8, 0.7, -0.7, 1.1, -1.1], inf),
	\pos, Pfunc({|event| if (event[\rate] > 0, {Pexprand(1, r.numFrames/4)}, {r.numFrames/5})}),
	\amp, 1,
	\rq, Pexprand(0.1, 0.9, inf),
	\mx, Pexprand(0.1, 0.8, inf),
	\rm, Pexprand(0.2, 0.8, inf),
	\dmp, Pexprand(0.3, 0.8, inf),
);

Ndef(\voices, ~voice).play;

)


// CLOUD SQUEEZE GLITCH
(
Ndef(\startstop, {
	arg thresh = 0;
	var in, chain, freq, hasFreq, sig, amp, trig, amp2, sig2, timetrig, start, stop;

	in = SoundIn.ar(2) * 3;

	chain = FFT(LocalBuf(2048), in);
	chain = PV_MagAbove(chain, 20);
	sig = IFFT(chain);

	amp = Amplitude.kr(sig).lag(1);

	amp = amp.abs;
	stop = amp < 0.0001;
	start = amp > 0.01;

	SendTrig.kr(start, 0, 1);
	SendTrig.kr(stop, 1, 1);
	DelayL.kr(SendTrig.kr(stop, 2, 1), 1.0, 1.0);

});
)

(
~stutter = { |snd, reset, fragmentlength, rate = 0.7, maxdelay = 20|
    var phase, fragment, del;
    phase = Sweep.ar(reset);
    fragment = { |ph| (ph - Delay1.ar(ph)) < 0 + Impulse.ar(0) }.value(phase / fragmentlength % 1);
    del = Latch.ar(phase, fragment) + ((fragmentlength - Sweep.ar(fragment)) * (rate - 1));
    DelayC.ar(snd, maxdelay, del);
};

SynthDef(\stuttermusic, {
	arg out=2;
    var snd, holdperiod, multiplier, shift;
	snd = Ndef(\amb, ~amb);
	holdperiod = PeakFollower.kr(SoundIn.ar(0) * 2, 0.999) * 0.5;
	multiplier = PeakFollower.kr(SoundIn.ar(0), 0.999) * 5;
    snd = ~stutter.(snd, Impulse.ar(holdperiod.reciprocal), holdperiod / multiplier);
    snd * 0.3;
	Out.ar(out, snd);
}).add;

SynthDef(\stutterwords, {
	arg out=2;
    var snd, holdperiod, multiplier;
	snd = SoundIn.ar(2) * 1.5;
	snd = FreeVerb.ar(snd, 0.5, 0.3, 0.3);
	holdperiod = PeakFollower.kr(SoundIn.ar(0) * 2, 0.999) * 0.7;
	multiplier = PeakFollower.kr(SoundIn.ar(0), 0.999) * 7;
    snd = ~stutter.(snd, Impulse.ar(holdperiod.reciprocal), holdperiod / multiplier);
    snd * 2;
	Out.ar(out, snd!2);
}).add;
)



Synth(\stuttermusic);
Synth(\stutterwords);
