#define MAX_MATERIAL_MAPS 12
#define RL_MAX_SHADER_LOCATIONS 32

#include <raylib.h>

#define RAYGUI_IMPLEMENTATION
#include <raygui.h>
#undef RAYGUI_IMPLEMENTATION

static void kk_raylib_InitWindow(kk_integer_t width, kk_integer_t height, kk_string_t window_name, kk_context_t* ctx) {
    const char* window_name_cstr = kk_string_cbuf_borrow(window_name, NULL, ctx);
    InitWindow(kk_integer_clamp32(width, ctx), kk_integer_clamp32(height, ctx), window_name_cstr);
}

static void kk_raylib_CloseWindow(kk_context_t* ctx) {
    CloseWindow();
}

static void kk_raylib_SetTargetFPS(kk_integer_t fps, kk_context_t* ctx) {
    SetTargetFPS(kk_integer_clamp32(fps, ctx));
}

static void kk_raylib_DisableCursor(kk_context_t* ctx) {
    DisableCursor();
}

static void kk_raylib_EnableCursor(kk_context_t* ctx) {
    EnableCursor();
}

static bool kk_raylib_IsCursorOnScreen(kk_context_t* ctx) {
    return IsCursorOnScreen();
}

static bool kk_raylib_WindowShouldClose(kk_context_t* ctx) {
    return WindowShouldClose();
}

static void kk_raylib_BeginDrawing(kk_context_t* ctx) {
    BeginDrawing();
}

static void kk_raylib_EndDrawing(kk_context_t* ctx) {
    EndDrawing();
}

static Color kk_color_to_raylib(kk_raylib_raylib__color kk_color, kk_context_t* ctx) {
    Color color;
    color.a = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_a(kk_color, ctx), ctx );
    color.r = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_r(kk_color, ctx), ctx );
    color.g = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_g(kk_color, ctx), ctx );
    color.b = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_b(kk_color, ctx), ctx );

    return color;
}

static void kk_raylib_ClearBackground(kk_raylib_raylib__color kk_color, kk_context_t* ctx) {
    Color color = kk_color_to_raylib(kk_color, ctx);
    ClearBackground(color);
}

static void kk_raylib_DrawText(kk_string_t kk_text,
                               kk_integer_t kk_posX,
                               kk_integer_t kk_posY,
                               kk_integer_t kk_fontSize,
                               kk_raylib_raylib__color kk_color,
                               kk_context_t* ctx) {
    const char* text = kk_string_cbuf_borrow(kk_text, NULL, ctx);
    int posX = kk_integer_clamp32(kk_posX, ctx);
    int posY = kk_integer_clamp32(kk_posY, ctx);
    int fontSize = kk_integer_clamp32(kk_fontSize, ctx);
    Color color = kk_color_to_raylib(kk_color, ctx);

    DrawText(text, posX, posY, fontSize, color);

    kk_string_drop(kk_text, ctx);
}

static void kk_raylib_DrawFPS(kk_integer_t kk_posX, kk_integer_t kk_posY, kk_context_t* ctx) {
    int posX = kk_integer_clamp32(kk_posX, ctx);
    int posY = kk_integer_clamp32(kk_posY, ctx);

    DrawFPS(posX, posY);
}

static kk_integer_t kk_raylib_MeasureText(kk_string_t kk_text, kk_integer_t kk_fontSize, kk_context_t* ctx) {
    const char* text = kk_string_cbuf_borrow(kk_text, NULL, ctx);
    int fontSize = kk_integer_clamp32(kk_fontSize, ctx);

    int res = MeasureText(text, fontSize);
    kk_integer_t kk_res = kk_integer_from_int32(res, ctx);

    kk_string_drop(kk_text, ctx);

    return kk_res;
}

static Vector3 kk_to_c_vector3(kk_raylib_raylib__vector3 kk_vector, kk_context_t *ctx) {
    float x = kk_raylib_raylib_vector3_fs_x(kk_vector, ctx);
    float y = kk_raylib_raylib_vector3_fs_y(kk_vector, ctx);
    float z = kk_raylib_raylib_vector3_fs_z(kk_vector, ctx);

    Vector3 vec;
    vec.x = x;
    vec.y = y;
    vec.z = z;

    return vec;
}

