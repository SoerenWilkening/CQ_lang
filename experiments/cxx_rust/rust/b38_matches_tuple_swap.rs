#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let (mut a, mut b) = (q(x), y); if matches!(a, 1..=9 | 20..=29) { core::mem::swap(&mut a, &mut b); } let t = (a, b, a < b); t.0.wrapping_sub(t.1).wrapping_add(t.2 as i32) }
