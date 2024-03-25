#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>

// TODO: Set all sockets to NON BLOCKING

static kk_integer_t kk_socket_socket_init(kk_context_t* ctx) {
    WSADATA wsaData;
    int result = WSAStartup(MAKEWORD(2,2), &wsaData);
    
    return kk_integer_from_int32(result, ctx);
}

static int64_t kk_socket_create_socket(kk_context_t* ctx) {
    SOCKET res = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    return res;
}

kk_integer_t kk_socket_bind(int64_t socket, kk_string_t kk_address, kk_integer_t kk_port, kk_context_t* ctx) {
    const char* address = kk_string_cbuf_borrow(kk_address, NULL, ctx);
    int port = kk_integer_clamp32(kk_port, ctx);

    struct addrinfo *result = NULL;
    int addr_res = getaddrinfo(address, port, NULL, &result);
    if (addr_res) {
        kk_string_drop(kk_address, ctx);
        return kk_integer_from_int32(addr_res);
    }

    kk_string_drop(kk_address, ctx);

    int bind_res = bin(socket, result->ai_addr, (int)result->ai_addrlen);

    freeaddrinfo(result);
    return kk_integer_from_int32(bind_res);
}