static void kk_raylib_DrawCube(kk_raylib_raylib__vector3 kk_position,
                               double width,
                               double height,
                               double length,
                               kk_raylib_raylib__color kk_color,
                               kk_context_t* ctx) {
    Vector3 position = kk_to_c_vector3(kk_position, ctx);
    Color color = kk_color_to_raylib(kk_color, ctx);
    DrawCube(position, width, height, length, color);
}

static void kk_raylib_DrawGrid(kk_integer_t kk_slices,
                               double spacing,
                               kk_context_t* ctx) {
    int slices = kk_integer_clamp32(kk_slices, ctx);
    DrawGrid(slices, spacing);
}

static kk_raylib_raylib__texture raylib_to_kk_texture(Texture2D texture, kk_context_t* ctx) {
    kk_integer_t kk_id = kk_integer_from_uint32(texture.id, ctx);
    kk_integer_t kk_width = kk_integer_from_int32(texture.width, ctx);
    kk_integer_t kk_height = kk_integer_from_int32(texture.height, ctx);
    kk_integer_t kk_mipmaps = kk_integer_from_int32(texture.mipmaps, ctx);
    kk_integer_t kk_format = kk_integer_from_int32(texture.format, ctx);

    return kk_raylib_raylib__new_Texture(kk_reuse_null, 0, kk_id, kk_width, kk_height, kk_mipmaps, kk_format, ctx);
}

static kk_raylib_raylib__texture kk_raylib_LoadTexture(kk_string_t kk_fileName, kk_context_t* ctx) {
    const char* fileName = kk_string_cbuf_borrow(kk_fileName, NULL, ctx);

    Texture2D res = LoadTexture(fileName);
    kk_string_drop(kk_fileName, ctx);

    return raylib_to_kk_texture(res, ctx);
}

static Texture2D kk_texture_from_kk(kk_raylib_raylib__texture kk_texture, kk_context_t* ctx) {
    Texture2D texture;
    texture.id = kk_integer_clamp32(kk_raylib_raylib_texture_fs_id(kk_texture, ctx), ctx);
    texture.width = kk_integer_clamp32(kk_raylib_raylib_texture_fs_width(kk_texture, ctx), ctx);
    texture.height = kk_integer_clamp32(kk_raylib_raylib_texture_fs_height(kk_texture, ctx), ctx);
    texture.mipmaps = kk_integer_clamp32(kk_raylib_raylib_texture_fs_mipmaps(kk_texture, ctx), ctx);
    texture.format = kk_integer_clamp32(kk_raylib_raylib_texture_fs_format(kk_texture, ctx), ctx);

    return texture;
}

static void kk_raylib_DrawTexture(kk_raylib_raylib__texture kk_texture,
                                  kk_integer_t kk_posX,
                                  kk_integer_t kk_posY, 
                                  kk_raylib_raylib__color kk_color, 
                                  kk_context_t* ctx) {
    Texture2D texture = kk_texture_from_kk(kk_texture, ctx);
    int posX = kk_integer_clamp32(kk_posX, ctx);
    int posY = kk_integer_clamp32(kk_posY, ctx);

    Color tint = kk_color_to_raylib(kk_color, ctx);

    DrawTexture(texture, posX, posY, tint);
}

static void kk_raylib_DrawTextureEx(kk_raylib_raylib__texture kk_texture,
                                    kk_raylib_raylib__vector2 kk_position,
                                    float rotation,
                                    float scale,
                                    kk_raylib_raylib__color kk_tint,
                                    kk_context_t *ctx)
{
    Texture2D texture = kk_texture_from_kk(kk_texture, ctx);

    Vector2 position;
    position.x = kk_raylib_raylib_vector2_fs_x(kk_position, ctx);
    position.y = kk_raylib_raylib_vector2_fs_y(kk_position, ctx);

    Color tint = kk_color_to_raylib(kk_tint, ctx);

    DrawTextureEx(texture, position, rotation, scale, tint);
}

static kk_vector_t raylib_to_kk_vector_float(int vertex_count, float* vertices, kk_context_t* ctx) {
    kk_vector_t v;
    if (vertices)
    {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(vertex_count, &p, ctx);
        for (kk_ssize_t i = 0; i < vertex_count; i++)
        {
            p[i] = kk_double_box(vertices[i], ctx);
        }
    }
    else
    {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(0, &p, ctx);
    }
    return v;
}

