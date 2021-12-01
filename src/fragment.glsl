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
    float scale = mix(1.5, 1.0, smoothstep(-1., 1., position.y));
    position.xz *= scale;
    float mag = sdMag2(position, d) / 1.5;
    return mag;
}

float sdTable(vec3 p) {
    float d = 0.4;
    float worktopLength = 3.0 * d;
    float worktopWidth = 2.0 * d;
    float worktopThickness = 0.02;
    float worktop = sdBox(p, vec3(worktopLength, worktopThickness, worktopWidth));

    float legThickness = 0.04;
    float legLength = 1.5 * d;
    vec3 p1 = p;
    p1.x = abs(p1.x);
    p1.z = abs(p.z);
    vec3 legPos = p1 - vec3(worktopLength- 2.0 * legThickness, -legLength-worktopThickness, worktopWidth - 2.0 * legThickness);
    float leg = sdBox(legPos, vec3(legThickness + 1.0 * legThickness * smoothstep(0.05, 0.75, legPos.y), legLength, legThickness));
    return min(worktop, leg);
}

float sdKidsChair(vec3 p) {
    float seatD = 0.5;
    float seat = sdBox(p, vec3(seatD, 0.1 * seatD, seatD));

    vec3 legPos = p;
    legPos.xz = abs(legPos.xz);
    float legLength = 1.3 * seatD;
    float legR = mix(0.05, 0.1, smoothstep(0., -legLength, legPos.y));
    legPos.x -= seatD - 0.05;
    legPos.z -= seatD - 0.05;

    float leg = sdCylinder(legPos, vec3(0.0, 0., 0.0), vec3(0, -legLength, 0), legR);

    vec3 connectorPos = p;
    float connectorLength = 0.7 * seatD;
    float connectorThickness = 0.03;
    float connectorWidth = seatD / 6.0;
    connectorPos.z -= seatD - 2.0 * connectorThickness;
    connectorPos.y -= connectorLength;
    float connector = sdBox(connectorPos, vec3(seatD / 6.0, connectorLength, connectorThickness));

    vec3 connector2Pos = connectorPos;
    connector2Pos.x = abs(connector2Pos.x);
    connector2Pos.x -= 4.0 * connectorWidth;
    float connector2 = sdBox(connector2Pos, vec3(connectorWidth, connectorLength, connectorThickness));

    float backWidth = 0.6 * seatD;
    vec3 backPos = p;
    backPos.y -= 2.0 * connectorLength + backWidth;
    backPos.z -= seatD - 2.0 * connectorThickness;
    // backPos - is new coordinate system for back. (0, 0) is center
    float backLength = mix(0.9 * seatD, 1.1 * seatD, smoothstep(-2.0 * backWidth, backWidth, backPos.y));
    float back = sdBox(backPos, vec3(backLength, backWidth, connectorThickness));
    float dist = seat;
    dist = min(dist, leg);
    dist = min(dist, connector);
    dist = min(dist, connector2);
    dist = min(dist, back);
    return dist;
}
float getDist(vec3 p) {
    vec3 pos = p - vec3(0, 1, 6);
    pos.yz *= rot(sin(0.5 * u_time));
    pos.xz *= rot(0.5 * u_time / PI);
    float chair = sdKidsChair(pos);
    float dist = chair;
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
