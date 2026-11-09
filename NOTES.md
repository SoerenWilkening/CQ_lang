# r4-nohandle: stopped at a §6 obstacle (2026-11-09)

Done: reading and design only; no code changed. Left: everything (C runtime, kept.py, run.py, tests/replay), pending a decision on the obstacle below.


Ruling under implementation: DECISIONS 2026-11-09 (a1a99c9), "a replayed call reserves no rail handles; its kept rails
are named (call occurrence, record row)". Branch r4-nohandle at 172e98c, no commits: the obstacle is in the identity
step, before any code.

## The obstacle

Whether a call is replayed is a function of the sample's VALUES, not of its path:
- the replay key includes each handle argument's rail value (core.c cqe__rp_argkey, `cqe__rp_put(o, rail_w(r), ...)`)
  and the bus bytes the record read (rt_replay.c pre_ok); the record table lives in __DATA and is restored per sample
  (core.c sect[] restore), so a call hits iff an EARLIER call of the same sample had equal argument values;
- a spot check runs a hit for real, chosen by FNV(sample k, hit index) (rt_replay.c spot_check): sample-dependent;
- a clone closes (runs real, outside any window) after 256 records with hits < records, or at the 1 GB record cap
  (__cqe_rp_enter): value-dependent;
- a window is dirty, so the call runs real, on a value test too (build_record: an 'i' result whose value lies in
  (w_base, nrails]).

Today this is invisible because a replayed call reserves exactly the handles the real run makes: replay on/off give
the same handle numbers (tests/replay "traces identical"). Under the ruling, a hit gives its rails names (occ, row)
and advances no counter, a miss/spot check/closed/dirty call gives them real handles and advances the counter. So two
samples on the same lowered path, differing only in quantum input values, get different kept-rail names AND different
real handle numbers for every rail made after the first call that hit in one and missed in the other; the occurrence
index of later replayed calls differs as well ("n-th replayed call").

Effect on §6 (compare.py), not just on messages:
- `_shape_of` puts handle_digest(kept), rotation/measure handles and the frees digest into the structure; groups are
  (classical args, our shape, ref shape) (compare.py ~2320). Value-dependent names split one path's samples into
  smaller groups. Every value-function rule (ref kept multiset, a_K, n>K2, abort, Ry target values) then runs over
  fewer samples; in the limit a group of one is the per-sample count that the exit-rows ruling calls unsound.
- With exact classical arguments, "the circuit's structure varies with the quantum inputs and nothing is measured"
  (compare.py ~2328) becomes a false FAIL on a correct module whenever a clone hits on some quantum inputs only.
The ruling's requirement "two samples that take the same path give the same names" cannot be met with
"n-th replayed call" naming plus real handles for everything else. Not implemented; nothing weakened.

## A sound variant (for the owner/orchestrator to choose; not done)

Make the name independent of how the call ran: every top-level call of an eligible clone (wrapper entry outside an
open window) is an occurrence, whether it hits, records, is spot-checked, closes, or is dirty. A rail made inside
occurrence o at relative row i is named (o, i) in every mode; any other rail by its rank among the rails made outside
occurrences (a dense index, what hclass computes today); a touched block rail's real handle maps back to (o, i).
Real handles then stay sequential with no reservation, and the canonical name is what every handle the checker reads
carries: the exit list (def/use with "occ", rows), ry/phase "h"/"a"/"ctl"/"f", measure "h", free "h" and the frees
digest, violation handles, and handles the driver prints as results (run.resolve_handle_rets). The runtime translates
at each event write (a sorted range table: real-run occurrence ranges and the touched-rail table). That is a larger
change than the brief (every handle-bearing event and the driver's handle results), so it needs a decision first.
Cheaper alternative if only the 0x51000000 limit matters: keep the reserved range (the counter only; map leaves are
already real-handle-only since the memory plan) and drop the per-block state that is not needed.
