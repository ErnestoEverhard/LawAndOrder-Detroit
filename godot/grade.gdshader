shader_type canvas_item;
// Film look over the 3D view: muted colour, crushed shadows, cool shadows / warm highlights, grain, vignette.
uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float grain = 0.0;   // animated film grain; off because it reads as the walls crawling
uniform float desaturate = 0.45;
uniform float vignette = 0.4;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(c, vec3(l), desaturate);
	c = mix(c, c * vec3(0.90, 0.98, 1.08), 1.0 - smoothstep(0.0, 0.5, l));   // cool shadows
	c = mix(c, c * vec3(1.06, 1.0, 0.90), smoothstep(0.4, 1.0, l));          // warm highlights
	c = (c - 0.5) * 1.12 + 0.5 + 0.01;                                        // contrast, lower blacks
	vec2 d = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * dot(d, d) * 1.6;
	float t = floor(TIME * 24.0);
	c += (hash(SCREEN_UV * vec2(1920.0, 1080.0) + t) - 0.5) * grain;
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
