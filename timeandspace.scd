(
s.waitForBoot({
	var buses = Dictionary.new();
	~synths = Dictionary.new();
	Routine{
		SynthDef("final",{
			arg busIn, verb;
			var snd, freq, dur;
			snd = In.ar(busIn,2);
			freq = LFNoise2.kr(1/3).range(0.5,10);
			dur = LFNoise2.kr(1/3).range(0.5,4);

			//snd = AnalogTape.ar(snd,0.9,0.9,0.8);
			snd = SelectX.ar(LFNoise2.kr(1/5).range(0,0.5),[snd,AnalogDegrade.ar(snd)]);
			snd = SelectX.ar(LFNoise2.kr(1/5).range(0.05,0.1)+verb,[snd,
				Fverb.ar(snd[0],snd[1],1,
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
			ReplaceOut.ar(0,snd * Lag.kr(\db.kr(-12),3).dbamp);
		}).send(s);
		s.sync;
		buses.put("final",Bus.audio(s,2));

		~is=InstrumentSample2.new(Server.default,buses.at("final"));

		// add final bus to the end
		~synths.put("final",Synth.tail(s,"final",[\busIn,buses.at("final")]));

		~oscReceiveData.free;
		~oscReceiveData= OSCFunc({ arg msg, time;
			[time, msg].postln;
			if (msg[1].asString=="piano",{
			});
			if (msg[1].asString=="musicbox",{
				["noteon",msg[2]].postln;
				~is.noteOn(1,"/home/zns/Documents/dronecore/samples/musicbox",msg[2].asFloat,msg[3].asFloat);
			});
		},'/data');
		~synths.at("final").set(\verb,0.0);
		~synths.at("final").set(\db,-12);
		"ready".postln;
		s.record;
	}.play;

});
)

