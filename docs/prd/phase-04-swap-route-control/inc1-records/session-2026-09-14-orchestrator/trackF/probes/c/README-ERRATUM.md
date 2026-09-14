# ERRATUM — six 0-byte probes were DELETED from this directory, not committed

`owner.{s1,W}.ll`, `vd.{s1,W}.ll`, `w2.{s1,W}.ll` were **zero bytes** and are gone. The `.c` sources beside
them are intact, so every one is regenerable with the stage-1 command in `$SES/PROTOCOL.md`.

**Why they were empty, and why it mattered.** On this (case-insensitive) filesystem,
`sed … X.s1.ll > X.S1.ll` truncates its **own source** to 0 bytes before `sed` reads it. And a **0-byte
module ACCEPTS**: `cq-lowering` passes through any module with no `theta`/`phi`/`measure` byte-identically,
exit 0. So each of these scored a **false ACCEPT on nothing**.

Six of `SCOPE_F.md`'s probes were affected. Re-measured with distinct names: **two of the three affected
claims stand; one does not** — §3b's *"w2 W → ACCEPT"* was wrong support for a conclusion that survives on a
different probe. The correction is `IMPL_F.md` §7 (Track F's worktree), and the trap is recorded as bd
memory `empty-module-accepts-vacuity-trap`.

**The three protections, for anyone writing a probe harness here:** never derive an output filename from an
input filename by case alone; assert non-zero size on every generated `.ll` before measuring it; and treat an
ACCEPT row whose lowered IR contains no `cqrt_*` symbol at all as a vacuity candidate, not a result.
