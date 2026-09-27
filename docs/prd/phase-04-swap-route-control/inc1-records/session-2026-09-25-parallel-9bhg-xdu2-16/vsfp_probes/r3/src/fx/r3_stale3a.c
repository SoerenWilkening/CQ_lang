int g_sink;
int main(void) {
  int q = cq_theta(0, 0.7);
  int r;
  if (q > 3) { volatile int z = 1; r = 5; } else { r = 9; }
  g_sink = r; return cq_measure(q);
}