static kk_vector_t raylib_to_kk_vector_char(int vertex_count, unsigned char* data, kk_context_t* ctx) {
    kk_vector_t v;
    if (data)
    {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(vertex_count, &p, ctx);
        for (kk_ssize_t i = 0; i < vertex_count; i++)
        {
            p[i] = kk_char_box(data[i], ctx);
        }
    }
    else
    {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(0, &p, ctx);
    }
    return v;
}

static kk_vector_t raylib_to_kk_vector_short(int vertex_count, unsigned short* data, kk_context_t* ctx) {
    // We use kk_integers for these because koka doesn't have a short type
    kk_vector_t v;
    if (data)
    {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(vertex_count, &p, ctx);
        for (kk_ssize_t i = 0; i < vertex_count; i++)
        {
            kk_integer_t kk_data_i = kk_integer_from_int32(data[i], ctx);
            p[i] = kk_integer_box(kk_data_i, ctx);
        }
    }
    else
    {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(0, &p, ctx);
    }
    return v;
}

static kk_vector_t raylib_to_kk_vector_int(int vertex_count, int* data, kk_context_t* ctx) {
    // We use kk_integers for these because koka doesn't have a short type
    kk_vector_t v;
    if (data) {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(vertex_count, &p, ctx);
        for (kk_ssize_t i = 0; i < vertex_count; i++)
        {
            kk_integer_t kk_data_i = kk_integer_from_int32(data[i], ctx);
            p[i] = kk_integer_box(kk_data_i, ctx);
        }
    } else {
        kk_box_t* p;
        v = kk_vector_alloc_uninit(0, &p, ctx);
    }
    return v;
}

static kk_raylib_raylib__mesh raylib_mesh_to_kk(Mesh m, kk_context_t *ctx) {
    kk_integer_t kk_vertex_count = kk_integer_from_int32(m.vertexCount, ctx);
    kk_integer_t kk_triangle_count = kk_integer_from_int32(m.triangleCount, ctx);

    kk_vector_t kk_vertices = raylib_to_kk_vector_float(m.vertexCount * 3, m.vertices, ctx);
    kk_vector_t kk_texcoords = raylib_to_kk_vector_float(m.vertexCount * 2, m.texcoords, ctx);
    kk_vector_t kk_texcoords2 = raylib_to_kk_vector_float(m.vertexCount * 2, m.texcoords2, ctx);
    kk_vector_t kk_normals = raylib_to_kk_vector_float(m.vertexCount * 3, m.normals, ctx);
    kk_vector_t kk_tangents = raylib_to_kk_vector_float(m.vertexCount * 4, m.tangents, ctx);
    kk_vector_t kk_colors = raylib_to_kk_vector_char(m.vertexCount * 4, m.colors, ctx);
    kk_vector_t kk_indices = raylib_to_kk_vector_short(m.vertexCount, m.indices, ctx);

    kk_integer_t kk_vao_id = kk_integer_from_int32(m.vaoId, ctx);
    kk_vector_t kk_vbo_id = raylib_to_kk_vector_int(m.triangleCount, (int*)m.vboId, ctx);

    return kk_raylib_raylib__new_Mesh(kk_reuse_null, 0, 
        kk_vertex_count,
        kk_triangle_count,
        kk_vertices,
        kk_texcoords,
        kk_texcoords2,
        kk_normals,
        kk_tangents,
        kk_colors,
        kk_indices,
        kk_vao_id,
        kk_vbo_id,
        ctx);
}

static kk_raylib_raylib__mesh kk_raylib_GenMeshCone(double radius,
                                                    double height,
                                                    kk_integer_t kk_slices,
                                                    kk_context_t* ctx) 
{
    int slices = kk_integer_clamp32(kk_slices, ctx);

    Mesh result = GenMeshCone(radius, height, slices);
    kk_raylib_raylib__mesh kk_result = raylib_mesh_to_kk(result, ctx);
    return kk_result;
}

