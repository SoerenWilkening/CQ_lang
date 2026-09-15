The three PRE-EXISTING `<unknown>:0:0` measurements behind BASELINE.md §7 item 3.

None of these programs contains a rail bank. Run on the ORACLE
(/Users/sorenwilkening/Desktop/CQ_lang/build, cq-opt 0e280fc6...):

  clang -I <include> -include CQ.h -g -O1 -emit-llvm -S <f>.c -o <f>.s1.ll
  cq-opt -load-pass-plugin libCQPass.so -passes=cq-lowering -S <f>.s1.ll -o /dev/null

  nobank_classical_mux.c -> exit 1
      error: <unknown>:0:0: in function slice i32 ():
             cq taint escape: tainted value muxed by a classical-condition select
  nobank_crossiter_a.c   -> exit 1
      error: <unknown>:0:0: in function slice i32 ():
             cq loop lowering: loop-carried tainted value crosses iterations
  nobank_crossiter_b.c   -> exit 1   (same string, same <unknown>:0:0)

Both fences diagnose a PHINode -- TaintPropagation.cpp:1620 `diagnoseEscape(Phi, ...)`,
LoopLowering.cpp:2143/2595 `diagnose(&P, kMsgCrossIter)` -- and `clang -O1` attaches no
`!dbg` to the phis mem2reg creates. So the five BANK rows that lose their source location
in this regeneration lose it to the FENCE that now owns them, not to this merge.
