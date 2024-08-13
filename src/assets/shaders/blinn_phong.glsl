#pragma language glsl3

in vec3 f_normal;
in vec3 f_position;

const vec3 light_position   = vec3(0.0,5.0,0.0);
const vec3 light_color      = vec3(1.0,1.0,1.0);
const float light_intensity = 40.0;
const vec3 ambient_color    = vec3(0.1,0.1,0.1);
const vec3 diffuse_color    = vec3(0.5,0.5,0.5);
const vec3 specular_color   = vec3(1.0,1.0,1.0);
const float shininess       = 20.0;
const float screen_gamma    = 2.2;

#ifdef PIXEL
vec4 effect(vec4 color,Image texture,vec2 texture_uv,vec2 screen_uv) {
	vec3 light_dir = light_position-f_position;
	
	float distance = length(light_dir);
	distance = distance*distance;
	light_dir = normalize(light_dir);
	
	float lambertian = max(dot(light_dir,f_normal),0.0);
	float specular   = 0.0;
	
	if (lambertian>0.0) {
		vec3 view_dir = normalize(-f_position);
		
		vec3 half_dir = normalize(light_dir+view_dir);
		
		float specular_angle = max(dot(half_dir,f_normal),0.0);
		specular = pow(specular_angle,shininess);
	}
	
	vec3 color_linear = ambient_color+diffuse_color*lambertian*light_color*light_intensity/distance+specular_color*specular*light_color*light_intensity/distance;
	vec3 color_gamma_corrected = pow(color_linear,vec3(1.0/screen_gamma));
	
	return vec4(color_gamma_corrected,1.0);
}
#endif