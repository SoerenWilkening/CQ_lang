#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let v = q(x); v.saturating_add(y).wrapping_add(v.checked_mul(3).unwrap_or(9)).wrapping_add(v.overflowing_sub(y).1 as i32).wrapping_add((v as i8).saturating_sub(y as i8) as i32) }
