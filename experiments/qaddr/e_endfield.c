/* a field read at a negative quantum index from the end pointer: base + field offset lies past the array. */
struct S { int x, y; };
static struct S arr[4] = {{1, 2}, {3, 4}, {5, 6}, {7, 8}};
static int nb[64];
int main(void) {
    for (int i = 0; i < 64; i++) nb[i] = 90 + i;
    signed char q = -2; cq_theta(&q, 0.0);
    struct S *end = arr + 4;
    return (int)cq_measure(end[q].y) + nb[3] - 93;
}
