+++
title = "初识 MPI"
date = 2020-10-11 12:10:37
[taxonomies]
tags = ["mpi"]
+++

## 消息传递模型

**消息传递模型(Message Passing Model)** 指程序通过在进程间传递消息（消息可以理解成带有一些信息和数据的一个数据结构）来完成某些任务。在实践中，基于此模型，很容易开发 **并发程序**。

举例来说:

1. 主进程(manager process) 可以通过向从进程(worker process) 发送一个描述工作的消息的方式，将工作分配给从进程。
2. 一个并发的排序程序可以在当前进程中对当前进程可见的(我们称作本地的，locally) 数据进行排序，然后把排好序的数据发送到邻居进程上面来进行合并的操作。

几乎所有的并行程序可以使用消息传递模型来描述。

之后，业界统一制定了一套消息传递模型的接口标准，即 **Message Passing Interface —— MPI**。

## MPI 基础概念

### Communicator

**通讯器(communicator)** 定义了一组能够互相发消息的进程。

### Rank

在 **通讯器(communicator)** 中，每个进程会被分配一个序号，称作 **秩(rank)**，进程间显性地通过指定 **rank** 来进行通信。

### Tag

不同进程之间发送、接收操作是通信的基础。

作为发送者时，进程可以通过指定另一个进程的 **rank** 和一个独一无二的 **消息标签(tag)** 来发送消息给另一个进程。

作为接受者时，进程可以发送一个 **接收特定标签标记的消息的请求 (或者忽略标签，接收任何消息)**，然后依次处理接收到的数据。

### Point-to-Point Communications

一个发送者，一个接受者的通信被称作 **点对点(point-to-point) 通信**。

### Collective Communications

在很多情况下，某个进程可能需要跟所有其他进程通信。比如主进程想发一个广播给所有的从进程。在这种情况下，如果通过写代码的方式来完成所有的发送和接收过程会很麻烦。并且，事实上，这种方式往往也不会以最佳方式使用网络。MPI 可以处理各种各样的这些涉及所有进程的 **集体(Collective)通信** 类型。

## 使用 MPI

**MPI** 只是一套接口标准，无法直接使用。对此不必担心，业内已经存在很多符合标准的实现。其中 **OpenMPI** 就是最受欢迎的实现之一。因此，之后的内容基于 **OpenMPI** 展开。

### 安装 OpenMPI

从 [这里](https://www.open-mpi.org/software/ompi/v4.0/) 可以找到最新的版本，本文基于版本 [4.0.5](https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz)。

``` bash
# download package
$ wget https://download.open-mpi.org/release/open-mpi/v4.0/openmpi-4.0.5.tar.gz

# extract files
$ tar xzf openmpi-4.0.5.tar.gz

$ cd openmpi-4.0.5

# configure project
$ mkdir -p build; ./configure --prefix=$(pwd)/build

# build
$ make -j; make -j install
```

## 参考文档

* [MPI Tutorial Introduction](https://mpitutorial.com/tutorials/mpi-introduction/)
* [OpenMPI FAQ](https://www.open-mpi.org/faq/)
* [MPI Forum](https://www.mpi-forum.org/)
* [The "Introduction to MPI" and "Intermediate MPI" tutorials](https://www.citutor.org//browse.php)
* [UNIVERSITY OF HULL HPC: OpenMPI](http://hpc.mediawiki.hull.ac.uk/Applications/OpenMPI)
