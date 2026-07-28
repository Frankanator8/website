shader_type canvas_item;

// Fades out only the pixels close to the player, so the player never hides
// behind the overhead layer but the rest of it stays solid.

uniform vec2 player_position;
// Closer than this to the player -> fully faded.
uniform float near_distance = 16.0;
// Farther than this -> fully solid.
uniform float far_distance = 32.0;
uniform float min_alpha : hint_range(0.0, 1.0) = 0.3;

varying vec2 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	float t = smoothstep(near_distance, far_distance, distance(world_position, player_position));
	COLOR.a *= mix(min_alpha, 1.0, t);
}
