#pragma language glsl3

uniform highp mat4 projection;
uniform highp mat4 view;
uniform highp mat4 model;

out vec3 f_normal;
//out vec3 f_position;

#ifdef VERTEX
attribute vec3 VertexNormal;

vec4 position(highp mat4 transform_projection,vec4 VertexPosition) {
	f_normal=normalize((model*vec4(VertexNormal,0.0)).xyz);
	//f_position=(model*VertexPosition).xyz;
	
	return projection*view*model*VertexPosition;
}
#endif