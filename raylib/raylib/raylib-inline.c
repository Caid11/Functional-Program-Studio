#include <raylib.h>

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

static void kk_raylib_ClearBackground(kk_context_t* ctx) {
    ClearBackground(RAYWHITE);
}

static void kk_raylib_DrawText(kk_string_t text, kk_integer_t posX, kk_integer_t posY, kk_integer_t fontSize, kk_context_t* ctx) {
    const char* text_cstr = kk_string_cbuf_borrow(text, NULL, ctx);
    int posX_cint = kk_integer_clamp32(posX, ctx);
    int posY_cint = kk_integer_clamp32(posY, ctx);
    int fontSize_cint = kk_integer_clamp32(fontSize, ctx);

    DrawText(text_cstr, posX_cint, posY_cint, fontSize_cint, LIGHTGRAY);
}