class HScrollbar extends PanelComponent{
  static final int VAR_TEXT_SIZE = 10;
  static final int TEXT_MARGIN = 4;
  static final int SLIDER_HEIGHT = 30;
  final int SLIDER_WIDTH;
  AjustableConstant controlledVar;
  float spos;    // x position of slider
  float sposMin, sposMax; // max and min values of slider
  boolean locked;

  HScrollbar(Panel p, AjustableConstant v, PVector position) {
    super(p, position.x, position.y, v.name);
    SLIDER_WIDTH = p.PANEL_WIDTH - 2*p.PANEL_XMARGIN;
    this.controlledVar = v;
    //this.y = yp-SLIDER_HEIGHT/2;
    //spos    = this.x + SLIDER_WIDTH/2 - SLIDER_HEIGHT/2;
    sposMin = this.x;
    sposMax = this.x + SLIDER_WIDTH - SLIDER_HEIGHT;

    // Position intiale depend de la valeur initiale de la variable controlee
    spos    = getSposFromVariableValue();
  }

  int getHeight(){
    return SLIDER_HEIGHT;
  }

  void update() {
    if (isMouseOver() && !OPTION_CLOSED_S.bolValue) {
      this.mouseOver = true;
    } else {
      this.mouseOver = false;
    }
    if (mousePressed && mouseOver) {
      this.locked = true;
    }
    if (!mousePressed) {
      this.locked = false;
    }
    if(locked){
      spos = constrain(mouseX-SLIDER_HEIGHT/2, sposMin, sposMax);
      this.controlledVar.setValue(this.getVariableValue());
    }
  }

  float constrain(float val, float minv, float maxv) {
    return min(max(val, minv), maxv);
  }

  boolean isMouseOver() {
    int textSpace = VAR_TEXT_SIZE+TEXT_MARGIN;

    if (mouseX > this.x && mouseX < this.x+SLIDER_WIDTH &&
       mouseY > (this.y+textSpace) && mouseY < this.y+SLIDER_HEIGHT) {
      return true;
    }
    return false;
  }

  void display() {
    int textSpace = VAR_TEXT_SIZE+TEXT_MARGIN;

    // Affichage du nom de la variable controlee
    textSize(VAR_TEXT_SIZE);
    fill(0);
    textAlign(CENTER, TOP);
    text(this.controlledVar.name, this.x+SLIDER_WIDTH/2, this.y);

    // Affichage du slider
    noStroke();
    fill(204);
    rect(this.x, this.y+textSpace, SLIDER_WIDTH, SLIDER_HEIGHT-textSpace);
    if (mouseOver || locked) {
      fill(0, 0, 0);
    } else {
      fill(102, 102, 102);
    }
    rect(spos, this.y+textSpace, SLIDER_HEIGHT, SLIDER_HEIGHT-textSpace);
    stroke(255);
    strokeWeight(1);
    line(spos+SLIDER_HEIGHT/2, this.y+textSpace, spos+SLIDER_HEIGHT/2, this.y+SLIDER_HEIGHT-1);
  }

  // Maps the value from spos to the ajustable constant values
  float getVariableValue() {
    float varMin = controlledVar.min;
    float varMax = controlledVar.max;

    return varMin+((varMax-varMin)/(sposMax-sposMin))*(this.spos-sposMin);
  }

  // Inverse de la fonction de la methode anterieure
  float getSposFromVariableValue(){
    float varMin = controlledVar.min;
    float varMax = controlledVar.max;

    return sposMin+((sposMax-sposMin)/(varMax-varMin))*(this.controlledVar.getValue()-varMin);
  }

  String actionClicked(){
    // Il ne faut faire rien ici, la methode update fait tout ce qu'il faut
    return "";
  }
}