#include <stdio.h>
#include <stdlib.h>
static int st[4096], sp; static int nh = 100000;
int cqrt_sp(void) { return sp; }
void cqrt_push(int h) { st[sp++] = h; }
int cqrt_pop(void) { if (!sp) { puts("POP EMPTY"); exit(9); } return st[--sp]; }
void cqrt_not_i1(int h) { printf("cqrt_not_i1(h%d)\n", h); }
/* CR rule 17 (2026-11-02): cq_invert is a run-time region; the backend reverses and inverts the gates recorded between the two calls. */
void cqrt_invert_begin(void) { puts("cqrt_invert_begin()"); }
void cqrt_invert_end(void) { puts("cqrt_invert_end()"); }
void cqrt_and_i1(int a, int b, int t) { printf("cqrt_and_i1(h%d, h%d, h%d)\n", a, b, t); }
void cqrt_or_i1(int a, int b, int t) { printf("cqrt_or_i1(h%d, h%d, h%d)\n", a, b, t); }
#define SEL(N, TA, TB, FA, FB) int cq_template_select_i32##N(int c, TA a, TB b) { int h = nh++; printf("cq_template_select_i32" #N "(h%d, " FA ", " FB ") -> h%d\n", c, a, b, h); return h; } \
  void cq_template_select_i32##N##_unc(int o, int c, TA a, TB b) { printf("cq_template_select_i32" #N "_unc(h%d, h%d, " FA ", " FB ")\n", o, c, a, b); }
SEL(, int, int, "h%d", "h%d") SEL(_hl, int, int, "h%d", "%d") SEL(_lh, int, int, "%d", "h%d") SEL(_ll, int, int, "%d", "%d")

/* bd 94ad E3: a rotation by a QUANTUM angle. The angle is an f64 register (IEEE bits on a rail); the backend supplies the
 * decoded bit-controlled ladder (exact: Ry(a)Ry(b) = Ry(a+b)); the angle register is only read. */
#define QANG(W) void cqrt_ry_##W##_qangle(int h, int a) { printf("cqrt_ry_" #W "_qangle(h%d, h%d)\n", h, a); } \
  void cqrt_ry_##W##_qangle_controlled(int c, int h, int a) { printf("cqrt_ry_" #W "_qangle_controlled(h%d, h%d, h%d)\n", c, h, a); }
QANG(i1) QANG(i8) QANG(i16) QANG(i32) QANG(i64) QANG(f32) QANG(f64)
void cqrt_rz_qangle(int a) { printf("cqrt_rz_qangle(h%d)\n", a); }
void cqrt_rz_qangle_controlled(int c, int a) { printf("cqrt_rz_qangle_controlled(h%d, h%d)\n", c, a); }
/* QRAM (owner 2026-10-25): a quantum-index store / a cell holding a quantum value makes the object a QRAM; the per-cell
 * flag+select ladder moved into the backend. alloc / load / load_hl / store / store_hl / store_controlled and their _unc
 * come from the old repo's libcq_runtime.a, whose header is the contract: the array handle prints a<N>; idx is a
 * logical-i32 handle, or a classical literal in the _hl forms (_hl = classical INDEX); a store value is ALWAYS a handle (a
 * classical value is materialised by cqrt_alloc_<W>); a store displaces the old cell onto a backend tape and its _unc pops
 * it, LIFO per array. These stubs add the controlled forms the runtime lacks and the free of an all-|0> array. */
static int na = 1000;   /* bus ids minted by qram_realloc */
#define QR(W) void cqrt_qram_store_##W##_hl_controlled(int c, int a, int j, int v) { printf("cqrt_qram_store_" #W "_hl_controlled(h%d, a%d, %d, h%d)\n", c, a, j, v); } \
  void cqrt_qram_store_##W##_hl_controlled_unc(int c, int a, int j, int v) { printf("cqrt_qram_store_" #W "_hl_controlled_unc(h%d, a%d, %d, h%d)\n", c, a, j, v); } \
  int cqrt_qram_load_##W##_controlled(int c, int a, int i) { int h = nh++; printf("cqrt_qram_load_" #W "_controlled(h%d, a%d, h%d) -> h%d\n", c, a, i, h); return h; } \
  void cqrt_qram_load_##W##_controlled_unc(int o, int c, int a, int i) { printf("cqrt_qram_load_" #W "_controlled_unc(h%d, h%d, a%d, h%d)\n", o, c, a, i); } \
  int cqrt_qram_load_##W##_hl_controlled(int c, int a, int j) { int h = nh++; printf("cqrt_qram_load_" #W "_hl_controlled(h%d, a%d, %d) -> h%d\n", c, a, j, h); return h; } \
  void cqrt_qram_load_##W##_hl_controlled_unc(int o, int c, int a, int j) { printf("cqrt_qram_load_" #W "_hl_controlled_unc(h%d, h%d, a%d, %d)\n", o, c, a, j);  } \
  int cqrt_qram_realloc_##W(int a, int n) { int b = na++; printf("cqrt_qram_realloc_" #W "(a%d, %d) -> a%d\n", a, n, b); return b; } \
  void cqrt_qram_realloc_##W##_unc(int b, int n) { printf("cqrt_qram_realloc_" #W "_unc(a%d, %d)\n", b, n); }
