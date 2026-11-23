#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut a = x as u8; theta(&mut a, 1.57); if a.wrapping_mul(a).wrapping_add(a.wrapping_mul(3)) % 16 == 4 { phi(3.14159); } inverted(|| theta(&mut a, 1.57)); if a == 0 { phi(3.14159); } let _ = y; measure(a) as i32 }
