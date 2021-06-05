/*
Auteur: Felipe Heiji Takaoka
Annee:   2A - Promo 2018
Date:        03/2016
*/

// Quelques unes des ces variables et des ces methodes devraient etre dans 
// des classes plus apropries, mais elles se trouvent ici, pour etre plus
// pratique, parce qu'ils sont vues par toutes les classes
Controller controller; // Controle tout l'envorinnement
MapGrid    mapGrid;    // Grille pour implementer le champs d'ecoulement
ArrayList<Agent> agents         = new ArrayList(); // Liste de tous les agents (boids, predateurs)
ArrayList<Agent> agentsToRemove = new ArrayList(); // Liste des boids manges par les predateurs
ArrayList<Obstacle> obstacles   = new ArrayList(); // Liste des obstacles

Option OPTION_CLOSED_B = new Option(false,'r');  // Option pour minimiser/maximiser la fenetre respective aux bouttons
Option OPTION_CLOSED_S = new Option(false,'t');  // Option pour minimiser/maximiser la fenetre respective aux sliders

Option OPTION_PAUSE = new Option(false,' ');      // Option pour pauser et reprendre la simulation
Option OPTION_SELECT  = new Option(false,'s');    // Option pour selectioner un agent pour ensuite pouvoir afficher d'autres choses
Option OPTION_SVECTOR = new Option(false,'v');    // Option pour afficher les vecteurs de l'agent selectionne
Option OPTION_SVISION = new Option(false,'c');    // Option pour afficher le champ de vision et d'evitement d'obstacle de l'agent selectionne
Option OPTION_SVITAL  = new Option(false,'x');    // Option pour afficher l'espace vital de l'agent selectionne
Option OPTION_STEER = new Option(true);           // Option pour activer les forces comme stearing forces (= desiree - vitesse)
Option OPTION_SEEK = new Option(false,'m');       // Option pour que les boids suivent la souris
Option OPTION_BOID = new Option(true,'b');        // Option pour placer des boids
Option OPTION_PRED = new Option(false,'p');       // Option pour placer des predateurs
Option OPTION_OBST = new Option(false,'o');       // Option pour placer des obstacles
Option OPTION_ERASE = new Option(false,'e');      // Option pour effacer les elements places
Option OPTION_SEELEADER = new Option(true,'l');   // Option pour le boid qui devient leader changer de couleur
Option OPTION_FLOWFIELD = new Option(false,'f');  // Option pour activer les forces du champ d'ecoulement
Option OPTION_SEEFLWFLD = new Option(false,'d');  // Option pour afficher le champs d'ecoulement
Option OPTION_ZOOMPAUSED = new Option(false,'z'); // Option pour zoomer sur un boid selectionne

AjustableConstant vMax = new AjustableConstant("Vitesse maximale",1.9,0,3.8);
AjustableConstant fMax = new AjustableConstant("Force maximale",0.05,0,0.1);

AjustableConstant vitalRadius  = new AjustableConstant("Espace vital",16,0,32);
AjustableConstant visionRadius = new AjustableConstant("Portee vision",85,0,170);
AjustableConstant visionAngle  = new AjustableConstant("Angle de vision",2*PI/3,0,PI);
                  // en rad

AjustableConstant constCohes   = new AjustableConstant("Cohesion",0.5,0,1);
AjustableConstant constSepar   = new AjustableConstant("Separation",0.5,0,1);
AjustableConstant constAlign   = new AjustableConstant("Alignement",0.5,0,1);
AjustableConstant chanceLeader = new AjustableConstant("Chance devenir leader",0.05,0,0.1);
AjustableConstant constFlField = new AjustableConstant("Force du champ",0.5,0,1);

float constSeek      = 0.07;
float constFlee      = 0.07;
float constAvoid     = 0.75;
float constSeparObst = 0.75;
float constEscape    = 1.00;
float constChase     = 1.00;

void mousePressed() {
  controller.mousePressedC();
}

void mouseDragged() {
  controller.mouseDraggedC();
}

void keyPressed() {
  controller.keyPressedC();
}

void setup(){
	// Option P2D for rendering: OpenGL hardware acceleration
  //size(900,500,P2D);
  size(1180,680);
  controller = new Controller();
  agents.add(new Boid(new PVector(width/2,height/2)));
}

void draw(){
	background(#0e0736);
  controller.update();
}

// Methode permettant de dessiner un vecteur v partant de la position (x,y) multipliee par scayl
// avec une couleur vec_color et transparence alpha
void drawVector(PVector v, float x, float y, float scayl, int vec_color, int alpha){
  if(v != null){
    pushMatrix();
    float arrowsize = 4;
    // Translate to position to render vector
    translate(x,y);
    stroke(vec_color,alpha);
    strokeWeight(1.3);
    // Call vector heading function to get direction (note that pointing to the right is a heading of 0) and rotate
    rotate(v.heading2D());
    // Calculate length of vector & scale it to be bigger or smaller if necessary
    float len = v.mag()*scayl;
    // Draw three lines to make an arrow (draw pointing up since we've rotate to the proper direction)
    line(0,0,len,0);
    line(len,0,len-arrowsize,+arrowsize/2);
    line(len,0,len-arrowsize,-arrowsize/2);
    popMatrix();
  }
}

// Carte toroidale - Methode a appliquer aux vecteurs de positions pour les borner a la fenetre
void borders(PVector p, float size){
  if(p.x < -size) p.x = width+size;
  if(p.y < -size) p.y = height+size;
  if(p.x > width+size) p.x = -size;
  if(p.y > height+size) p.y = -size;
}