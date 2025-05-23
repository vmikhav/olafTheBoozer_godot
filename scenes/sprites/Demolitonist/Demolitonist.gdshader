shader_type canvas_item;

uniform float status_intensity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 status_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float transparency : hint_range(0.0, 1.0) = 0.7;
uniform int ignore_background : hint_range(0, 1) = 1;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Skip transparent pixels
    if (tex_color.a < 0.01) {
        COLOR = tex_color;
    } else {
	    
	    // Convert original color to grayscale to neutralize existing colors
	    float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	    
	    // Mix grayscale with status color based on intensity
	    vec3 final_color = mix(tex_color.rgb, status_color.rgb * gray, status_intensity);
	    
	    // Apply transparency
	    float final_alpha = tex_color.a * transparency;
	    
	    if (ignore_background > 0) {
	        // Use premultiplied alpha to avoid blending with background
	        COLOR = vec4(final_color * final_alpha, final_alpha);
	    } else {
	        // Normal alpha blending
	        COLOR = vec4(final_color, final_alpha);
	    }
	}
}