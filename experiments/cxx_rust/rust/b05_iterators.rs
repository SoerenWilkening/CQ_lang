#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let a = [1, y, 3, q(x), 5, 6]; let s: i32 = a.iter().map(|v| v.wrapping_mul(2)).filter(|v| v % 3 != 0).fold(0i32, |p, v| p.wrapping_add(v)); s.wrapping_add(a.iter().copied().max().unwrap_or(0)) }