QR(i8) QR(i32) QR(i64)
void cqrt_qram_free(int a) { printf("cqrt_qram_free(a%d)\n", a); }
void cqrt_xor_i1(int a, int t) { printf("cqrt_xor_i1(h%d, h%d)\n", a, t); }
int cq_template_qrom_load_i32(const int *t, long long n, int idx) { int h = nh++; printf("cq_template_qrom_load_i32(table, %lld, h%d) -> h%d\n", n, idx, h); return h; }
void cq_template_qrom_load_i32_unc(int o, const int *t, long long n, int idx) { printf("cq_template_qrom_load_i32_unc(h%d, table, %lld, h%d)\n", o, n, idx); }

void cqrt_abort_i1(int h) { printf("cqrt_abort_i1(h%d)\n", h); }
static void pfmt(const char *f) { for (; *f; f++) { if (*f == '\n') printf("\\n"); else putchar(*f); } }
void cqrt_tape_fmt(int t, const char *f) { printf("cqrt_tape_fmt(t%d, \"", t); pfmt(f); printf("\")\n"); }
void cqrt_tape_fmt_controlled(int c, int t, const char *f) { printf("cqrt_tape_fmt_controlled(h%d, t%d, \"", c, t); pfmt(f); printf("\")\n"); }
void cqrt_tape_write_i32_lit(int t, int v) { printf("cqrt_tape_write_i32_lit(t%d, %d)\n", t, v); }

/* --- added 2026-10-18 for examples 48-65 --- */

#define SELW(W, N, TA, TB, FA, FB) int cq_template_select_##W##N(int c, TA a, TB b) { int h = nh++; printf("cq_template_select_" #W #N "(h%d, " FA ", " FB ") -> h%d\n", c, a, b, h); return h; } \
  void cq_template_select_##W##N##_unc(int o, int c, TA a, TB b) { printf("cq_template_select_" #W #N "_unc(h%d, h%d, " FA ", " FB ")\n", o, c, a, b); }
SELW(f64, , int, int, "h%d", "h%d") SELW(f64, _hl, int, double, "h%d", "%g") SELW(f64, _lh, double, int, "%g", "h%d") SELW(f64, _ll, double, double, "%g", "%g")
SELW(i64, , int, int, "h%d", "h%d") SELW(i64, _hl, int, long long, "h%d", "%lld") SELW(i64, _lh, long long, int, "%lld", "h%d")
SELW(i1, , int, int, "h%d", "h%d") SELW(i1, _hl, int, int, "h%d", "%d") SELW(i1, _lh, int, int, "%d", "h%d")
SELW(f80, , int, int, "h%d", "h%d")
int cq_template_qrom_load_f64(const double *t, long long n, int idx) { int h = nh++; printf("cq_template_qrom_load_f64(table, %lld, h%d) -> h%d\n", n, idx, h); return h; }
void cq_template_qrom_load_f64_unc(int o, const double *t, long long n, int idx) { printf("cq_template_qrom_load_f64_unc(h%d, table, %lld, h%d)\n", o, n, idx); }
/* 72: byte-cell select */
SELW(i8, _lh, signed char, int, "%d", "h%d")

