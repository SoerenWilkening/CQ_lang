/* cq-iaz30 (SQLite sqlite3AddColumn, reduced): a classically bounded loop with a quantum exit whose exit arm selects on
   the induction (the trip index, classical in the trip, quantum to taint once read after the loop). The select's
   condition is bound classically in the trip's arm; lowered as a quantum select it asked for its rail. */
unsigned char lens[6] = {4, 3, 7, 4, 2, 6};
unsigned char aff[6] = {65, 66, 67, 68, 69, 70};
int f(unsigned x0, double th)
{
  unsigned x = x0;
  cq_theta(&x, th);
  unsigned n = x & 7;
  int a = 0, flags = 0;
  for (unsigned i = 0; i < 6; i++) {
    if (n == lens[i]) {
      a = aff[i];
      flags = (i & 3) == 1 ? 5 : 1;
      break;
    }
  }
  return a * 16 + flags;
}
