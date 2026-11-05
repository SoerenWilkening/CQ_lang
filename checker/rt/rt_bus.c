/* rt_bus.c: evaluator semantics of the one memory bus on basis values (CR §1.3, §2, rule 5; BACKEND_ABI §0, §1.10).
 *
 * The bus. One handle, minted by the one cqrt_qram_alloc_i8(0) (a second call or n != 0 is a violation). The
 * cell index is the x86-64 address, little-endian, addresses mod 2^64. W is any width token: S = ceil(N/8)
 * cells, f16/bf16 2, f32 4, f64 8, f80 10; an access reads the low N bits; a swap leaves the high bits of a
 * partial top cell where they are; a store writes the value zero-extended.
 *
 * The overlay. A cell is HOST or QUANTUM; this file's map holds only what QUANTUM cells hold, HOST cells live in
 * host memory and are read at each access (guarded: mach_vm_read_overwrite; a failure reads 0, so no bus access
 * ever faults). A store or swap whose address, control and resulting content are classical-valued writes host
 * bytes and leaves the cells HOST, unless the byte is not writable (mach_vm_region protection), which makes
 * the cell QUANTUM with no host write. Any other store or swap makes the cells it reaches on this basis branch
 * QUANTUM, keeping their content where a control reads 0 on this branch but is not classical-valued (the
 * branch where it reads 1 reaches them). A classical-valued control reading 0 touches nothing.
 *
 * Classical-valued (ABI §0) is the rail's known flag (core.c) and, for a QUANTUM cell, the cell's own: the
 * result of an access is known iff its address, control and cells are. HOST cells are known.
 *
 * Load _unc (ABI §1.10, rulings "Every _unc"): h ^= the cells, no residue check here: an overtaken copy is legal
 * and stays allocated (exit role overtaken). The check is at the following cqrt_free (dispatch.c gate_free):
 * legal iff known, and h is known afterwards iff it reads 0 with no non-diagonal gate on h or the operands since
 * (cqe__zero_rule) or h, the address, the control and the cells were all known (the classical XOR of "Classical-
 * valued _unc"). Its precondition (address and control at their forward values) is checked against the load
 * that made h (load_unc_args). A rotated or measured load copy is never un-copied (rule 5).
 *
 * The in-place form (rule 5, ABI §1.10 Undo 2): the rail the cells' 0 went to reads 0 after the second swap and is
 * freed, also under a control that is not classical-valued: a swap leaving h at 0 marks it (cqe__set_busz).
 *
 * Store (CR §1.3): a fresh tape slot t per call, as wide as the cells, holds the displaced content, |0> under
 * control 0; exit role tape_slot, never released. The value and control rails of a store have exit role store_kept
 * while they stay live (rule 5 sentence 3; a caller that passed them frees or uncomputes them by its own rules).
 *
 * Events. {"ev":"bus","op":"load|store|swap","w":W,"addr":<u64>,"c":0|1|-1,"host":0|1,"h":<handle>} with the
 * additive fields "v" (the value read, or the cells' new content, hex), "unc":1 on a load _unc and "t" (the slot) on
 * a store; h is the load copy, the swap's rail or the store's value rail. c is the control's basis value, -1 with no
 * control; host is 1 when every cell of the access is HOST after it. At the end of the shot
 * {"ev":"cells","q":[[addr,byte],...]} lists the QUANTUM cells by address. __cqe_out_mem logs one named output
 * read from the bus: {"ev":"out_mem","name":..,"w":"i<8*bytes>","v":..}, with no rail and no measurement. */
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "cqe.h"
#include "rt_tape.h"

