(
s.waitForBoot({
	var buses = Dictionary.new();
	~synths = Dictionary.new();

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
	Routine{
		SynthDef("final",{
			arg busTime, busSpace, busPlace, spacePlaceMix=0.0, spaceTimeMix = 1.0, verb=0;
			var snd, freq, dur;
			var sndTime = In.ar(busTime,2);
			var sndSpace = In.ar(busSpace,2);
			var sndPlace = In.ar(busPlace,2);
			var sndGrains;
			sndSpace = SelectX.ar(spacePlaceMix,[sndSpace,sndPlace]);
			snd = SelectX.ar(spaceTimeMix,[sndTime,sndSpace]);
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

			sndGrains = [GrainIn.ar(
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
			snd = SelectX.ar(LFNoise2.kr(1/10).range(0,1.0),[snd,sndGrains]);

			snd = snd * EnvGen.ar(Env.adsr(3,1,1,1));
			snd = HPF.ar(snd,100);
			snd = LPF.ar(snd,12000);
			ReplaceOut.ar(0,snd * Lag.kr(\db.kr(12),3).dbamp*0.5);
		}).send(s);


		["looper1", "looper2"].do { |name, i|
			SynthDef(name, {
				arg buf, busOut, done = 0;
				var snd;
				snd = PlayBuf.ar(i + 1, buf, BufRateScale.kr(buf), loop: 1);
				snd = EnvGen.ar(Env.adsr(3, 1, 1, 3), gate: done, doneAction: 2) * snd;
				Out.ar(busOut, snd);
			}).send(s);
		};

		SynthDef("bass", { arg freq = 440, amp = 0.5, gate = 0, busOut, volume = 0.0;
			var snd, env, oscfreq, output;
			var lfo;
			var newAttack = 1.0;
			var newDecay = 0.9;
			oscfreq = {freq * LFNoise2.kr(Rand(0.0001,0.5)).range(0.99, 1.01)}!10;
			lfo = { SinOsc.kr({ 1/Rand(2,52) }!10) };
			newAttack = Latch.ar(LFNoise2.ar(1/10).range(0.01,1), gate);
			newDecay = Latch.ar(LFNoise2.ar(1/10).range(3,32), gate);
			env = EnvGen.ar(Env.perc(newAttack,newDecay),gate:gate);
			output = LFSaw.ar(oscfreq, mul: lfo.value.range(0,1));
			output = Fold.ar(output,-0.5,0.5);
			output = RLPF.ar(output, (env*freq*0.7) + (freq * lfo.value.range(0.1,2)), lfo.value.range(0.2,1));
			output = Splay.ar(output, lfo.value.range(0,1));
			output = output + (LFNoise2.ar(1/3).range(-96,-32).dbamp*BrownNoise.ar(1));
			Out.ar(busOut, output * env * amp * Lag.kr(volume,3).dbamp);
		}).send(s);

		
		s.sync;
		buses.put("busSpace",Bus.audio(s,2));
		buses.put("busTime",Bus.audio(s,2));
		buses.put("busPlace",Bus.audio(s,2));

		~is=InstrumentSample2.new(Server.default,buses.at("busTime"));
		~isSpace=InstrumentSample2.new(Server.default,buses.at("busSpace"));

		// add final bus to the end
		~synths.put("final",Synth.tail(s,"final",[\busTime,buses.at("busTime"),\busSpace,buses.at("busSpace"),\busPlace,buses.at("busPlace")]));



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
		~playPiano=1;
		~playStrings=1;
		Routine {
			s.sync;
			~synths.put("bass",Synth.head(s,"bass",[
				\busOut, buses.at("busSpace"),
			]));
			inf.do{
				~synths.at("bass").set(\freq,(~scale.wrapAt(~bass[~chord]+6)+~noteMain-24).midicps);
				3.do({ arg j;
					var ind=~chords[~chord][j]+[0,0,0,0,0,0,0,1,1,1,-1,-1,-1,2,-2].choose+6;
					var note=~scale.wrapAt(ind)+~noteMain;
					// ["note",note].postln;
					([4,3,3,2,2,2.5,1.5,1,1,1,1,1,0.5,0.25,0,0].choose).wait;
					if (12.rand<3,{
						~synths.at("bass").set(\gate,0);
					});
					if (12.rand<3,{
						~synths.at("bass").set(\gate,1);
					});
					if (12.rand<5,{
						if (~lastNote>0,{
							~isSpace.noteOff(1,~lastNote);
							~synths.at("bass").set(\gate,0);
						});
						~lastNote=note;
						if (~playStrings>0,{
							~isSpace.noteOn(1,"samples/string_spurs_swells",~lastNote-12,~velocity.getSynchronous/10);
						});
					},{
						["bass",note].postln;
						~synths.at("bass").set(\gate,1);
						if (~playPiano>0,{
							["note",note,~velocity.getSynchronous,~octave.getSynchronous,~instrument].postln;
							~isSpace.noteOn(1,"samples/"++~instrument,
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
								~isSpace.noteOn(1,"samples/"++~instrument,note.asInteger,10+20.rand);
							});
						});
						if (~playPiano>0,{
							~isSpace.noteOn(1,"samples/"++~instrument,~scale.wrapAt(~bass[~chord]+6)+~noteMain-12,10+30.rand);
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
			if (msg[1].asString=="musicbox",{
				["noteon",msg[2]].postln;
				~is.noteOn(1,"samples/musicbox",msg[2].asFloat,msg[3].asFloat);
			});
			if (msg[1].asString=="volume",{
				~synths.at("final").set(\db,msg[2].asFloat);
			});
			if (msg[1].asString=="verb",{
				~synths.at("final").set(\verb,msg[2].asFloat);
			});
			if (msg[1].asString=="bass",{
				// expects db
				~synths.at("bass").set(\volume,msg[2].asFloat);
			});
		},'/data');
		~synths.at("final").set(\verb,0.0);
		~synths.at("final").set(\db,-12);
		"ready".postln;
	}.play;

});
)

