float hff(float, float); float hffq(float, float);
int main(int c, char **v) {
  float x = (float)c;
  float q = cq_theta(x, .5);
  float y = hffq(q, x);
  float z = hff(y, x);
  float w = hffq(z, q);
  return (int)(cq_measure(w) + cq_measure(q) + cq_measure(y));
}
