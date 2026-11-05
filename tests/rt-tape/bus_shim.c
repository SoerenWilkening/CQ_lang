/* A small stand-in for rt_bus.c, for the hand driver of refs.py while the evaluator's bus is not on this branch:
 * the _hl and rail-address load, load _unc and store over a QUANTUM-cell table, __cq_mem, __cq_alloc, and the
 * hook of rt_tape.h. It is not the evaluator's bus and proves nothing about one. */
#include <mach/mach.h>
#include <mach/mach_vm.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>

#include "cqe.h"
#include "rt_tape.h"

int cqe__known(int32_t h);
void cqe__setrole(int32_t h, int role);

#define BUS 0x51000001
#define NCELLS 4096
static struct { uint64_t a; uint8_t b; } cells[NCELLS];
static int ncells;

static int find(uint64_t a) {
  for (int i = 0; i < ncells; i++) if (cells[i].a == a) return i;
  return -1;
}
static int peek(uint64_t a, uint8_t *b) {
  int i = find(a);
  if (i >= 0) { *b = cells[i].b; return 1; }
  mach_vm_size_t got = 0;
  *b = 0;
  if (mach_vm_read_overwrite(mach_task_self(), a, 1, (mach_vm_address_t)(uintptr_t)b, &got) != KERN_SUCCESS || got != 1) *b = 0;
  return 0;
}
static void quantum(uint64_t a) {
  if (find(a) >= 0) return;
  uint8_t b;
  peek(a, &b);
  if (ncells == NCELLS) { cqe_fail("bus_shim: out of cells"); return; }
  cells[ncells].a = a;
  cells[ncells++].b = b;
}
static int32_t slot(uint8_t displaced) {
  uint64_t w = displaced;
  cqe_val v = {8, 'i', 1, &w};
  int32_t h = cqe_new_rail("i8", &v, 0);
  cqe__setrole(h, 3);
  return h;
}
static void qstore(uint64_t a, uint8_t byte, int write) {
  quantum(a);
  int i = find(a);
  slot(write ? cells[i].b : 0);
  if (write) cells[i].b = byte;
}
static const cqe_tape_bus hook = {peek, qstore};

static unsigned nbytes(const char *w) { return ((unsigned)atoi(w + 1) + 7) / 8; }

static uint64_t addr_arg(const cqe_tname *t, const cqe_val *a) {
  if (!strcmp(t->shape, "hl")) return a->w[0];
  const cqe_val *r = cqe_rail((int32_t)a->w[0]);
  return r ? r->w[0] : 0;
}
static int addr_known(const cqe_tname *t, const cqe_val *a) {
  return !strcmp(t->shape, "hl") || cqe__known((int32_t)a->w[0]);
}

static int op(const cqe_tname *t, const cqe_val *a, int n, cqe_val *out) {
  int ctl = !strcmp(t->pred, "ctl");
  if (!strcmp(t->op, "qram_alloc")) { out->w[0] = BUS; return 0; }
  if (!strcmp(t->op, "qram_store")) {
    if (n != 3 + ctl) { cqe_fail("bus_shim: store arity"); return -1; }
    int cv = 1, cknown = 1;
    if (ctl) { const cqe_val *c = cqe_rail((int32_t)a[0].w[0]); cv = c ? (int)(c->w[0] & 1) : 0; cknown = cqe__known((int32_t)a[0].w[0]); }
    uint64_t addr = addr_arg(t, &a[1 + ctl]);
    int32_t vh = (int32_t)a[2 + ctl].w[0];
    const cqe_val *v = cqe_rail(vh);
    if (!v) return -1;
    int classical = cknown && addr_known(t, &a[1 + ctl]) && cqe__known(vh);
    unsigned nb = nbytes(t->w);
    for (unsigned j = 0; j < nb; j++) {
      uint8_t byte = (uint8_t)(v->w[j / 8] >> (8 * (j % 8)));
      if (classical) {
        if (cv) { uint8_t d; peek(addr + j, &d); slot(d); *(volatile uint8_t *)(uintptr_t)(addr + j) = byte; }
        continue;
      }
      qstore(addr + j, byte, cv);
    }
    return 0;
  }
  /* qram_load[_unc] */
  int base = t->unc ? 1 : 0;
  if (n != base + 2 + ctl) { cqe_fail("bus_shim: load arity"); return -1; }
  int cv = 1, known = 1;
  if (ctl) { const cqe_val *c = cqe_rail((int32_t)a[base].w[0]); cv = c ? (int)(c->w[0] & 1) : 0; known = cqe__known((int32_t)a[base].w[0]); }
  uint64_t addr = addr_arg(t, &a[base + 1 + ctl]);
  known = known && addr_known(t, &a[base + 1 + ctl]);
  unsigned nb = nbytes(t->w), bits = (unsigned)atoi(t->w + 1);
  uint64_t w[4] = {0};
  for (unsigned j = 0; j < nb && cv; j++) {
    uint8_t byte;
    if (peek(addr + j, &byte)) known = 0;
    w[j / 8] |= (uint64_t)byte << (8 * (j % 8));
  }
  cqe_val v = {bits, t->w[0] == 'f' ? 'f' : 'i', (bits + 63) / 64, w};
  if (t->unc) {
    int32_t h = (int32_t)a[0].w[0];
    cqe_xor_into(h, &v);
    const cqe_val *now = cqe_rail(h);
    int zero = now != NULL;
    for (uint32_t i = 0; now && i < now->nw; i++) zero &= now->w[i] == 0;
    if (zero) cqe_set_known(h, 1);   /* a rail its _unc returned to 0 */
    return 0;
  }
  out->w[0] = (uint32_t)cqe_new_rail(t->w, &v, known);
  return 0;
}

__attribute__((constructor)) static void bus_shim_register(void) {
  cqe_register_op("qram_alloc", op);
  cqe_register_op("qram_store", op);
  cqe_register_op("qram_load", op);
  cqe_tape_set_bus(&hook);
}

int __cq_mem(void) { return BUS; }
void *__cq_alloc(uint64_t size, uint64_t align) {
  (void)align;
  size_t total = (size_t)size + 4096;
  char *p = mmap(NULL, total, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANON, -1, 0);
  *(uint64_t *)(p + 4088) = size;
  return p + 4096;
}
