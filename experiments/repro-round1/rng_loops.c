/* cq-03rdt: a classically bounded loop's exit value is the initial value of the next loop's carried
   value (a header phi), whose trips keep a stored value. Before the fix the first loop's reverse was
   placed inside the second loop's trip (it ran per trip and freed the rail trip 0 still reads):
   "use of %N after it was uncomputed and freed" (GSL rng ran1_set). */
long sh[4];
long rng_loops(long s0, double th) {
  long s = s0;
  cq_theta(&s, th);
  for (int i = 0; i < 4; i++)
    s = s / 3;
  for (int i = 0; i < 4; i++) {
    s = s / 5;
    sh[i] = s;
  }
  return cq_measure(s);
}
