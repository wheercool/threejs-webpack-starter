uniform vec2 u_resolution;
uniform float u_time;
uniform sampler2D u_texture;
uniform vec2 u_texture_uv;
uniform vec3 u_mouse;

void main() {
    vec2 pos = gl_FragCoord.xy / u_texture_uv;
    vec4 color = texture2D(u_texture, pos);

//    float warmness = 0.0; // +0.2 - wram   -0.2 -cold
//    color.r += warmness;
//    color.b -= warmness;
//
//    float brightness = 0.2;
//    color.rgb += brightness;
//
//    float grayscale = (color.r + color.g + color.b) / 3.0;
//    color.rbg = vec3(grayscale);

    float shift = 100.0 * cos(u_time * 100.0) / pow(u_time, 2.0);
    vec2 left_pos = (gl_FragCoord.xy + vec2(shift, 0.0)) / u_texture_uv;
    vec2 top_pos = (gl_FragCoord.xy + vec2(0.0, 0.0)) / u_texture_uv;
    vec4 left_color = texture2D(u_texture, left_pos);
    vec4 top_color = texture2D(u_texture, top_pos);
    color = 0.5 * (color + left_color);

    gl_FragColor = color;
}
