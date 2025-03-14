(
s.waitForBoot({
	Routine {
		s.sync;
		1.wait;
		d = Drone.new(Server.default,thisProcess.nowExecutingPath.dirname++ "/drones");
		1.wait;
		d.startDrone("track1",0);

	}.play;
});
)

d.startDrone("track1",1);
d.set("track1","amp",0.1)

d.set("track1","gate",0);

d.startDrone("track2",0);
d.startDrone("track1",1);

d.set("track1","hz",460)
d.set("main","reverb",0.5)
