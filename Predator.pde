class Predator extends Agent{
	// rapport des grandeurs entre les predateurs et les boids
	static final int   WAIT_TIME    = 480;
	static final float BRAKE_CONST  = 0.15;
	static final float P_CONST_SEEK = 3;
	static final float P_CONST_SPRT = 1;
	static final float RELAX_TIME   = WAIT_TIME/1.5;
	boolean isChasing;
	int     hungerTimer;

	Predator(PVector position){
		super(position.x, position.y, AgentType.PREDATOR, 1.2);
		this.isChasing = true;
		this.hungerTimer = 0;
	}

	// Methode qui permet de choisir le boid a chasser
	// (celui qui est le plus proche)
	Boid choosePrey(){
		PVector distV;
		Boid  bMin = null;
		float d, dMin = (agentConstScale*visionRadius.getValue())+10;

		for(Boid b : boidsInVisionRadius){
			distV = smallestDistVect(b.p, this.p);
			d = distV.mag();

			if(d < dMin){
				dMin = d;
				bMin = b;
			}
		}

		return bMin;
	}

	// Methode qui fait le predateur manger la proie
	void eatPrey(Boid prey){
		agentsToRemove.add(prey);
		this.isChasing   = false;
		this.hungerTimer = WAIT_TIME;
	}

	// Methode qui donne la force pour la chasse et mange
	// la proie s'il arrive a la rattrapper
	PVector chase(Boid prey){
		PVector desired = new PVector(0,0);

		if(prey != null){
			float dist = smallestDistVect(prey.p,this.p).mag();

			if(dist < this.r){
				this.eatPrey(prey);
			}
			else{
				desired = getCorrespondingForce(getSeek(prey.p), constChase);

				// L'une des forces dont la norme doit etre la plus grande
				// Cet ajustement est fait ici pour garder une meme ordre de grandeur
				// pour les constantes qui multiplent les forces
				desired.setMag(200);
			}
		}

		return desired;
	}

	// Methode qui donne la force agissant sur le predateur
	// quand il n'a pas "faim". Juste apres manger, il va
	// freiner pour diminuer sa grande vitesse a l'instant
	// et apres il commence a "errer" / wanders
	PVector brakeAndWander(){
		PVector desired;

		// On ne veux freiner que si on vient de manger
		// Apres on va "errer" (wander)
		if((this.hungerTimer > RELAX_TIME)
			&& (this.v.mag() > vMax.getValue()*agentConstScale/2)){
			desired = this.v.copy();
			desired.mult(-1);
			return desired.setMag(fMax.getValue()*BRAKE_CONST);
		}
		else{
			// Garder ordre de grandeur
			this.randIndex = random(1);
			return getWander().mult(0.4);
		}
	}

	// Methode qui donne la force permettant de garder une
	// distance minimale entre les predateurs
	PVector separation(){
		PVector sep = getSeparation();

		sep = getCorrespondingForce(sep, constSepar.getValue());

		sep.mult(50);

		// Garder ordre de grandeur par rapport aux autres forces
		return sep;
	}
	
	void update(){
		PVector force = new PVector(0,0);

		refreshNeighbors();

		// Chasse les boids s'il a "faim"
		if(this.isChasing){
			force.add(chase(choosePrey()));
		}
		else{
			force.add(brakeAndWander());
			this.hungerTimer--;
			if(hungerTimer == 0)
				this.isChasing = true;
		}

		force.add(separation()); // Separation entre predateurs
		force.add(avoid());      // Evitement et separation d'obstacle

		if(OPTION_FLOWFIELD.bolValue) // Applique la force du champs
			force.add(followFlowField());
		if(OPTION_ERASE.bolValue) // Applique une force pour fuir d'etre efface
			force.add(fleeFromMouse(new PVector(mouseX,mouseY)));

		// Aplication de la force resultante
		this.applyForce(force);

		// Actualise les vecteurs de position et vitesse
		super.update();

		// Si le predateur n'est pas en chasse, limiter la vitesse max
		if(!this.isChasing && (this.hungerTimer < RELAX_TIME))
			this.v.limit(vMax.getValue()*agentConstScale/2);
	}

	void display(){
		// Dessiner le predateur
		this.drawPredator();

		// Dessiner champs de vision et d'evittement d'obstacle
		this.drawVision();

		// Dessiner l'espace vital
	    this.drawVitalSpace();
	    
	    // Dessiner les veteurs
	    this.drawVectors();

	    // Remet l'acceleration à zero à chaque iteration
    	a.mult(0);
	}

	void drawPredator(){
		float theta = this.v.heading2D() + PI/2;

		  // Surligner le predateur selectionne
		if(OPTION_SELECT.bolValue && this.isSelected){
			fill(#26C8FE);
		    stroke(#0B3C4C);
			strokeWeight(1.5);
		} // Dessiner le predateur sans faim
		else if(!this.isChasing){
			float decTimer = ((float) this.hungerTimer/WAIT_TIME);
			float shade_R = getShadeValue(108,185,decTimer);
	    	float shade_G = getShadeValue(246,52,decTimer);
	    	float shade_B = getShadeValue(210,27,decTimer);
	    	float shade_RS = getShadeValue(0,255,decTimer);
	    	float shade_S = getShadeValue(1,1.5,decTimer);
	    	
		    fill(shade_R,shade_G,shade_B,225);
		    stroke(shade_RS,0,0,225);
			strokeWeight(shade_S);
		} // Dessiner le predateur en chasse
	    else{
	    	fill(185,52,27,225);
		    stroke(255,0,0,225);
			strokeWeight(1.2);
	    }
	    pushMatrix();
	    translate(this.p.x,this.p.y);
	    rotate(theta);
	    beginShape();
	    vertex(0, -r*2);
	    vertex(-r, r);
	    vertex(0, r*2);
	    vertex(r, r);
	    endShape(CLOSE);
	    popMatrix();
	}
}