class Panel{
	ArrayList<PanelComponent> components;
	final int PANEL_XMARGIN;
	final int PANEL_YMARGIN;
	final int PANEL_WIDTH;
	final int XINIT;
	final int YINIT;

	Panel(int x, int y, int pwidth, int xymargin){
		this.components = new ArrayList();
		this.PANEL_XMARGIN = xymargin;
		this.PANEL_YMARGIN = xymargin;
		this.PANEL_WIDTH = pwidth;
		this.XINIT = x;
		this.YINIT = y;
	}

	// Methode pour ajouter un bouton et le renvoie
	Button addButton(Panel p, String name, Option bov){
		Button newBouton = new Button(p,getNewComponentPosition(),name,bov);

		this.components.add(newBouton);

		return newBouton;
	}

	// Methode pour ajouter un bouton avec impression simple de message et le renvoie
	Button addButton(Panel p, String name, Option bov, String printMessage){
		Button newBouton = new Button(p,getNewComponentPosition(),name,bov,printMessage);

		this.components.add(newBouton);

		return newBouton;
	}

	// Methode pour ajouter un bouton avec impression conditionnelle de message et le renvoie
	Button addButton(Panel p, String name, Option bov, String printOn, String printOff){
		Button newBouton = new Button(p,getNewComponentPosition(),name,bov,printOn,printOff);

		this.components.add(newBouton);

		return newBouton;
	}

	// Methode pour ajouter une liste de boutons qui ne peuvent pas
	// etre actifs simultanement
	void addExcludingButtons(ArrayList<Button> exButtons){
		for(Button b : exButtons){
			b.excludingGroup = exButtons;
		}
	}

	void addSlider(Panel p, AjustableConstant ajConst){
		HScrollbar newSlider = new HScrollbar(p,ajConst,getNewComponentPosition());

		this.components.add(newSlider);
	}

	// Methode pour calculer la position du prochain composant a ajouter
	PVector getNewComponentPosition(){
		int y = YINIT+PANEL_YMARGIN;
		int k = components.size();

		for(PanelComponent c : components){
			y += c.getHeight() + PANEL_YMARGIN;
		}

		return new PVector(XINIT+PANEL_XMARGIN,y);
	}

	void display(){
		// Premier bouton de chaque panneau est reserve
		// au bouton pour minimisation du panneau
		Button minimizePanel = (Button) components.get(0);

		if(minimizePanel.optionVar.bolValue){
			stroke(0);
			strokeWeight(2);
			fill(#696969, 160);
			rect(XINIT, YINIT, PANEL_WIDTH, minimizePanel.getHeight()+2*PANEL_YMARGIN);
			minimizePanel.display();
		}
		else{
			stroke(0);
			strokeWeight(2);
			fill(#696969, 160);
			rect(XINIT, YINIT, PANEL_WIDTH, getPanelHeight());

			for(PanelComponent c : components)
				c.display();
		}
	}

	void update(){
		for(PanelComponent c : components)
			c.update();
	}

	int getPanelHeight(){
		int ch = PANEL_YMARGIN;

		for(PanelComponent c : components){
			ch += + c.getHeight() + PANEL_YMARGIN;
		}

		return ch;
	}

	boolean isMouseOverPanel(){
		if (mouseX >= XINIT && mouseX <= (XINIT+PANEL_WIDTH) && 
			mouseY >= YINIT && mouseY <= (YINIT+getPanelHeight())) {
			return true;
		}
		return false;
	}

	// Renvoie une message a imprimer
	String clicked(){
		for(PanelComponent c : components){
			if(c.isMouseOver())
				return c.actionClicked();
		}

		return "";
	}

}