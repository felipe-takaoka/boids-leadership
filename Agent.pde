abstract class Agent{
    static final float INCRNOISE = 0.01;    // Increment pour le bruit de Perlin
    static final float OBSTACLE_MARGIN = 8; // Marge pour l'algorithme de evitement d'obstacle
    static final float BASE_R = 6; // "Taille" de base pour l'agent
    AgentType type; // Type d'agent (boid, predateur, ...)
    PVector p; // Vecteur position
    PVector v; // Vecteur vitesse
    PVector a; // Vecteur acceleration
    ArrayList<Agent> neighbors;           // Listes commentees dans le constructeur
    ArrayList<Boid> boidsInVisionRadius;
    ArrayList<Predator> seenPredators;
    ArrayList<Obstacle> seenObstacles;
    ArrayList<Obstacle> closeObstacles;
    float r;               // Taille de l'agent - BASE_R*agentConstScale
    float randIndex;       // Index pour l'increment dans la bruit de Perlin
    float bTOff = 0;       // Index pour l'increment dans la bruit de Perlin
    float agentConstScale; // Constante d'echelle des grandeurs de chaque agent
    boolean isSelected;
  
    // Constructeur de l'agent
    // Il construit un agent de type aType dans la position (x,y) avec une "taille" scl;
    Agent(float x, float y, AgentType aType, float scl){
        this.type = aType;
        this.agentConstScale = scl;
        this.r = BASE_R*agentConstScale;
        this.p = new PVector(x,y);
        this.v = new PVector(0,0);
        this.a = new PVector(random(1)-0.5, random(1)-0.5);
        this.a.setMag(fMax.getValue()*agentConstScale/2);
        this.isSelected = false;

        // boidsInVisionRadius: si boid, sert au changement de leadership
        //                      si predateur, sert comme liste de cibles
        this.boidsInVisionRadius = new ArrayList();
        this.neighbors      = new ArrayList(); // Boid ou predateurs
        this.seenPredators  = new ArrayList(); // Predateurs vues par les boids
        this.closeObstacles = new ArrayList(); // Pour la separation
        this.seenObstacles  = new ArrayList(); // Pour l'evasion
    }

    /* ========== Methodes pour la vision locale des agents ========== */

    // Methode utilisee pour savoir si un agent j est dans le cercle
    // de rayon visionRadius centre dans la position de l'agent courant
    boolean isInVisionRadius(Agent aj){
        PVector relativePos = smallestDistVect(aj.p,this.p);
        float distance = relativePos.mag();
        return (distance > 0) && (distance < agentConstScale*visionRadius.getValue());
    }

    // Methode utilisee pour savoir si un agent j est dans l'angle de
    // vision de l'agent courant (c-a-d que l'angle entre le vecteur de
    // la position relative de l'agent j avec le vecteur de la vitesse 
    // de l'agent courant est compris entre [-visionAngle;+visionAngle])
    boolean isInVisionAngle(Agent aj){
        PVector relativePos = smallestDistVect(aj.p,this.p);
        return (PVector.angleBetween(this.v,relativePos) < visionAngle.getValue());
    }

    // Methode utilisee pour savoir si l'agent this voit un autre agent
    boolean sees(Agent aj){
        return isInVisionRadius(aj) && isInVisionAngle(aj);
    }

    // Methode utilisee pour savoir si l'agent this voit un obstacle
    boolean sees(Obstacle obst){
        PVector distV  = smallestDistVect(obst.p,this.p);
        float distance = distV.mag();

        if((distance > 0) && (distance < agentConstScale*visionRadius.getValue()+obst.diam/2)){
            if(PVector.angleBetween(this.v,distV) < visionAngle.getValue()){
                return true;
            }
        }
        return false;
    }

    // Methode utilisé pour actualiser la liste de voisins et d'obstacles
    // proches de l'agent courant (la liste de predateurs aussi si l'agent
    // courant est un boid/proie)
    // Attention: Coute cher en memoire (O(n^2) globalement)
    void refreshNeighbors(){
        Predator pj;
        Boid     bj;

        this.neighbors.clear();
        this.boidsInVisionRadius.clear();
        this.seenPredators.clear();
        this.closeObstacles.clear();
        this.seenObstacles.clear();

        for(Agent a : agents){
            // L'agent a n'est pas lui meme
            if(a != this){
                // L'agent courant est un boid/proie
                if(this.type == AgentType.BOID){
                    if(isInVisionRadius(a)){
                        // L'agent de la liste est un autre boid
                        if(a.type == AgentType.BOID){
                            bj = (Boid) a;
                            boidsInVisionRadius.add(bj);
                            if(isInVisionAngle(bj))
                                this.neighbors.add(bj);
                        } // L'agent de la liste est un predateur
                        else if(a.type == AgentType.PREDATOR){
                            pj = (Predator) a;
                            if(this.isInVisionAngle(pj))
                                this.seenPredators.add(pj);
                        }
                    }
                }
                // L'agent courant est un predateur
                else if(this.type == AgentType.PREDATOR){
                    // Les possedent une champs de vision different
                    // donc on donne une "constante d'echelle" aux methodes
                    if(this.sees(a)){
                        // L'agent de la liste est un boid
                        if(a.type == AgentType.BOID)
                            this.boidsInVisionRadius.add((Boid) a);
                        // L'agent de la liste est un autre predateur
                        else if(a.type == AgentType.PREDATOR)
                            this.neighbors.add((Predator) a);
                    }
                }
            }
        }

        for(Obstacle o : obstacles){
            if(this.sees(o))
                seenObstacles.add(o);
            if(this.closeToObstacle(o))
                closeObstacles.add(o);
        }
    }

    /* =============================================================== */


    /* ======= Methodes auxiliaires pour le calcul des forces ======== */

    // Methode qui detecte si un point est dans un obstacle (cercle)
    // Si oui, on ajoute le point a l'attribut de l'obstacle
    boolean isPointInCircle(PVector pos, Obstacle obst){
        PVector dist = smallestDistVect(obst.p, pos);
        boolean intersects = (dist.mag() < obst.diam/2);

        if(intersects)
          obst.intersectingPoint = pos;

        return intersects;
    }

    // Methode utilisee pour savoir si le boid est proche d'un obstacle
    boolean closeToObstacle(Obstacle obst){
        float distance = smallestDistVect(this.p,obst.p).mag();

        if((distance > 0) && (distance < vitalRadius.getValue()+obst.diam/2))
            return true;

        return false;
    }

    // Algorithme de selection de l'obstacle le plus menaçant
    // Se base sur l'intersection des segments de droites avec les
    // obstacles ronds. Il est simplifie pour besoins d'efficacite
    // et ne cherche que si des points de test sont dans les obstacles.
    // Il y a 2 points de test pour chaqu'une des 3 droites de direction
    // egale a celle de la vitesse (donc paralleles) decalees entre elles
    //             droite 1
    //            -----o-----o               ->
    // droite 2  x-----o-----o------------> 2*V
    //            -----o-----o
    //             droite 3
    // x : boid / ---> 2*V : 2*Vecteur de la vitesse / o : point de test
    // Voir l'execution pour mieux comprendre
    Obstacle getMostThreateningObstacle(ArrayList<Obstacle> obsts){
        ArrayList<Obstacle> mostThreateningMiddle = new ArrayList();
        ArrayList<Obstacle> mostThreateningBorder = new ArrayList();
        PVector ahead  = this.v.copy();
        PVector ahead2 = ahead.copy();
        PVector ahead_t, ahead2_t;
        PVector ahead_b, ahead2_b;
        PVector auxV;
        float theta1, theta2, visionRange = visionRadius.getValue();

        ahead.setMag(visionRange);
        ahead2.setMag(visionRange/2);

        theta1 = atan(OBSTACLE_MARGIN/visionRange);
        theta2 = atan(2*OBSTACLE_MARGIN/visionRange);

        ahead_t = ahead.copy();
        ahead2_t = ahead2.copy();
        ahead_t.rotate(theta1);
        ahead2_t.rotate(theta2);

        ahead_b = ahead.copy();
        ahead2_b = ahead2.copy();
        ahead_b.rotate(-theta1);
        ahead2_b.rotate(-theta2);

        ahead.add(this.p);
        ahead2.add(this.p);
        ahead_t.add(this.p);
        ahead2_t.add(this.p);
        ahead_b.add(this.p);
        ahead2_b.add(this.p);
 
        for(Obstacle o : obsts) {
            boolean collisionTop, collisionBottom;
            boolean collisionCenter = 
                isPointInCircle(ahead,o) || isPointInCircle(ahead2,o) || isPointInCircle(this.p,o);
 
            if(collisionCenter){
                mostThreateningMiddle.add(o);
            }
            else{
                collisionTop    = isPointInCircle(ahead_t,o) || isPointInCircle(ahead2_t,o);
                collisionBottom = isPointInCircle(ahead_b,o) || isPointInCircle(ahead2_b,o);

                if(collisionBottom || collisionTop){
                    mostThreateningBorder.add(o);
                }
            }
        }

        if(mostThreateningMiddle.size() > 0)
            return getClosestObstacleFromList(mostThreateningMiddle);

        if(mostThreateningBorder.size() > 0)
            return getClosestObstacleFromList(mostThreateningBorder);

        return null;
    }

    // Methode qui renvoie l'obstacle dans une liste le plus proche de l'agent
    Obstacle getClosestObstacleFromList(ArrayList<Obstacle> obsts){
        PVector distV;
        Obstacle o_min = null;
        float dist_aux, dist_min = height+width; // grande valeur pour commencer

        for(Obstacle o : obsts){
            distV = smallestDistVect(o.p,this.p);
            dist_aux = distV.mag();

            if(dist_aux < dist_min){
                dist_min = dist_aux;
                o_min = o;
            }
        }

        return o_min;
    }

    // Methode qui donne la force de "direction" bornee
    PVector getSteerForce(PVector desiredDirection){
        PVector steer = PVector.sub(desiredDirection,this.v);
        steer.limit(fMax.getValue()*agentConstScale);

        return steer;
    }

    /* =============================================================== */


    /* ========= Methodes qui donnent les differentes forces ========= */

    // Methode qui donne le vecteur de direction desiree pour que les
    // agents gardent une distance minimale entre eux
    // (poitant dans la direction contraire au voisin)
    PVector getSeparation(){
        PVector separation = new PVector(0, 0);
        PVector dp;
        float d, newMag;
        int count = 0;

        if(neighbors.size() > 0){
            for(Agent a : neighbors){
                dp = smallestDistVect(this.p,a.p);
                d  = dp.mag();
                if(d < r+vitalRadius.getValue()){
                    dp.normalize();
                    // La volonte de s'eloigner est d'autant
                    // plus elevée que la distance est faible
                    dp.div(d);
                    separation.add(dp);
                    count++;
                }
            }

            if(count > 0){
                separation.div((float) count);
                // Pour garder la meme ordre de grander que les autres forces
                separation.setMag(5);
            }
        }

        return separation;
    }

    // Methode qui donne le vecteur d'evasion d'obstacle
    // Attention: obstacle avoidance != separation (flee)
    // Evittement d'obstacle ne s'interesse qu'aux obstacles
    // dans la direction de l'agent
    PVector getObstacleAvoidance(){
        Obstacle obst = getMostThreateningObstacle(this.seenObstacles);
        PVector desired = new PVector(0, 0);
        float dist;

        if(obst != null){
            if(this.isSelected && OPTION_SVISION.bolValue && OPTION_SVECTOR.bolValue){
                // Surligner les obstacles dans le chemin des boids
                obst.displayWillCollide();
            }

            desired = PVector.sub(obst.intersectingPoint,obst.p);
            dist = desired.mag();
            desired.normalize();
            desired.div(dist);
        }

        return desired;
    }

    // Methode qui donne le vecteur de separation d'obstacle
    // On ajoute non pas seulement la separation entre agents et 
    // l'algorithme d'evitement d'obstacle, mais aussi la sepa-
    // ration pour les obstacles, de maniere a garder une
    // distance minimale entre eux. Par contre, pour le dernier, 
    // il faut que la force soit plus grande, vu que l'agent ne 
    // peut pas ocuper le meme espace que l'obstacle
    PVector getObstacleSeparation(){
        PVector desired = new PVector(0, 0);
        PVector dp;
        float dist;
        int n = closeObstacles.size();

        for(Obstacle o : closeObstacles){
            // Il n'y a pas besoin de tester la distance
            // Les obstacles dans la liste closeObstacles
            // sont deja ceux dont il faut s'eloigner
            dp = smallestDistVect(this.p,o.p);
            dist = dp.mag();
            desired.normalize();
            desired.div(dist);
            desired.add(dp);
        }

        if(n > 0)
            desired.div((float) n);

        return desired;
    }

    // Methode qui donne le vecteur de chasse a une cible
    PVector getSeek(PVector target){
        return smallestDistVect(target,this.p);
    }

    // Methode qui donne le vecteur de fuite d'une position
    PVector getFlee(PVector target){
        return smallestDistVect(this.p,target);
    }

    // Methode qui donne le vecteur de wander ("errer")
    PVector getWander(){
        float   index = (INCRNOISE*bTOff++)%200;
        float   theta = 2.2*(noise(index,randIndex)-0.5)*visionAngle.getValue();
        float   norm  = (noise(randIndex,index));
        PVector randV = PVector.fromAngle(theta+this.v.heading2D());

        randV.setMag(norm);
        drawVector(randV, this.p.x, this.p.y, 1, 255, 255);

        return randV;
    }

    // Methode qui donne la force de "chasse" de la souris et implemente
    // aussi la separation entre agents et la force d'arrivee (arrival)
    // = diminue la force de "chasse" de la souris si on est de plus en 
    // plus proche d'elle
    PVector seekMouse(PVector mouse){
        // On ne tient pas compte de l'aspect toroidal => PVector.sub
        PVector desired = new PVector(0,0);
        PVector seek = PVector.sub(mouse,this.p);
        PVector sepa = getSeparation().mult(constSepar.getValue());
        PVector steer;
        float   dist = seek.mag();
        float   mag;

        desired.add(seek.setMag(0.01));
        desired.add(sepa);

        // Arrival
        if(dist < 10*this.r)
            mag = map(dist,0,10*this.r,0,vMax.getValue());
        else
            mag = vMax.getValue();

        desired.setMag(mag);
        steer = PVector.sub(desired,this.v);

        // Garder ordre de grandeur
        return steer;
    }

    // Methode qui donne la force de "fuite" pour la souris
    PVector fleeFromMouse(PVector mouse){
        // On ne tient pas compte de l'aspect toroidal
        return PVector.sub(this.p,mouse);
    }

    // Methode qui donne la force de detour + separation d'obstacle
    PVector avoid(){
        PVector desired = new PVector(0,0);

        if(obstacles.size() > 0){
            PVector av = getObstacleAvoidance().mult(constAvoid*agentConstScale);
            PVector s =  getObstacleSeparation().mult(constSeparObst*agentConstScale);

            // La force resultante "partielle" due au detour d'obstacle
            // peut ici evidemment avoir une norme superieure a la force
            // maximale permise. Voir commentaire dans la methode flock
            desired.add(av);
            desired.add(s);

            desired = getCorrespondingForce(desired,1);

            // Pour garder la meme ordre de grander que les autres forces
            desired.setMag(15);
        }

        // Ne pas utiliser comme une "steering force"
        return desired;
    }

    // Methode qui donne la force permettant de suivre le champs d'ecoulement
    PVector followFlowField(){
        PVector fieldForce =  mapGrid.getVector(this.p.x, this.p.y).copy();

        return fieldForce.mult(constFlField.getValue());
    }

    // Methode qui donne la force a etre utilisee (steering force ou pas)
    // multipliee par une constante respective
    PVector getCorrespondingForce(PVector desired, float scl){
        PVector correspF = new PVector(0,0);

        if((desired != null) && (desired.mag() > 0)){
            correspF = desired.copy();
    
            if(OPTION_STEER.bolValue)
                correspF.setMag(vMax.getValue()*agentConstScale*scl);
            else
                correspF.setMag(fMax.getValue()*agentConstScale*scl);
        }
        return correspF;
    }

    // Methode permettant l'application d'une force à l'agent
    // Pour les agents leaders, on n'impose pas de force maximale
    // pour qu'ils puissent guider le groupe
    void applyForce(PVector f){
        this.a.add(f);
        this.a.limit(fMax.getValue()*agentConstScale); // on suppose "m = 1kg"
    }

    /* =============================================================== */


    // Methode principale appele par l'appli. Elle actualise les vecteurs
    void update(){
        // Si aucune force n'y agit pas, on lui en donne une
        if(a.mag() == 0){
            a = v.copy(); // prendre la direction de la vitesse
            a.setMag(fMax.getValue()*agentConstScale/5); // on suppose "m = 1kg"
        }

        // Increment/pas de temps pas pris en compte (ne change que l'echelle)
        v.add(a);
        v.limit(vMax.getValue()*agentConstScale);
        obstacleConstraint(); // evite que les agents entrent dans les obstacles
        p.add(v);

        // Espace toroidal
        borders(this.p,this.r);
    }
  
    /* =============================================================== */


    /* =========== Methodes pour l'affichage et auxiliares =========== */

    // Methode pour l'affichage de la forme de chaque agent
    abstract void display();

    // Methode utilise pour changer progressivement d'une valeur
    // a une autre parametree par un timer decroissant
    float getShadeValue(float from, float to, float decTimer){
        return to+(from-to)*decTimer;
    }

    // Methode pour dire si la souris est sur l'agent courant
    boolean isMouseOverAgent(){
        if (mouseX >= (this.p.x-1.5*r) && mouseX <= (this.p.x+1.5*r) && 
            mouseY >= (this.p.y-1.5*r) && mouseY <= (this.p.y+1.5*r)) {
            return true;
        }
        return false;
    }

    // Methode qui dessine le champs de vision et d'evasion d'obstacle
    void drawVision(){
        if(OPTION_SELECT.bolValue && this.isSelected
                && OPTION_SVISION.bolValue){
            float theta = this.v.heading2D();
            float vr = agentConstScale*visionRadius.getValue();
            float va = visionAngle.getValue();
            pushMatrix();

            // Champs de vision
            stroke(255);
            strokeWeight(1);
            translate(this.p.x,this.p.y);
            rotate(theta);
            fill(255,100);
            arc(0, 0, 2*vr, 2*vr,-va, va);
            line(0, 0, cos(va)*vr,sin(va)*vr);
            line(0, 0, cos(-va)*vr,sin(-va)*vr);

            // Champs d'evittement d'obstacle
            stroke(#f9bd35);
            strokeWeight(1);
            fill(#FFF68F,100);
            rect(0, -OBSTACLE_MARGIN, vr, 2*OBSTACLE_MARGIN);

            // Points de test pour l'evittement d'obstacle
            stroke(255);
            fill(255);
            ellipse(vr, OBSTACLE_MARGIN, 3, 3);
            ellipse(vr, -OBSTACLE_MARGIN, 3, 3);
            ellipse(vr/2, OBSTACLE_MARGIN, 3, 3);
            ellipse(vr/2, -OBSTACLE_MARGIN, 3, 3);

            popMatrix();
        }
    }

    // Methode qui dessine l'espace vital de l'agent
    void drawVitalSpace(){
        if(OPTION_SELECT.bolValue && this.isSelected
                && OPTION_SVITAL.bolValue){
            stroke(#EF1C17);
            strokeWeight(2);
            noFill();
            arc(this.p.x, this.p.y,
                2*vitalRadius.getValue(), 2*vitalRadius.getValue(), 0, TWO_PI);
        }
    }

    // Methode qui dessine les vecteurs de l'agent
    void drawVectors(){
        if(OPTION_SELECT.bolValue && this.isSelected
                && OPTION_SVECTOR.bolValue){
            // Dessiner vecteur vitesse
            drawVector(this.v, this.p.x, this.p.y, 12*vMax.getValue(), #abcdef, 255);

            // Dessiner vecteur acceleration
            if(this.a.mag() > 0)
                drawVector(this.a, this.p.x, this.p.y, 10000*fMax.getValue(), #ffffcc, 255);
        }
    }

    /* =============================================================== */    


    /* =============== Methodes auxiliaires generales ================ */

    // Methode qui prend le vecteur distance le plus petit
    // entre deux positions p1 - p2
    // (espace toroidal)
	PVector smallestDistVect(PVector p1, PVector p2){
		PVector d = new PVector(0,0);
		float aux;

		aux = p1.x - p2.x;
		d.x = (abs(aux) > width/2) ? sign(aux)*(abs(aux) - width) : aux;
		aux = p1.y - p2.y;
		d.y = (abs(aux) > height/2) ? sign(aux)*(abs(aux) - height) : aux;

		return d;
	}

    // Methode qui limite la position de l'agent pour qu'il ne
    // puisse pas entrer dans des obstacles
    // S'il entre en collision, on remet sa vitesse a 0
    void obstacleConstraint(){
        PVector newPos = p.copy();
        newPos.add(v);

        for(Obstacle o : obstacles){
            if(isPointInCircle(newPos,o)){
                this.v = new PVector(0,0);
                this.a = new PVector(0,0);
                return;
            }
        }
    }

    // Fonction signe
    int sign(float x){
		if(x >= 0) return 1;
		return -1;
	}

    // Fonction pour convertir une liste de predateurs dans une liste d'agents
    ArrayList<Agent> agentListFromPredatorList(ArrayList<Predator> pList){
        Agent a;
        ArrayList<Agent> aList = new ArrayList();

        for(Predator p : pList){
            a = (Agent) p;
            aList.add(a);
        }

        return aList;
    }
}

// Classe auxiliaire pour savoir quel type d'agent on manipule
public enum AgentType{
  BOID, PREDATOR
};