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

static void kk_raylib_ClearBackground(kk_raylib_raylib__raylib_Color kk_color, kk_context_t* ctx) {
    Color color;
    color.a = kk_integer_clamp_byte( kk_raylib_raylib_raylib_Color_fs_a(kk_color, ctx), ctx );
    color.r = kk_integer_clamp_byte( kk_raylib_raylib_raylib_Color_fs_r(kk_color, ctx), ctx );
    color.g = kk_integer_clamp_byte( kk_raylib_raylib_raylib_Color_fs_g(kk_color, ctx), ctx );
    color.b = kk_integer_clamp_byte( kk_raylib_raylib_raylib_Color_fs_b(kk_color, ctx), ctx );

    ClearBackground(color);
}

static void kk_raylib_DrawText(kk_string_t text, kk_integer_t posX, kk_integer_t posY, kk_integer_t fontSize, kk_context_t* ctx) {
    const char* text_cstr = kk_string_cbuf_borrow(text, NULL, ctx);
    int posX_cint = kk_integer_clamp32(posX, ctx);
    int posY_cint = kk_integer_clamp32(posY, ctx);
    int fontSize_cint = kk_integer_clamp32(fontSize, ctx);

    DrawText(text_cstr, posX_cint, posY_cint, fontSize_cint, LIGHTGRAY);
}

static void kk_raylib_GuiSetStyle(kk_integer_t kk_rl_control, kk_integer_t kk_property, kk_integer_t kk_value, kk_context_t* ctx) {
    int control = kk_integer_clamp32(kk_rl_control, ctx);
    int property = kk_integer_clamp32(kk_property, ctx);
    int value = kk_integer_clamp32(kk_value, ctx);

    GuiSetStyle(control, property, value);
}
static bool kk_raylib_GuiButton(kk_raylib_raylib__raylib_Rectangle kk_bounds, kk_string_t kk_text, kk_context_t* ctx) {
    Rectangle bounds;
    bounds.x = kk_raylib_raylib_raylib_Rectangle_fs_x( kk_bounds, ctx );
    bounds.y = kk_raylib_raylib_raylib_Rectangle_fs_y( kk_bounds, ctx );
    bounds.width = kk_raylib_raylib_raylib_Rectangle_fs_width( kk_bounds, ctx );
    bounds.height = kk_raylib_raylib_raylib_Rectangle_fs_height( kk_bounds, ctx );

    const char* text = kk_string_cbuf_borrow(kk_text, NULL, ctx);

    return GuiButton(bounds, text);
}