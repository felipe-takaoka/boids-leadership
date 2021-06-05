class Option{
	boolean bolValue;
	char    oKey;

	Option(boolean b){
    	this.bolValue = b;
  	}

  	Option(boolean b, char k){
  		this(b);
  		this.oKey = k;
  	}
}