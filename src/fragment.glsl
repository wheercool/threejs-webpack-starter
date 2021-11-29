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

float getDist(vec3 p) {
    vec3 box2Pos = p - vec3(-2.5, 1.0, 7);
    vec3 boxPos = p - vec3(0.5, 1.0, 6);
    boxPos.xz *= rot(u_time);

    vec3 spherePos = p - vec3((u_mouse.x -0.5) * 20.0, (0.5 - u_mouse.y) * 10.0, 6);//vec3(1.5, 1.5, 6);
    spherePos *= vec3(2, 1, 1);
    float box = sdBox(boxPos, vec3(1.0));
    float box2 = sdBox(box2Pos, vec3(0.8));
    float sphere = sdSphere(spherePos, 0.8)/2.0;
    float sphere2 = sdSphere(box2Pos, 0.8);

    float plane = p.y;
    float dist = plane;
    float morph = mix(box2, sphere2, 0.5 * sin(u_time) + 0.5);
    dist = min(dist, morph);
    dist = min(dist, smin(sphere, box, 0.3));
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
    vec3 lightPos = vec3(0, 3, 2);
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
