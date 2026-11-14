shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D forest_ground : source_color, repeat_enable, filter_linear_mipmap;
varying float elevation;

void vertex() {
	elevation = VERTEX.y;
}

void fragment() {
	vec3 sand = COLOR.rgb;
	vec3 grass = texture(forest_ground, UV).rgb * vec3(0.9, 0.96, 0.88);
	float inland = smoothstep(1.0, 2.3, elevation);
	ALBEDO = mix(sand, grass, inland);
	ROUGHNESS = 1.0;
}
