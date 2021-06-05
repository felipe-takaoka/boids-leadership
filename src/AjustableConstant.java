import java.lang.Math;

public class AjustableConstant{
	public String name;
	private float constant;
	public final float max;
	public final float min;
	
	AjustableConstant(String name, float initValue, float min, float max){
		this.name = name;
		this.constant = initValue;
		this.min = min;
		this.max = max;
	}

	void setValue(float value){
		this.constant = Math.min(Math.max(value, min), max);
	}

	float getValue(){
		return this.constant;
	}

}