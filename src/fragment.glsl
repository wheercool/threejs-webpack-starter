#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

vec3 rgb2hsb(in vec3 c){
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz),
    vec4(c.gb, K.xy),
    step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r),
    vec4(c.r, p.yzx),
    step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)),
    d / (q.x + e),
    q.x);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
vec3 hsb2rgb(in vec3 c) {
    vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0, 4.0, 2.0),
    6.0)-3.0)-1.0,
    0.0,
    1.0);
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * mix(vec3(1.0), rgb, c.y);
}

float linear(vec2 domain, vec2 range, float x) {
    return range.x + ((range.y - range.x) * (x - domain.x) / (domain.y - domain.x));
}
void main() {
    vec2 st = gl_FragCoord.xy/u_resolution;
    vec3 color = vec3(0.0);
    float d = 0.1;
    float frequence = 0.3;
    float fn = st.x;

    if (abs(frequence - st.x) <= d) {
        fn = frequence;
    } else if (st.x < (frequence - d)) {
        fn = linear(vec2(0.0, frequence - d), vec2(0.0  , frequence), st.x);
    } else if (st.x > (frequence + d)) {
        fn = linear(vec2(frequence + d, 1.0), vec2(frequence, 1.0), st.x);
    }

    color = hsb2rgb(vec3(fn, 1.0, 1.0));
    gl_FragColor = vec4(color, 1.0);
}
