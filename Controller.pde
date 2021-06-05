class Controller{
	static final int squareSize = 50;     // Carre pour effacer
	static final int INIT_MSG_TIMER = 50; // Temps d'affichage des messages
	Panel buttonsPanel;					  // Panneau avec les boutons de controle
	Panel slidersPanel;					  // Panneau avec les sliders de reglage
	String messageText = "";			  // Message en train d'etre imprimee
	int messageTimer = 0;				  // Timer pour l'affichage de la message
	float xzoom = width/2;
	float yzoom = height/2;
	float zoomScale = 2.3;

	// Constructeur du controlleur
	Controller(){
		// Initilisation de la grille comme une maille carre de taille 45
		mapGrid = new MapGrid(45);

		buttonsPanel = new Panel(5,5,145,5);
		buttonsPanel.addButton(buttonsPanel,"(R) Minimiser panneau",OPTION_CLOSED_B);
		slidersPanel = new Panel(width-5-200,5,200,5);
		slidersPanel.addButton(slidersPanel,"(T) Minimiser panneau",OPTION_CLOSED_S);

			// Ajout des boutons
		Button boidButton, predateurButton, obstacleButton;
		Button seekButton, eraseButton,     selectButton;

		buttonsPanel.addButton(buttonsPanel, "(ESPACE) Pauser/Repr.", OPTION_PAUSE, "Simulation en pause", "Simulation reprise");
		buttonsPanel.addButton(buttonsPanel, "Steering force", OPTION_STEER);

		boidButton = 
			buttonsPanel.addButton(buttonsPanel, "(B) Placer boid", OPTION_BOID, "Placez des boids");
  		predateurButton =
  			buttonsPanel.addButton(buttonsPanel, "(P) Placer predateur", OPTION_PRED, "Placez des predateurs");
		obstacleButton =
			buttonsPanel.addButton(buttonsPanel, "(O) Placer obstacle", OPTION_OBST, "Placez des obstacles");
		seekButton = 
  			buttonsPanel.addButton(buttonsPanel, "(M) Suivre la souris", OPTION_SEEK, "Les boids veulent la souris!");
  		eraseButton =
  			buttonsPanel.addButton(buttonsPanel, "(E) Effacer et fuir", OPTION_ERASE, "Essayez d'effacer les agents!");
		selectButton =
  			buttonsPanel.addButton(buttonsPanel, "(S) Selectionner agent", OPTION_SELECT, "Selectionnez des agent");

  				// Ajout de la liste de boutons qui ne peuvent pas etre actives au meme temps
  		ArrayList<Button> excludingButtons = new ArrayList();
  		excludingButtons.add(boidButton);
  		excludingButtons.add(predateurButton);
  		excludingButtons.add(obstacleButton);
  		excludingButtons.add(seekButton);
  		excludingButtons.add(eraseButton);
  		excludingButtons.add(selectButton);
  		buttonsPanel.addExcludingButtons(excludingButtons);

  		buttonsPanel.addButton(buttonsPanel,"(V) Afficher Vecteur",OPTION_SVECTOR, "Affichage des vecteurs active", "Affichage des vecteurs desactivee");
  		buttonsPanel.addButton(buttonsPanel,"(C) Champ de vision",OPTION_SVISION, "Affichage du champ de vision active", "Affichage du champ de vision desactivee");
  		buttonsPanel.addButton(buttonsPanel,"(X) Espace vital",OPTION_SVITAL, "Affichage de l'espace vital active", "Affichage de l'espace vital desactivee");
  		buttonsPanel.addButton(buttonsPanel,"(L) Surligner leader",OPTION_SEELEADER, "Visualisation du leader active", "Visualisation du leader desactivee");
  		buttonsPanel.addButton(buttonsPanel,"(F) Champ d'ecoulement",OPTION_FLOWFIELD, "Champ d'ecoulement active", "Champ d'ecoulement desactive");
  		buttonsPanel.addButton(buttonsPanel,"(D) Visualiser champs",OPTION_SEEFLWFLD, "Visualisation du champs activee", "Visualisation du champs desactivee");
  		buttonsPanel.addButton(buttonsPanel,"(Z) Zoom",OPTION_ZOOMPAUSED,"(Z) ou (ESPACE) pour sortir"," ");
  			// Fin d'ajout des boutons

  			// Ajout des scroll bars
  		slidersPanel.addSlider(slidersPanel,vMax);
  		slidersPanel.addSlider(slidersPanel,fMax);
  		slidersPanel.addSlider(slidersPanel,vitalRadius);
  		slidersPanel.addSlider(slidersPanel,visionRadius);
  		slidersPanel.addSlider(slidersPanel,visionAngle);
  		slidersPanel.addSlider(slidersPanel,constCohes);
  		slidersPanel.addSlider(slidersPanel,constSepar);
  		slidersPanel.addSlider(slidersPanel,constAlign);
  		slidersPanel.addSlider(slidersPanel,chanceLeader);
  		slidersPanel.addSlider(slidersPanel,constFlField);
  			// Fin d'ajout des scroll bars
	}

	// Methode de mise a jour du controlleur ("principale" de l'application)
	void update(){
		buttonsPanel.update();
		slidersPanel.update();

		if(!OPTION_PAUSE.bolValue){
			mapGrid.update();
			for(Agent a : agents)
				a.update();
		}
		for(Agent a : agentsToRemove){
			agents.remove(a);
		}
		// On cree une liste de agents a effacer pour eviter les modifications
		// dans la liste d'agents son parcous
		agentsToRemove = new ArrayList();

		this.display();
	}

	// Methode pour l'affichage de tous les elements controles par le controleur
	void display(){
		if(OPTION_PAUSE.bolValue && OPTION_ZOOMPAUSED.bolValue){
			Button openCloseButtons = (Button) buttonsPanel.components.get(0);
			Button openCloseSliders = (Button) slidersPanel.components.get(0);

			openCloseButtons.optionVar.bolValue = true;
			openCloseSliders.optionVar.bolValue = true;

			translate(-xzoom, -yzoom);
			scale(zoomScale);
		}

		mapGrid.display();

		for(Obstacle o : obstacles)
			o.display();

		for(Agent a : agents)
			a.display();

		if(OPTION_ERASE.bolValue){
			fill(#0e0736);
			stroke(0);
			strokeWeight(3);
			ellipse(mouseX, mouseY, 20, 20);
			rect(mouseX-squareSize/2, mouseY-squareSize/2, squareSize, squareSize);
		}

		buttonsPanel.display();
		slidersPanel.display();

		fill(255);
		textSize(10);
		String stat1 = String.format("Nombre d'agents: %d", agents.size());
		String stat2 = String.format("FPS: %.1f", frameRate);
		text(stat1, width-58, height-48);
		text(stat2, width-33, height-36);

		textSize(14);
		text("Developpe par Felipe Heiji Takaoka - 2A",
			width - 150, height - 22);

		if(messageTimer > 0) messageTimer--;
		drawMessageText();
	}

	// Permet d'ecrire une message guidant l'utilisateur pour le bouton selecionne
	void drawMessageText(){
		if(messageTimer > 0) {
			fill(255, (min(30,messageTimer)/30.0)*255.0);
			textAlign(CENTER, CENTER);
			textSize(30);
			text(messageText, width/2, height/2); 
		}
	}

	void setMessage(String in){
		messageText  = in;
		messageTimer = INIT_MSG_TIMER;
	}

	// Methode appele quand la souris a ete appuyee
	void mousePressedC(){
		if(!OPTION_ZOOMPAUSED.bolValue){
			String printMessage;
			Button openCloseButtons = (Button) buttonsPanel.components.get(0);
			Button openCloseSliders = (Button) slidersPanel.components.get(0);

			// La souris est sur le panneau et celui-ci est ouvert
			boolean overButtons = buttonsPanel.isMouseOverPanel() && !OPTION_CLOSED_B.bolValue;
			boolean overSliders = slidersPanel.isMouseOverPanel() && !OPTION_CLOSED_S.bolValue;

			if(overButtons || openCloseButtons.isMouseOver()){
				printMessage = buttonsPanel.clicked();
				setMessage(printMessage);
			}
			else if(overSliders || openCloseSliders.isMouseOver()){
				slidersPanel.clicked();
			}
			else{
				if(OPTION_BOID.bolValue)
					agents.add(new Boid(new PVector(mouseX,mouseY)));
				if(OPTION_PRED.bolValue)
					agents.add(new Predator(new PVector(mouseX,mouseY)));
				if(OPTION_OBST.bolValue)
					obstacles.add(new Obstacle(new PVector(mouseX,mouseY)));
				if(OPTION_ERASE.bolValue)
					clearInSquare();
				if(OPTION_SELECT.bolValue)
					selectAgent();
			}
		}
	}

	// Methode appele quand la souris a ete trainee
	void mouseDraggedC(){
		if(!OPTION_ZOOMPAUSED.bolValue){
			// La souris est sur le panneau et celui-ci est ouvert
			boolean overButtons = buttonsPanel.isMouseOverPanel() && !OPTION_CLOSED_B.bolValue;
			boolean overSliders = slidersPanel.isMouseOverPanel() && !OPTION_CLOSED_S.bolValue;

			if(!overButtons && !overSliders){
				if(OPTION_BOID.bolValue)
					agents.add(new Boid(new PVector(mouseX,mouseY)));
				if(OPTION_PRED.bolValue)
					agents.add(new Predator(new PVector(mouseX,mouseY)));
				if(OPTION_ERASE.bolValue)
					clearInSquare();
			}
		}
		else{
			xzoom = xzoom - (mouseX - pmouseX);
  			yzoom = yzoom - (mouseY - pmouseY);
  		}
	}

	// Methode appele quand le clavier a ete appuye
	void keyPressedC(){
		String printMessage;
		Button b;

		for(PanelComponent c : buttonsPanel.components){
			b = (Button) c;
			if(key == b.optionVar.oKey){
				printMessage = b.actionClicked();
				setMessage(printMessage);
				if(!OPTION_PAUSE.bolValue)
					OPTION_ZOOMPAUSED.bolValue = false;
				else if(OPTION_ZOOMPAUSED.bolValue && key == 'z'){
					xzoom = mouseX;
					yzoom = mouseY;
				}
			}
		}

		b = (Button) slidersPanel.components.get(0);
		if(key == b.optionVar.oKey){
			printMessage = b.actionClicked();
			setMessage(printMessage);
		}
	}

	// Methode qui efface tous les composants ajoutes par l'utilisateur
	// dans un carre centre dans la position de la souris
	void clearInSquare(){
		// Creation des listes pour eviter l'exception genere
		// par modification de la liste pendant qu'on la parcours
		ArrayList<Agent> aToRemove = new ArrayList();
		ArrayList<Obstacle> oToRemove = new ArrayList();

		for(Agent a : agents){
			if(isUnderSquare(a.p)){
				aToRemove.add(a);
			}
		}
		for(Obstacle o : obstacles){
			if(isUnderSquare(o.p)){
				oToRemove.add(o);
			}
		}
		for(Agent a : aToRemove){
			agents.remove(a);
		}
		for(Obstacle o : oToRemove){
			obstacles.remove(o);
		}

		aToRemove = null;
		oToRemove = null;
	}

	// Methode utilise pour effacer les agents
	// Elle dit si un point de position pos est sur le carre d'effaçage
	boolean isUnderSquare(PVector pos){
		if ((mouseX >= pos.x-squareSize/2) && (mouseX <= pos.x+squareSize/2) 
			&& (mouseY >= pos.y-squareSize/2) && (mouseY <= pos.y+squareSize/2)) {
			return true;
		}
		return false;
	}

	// Methode pour selectionner un agent
	void selectAgent(){
		for(Agent a : agents){
			if(a.isMouseOverAgent()){
				a.isSelected = !a.isSelected;
				return;
			}
		}
	}
}