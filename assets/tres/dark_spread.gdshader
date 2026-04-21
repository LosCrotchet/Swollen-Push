shader_type canvas_item;

// 控制黑色区域的大小：0 为全透明/无，1 为全黑/满
uniform float spread : hint_range(0.0, 1.0) = 0.5;

// 控制边缘的羽化程度（模糊感）
uniform float feather : hint_range(0.01, 1.0) = 0.2;

// 你可以自由调整黑色区域的颜色（默认为纯黑）
uniform vec4 mask_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // 1. 计算 UV 坐标到中心点 (0.5, 0.5) 的距离
    // length(vec2) 返回向量的长度
    float dist = length(UV - vec2(0.5));
    
    // 2. 核心逻辑：使用 smoothstep 处理羽化效果
    // 我们将 spread 映射到距离上。因为中心到边缘的最大距离约为 0.707，
    // 所以我们需要对 spread 进行适当缩放，使得 1.0 能覆盖全屏。
    float radius = spread;
    
    // smoothstep(下限, 上限, 变量)
    // 当距离小于 (radius - feather) 时，返回 1.0（完全黑色）
    // 在羽化区间内，产生 1.0 到 0.0 的平滑过渡
    float alpha = 1.0 - smoothstep(radius - feather, radius, dist);
    
    // 3. 输出颜色
    // mask_color.rgb 是颜色，mask_color.a * alpha 控制透明度
    COLOR = vec4(mask_color.rgb, mask_color.a * alpha);
}