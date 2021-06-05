class Button extends PanelComponent{
  static final int BUTTON_HEIGHT = 15;
  final int   BUTTON_WIDTH;
  // Couleur du bouton quand la souris n'est pas sur le bouton et
  // aussi il n'est pas active
  final color BASECOLOR      = #26393d;
  final color HIGHLIGHTCOLOR = #FFAE1A;
  String printMessage;
  String printOn;
  String printOff;
  Option optionVar; // Variable controlee par le bouton
  // Liste des boutons qui ne peuvent pas avoir sa variable
  // controlee active au meme temps (ex.: placer boids et placer obstacles)
  ArrayList<Button> excludingGroup;
  color currentColor = #26393d; // Couleur courant du bouton

  	// Constructeur sans mensage a etre imprimeee
	Button(Panel p, PVector pos, String name, Option bov){
		super(p, pos.x, pos.y, name);
    	this.BUTTON_WIDTH = p.PANEL_WIDTH - 2*p.PANEL_XMARGIN;
		this.excludingGroup = null;
		this.currentColor = BASECOLOR;
		this.optionVar = bov;
		this.printMessage = "";
		this.printOn      = "";
		this.printOff     = "";
	}

	// Constructeur avec message unique a etre imprimee quand le bouton change d'etat
	Button(Panel p, PVector pos, String name, Option bov, String printMessage){
		this(p,pos,name,bov);
		this.printMessage = printMessage;
	}

	// Constructeur avec message conditionnele selon l'etat de la variable controlee
	Button(Panel p, PVector pos, String name, Option bov, String printOn, String printOff){
		this(p,pos,name,bov);
		this.printOn = printOn;
		this.printOff = printOff;
	}

	int getHeight(){
		return BUTTON_HEIGHT;
	}

	// Methode pour l'affichage du bouton
	void display(){
		stroke(0);
		strokeWeight(1);
		fill(currentColor, 180);
		rect(this.x, this.y, BUTTON_WIDTH, BUTTON_HEIGHT);
		textSize(10);
		fill(255);
		textAlign(CENTER, CENTER);
		text(this.name, this.x + BUTTON_WIDTH/2, this.y + BUTTON_HEIGHT/2);
	}

	// Methode de mise a jour des attributs du bouton
	void update(){
		if(isMouseOver()){
			this.mouseOver = true;
			this.currentColor = HIGHLIGHTCOLOR;
		}
		else{
			this.mouseOver = false;
			if(this.optionVar.bolValue)
				this.currentColor = HIGHLIGHTCOLOR;
			else
				this.currentColor = BASECOLOR;
		}
	}

	// Methode qui dit si la souris est sur le bouton
	boolean isMouseOver(){
		if (mouseX >= this.x && mouseX <= this.x+BUTTON_WIDTH && 
			mouseY >= this.y && mouseY <= this.y+BUTTON_HEIGHT) {
			return true;
		}
		return false;
	}

	// Methode appele quand le bouton est clicke
	// Renvoi une message a etre imprimee
	String actionClicked(){
		if(this.excludingGroup != null){
			for(Button b : this.excludingGroup)
				b.optionVar.bolValue = false;
		}
		this.optionVar.bolValue = !this.optionVar.bolValue;

		if(!printOn.equals("") && !printOff.equals(""))
			return (this.optionVar.bolValue) ? printOn : printOff;

		return printMessage;
	}
}