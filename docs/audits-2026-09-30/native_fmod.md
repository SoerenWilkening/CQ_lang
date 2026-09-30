# Runtime-operand census

**3/3 cells have pipeline acceptance for every runtime C/Q mixture.**

This counts build, lowering, link and trace-run success. It does not certify numerical
or unitary semantics. CQ-provided leaf range contracts remain pending. No new goldens were blessed.

| Provider | Accepted for every mixture | Cells |
| --- | ---: | ---: |
| intrinsic | 3 | 3 |

Measured 12 probes: 12 accepted; 0 did not accept.
Structural free-check passes: 12. Classical-only nan accounting is separate.
The macro cells retain the historical f64 scope of the 183-cell model.

## Reproduction

```sh
git clone https://github.com/JuliaMath/openlibm.git /private/tmp/cq-northstar-openlibm
git -C /private/tmp/cq-northstar-openlibm checkout 5fe399749f9276eaa0b8403e507470da05cbbb3f
python3 tools/library_coverage/full_surface/build_corpus.py --openlibm /private/tmp/cq-northstar-openlibm --out /private/tmp/cq-northstar-bc --expect-bc 252
BC=/private/tmp/cq-northstar-bc OPENLIBM=/private/tmp/cq-northstar-openlibm python3 tools/library_coverage/runtime_census.py --native-fmod --output docs/audits-2026-09-30/native_fmod.json
```

Exact compiler and corpus hashes are in the adjacent JSON metadata. Classical operands
and quantum seeds are function parameters. Pointer outputs are read and explicitly measured;
signgam is preserved through internalization. fenv remains outside the CQ model (CLAUDE R16).

## Cells lacking acceptance for every mixture

| Cell | Failing mixtures | First diagnostic |
| --- | --- | --- |
