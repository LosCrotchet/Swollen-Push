shader_type canvas_item;

uniform bool enable = true;
uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float width : hint_range(0.0, 10.0) = 1.0;
uniform int pattern : hint_range(0, 2) = 0; // 0: 菱形, 1: 圆形, 2: 方形

void fragment() {
    float size = width * fwidth(UV.x); // 适配缩放
    vec2 unit = TEXTURE_PIXEL_SIZE;
    float alpha = 0.0;
    
    if (pattern == 0) {
        // 菱形采样 (性能最好)
        alpha += texture(TEXTURE, UV + vec2(0.0, -width) * unit).a;
        alpha += texture(TEXTURE, UV + vec2(0.0, width) * unit).a;
        alpha += texture(TEXTURE, UV + vec2(-width, 0.0) * unit).a;
        alpha += texture(TEXTURE, UV + vec2(width, 0.0) * unit).a;
    } else {
        // 圆形采样 (效果最圆润)
        for (float x = -width; x <= width; x++) {
            for (float y = -width; y <= width; y++) {
                if (pattern == 1 && length(vec2(x, y)) > width) continue;
                alpha += texture(TEXTURE, UV + vec2(x, y) * unit).a;
            }
        }
    }
    
    vec4 col = texture(TEXTURE, UV);
    // 如果原像素透明且周围有像素，则显示描边
    if (enable && col.a < 0.1 && alpha > 0.0) {
        COLOR = outline_color;
    } else {
        COLOR = col;
    }
	
	
}