(
    s.waitForBoot({
        var synths = Dictionary.new();
        var buses = Dictionary.new();
        var octaves = [2,3,5];
        var octaves2 = [2,4,6];
        var emin=[4,7,11];
        var cmaj=[0,4,7];
        var gmaj=[7,11,14];
        var dmaj=[2,6,9];
        var chords=[
            emin.scramble.postln,
            cmaj.scramble,
            gmaj.scramble,
            dmaj.scramble
        ].postln;
        var voiceNotes = chords.flop.flatten.clump(4).postln;
        var emin2=[4,7-12,11-12];
        var cmaj2=[0,4-12,7];
        var gmaj2=[7,11-12,14-12];
        var dmaj2=[2,6,9-12];
        var chords2=[
            emin2.scramble.postln,
            cmaj2.scramble,
            gmaj2.scramble,
            dmaj2.scramble
        ].postln;
        var voiceNotes2 = chords2.flop.flatten.clump(4).postln;
        Routine {
            var group = Group.new; // Create a new group
            SynthDef("final",{
                arg busTime, busSpace, busPlace, spacePlaceMix=0.0, spaceTimeMix = 0.0, verb=0.8, volume = 1.0;
                var snd, freq, dur;
                var sndTime = In.ar(busTime,2)*0.1;
                var sndSpace = In.ar(busSpace,2);
                var sndPlace = In.ar(busPlace,2);
                var sndGrains;
                snd = In.ar(busSpace,2);
                freq = LFNoise2.kr(1/3).range(0.5,10);
                dur = LFNoise2.kr(1/3).range(0.5,4);

                snd = AnalogTape.ar(snd,0.9,0.9,0.8);
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
                Out.ar(0,snd * Lag.kr(volume));
            }).send(s);

            SynthDef("supersaw",{
                arg note,t_trig=1,env=1,db=0,busOut;
                var hz = note.midicps;
                var snd=Mix.ar({
                    var snd_;
                    snd_=SawDPW.ar(Lag.kr(note.midicps,0.02));
                    snd_=DelayC.ar(snd_, rrand(0.01,0.03), LFNoise1.kr(Rand(5,10),0.01,0.02)/15 );
                    Pan2.ar(snd_,0)/4
                }!10);
                var sndFiltered=MoogLadder.ar(snd.tanh,LinExp.kr(VarLag.kr(LFNoise0.kr(1/6)+LFNoise0.kr(0),6,warp:\sine),-1,1,hz*rrand(4,12),hz*rrand(12,16)));
                var sndHPF = HPF.ar(sndFiltered, hz/rrand(1,3));
                var envGate = EnvGen.kr(Env.perc(Rand(1,5),Rand(5,8)),t_trig);
                var envMain = EnvGen.kr(Env.adsr(3.0,1.0,1.0,3.0),env,doneAction:2);
                var sndFinal = Pan2.ar(sndHPF * envMain * envGate);
                Out.ar(busOut,sndFinal* db.dbamp/6);
            }).send(s);

            s.sync;
            "Creating buses".postln;
            buses.put(\busTime, Bus.audio(s,2));
            buses.put(\busSpace, Bus.audio(s,2));
            buses.put(\busPlace, Bus.audio(s,2));
            s.sync;
            "Creating synths".postln;
            synths.put(\final, Synth.tail(group,"final",[ // Use the created group as the target
                \busTime, buses[\busTime].index,
                \busSpace, buses[\busSpace].index,
                \busPlace, buses[\busPlace].index,
            ]));
            voiceNotes.do({|notes, i|
                [notes,i].postln;
                synths.put("voice"+i, Synth.head(group,"supersaw",[
                    \note, notes[0]+(octaves[i]*12),
                    \busOut, buses[\busSpace],
                    \db, rrand(-600,-300)/100,
                ]));
                Routine{
                    inf.do{
                        notes.do({|note,j|
                            [i,j,note].postln;
                            synths.at("voice"+i).set(\t_trig,1,\note, note+(octaves[i]*12));
                           (rrand(590,610)/100.0).wait;
                        })
                    };
                }.play;
            });
            voiceNotes2.do({|notes, i|
                [notes,i].postln;
                synths.put("voice"+(i+5), Synth.head(group,"supersaw",[
                    \note, notes[0]+(octaves2[i]*12),
                    \busOut, buses[\busSpace],
                    \db, rrand(-1200,-600)/100,
                ]));
                Routine{
                    inf.do{
                        notes.do({|note,j|
                            [i,j,note].postln;
                            synths.at("voice"+(i+5)).set(\t_trig,1,\note, note+(octaves[i]*12));
                            (rrand(590,610)/100.0).wait;
                        })
                    };
                }.play;
            });
            s.sync;

        }.play;
    });
)