/* core.c, dispatch.c */
uint32_t cqe__wtok_bits(const char *w, char *kind);
char *cqe__hexa(const cqe_val *v);
void cqe__init(void);
void cqe__logf(const char *fmt, ...);
void cqe__violation(const char *what, int32_t h, const char *fmt, ...);
int32_t cqe__new(const char *w, const cqe_val *init, int known, int seed);
int cqe__check(int32_t h, const char *ctx);
cqe_val *cqe__val(int32_t h);
const char *cqe__w(int32_t h);
int cqe__known(int32_t h);
void cqe__setknown(int32_t h, int k);
uint64_t cqe__created(int32_t h);
uint64_t cqe__last_nd(int32_t h);
int cqe__measured(int32_t h);
void cqe__setrole(int32_t h, int role);
void cqe__set_busz(int32_t h);
void cqe__set_store_kept(int32_t h);
void cqe__set_load_copy(int32_t h);
void cqe__mark_written(int32_t h);
void cqe__add_dep(int32_t h, int32_t src);
int cqe__val_iszero(const cqe_val *v);
void cqe__val_mask(cqe_val *v);
void cqe__val_init(cqe_val *v, uint32_t bits, char kind);
void cqe__val_free(cqe_val *v);
int cqe__zero_rule(int32_t d, const int32_t *src, int ns);

#define BUS_HANDLE 0x51000000 /* core.c: CQE_RAIL_LIMIT, no rail reaches it */
#define ROLE_TAPE_SLOT 4
#define ROLE_OVERTAKEN 5

static int bus_minted;

/* ---- the map of QUANTUM cells: open addressing; an entry whose cell went back to HOST stays, quantum 0 ---- */

typedef struct {
  uint64_t addr;
  uint8_t used, value, quantum, known;
} cell_t;
static cell_t *cells;
static size_t cells_cap, cells_used, cells_quantum;

static size_t cell_slot(const cell_t *tab, size_t cap, uint64_t addr) {
  size_t i = (size_t)((addr ^ (addr >> 29)) * 0x9E3779B97F4A7C15ULL) & (cap - 1);
  while (tab[i].used && tab[i].addr != addr)
    i = (i + 1) & (cap - 1);
  return i;
}

static cell_t *cell_find(uint64_t addr) {
  if (!cells_quantum)
    return NULL;
  cell_t *c = &cells[cell_slot(cells, cells_cap, addr)];
  return c->used && c->quantum ? c : NULL;
}

static cell_t *cell_get(uint64_t addr) {
  if (2 * (cells_used + 1) > cells_cap) {
    size_t cap = cells_cap ? 2 * cells_cap : 256;
    cell_t *tab = calloc(cap, sizeof *tab);
    if (!tab)
      abort();
    for (size_t i = 0; i < cells_cap; ++i)
      if (cells[i].used)
        tab[cell_slot(tab, cap, cells[i].addr)] = cells[i];
    free(cells);
    cells = tab;
    cells_cap = cap;
  }
  cell_t *c = &cells[cell_slot(cells, cells_cap, addr)];
  if (!c->used) {
    c->used = 1;
    c->addr = addr;
    ++cells_used;
  }
  return c;
}

static void cell_quantum(uint64_t addr, uint8_t value, int known) {
  cell_t *c = cell_get(addr);
  cells_quantum += !c->quantum;
  c->quantum = 1;
  c->value = value;
  c->known = known ? 1 : 0;
}

static void cell_host(uint64_t addr) {
  if (!cells_quantum)
    return;
  cell_t *c = &cells[cell_slot(cells, cells_cap, addr)];
  if (c->used && c->quantum) {
    c->quantum = 0;
    --cells_quantum;
  }
}

/* ---- host memory ------------------------------------------------------------------------- */

/* n bytes at addr; a byte that is not readable reads 0. */
static void host_read(uint64_t addr, size_t n, uint8_t *buf) {
  mach_vm_size_t got = 0;
  if (addr + n >= addr &&
      mach_vm_read_overwrite(mach_task_self(), addr, n, (mach_vm_address_t)buf, &got) == KERN_SUCCESS && got == n)
    return;
  for (size_t i = 0; i < n; ++i) {
    got = 0;
    if (mach_vm_read_overwrite(mach_task_self(), addr + i, 1, (mach_vm_address_t)&buf[i], &got) != KERN_SUCCESS || got != 1)
      buf[i] = 0;
  }
}

