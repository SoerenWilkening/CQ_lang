/* y01c — y01's COMPARE twin. */
int slice(int y) {
  int q = cq_theta(y, 0.2);
  int t = cq_theta(q & 1, 0.5);
  if (t == 1) { q = cq_theta(q, 0.9); }
  return cq_measure(t) + cq_measure(q);
}
int main(void){(void)slice(3);return 0;}
