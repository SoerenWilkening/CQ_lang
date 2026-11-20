/* cq-aqr5v (block, integration): a classically bounded sub-loop with a quantum exit (rule 14 case 3) whose exit edges
   leave from several blocks (a classical exit test besides the bound, a quantum one), inside a classically bounded loop,
   the exit arm writing memory (so its exits meet at one hub, run once after the trips). */
int out[4];
int f(unsigned x0, double th, int c)
{
  unsigned x = x0;
  cq_theta(&x, th);
  for (int i = 0; i < 3; i++) {
    for (int k = 0; k < 2; k++) {
      if (k > 0 && c == 7) { out[0] = 1; return 5; }
      if ((x >> (2 * i + k)) & 1) { out[1] = 2; return 6; }
    }
  }
  return 0;
}
