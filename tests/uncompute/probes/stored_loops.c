// CR rules 5 (sentence 3), 14: rails kept-stored in or around a loop. Each entry is §6-checked against its C program
// (every rail no store kept is uncomputed: §6 item 1).
int g[8];
__attribute__((noinline)) void put(int *p, int v) { *p = v; }
#define I1 int x = cq_theta_si32(x0, t); put(&g[0], x); put(&g[1], x + 1); put(&g[2], x ^ 5);

// cq-mmdf3: an accumulator stored each trip: every instance is kept, the final one read in place, no copy-out.
int sl_each(int x0, int n, double t) {
  I1 int s = g[0];
  for (int i = 0; i < (n & 3); i++) { s += x; g[i & 1] = s; }
  return cq_measure_si32(s + g[0]);
}
int sl_each_rot(int x0, int n, double t, double u) {
  I1 int s = g[0];
  for (int i = 0; i < (n & 3); i++) { s += x; g[i & 1] = s; }
  int r = cq_theta_si32(s, u);
  return cq_measure_si32(r + g[0]);
}
int sl_each_meas(int x0, int n, double t) {
  I1 int s = g[0];
  for (int i = 0; i < (n & 3); i++) { s *= x; g[i & 1] = s; }
  return cq_measure_si32(s);
}
// A carried phi stored each trip: the kept rail is a copy, the reverse undoes the instances.
int sl_phi(int x0, int n, double t) {
  I1 int s = x * 3;
  for (int i = 0; i < (n & 3); i++) { g[i & 1] = s; s *= x; }
  return cq_measure_si32(s + g[0]);
}
// cq-gr5vw: a walked address rail with the accumulator stored each trip.
int sl_walk(int x0, double t) {
  I1 int *p = g + (x & 1);
  int s = 0;
  for (int i = 0; i < 3; i++) { s += *p++; g[3] = s; }
  return cq_measure_si32(s + g[3]);
}
// cq-ii0vf: a rail stored on some classical paths: kept where the store ran, uncomputed where it did not.
int sl_before(int x0, int n, double t) {   // one instance, stored before an unrelated loop
  I1 int y = x + 3;
  int z = y * 5;
  if (n & 1) g[3] = y;
  int s = 0;
  for (int i = 0; i < (n & 3); i++) s += g[i & 1];
  return cq_measure_si32(s + g[3] + z);
}
int sl_after(int x0, int n, double t) {    // one instance, stored after an unrelated loop
  I1 int y = x * 3;
  int s = 0;
  for (int i = 0; i < (n & 3); i++) s += g[i & 1];
  if (n & 4) g[3] = y;
  return cq_measure_si32(s + g[3]);
}
int sl_in(int x0, int n, double t) {       // one instance, stored on some trips
  I1 int y = x * 3;
  for (int i = 0; i < (n & 3); i++) { if (i == 1) g[3] = y; }
  return cq_measure_si32(g[3]);
}
int sl_guard(int x0, int n, double t) {    // one instance, stored each trip; zero trips bypass
  I1 int y = x * 3;
  for (int i = 0; i < (n & 3); i++) g[i & 1] = y;
  return cq_measure_si32(g[1]);
}
int sl_trip(int x0, int n, double t) {     // an instance per trip, stored on some trips
  I1 int s = 0;
  for (int i = 0; i < (n & 3); i++) { int y = x * (i + 3); s ^= y; if (i & 1) g[3] = y; }
  return cq_measure_si32(s + g[3]);
}
int sl_acc(int x0, int n, double t) {      // a carried accumulator stored on some trips
  I1 int s = g[0];
  for (int i = 0; i < (n & 3); i++) { s *= x; if (i & 1) g[3] = s; }
  return cq_measure_si32(s + g[3]);
}
int sl_phi_some(int x0, int n, double t) { // a carried phi stored on some trips
  I1 int s = x * 3;
  for (int i = 0; i < (n & 3); i++) { if (i & 1) g[3] = s; s *= x; }
  return cq_measure_si32(s + g[3]);
}
int sl_kloop(int x0, int n, double t) {    // a K-loop, a classical branch decides the store
  I1 int s = 0;
  for (int i = 0; i < (x & 3); i++) { int y = x * (i + 2); s ^= y; if (n & 1) g[3] = y; }
  return cq_measure_si32(s + g[3]);
}
int sl_arm(int x0, int n, double t) {      // a trip's arm flag controls a store on some trips; a join of handles exits
  I1 int s = 0;
  for (int i = 0; i < (n & 3); i++) {
    if ((x >> (i & 3)) & 1) { int y = x * (i + 3); s ^= y; if (i & 1) g[3] = y; }
  }
  return cq_measure_si32(s + g[3]);
}
int sl_arm_false(int x0, int n, double t) { // the same on the flag's false edge
  I1 int s = 0;
  for (int i = 0; i < (n & 3); i++) {
    if (((x >> (i & 3)) & 1) == 0) { int y = x * (i + 3); s ^= y; if (i & 1) g[3] = y; } else s += x;
  }
  return cq_measure_si32(s + g[3]);
}
