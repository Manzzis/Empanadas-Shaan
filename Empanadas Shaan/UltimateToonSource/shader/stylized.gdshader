shader_type spatial;

// ==============================================================================
// VARIABLES DEL INSPECTOR (UNIFORMS)
// Estas variables aparecerán agrupadas en el panel derecho de Godot.
// ==============================================================================

// --- GRUPO: Color Base e Imagen ---
group_uniforms Shader.Albedo;
uniform vec4 albedo_color : source_color  = vec4(1.0); // Color principal
uniform sampler2D albedo_texture;                      // Textura base
uniform float albedo_affect : hint_range(0.0, 1.0, 0.05) = 0.0; // Cuánto afecta el color a la luz difusa

// --- GRUPO: Iluminación y Sombras (El núcleo del estilo Toon) ---
group_uniforms Shader.Light;
uniform bool use_stepped = true;                       // Activa el corte duro de luz (Cel-Shading)
uniform float steps = 3.0;                             // Cantidad de "bandas" o escalones de luz
uniform float step_smoothness : hint_range(0.0, 1.0, 0.05) = 0.3; // Suavidad entre las bandas de luz
uniform vec4 shadow_tint : source_color;               // Color con el que se tiñen las sombras
uniform float shadow_tint_amount : hint_range(0.0, 1.0, 0.1) = 0.4; // Intensidad del tinte de sombra

// --- GRUPO: Brillo (Especular) ---
group_uniforms Shader.Specular;
uniform float specular : hint_range(0.0, 1.0, 0.05) = 0.0; // Intensidad del brillo de la luz directa

// --- GRUPO: Relieve (Normales) ---
group_uniforms Shader.Normal;
uniform float normal_strength : hint_range(0.0, 1.0, 0.05) = 0.0; // Fuerza de la textura de relieve
uniform sampler2D normal_texture;                      // Mapa de normales

// --- GRUPO: Luz de Borde (Rim Light) ---
// Ideal para destacar la silueta de los objetos contra el fondo.
group_uniforms Shader.Rim;
uniform bool use_rim = true;                           // Activa la luz de borde
uniform vec4 rim_color : source_color = vec4(1.0);     // Color del borde
uniform float rim_amount = 2.0;                        // Grosor del borde
uniform float rim_smoothness = 0.2;                    // Suavidad del borde
uniform float rim_mask_shadow : hint_range(0.0, 1.0, 0.05) = 1.0; // Oculta el borde si está en la oscuridad
uniform float rim_blend : hint_range(0.0, 1.0, 0.05) = 1.0; // Mezcla general del efecto

// --- GRUPO: Patrones de Sombra (Estilo Cómic / Manga) ---
// Dibuja una trama (como puntitos o líneas) en las zonas oscuras.
group_uniforms Shader.Pattern;
uniform bool use_pattern = true;                       // Activa la textura de trama
uniform sampler2D pattern_texture : filter_nearest, repeat_enable;                     // La imagen del patrón (ej. puntos de semitono)
uniform int pattern_uv_mode : hint_enum("UV", "Screen", "Local Screen") = 2; // Cómo se proyecta el patrón
uniform float pattern_tiling = 32.0;                   // Tamaño del patrón
uniform float pattern_amount : hint_range(0.0, 1.0, 0.05) = 0.5; // Cantidad de patrón
uniform float pattern_smoothness : hint_range(0.0, 1.0, 0.05) = 0.5; // Difuminado del patrón
uniform float pattern_blend : hint_range(0.0, 1.0, 0.05) = 0.2; // Transparencia del patrón

// Variable para pasar datos de la posición desde el Vertex al Fragment/Light
varying vec4 node_position; 


// ==============================================================================
// FUNCIONES MATEMÁTICAS AUXILIARES
// ==============================================================================

// Calcula el "Fresnel", que es más intenso en los bordes del modelo. Se usa para el Rim Light.
float fresnel(float amount, vec3 normal, vec3 view) {
	return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0 )), amount);
}

// Proyecta el mapa del patrón dependiendo del modo elegido (pegado al modelo o pegado a la cámara)
vec2 pattern_uv(vec2 uv, vec2 screen_uv){
	vec2 p_uv = uv;
	if(pattern_uv_mode == 1) { p_uv = screen_uv; }
	if(pattern_uv_mode == 2) { p_uv = (screen_uv * 2.0 - 1.0) * node_position.w - node_position.xy; }
	return p_uv;
}

