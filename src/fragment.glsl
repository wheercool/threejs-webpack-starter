#ifdef GL_ES
precision mediump float;
#endif

#define MAX_STEPS 100
#define SURF_DIST .001
#define MAX_DIST 100.

uniform vec2 u_resolution;
uniform float u_time;

float getDist(vec3 p) {
    vec4 sphere = vec4(0, 1, 6, 1);
    float sphereDist = length(sphere.xyz - p) - sphere.w;
    float planeDist = p.y;
    float dist = min(sphereDist, planeDist);
    return dist;
}
float rayMarch(vec3 ro, vec3 rd)
{

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
    vec3 lightPos = vec3(0, 5, 6);
    lightPos.xz += vec2(sin(u_time), cos(u_time)) * 2.0;
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
    vec3 col = vec3(0.0);
    vec3 ro = vec3(.0, 1.0, .0);
    vec3 rd = normalize(vec3(uv.x, uv.y, 1.0));
    float d = rayMarch(ro, rd);
    vec3 p = ro + d * rd;
    float diff = getLight(p);
    col = vec3(diff);
    gl_FragColor = vec4(col, 1.0);
}
