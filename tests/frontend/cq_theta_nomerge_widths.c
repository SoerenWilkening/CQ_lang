// RUN: %clang %cq_include -O1 -emit-llvm -include CQ.h -S %s -o - | %filecheck %s

// bd test_C_libtooling-fmt3 round 2 (Rule-13 r1A F-r1A-5 / r1B F-r1B-3): ONE PIN PER
// `nomerge` TOKEN. `include/CQ.h` puts `CQ_THETA_NOMERGE_` on each of the 16
// `cq_theta_*` declarations, and before this file only `cq_theta_si32` was pinned —
// both reviews measured a header with the other 15 tokens deleted passing every
// committed layer while the fmt3 fold came back at f80 / f16 / f64 / i1.
//
// Each function below is the same MERGE PROBE at one `_Generic` row: an if/else of
// two `cq_theta` calls on ONE register that differ only in the angle. Without
// `nomerge` on that row's declaration, `-O1`'s SimplifyCFG sinks the two calls into
// ONE call with a `select` on the angle and the branch disappears; with it, the
// `br i1` and BOTH calls survive. Deleting any ONE token fails exactly its function
// here (mutation-checked, all 16 caught: TRACK_FMT3.md §10).
//
// ⚠ This probe is the if/else spelling because it is the one -O1 merges at every
// width with no pin needed; it pins the ATTRIBUTE, not the fmt3 hazard itself (that
// is `cq_theta_nomerge.c` + the `…_nomerge_*.ll` lit fixtures). The ternary spelling
// `cq_theta(&r, c ? A : B)` is unaffected by the attribute and is not probed here.

#define NM_PROBE(T, NAME)                                                       \
    T NAME(T r, int c) {                                                        \
        if (c) cq_theta(&r, 0.9); else cq_theta(&r, 0.3);                    \
        return r;                                                               \
    }

NM_PROBE(bool, nm_i1)
// CHECK-LABEL: define {{.*}} @nm_i1(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_i1(
// CHECK:       call {{.*}}@cq_theta_i1(
// CHECK:       ret

NM_PROBE(char, nm_c)
// CHECK-LABEL: define {{.*}} @nm_c(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_c(
// CHECK:       call {{.*}}@cq_theta_c(
// CHECK:       ret

NM_PROBE(signed char, nm_si8)
// CHECK-LABEL: define {{.*}} @nm_si8(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_si8(
// CHECK:       call {{.*}}@cq_theta_si8(
// CHECK:       ret

NM_PROBE(unsigned char, nm_ui8)
// CHECK-LABEL: define {{.*}} @nm_ui8(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_ui8(
// CHECK:       call {{.*}}@cq_theta_ui8(
// CHECK:       ret

NM_PROBE(short, nm_si16)
// CHECK-LABEL: define {{.*}} @nm_si16(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_si16(
// CHECK:       call {{.*}}@cq_theta_si16(
// CHECK:       ret

NM_PROBE(unsigned short, nm_ui16)
// CHECK-LABEL: define {{.*}} @nm_ui16(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_ui16(
// CHECK:       call {{.*}}@cq_theta_ui16(
// CHECK:       ret

NM_PROBE(int, nm_si32)
// CHECK-LABEL: define {{.*}} @nm_si32(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_si32(
// CHECK:       call {{.*}}@cq_theta_si32(
// CHECK:       ret

NM_PROBE(unsigned int, nm_ui32)
// CHECK-LABEL: define {{.*}} @nm_ui32(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_ui32(
// CHECK:       call {{.*}}@cq_theta_ui32(
// CHECK:       ret

NM_PROBE(long, nm_sl)
// CHECK-LABEL: define {{.*}} @nm_sl(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_sl(
// CHECK:       call {{.*}}@cq_theta_sl(
// CHECK:       ret

NM_PROBE(unsigned long, nm_ul)
// CHECK-LABEL: define {{.*}} @nm_ul(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_ul(
// CHECK:       call {{.*}}@cq_theta_ul(
// CHECK:       ret

NM_PROBE(long long, nm_sll)
// CHECK-LABEL: define {{.*}} @nm_sll(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_sll(
// CHECK:       call {{.*}}@cq_theta_sll(
// CHECK:       ret

NM_PROBE(unsigned long long, nm_ull)
// CHECK-LABEL: define {{.*}} @nm_ull(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_ull(
// CHECK:       call {{.*}}@cq_theta_ull(
// CHECK:       ret

NM_PROBE(float, nm_f32)
// CHECK-LABEL: define {{.*}} @nm_f32(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_f32(
// CHECK:       call {{.*}}@cq_theta_f32(
// CHECK:       ret

NM_PROBE(double, nm_f64)
// CHECK-LABEL: define {{.*}} @nm_f64(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_f64(
// CHECK:       call {{.*}}@cq_theta_f64(
// CHECK:       ret

NM_PROBE(_Float16, nm_f16)
// CHECK-LABEL: define {{.*}} @nm_f16(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_f16(
// CHECK:       call {{.*}}@cq_theta_f16(
// CHECK:       ret

NM_PROBE(long double, nm_f80)
// CHECK-LABEL: define {{.*}} @nm_f80(
// CHECK:       br i1
// CHECK:       call {{.*}}@cq_theta_f80(
// CHECK:       call {{.*}}@cq_theta_f80(
// CHECK:       ret