static kk_raylib_raylib__color raylib_color_to_kk(Color c, kk_context_t* ctx) {
    kk_integer_t kk_r = kk_integer_from_int32(c.r, ctx);
    kk_integer_t kk_g = kk_integer_from_int32(c.g, ctx);
    kk_integer_t kk_b = kk_integer_from_int32(c.b, ctx);
    kk_integer_t kk_a = kk_integer_from_int32(c.a, ctx);

    return kk_raylib_raylib__new_Color(kk_reuse_null, 0, kk_r, kk_g, kk_b, kk_a, ctx);
}

static kk_raylib_raylib__materialMap raylib_to_kk_materialMap(MaterialMap* map, kk_context_t* ctx) {
    kk_raylib_raylib__texture kk_texture = raylib_to_kk_texture(map->texture, ctx);
    kk_raylib_raylib__color kk_color = raylib_color_to_kk(map->color, ctx);
    double value = map->value;

    return kk_raylib_raylib__new_MaterialMap(kk_reuse_null, 0, kk_texture, kk_color, value, ctx);
}

static kk_vector_t raylib_to_kk_vector_materialMap(MaterialMap* maps, kk_context_t* ctx) {
    kk_vector_t v;
    if (maps) {
        kk_box_t *p;
        v = kk_vector_alloc_uninit(MAX_MATERIAL_MAPS, &p, ctx);
        for (kk_ssize_t i = 0; i < MAX_MATERIAL_MAPS; i++)
        {
            MaterialMap map = maps[i];
            kk_raylib_raylib__materialMap kk_map = raylib_to_kk_materialMap(&map, ctx);
            p[i] = kk_raylib_raylib__materialMap_box(kk_map, ctx);
        }
    } else {
        kk_box_t* p;
        v = kk_vector_alloc_uninit(0, &p, ctx);
    }
    return v;
}

static kk_raylib_raylib__shader raylib_shader_to_kk(Shader shader, kk_context_t* ctx) {
    kk_integer_t kk_id = kk_integer_from_int32(shader.id, ctx);
    kk_vector_t kk_locs = raylib_to_kk_vector_int(RL_MAX_SHADER_LOCATIONS, shader.locs, ctx);
    return kk_raylib_raylib__new_Shader(kk_reuse_null, 0, kk_id, kk_locs, ctx);
}

static kk_raylib_raylib__material raylib_material_to_kk(Material mat, kk_context_t* ctx) {
    kk_raylib_raylib__shader kk_shader = raylib_shader_to_kk(mat.shader, ctx);
    kk_vector_t kk_maps = raylib_to_kk_vector_materialMap(mat.maps, ctx);
    kk_vector_t kk_params = raylib_to_kk_vector_float(4, mat.params, ctx);
    return kk_raylib_raylib__new_Material(kk_reuse_null, 0, kk_shader, kk_maps, kk_params, ctx);
}

static kk_raylib_raylib__material kk_raylib_LoadMaterialDefault(kk_context_t* ctx) {
    Material result = LoadMaterialDefault();
    kk_raylib_raylib__material kk_result = raylib_material_to_kk(result, ctx);
    return kk_result;
}

static bool kk_raylib_IsKeyPressed(kk_integer_t kk_key, kk_context_t *ctx)
{
    int key = kk_integer_clamp32(kk_key, ctx);
    return IsKeyPressed(key);
}

static bool kk_raylib_IsKeyDown(kk_integer_t kk_key, kk_context_t *ctx)
{
    int key = kk_integer_clamp32(kk_key, ctx);
    return IsKeyDown(key);
}

static void kk_raylib_SetExitKey(kk_integer_t kk_key, kk_context_t *ctx)
{
    int key = kk_integer_clamp32(kk_key, ctx);
    SetExitKey(key);
}

static bool kk_raylib_IsMouseButtonPressed(kk_integer_t kk_button, kk_context_t *ctx)
{
    int button = kk_integer_clamp32(kk_button, ctx);
    return IsMouseButtonPressed(button);
}

static kk_raylib_raylib__vector2 kk_raylib_GetMousePosition(kk_context_t* ctx) {
    Vector2 mousePos = GetMousePosition();
    return kk_raylib_raylib__new_Vector2(kk_reuse_null, 0, mousePos.x, mousePos.y, ctx);
}

static kk_raylib_raylib__vector2 kk_raylib_GetMouseDelta(kk_context_t* ctx) {
    Vector2 mouseDelta = GetMouseDelta();
    return kk_raylib_raylib__new_Vector2(kk_reuse_null, 0, mouseDelta.x, mouseDelta.y, ctx);
}