// Aplica la imagen de la textura del patrón sobre las sombras usando un cálculo de suavizado (smoothstep)
float shape_value(float value, vec2 uv, vec2 screen_size){
	float aspect = screen_size.y / screen_size.x;
	vec2 pattern_uv = uv * pattern_tiling * vec2(1.0, aspect);
	float shadow_pattern = texture(pattern_texture, pattern_uv).r;
	shadow_pattern = clamp(smoothstep(shadow_pattern - pattern_smoothness, shadow_pattern + pattern_smoothness, value + pattern_amount), 0.0, value + pattern_amount);
	return shadow_pattern;
}


// ==============================================================================
// PROCESAMIENTO DEL MODELO 3D
// ==============================================================================

// Función Vertex: Se ejecuta por cada vértice de la malla 3D.
void vertex() {
     // Guarda la posición del nodo en el mundo para que el patrón "Local Screen" no se deslice
	 node_position = (PROJECTION_MATRIX * vec4(NODE_POSITION_VIEW, 1.0));
}

// Función Fragment: Se ejecuta por cada píxel visible del modelo. 
// Define los colores puros antes de que les pegue la luz.
void fragment() {
	// (Modificación aplicada previamente): Multiplicamos por COLOR para leer los colores de vértice del .glb
	vec4 albedo = texture(albedo_texture, UV) * albedo_color * COLOR;
	vec4 normal_map = texture(normal_texture, UV);

	ALBEDO = albedo.rgb; // Asigna el color final del píxel
	NORMAL_MAP = mix(vec3(0.5,0.5,1.0), normal_map.rgb, normal_strength); // Aplica el relieve
	SPECULAR = specular; // Asigna cuánto va a brillar
}


// ==============================================================================
// CÁLCULO DE ILUMINACIÓN PERSONALIZADA
// Aquí es donde ocurre la "magia" del Toon Shader, anulando la luz realista de Godot.
// ==============================================================================
void light () {
    // 1. Calcula cuánta luz recibe la cara del modelo (Normal Dot Light). Da un valor de 0 (sombra) a 1 (luz total).
	float ndotl = clamp(dot(NORMAL,LIGHT),0.0,1.0) * ATTENUATION;
	float light = ndotl;

    // 2. Efecto Escalera (Cel-Shading). Corta el gradiente de luz suave en franjas sólidas.
	if(use_stepped){
		float light_mult = light * steps;
		float step_base = floor(light_mult);
		float light_factor = light_mult - step_base;

		light_factor = smoothstep(0.5 - step_smoothness, 0.5 + step_smoothness, light_factor);
		light = (step_base + light_factor) / steps;
	}

    // 3. Efecto Trama (Pattern). Aplica puntitos o rayitas en las transiciones de sombra.
	if(use_pattern){
		vec2 p_uv = pattern_uv(UV, SCREEN_UV);
		light = mix(light, shape_value(light, p_uv, VIEWPORT_SIZE), pattern_blend);
	}

    // 4. Color y Sombras. Se mezcla la luz con el color (LIGHT_COLOR) y se aplica el tinte a las zonas oscuras (shadow_tint).
	vec3 diffuse = vec3(pow(light, 1.0)) * (LIGHT_COLOR / PI);
	diffuse = (shadow_tint.rgb * (1.0 - (light)) * shadow_tint_amount) + diffuse * light;

    // 5. Efecto Luz de Borde (Rim Light). Dibuja un halo brillante en los contornos del modelo.
	if(use_rim){
		float rim_value = fresnel(rim_amount, NORMAL, VIEW);
		rim_value = smoothstep(0.5 - (rim_smoothness / 2.0), 0.5 + (rim_smoothness / 2.0), rim_value);
		rim_value = mix(rim_value, rim_value * light, rim_mask_shadow); // Evita que el borde brille en la sombra absoluta

		diffuse += rim_color.rgb * rim_value * rim_blend;
	}

    // 6. Entrega el resultado final a Godot para que lo pinte en pantalla.
	DIFFUSE_LIGHT += mix(diffuse, ALBEDO * diffuse, albedo_affect);
	SPECULAR_LIGHT += vec3(pow(light, 50.0)) * specular;
}