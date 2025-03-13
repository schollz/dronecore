(
s.waitForBoot({
	Routine{
		Buffer.read(s,"test.ogg".asString,action: { |buf|
			"test.ogg".postln;
            buf.postln;
            SynthDef("player",{
                var snd = PlayBuf.ar(2,buf.bufnum,BufRateScale.kr(buf.bufnum),loop:1);
                Out.ar(0,snd*8);
            }).play;
    	});	
	}.play;
});
)

