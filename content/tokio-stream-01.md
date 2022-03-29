+++
title = "tokio stream"
date = 2021-05-30 17:15:46
[taxonomies]
tags = ["rust", "async", "tokio", "stream", "iterator"]
+++

如下所示代码，`sleep` 代替实际可能遇到的其他 `async` 函数，即希望通过使用 `async` 配合 `adaptor` 的组合处理 `iterator`。显然，如下代码无法通过编译，因为不允许在 `non-async` 代码块中使用 `.await`。而且，也不允许传入 `async` 函数给 `fold`。可以尝试的一种方法是通过 `futures::executor::block_on` 将 `async` 函数转换为 `non-async` 函数，但这个方法看起来有些蠢笨。好在，在 `async` 环境中存在 `stream` 可以使用。

``` rust
use std::time::Duration;

use futures::StreamExt;
use tokio::time::sleep;

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() {
    let mut handles = vec![];

    for index in 0..16 {
        let h = tokio::spawn(async move {
            println!("start index: {}", index);
            let res = (0u128..1000).fold(0u128, |a, b| {
                sleep(Duration::from_micros(1)).await;
                a + b * b
            });
            println!("finish index: {} res: {}", index, res);
        });
        handles.push(h);
    }

    for h in handles {
        let _res = h.await.unwrap();
    }
}
```

## Stream

