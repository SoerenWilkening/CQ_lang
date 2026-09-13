# Track M — gate ledger (`../PROTOCOL.md` §3.1)

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`.
**A gate result is a fact about a BINARY, not about a moment.** Read this file before running any
gate; if the hash is unchanged and the gate is recorded, CITE the line instead of re-running it.

A cited line whose hash does not match the binary on disk is a FINDING.

| gate | binary | result verbatim | who | when |
|---|---|---|---|---|
| per-probe pipeline (stages 1,2,2b,3,4) over `probes/` — 27 probes | `fbbe0820ef4b176a` (ORACLE, `e96f89c`) | 9 ACCEPT (`m03` 23, `m07` 23, `m09` 23, `m11` 28, `m12` 31, `m17` 28, `m18` 29, `m19` 28, `m26` 25 trace lines; every one STRICT stage 2b `0 violation(s), 0 unproven`) / 18 DECLINE with the anchors in `probes/README.md` | M-scope | 2026-09-13 12:4x |

**Not run by this agent, by protocol (the "scoping" column):** any build, `lit`, any `ctest` entry,
`cq-opt-equivalence`, the corpus sweep, the injection matrix, any twin matrix. The ORACLE hash was
verified by `probes/run.sh` before each sweep and matched `PROTOCOL.md`.
