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

		snd = SelectX.ar(LFNoise2.kr(1/5).range(0.05,0.15),[snd,
			Fverb.ar(snd[0],snd[1],50,
				tail_density: LFNoise2.kr(1/3).range(50,90),
				decay: LFNoise2.kr(1/3).range(50,90),
			)
		]);

		snd = snd * EnvGen.ar(Env.adsr(3,1,1,1));
		//snd = HPF.ar(snd,800);
		ReplaceOut.ar(0,snd * Lag.kr(\db.kr(0),30).dbamp);
	}.play;
	i=InstrumentSample.new(Server.default);

	~chords=[
		[1,3,6],
		[1,4,6],
		[1,3,5],
		[0,3,5],
	];
	~chord=0;
	Routine {
		inf.do{
			3.do({ arg j;
				var ind=~chords[~chord][j]+[0,0,0,0,0,0,1,1,-1,2,-2].choose+6;
				var note=~scale.wrapAt(ind)+60;
				note.postln;
				([2,2.5,1,1.5,2,0.5,0.25,1,1,0.125,0,0].choose*1.05).wait;
				i.noteOn(1,"/home/zns/Documents/dronecore/samples/claus_piano",
					note.asInteger+(~octave.getSynchronous),
					~velocity.getSynchronous
				);
			});
			if (4.rand<2,{
				~chord=(~chord+1).mod(~chords.size);
				["chord",~chord].postln;
				if (5.rand<2,{
					3.do({ arg j;
						var ind=~chords[~chord][j]+6;
						var note=~scale.wrapAt(ind)+60;
						i.noteOn(1,"/home/zns/Documents/dronecore/samples/claus_piano",note.asInteger,10);
					});
				});

			});
		};
	}.play;
});
)