/* The writable region around one address, kept for the bytes of one access. */
typedef struct { uint64_t lo, hi; } wr_region;

static int host_writable(uint64_t a, wr_region *r) {
  if (a >= r->lo && a < r->hi)
    return 1;
  mach_vm_address_t ra = a;
  mach_vm_size_t rs = 0;
  vm_region_basic_info_data_64_t info;
  mach_msg_type_number_t cnt = VM_REGION_BASIC_INFO_COUNT_64;
  mach_port_t obj = MACH_PORT_NULL;
  if (mach_vm_region(mach_task_self(), &ra, &rs, VM_REGION_BASIC_INFO_64, (vm_region_info_t)&info, &cnt, &obj) != KERN_SUCCESS ||
      ra > a || a - ra >= rs || !(info.protection & VM_PROT_WRITE))
    return 0;
  r->lo = ra;
  r->hi = ra + rs;
  return 1;
}

/* ---- the cells of one access -------------------------------------------------------------- */

/* The S cells at addr into buf. Returns 1 iff all are classical-valued; *anyq: one of them is QUANTUM. */
static int cells_read(uint64_t addr, uint32_t S, uint8_t *buf, int *anyq) {
  int known = 1;
  *anyq = 0;
  host_read(addr, S, buf);
  if (!cells_quantum)
    return 1;
  for (uint32_t i = 0; i < S; ++i) {
    const cell_t *c = cell_find(addr + i);
    if (c) {
      buf[i] = c->value;
      known = known && c->known;
      *anyq = 1;
    }
  }
  return known;
}

/* The S cells at addr take buf. classical (top_classical for the last cell): the content is classical-valued and the
 * address and control are, so it goes to host memory if the byte is writable. 1 iff every cell is HOST afterwards. */
static int cells_write(uint64_t addr, uint32_t S, const uint8_t *buf, int classical, int top_classical) {
  wr_region r = {0, 0};
  int host = 1;
  for (uint32_t i = 0; i < S; ++i) {
    uint64_t a = addr + i;
    int cl = i + 1 == S ? top_classical : classical;
    if (cl && host_writable(a, &r)) {
      memcpy((void *)(uintptr_t)a, &buf[i], 1);
      cell_host(a);
    } else {
      cell_quantum(a, buf[i], cl);
      host = 0;
    }
  }
  return host;
}

/* A store or swap under a control that reads 0 here and is not classical-valued: the cells keep their content, QUANTUM. */
static void cells_reach(uint64_t addr, uint32_t S) {
  uint8_t b;
  for (uint32_t i = 0; i < S; ++i) {
    uint64_t a = addr + i;
    if (cell_find(a)) {
      cell_quantum(a, cell_find(a)->value, 0);
      continue;
    }
    host_read(a, 1, &b);
    cell_quantum(a, b, 0);
  }
}

/* ---- arguments ---------------------------------------------------------------------------- */

typedef struct {
  const cqe_tname *t;
  char sym[64];
  uint32_t bits, S;
  int32_t ctl_h, addr_h;
  uint64_t addr;
  int ctl;    /* has a control */
  int fire;   /* the control reads 1 on this branch, or there is none */
  int known;  /* address and control classical-valued */
  int ctl_known;
} access_t;

static int32_t arg_h(const cqe_val *v) { return (int32_t)(uint32_t)v->w[0]; }

static int rail_ok(const access_t *x, int32_t h, const char *w) {
  if (cqe__check(h, x->sym) != 0)
    return 0;
  if (strcmp(cqe__w(h), w) != 0) {
    cqe__violation("width_mismatch", h, "%s: rail %d is %s, expected %s", x->sym, (int)h, cqe__w(h), w);
    return 0;
  }
  return 1;
}

