/* f02 — the arm's theta SEED is the condition register itself (Track C's alpha):
   `if (b) r = cq_theta(b, t)` with r a separate _Bool. */
int slice(int y) {
  _Bool x = (y != 0);
  _Bool b = cq_theta(x, 0.5);
  _Bool r = 0;
  if (b) { r = cq_theta(b, 0.9); }
  return (int)cq_measure(b) + (int)cq_measure(r);
}
int main(void){(void)slice(1);return 0;}
