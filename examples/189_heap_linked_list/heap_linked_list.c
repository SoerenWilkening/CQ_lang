#include <stdlib.h>
/* Heap objects holding quantum values and classical pointers (rules 14, 16, 20, 21). */
struct node { int v; struct node *next; };
int list_search(int x0, double tx, int y0, double ty, int key) {
    struct node *c = malloc(sizeof *c), *b = malloc(sizeof *b), *a = malloc(sizeof *a);
    int x = x0;
    cq_theta(&x, tx);
    int y = y0;
    cq_theta(&y, ty);
    a->v = x; a->next = b;                    /* the next fields are classical host pointers */
    b->v = y; b->next = c;
    c->v = 7; c->next = 0;
    int i = 0;
    struct node *p;
    for (p = a; p && p->v != key; p = p->next) /* quantum exit: a K-loop, p a quantum pointer */
        i++;
    return cq_measure(p ? i : -1);            /* index of the first node holding key, else -1 */
}
int calloc_aligned(unsigned k0, double tk, int x0, double tx, unsigned j) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int x = x0;
    cq_theta(&x, tx);
    int *a = calloc(4, sizeof(int));          /* zero-filled: the fresh |0> cells of a QRAM */
    int *s = aligned_alloc(16, 16);           /* 4 int cells, classical offsets only: a slot array */
    a[k & 3] = x;                             /* quantum-offset store: a is a QRAM */
    s[0] = a[1];                              /* fixed-index QRAM read into a slot */
    s[1] = x + 1;
    int r = s[j & 1] + 1;                     /* slot read at a classical runtime offset */
    free(a);
    free(s);
    return cq_measure(r);
}
