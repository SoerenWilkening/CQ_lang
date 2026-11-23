#![allow(unused_imports, dead_code)]
include!("../cq.rs");
use std::{future::Future, pin::Pin, task::*};
struct Y(bool); impl Future for Y { type Output = i32; fn poll(mut self: Pin<&mut Self>, _: &mut Context<'_>) -> Poll<i32> { if self.0 { Poll::Ready(4) } else { self.0 = true; Poll::Pending } } }
async fn go(v: i32) -> i32 { let a = Y(false).await; let b = Y(false).await; v.wrapping_mul(a).wrapping_add(b) }
#[no_mangle] pub extern "C" fn f(x: i32, y: i32) -> i32 { let mut fu = Box::pin(go(q(x))); let mut cx = Context::from_waker(Waker::noop()); let mut n = y; loop { match fu.as_mut().poll(&mut cx) { Poll::Ready(v) => return v.wrapping_add(n), Poll::Pending => n = n.wrapping_add(1) } } }