/* --- added for examples 76-79: strided QROM over an array of structs --- */
int cq_template_qrom_load_i32_s(const void *b, long long n, long long st, int idx) { int h = nh++; printf("cq_template_qrom_load_i32_s(base, %lld, %lld, h%d) -> h%d\n", n, st, idx, h); return h; }
void cq_template_qrom_load_i32_s_unc(int o, const void *b, long long n, long long st, int idx) { printf("cq_template_qrom_load_i32_s_unc(h%d, base, %lld, %lld, h%d)\n", o, n, st, idx); }
int cq_template_qrom_load_f64_s(const void *b, long long n, long long st, int idx) { int h = nh++; printf("cq_template_qrom_load_f64_s(base, %lld, %lld, h%d) -> h%d\n", n, st, idx, h); return h; }
void cq_template_qrom_load_f64_s_unc(int o, const void *b, long long n, long long st, int idx) { printf("cq_template_qrom_load_f64_s_unc(h%d, base, %lld, %lld, h%d)\n", o, n, st, idx); }

/* 80-82: full fenv. _rm = classical rounding mode operand (last), _rmq = mode handle (last), _exc = the op's exception bits */
#define FENV_HL(N, MF) int cq_template_##N(int a, double b, int m) { int h = nh++; printf("cq_template_" #N "(h%d, %a, " MF ") -> h%d\n", a, b, m, h); return h; } \
  void cq_template_##N##_unc(int o, int a, double b, int m) { printf("cq_template_" #N "_unc(h%d, h%d, %a, " MF ")\n", o, a, b, m); }
FENV_HL(fmul_f64_hl_rm, "%d") FENV_HL(fmul_f64_hl_rm_exc, "%d") FENV_HL(fdiv_f64_hl_rm, "%d") FENV_HL(fdiv_f64_hl_rm_exc, "%d")
FENV_HL(fadd_f64_hl_rmq, "h%d")
int cq_template_fadd_f64_ll_rmq(double a, double b, int m) { int h = nh++; printf("cq_template_fadd_f64_ll_rmq(%a, %a, h%d) -> h%d\n", a, b, m, h); return h; }
void cq_template_fadd_f64_ll_rmq_unc(int o, double a, double b, int m) { printf("cq_template_fadd_f64_ll_rmq_unc(h%d, %a, %a, h%d)\n", o, a, b, m); }
int cq_template_fcmps_ogt_f64_hl_exc(int a, double b) { int h = nh++; printf("cq_template_fcmps_ogt_f64_hl_exc(h%d, %a) -> h%d\n", a, b, h); return h; }
void cq_template_fcmps_ogt_f64_hl_exc_unc(int o, int a, double b) { printf("cq_template_fcmps_ogt_f64_hl_exc_unc(h%d, h%d, %a)\n", o, a, b); }
#define FENV_QLL(N) int cq_template_##N(int a, double b, double c, int m) { int h = nh++; printf("cq_template_" #N "(h%d, %a, %a, %d) -> h%d\n", a, b, c, m, h); return h; } \
  void cq_template_##N##_unc(int o, int a, double b, double c, int m) { printf("cq_template_" #N "_unc(h%d, h%d, %a, %a, %d)\n", o, a, b, c, m); }
FENV_QLL(fma_f64_qll_rm) FENV_QLL(fma_f64_qll_rm_exc)

/* --- added for example 83: frem (fmod/fmodf/fmodl reach -O1 IR as the frem instruction) --- */
int cq_template_frem_f64_hl(int a, double b) { int h = nh++; printf("cq_template_frem_f64_hl(h%d, %a) -> h%d\n", a, b, h); return h; }
int cq_template_frem_f64_lh(double a, int b) { int h = nh++; printf("cq_template_frem_f64_lh(%a, h%d) -> h%d\n", a, b, h); return h; }
int cq_template_frem_f32(int a, int b) { int h = nh++; printf("cq_template_frem_f32(h%d, h%d) -> h%d\n", a, b, h); return h; }
int cq_template_frem_f80_hl(int a, long double b) { int h = nh++; printf("cq_template_frem_f80_hl(h%d, %La) -> h%d\n", a, b, h); return h; }

/* --- added for examples 84-85: a quantum pointer is a fat pointer (tag i32 rail, idx i64 rail) --- */
SELW(i64, _ll, long long, long long, "%lld", "%lld")
int cq_template_add_i64_lh(long long a, int b) { int h = nh++; printf("cq_template_add_i64_lh(%lld, h%d) -> h%d\n", a, b, h); return h; }
void cq_template_add_i64_lh_unc(int o, long long a, int b) { printf("cq_template_add_i64_lh_unc(h%d, %lld, h%d)\n", o, a, b); }

