# Track L — gate ledger (PROTOCOL.md "the non-redundancy protocol")

Format: `<gate> | <sha256 of build/ir-pass/cq-opt, first 16> | <result verbatim> | <who> | <when>`

The **scoping** row of PROTOCOL.md's table owes exactly one gate — the per-probe pipeline against the
ORACLE — and is forbidden `lit`, `ctest`, any build, the corpus sweep and the injection matrix. So
this track ran no suite and this ledger carries no suite line. Nothing here may be cited as
clearance for a binary other than the ORACLE.

```
ORACLE identity verified (shasum -a 256) | fbbe0820ef4b176a | cq-opt fbbe0820ef4b176ad7f36448d1ded7f32ee4dfd368f951db0826a6f34f91a661 / libCQPass.so 40e9c7a51e8120bb0ec41fcda78b961c3d694e5a51b6fadb33df881113892e93 — unchanged before the first probe and after the last | scoping-L | 2026-09-13 11:34 / 12:18
per-probe pipeline, 37 probes (probes/run.sh) | fbbe0820ef4b176a | 4 ACCEPT (p2, p9, p2u/p9u, p23, w2 — 6 rows) / 31 DECLINE; full table probes/README.md | scoping-L | 2026-09-13 12:05
per-probe pipeline, ready/ fixtures (2) | fbbe0820ef4b176a | both exit 0; every CHECK line copied from this output | scoping-L | 2026-09-13 12:02
e2e pipeline incl. STRICT stage 2b + link + run, ready/ slices (2) | fbbe0820ef4b176a | both exit 0; 1 rail mint(s) of which 1 left allocated, 0 cqrt_free site(s): 0 verified, 0 violation(s), 0 unproven; goldens diff-clean; rolled golden == unrolled golden | scoping-L | 2026-09-13 12:10
K-independence (no -g), p2 vs p2k1000 | fbbe0820ef4b176a | 50 lowered IR lines at K=3 and 50 at K=1000 (traces 9 / 2003) | scoping-L | 2026-09-13 11:58
```

**Owed by the landing agent, not by this track:** `lit --filter 'carried_theta_first'` (2 fixtures),
`ctest -R 'carried-theta-first'` (3 entries), the injection matrix over the two new accepts. See
`ready/README.md`.
