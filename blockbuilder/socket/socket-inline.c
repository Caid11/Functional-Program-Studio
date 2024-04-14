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

static kk_string_t kk_socket_socket_get_error_string(kk_integer_t kk_err, kk_context_t* ctx) {
    int err = kk_integer_clamp32(kk_err, ctx);

    char msgbuf[256];
    msgbuf[255] = 0;

    FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM|FORMAT_MESSAGE_IGNORE_INSERTS,
                  NULL,
                  err,
                  MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                  msgbuf,
                  sizeof(msgbuf),
                  NULL);

    if (! *msgbuf)
        sprintf(msgbuf, "%d", err);

    return kk_string_alloc_from_qutf8(msgbuf, ctx);
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
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(address);

    int res = bind(socket, (SOCKADDR*)&addr, sizeof(addr));

    return kk_integer_from_int32(res, ctx);
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
    
    struct sockaddr_in addr;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(port);
    addr.sin_addr.s_addr = inet_addr(address);

    kk_string_drop(kk_address, ctx);

    int connect_res = connect(socket, (SOCKADDR*)&addr, sizeof(addr));

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

    for (kk_ssize_t i = 0; i < kk_length; i++)
        bytes[i] = kk_char_unbox(ptr[i], KK_BORROWED, ctx);

    kk_vector_drop(vec,ctx);

    return bytes;
}

kk_integer_t kk_socket_send_bytes(int64_t socket, kk_vector_t kk_bytes, kk_context_t* ctx) {
    int length;
    uint8_t *bytes = kk_vector_to_bytes(kk_bytes, &length, ctx); 

    int res = send(socket, (const char*)bytes, length, 0);

    free(bytes);
    return kk_integer_from_int32(res, ctx);
}

kk_std_core_types__tuple2 kk_socket_recv_bytes(int64_t socket, kk_integer_t kk_num_bytes, kk_context_t* ctx) {
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


    return kk_std_core_types__new_Tuple2(kk_integer_box(kk_integer_from_int32(res, ctx), ctx), kk_vector_box(vec, ctx), ctx);
}

kk_integer_t kk_socket_send_int(int64_t socket, kk_integer_t kk_v, kk_context_t* ctx) {
    int v = kk_integer_clamp32(kk_v, ctx);

    int res = send(socket, (const char*)&v, sizeof(int), 0);

    return kk_integer_from_int32(res, ctx);
}

kk_std_core_types__tuple2 kk_socket_recv_int(int64_t socket, kk_context_t* ctx) {
    int recv_buf;
    int res = recv(socket, (char*)&recv_buf, sizeof(int), 0);
    kk_integer_t kk_v = kk_integer_from_int32(recv_buf, ctx);

    return kk_std_core_types__new_Tuple2(kk_integer_box(kk_integer_from_int32(res, ctx), ctx), kk_integer_box(kk_v, ctx), ctx);
}

kk_integer_t kk_socket_send_float64(int64_t socket, double v, kk_context_t* ctx) {
    int res = send(socket, (const char*)&v, sizeof(double), 0);
    return kk_integer_from_int32(res, ctx);
}

kk_std_core_types__tuple2 kk_socket_recv_float64(int64_t socket, kk_context_t* ctx) {
    double recv_buf;
    int res = recv(socket, (char*)&recv_buf, sizeof(double), 0);
    return kk_std_core_types__new_Tuple2(kk_integer_box(kk_integer_from_int32(res, ctx), ctx), kk_double_box(recv_buf, ctx), ctx);
}

kk_integer_t kk_socket_shutdown(int64_t socket, kk_context_t* ctx) {
    int res = shutdown(socket, SD_SEND);
    return kk_integer_from_int32(res, ctx);
}

static fd_set kk_list_to_fd_set(kk_std_core_types__list kk_fds, kk_context_t* ctx) {
    fd_set fds;
    FD_ZERO(&fds);

    kk_std_core_types__list fds_it = kk_fds;
    while (kk_std_core_types__is_Cons(fds_it,ctx)) {
        struct kk_std_core_types_Cons* cons = kk_std_core_types__as_Cons(fds_it,ctx);

        SOCKET socket = kk_int64_unbox(cons->head, KK_BORROWED, ctx);
        FD_SET(socket, &fds);

        fds_it = cons->tail;
    }

    return fds;
}

static kk_std_core_types__list fd_set_to_kk_list(kk_std_core_types__list kk_fds, fd_set fds, kk_context_t* ctx) {
    // Collect sockets to check

    int num_sockets_to_check = 0;
    SOCKET sockets_to_check[255];

    kk_std_core_types__list fds_it = kk_fds;
    while (kk_std_core_types__is_Cons(fds_it,ctx)) {
        struct kk_std_core_types_Cons* cons = kk_std_core_types__as_Cons(fds_it,ctx);

        SOCKET socket = kk_int64_unbox(cons->head, KK_BORROWED, ctx);
        sockets_to_check[num_sockets_to_check++] = socket;

        fds_it = cons->tail;
    }
    
    // Construct list with all sockets from sockets_to_check that are in fds

    kk_std_core_types__list nil  = kk_std_core_types__new_Nil(ctx);
    struct kk_std_core_types_Cons* cons = NULL;
    kk_std_core_types__list list = kk_std_core_types__new_Nil(ctx);

    for (int i = 0; i < num_sockets_to_check; i++) {
        if (!FD_ISSET(sockets_to_check[i], &fds))
            continue;

        kk_box_t boxed_socket = kk_int64_box(sockets_to_check[i], ctx);
        kk_std_core_types__list head = kk_std_core_types__new_Cons(kk_reuse_null,0,boxed_socket, nil, ctx);
        if (cons == NULL)
            list = head;
        else
            cons->tail = head;
        
        cons = kk_std_core_types__as_Cons(head,ctx);
    }

    return list;
}

kk_std_core_types__tuple2 kk_socket_select(kk_std_core_types__list kk_readfds,
                                           kk_std_core_types__list kk_writefds,
                                           kk_std_core_types__list kk_exceptfds,
                                           bool block,
                                           kk_context_t* ctx) {
    // Create read and write sets
    fd_set readfds = kk_list_to_fd_set(kk_readfds, ctx);
    fd_set writefds = kk_list_to_fd_set(kk_writefds, ctx);
    fd_set exceptfds = kk_list_to_fd_set(kk_exceptfds, ctx);

    // Do select call

    int result;
    if (block) {
        result = select(0, &readfds, &writefds, &exceptfds, NULL);
    } else {
        TIMEVAL t = {0};
        result = select(0, &readfds, &writefds, &exceptfds, &t);
    }

    // Put read and write sets in result struct
    kk_std_core_types__list kk_resultreadfds = fd_set_to_kk_list(kk_readfds, readfds, ctx);
    kk_std_core_types__list kk_resultwritefds = fd_set_to_kk_list(kk_writefds, writefds, ctx);
    kk_std_core_types__list kk_resultexceptfds = fd_set_to_kk_list(kk_exceptfds, exceptfds, ctx);

    kk_socket_socket__selectResult kk_result_fds = kk_socket_socket__new_SelectResult(kk_reuse_null, 0, kk_resultreadfds, kk_resultwritefds, kk_resultexceptfds, ctx);

    return kk_std_core_types__new_Tuple2(kk_integer_box(kk_integer_from_int32(result, ctx), ctx), kk_socket_socket__selectResult_box(kk_result_fds, ctx), ctx);
}