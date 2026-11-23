#![allow(unused_imports, dead_code)]
include!("../cq.rs");
trait Sh { fn area(&self, k: i32) -> i32; } struct S(i32); struct R(i32, i32);
impl Sh for S { fn area(&self, k: i32) -> i32 { self.0.wrapping_mul(self.0).wrapping_add(k) } }
impl Sh for R { fn area(&self, k: i32) -> i32 { self.0.wrapping_mul(self.1).wrapping_sub(k) } }
#[inline(never)] fn total(s: &[&dyn Sh], k: i32) -> i32 { let mut t = 0i32; for e in s { t = t.wrapping_add(e.area(k)); } t }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { total(&[&S(q(x)), &R(x, y)], q(y)) }
