class MapGrid{
	private PVector[][] flowFieldVectors;
	private ArrayList<Agent>  mapGridAgents;
	private int   scl;        // Variables pour le champs d'ecoulement
	private float inc  = 0.1; // Increments pour le bruit de Perlin
	private float toff = 0;
	private int   rows;
	private int   cols;

	MapGrid(int scl){
		this.scl = scl;
		this.rows = floor(height/scl);
		this.cols = floor(width/scl);
		this.flowFieldVectors = new PVector[rows][cols];
		this.mapGridAgents    = new ArrayList();
	}

	PVector getVector(int row, int col){
		return flowFieldVectors[row][col];
	}

	PVector getVector(float x, float y){
		int row = max(min(floor(y/scl), rows-1), 0);
		int col = max(min(floor(x/scl), cols-1), 0);

		return getVector(row,col);
	}

	void update(){
		if(OPTION_FLOWFIELD.bolValue){
			int     index;
			float   theta, xoff, yoff = 0;

			for(int i = 0; i < rows; i++){
				xoff = 0;
				for(int j = 0; j < cols; j++){
					index = (j+i*width)*4;
					xoff += inc;

					theta = noise(xoff, yoff, toff)*2*PI;
					this.flowFieldVectors[i][j] = PVector.fromAngle(theta);
				}
				yoff += inc;
			}

			toff += inc/15;
		}
	}

	void display(){
		if(OPTION_SEEFLWFLD.bolValue && OPTION_FLOWFIELD.bolValue)
			displayFlowField();
	}

	// Methode qui dessine le champs de vecteur
	void displayFlowField(){
		for(int i = 0; i < rows; i++){
			for(int j = 0; j < cols; j++){
				drawVector(this.flowFieldVectors[i][j],
					scl/2+j*scl, scl/2+i*scl, map(constFlField.getValue(),0,1,0,scl/1.5), 255, 120);
			}
		}
	}
}