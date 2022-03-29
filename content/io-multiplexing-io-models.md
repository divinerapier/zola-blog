+++
title = "IO 模型"
date = 2021-05-09 16:34:02
[taxonomies]
tags = ["linux", "network programming", "io"]
+++

在 Unix/Linux 系统中，存在五中 `I/O` 模型:

* 阻塞式 I/O
* 非阻塞式 I/O
* I/O 复用 (select/poll)
* 信号驱动式 I/O (SIGIO)
* 异步 I/O (aio_系列函数)

一次输入操作通常会包括两个不同的阶段:

1. 等待数据准备好
2. 将数据从内核复制到进程

而对于一个发生在套接字上的输入操作，第一步是等待数据从网络中到达。当目标分组到达时，数据将被复制到内核中的某个缓冲区。第二步是把数据从内核缓冲区复制到应用进程缓冲区。

在之后的例子中，以 `UDP` 为例，并将函数 `recvfrom` 视为系统调用。

## 阻塞式 I/O 模型

最流行，最常用的 I/O 模型当属阻塞式 I/O (blocking I/O) 模型。并且，在默认情况下，所有的套接字都是阻塞式的。

![图-Blocking-IO-Model](/images/io-multiplexing-io-models/01-Blocking-IO-Model.png)

## 非阻塞式 I/O 模型

当进程将一个套接字设置成非阻塞式后，如果对其进行的 I/O 操作会导致当前进程进入到睡眠状态，内核会直接返回一个错误，避免进程进入到睡眠状态。

![图-Blocking-IO-Model](/images/io-multiplexing-io-models/02-Nonblocking-IO-Model.png)

上图所示，前三次调用 `recvfrom` 时均没有已就绪的数据，因此内核立刻返回了错误 `EWOULDBLOCK`。而当第四次调用 `recvfrom` 时，已有数据准备就绪，内核此时就会将这部分数据返回给进程。

当应用进程如上图所示对一个非阻塞的文件描述符循环调用 `recvfrom` 时，该过程被称作 **轮询 (polling)**。该过程通常会消耗大量的 `CPU` 资源。

## I/O 复用模型

目前主流系统系统了一种叫做 `I/O 多路复用 (I/O Multiplexing)` 的技术，允许一次监听多个文件描述符。

![图-Blocking-IO-Model](/images/io-multiplexing-io-models/03-Multiplexing-IO-Model.png)

对比 `I/O 多路复用` 的处理过程与 `阻塞式 I/O` 的处理过程，不难发现，阻塞式 `I/O` 模型的两个阶段均阻塞在 `recvfrom` 系统调用上，而 `I/O 多路复用` 模型将第一阶段阻塞在 `select` 系统调用上，而第二个阶段依然阻塞在 `recvfrom` 上。

## 信号驱动式 I/O 模型

当内核在文件描述符就绪时发送 `SIGIO` 信号通知应用进程。

![图-Blocking-IO-Model](/images/io-multiplexing-io-models/04-Signal-Driven-IO-Model.png)

## 异步 I/O

应用进程告知内核启动某个操作，并让内核在完成整个操作(包含两个阶段)后通知应用进程。该模型与信号驱动模型的区别在于: 信号驱动式I/O由内核通知应用进程何时可以启动I/O操作，而异步I/O模型是有内核通知应用进程I/O操作何时完成。

![图-Blocking-IO-Model](/images/io-multiplexing-io-models/05-Asynchronous-IO-Model.png)

## 参考资料

* [MAN Page: sigaction](https://man7.org/linux/man-pages/man2/sigaction.2.html)
* [SIGIO demo](https://man7.org/tlpi/code/online/dist/altio/demo_sigio.c.html)
