/* tests/spine probe (CR rule 20, §1.3): a load and store per type: f64, f80, i8, i64, a pointer. */
double fd = 1.5; long double fl = 2.5L; char cc = 3; long long ll = 4; double out1; long double out2; char out3; long long out4;
int float_widths(double x0, double tx) {
  double x = x0;
  cq_theta(&x, tx);
  out1 = fd + x;
  out2 = fl * x;
  out3 = cc + (x > 0);
  out4 = ll + (x > 1);
  return cq_measure(out3);
}
