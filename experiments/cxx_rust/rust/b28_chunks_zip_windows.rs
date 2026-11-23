#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let a = [1, q(x), 3, y, 5, 6]; let mut s = 0i32; for w in a.windows(2) { s = s.wrapping_add(w[0].wrapping_mul(w[1])); } for c in a.chunks(4) { s = s.wrapping_mul(3).wrapping_add(c[0]); } for (p, r) in a.iter().zip(a.iter().rev()) { s ^= p.wrapping_sub(*r); } s }