/* args from index i: [c,] m, addr. The next index, -1 after a violation. */
static int access_parse(access_t *x, const cqe_tname *t, const cqe_val *args, int nargs, int i, int extra) {
  memset(x, 0, sizeof *x);
  x->t = t;
  snprintf(x->sym, sizeof x->sym, "cqrt_%s_%s%s%s%s", t->op, t->w, t->shape[0] ? "_hl" : "", t->pred[0] ? "_controlled" : "",
           t->unc ? "_unc" : "");
  char kind = 0;
  x->bits = cqe__wtok_bits(t->w, &kind);
  if (!x->bits) {
    cqe__violation("malformed_call", -1, "%s: no width token", x->sym);
    return -1;
  }
  x->S = (x->bits + 7) / 8;
  x->ctl = t->pred[0] != 0;
  if (nargs != i + x->ctl + 2 + extra || (t->shape[0] && strcmp(t->shape, "hl") != 0)) {
    cqe__violation("malformed_call", -1, "%s: %d arguments (ABI §1.10)", x->sym, nargs);
    return -1;
  }
  x->fire = x->known = x->ctl_known = 1;
  if (x->ctl) {
    x->ctl_h = arg_h(&args[i++]);
    if (!rail_ok(x, x->ctl_h, "i1"))
      return -1;
    x->fire = (int)(cqe__val(x->ctl_h)->w[0] & 1);
    x->ctl_known = cqe__known(x->ctl_h);
    x->known = x->ctl_known;
  }
  int32_t m = arg_h(&args[i++]);
  if (!bus_minted || m != BUS_HANDLE) {
    cqe__violation("bad_bus", -1, "%s: %d is not the bus handle (__cq_mem)", x->sym, (int)m);
    return -1;
  }
  if (t->shape[0]) {
    x->addr = args[i++].w[0];
  } else {
    x->addr_h = arg_h(&args[i++]);
    if (!rail_ok(x, x->addr_h, "i64"))
      return -1;
    x->addr = cqe__val(x->addr_h)->w[0];
    x->known = x->known && cqe__known(x->addr_h);
  }
  return i;
}

static void log_bus(const access_t *x, const char *op, int host, int32_t h, const cqe_val *v, int32_t slot) {
  char *hx = cqe__hexa(v);
  char c[8], extra[32] = "";
  snprintf(c, sizeof c, "%d", x->ctl ? x->fire : -1);
  if (slot)
    snprintf(extra, sizeof extra, ",\"t\":%d", (int)slot);
  else if (x->t->unc)
    snprintf(extra, sizeof extra, ",\"unc\":1");
  cqe__logf("{\"ev\":\"bus\",\"op\":\"%s\",\"w\":\"%s\",\"addr\":%llu,\"c\":%s,\"host\":%d,\"h\":%d,\"v\":\"%s\"%s}", op, x->t->w,
            (unsigned long long)x->addr, c, host, (int)h, hx, extra);
  free(hx);
}

static void add_deps(int32_t h, const access_t *x) {
  if (x->addr_h)
    cqe__add_dep(h, x->addr_h);
  if (x->ctl_h)
    cqe__add_dep(h, x->ctl_h);
}

/* ---- ops ---------------------------------------------------------------------------------- */

/* The load that made a rail: the forward values its _unc must see (ABI §1.10). Keyed by handle. */
typedef struct { int32_t h; uint64_t addr; uint8_t fire; } load_rec;
static load_rec *loads;
static size_t loads_cap, loads_n;

static size_t load_slot(const load_rec *tab, size_t cap, int32_t h) {
  size_t i = ((size_t)(uint32_t)h * 0x9E3779B1u) & (cap - 1);
  while (tab[i].h && tab[i].h != h)
    i = (i + 1) & (cap - 1);
  return i;
}

