(
var size=400;
Window.closeAll;
k = Window("pentacore", Rect(
	50,
	Window.availableBounds.height-size,
	size*1.05,
	size*1.05),border:true)
.front
.background_(
	Color.white
	//Color.rand
).alwaysOnTop_(true);
k.view.decorator_(FlowLayout(k.bounds,5@5,0@0));

Array.fill(25,{
	arg m;
	var row=(m/5).floor.asInteger;
	var col=m%5;
	Button(
		k,
		Rect(row*size/6,col*size/6,size/5,size/5)
	).states_(
		[
			[ " ",
				Color.new(1,1,1,1),
				Color.new(1,1,1,1)
			],
			[ " ",
				Color.new(0.1,0.1,0.1,0.5),
				Color.new(0.9,0.9,0.9,0.8)
			]
		]
	).action_({ arg view;
			("toggle " ++ m ++ " set to " ++ view.value).postln
	})
});
)