#ifdef GL_ES
precision mediump float;
#endif

#define PI 3.1415
#define MAX_STEPS 100
#define SURF_DIST .001
#define MAX_DIST 100.

uniform vec2 u_resolution;
uniform vec2 u_mouse;
uniform float u_time;

mat2 rot(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return mat2(c, -s, s, c);
}

float sdSphere(vec3 p, float r) {
    return length(p)-r;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a)/k, 0., 1.);
    return mix(b, a, h) - k*h*(1.0 - h);
}

float sdCylinder(vec3 p, vec3 a, vec3 b, float r)
{
    vec3  ba = b - a;
    vec3  pa = p - a;
    float baba = dot(ba, ba);
    float paba = dot(pa, ba);
    float x = length(pa*baba-ba*paba) - r*baba;
    float y = abs(paba-baba*0.5)-baba*0.5;
    float x2 = x*x;
    float y2 = y*y*baba;
    float d = (max(x, y)<0.0)?-min(x2, y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
    return sign(d)*sqrt(abs(d))/baba;
}

float sdCappedCylinder(vec3 p, float h, float r)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}

float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz)-t.x, p.y);
    return length(q)-t.y;
}

float sdMag(vec3 p, float d) {
    float thickness = d / 10.0;
    float outerCylinder = sdCylinder(p, vec3(0, 0, 0), vec3(0, 2.0 * d, 0), d);
    float innerCylinder = sdCylinder(p, vec3(0, thickness, 0), vec3(0, 2.0 * d + thickness, 0), d - thickness);

    vec3 magHandlePos = p - vec3(d, d, 0);
    magHandlePos.yz *= rot(0.5 * PI);

    float bowl = max(outerCylinder, -innerCylinder);
    float magHandle = sdTorus(magHandlePos, vec2(0.6 * d, 0.1 * d));
    magHandle = max(magHandle, -outerCylinder);
    float dist = smin(bowl, magHandle, 0.01);
    return dist;
}

float sdMag2(vec3 p, float d) {
    float thickness = d / 10.0;
    float outerCylinder = sdCylinder(p, vec3(0, 0, 0), vec3(0, 2.0 * d, 0), d);

    vec3 magHandlePos = p - vec3(d, d, 0);
    magHandlePos.yz *= rot(0.5 * PI);

    float bowl = outerCylinder;
    bowl = abs(bowl) - 0.5 * thickness;
    float plane = dot(p - 2.0 * d + thickness, normalize(vec3(0, 1, 0)));
    bowl = max(plane, bowl);

    float fullMagHandle = sdTorus(magHandlePos, vec2(0.6 * d, 0.1 * d));
    float magHandle = max(fullMagHandle, -outerCylinder);
    float dist = min(bowl, magHandle);
    return dist;
}

float sdMag3(vec3 p, float d) {
    vec3 position = p;
    float scale = mix(1.5, 1.0, smoothstep(-1., 1. , position.y));
    position.xz *= scale;
    float mag = sdMag2(position, d) / 1.5;
    return mag;
}

float getDist(vec3 p) {
    vec3 magPos = p - vec3(0, 1, 6);
    vec3 mag2Pos = p - vec3(-1.5, 1, 6);
    mag2Pos.yz *= rot(0.25 * PI);
    magPos.yz *= rot(sin(0.5 * u_time));
    magPos.xz *= rot(2.0 * u_time / PI);
    float mag = sdMag3(magPos, 0.5);
    float mag2 = sdMag2(mag2Pos, 0.3);
    float dist = min(mag, mag2);
    return dist;
}
float rayMarch(vec3 ro, vec3 rd) {
    float d0 = 0.0;
    for (int i = 0; i < MAX_STEPS; i++) {

        vec3 p = ro + d0*rd;
        float dS = getDist(p);
        d0 += dS;
        if (d0 > MAX_DIST || d0 < SURF_DIST) break;
    }
    return d0;
}
vec3 getNormal(vec3 p) {
    float d = getDist(p);
    vec2 e = vec2(0.01, 0);
    vec3 n = d - vec3(
    getDist(p - e.xyy),
    getDist(p - e.yxy),
    getDist(p - e.yyx)
    );
    return normalize(n);
}
float getLight(vec3 p) {
    vec3 lightPos = vec3(0, 1, 2);
    //    lightPos.xz += vec2(sin(u_time), cos(u_time)) * 2.0;
    vec3 l = normalize(lightPos - p);
    vec3 n = getNormal(p);
    float dif = clamp(dot(l, n), 0.0, 1.0);
    float d = rayMarch(p + n * SURF_DIST * 2.0, l);
    if (d < length(lightPos - p)) {
        dif *= 0.1;
    }

    return dif;
}

void main() {
    vec2 uv = (gl_FragCoord.xy - 0.5 * u_resolution.xy) / u_resolution.y;
    vec3 col =  vec3(0.0);
    //    vec3 ro = vec3(vec2(1.0, 4.0) * (1.0 - u_mouse / u_resolution), 1.0);
    vec3 ro = vec3(0.0, 1.0, 0.0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.0));
    float d = rayMarch(ro, rd);
    vec3 p = ro + d * rd;
    float diff = getLight(p);
    col = vec3(diff);
    gl_FragColor = vec4(col, 1.0);
}