static void load_note(int32_t h, uint64_t addr, int fire) {
  if (2 * (loads_n + 1) > loads_cap) {
    size_t cap = loads_cap ? 2 * loads_cap : 256;
    load_rec *tab = calloc(cap, sizeof *tab);
    if (!tab)
      abort();
    for (size_t i = 0; i < loads_cap; ++i)
      if (loads[i].h)
        tab[load_slot(tab, cap, loads[i].h)] = loads[i];
    free(loads);
    loads = tab;
    loads_cap = cap;
  }
  load_rec *r = &loads[load_slot(loads, loads_cap, h)];
  loads_n += !r->h;
  *r = (load_rec){h, addr, (uint8_t)fire};
}

static const load_rec *load_of(int32_t h) {
  if (!loads_cap)
    return NULL;
  const load_rec *r = &loads[load_slot(loads, loads_cap, h)];
  return r->h ? r : NULL;
}

static uint8_t *bytes_buf(uint32_t S) {
  uint8_t *b = calloc(S ? S : 1, 1);
  if (!b)
    abort();
  return b;
}

/* The low bits of the S bytes at buf into v (v's bits above its width zero). */
static void bytes_to_val(cqe_val *v, const uint8_t *buf, uint32_t S) {
  memset(v->w, 0, v->nw * sizeof *v->w);
  memcpy(v->w, buf, S);
  cqe__val_mask(v);
}

static int op_load_forward(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  access_t x;
  if (access_parse(&x, t, args, nargs, 0, 0) < 0)
    return -1;
  char kind = 0;
  cqe__wtok_bits(t->w, &kind);
  cqe_val v;
  cqe__val_init(&v, x.bits, kind);
  int cknown = 1, anyq = 0;
  if (x.fire) {
    uint8_t *buf = bytes_buf(x.S);
    cknown = cells_read(x.addr, x.S, buf, &anyq);
    bytes_to_val(&v, buf, x.S);
    free(buf);
  }
  int32_t h = cqe__new(t->w, &v, x.known && cknown, 0);
  add_deps(h, &x);
  load_note(h, x.addr, x.fire);
  cqe__set_load_copy(h); /* rule 5: never cleaned by rule 6, so no rule-6 image (core.c, cqe__r6_unc) */
  log_bus(&x, "load", !anyq, h, cqe__val(h), 0);
  cqe__val_free(&v);
  out->w[0] = (uint32_t)h;
  return 0;
}

static int op_load_unc(const cqe_tname *t, const cqe_val *args, int nargs) {
  access_t x;
  if (nargs < 1) {
    cqe__violation("malformed_call", -1, "cqrt_%s_%s_unc: no out handle", t->op, t->w);
    return -1;
  }
  int32_t h = arg_h(&args[0]);
  if (access_parse(&x, t, args, nargs, 1, 0) < 0 || !rail_ok(&x, h, t->w))
    return -1;
  if (cqe__measured(h))
    cqe__violation("unc_after_measure", h, "%s: load copy %d was measured: it is never un-copied (rule 5)", x.sym, (int)h);
  else if (cqe__last_nd(h) > cqe__created(h))
    cqe__violation("unc_after_nondiagonal", h, "%s: load copy %d was rotated: it is never un-copied (rule 5)", x.sym, (int)h);
  const load_rec *r = load_of(h);
  if (r && (r->addr != x.addr || (int)r->fire != x.fire))
    cqe__violation("load_unc_args", h,
                   "%s: load copy %d was loaded at 0x%llx under control %d, its _unc is at 0x%llx under control %d (ABI §1.10)",
                   x.sym, (int)h, (unsigned long long)r->addr, (int)r->fire, (unsigned long long)x.addr, x.fire);
  int cknown = 1, anyq = 0;
  if (x.fire) {
    char kind = 0;
    cqe__wtok_bits(t->w, &kind);
    cqe_val v;
    cqe__val_init(&v, x.bits, kind);
    uint8_t *buf = bytes_buf(x.S);
    cknown = cells_read(x.addr, x.S, buf, &anyq);
    bytes_to_val(&v, buf, x.S);
    free(buf);
    cqe_xor_into(h, &v);
    cqe__val_free(&v);
  }
  cqe__mark_written(h);
  add_deps(h, &x);
  if (cqe__val_iszero(cqe__val(h))) {
    int32_t srcs[2];
    int ns = 0;
    if (x.addr_h)
      srcs[ns++] = x.addr_h;
    if (x.ctl_h)
      srcs[ns++] = x.ctl_h;
    cqe__zero_rule(h, srcs, ns);
  } else {
    cqe__setknown(h, cqe__known(h) && x.known && cknown);
  }
  cqe__setrole(h, ROLE_OVERTAKEN); /* its exit role if it stays allocated */
  log_bus(&x, "load", !anyq, h, cqe__val(h), 0);
  return 0;
}

