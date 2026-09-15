; ModuleID = '/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/out/e2l_global_initializer_defined.s1.ll'
source_filename = "/Users/sorenwilkening/Desktop/CQ_lang/docs/prd/phase-04-swap-route-control/inc1-records/session-2026-09-15-orchestrator/trackM/probes/out/e2l_global_initializer_defined.s1.ll"

@g = global { i32, i32 } { i32 1, i32 2 }

define i32 @gi() {
entry:
  ret i32 ptrtoint (ptr @g to i32)
}
