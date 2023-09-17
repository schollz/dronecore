{
	arg hz=120, amp=0.5, buf=0;
	var snd,snd2,sndr;
	var rate=VarLag.kr(LFNoise0.kr(1/10),LFNoise0.kr(1/10).range(0.1,10),warp:\sine).range(0.5,1);
	var pw,pr;

	snd=Splay.ar({
		var snd_;
		var maxDelay=rrand(0.3,0.6);
		var minDelay=maxDelay-rrand(0.05,0.2);
		var maxDelay2=rrand(0.2,0.4);
		var minDelay2=maxDelay2-rrand(0.05,0.2);
		var hz_=Lag.kr([hz*rrand(0.995,1.00),hz*rrand(1.0,1.005)]*TChoose.kr(Impulse.kr(0)+Dust.kr(1/30),[0.5,0.5,1,1,1,1,2,2,3,4,0.5,0.25]),rrand(0.5,2));
		snd_=Saw.ar(hz_);
		snd_=snd_+CombC.ar(snd_,maxDelay,VarLag.kr(LFNoise0.kr(1/5),5,warp:\sine).range(maxDelay*rrand(0.5,0.9),maxDelay),rrand(0.5,1));
		snd_=snd_+CombC.ar(snd_,maxDelay2,VarLag.kr(LFNoise0.kr(1/5),5,warp:\sine).range(maxDelay2*rrand(0.5,0.9),maxDelay2),rrand(0.5,1));

		snd_
	}!6);

	pw=DelayL.ar(Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf)),0.5,0.5);
	pr=Phasor.ar(0, BufRateScale.kr(buf)*rate, 0, BufFrames.kr(buf));
	BufWr.ar(snd,buf,pw);
	sndr=BufRd.ar(2,buf,pr,interpolation:4);
	snd=sndr;

	snd=snd+CombC.ar(snd,0.5,VarLag.kr(LFNoise0.kr(1/5),5,warp:\sine).range(0.3,0.5),rrand(0.5,1));

	snd=MoogLadder.ar(snd,LinExp.kr(SinOsc.kr(
		LinExp.kr(VarLag.kr(LFNoise0.kr(1/5),5,warp:\sine),-1,1,0.001,20)
	),-1,1,
	VarLag.kr(LFNoise0.kr(1/10),0.1,warp:\sine).range(600,6000)
	,9000));

	snd=Limiter.ar(snd,0.95,0.1);

	snd
}