根据[文档](https://doc.rust-lang.org/std/stream/index.html):

> If futures are asynchronous values, then streams are asynchronous iterators. If you’ve found yourself with an asynchronous collection of some kind, and needed to perform an operation on the elements of said collection, you’ll quickly run into ‘streams’. Streams are heavily used in idiomatic asynchronous Rust code, so it’s worth becoming familiar with them.

核心内容: `stream` 就是 `async` 编程中的 `iterator`。

### Iterator -> Stream

`crate futures` 提供的函数 `futures::stream::iter` 可以将一个 `iterator` 转换为 `stream`:

``` rust
/// Converts an `Iterator` into a `Stream` which is always ready
/// to yield the next value.
///
/// Iterators in Rust don't express the ability to block, so this adapter
/// simply always calls `iter.next()` and returns that.
pub fn iter<I>(i: I) -> Iter<I::IntoIter>
where
    I: IntoIterator,
{
    assert_stream::<I::Item, _>(Iter { iter: i.into_iter() })
}
```

例如:

``` rust
async fn foo() {
  futures::executor::block_on(async {
    use futures::stream::{self, StreamExt};

    let stream = stream::iter(vec![17, 19]);
    assert_eq!(vec![17, 19], stream.collect::<Vec<i32>>().await);
  });
}
```

## 使用 Stream 重构

整个重构的核心就是 `futures::stream::iter` 函数。

`main` 函数为:

``` rust
use std::time::Duration;

use futures::StreamExt;
use tokio::time::sleep;

#[tokio::main(flavor = "multi_thread", worker_threads = 2)]
async fn main() {
    let start = std::time::Instant::now();

    // for_loop().await

    // for_each().await;

    // map().await;

    println!("elapsed: {}", start.elapsed().as_secs_f64());
}
```

各种重构代码分别位于 `for_loop`, `for_each`, `map` 中。

### 使用 for-loop

``` rust
async fn for_loop() {
    let mut handles = vec![];

    for index in 0..16 {
        let h = tokio::spawn(async move {
            println!("start index: {}", index);
            sleep(Duration::from_secs(1)).await;
            let res = futures::stream::iter(0u128..1000).fold(0u128, |a, b| async move {
                sleep(Duration::from_nanos(1)).await;
                a + b * b
            });
            (index, res)
        });
        handles.push(h);
    }

    for h in handles {
        let res = h.await.unwrap();
        println!("index: {}. result: {}", res.0, res.1.await)
    }
}
```

输出为:

``` text
start index: 0
start index: 1
start index: 2
start index: 3
start index: 4
start index: 5
start index: 6
start index: 7
start index: 8
start index: 9
start index: 10
start index: 11
start index: 12
start index: 13
start index: 14
start index: 15
index: 0. result: 332833500
index: 1. result: 332833500
index: 2. result: 332833500
index: 3. result: 332833500
index: 4. result: 332833500
index: 5. result: 332833500
index: 6. result: 332833500
index: 7. result: 332833500
index: 8. result: 332833500
index: 9. result: 332833500
index: 10. result: 332833500
index: 11. result: 332833500
index: 12. result: 332833500
index: 13. result: 332833500
index: 14. result: 332833500
index: 15. result: 332833500
elapsed: 20.4097263
```

### 使用 for-each

``` rust
async fn for_each() {
    futures::stream::iter(0..16)
        .for_each(|index| async move {
            tokio::spawn(async move {
                println!("start index: {}", index);
                sleep(Duration::from_secs(1)).await;
                let res = futures::stream::iter(0u128..1000).fold(0u128, |a, b| async move {
                    sleep(Duration::from_nanos(1)).await;
                    a + b * b
                });
                println!("finish index: {} res: {}", index, res.await);
            })
            .await;
        })
        .await;
}
```

输出为:

``` text
start index: 0
finish index: 0 res: 332833500
start index: 1
finish index: 1 res: 332833500
start index: 2
finish index: 2 res: 332833500
start index: 3
finish index: 3 res: 332833500
start index: 4
finish index: 4 res: 332833500
start index: 5
finish index: 5 res: 332833500
start index: 6
finish index: 6 res: 332833500
start index: 7
finish index: 7 res: 332833500
start index: 8
finish index: 8 res: 332833500
start index: 9
finish index: 9 res: 332833500
start index: 10
finish index: 10 res: 332833500
start index: 11
finish index: 11 res: 332833500
start index: 12
finish index: 12 res: 332833500
start index: 13
finish index: 13 res: 332833500
start index: 14
finish index: 14 res: 332833500
start index: 15
finish index: 15 res: 332833500
elapsed: 35.0121356
```

### 使用 map

``` rust
async fn map() {
    let handles = futures::stream::iter(0..16)
        .map(|index| async move {
            tokio::spawn(async move {
                println!("start index: {}", index);
                sleep(Duration::from_secs(1)).await;
                let res = futures::stream::iter(0u128..1000).fold(0u128, |a, b| async move {
                    sleep(Duration::from_nanos(1)).await;
                    a + b * b
                });
                println!("finish index: {} res: {}", index, res.await);
            }).await
        }).collect::<Vec<_>>().await;

    async {
        for h in handles {
            let a = h.await.unwrap();
        }
    }.await
}
```

``` text
start index: 0
finish index: 0 res: 332833500
start index: 1
finish index: 1 res: 332833500
start index: 2
finish index: 2 res: 332833500
start index: 3
finish index: 3 res: 332833500
start index: 4
finish index: 4 res: 332833500
start index: 5
finish index: 5 res: 332833500
start index: 6
finish index: 6 res: 332833500
start index: 7
finish index: 7 res: 332833500
start index: 8
finish index: 8 res: 332833500
start index: 9
finish index: 9 res: 332833500
start index: 10
finish index: 10 res: 332833500
start index: 11
finish index: 11 res: 332833500
start index: 12
finish index: 12 res: 332833500
start index: 13
finish index: 13 res: 332833500
start index: 14
finish index: 14 res: 332833500
start index: 15
finish index: 15 res: 332833500
elapsed: 34.9667163
```

``` rust
async fn map() {
    let handles = futures::stream::iter(0..16)
        .map(|index| async move {
            tokio::spawn(async move {
                println!("start index: {}", index);
                sleep(Duration::from_secs(1)).await;
                let res = futures::stream::iter(0u128..1000).fold(0u128, |a, b| async move {
                    sleep(Duration::from_nanos(1)).await;
                    a + b * b
                });
                println!("finish index: {} res: {}", index, res.await);
            })
        }).collect::<Vec<_>>().await;

    async {
        for h in handles {
            let a = h.await.await.unwrap();
        }
    }.await
}
```

``` text
start index: 0
finish index: 0 res: 332833500
start index: 1
finish index: 1 res: 332833500
start index: 2
finish index: 2 res: 332833500
start index: 3
finish index: 3 res: 332833500
start index: 4
finish index: 4 res: 332833500
start index: 5
finish index: 5 res: 332833500
start index: 6
finish index: 6 res: 332833500
start index: 7
finish index: 7 res: 332833500
start index: 8
finish index: 8 res: 332833500
start index: 9
finish index: 9 res: 332833500
start index: 10
finish index: 10 res: 332833500
start index: 11
finish index: 11 res: 332833500
start index: 12
finish index: 12 res: 332833500
start index: 13
finish index: 13 res: 332833500
start index: 14
finish index: 14 res: 332833500
start index: 15
finish index: 15 res: 332833500
elapsed: 35.0125656
```

``` rust
async fn map() {
    let handles = futures::stream::iter(0..16)
        .map(|index| async move {
            let h =tokio::spawn(async move {
                println!("start index: {}", index);
                sleep(Duration::from_secs(1)).await;
                let res = futures::stream::iter(0u128..1000).fold(0u128, |a, b| async move {
                    sleep(Duration::from_nanos(1)).await;
                    a + b * b
                });
                (index, res)
            });
            h
        })
        .collect::<Vec<_>>()
        .await;

    async {
        for h in handles {
            let a = h.await.await.unwrap();
            println!("finish index: {} res: {}", a.0, a.1.await);
        }
    }
    .await
}
```

``` text
start index: 0
finish index: 0 res: 332833500
start index: 1
finish index: 1 res: 332833500
start index: 2
finish index: 2 res: 332833500
start index: 3
finish index: 3 res: 332833500
start index: 4
finish index: 4 res: 332833500
start index: 5
finish index: 5 res: 332833500
start index: 6
finish index: 6 res: 332833500
start index: 7
finish index: 7 res: 332833500
start index: 8
finish index: 8 res: 332833500
start index: 9
finish index: 9 res: 332833500
start index: 10
finish index: 10 res: 332833500
start index: 11
finish index: 11 res: 332833500
start index: 12
finish index: 12 res: 332833500
start index: 13
finish index: 13 res: 332833500
start index: 14
finish index: 14 res: 332833500
start index: 15
finish index: 15 res: 332833500
elapsed: 35.442368
```

具体的时间差异以后再来分析。