static int op_qram_load(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  return t->unc ? op_load_unc(t, args, nargs) : op_load_forward(t, args, nargs, out);
}

/* The slot's width token: W when W fills its cells, else the cells' i<8S>. */
static const char *slot_w(const access_t *x, char *buf, size_t n) {
  if (x->bits == 8 * x->S)
    return x->t->w;
  snprintf(buf, n, "i%u", 8 * x->S);
  return buf;
}

static int op_qram_store(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)out;
  access_t x;
  if (t->unc) {
    cqe__violation("unknown_symbol", -1, "cqrt_qram_store_%s..._unc: a store has no _unc (CR §1.3)", t->w);
    return -1;
  }
  int i = access_parse(&x, t, args, nargs, 0, 1);
  if (i < 0)
    return -1;
  int32_t vh = arg_h(&args[i]);
  if (!rail_ok(&x, vh, t->w))
    return -1;
  cqe__set_store_kept(vh);
  if (x.ctl_h)
    cqe__set_store_kept(x.ctl_h);
  char sw[16], skind = 0;
  const char *slotw = slot_w(&x, sw, sizeof sw);
  cqe__wtok_bits(slotw, &skind);
  cqe_val disp;
  cqe__val_init(&disp, 8 * x.S, skind);
  int cknown = 1, anyq = 0, host = 1;
  uint8_t *buf = bytes_buf(x.S);
  if (x.fire) {
    cknown = cells_read(x.addr, x.S, buf, &anyq);
    memcpy(disp.w, buf, x.S);
    cqe__val_mask(&disp);
    memset(buf, 0, x.S);
    memcpy(buf, cqe__val(vh)->w, x.S);
    int cl = x.known && cqe__known(vh);
    host = cells_write(x.addr, x.S, buf, cl, cl);
  } else if (!x.ctl_known) {
    cells_reach(x.addr, x.S);
    host = 0;
  }
  int32_t slot = cqe__new(slotw, &disp, x.known && cknown, 0);
  cqe__setrole(slot, ROLE_TAPE_SLOT);
  add_deps(slot, &x);
  if (x.fire)
    log_bus(&x, "store", host, vh, cqe__val(vh), slot);
  else {
    cqe_val zero;
    cqe__val_init(&zero, x.bits, 'i');
    log_bus(&x, "store", host, vh, &zero, slot);
    cqe__val_free(&zero);
  }
  free(buf);
  cqe__val_free(&disp);
  return 0;
}

