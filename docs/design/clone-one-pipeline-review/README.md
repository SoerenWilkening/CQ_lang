# Clone pipeline adversarial evidence

Four independent review rounds cleared the implementation at `bae428e8`, with
subsequent comment corrections only. Each round contains its original report,
fresh LLVM inputs, accepted output IR and nonempty diagnostics. Reports retain
the original `/tmp/p3kd78-review-rN` command paths; the corresponding files are
archived here under `roundN`. These artifacts record a run, not new test fixtures.

| Round | New lowering executions | Accepted | Limits |
| --- | ---: | ---: | --- |
| [1](round1/report.md) | 6 | 4 | i1 ABI and rolled-loop gaps stop two probes |
| [2](round2/report.md) | 6 | 5 | One malformed probe; QROM integer-root coverage weakened |
| [3](round3/report.md) | 6 | 4 | Two probes stop at earlier main-control gaps |
| [4](round4/report.md) | 2 | 2 | New round-2 candidates and grown masks both witnessed |

All four verdicts were ACCEPT. Reviewers reran no implementer fixture, suite or
census. Round 3 fills round 2's FP80/debug-allocator gap; round 4 fills round 3's
round-2 reachability gap. The coordinator read the lowered bodies independently.

The proof applies to phase-free basis permutations over a single captured gate
stream. Strip elision retains scratch through the forward computation and relies
on emitter ownership forbidding a scratch read after its free. The mechanical
mirror then clears each scratch after every forward use. Parameters are borrowed;
only captured mints and constant-zero allocations are freed. Nonzero classical
allocations remain allocated under the existing policy. Path-dependent streams
remain the compiler gap tracked by p3kd.7.9.
