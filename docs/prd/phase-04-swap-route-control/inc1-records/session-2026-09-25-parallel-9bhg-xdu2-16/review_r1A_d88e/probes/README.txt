Probes for Rule-13 review r1A of bd test_C_libtooling-d88e (see ../REVIEW.md).

The scripts carry no absolute paths of their own; they expect this layout under a
scratch directory:  bin/{ora,new,c9,comp,inst}  (frozen cq-opt copies, plus the
runtime archives libcq_templates.a / libcq_runtime.a),  src/  p/  .
They are bash scripts: run them with bash, never let zsh expand an unquoted
list into them (the first twin run of this review reported "0 pairs" for
exactly that reason, and the denominator line is what caught it).

  gen.sh   name...        src/<name>.c (+ src/<name>.lib.c, llvm-linked) -> p/<name>.s1.ll
  run.sh   "tags" name... rc, #cqrt_measure, #cqrt_ry, first error per binary
  twin.sh  TAG base...    <base>C vs <base>T (hand-inlined twin); DECL-SAME / DECL-DIFF /
                          ACC-SAME (traces diffed under "5 7" and "2 9") / ACC-DIFF / VERDICT-DIFF
  one.sh / sweep.sh       corpus sweep: rc, sha(stdout), sha(stderr with the path masked), first error
  batch.sh LIST OUT       rc/measure-count/stderr-hash on ora, new, c9, comp
  ra_instrument.patch     the ENV-SWITCHED instrument built from 52d35e5d (cq-opt 6c215158b89c8d4d).
                          With no RA_* variable set it is behaviour-identical to the subject over
                          the whole corpus (null control, REVIEW.md §3). Switches:
                            RA_MC=1       every recorded lift declines ("RA_MC census")
                            RA_WVH=1      the re-ask reads WeakVH copies of the record (mutant M6')
                            RA_NOREASK=1  the re-ask returns false (mutant M1)
                            RA_OLDSLOT=1  the 2qyz re-sweep runs at its pre-d88e slot (mutant M10)

src/r*.c    reviewer probes (C = 2-TU with lib h(a,k)=k+1 unless a .lib.c says otherwise;
            T = hand-inlined twin; Q = lib h(a,k)=a+k, a spec-QUANTUM verdict).
ir/rk04{Q,C}_rev.s1.ll
            k04Q / k04C (two chained lifts) after `opt -passes=instnamer`, with the four
            blocks of the two diamonds laid out in REVERSE (bb14, bb12, bb9, bb7), so the
            outer lift is RECORDED first with the inner merge phi as its base and the inner
            lift then RAUWs that phi. `opt -passes=verify` clean.
results/    sweep and battery outputs quoted in REVIEW.md.
