+++
title = "在非 async 函数中执行 async 语句块"
date = 2021-05-29 19:53:22
[taxonomies]
tags = ["rust", "async", "tokio"]
+++

在使用 `mongodb`，在未启用 `#[feature = "sync"]` 时，解析 `url` 的函数是一个 `async` 函数:

``` rust
/// crate: mongodb::options
impl ClientOptions {
    #[cfg(not(feature = "sync"))]
    pub async fn parse(s: impl AsRef<str>) -> Result<Self> {
        Self::parse_uri(s, None).await
    }
}
```

个人习惯，在业务项目中定义一个专属的配置类型:

``` rust
pub struct ClientOptions {
    pub uri: Option<String>,
    pub database: Option<String>,
    pub collection: Option<String>,
}
```

并为该类型实现 `From Trait`:

``` rust
impl From<ClientOptions> for mongodb::options::ClientOptions {
    fn from(opts: ClientOptions) -> Self {
        todo!()
    }
}
```

由于，`Trait` 的函数签名是无法改动的，就导致需要在 `non-async` 函数中调用 `async` 函数。

## 创建一个新的 Runtime

通过查阅[文档](https://docs.rs/tokio/1.6.1/tokio/)，根据关键字 `current` 查找到 [tokio::runtime::Builder::new_current_thread](https://docs.rs/tokio/1.6.1/tokio/runtime/struct.Builder.html#method.new_current_thread):

``` rust
impl Builder {
    /// Returns a new builder with the current thread scheduler selected.
    ///
    /// Configuration methods can be chained on the return value.
    ///
    /// To spawn non-`Send` tasks on the resulting runtime, combine it with a
    /// [`LocalSet`].
    ///
    /// [`LocalSet`]: crate::task::LocalSet
    pub fn new_current_thread() -> Builder {
        Builder::new(Kind::CurrentThread)
    }
}
```

使用当前线程创建一个调度器，看起来靠谱。由此，`from` 的实现如下:

``` rust
use tokio::runtime::Builder as RuntimeBuilder

impl From<ClientOptions> for mongodb::options::ClientOptions {
    fn from(opts: ClientOptions) -> Self {
        RuntimeBuilder::new_current_thread()
            .build()
            .unwrap()
            .block_on(async {
                mongodb::options::ClientOptions::parse(opts.uri.as_ref().unwrap())
                    .await
                    .unwrap()
            })
    }
}
```

但是，在执行时遇到一个错误:

``` bash
thread 'main' panicked at 'Cannot start a runtime from within a runtime. This happens because a function (like `block_on`) attempted to block the current thread while the thread is being used to drive asynchronous tasks.', /home/divinerapier/.cargo/registry/src/github.com-1ecc6299db9ec823/tokio-1.6.0/src/runtime/enter.rs:39:9
```

提示，不能在 `Runtime` 中执行另一个 `Runtime`。这里的第一个 `Runtime` 应该就是由 `#[tokio::main]` 自动创建的。

## 使用当前的 Runtime

在根据关键字 `current` 查找文档是，还存在另一个结果 [tokio::runtime::Handle::current](https://docs.rs/tokio/1.6.1/tokio/runtime/struct.Handle.html#method.current):

``` rust
impl Handle {
    /// Returns a `Handle` view over the currently running `Runtime`
    ///
    /// # Panic
    ///
    /// This will panic if called outside the context of a Tokio runtime. That means that you must
    /// call this on one of the threads **being run by the runtime**. Calling this from within a
    /// thread created by `std::thread::spawn` (for example) will cause a panic.
    ///
    /// # Examples
    ///
    /// This can be used to obtain the handle of the surrounding runtime from an async
    /// block or function running on that runtime.
    ///
    ///
    /// # use std::thread;
    /// # use tokio::runtime::Runtime;
    /// # fn dox() {
    /// # let rt = Runtime::new().unwrap();
    /// # rt.spawn(async {
    /// use tokio::runtime::Handle;
    ///
    /// // Inside an async block or function.
    /// let handle = Handle::current();
    /// handle.spawn(async {
    ///     println!("now running in the existing Runtime");
    /// });
    ///
    /// # let handle =
    /// thread::spawn(move || {
    ///     // Notice that the handle is created outside of this thread and then moved in
    ///     handle.spawn(async { /* ... */ })
    ///     // This next line would cause a panic
    ///     // let handle2 = Handle::current();
    /// });
    /// # handle.join().unwrap();
    /// # });
    /// # }
    ///
    pub fn current() -> Self {
        context::current().expect(CONTEXT_MISSING_ERROR)
    }
}
```

通过 `Handle::current` 函数可以获得当前的 `Runtime` 对象。

但是，需要注意，如下方式直接通过 `Handle` 调用 `Handle::block_on` 函数同样会遇到上面的错误。

``` rust
impl From<ClientOptions> for mongodb::options::ClientOptions {
    fn from(opts: ClientOptions) -> Self {
        let handle = Handle::current();
        handle.enter();
        handle.block_on(async {})
    }
}
```

应通过 `futures::executor::block_on` 函数来执行 `async` 函数。

``` rust
impl From<ClientOptions> for mongodb::options::ClientOptions {
    fn from(opts: ClientOptions) -> Self {
        let handle = Handle::current();
        handle.enter();
        futures::executor::block_on(async {
            mongodb::options::ClientOptions::parse(opts.uri.as_ref().unwrap())
                .await
                .unwrap()
        })
    }
}
```

### 惊

通过实验，只需要 `futures::executor::block_on` 函数就可以完成对 `async` 函数的调用。

上面就不改了，当做备忘录，避免以后采坑。

## 通过新的线程执行 async 函数

上面的一系列想法都是基于 **复用当前线程**，下面来尝试通过创建新的线程解决问题。

``` rust
use tokio::runtime::Builder as RuntimeBuilder;

impl From<ClientOptions> for mongodb::options::ClientOptions {
    fn from(opts: ClientOptions) -> Self {
        std::thread::spawn(move || {
            RuntimeBuilder::new_current_thread()
                .build()
                .unwrap()
                .block_on(async {
                    mongodb::options::ClientOptions::parse(opts.uri.as_ref().unwrap())
                        .await
                        .unwrap()
                })
        })
        .join()
        .unwrap()
    }
}
```

确认同样可以解决问题。

同样地，在新的线程中使用 `futures::executor::block_on` 同样可以解决问题。

``` rust
impl From<ClientOptions> for mongodb::options::ClientOptions {
    fn from(opts: ClientOptions) -> Self {
        std::thread::spawn(move || {
            futures::executor::block_on(async {
                mongodb::options::ClientOptions::parse(opts.uri.as_ref().unwrap())
                    .await
                    .unwrap()
            })
        })
        .join()
        .unwrap()
    }
}
```

## 参考

* [how-do-i-await-a-future-inside-a-non-async-method-which-was-called-from-an-async](https://stackoverflow.com/a/66280983)
