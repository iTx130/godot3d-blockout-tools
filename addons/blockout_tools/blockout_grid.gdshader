shader_type spatial;
render_mode diffuse_burley, cull_back;

uniform vec4 base_color : source_color = vec4(0.619607843, 0.619607843, 0.619607843, 1.0);
uniform vec4 top_color : source_color = vec4(0.25, 0.25, 0.25, 1.0);
uniform bool use_grid = true;
uniform bool world_aligned = false;
uniform bool use_top_color = true;
uniform float grid_size = 0.5;
uniform int grid_subdivisions : hint_range(1, 100, 1) = 5;
uniform float checker_luminance : hint_range(0.0, 1.0) = 0.3;
uniform float roughness : hint_range(0.0, 1.0) = 0.3;
varying vec3 local_position;
varying vec3 local_normal;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	vec3 scale = max(vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz)), vec3(0.0001));
	local_position = VERTEX * scale;
	local_normal = normalize(NORMAL / scale);
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

// Antialias each grid level independently; subpixel lines fade at a distance.
float grid_lines(vec2 cell, float half_width) {
	vec2 pixel = max(fwidth(cell), vec2(0.0001));
	vec2 distance_to_line = abs(fract(cell + 0.5) - 0.5);
	vec2 coverage = 1.0 - smoothstep(vec2(half_width) - pixel * 0.5, vec2(half_width) + pixel * 0.5, distance_to_line);
	coverage *= min(vec2(1.0), vec2(2.0 * half_width) / pixel);
	vec2 resolved = 1.0 - smoothstep(vec2(0.2), vec2(0.8), pixel);
	return max(coverage.x * resolved.x, coverage.y * resolved.y);
}

// Grid Size measures major spacing; subdivisions control the minor spacing.
vec3 grid_pattern(vec2 position) {
	vec2 cell = position / max(grid_size, 0.0001);
	float major = grid_lines(cell, 0.012);
	float minor = grid_lines(cell * float(clamp(grid_subdivisions, 1, 100)), 0.015);
	vec2 pixel = max(fwidth(cell), vec2(0.0001));
	float resolved = 1.0 - smoothstep(0.2, 0.8, max(pixel.x, pixel.y));
	float checker = mod(floor(cell.x) + floor(cell.y), 2.0);
	return vec3(major, minor, mix(0.5, checker, resolved));
}

void fragment() {
	vec3 normal_world = normalize(world_normal);
	float top = use_top_color ? abs(normal_world.y) : 0.0;
	vec3 color = mix(base_color.rgb, top_color.rgb, top);
	if (use_grid) {
		vec3 position = world_aligned ? world_position : local_position;
		vec3 normal = normalize(world_aligned ? world_normal : local_normal);
		vec3 weights = pow(abs(normal), vec3(4.0));
		weights /= max(weights.x + weights.y + weights.z, 0.0001);
		vec3 pattern = grid_pattern(position.yz) * weights.x + grid_pattern(position.xz) * weights.y + grid_pattern(position.xy) * weights.z;
		color *= 1.0 - pattern.z * checker_luminance;
		color = mix(color, vec3(0.8), pattern.y * 0.55);
		color = mix(color, vec3(0.8), pattern.x);
	}
	ALBEDO = color;
	ROUGHNESS = roughness;
}
