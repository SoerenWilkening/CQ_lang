#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut v = [y; 8]; let i = (q(x as u8) & 7) as usize; v[i] = v[i].wrapping_add(5); v[(i + 1) & 7].wrapping_mul(2).wrapping_add(v[3]) }
