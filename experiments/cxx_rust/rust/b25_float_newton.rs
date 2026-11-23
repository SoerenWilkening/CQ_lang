#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> f64 { let a = q(x as f64); let mut z = 1.0 + y as f64; for _ in 0..3 { z -= (z * z - a) / (2.0 * z); } z + a.abs().sqrt().floor() + a.max(2.0).clamp(-5.0, 5.0) }
