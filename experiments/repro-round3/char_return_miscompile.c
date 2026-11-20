/* cq-iaz30 (SQLite sqlite3ExprAffinity, reduced): a K-loop (tail recursion made a loop) whose exit arm holds another
   K-loop, both exiting into the outer loop's continuation, beside other arm blocks' edges into it. The inner loop,
   lowered inside the outer trip, left those blocks' incomings to the walker's join, which read one trip's rails after
   the last trip; the outer trip already merges them. */
struct E { unsigned char op, aff, l, tok, skip; };
struct E nodes[8] = {
    {0, 65, 1, 0, 0}, {3, 66, 3, 2, 0}, {2, 67, 3, 4, 1}, {0, 68, 4, 1, 0},
    {1, 69, 6, 3, 0}, {3, 70, 6, 5, 0}, {0, 71, 7, 6, 1}, {4, 72, 7, 0, 0},
};
unsigned char str[8] = {'r', 'e', 'a', 'l', 0, 'i', 'n', 0};
static char affOf(const struct E *p)
{
  unsigned op = p->op;
  while (1) {
    if (op == 3) {
      return str[p->tok];
    }
    if (op == 0)
      return affOf(&nodes[p->l]);
    if (op == 1)
      return affOf(&nodes[p->tok & 7]);
    break;
  }
  return p->aff;
}
char aff(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  return affOf(&nodes[x & 7]);
}