/* --- batch A (86-88): byte-cell selects for a quantum char buffer (87) and pointer-cell selects (88) --- */
SELW(i8, , int, int, "h%d", "h%d") SELW(i8, _ll, signed char, signed char, "%d", "%d") SELW(i8, _hl, int, signed char, "h%d", "%d")

/* --- batch C (92-95): the with.overflow flag twins (the value half is the plain opcode template) --- */
int cq_template_umul_overflow_i32_hl(int a, int b) { int h = nh++; printf("cq_template_umul_overflow_i32_hl(h%d, %d) -> h%d\n", a, b, h); return h; }
void cq_template_umul_overflow_i32_hl_unc(int o, int a, int b) { printf("cq_template_umul_overflow_i32_hl_unc(h%d, h%d, %d)\n", o, a, b); }
int cq_template_sadd_overflow_i32(int a, int b) { int h = nh++; printf("cq_template_sadd_overflow_i32(h%d, h%d) -> h%d\n", a, b, h); return h; }
void cq_template_sadd_overflow_i32_unc(int o, int a, int b) { printf("cq_template_sadd_overflow_i32_unc(h%d, h%d, h%d)\n", o, a, b); }

/* --- batch D (96-100): byte tape literal, fenv width variants --- */
void cqrt_tape_write_i8_lit(int t, signed char v) { printf("cqrt_tape_write_i8_lit(t%d, %d)\n", t, v); }
FENV_HL(fadd_f64_hl_rm, "%d") FENV_HL(fadd_f64_hl_rm_exc, "%d")
int cq_template_fadd_f64_ll_rmq_exc(double a, double b, int m) { int h = nh++; printf("cq_template_fadd_f64_ll_rmq_exc(%a, %a, h%d) -> h%d\n", a, b, m, h); return h; }
void cq_template_fadd_f64_ll_rmq_exc_unc(int o, double a, double b, int m) { printf("cq_template_fadd_f64_ll_rmq_exc_unc(h%d, %a, %a, h%d)\n", o, a, b, m); }

/* --- 102: effects under a quantum predicate (cqrt_tape_effect_controlled, accepted by the owner 2026-10-20) --- */
void cqrt_tape_effect_controlled(int c, int t, const char *name) { printf("cqrt_tape_effect_controlled(h%d, t%d, \"%s\")\n", c, t, name); }
void cqrt_tape_write_str_lit(int t, const char *s) { printf("cqrt_tape_write_str_lit(t%d, \"", t); pfmt(s); printf("\")\n"); }

/* --- 103-105: fp classification intrinsic (llvm.is.fpclass -> cq_template_is_fpclass_<W>_hl(h, mask), an i1 rail) --- */
int cq_template_is_fpclass_f64_hl(int a, int m) { int h = nh++; printf("cq_template_is_fpclass_f64_hl(h%d, %d) -> h%d\n", a, m, h); return h; }
void cq_template_is_fpclass_f64_hl_unc(int o, int a, int m) { printf("cq_template_is_fpclass_f64_hl_unc(h%d, h%d, %d)\n", o, a, m); }

/* --- 110: C23 _BitInt widths (i100, i7): templates exist per width on demand; the trace prints an i100 classical
 * operand as its two 64-bit hex halves (hi:lo), an i7 as an int --- */
