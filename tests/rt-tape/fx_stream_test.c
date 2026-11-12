/* cq-dsnrs: fx_standin.h's stream model against musl's source (ungetc.c, ungetwc.c, getdelim.c), the plan and apply
 * functions both sides call. Built and run by test_fx_table.py; prints FAIL lines, exits 1 on any. */
#include "fx_standin.h"

static int fails;
#define CHECK(c, ...) do { if (!(c)) { printf("FAIL " __VA_ARGS__); printf("\n"); fails++; } } while (0)

static uint64_t call(const char *name, uint64_t v, uint64_t buf, uint64_t aux) {
  const cq_fx_ent *e = cq_fx_find(name);
  cq_fx_io io = cq_fx_input_plan(e, v, buf, 1, aux);
  cq_fx_input_done(&io);
  return io.result;
}
static int peek(uint64_t a, uint8_t *b) { *b = *(uint8_t *)(uintptr_t)a; return 1; }
static void store(uint64_t a, uint8_t b, int w, int c) { (void)c; if (w) *(uint8_t *)(uintptr_t)a = b; }

int main(void) {
  static const char in[] = "ab";
  cq_fx_stdin_set(in, 2);
  /* musl ungetc: at least UNGET (8) bytes of push-back, read last pushed first; the ninth is not modelled (fails) */
  CHECK(call("getc", 0, 0, 0) == 'a', "getc a");
  CHECK(call("ungetc", 0, 0, 'x') == 'x', "ungetc x");
  CHECK(call("ungetc", 0, 0, 'y') == 'y', "a second ungetc succeeds (musl ungetc.c)");
  CHECK(call("getc", 0, 0, 0) == 'y', "y first");
  CHECK(call("getc", 0, 0, 0) == 'x', "then x");
  CHECK(call("getc", 0, 0, 0) == 'b', "then the stream");
  for (int i = 0; i < 8; i++) CHECK(call("ungetc", 0, 0, '0' + i) == (uint64_t)('0' + i), "push-back %d", i);
  CHECK(call("ungetc", 0, 0, 'z') == 0xFFFFFFFFu, "a ninth fails (the model's limit)");
  char b4[4];
  CHECK(call("fgets", 4, (uint64_t)(uintptr_t)b4, 0) == (uint64_t)(uintptr_t)b4, "fgets over push-back");
  for (int i = 0; i < 5; i++) call("getc", 0, 0, 0);
  CHECK(call("getc", 0, 0, 0) == (uint64_t)(int64_t)EOF, "end after the push-back");
  /* musl ungetwc in the C locale: c < 0x80 its byte; 0xdf80..0xdfff its low byte; anything else WEOF */
  CHECK(call("ungetwc", 0, 0, 0xe9) == 0xFFFFFFFFu, "ungetwc(0xe9) WEOF (wcrtomb EILSEQ)");
  CHECK(call("ungetwc", 0, 0, 0x1e9) == 0xFFFFFFFFu, "ungetwc(0x1e9) WEOF, not its low byte");
  CHECK(call("ungetwc", 0, 0, 0xdfe9) == 0xdfe9, "ungetwc(0xdfe9)");
  CHECK(call("getc", 0, 0, 0) == 0xe9, "its byte 0xe9");
  /* musl getdelim at the end of file with *lineptr null: a buffer of 3, *n = 3, -1 */
  char *lp = NULL;
  size_t n = 0;
  const cq_fx_ent *g = cq_fx_find("getline");
  cq_fx_io io = cq_fx_input_plan(g, 0, 0, 1, 0);
  uint64_t r = cq_fx_input_apply(g, &io, 0, 0, 0, 1, 1, 1, (uint64_t)(uintptr_t)&lp, (uint64_t)(uintptr_t)&n, peek, store);
  cq_fx_input_done(&io);
  CHECK(r == UINT64_MAX && lp != NULL && n == 3, "getline at EOF: r %lld lp %p n %zu", (long long)r, (void *)lp, n);
  free(lp);
  /* one length rule: a negative int factor is 0; saturating */
  CHECK(cq_fx_len_mul(1, 0xffffffffu, 32) == 0, "negative int length");
  CHECK(cq_fx_len_mul(UINT64_C(1) << 40, UINT64_C(1) << 40, 64) == UINT64_MAX, "saturating");
  printf("%s\n", fails ? "fx stream: failures" : "fx stream: ok");
  return fails != 0;
}
