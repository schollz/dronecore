Drone {

	var server;
	var <bufs;
	var buses;
	var syns;
	var oscs;
	var params;
	var buf;
	var <drones;

	*new { arg argServer, argPath;
		^super.new.init(argServer, argPath);
	}


	set {
		arg name,k,v;
		if (syns.at(name).isNil,{
			^0
		});
		if (params.at(name).isNil,{
			params.put(name,Dictionary.new());
		});

		if (syns.at(name).isRunning,{
			//["[ouro] set",name,k,v].postln;
			syns.at(name).set(k,v);
			params.at(name).put(k,v);
		});
	}

	wrapDef {
		arg fn, name;
		var def, nope = false;
		postln("building synthdef: "++name);
		def = SynthDef.new(name, {
			arg hz=220, amp=1, out=0, gate=1, attack=10.0, release=10.0;

			var aenv, snd;
			snd = { fn.value(hz, amp, buf.bufnum) }.try {
				arg err;
				postln("failed to wrap ugen graph! error:");
				err.postln;
				nope = true;
				[Silent.ar]
			};
			aenv = EnvGen.kr(Env.asr(attack, 1, release), gate, doneAction:2);
			Out.ar(out, snd * aenv);
		});
		if (nope, {
			^nil
		}, {
			def.load(server);
			^def;
		});
	}


	startDrone {
		arg id,droneNum;

		if (syns.at(id).notNil,{
			if (syns.at(id).isRunning,{
				syns.at(id).set(\gate,0);
			});
		});

		syns.put(id,Synth.head(server,
			drones[droneNum],[
				out: buses.at("main")
		]));
		NodeWatcher.register(syns.at(id));
	}


	/*		var baseDronePath = PathName(Document.current.path).pathOnly ++ "drones";
	baseDronePath.postln;

	PathName.new(baseDronePath).entries.do({|e|
	var name = e.fileNameWithoutExtension;
	var def = socket.wrapDef(e.fullPath.load, name, server);
	});

	*/
	init {
		arg argServer, argPath;

		server = argServer;


		argPath.postln;

		// initialize variables
		syns = Dictionary.new();
		buses = Dictionary.new();
		bufs = Dictionary.new();
		oscs = Dictionary.new();
		params = Dictionary.new();
		drones = Array.new();

		buf = Buffer.alloc(argServer,96000,2);

		// main output
		SynthDef("main",{
			arg busIn, busOut, busCount, db=0, reverb=0;
			var snd;
			var count;
			count = Clip.kr(In.kr(busCount,1)/5,1,30);
			snd = In.ar(busIn,2);

			snd = snd * EnvGen.ar(Env.adsr(10,1,1,1));

			snd = AnalogTape.ar(snd,0.9,0.9,0.7,1);

			snd = SelectX.ar(Lag.kr(reverb,1),[snd,
				Fverb.ar(snd[0],snd[1],200,
					tail_density: LFNoise2.kr(1/3).range(50,90),
					decay: LFNoise2.kr(1/3).range(50,90),
				)
			]);

			Out.ar(busOut,snd * Lag.kr(db,30).dbamp);
		}).send(server);

		// load drones
		PathName.new(argPath).entries.do({|e|
			var name = e.fileNameWithoutExtension;
			var def = this.wrapDef(e.fullPath.load, name, server);
			drones = drones.add(name);
		});

		server.sync;

		// setup buses
		// buses.put("input",Bus.audio(server,2));
		buses.put("main",Bus.audio(server,2));
		buses.put("count",Bus.control(server,1));

		// setup synths
		syns.put("main",Synth.tail(server,"main",[\busOut,0,\busIn,buses.at("main"),\busCount,buses.at("count")]));
		syns.keysValuesDo({ arg k, val;
			NodeWatcher.register(val);
		});

		server.sync;
		"ready".postln;
	}


	free {
		bufs.keysValuesDo({ arg k, val;
			val.free;
		});
		oscs.keysValuesDo({ arg k, val;
			val.free;
		});
		syns.keysValuesDo({ arg k, val;
			val.free;
		});
		buses.keysValuesDo({ arg k, val;
			val.free;
		});
	}
}


