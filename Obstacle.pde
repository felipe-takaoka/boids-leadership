class Obstacle{
	float diam;
	PVector p;
	PVector intersectingPoint;

	Obstacle(PVector position){
		this.p = position.copy();
		this.diam = random(50)+30;
		this.intersectingPoint = null;
	}

	void display(){
		stroke(#192c19);
		strokeWeight(2);
		fill(#66b266,200);
		ellipse(p.x, p.y, diam, diam);
	}

	void displayWillCollide(){
		stroke(#B4EEB4);
		strokeWeight(4);
		fill(#66b266);
		ellipse(p.x, p.y, diam, diam);	
	}
}