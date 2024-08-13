#pragma language glsl3

in vec3 f_normal;

const vec3 light_dir=normalize(vec3(0.6,1.0,0.8));

#ifdef PIXEL
vec4 effect(vec4 color,Image texture,vec2 texture_uv,vec2 screen_uv) {
	float shading=max(0.2,smoothstep(
		0.4,1.0,
		(dot(f_normal,light_dir)+1.0)/2.0
	));
	return color*vec4(shading,shading,shading,1.0);
}
#endif