static int op_qram_swap(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  (void)out;
  access_t x;
  if (t->unc) {
    cqe__violation("unknown_symbol", -1, "cqrt_qram_swap_%s..._unc: a swap is its own inverse (CR §1.3)", t->w);
    return -1;
  }
  int i = access_parse(&x, t, args, nargs, 0, 1);
  if (i < 0)
    return -1;
  int32_t h = arg_h(&args[i]);
  if (!rail_ok(&x, h, t->w))
    return -1;
  if (h == x.ctl_h || h == x.addr_h) {
    cqe__violation("target_aliases_operand", h, "%s: rail %d is also the control or the address", x.sym, (int)h);
    return -1;
  }
  int host = 1, anyq = 0;
  if (x.fire) {
    uint8_t *buf = bytes_buf(x.S), *nw = bytes_buf(x.S);
    int cknown = cells_read(x.addr, x.S, buf, &anyq);
    cqe_val *hv = cqe__val(h);
    /* the cells' new content: h, and the high bits of a partial top cell where they are */
    memcpy(nw, hv->w, x.S);
    int top_known = 1;
    if (x.bits % 8) {
      uint8_t mask = (uint8_t)((1u << (x.bits % 8)) - 1);
      nw[x.S - 1] = (uint8_t)((nw[x.S - 1] & mask) | (buf[x.S - 1] & (uint8_t)~mask));
      const cell_t *c = cell_find(x.addr + x.S - 1);
      top_known = !c || c->known;
    }
    int hknown = cqe__known(h), cl = x.known && hknown;
    bytes_to_val(hv, buf, x.S);
    host = cells_write(x.addr, x.S, nw, cl, cl && top_known);
    cqe__setknown(h, x.known && cknown);
    free(buf);
    free(nw);
    cqe__mark_written(h);
  } else if (!x.ctl_known) {
    cells_reach(x.addr, x.S);
    host = 0;
    cqe__setknown(h, 0);
    cqe__mark_written(h);
  }
  if (!x.fire && x.ctl_known) {
    log_bus(&x, "swap", 1, h, cqe__val(h), 0);
    return 0;
  }
  add_deps(h, &x);
  if (cqe__val_iszero(cqe__val(h)))
    cqe__set_busz(h);
  log_bus(&x, "swap", host, h, cqe__val(h), 0);
  return 0;
}

static int bus_mint(void) {
  if (bus_minted) {
    cqe__violation("bad_bus", -1, "cqrt_qram_alloc_i8: a second call: the bus is created once per process (ABI §1.10)");
    return BUS_HANDLE;
  }
  bus_minted = 1;
  return BUS_HANDLE;
}

static int op_qram_alloc(const cqe_tname *t, const cqe_val *args, int nargs, cqe_val *out) {
  if (strcmp(t->w, "i8") != 0 || t->shape[0] || t->pred[0] || t->unc || nargs != 1 || args[0].w[0] != 0) {
    cqe__violation("bad_bus", -1, "cqrt_qram_alloc_%s: the only bus is qram_alloc_i8(0) (CR §0, ABI §1.10)", t->w);
    return -1;
  }
  out->w[0] = (uint32_t)bus_mint();
  return 0;
}

/* The one bus handle for the injection-bundle getter (bundle/host/cq_host.c). A real function, not a stub: the
 * bundle is host C that no stubgen run sees (stubgen.py leaves this name alone). */
int32_t cqrt_qram_alloc_i8(int32_t n) {
  cqe__init();
  if (n != 0) {
    cqe__violation("bad_bus", -1, "cqrt_qram_alloc_i8(%d): the only bus is n = 0 (CR §0, ABI §1.10)", (int)n);
    return 0;
  }
  return bus_mint();
}

/* A named output of the driver: `bytes` cells from addr, by their basis value, as the bus holds them. No rail, no
 * measurement (CR §6 item 1, "read from the bus at exit"). The same signature as the C oracle's __cqo_out_mem. */
void __cqe_out_mem(const char *name, uint64_t addr, uint64_t bytes) {
  cqe__init();
  uint8_t *buf = bytes_buf((uint32_t)bytes);
  int anyq = 0;
  cells_read(addr, (uint32_t)bytes, buf, &anyq);
  cqe_val v;
  cqe__val_init(&v, (uint32_t)bytes * 8, 'i');
  memcpy(v.w, buf, bytes);
  char *hx = cqe__hexa(&v);
  cqe__logf("{\"ev\":\"out_mem\",\"name\":\"%s\",\"w\":\"i%llu\",\"v\":\"%s\"}", name, (unsigned long long)bytes * 8, hx);
  free(hx);
  cqe__val_free(&v);
  free(buf);
}

