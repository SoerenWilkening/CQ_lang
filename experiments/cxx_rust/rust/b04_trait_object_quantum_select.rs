#![allow(unused_imports, dead_code)]
include!("../cq.rs");
trait Op { fn go(&self, v: i32) -> i32; } struct A; struct M;
impl Op for A { fn go(&self, v: i32) -> i32 { v.wrapping_add(7) } } impl Op for M { fn go(&self, v: i32) -> i32 { v.wrapping_mul(3) } }
#[inline(never)] fn call(o: &dyn Op, v: i32) -> i32 { o.go(v) }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let o: &dyn Op = if q(x & 1 == 1) { &A } else { &M }; call(o, y) }
