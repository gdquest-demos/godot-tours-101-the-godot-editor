// Fades islands and other floating items in the background
shader_type canvas_item;

uniform vec4 color : source_color;

void fragment(){
	vec4 base_color = texture(TEXTURE,UV);
	vec4 new_color = mix(base_color, color, color.a * base_color.a);
	new_color.a = base_color.a;
	COLOR = new_color;
}