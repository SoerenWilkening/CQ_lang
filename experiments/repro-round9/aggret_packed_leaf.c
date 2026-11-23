/* cq-126eb (Stockfish Tablebases::rank_root_moves): an entry returning a 12-byte struct by value, { i64, i32 }, whose
   i64 leaf is packed from several C fields (or disjoint of zext and shifted fields), one of them quantum. The entry
   returns the packed leaf as ONE handle, its fields joined; f's in-place call reads it whole (r.b by lshr + trunc).
   cqcc --cq-check --cq-entry f: the values match the C program; the one reason left is the joined i64 rail reported
   as a leak, which an unpacked { long, int } result shows the same way (a separate issue, see the commit). */
struct R { int a; char b; char c; int d; };
__attribute__((noinline)) struct R rank(unsigned x0, double th, int y)
{
  unsigned x = x0;
  cq_theta(&x, th);
  struct R r = { (int)x, (char)(y > 3), 1, (int)x + y };
  return r;
}
int f(unsigned x0, double th, int y)
{
  struct R r = rank(x0, th, y);
  return r.a * 3 + r.b * 5 + r.c + r.d;
}
