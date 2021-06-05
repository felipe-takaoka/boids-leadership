class Boid extends Agent{
	static final int TIMERINIT = 240;
	int leaderTimer;      // Timer pour le leadership
	boolean isLeader;     // Agent est leader ou non
	boolean seesPredator; // Variable pour dire si le boid voit un predateur
	// Biais de direction juste apres devenir leader pour que l'effet soit plus visible
	float randThetaBias;  // Moyenne dans la direction du bruit pour la force d'errer (wander)
	PVector cohesionV;
	PVector separationV;
	PVector alignementV;

	// Constructeur du boid
	Boid(PVector position){
		super(position.x, position.y, AgentType.BOID, 1.0);
		this.leaderTimer = 0;
		this.isLeader = false;
		this.cohesionV = new PVector(0,0);
		this.separationV = new PVector(0,0);
		this.alignementV = new PVector(0,0);
	}

	// Methode qui donne le vecteur pointant vers le centroide
	// des agents de type agentType a partir d'une liste d'agents
	// Methode utilisee pour obtenir la cohesion et la fuite des predateurs
    PVector getCentroidOfFromList(AgentType agentType, ArrayList<Agent> seenAgents){
        PVector centroid = new PVector(0, 0);
        int n = seenAgents.size();

        if(n > 0){
            for(Agent a : seenAgents){
            	if(a.type == agentType)
                	centroid.add(smallestDistVect(a.p,this.p));
            }
            centroid.div((float) n);
        }

        return centroid;
    }

    // Methode qui donne le vecteur de direction desiree pour que les boids
    // puissent rester ensemble
    // (pointant vers le centroid des boids du voisinage)
    PVector getCohesion(){
    	PVector k = getCentroidOfFromList(AgentType.BOID, this.neighbors);

    	// Pour garder la meme ordre de grander que les autres forces
		k.setMag(1.4);
    	return k;
    }

    // Methode qui donne le vecteur de direction desiree pour que les boids 
    // suivent le meme chemin
    // (pointant vers la direction moyenne de la vitesse des boids voisins)
    // Legere modification: on donne plus d'importance (poids plus grand)
    // pour les directions des boids a l'avant du groupe
    PVector getAlignment(){
        PVector vm = new PVector(0, 0); // Direction de la vitesse moyenne
        PVector aux, distV;
        Boid bj;
        int n = neighbors.size();
        float weight, z, z0;
        
        if((n > 0) && (this.type == AgentType.BOID)){
        	z0 = min(cos(visionAngle.getValue()),0);
            for(Agent a : neighbors){
                bj = (Boid) a;
                aux = bj.v.copy();
                aux = aux.normalize();
                // La volonte de suivre le meme chemin est d'autant
                // plus elevée que la distance est faible
                distV = smallestDistVect(bj.p,this.p);
                z = cos(PVector.angleBetween(distV,this.v));
                //weight = map(z-z0,0,2,1,20);
                weight = 1;
                aux.div(distV.mag());
                vm.add(aux.mult(weight));
            }

            vm.div((float) n);
            // Pour garder l'ordre de grandeur par rapport aux autres forces
            vm.setMag(3);
        }
        
        return vm;
    }

	// Methode qui donne le vecteur normalise pointant vers le
	// centroide du voisinage du boid courant (sans angle de vision)
	PVector getRelativeCentroid(){
		PVector centroid = new PVector(0, 0);
		int n = boidsInVisionRadius.size();

		if(n > 0){
			for(Boid bj : boidsInVisionRadius)
				centroid.add(smallestDistVect(bj.p,this.p));
			centroid.div(n);
		}

		return centroid;
	}

	// Methode qui donne les forces decrites par les lois des boids
	// de Reynolds: cohesion, separation et alignement
	PVector flock(){
		cohesionV = getCohesion().mult(constCohes.getValue());
		separationV = getSeparation().mult(constSepar.getValue());
		alignementV = getAlignment().mult(constAlign.getValue());
		PVector desired = new PVector(0, 0);

		desired.add(cohesionV);
		desired.add(separationV);
		desired.add(alignementV);
    	
    	// Meme si la norme de la force resultante est superieure
    	// a la force maximale permise, il n'y a pas de probleme.
    	// La saturation est faite au niveau de la methode applyForce.
    	// De plus, d'autres forces sont appliquees et donc la force
    	// resultante ici n'est qu'une partie ponderee de la force
    	// effectivement appliquee
    	return getCorrespondingForce(desired, 1);
	}

	// Methode qui donne une force aleatoire / "errer"
	PVector wander(){
		float   index = (INCRNOISE*bTOff++)%200;
		float   theta = randThetaBias+(noise(index,randIndex)-0.5)*visionAngle.getValue()/3;
		float   norm  = (noise(randIndex,index))*((float) leaderTimer/TIMERINIT);
		PVector randV = PVector.fromAngle(theta+this.v.heading2D());

		return randV.setMag(norm/12);
	}

	// Methode qui gere le chagement de leadership dans les boids
	void changeOfLeadership(){
		if(!this.isLeader){
			PVector rCentroid = getRelativeCentroid();
			float dotProduct, rvLeader;
			float angle = PVector.angleBetween(this.v,rCentroid);
			float gkSigma = (visionRadius.getValue()-this.r)/10;
			float gkMean  = this.r + (visionRadius.getValue()-this.r)/2;
			float eccentricity;

			// Valeur normalisee
			// eccentricity ~= 0 => boid entoure par d'autres
			// eccentricity ~= 1 => sur le bord
			// modele de l'article
			// eccentricity = rCentroid.div(visionRadius.getValue());
			// mon modele : Gaussian Kernel : exp(-(||c-p||_t)^2/2sigma^2)
			// c : centroide des boids compris le voisinage (sans angle de vision)
			// p : position du boid courant
			// relative centroid = c - p;
			// ce n'est pas la norme euclidienne vu que l'espace a
			// l'aspect "toroidal"
			eccentricity = exp(-sq(rCentroid.mag()-gkMean)/(2*sq(gkSigma)));
	
			// Valeurs normalisees => -produit scalaire = -cos()
			// Si positif => boid est en avant
			// Si negatif => le boid est derriere
			dotProduct = -cos(angle);
	
			// -1 <=    dotProduct    <= +1
			// -1 <= ||eccentricity|| <= +1
			// =>   -1 <=  rvLeader   <= +1
			rvLeader = dotProduct*eccentricity;

			if(random(1-chanceLeader.getValue(),1) < rvLeader){
				this.isLeader        = true;
				this.leaderTimer     = TIMERINIT;
				this.agentConstScale = 1.05;
				this.randIndex       = random(1);
				this.randThetaBias   = random(visionAngle.getValue()/4)-visionAngle.getValue()/8;
			}
		}
		else{
			// Le boid courant est leader
			this.leaderTimer--;
			if(leaderTimer == 0){
				this.isLeader        = false;
				this.agentConstScale = 1.0;
			}
		}
	}

	// Methode qui donne la force qui agit sur le leader pendant son leadership
	// Elle se compose de deux forces:
	// La premiere, decroissante : permet le boid de sortir et d'etre en tete du groupe
	// La deuxieme, croissante   : permet de boid d'errer et, donc, influencer le groupe
	PVector leader(){
		PVector desired = this.v.copy();
		PVector wanderComponent = wander();
		float   exitConst = map(sq((float)leaderTimer/TIMERINIT),0,1,-0.75,1);
		float   wndrConst = map(leaderTimer,0,TIMERINIT,0,1);

		desired.setMag(fMax.getValue()*exitConst);
		wanderComponent.setMag(fMax.getValue()*(1-wndrConst)/2);

		desired.add(wanderComponent);

		return desired;
	}

	// Methode qui donne la force permettant de fuir des predateurs
	PVector escape(){
		ArrayList<Agent> seenPredatorsAux = agentListFromPredatorList(this.seenPredators);
		PVector desired = new PVector(0,0);
		int n = this.seenPredators.size();
		PVector aux = new PVector(0,0);

		if(n > 0){
			desired = getCentroidOfFromList(AgentType.PREDATOR,seenPredatorsAux);
			desired.mult(-1); // On veut fuir du centroid des predateurs

			aux = getCorrespondingForce(desired, constEscape);

			// L'une des forces dont la norme doit etre la plus grande
			// Cet ajustement est fait ici pour garder une meme ordre de grandeur
			// pour les constantes qui multiplent les forces
			aux.setMag(100);
		}

		return aux;
	}

	// Methode principale qui met a jour les forces, les appliques sur les boid
	// et met a jour la vitesse et la position avec l'aide de la methode upddate
	// de la classe dont il herite
	void update(){
		PVector force = new PVector(0,0);

		// Met a jour la liste de voisins (boids, predateurs et obstacles)
		refreshNeighbors();
		// Gere la probabilite de devenir leader et son temps de leadership
		changeOfLeadership();

		// Applique une force pour suivre la souris + separation entre boids
		if(OPTION_SEEK.bolValue){
			force.add(seekMouse(new PVector(mouseX,mouseY)));
		} // Applique une force pour fuir d'etre efface + separation entre boids
		else if(OPTION_ERASE.bolValue){
			force.add(fleeFromMouse(new PVector(mouseX,mouseY)));
		} // Deroulement normal de l'application
		else{
			// Applique une acceleration et une force aleatoire
			// si le boid est leader
			if(this.isLeader){
				force.add(leader());
				// Si le boid est leader, il doit etre moins influence
				// par les forces de rassemblement
				force.add(flock().mult(0.75));
			}
			// Calcule et applique les forces pour le "rassemblement"
			force.add(flock());
		}

		force.add(escape()); // Fugir des predateurs
		force.add(avoid());  // Evitement et separation d'obstacle
		if(OPTION_FLOWFIELD.bolValue) // Applique la force du champs
			force.add(followFlowField());


		// Applique la force resultante au boid courant
		this.applyForce(force);

		// Actualise les vecteurs de position et vitesse
		super.update();
	}

	// Methode overriding la methode drawVectors de Agents pour pouvoir
	// dessiner les vecteurs cohesion, separation et alignement
	void drawVectors(){
		if(this.isSelected && OPTION_SVECTOR.bolValue && OPTION_SELECT.bolValue){
			drawVector(getCentroidOfFromList(AgentType.BOID, this.neighbors),
				this.p.x, this.p.y, 1, #E04040, 255);
			drawVector(alignementV, this.p.x, this.p.y, 50.0/3.0, #2B90F5, 255);
			if(separationV.mag() > 0)
				drawVector(separationV, this.p.x, this.p.y, 50.0/5.0, #73E16F, 255);
			
		}
		super.drawVectors();
	}

	// Methode overriding la methode drawVectors de Agents pour pouvoir
	// changer la couleur de l'espace vital quand la force de separation est non-nulle
	void drawVitalSpace(){
		if(OPTION_SELECT.bolValue && this.isSelected
                && OPTION_SVITAL.bolValue){
			if(separationV.mag() > 0){
				stroke(#FFFF00);
	            strokeWeight(2);
	            noFill();
	            arc(this.p.x, this.p.y,
	                2*vitalRadius.getValue(), 2*vitalRadius.getValue(), 0, TWO_PI);	
			}
            else
            	super.drawVitalSpace();
        }
	}

	// Methode principale pour l'affichage du boid avec ses "proprietes"
	void display(){
		// Dessiner le boid (format triangulaire)
		this.drawBoid();

	    // Dessiner champs de vision et d'evittement d'obstacle
       	this.drawVision();

	    // Dessiner l'espace vital
	    this.drawVitalSpace();
	    
	    // Dessiner les veteurs
	    this.drawVectors();

	    // Remet l'acceleration à zero à chaque iteration
    	a.mult(0);
	}

	// Methode qui dessine le boid propremment dit avec les differents options
	void drawBoid(){
		float theta = this.v.heading2D() + PI/2;

		  // Surligner le boid selectione
		if(OPTION_SELECT.bolValue && this.isSelected){
			fill(#26C8FE);
		    stroke(#0B3C4C);
			strokeWeight(1.5);
		} // Surligner le boid leader
		else if(OPTION_SEELEADER.bolValue && this.isLeader){
			float decTimer = ((float) this.leaderTimer/TIMERINIT);
	    	float shade_R = getShadeValue(43,254,decTimer);
	    	float shade_G = getShadeValue(144,228,decTimer);
	    	float shade_B = getShadeValue(245,180,decTimer);
	    	float shade_S = getShadeValue(2.8,1,decTimer);
	    	
		    // (43,144,245) -> (254,228,180)
		    fill(shade_R,shade_G,shade_B,200);
		    stroke(#7466ff,100);
			strokeWeight(shade_S);
	    } // Boid normalement dessine
	    else{
	    	fill(254,228,180,200);
		    stroke(0);
			strokeWeight(1);
	    }
	    pushMatrix();
	    translate(this.p.x,this.p.y);
	    rotate(theta);
	    beginShape();
	    vertex(0, -r*2);
	    vertex(-r, r*2);
	    vertex(r, r*2);
	    endShape(CLOSE);
	    popMatrix();
	}
}