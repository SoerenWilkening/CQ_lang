long f(long *sh, long s) {
  for (int i = 0; i < 4; i++)
    s = s / 3;
  for (int i = 0; i < 4; i++) {
    s = s / 5;
    sh[i] = s;
  }
  return 0;
}