typedef unsigned __int128 cq_u128;
static void p100(cq_u128 v) { printf("0x%llx:%llx", (unsigned long long)(v >> 64), (unsigned long long)v); }  /* unpadded: a 16-digit field would read as an address to make_trace's normaliser */
int cq_template_zext_i64_to_i100(int a) { int h = nh++; printf("cq_template_zext_i64_to_i100(h%d) -> h%d\n", a, h); return h; }
void cq_template_zext_i64_to_i100_unc(int o, int a) { printf("cq_template_zext_i64_to_i100_unc(h%d, h%d)\n", o, a); }
int cq_template_mul_i100_hl(int a, cq_u128 b) { int h = nh++; printf("cq_template_mul_i100_hl(h%d, ", a); p100(b); printf(") -> h%d\n", h); return h; }
void cq_template_mul_i100_hl_unc(int o, int a, cq_u128 b) { printf("cq_template_mul_i100_hl_unc(h%d, h%d, ", o, a); p100(b); printf(")\n"); }
int cq_template_lshr_i100_hl(int a, cq_u128 b) { int h = nh++; printf("cq_template_lshr_i100_hl(h%d, ", a); p100(b); printf(") -> h%d\n", h); return h; }
void cq_template_lshr_i100_hl_unc(int o, int a, cq_u128 b) { printf("cq_template_lshr_i100_hl_unc(h%d, h%d, ", o, a); p100(b); printf(")\n"); }
int cq_template_add_i100(int a, int b) { int h = nh++; printf("cq_template_add_i100(h%d, h%d) -> h%d\n", a, b, h); return h; }
void cq_template_add_i100_unc(int o, int a, int b) { printf("cq_template_add_i100_unc(h%d, h%d, h%d)\n", o, a, b); }
int cq_template_trunc_i100_to_i64(int a) { int h = nh++; printf("cq_template_trunc_i100_to_i64(h%d) -> h%d\n", a, h); return h; }
int cq_template_trunc_i64_to_i7(int a) { int h = nh++; printf("cq_template_trunc_i64_to_i7(h%d) -> h%d\n", a, h); return h; }
void cq_template_trunc_i64_to_i7_unc(int o, int a) { printf("cq_template_trunc_i64_to_i7_unc(h%d, h%d)\n", o, a); }
int cq_template_sext_i7_to_i32(int a) { int h = nh++; printf("cq_template_sext_i7_to_i32(h%d) -> h%d\n", a, h); return h; }
int cq_template_add_i7_hl(int a, int b) { int h = nh++; printf("cq_template_add_i7_hl(h%d, %d) -> h%d\n", a, b, h); return h; }
void cq_template_add_i7_hl_unc(int o, int a, int b) { printf("cq_template_add_i7_hl_unc(h%d, h%d, %d)\n", o, a, b); }
int cqrt_alloc_i7(int v) { int h = nh++; printf("cqrt_alloc_i7(%d) -> h%d\n", v, h); return h; }
void cqrt_copy_i7(int a, int t) { printf("cqrt_copy_i7(h%d, h%d)\n", a, t); }

/* --- 112: with.overflow width/op variants (92's value + flag twins) and the all-quantum funnel shift (56) --- */
int cq_template_uadd_overflow_i32_hl(int a, int b) { int h = nh++; printf("cq_template_uadd_overflow_i32_hl(h%d, %d) -> h%d\n", a, b, h); return h; }
void cq_template_uadd_overflow_i32_hl_unc(int o, int a, int b) { printf("cq_template_uadd_overflow_i32_hl_unc(h%d, h%d, %d)\n", o, a, b); }
int cq_template_usub_overflow_i64(int a, int b) { int h = nh++; printf("cq_template_usub_overflow_i64(h%d, h%d) -> h%d\n", a, b, h); return h; }
void cq_template_usub_overflow_i64_unc(int o, int a, int b) { printf("cq_template_usub_overflow_i64_unc(h%d, h%d, h%d)\n", o, a, b); }
int cq_template_fshr_i32(int a, int b, int c) { int h = nh++; printf("cq_template_fshr_i32(h%d, h%d, h%d) -> h%d\n", a, b, c, h); return h; }
void cq_template_fshr_i32_unc(int o, int a, int b, int c) { printf("cq_template_fshr_i32_unc(h%d, h%d, h%d, h%d)\n", o, a, b, c); }
int cq_template_fshl_i32(int a, int b, int c) { int h = nh++; printf("cq_template_fshl_i32(h%d, h%d, h%d) -> h%d\n", a, b, c, h); return h; }
void cq_template_fshl_i32_unc(int o, int a, int b, int c) { printf("cq_template_fshl_i32_unc(h%d, h%d, h%d, h%d)\n", o, a, b, c); }

/* --- 132-141 (2026-10-25): i128 compare/select width variants (134), the mixed-operand funnel shift (134), the f64 tape field (138) --- */
int cq_template_icmp_ugt_i128_hl(int a, cq_u128 b) { int h = nh++; printf("cq_template_icmp_ugt_i128_hl(h%d, ", a); p100(b); printf(") -> h%d\n", h); return h; }
void cq_template_icmp_ugt_i128_hl_unc(int o, int a, cq_u128 b) { printf("cq_template_icmp_ugt_i128_hl_unc(h%d, h%d, ", o, a); p100(b); printf(")\n"); }
int cq_template_select_i128(int c, int a, int b) { int h = nh++; printf("cq_template_select_i128(h%d, h%d, h%d) -> h%d\n", c, a, b, h); return h; }
void cq_template_select_i128_unc(int o, int c, int a, int b) { printf("cq_template_select_i128_unc(h%d, h%d, h%d, h%d)\n", o, c, a, b); }
int cq_template_fshl_i32_qll(int a, int b, int c) { int h = nh++; printf("cq_template_fshl_i32_qll(h%d, %d, %d) -> h%d\n", a, b, c, h); return h; }
int cqrt_tape_write_f64(int t, int src) { int h = nh++; printf("cqrt_tape_write_f64(t%d, h%d) -> h%d\n", t, src, h); return h; }

