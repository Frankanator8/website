shader_type canvas_item;

// Concentric ripple rings spreading out from the centre of the sprite.
// The sprite's own texture is the water mask - rings only draw where it is
// opaque, so a plain circle spreads into open water and a pool-shaped mask
// keeps the rings off the surrounding tiles.

uniform vec4 ring_color : source_color = vec4(0.663, 0.835, 1.0, 1.0);
// How many rings are alive at once.
uniform int rings : hint_range(1, 6) = 3;
// Ripples born per second.
uniform float speed : hint_range(0.05, 3.0) = 0.5;
// Ring width, in texels.
uniform float thickness : hint_range(0.5, 6.0) = 1.0;
// Radius a ring is born at, as a fraction of the half width.
uniform float inner : hint_range(0.0, 0.9) = 0.2;
// Below 1.0 squashes the rings into ellipses, for a more angled camera.
uniform float squash : hint_range(0.2, 1.0) = 1.0;
// Fade is quantised to this many steps so the rings stay pixel-art chunky.
uniform int alpha_steps : hint_range(1, 8) = 3;

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	// Snap to the texel centre so rings are crisp instead of smeared.
	vec2 p = floor(UV * size) + 0.5 - size * 0.5;
	p.y /= squash;
	float d = length(p) / (size.x * 0.5);
	float half_width = thickness / size.x;

	float a = 0.0;
	for (int i = 0; i < 6; i++) {
		if (i >= rings) {
			break;
		}
		// 0.0 the moment the ring is born, 1.0 as it dies at the edge.
		float age = fract(TIME * speed + float(i) / float(rings));
		float radius = mix(inner, 1.0, age);
		float on_ring = 1.0 - step(half_width, abs(d - radius));
		a = max(a, on_ring * sin(age * PI));
	}
	a = floor(a * float(alpha_steps)) / float(alpha_steps);

	COLOR = vec4(ring_color.rgb, ring_color.a * a * texture(TEXTURE, UV).a);
}
