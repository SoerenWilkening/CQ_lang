#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[derive(Clone, Copy, PartialEq)] struct F { n: i32, d: i32 }
impl core::ops::Add for F { type Output = F; fn add(self, o: F) -> F { F { n: self.n.wrapping_mul(o.d).wrapping_add(o.n.wrapping_mul(self.d)), d: self.d.wrapping_mul(o.d) } } }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let a = F { n: q(x), d: 3 }; let c = a + F { n: y, d: 5 } + a; if c.n < 100 { c.n } else { c.d } }
