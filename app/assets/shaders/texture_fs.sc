$input v_texcoord0

#include <bgfx_shader.sh>

uniform vec4 color;
SAMPLER2D(s_tex, 0);

void main() {
	gl_FragColor = texture2D(s_tex, vec2(1.0, 0.0) + (v_texcoord0 * vec2(-1.0, 1.0))) * color;
}
