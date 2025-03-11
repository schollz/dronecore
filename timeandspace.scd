(
s.waitForBoot({
	var buses = Dictionary.new();
	var synths = Dictionary.new();
	Routine{
		SynthDef("final",{
			arg busIn;
			var snd, freq, dur;
			snd = In.ar(busIn,2);
			freq = LFNoise2.kr(1/3).range(0.5,10);
			dur = LFNoise2.kr(1/3).range(0.5,4);

			snd = AnalogTape.ar(snd,0.9,0.9,0.8);
			snd = SelectX.ar(LFNoise2.kr(1/5).range(0,0.5),[snd,AnalogDegrade.ar(snd)]);
			snd = SelectX.ar(LFNoise2.kr(1/5).range(0.05,0.1),[snd,
				Fverb.ar(snd[0],snd[1],50,
					tail_density: LFNoise2.kr(1/3).range(50,90),
					decay: LFNoise2.kr(1/3).range(50,90),
				)
			]);

			snd = snd * EnvGen.ar(Env.adsr(3,1,1,1));
			snd = HPF.ar(snd,100);
			snd = LPF.ar(snd,12000);
			ReplaceOut.ar(0,snd * Lag.kr(\db.kr(0),3).dbamp);
		}).send(s);
		s.sync;
		buses.put("final",Bus.audio(s,2));

		~is=InstrumentSample2.new(Server.default,buses.at("final"));

		// add final bus to the end
		synths.put("final",Synth.tail(s,"final",[\busIn,buses.at("final")]));

		~oscReceiveData.free;
		~oscReceiveData= OSCFunc({ arg msg, time;
			[time, msg].postln;
			if (msg[1].asString=="piano",{
			});
			if (msg[1].asString=="musicbox",{
				~is.noteOn(1,thisProcess.nowExecutingPath.dirname++"/samples/musicbox",msg[2].asFloat,msg[3].asFloat);
			});
		},'/data');


	}.play;

});
)
