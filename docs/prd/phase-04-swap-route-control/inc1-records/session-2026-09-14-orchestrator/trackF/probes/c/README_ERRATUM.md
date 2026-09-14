# ERRATUM — six probes in this directory were 0 bytes and are DELETED

`sed X.s1.ll > X.S1.ll` on a case-insensitive filesystem (macOS default) is a
read-and-write of ONE file: the shell truncates the redirect target before `sed`
reads it, so `X.s1.ll` ends up 0 bytes and `X.S1.ll` is empty too. An empty `.ll`
parses as an empty module and `cq-opt` ACCEPTS it, so the probe reported a green
result for the wrong reason.

Affected, all deleted: `owner.s1.ll`, `owner.W.ll`, `vd.s1.ll`, `vd.W.ll`,
`w2.s1.ll`, `w2.W.ll` (the main checkout's copies are still 0 bytes; this is the
worktree's record). They backed three sentences of `SCOPE_F.md` §3a/§3b/§3c.

Replaced by `../cust/*.ll`, generated with DISTINCT names and with every file's
byte size printed before use. The corrected verdicts — two of the three claims
stand, one does not — are in `IMPL_F.md` §7.

**The defence, cheap and now standard for this track: print the byte size of
every generated probe and treat 0 as a HOLE. A probe that cannot fail is not a
probe.**