/* --- 91 (2026-10-26, rule 16): free under a quantum predicate is a tape entry; its host-pointer argument is a classical i64 field --- */
void cqrt_tape_write_i64_lit(int t, long long v) { printf("cqrt_tape_write_i64_lit(t%d, %lld)\n", t, v); }

/* --- 161 (2026-10-26, rule 19): an opaque external callee receives the RAW HANDLE of a quantum argument; its result is classical garbage. The driver cannot define it (the 4th driver field runs inside main) --- */
/* rule 27 declared clones of 161 and 190 (trailing K argument): stand-ins for a linked lowered library */
int __cq_q_ext_fn_10(int a, int b, int k) { int h = nh++; printf("__cq_q_ext_fn_10(h%d, %d, %d) -> h%d\n", a, b, k, h); return h; }
void __cq_q_ext_fn_10_unc(int o, int a, int b, int k) { printf("__cq_q_ext_fn_10_unc(h%d, h%d, %d, %d)\n", o, a, b, k); }

/* --- 169-175 (2026-10-26, complex/libm clones): f32 and f80 select shapes the trace runtime lacks, and the two 175 clones whose
 * bodies are the injected musl exp/atan2 (not shown in the corpus; a stub prints the call so the trace links) --- */
SELW(f32, , int, int, "h%d", "h%d") SELW(f32, _ll, float, float, "%a", "%a") SELW(f80, _ll, long double, long double, "%La", "%La")
int __cq_q_exp_1(int x) { int h = nh++; printf("__cq_q_exp_1(h%d) -> h%d\n", x, h); return h; }
void __cq_q_exp_1_unc(int o, int x) { printf("__cq_q_exp_1_unc(h%d, h%d)\n", o, x); }
int __cq_q_atan2_10(int x, double y) { int h = nh++; printf("__cq_q_atan2_10(h%d, %a) -> h%d\n", x, y, h); return h; }
void __cq_q_atan2_10_unc(int o, int x, double y) { printf("__cq_q_atan2_10_unc(h%d, h%d, %a)\n", o, x, y); }
int __cq_q_sin_1(int x) { int h = nh++; printf("__cq_q_sin_1(h%d) -> h%d\n", x, h); return h; }
void __cq_q_sin_1_unc(int o, int x) { printf("__cq_q_sin_1_unc(h%d, h%d)\n", o, x); }
int __cq_q_log_1(int x) { int h = nh++; printf("__cq_q_log_1(h%d) -> h%d\n", x, h); return h; }
void __cq_q_log_1_unc(int o, int x) { printf("__cq_q_log_1_unc(h%d, h%d)\n", o, x); }
int __cq_q_pow_10(int x, double y) { int h = nh++; printf("__cq_q_pow_10(h%d, %a) -> h%d\n", x, y, h); return h; }
void __cq_q_pow_10_unc(int o, int x, double y) { printf("__cq_q_pow_10_unc(h%d, h%d, %a)\n", o, x, y); }

/* merged from stubs.d/190_memmove_memcmp_escape.c */
#include <stdio.h>
/* 190: the opaque external callee (rule 19). It receives the raw slot memory: n i32 handles. Prints them, writes nothing. */
void __cq_q_ext_sink_0010(int *p, int tag, int idx, int n_cells, int n, int k) { printf("__cq_q_ext_sink_0010(cells:"); for (int i = 0; i < n_cells; i++) printf(" h%d", p[i]); printf(", %d, %d, %d, %d, %d)\n", tag, idx, n_cells, n, k); }
void __cq_q_ext_sink_0010_unc(int *p, int tag, int idx, int n_cells, int n, int k, int *snap) { printf("__cq_q_ext_sink_0010_unc(cells:"); for (int i = 0; i < n_cells; i++) printf(" h%d", p[i]); printf(", %d, %d, %d, %d, %d)\n# twin snapshot:", tag, idx, n_cells, n, k); for (int i = 0; i < n_cells; i++) printf(" h%d", snap[i]); printf("\n"); }
