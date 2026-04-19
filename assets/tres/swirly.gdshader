shader_type canvas_item;

uniform vec2 center = vec2(0.5);
uniform float swirl_strength : hint_range(-2.0, 2.0, 0.1) = 1.2;
/** duration in multiples of PI seconds */
uniform float duration = 1.0; 
/** the amount of degrees it rotates in the duration 
  * any non 360 divisible amount of rotation will not produce a continuous loop
*/
uniform float rotation_degrees : hint_range(-2880.0, 2880.0, 360.0) = -1440.0; 

vec2 rotate_vec2(vec2 vec, float angle_degrees) {
	
	return vec2(
		vec.x * cos(radians(-angle_degrees)) - vec.y * sin(radians(-angle_degrees)),
		vec.y * cos(radians(-angle_degrees)) + vec.x * sin(radians(-angle_degrees))
	);
}

void fragment() {
	vec2 coords = UV - center;
	float dist = length(coords);
	
	// make a sine wave
	float modificator = sin(mod(TIME, PI * duration) / duration - PI / 2.0) / 2.0 + 0.5;
	//change the sine wave's steepness depending on the distance from the center
	modificator = pow(modificator, 2.0 - dist * swirl_strength);
	
	coords = rotate_vec2(coords, rotation_degrees * modificator);
	
	coords += center;
	
	COLOR = texture(TEXTURE, coords);
}
