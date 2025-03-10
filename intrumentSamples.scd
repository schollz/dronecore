(
s.waitForBoot({
	// s.record;
	~scale=(Scale.major.degrees-12)++(Scale.major.degrees)++(Scale.major.degrees+12);
	~velocity=Bus.control(s,1);
	{
		Out.kr(~velocity,SinOsc.kr(1/LFNoise2.kr(1/5).range(5,6)).range(30,70));
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

		snd = AnalogTape.ar(snd*2,0.9,0.9,0.8);
		snd = SelectX.ar(LFNoise2.kr(1/5).range(0,0.5),[snd,AnalogDegrade.ar(snd)]);
		snd = SelectX.ar(LFNoise2.kr(1/5).range(0.1,0.2),[snd,
			Fverb.ar(snd[0],snd[1],50,
				tail_density: LFNoise2.kr(1/3).range(50,90),
				decay: LFNoise2.kr(1/3).range(50,90),
			)
		]);

		snd = [GrainIn.ar(
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
		)];

		snd = snd * EnvGen.ar(Env.adsr(3,1,1,1));
		snd = HPF.ar(snd,100);
		snd = LPF.ar(snd,12000);
		ReplaceOut.ar(0,snd * Lag.kr(\db.kr(0),6).dbamp);
	}.play;

	SynthDef(\bass, { arg freq = 440, amp = 0.5, gate = 1;
		var snd, env, oscfreq, output;
		var lfo;
		oscfreq = {freq * LFNoise2.kr(Rand(0.0001,0.5)).range(0.99, 1.01)}!10;
		lfo = { SinOsc.kr({ 1/Rand(2,52) }!10) };
		env = Env.adsr(0.2, 1, 0.9,0.1).kr(doneAction:2, gate: gate);
		output = LFSaw.ar(oscfreq, mul: lfo.value.range(0,1));
		output = Fold.ar(output,-0.5,0.5);
		output = RLPF.ar(output, (env*freq*0.7) + (freq * lfo.value.range(0.1,2)), lfo.value.range(0.2,1));
		output = Splay.ar(output, lfo.value.range(0,1));
		output = output * env * amp;
		Out.ar(0, output * 20.neg.dbamp);
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
	~noteMain=60;
	~lastNote=0;
	~playPiano=0;
	~playStrings=1;
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
			x.set(\freq,(~scale.wrapAt(~bass[~chord]+6)+~noteMain-24).midicps);
			3.do({ arg j;
				var ind=~chords[~chord][j]+[0,0,0,0,0,0,0,1,1,1,-1,-1,-1,2,-2].choose+6;
				var note=~scale.wrapAt(ind)+~noteMain;
				// ["note",note].postln;
				([4,3,3,2,2,2.5,1.5,1,1,1,1,1,0.5,0.25,0,0].choose).wait;
				if (12.rand<5,{
					if (~lastNote>0,{
						i.noteOff(1,~lastNote);
					});
					~lastNote=note;
					if (~playStrings>0,{
						i.noteOn(1,"/home/zns/Documents/dronecore/samples/string_spurs_swells",~lastNote-12,~velocity.getSynchronous/10);
					});
				},{
					if (~playPiano>0,{
						i.noteOn(1,"/home/zns/Documents/dronecore/samples/"++~instrument,
							note.asInteger+(~octave.getSynchronous),
							~velocity.getSynchronous
						);
					});
				});
			});
			([4,3,2,2,2.5,1.5,1,1,1,1,1,1,0.5,0.5,0.5,0.25,0,0,0,0].choose*4).wait;
			if (4.rand<3,{
				~chord=(~chord+1).mod(~chords.size);
				// ["chord",~chord].postln;
				if (5.rand<4,{
					3.do({ arg j;
						var ind=~chords[~chord][j]+6;
						var note=~scale.wrapAt(ind)+~noteMain;
						if (~playPiano>0,{
							i.noteOn(1,"/home/zns/Documents/dronecore/samples/"++~instrument,note.asInteger,10+20.rand);
						});
					});
					if (~playPiano>0,{
						i.noteOn(1,"/home/zns/Documents/dronecore/samples/"++~instrument,~scale.wrapAt(~bass[~chord]+6)+~noteMain-12,10+30.rand);
					});
				});

			});
		};
	}.play;
	~oscReceiveData.free;
	~oscReceiveData= OSCFunc({ arg msg, time;
		[time, msg].postln;
		if (msg[1].asString=="piano",{
			~playPiano = msg[2].asInteger;
			["playPiano",~playPiano].postln;
		});
	},'/data');
});
)


~playPiano=1;
~fx.set(\db,12)