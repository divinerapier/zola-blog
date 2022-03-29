+++
title = "macro tokio::main"
date = 2021-05-30 11:28:19
[taxonomies]
tags = ["rust", "tokio"]
+++

在各种讲解 `async` 编程的的文章中，其使用的示例代码基本都类似于:

``` rust
use tokio::net::TcpListener;
use tokio::io::{AsyncReadExt, AsyncWriteExt};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let listener = TcpListener::bind("127.0.0.1:8080").await?;

    loop {
        let (mut socket, _) = listener.accept().await?;

        tokio::spawn(async move {
            let mut buf = [0; 1024];

            // In a loop, read data from the socket and write the data back.
            loop {
                let n = match socket.read(&mut buf).await {
                    // socket closed
                    Ok(n) if n == 0 => return,
                    Ok(n) => n,
                    Err(e) => {
                        eprintln!("failed to read from socket; err = {:?}", e);
                        return;
                    }
                };

                // Write the data back
                if let Err(e) = socket.write_all(&buf[0..n]).await {
                    eprintln!("failed to write to socket; err = {:?}", e);
                    return;
                }
            }
        });
    }
}
```

使用 `#[tokio::main]` 宏将 `async fn main` 函数转换成普通的 `fn main` 函数。但是却很少有文章说明更多关于 `#[tokio::main]` 的内容。

以下内容均来自官方[文档](https://docs.rs/tokio/1.6.1/tokio/attr.main.html)。

## 概述

在官方文档中说明了几点:

* 方便为被标记的 `async` 函数创建响应的运行时，而无需开发者直接操作 `tokio::runtime::Runtime` 或者 `tokio::runtime::Builder`。
* 仅限于面向不需要复杂设置与功能的 `async` 函数，否则仍建议直接使用 `tokio::runtime::Builder` 配置。
* 除用于 `async fn main` 函数之外，同样可用于其他任何函数(之后称作**一般函数**)。在配合一般函数使用时，每次进行函数调用时均会启动一个**新**的 `tokio::runtime::Runtime`，且函数的行为等同于同步函数。推荐对于需要被经常调用的函数**复用**由 `tokio::runtime::Builder` 创建的 `tokio::runtime::Runtime`。

## 常用配置

### Multi-threaded runtime

要使用 `Multi-threaded runtime` 功能，需要在 `Cargo.toml` 中启用 `rt-multi-thread` 功能:

``` toml
tokio = { version = "1.6", features = ["macros", "rt-multi-thread"] }
```

在启用 `rt-multi-thread` 功能后，默认工作线程数量为系统的 `cpu` 数量:

``` rust
#[tokio::main]
async fn main() {
    println!("Hello world");
}
```

等价于:

``` rust
fn main() {
    tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            println!("Hello world");
        })
}
```

也可以通过配置 `worker_thread` 选项来指定工作线程的数量:

``` rust
#[tokio::main(worker_threads = 2)]
async fn main() {
    println!("Hello world");
}
```

等价于:

``` rust
fn main() {
    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            println!("Hello world");
        })
}
```

### Current thread runtime

另一种是只是用单线程的模式:

``` rust
#[tokio::main(flavor = "current_thread")]
async fn main() {
    println!("Hello world");
}
```

等价于:

``` rust
fn main() {
    tokio::runtime::Builder::new_current_thread()
        .enable_all()
        .build()
        .unwrap()
        .block_on(async {
            println!("Hello world");
        })
}
```
