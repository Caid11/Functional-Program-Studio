#include <raylib.h>

#define RAYGUI_IMPLEMENTATION
#include <raygui.h>
#undef RAYGUI_IMPLEMENTATION

static void kk_raylib_InitWindow(kk_integer_t width, kk_integer_t height, kk_string_t window_name, kk_context_t* ctx) {
    const char* window_name_cstr = kk_string_cbuf_borrow(window_name, NULL, ctx);
    InitWindow(kk_integer_clamp32(width, ctx), kk_integer_clamp32(height, ctx), window_name_cstr);
}

static void kk_raylib_SetTargetFPS(kk_integer_t fps, kk_context_t* ctx) {
    SetTargetFPS(kk_integer_clamp32(fps, ctx));
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

static Color kk_color_from_kk(kk_raylib_raylib__color kk_color, kk_context_t* ctx) {
    Color color;
    color.a = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_a(kk_color, ctx), ctx );
    color.r = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_r(kk_color, ctx), ctx );
    color.g = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_g(kk_color, ctx), ctx );
    color.b = kk_integer_clamp_byte( kk_raylib_raylib_color_fs_b(kk_color, ctx), ctx );

    return color;
}

static void kk_raylib_ClearBackground(kk_raylib_raylib__color kk_color, kk_context_t* ctx) {
    Color color = kk_color_from_kk(kk_color, ctx);
    ClearBackground(color);
}

// TODO: Plumb through text color
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
    Color color = kk_color_from_kk(kk_color, ctx);

    DrawText(text, posX, posY, fontSize, color);
}

static kk_integer_t kk_raylib_MeasureText(kk_string_t text, kk_integer_t fontSize, kk_context_t* ctx) {
    const char* text_cstr = kk_string_cbuf_borrow(text, NULL, ctx);
    int fontSize_cint = kk_integer_clamp32(fontSize, ctx);

    int res = MeasureText(text_cstr, fontSize_cint);
    kk_integer_t kk_res = kk_integer_from_int32(res, ctx);
    return kk_res;
}

static kk_raylib_raylib__texture kk_raylib_LoadTexture(kk_string_t kk_fileName, kk_context_t* ctx) {
    const char* fileName = kk_string_cbuf_borrow(kk_fileName, NULL, ctx);

    Texture2D res = LoadTexture(fileName);

    kk_integer_t kk_id = kk_integer_from_uint32(res.id, ctx);
    kk_integer_t kk_width = kk_integer_from_int32(res.width, ctx);
    kk_integer_t kk_height = kk_integer_from_int32(res.height, ctx);
    kk_integer_t kk_mipmaps = kk_integer_from_int32(res.mipmaps, ctx);
    kk_integer_t kk_format = kk_integer_from_int32(res.format, ctx);

    return kk_raylib_raylib__new_Texture(kk_reuse_null, 0, kk_id, kk_width, kk_height, kk_mipmaps, kk_format, ctx);
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

    Color tint = kk_color_from_kk(kk_color, ctx);

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

    Color tint = kk_color_from_kk(kk_tint, ctx);

    DrawTextureEx(texture, position, rotation, scale, tint);
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

static void kk_raylib_GuiSetStyle(kk_integer_t kk_rl_control, kk_integer_t kk_property, kk_integer_t kk_value, kk_context_t* ctx) {
    int control = kk_integer_clamp32(kk_rl_control, ctx);
    int property = kk_integer_clamp32(kk_property, ctx);
    int value = kk_integer_clamp32(kk_value, ctx);

    GuiSetStyle(control, property, value);
}
static bool kk_raylib_GuiButton(kk_raylib_raylib__rectangle kk_bounds, kk_string_t kk_text, kk_context_t* ctx) {
    Rectangle bounds;
    bounds.x = kk_raylib_raylib_rectangle_fs_x( kk_bounds, ctx );
    bounds.y = kk_raylib_raylib_rectangle_fs_y( kk_bounds, ctx );
    bounds.width = kk_raylib_raylib_rectangle_fs_width( kk_bounds, ctx );
    bounds.height = kk_raylib_raylib_rectangle_fs_height( kk_bounds, ctx );

    const char* text = kk_string_cbuf_borrow(kk_text, NULL, ctx);

    return GuiButton(bounds, text);
}