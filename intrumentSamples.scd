(
s.waitForBoot({
	~velocity=Bus.control(s,1);
	{
		Out.kr(~velocity,SinOsc.kr(1/LFNoise2.kr(1/5).range(5,6)).range(1,90));
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

		snd = SelectX.ar(LFNoise2.kr(1/5).range(0.1,0.25),[snd,
			Fverb.ar(snd[0],snd[1],50,
				tail_density: LFNoise2.kr(1/3).range(50,90),
				decay: LFNoise2.kr(1/3).range(50,90),
			)
		]);

		snd = snd * EnvGen.ar(Env.adsr(10,1,1,1));
		ReplaceOut.ar(0,snd * Lag.kr(\db.kr(0),30).dbamp);
	}.play;
	i=InstrumentSample.new(Server.default);
	Routine {
		inf.do{
			[2,2.5,1,1.5,2,0.5,0.25,1,1].choose.wait;
			i.noteOn(1,"/home/zns/Documents/dronecore/samples/claus_piano",
				[60,59,60,59,60,57].choose+(~octave.getSynchronous),
				~velocity.getSynchronous
			);

			[0,0,2,2.5,3,1,1.5,2,0.5,0.25,1,1].choose.wait;
			i.noteOn(1,"/home/zns/Documents/dronecore/samples/claus_piano",
				[64,64,64,62,65].choose+(~octave.getSynchronous),
				~velocity.getSynchronous
			);
			[0,0,2,2.5,3,0.125,1,1.5,2,0.5,0.25,1,1].choose.wait;
			i.noteOn(1,"/home/zns/Documents/dronecore/samples/claus_piano",
				[67,67,67,67,69,69,69,71,71].choose+(~octave.getSynchronous),
				~velocity.getSynchronous
			);
		};
	}.play;
});
)


i.noteOn(1,"/home/zns/Documents/dronecore/samples/ultra_synth",60-12,20)
