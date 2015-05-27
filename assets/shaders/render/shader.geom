#version 430

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

in mat4 trans[];
in mat3 normaltrans[];
uniform vec3 camera_position;
out vec3 col;
out vec3 gNormal;
out vec3 gTexcoords;

const float power = 11.0;
const float multiplier = 8.0;
const float threshold = 0.0;
const float threshold_ = -0.85;
const float reverse_period = 0.06;
const float terrain_size_multiplier = 1.0;

float snoise(vec2);
vec3 get_col(float);

void main() {
	// vec3(0.0, 1.0, 0.0)
	vec4 positions[3];
	vec2 position;
	position = gl_in[0].gl_Position.xy*terrain_size_multiplier;
	position += -camera_position.xy*terrain_size_multiplier;
	positions[0] = vec4(position, pow((snoise(position*reverse_period)-threshold_)/(1.0-threshold_), power)*multiplier, 1.0);
	positions[0].z = max(positions[0].z, threshold);

	position = gl_in[1].gl_Position.xy*terrain_size_multiplier;
	position += -camera_position.xy*terrain_size_multiplier;
	positions[1] = vec4(position, pow((snoise(position*reverse_period)-threshold_)/(1.0-threshold_), power)*multiplier, 1.0);
	positions[1].z = max(positions[1].z, threshold);

	position = gl_in[2].gl_Position.xy*terrain_size_multiplier;
	position += -camera_position.xy*terrain_size_multiplier;
	positions[2] = vec4(position, pow((snoise(position*reverse_period)-threshold_)/(1.0-threshold_), power)*multiplier, 1.0);
	positions[2].z = max(positions[2].z, threshold);
	
	gNormal = cross(vec3(positions[0] - positions[1]), vec3(positions[1] - positions[2]));
	gNormal = normalize(transpose(inverse(mat3(trans[0])))*gNormal);
	
	col = get_col(positions[0].z);
	gl_Position = trans[0]*positions[0];
	EmitVertex();
	
	col = get_col(positions[1].z);
	gl_Position = trans[1]*positions[1];
	EmitVertex();
	
	col = get_col(positions[2].z);
	gl_Position = trans[2]*positions[2];
	EmitVertex();
	EndPrimitive();
}

vec3 get_col(float z) {
	z = pow(z/multiplier, 1.0/power);
	if(z <= threshold) {
		return vec3(0.0, 0.0, 1.0);
	} else if (z <= threshold+0.1) {
		return vec3(1.0, 1.0, 0.0);
	} else if (z <= 0.85) {
		return vec3(0.1, 0.9, 0.1);
	} else if (z <= 0.92) {
		return vec3(0.7, 0.3, 0.0);
	} else {
		return vec3(1.0, 1.0, 1.0);
	}
}

//
// Description : Array and textureless GLSL 2D simplex noise function.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : ijm
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
// 

vec3 mod289(vec3 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289(vec2 x) {
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(vec3 x) {
  return mod289(((x*34.0)+1.0)*x);
}

float snoise(vec2 v)
  {
  const vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                      0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                     -0.577350269189626,  // -1.0 + 2.0 * C.x
                      0.024390243902439); // 1.0 / 41.0
// First corner
  vec2 i  = floor(v + dot(v, C.yy) );
  vec2 x0 = v -   i + dot(i, C.xx);

// Other corners
  vec2 i1;
  // i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
  // i1.y = 1.0 - i1.x;
  i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
  // x0 = x0 - 0.0 + 0.0 * C.xx ;
  // x1 = x0 - i1 + 1.0 * C.xx ;
  // x2 = x0 - 1.0 + 2.0 * C.xx ;
  vec4 x12 = x0.xyxy + C.xxzz;
  x12.xy -= i1;

// Permutations
  i = mod289(i); // Avoid truncation effects in permutation
  vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
		+ i.x + vec3(0.0, i1.x, 1.0 ));

  vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), 0.0);
  m = m*m ;
  m = m*m ;

// Gradients: 41 points uniformly over a line, mapped onto a diamond.
// The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

  vec3 x = 2.0 * fract(p * C.www) - 1.0;
  vec3 h = abs(x) - 0.5;
  vec3 ox = floor(x + 0.5);
  vec3 a0 = x - ox;

// Normalise gradients implicitly by scaling m
// Approximation of: m *= inversesqrt( a0*a0 + h*h );
  m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

// Compute final noise value at P
  vec3 g;
  g.x  = a0.x  * x0.x  + h.x  * x0.y;
  g.yz = a0.yz * x12.xz + h.yz * x12.yw;
  return 130.0 * dot(m, g);
}
