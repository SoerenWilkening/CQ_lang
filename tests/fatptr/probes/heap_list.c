/* tests/fatptr heap-list probes (cq-z6q1; CR rules 14, 20, 21; 189's list_search): heap records {v, next} whose
 * v fields hold handles and whose next fields hold classical host pointers; a K-loop whose classical exit
 * (a NULL read from memory) has no count LLVM computes carries p as a fat pointer's tag (fatptr R2); a load
 * through p is one access per record merged by select, a next field is decoded at run time by range tests.
 * Each entry is checked §6 against its own C program (cqcheck user). Regenerate heap_list.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec heap_list.c -o heap_list.O1.ll */
#include <stdlib.h>
#include "CQ.h"
struct node { int v; struct node *next; };
/* Four nodes (K = 4: the overflow predicate can be 1), two quantum, the key quantum too. */
int hl_index(int x0, double tx, int y0, double ty, int k0, double tk) {
  struct node *d = malloc(sizeof *d), *c = malloc(sizeof *c), *b = malloc(sizeof *b), *a = malloc(sizeof *a);
  int x = x0; cq_theta(&x, tx);
  int y = y0; cq_theta(&y, ty);
  int key = k0; cq_theta(&key, tk);
  a->v = 3; a->next = b;
  b->v = x; b->next = c;
  c->v = 5; c->next = d;
  d->v = y; d->next = 0;
  int i = 0;
  struct node *p;
  for (p = a; p && p->v != key; p = p->next)
    i++;
  return cq_measure(p ? i : -1);
}
/* The value of the first node at or above a classical threshold, summing the values passed. */
struct rec { long pad; int v; struct rec *next; };
int hl_sum(int x0, double tx, int t) {
  struct rec *c = malloc(sizeof *c), *b = malloc(sizeof *b), *a = malloc(sizeof *a);
  int x = x0; cq_theta(&x, tx);
  a->pad = 1; a->v = x; a->next = b;
  b->pad = 2; b->v = x + 4; b->next = c;
  c->pad = 3; c->v = 9; c->next = 0;
  int s = 0;
  struct rec *p = a;
  while (p->v < t) {
    s += p->v;
    p = p->next;
    if (!p)
      break;
  }
  return cq_measure(s);
}
