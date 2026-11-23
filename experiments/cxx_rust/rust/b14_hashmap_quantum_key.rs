#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::collections::HashMap; use std::hash::*;
#[derive(Default, Clone)] struct H(u64); impl Hasher for H { fn finish(&self) -> u64 { self.0 } fn write(&mut self, b: &[u8]) { for c in b { self.0 = self.0.wrapping_mul(31).wrapping_add(*c as u64); } } fn write_i32(&mut self, i: i32) { self.0 = (i as u64).wrapping_mul(0x9E3779B97F4A7C15); } }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut m: HashMap<i32, i32, BuildHasherDefault<H>> = HashMap::default(); m.insert(1, 10); m.insert(5, 20); m.insert(3, y); m.get(&(q(x) & 7)).copied().unwrap_or(-1) }
