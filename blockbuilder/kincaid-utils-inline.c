kk_string_t kk_ks_string_from_chars(kk_vector_t v, kk_context_t* ctx) {
  kk_ssize_t n;
  kk_box_t* cs = kk_vector_buf_borrow(v, &n, ctx);
  kk_ssize_t len = 0;
  for (kk_ssize_t i = 0; i < n; i++) {
    len += kk_utf8_len(kk_char_unbox(cs[i], KK_BORROWED, ctx));
  }
  uint8_t* p;
  // kk_string_t s = kk_unsafe_string_alloc_buf(len + 1, &p, ctx);
  kk_string_t s = kk_unsafe_string_alloc_buf(len, &p, ctx);
  for (kk_ssize_t i = 0; i < n; i++) {
    kk_ssize_t count;
    kk_utf8_write(kk_char_unbox(cs[i], KK_BORROWED, ctx), p, &count);
    p += count;
  }
  kk_assert_internal(kk_string_buf_borrow(s, NULL, ctx) + n == p);
  kk_vector_drop(v, ctx);
  return s;
}