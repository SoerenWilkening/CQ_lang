#![allow(unused_imports, dead_code)]
include!("../cq.rs");
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let a = [q(x as u8), 2, 3]; let b = [2u8, y as u8, 3]; let mut d = [[0i32; 4]; 4]; for i in 0..3 { for j in 0..3 { d[i + 1][j + 1] = if a[i] == b[j] { d[i][j] + 1 } else { d[i][j + 1].max(d[i + 1][j]) }; } } d[3][3] }
