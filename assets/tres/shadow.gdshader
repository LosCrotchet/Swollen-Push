shader_type canvas_item;

// 阴影颜色与透明度
uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.4);

// 光源角度（度数，0代表右，90代表下）
uniform float shadow_angle : hint_range(0.0, 360.0) = 45.0;

// 阴影拉伸倍数（1.0为原始大小，数值越大影子被拉得越长）
uniform float shadow_length : hint_range(1.0, 50.0) = 1.5;

// 小鸟距离地面的高度（控制阴影的整体偏移距离）
uniform float shadow_height : hint_range(0.0, 2000.0) = 30.0;

// 错切/斜切因子（用于模拟不同视角的3D透视形变，0为无错切）
uniform float skew_factor : hint_range(-2.0, 2.0) = 0.0;

void vertex() {
    // 将角度转换为弧度，并计算光线的方向向量
    float rad = radians(shadow_angle);
    vec2 light_dir = vec2(cos(rad), sin(rad));
    
    // 1. 沿光线方向的拉伸变换 (Scale along light axis)
    // 利用点积算出当前顶点在光线方向上的投影分量
    float dot_prod = VERTEX.x * light_dir.x + VERTEX.y * light_dir.y;
    vec2 stretched_vertex = VERTEX + light_dir * dot_prod * (shadow_length - 1.0);
    
    // 2. 垂直于光线方向的错切变换 (Skew)
    // 计算出法线向量，用于产生不对称的倾斜感
    vec2 normal_dir = vec2(-light_dir.y, light_dir.x);
    float normal_dot = VERTEX.x * normal_dir.x + VERTEX.y * normal_dir.y;
    stretched_vertex += light_dir * normal_dot * skew_factor;
    
    // 3. 应用高度偏移 (Offset)
    // 影子根据光源方向投射出一段距离，表现出小鸟悬空的高度
    VERTEX = stretched_vertex + light_dir * shadow_height;
}

void fragment() {
    // 采样原图的像素
    vec4 tex_color = texture(TEXTURE, UV);
    
    // 丢弃原图的色彩，只保留透明度 (Alpha)
    // 将其乘以我们自定义的阴影透明度
    COLOR = vec4(shadow_color.rgb, tex_color.a * shadow_color.a);
}