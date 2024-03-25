//================================================================================
// Logging 

#include <stdarg.h>

// NBNet relies on the client to define logging functions. To make things
// simpler, we'll just define them to be printf.

enum
{
    LOG_INFO,
    LOG_ERROR,
    LOG_DEBUG,
    LOG_TRACE,
    LOG_WARNING
};

static const char *log_type_strings[] = {
    "INFO",
    "ERROR",
    "DEBUG",
    "TRACE",
    "WARNING"
};

// Basic logging function
void Log(int type, const char *fmt, ...)
{
    va_list args;

    va_start(args, fmt);

    printf("[%s] ", log_type_strings[type]);
    vprintf(fmt, args);
    printf("\n");

    va_end(args);
}

#define NBN_LogInfo(...) Log(LOG_INFO,  __VA_ARGS__)
#define NBN_LogError(...) Log(LOG_ERROR, __VA_ARGS__)
#define NBN_LogDebug(...) Log(LOG_DEBUG, __VA_ARGS__)
#define NBN_LogTrace(...) Log(LOG_TRACE, __VA_ARGS__)
#define NBN_LogWarning(...) Log(LOG_WARNING, __VA_ARGS__)

// End logging
//================================================================================

#define NBNET_IMPL
#include <nbnet.h>

static uint8_t* kk_vector_to_bytes(kk_vector_t vec, int* length, kk_context_t* ctx) {
    kk_ssize_t kk_length;
    kk_box_t* ptr = kk_vector_buf_borrow(vec, &kk_length, ctx);

    *length = (int)kk_length;

    uint8_t* bytes = (uint8_t*)malloc(kk_length);

    for (kk_ssize_t i = 0; i < kk_length; i++) {
        // TODO: KK_BORROWED or KK_OWNED?
        bytes[i] = kk_char_unbox(ptr[i], KK_BORROWED, ctx);
    }

    kk_vector_drop(vec,ctx);

    return bytes;
}

static kk_integer_t kk_nbnet_gameServer_sendReliableByteArrayTo(kk_integer_t kk_connection_handle,
                                                                kk_vector_t kk_bytes,
                                                                kk_context_t* ctx) {
    int length;
    uint8_t *bytes = kk_vector_to_bytes(kk_bytes, &length, ctx); 

    NBN_ConnectionHandle connection_handle = kk_integer_clamp32(kk_connection_handle, ctx);

    int res = NBN_GameServer_SendReliableByteArrayTo(connection_handle, bytes, length);

    free(bytes);

    return kk_integer_from_int32(res, ctx);
}

static kk_nbnet_nbnet__messageInfo kk_nbnet_GameServer_GetMessageInfo(kk_context_t* ctx)
{
    NBN_MessageInfo info = NBN_GameServer_GetMessageInfo();

    kk_integer_t ty = kk_integer_from_uint32(info.type, ctx);
    kk_integer_t channel_id = kk_integer_from_uint32(info.channel_id, ctx);
    int64_t data = (int64_t)info.data;
    kk_integer_t sender = kk_integer_from_uint32(info.sender, ctx);
    return kk_nbnet_nbnet__new_MessageInfo(kk_reuse_null, 0, ty, channel_id, data, sender, ctx);
}

static kk_vector_t kk_nbnet_message_to_byte_vector(int64_t ptr, kk_context_t* ctx) {
    NBN_ByteArrayMessage *msg = (NBN_ByteArrayMessage *)ptr;

    kk_box_t* vec_ptr;
    kk_vector_t vec = kk_vector_alloc_uninit(msg->length, &vec_ptr, ctx);

    for (unsigned int i = 0; i < msg->length; i++) {
        kk_char_t curr_byte = msg->bytes[i];
        kk_box_t curr_boxed_val = kk_char_box(curr_byte, ctx);
        vec_ptr[i] = curr_boxed_val;
    }

    return vec;
}