#define WIN32_LEAN_AND_MEAN

#include <windows.h>
#include <winsock2.h>
#include <ws2tcpip.h>

// TODO: Figure out a good way to pass errors back for functions with two or more calls with int return results

// winsock header location: c:\Program Files (x86)\Windows Kits\10\Include\10.0.22000.0\um\WinSock2.h

static kk_integer_t kk_socket_socket_init(kk_context_t* ctx) {
    WSADATA wsaData;
    int result = WSAStartup(MAKEWORD(2,2), &wsaData);
    
    return kk_integer_from_int32(result, ctx);
}

static kk_integer_t kk_socket_socket_shutdown(kk_context_t* ctx) {
    int result = WSACleanup();
    return kk_integer_from_int32(result, ctx);
}

static kk_integer_t kk_socket_socket_get_last_error(kk_context_t* ctx) {
    int err = WSAGetLastError();
    return kk_integer_from_int32(err, ctx);
}

// TODO: Switch to UDP

static int64_t kk_socket_create_socket(kk_context_t* ctx) {
    SOCKET res = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);

    // For now, just make all sockets non-blocking (we can generalize later if necessary)
    if (res != INVALID_SOCKET) {
        u_long blocking_mode = 1; // non-zero = non-blocking
        int blocking_res = ioctlsocket(res, FIONBIO, &blocking_mode);
        if (blocking_res != NO_ERROR)
            return INVALID_SOCKET;
    }

    return res;
}

kk_integer_t kk_socket_bind(int64_t socket, kk_string_t kk_address, kk_integer_t kk_port, kk_context_t* ctx) {
    const char* address = kk_string_cbuf_borrow(kk_address, NULL, ctx);
    int port = kk_integer_clamp32(kk_port, ctx);
    
    char port_str[10];
    itoa(port, port_str, 10);

    struct addrinfo *result = NULL;
    int addr_res = getaddrinfo(address, port_str, NULL, &result);
    if (addr_res) {
        kk_string_drop(kk_address, ctx);
        return kk_integer_from_int32(addr_res, ctx);
    }

    kk_string_drop(kk_address, ctx);

    int bind_res = bind(socket, result->ai_addr, (int)result->ai_addrlen);

    freeaddrinfo(result);
    return kk_integer_from_int32(bind_res, ctx);
}

kk_integer_t kk_socket_listen(int64_t socket, kk_context_t* ctx) {
    int listenResult = listen(socket, SOMAXCONN);
    return kk_integer_from_int32(listenResult, ctx);
}

int64_t kk_socket_accept(int64_t socket, kk_context_t* ctx) {
    int64_t clientSocket = accept(socket, NULL, NULL);
    return clientSocket;
}

kk_integer_t kk_socket_connect(int64_t socket, kk_string_t kk_address, kk_integer_t kk_port, kk_context_t* ctx) {
    const char* address = kk_string_cbuf_borrow(kk_address, NULL, ctx);
    int port = kk_integer_clamp32(kk_port, ctx);
    
    char port_str[10];
    itoa(port, port_str, 10);

    struct addrinfo *result = NULL;
    int addr_res = getaddrinfo(address, port_str, NULL, &result);
    if (addr_res) {
        kk_string_drop(kk_address, ctx);
        return kk_integer_from_int32(addr_res, ctx);
    }

    kk_string_drop(kk_address, ctx);

    int connect_res = connect(socket, result->ai_addr, (int)result->ai_addrlen);

    freeaddrinfo(result);
    return kk_integer_from_int32(connect_res, ctx);
}

kk_integer_t kk_socket_close(int64_t socket, kk_context_t* ctx) {
    int res = closesocket(socket);
    return kk_integer_from_int32(res, ctx);
}

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

kk_integer_t kk_socket_send(int64_t socket, kk_vector_t kk_bytes, kk_context_t* ctx) {
    int length;
    uint8_t *bytes = kk_vector_to_bytes(kk_bytes, &length, ctx); 

    int res = send(socket, (const char*)bytes, length, 0);

    free(bytes);
    return kk_integer_from_int32(res, ctx);
}

kk_vector_t kk_socket_recv(int64_t socket, kk_integer_t kk_num_bytes, kk_context_t* ctx) {
    int num_bytes = kk_integer_clamp32(kk_num_bytes, ctx);

    uint8_t *recv_buf = (uint8_t*)malloc(num_bytes);
    int res = recv(socket, (char*)recv_buf, num_bytes, 0);

    kk_box_t* vec_ptr;
    kk_vector_t vec = kk_vector_alloc_uninit(max(res, 0), &vec_ptr, ctx);

    for (int i = 0; i < res; i++) {
        kk_char_t curr_byte = recv_buf[i];
        kk_box_t curr_boxed_val = kk_char_box(curr_byte, ctx);
        vec_ptr[i] = curr_boxed_val;
    }

    free(recv_buf);
    return vec;
}

kk_integer_t kk_socket_shutdown(int64_t socket, kk_context_t* ctx) {
    int res = shutdown(socket, SD_SEND);
    return kk_integer_from_int32(res, ctx);
}