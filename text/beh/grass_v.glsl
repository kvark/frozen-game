#version 130

uniform struct Spatial	{
	vec4 pos,rot;
}s_heli;
uniform float reflect_koef;

uniform vec4 cur_time;


out vec3 to_pos,to_speed;

const float klink = 1.0;	//coef it affects the speed
const float kpow = -1.5;	//distance^2 attenuation power
const float ktime = 40.0;	//sinus time factor


float update_grass()	{
	vec3 dir = s_heli.pos.xyz - to_pos;
	float d2 = dot(dir,dir);
	float s2 = 0.5*(1.0+sin(cur_time.y * ktime));
	dir *= pow(d2,kpow) * s2;
	float dt = klink / max(cur_time.x,0.01);
	to_speed -= dir * dt;
	return 1.0;
}
