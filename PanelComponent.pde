abstract class PanelComponent{
	Panel panelParent;
	boolean mouseOver;
	String name;
	float x;
	float y;

	PanelComponent(Panel p, float x, float y, String name){
		this.panelParent = p;
		this.mouseOver = false;
		this.name = name;
		this.x = x;
		this.y = y;
	}

	abstract int getHeight();

	abstract void display();

	abstract void update();

	abstract boolean isMouseOver();

	// Renvoie une message a imprimer
	abstract String actionClicked();
}