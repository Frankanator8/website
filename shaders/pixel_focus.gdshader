shader_type canvas_item;

// Chunks a photo into big blocks when the player is far away, then resolves it
// into the raw image as they walk up. Block size is measured in world pixels
// (the game's own pixel grid), so sprites at different scales chunk the same.

uniform vec2 player_position;
// Closer than this to the sprite -> no pixelation at all.
uniform float near_distance = 32.0;
// Farther than this -> full chunk.
uniform float far_distance = 140.0;
// Block size in world pixels when fully chunked.
uniform float max_block = 4.0;
// 0 = one hard sample per block, 1 = averaged block colour.
uniform float softness : hint_range(0.0, 1.0) = 1.0;

// UV size of one world pixel on this sprite.
varying vec2 texel_per_world;
// 0 = far and chunky, 1 = close and sharp.
varying float focus;

void vertex() {
	vec2 world_scale = vec2(length(MODEL_MATRIX[0].xy), length(MODEL_MATRIX[1].xy));
	texel_per_world = TEXTURE_PIXEL_SIZE / max(world_scale, vec2(0.0001));

	// Distance from the sprite's origin, not the fragment, so the whole image
	// focuses as one instead of blurring across a gradient.
	vec2 origin = MODEL_MATRIX[3].xy;
	focus = 1.0 - smoothstep(near_distance, far_distance, distance(origin, player_position));
}

void fragment() {
	float block_px = mix(max_block, 0.0, focus);
	vec4 sharp = texture(TEXTURE, UV);

	if (block_px < 0.01) {
		COLOR = sharp;
	} else {
		vec2 block = block_px * texel_per_world;
		vec2 snapped = (floor(UV / block) + 0.5) * block;

		// Box average of the block, so a chunk shows its region's colour
		// instead of whichever photo texel happened to land dead centre.
		vec2 quarter = block * 0.25;
		vec4 avg = texture(TEXTURE, snapped + vec2(-quarter.x, -quarter.y));
		avg += texture(TEXTURE, snapped + vec2(quarter.x, -quarter.y));
		avg += texture(TEXTURE, snapped + vec2(-quarter.x, quarter.y));
		avg += texture(TEXTURE, snapped + vec2(quarter.x, quarter.y));
		avg *= 0.25;

		vec4 chunky = mix(texture(TEXTURE, snapped), avg, softness);
		// Cross-fade the last bit of chunk into the sharp image so the switch
		// to unpixelated has no pop.
		COLOR = mix(sharp, chunky, smoothstep(0.0, 1.0, block_px));
	}
}
