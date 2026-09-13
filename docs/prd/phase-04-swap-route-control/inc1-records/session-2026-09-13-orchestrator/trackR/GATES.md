# Track R — gate ledger (PROTOCOL.md: a gate result is a fact about a BINARY, not a moment)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

per-probe pipeline (36 probes, ORACLE) | fbbe0820ef4b176a | 9 ACCEPT (all STRICT stage 2b `0 violation(s), 0 unproven`, all linked and ran), 27 DECLINE; full table in probes/README.md | scoping-R | 2026-09-13 12:06
per-probe pipeline (3 vd IR surgeries, ORACLE) | fbbe0820ef4b176a | S1/S2/S3: F2 gone, all three -> `control flow` | scoping-R | 2026-09-13 12:08

Not run by this agent (scoping row): any build, `lit`, any `ctest`, the corpus sweep, the
injection matrix, the twin matrices.
