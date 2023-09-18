(
s.waitForBoot({
	// s.record;
	~scale=(Scale.major.degrees-12)++(Scale.major.degrees)++(Scale.major.degrees+12);
	~velocity=Bus.control(s,1);
	{
		Out.kr(~velocity,SinOsc.kr(1/LFNoise2.kr(1/5).range(5,6)).range(1,70));
	}.play;
	~octave=Bus.control(s,1);
	{
		Out.kr(~octave,
			LinLin.kr(SinOsc.kr(1/7,mul:1.5)+SinOsc.kr(1/1.1,mul:0.5),2.neg,2,2.neg,2).round*12);
	}.play;
	~fx={
		var snd, freq, dur;
		snd = In.ar(0,2);
		freq = LFNoise2.kr(1/3).range(0.5,10);
		dur = LFNoise2.kr(1/3).range(0.5,4);

		snd = SelectX.ar(LFNoise2.kr(1/5).range(0.1,0.55),[snd,
			Fverb.ar(snd[0],snd[1],50,
				tail_density: LFNoise2.kr(1/3).range(50,90),
				decay: LFNoise2.kr(1/3).range(50,90),
			)
		]);

/*		snd = [GrainIn.ar(
			numChannels: 1,
			trigger: Impulse.kr(freq+0.1),
			dur: dur/(freq+0.1),
			in: snd[0],
			maxGrains: 64,
		),GrainIn.ar(
			numChannels: 1,
			trigger: Impulse.kr(freq+0.2),
			dur: dur/(freq+0.2),
			in: snd[1],
			maxGrains: 64,
		)];*/

		snd = snd * EnvGen.ar(Env.adsr(3,1,1,1));
		snd = HPF.ar(snd,100);
		snd = LPF.ar(snd,12000);
		ReplaceOut.ar(0,snd * Lag.kr(\db.kr(0),30).dbamp);
	}.play;

	SynthDef(\bass, { arg freq = 440, amp = 0.5, gate = 1;
		var snd, env, oscfreq, output;
		var lfo;
		oscfreq = {freq * LFNoise2.kr(Rand(0.0001,0.5)).range(0.98, 1.02)}!10;
		lfo = { SinOsc.kr({ 1/Rand(2,52) }!10) };
		env = Env.adsr(0.2, 1, 0.9,0.1).kr(doneAction:2, gate: gate);
		output = LFSaw.ar(oscfreq, mul: lfo.value.range(0,1));
		output = Fold.ar(output,-0.5,0.5);
		output = RLPF.ar(output, (env*freq*0.7) + (freq * lfo.value.range(0.1,2)), lfo.value.range(0.2,1));
		output = Splay.ar(output, lfo.value.range(0,1));
		output = output * env * amp;
		Out.ar(0, output * 24.neg.dbamp);
	}).add;




	i=InstrumentSample.new(Server.default);

	~chords=[
		[4,6,8],
		[5,7,9],
		[3,5,8],
		[1,3,5],
		[1,3,6],
		[1,4,6],
		[1,3,5],
		[0,3,5],
	];
	~bass=[-2,4,1,3,4,5,1,1];
	~chord=~chords.size.rand;
	~instrument="claus_piano";
	~noteMain=48;
	~lastNote=0;
	Routine {
		s.sync;
		// Buffer.read(Server.default,"/home/zns/Documents/internetarchive-downloader/internet_archive_downloads/aporee_6428_7973/1ocean.ogg",action:{
		// 	arg b;
		// 	{
		// 		Out.ar(0,MouseY.kr()*PlayBuf.ar(2,b,BufRateScale.ir(b)));
		// 	}.play;
		// });
		x=Synth.head(Server.default,\bass);
		inf.do{
			x.set(\freq,(~scale.wrapAt(~bass[~chord]+6)+~noteMain-12).midicps);
			3.do({ arg j;
				var ind=~chords[~chord][j]+[0,0,0,0,0,0,0,1,1,1,-1,-1,-1,2,-2].choose+6;
				var note=~scale.wrapAt(ind)+~noteMain;
				["note",note].postln;
				([4,3,3,2,2,2.5,1.5,1,1,1,1,1,0.5,0.25,0,0].choose*2).wait;
				if (7.rand<2,{
					if (~lastNote>0,{
						i.noteOff(1,~lastNote);
					});
					~lastNote=note;
					i.noteOn(1,"/home/zns/Documents/dronecore/samples/string_spurs_swells",~lastNote,5+5.rand);
				},{
					i.noteOn(1,"/home/zns/Documents/dronecore/samples/"++~instrument,
						note.asInteger+(~octave.getSynchronous),
						~velocity.getSynchronous
					);
				});
			});
			// ([6,4,3,2,2,2.5,1.5,1,1,1,1,1,0.5].choose*4).wait;
			if (4.rand<2,{
				~chord=(~chord+1).mod(~chords.size);
				["chord",~chord].postln;
				if (5.rand<2,{
					3.do({ arg j;
						var ind=~chords[~chord][j]+6;
						var note=~scale.wrapAt(ind)+~noteMain;
						i.noteOn(1,"/home/zns/Documents/dronecore/samples/"++~instrument,note.asInteger,10+20.rand);
					});
					i.noteOn(1,"/home/zns/Documents/dronecore/samples/"++~instrument,~scale.wrapAt(~bass[~chord]+6)+~noteMain-12,10+30.rand);
				});

			});
		};
	}.play;
});
)



~fx.set(\db,8)