/* ---- the tape family's view of the bus (rt_tape.h, BACKEND_ABI §1.11) ---- */

static int tape_peek(uint64_t addr, uint8_t *byte) {
  const cell_t *c = cell_find(addr);
  if (c) {
    *byte = c->value;
    return 1;
  }
  host_read(addr, 1, byte);
  return 0;
}

/* A store the backend makes for an effect entry with a quantum address, control or length (ABI §1.10): the cell goes
 * QUANTUM and a fresh kept i8 slot takes what it displaced; write == 0 is this branch not storing: the value stays and
 * the slot reads 0. */
static void tape_qstore(uint64_t addr, uint8_t byte, int write) {
  uint8_t old = 0;
  tape_peek(addr, &old);
  cell_quantum(addr, write ? byte : old, 0);
  cqe_val disp;
  cqe__val_init(&disp, 8, 'i');
  disp.w[0] = write ? old : 0;
  cqe__setrole(cqe__new("i8", &disp, 0, 0), ROLE_TAPE_SLOT);
  cqe__val_free(&disp);
}

/* The classical store of an INPUT entry's byte (ABI §1.10; rulings 2 D, cq-ytux): like any store whose address, control
 * and content are classical-valued it writes host bytes and the cell is HOST, a QUANTUM cell too, and the slot takes what
 * it displaced. It is the same write as op_qram_store's, one byte long. */
static void tape_cstore(uint64_t addr, uint8_t byte) {
  uint8_t old = 0;
  int anyq = 0;
  int known = cells_read(addr, 1, &old, &anyq);
  cells_write(addr, 1, &byte, 1, 1);
  cqe_val disp;
  cqe__val_init(&disp, 8, 'i');
  disp.w[0] = old;
  cqe__setrole(cqe__new("i8", &disp, known, 0), ROLE_TAPE_SLOT);
  cqe__val_free(&disp);
}

static const cqe_tape_bus tape_bus = {tape_peek, tape_qstore, tape_cstore};

/* ---- end of shot -------------------------------------------------------------------------- */

static int cell_cmp(const void *a, const void *b) {
  uint64_t x = ((const cell_t *)a)->addr, y = ((const cell_t *)b)->addr;
  return x < y ? -1 : x > y;
}

static void bus_at_exit(void) {
  if (!bus_minted)
    return;
  cell_t *q = calloc(cells_quantum ? cells_quantum : 1, sizeof *q);
  size_t n = 0;
  for (size_t i = 0; i < cells_cap; ++i)
    if (cells[i].used && cells[i].quantum)
      q[n++] = cells[i];
  qsort(q, n, sizeof *q, cell_cmp);
  size_t cap = 64 + 32 * n;
  char *line = malloc(cap);
  if (!q || !line)
    abort();
  size_t len = (size_t)snprintf(line, cap, "{\"ev\":\"cells\",\"q\":[");
  for (size_t i = 0; i < n; ++i)
    len += (size_t)snprintf(line + len, cap - len, "%s[%llu,%u]", i ? "," : "", (unsigned long long)q[i].addr, (unsigned)q[i].value);
  snprintf(line + len, cap - len, "]}");
  cqe_log(line);
  free(line);
  free(q);
}

__attribute__((constructor)) static void bus_register(void) {
  cqe_register_op("qram_alloc", op_qram_alloc);
  cqe_register_op("qram_load", op_qram_load);
  cqe_register_op("qram_store", op_qram_store);
  cqe_register_op("qram_swap", op_qram_swap);
  atexit(bus_at_exit);
  cqe_tape_set_bus(&tape_bus);
}
