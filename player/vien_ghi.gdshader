shader_type spatial;
render_mode unshaded, blend_add;

// Lượt 1 của viền ngắm (material_overlay): vô hình (cộng màu đen), chỉ ghi stencil = 1 lên đúng hình vật.
// Lượt 2 là `vien_vanh.gdshader`, gắn ở next_pass.
stencil_mode write, compare_always, 1;

void fragment() {
	ALBEDO = vec3(0.0);
}
