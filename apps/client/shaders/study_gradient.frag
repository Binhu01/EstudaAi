#version 460 core
#include <flutter/runtime_effect.glsl>
uniform vec2 uResolution;
uniform float uTime;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;
uniform float uBrightness;
uniform float uDensity;
uniform float uFrequency;
uniform float uAmplitude;
uniform float uSpeed;
uniform float uStrength;
uniform float uRotation;
out vec4 fragColor;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
             mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0)), f.x), f.y);
}
void main() {
  vec2 uv = FlutterFragCoord().xy / max(uResolution, vec2(1.0));
  vec2 p = (uv - 0.5) * vec2(1.4, 1.0);
  float a = radians(uRotation);
  p = mat2(cos(a), -sin(a), sin(a), cos(a)) * p;
  float t = uTime * uSpeed;
  float sphere = sqrt(max(0.02, 1.0 - dot(p, p) * 0.8));
  vec2 warped = p * (uDensity * 2.0) + vec2(sin(t * 0.3), cos(t * 0.23)) * 0.3;
  float field = noise(warped + vec2(sphere * 0.8, t * 0.07));
  field += sin(p.x * uFrequency + field * uAmplitude + t * 0.4) * uStrength * 0.35;
  float violet = smoothstep(0.22, 0.75, field + p.y * 0.5);
  float yellow = smoothstep(0.58, 1.05, field - p.x * 0.7 - p.y * 0.2);
  vec3 color = mix(uColor2, uColor3, violet);
  color = mix(color, uColor1, yellow * 0.8);
  float lighting = 0.62 + sphere * 0.3 + field * 0.08;
  color *= lighting * uBrightness;
  float grain = (hash(FlutterFragCoord().xy + floor(t * 5.0)) - 0.5) * 0.035;
  fragColor = vec4(clamp(color + grain, 0.0, 1.0), 1.0);
}
