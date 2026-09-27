float hff(float, float); float hffq(float, float);
int main(int c, char **v) {
  float x = (float)c;
  float q = cq_theta(x, .5);
  float q2 = cq_theta(x + 2, .25);
  float y = hffq(q, x);
  float z = hffq(y, q2);
  float u = hff(z, x);
  float w = hffq(u, y);
  return (int)(cq_measure(w) + cq_measure(q2));
}