static void kk_raylib_GuiSetStyle(kk_integer_t kk_rl_control, kk_integer_t kk_property, kk_integer_t kk_value, kk_context_t* ctx) {
    int control = kk_integer_clamp32(kk_rl_control, ctx);
    int property = kk_integer_clamp32(kk_property, ctx);
    int value = kk_integer_clamp32(kk_value, ctx);

    GuiSetStyle(control, property, value);
}

static Camera3D kk_to_c_camera3D(kk_raylib_raylib__camera3D kk_camera, kk_context_t *ctx) {
    kk_raylib_raylib__vector3 kk_pos = kk_raylib_raylib_camera3D_fs_position(kk_camera, ctx);
    kk_raylib_raylib__vector3 kk_target = kk_raylib_raylib_camera3D_fs_target(kk_camera, ctx);
    kk_raylib_raylib__vector3 kk_up = kk_raylib_raylib_camera3D_fs_up(kk_camera, ctx);

    Vector3 pos = kk_to_c_vector3(kk_pos, ctx);
    Vector3 target = kk_to_c_vector3(kk_target, ctx);
    Vector3 up = kk_to_c_vector3(kk_up, ctx);

    float fovy = kk_raylib_raylib_camera3D_fs_fovy(kk_camera, ctx);
    
    kk_integer_t kk_projection = kk_raylib_raylib_camera3D_fs_projection(kk_camera, ctx);
    int projection = kk_integer_clamp32(kk_projection, ctx);

    Camera3D camera;
    camera.position = pos;
    camera.target = target;
    camera.up = up;
    camera.fovy = fovy;
    camera.projection = projection;

    return camera;
}

static void kk_raylib_BeginMode3D(kk_raylib_raylib__camera3D kk_camera, kk_context_t *ctx) {
    Camera3D camera = kk_to_c_camera3D(kk_camera, ctx);
    BeginMode3D(camera);
}

static void kk_raylib_EndMode3D(kk_context_t *ctx) {
    EndMode3D();
}

static Rectangle kk_rectangle_from_kk(kk_raylib_raylib__rectangle kk_rectangle, kk_context_t* ctx) {
    Rectangle rect;
    rect.x = kk_raylib_raylib_rectangle_fs_x( kk_rectangle, ctx );
    rect.y = kk_raylib_raylib_rectangle_fs_y( kk_rectangle, ctx );
    rect.width = kk_raylib_raylib_rectangle_fs_width( kk_rectangle, ctx );
    rect.height = kk_raylib_raylib_rectangle_fs_height( kk_rectangle, ctx );
    return rect;
}

static bool kk_raylib_GuiButton(kk_raylib_raylib__rectangle kk_bounds, kk_string_t kk_text, kk_context_t* ctx) {
    Rectangle bounds = kk_rectangle_from_kk(kk_bounds, ctx);
    const char* text = kk_string_cbuf_borrow(kk_text, NULL, ctx);

    bool res = GuiButton(bounds, text);

    kk_string_drop(kk_text, ctx);

    return res;
}

static kk_std_core_types__tuple2 kk_raylib_GuiTextBox(kk_raylib_raylib__rectangle kk_bounds, kk_string_t kk_text, kk_integer_t kk_buffer_size, bool kk_edit_mode, kk_context_t* ctx) {
    Rectangle bounds = kk_rectangle_from_kk(kk_bounds, ctx);

    const char* text = kk_string_cbuf_borrow(kk_text, NULL, ctx);

    int buffer_size = kk_integer_clamp32(kk_buffer_size, ctx);

    char* buffer = (char*)malloc(buffer_size);
    
    int cpy_size = kk_integer_clamp32(kk_string_len_int( kk_text, ctx ), ctx);
    if( cpy_size > buffer_size )
        cpy_size = buffer_size;

    strncpy(buffer, text, cpy_size);
    buffer[cpy_size] = 0;

    int is_clicked = GuiTextBox(bounds, buffer, buffer_size, kk_edit_mode);
    kk_string_t new_text = kk_string_alloc_from_qutf8( buffer, ctx );

    kk_string_drop(kk_text, ctx);

    return kk_std_core_types__new_Tuple2(kk_string_box(new_text), kk_bool_box(is_clicked), ctx);
}
