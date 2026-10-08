// slice_stale_speccall_placed.c — bd test_C_libtooling-r2j3.6, owner ruling bd 57ch (A).
//
// A lifted (Phase-6 specialized) call that reads a STALE record: `q2` aliases `q`'s
// register, the in-place Ry on `q2` moves the wire past the record `q` names, and
// `f(q)` asks for the PRE-Ry value. Before r2j3.6 this lowered at exit 0 with the
// clone's templates AFTER `cqrt_ry_i32(h, 0.3)`: f ran on the rotated register. The
// call is movable, so the 57ch (A) placement emits it just before the gate: the
// golden shows the clone's forward chain, its copy-out and its own adjoint between
// the two rotations, i.e. the trace of the program written as
// `int r = f(q); int q2 = q; cq_theta(&q2, .3);` (that twin is the lit fixture
// lowering_stale_speccall_call_before_theta_accept.ll).
//
// This is the only layer that LINKS: the clone and its `_unc` twin must resolve.
__attribute__((noinline)) int f(int x) { return x * 3 + 1; }

int main(void) {
  int q = 0;
  cq_theta(&q, .5);
  int q2 = q;
  cq_theta(&q2, .3);  // in-place Ry on q's register
  int r = f(q);       // reads the PRE-Ry record
  return (int)cq_measure(r) + (int)cq_measure(q2);
}
