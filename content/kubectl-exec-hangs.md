+++
title = "Kubectl Exec 无响应"
date = 2021-03-16 14:15:29
[taxonomies]
tags = ["linux", "docker", "containerd"]
+++

## 起因

在使用 `kubectl exec` 进入到 `pod` 时，进程会停止响应。

## 定位问题

### 确认 kubelet 问题

由于 `kubectl exec` 这个命令的实际执行链路非常长，所以，先简单粗暴的确认一下问题是否与 `kubelet` 有关。

登录到异常 `pod` 所在的节点，查看问题容器的 `container id`:

``` bash
$ docker ps

CONTAINER ID   IMAGE                      COMMAND                  CREATED        STATUS        PORTS     NAMES
0253de11b8f1   nvidia/k8s-device-plugin   "nvidia-device-plugi…"   10 hours ago   Up 10 hours             k8s_nvidia-device-plugin-ctr_nvidia-device-plugin-daemonset-jzrz7_kube-system_164ea21a-cc71-4cb0-8f83-6d160a720163_0
ecaa1fd07ce8   k8s.gcr.io/pause:3.1       "/pause"                 10 hours ago   Up 10 hours             k8s_POD_nvidia-device-plugin-daemonset-jzrz7_kube-system_164ea21a-cc71-4cb0-8f83-6d160a720163_0
e318f67bce5c   bdb21b3e4fdf               "/bin/bash -c 'sleep…"   15 hours ago   Up 15 hours             k8s_namespace-job_pod-w9lsq_xxxx_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx_0
c8d5fa9327ab   k8s.gcr.io/pause:3.1       "/pause"                 15 hours ago   Up 15 hours             k8s_POD_job-w9lsq_xxxx_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx_0
```

确认异常容器为 `e318f67bce5c`。

验证是否可以进入容器:

``` bash
$ docker exec -ti e318f67bce5c /bin/bash
# 无响应
```

此处的现象与 `kubectl exec` 如出一辙。因此，可以确定 `docker` 之后的链路一定有问题，所以先忽略 `kubelet`。

### 查看 Docker Daemon Profile

`Docker Daemon` 进程监听的是 `UNIX Socket`，通过 `socat` 转为 `TCP` 流量:

``` bash
socat -d -d TCP-LISTEN:8080,fork,bind=10.100.200.27 UNIX:/var/run/docker.sock
```

访问 `pprof` 的接口下载 `goroutine` 信息:

``` bash
wget -O all_goroutines http://10.100.200.27:8080/debug/pprof/goroutine?debug=2
```

精简之后，得到如下重要信息:

``` bash
$ cat all_goroutines

goroutine 87725 [select, 635 minutes]:
github.com/docker/docker/vendor/github.com/containerd/fifo.(*fifo).Write(0xc001768000, 0xc001282000, 0x1, 0x8000, 0x1, 0x0, 0x0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/containerd/fifo/fifo.go:195 +0xdb
io.copyBuffer(0x7f72d86f92a8, 0xc001cba740, 0x563d49513f80, 0xc0019983b0, 0xc001282000, 0x8000, 0x8000, 0x0, 0x1, 0x0)
  /usr/local/go/src/io/io.go:404 +0x1fd
io.CopyBuffer(0x7f72d86f92a8, 0xc001cba740, 0x563d49513f80, 0xc0019983b0, 0xc001282000, 0x8000, 0x8000, 0xc0011e4f90, 0xc0011e4f50, 0x563d465a9277)
  /usr/local/go/src/io/io.go:375 +0x84
github.com/docker/docker/pkg/pools.Copy(0x7f72d86f92a8, 0xc001cba740, 0x563d49513f80, 0xc0019983b0, 0xc0019983b0, 0x1, 0x563d465d6bd8)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/pkg/pools/pools.go:81 +0xa6
github.com/docker/docker/container/stream.(*Config).CopyToPipe.func2(0xc001092c60, 0x563d4954ce80, 0xc0019983b0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/stream/streams.go:142 +0xad
created by github.com/docker/docker/container/stream.(*Config).CopyToPipe
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/stream/streams.go:141 +0xbb

goroutine 87733 [select, 777 minutes]:
github.com/docker/docker/vendor/google.golang.org/grpc/internal/transport.(*Stream).waitOnHeader(0xc000a35a00)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/internal/transport/transport.go:318 +0xce
github.com/docker/docker/vendor/google.golang.org/grpc/internal/transport.(*Stream).RecvCompress(...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/internal/transport/transport.go:333
github.com/docker/docker/vendor/google.golang.org/grpc.(*csAttempt).recvMsg(0xc000b12e00, 0x563d4934b1a0, 0xc001e683c0, 0x0, 0xc0012f0360, 0x84)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/stream.go:871 +0x755
github.com/docker/docker/vendor/google.golang.org/grpc.(*clientStream).RecvMsg.func1(0xc000b12e00, 0x84, 0x84)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/stream.go:736 +0x48
github.com/docker/docker/vendor/google.golang.org/grpc.(*clientStream).withRetry(0xc0013eeea0, 0xc000adab30, 0xc000adab00, 0xc0012f0360, 0xc0016eedb8)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/stream.go:594 +0x9e
github.com/docker/docker/vendor/google.golang.org/grpc.(*clientStream).RecvMsg(0xc0013eeea0, 0x563d4934b1a0, 0xc001e683c0, 0x0, 0x0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/stream.go:735 +0x105
github.com/docker/docker/vendor/google.golang.org/grpc.invoke(0x563d495784c0, 0xc001e684b0, 0x563d481cdc32, 0x29, 0x563d49352ae0, 0xc00157aa40, 0x563d4934b1a0, 0xc001e683c0, 0xc000968380, 0xc0009fdda0, ...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/call.go:73 +0x13d
github.com/docker/docker/vendor/github.com/containerd/containerd.namespaceInterceptor.unary(0x563d4816cc49, 0x4, 0x563d49578440, 0xc000052038, 0x563d481cdc32, 0x29, 0x563d49352ae0, 0xc00157aa40, 0x563d4934b1a0, 0xc001e683c0, ...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/containerd/containerd/grpc.go:35 +0xf4
github.com/docker/docker/vendor/google.golang.org/grpc.(*ClientConn).Invoke(0xc000968380, 0x563d49578440, 0xc000052038, 0x563d481cdc32, 0x29, 0x563d49352ae0, 0xc00157aa40, 0x563d4934b1a0, 0xc001e683c0, 0x0, ...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/google.golang.org/grpc/call.go:35 +0x10b
github.com/docker/docker/vendor/github.com/containerd/containerd/api/services/tasks/v1.(*tasksClient).Start(0xc001574758, 0x563d49578440, 0xc000052038, 0xc00157aa40, 0x0, 0x0, 0x0, 0x1, 0xc0018b4210, 0xa2)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/containerd/containerd/api/services/tasks/v1/tasks.pb.go:1309 +0xd1
github.com/docker/docker/vendor/github.com/containerd/containerd.(*process).Start(0xc001e68390, 0x563d49578440, 0xc000052038, 0xc001634f40, 0x40)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/containerd/containerd/process.go:118 +0xef
github.com/docker/docker/libcontainerd/remote.(*client).Exec(0xc0001ee0e0, 0x563d49578440, 0xc000052038, 0xc00098bb80, 0x40, 0xc001634f40, 0x40, 0xc0009a4690, 0x1, 0xc001df0b00, ...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/libcontainerd/remote/client.go:324 +0x8cc
github.com/docker/docker/daemon.(*Daemon).ContainerExecStart(0xc00000c1e0, 0x563d49578440, 0xc000052038, 0xc000f5200b, 0x40, 0x563d495141e0, 0xc001998398, 0x7f72d86f9198, 0xc001998398, 0x0, ...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec.go:263 +0xd51
github.com/docker/docker/api/server/router/container.(*containerRouter).postContainerExecStart(0xc001516d40, 0x563d495784c0, 0xc001ca0f30, 0x563d495683c0, 0xc000284d20, 0xc001fb6900, 0xc001ca0e70, 0x0, 0x0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/router/container/exec.go:132 +0x42a
github.com/docker/docker/api/server/middleware.ExperimentalMiddleware.WrapHandler.func1(0x563d495784c0, 0xc001ca0f30, 0x563d495683c0, 0xc000284d20, 0xc001fb6900, 0xc001ca0e70, 0x563d495784c0, 0xc001ca0f30)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/middleware/experimental.go:26 +0x177
github.com/docker/docker/api/server/middleware.VersionMiddleware.WrapHandler.func1(0x563d495784c0, 0xc001ca0f00, 0x563d495683c0, 0xc000284d20, 0xc001fb6900, 0xc001ca0e70, 0x203000, 0x203000)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/middleware/version.go:62 +0x5fb
github.com/docker/docker/pkg/authorization.(*Middleware).WrapHandler.func1(0x563d495784c0, 0xc001ca0f00, 0x563d495683c0, 0xc000284d20, 0xc001fb6900, 0xc001ca0e70, 0x563d495784c0, 0xc001ca0f00)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/pkg/authorization/middleware.go:59 +0x826
github.com/docker/docker/api/server.(*Server).makeHTTPHandler.func1(0x563d495683c0, 0xc000284d20, 0xc001fb6800)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/server.go:141 +0x241
net/http.HandlerFunc.ServeHTTP(0xc000afa820, 0x563d495683c0, 0xc000284d20, 0xc001fb6800)
  /usr/local/go/src/net/http/server.go:2036 +0x46
github.com/docker/docker/vendor/github.com/gorilla/mux.(*Router).ServeHTTP(0xc00143c0c0, 0x563d495683c0, 0xc000284d20, 0xc001fb6600)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/gorilla/mux/mux.go:210 +0xe4
net/http.serverHandler.ServeHTTP(0xc000b6e000, 0x563d495683c0, 0xc000284d20, 0xc001fb6600)
  /usr/local/go/src/net/http/server.go:2831 +0xa6
net/http.(*conn).serve(0xc00140a0a0, 0x563d49578400, 0xc00190b3c0)
  /usr/local/go/src/net/http/server.go:1919 +0x877
created by net/http.(*Server).Serve
  /usr/local/go/src/net/http/server.go:2957 +0x386


goroutine 87735 [select, 773 minutes]:
io.(*pipe).Write(0xc000456640, 0xc0011be000, 0x1, 0x8000, 0x0, 0x0, 0x0)
  /usr/local/go/src/io/pipe.go:87 +0x1fd
io.(*PipeWriter).Write(0xc0019983a8, 0xc0011be000, 0x1, 0x8000, 0x1, 0x0, 0x0)
  /usr/local/go/src/io/pipe.go:153 +0x4e
io.copyBuffer(0x563d49513fa0, 0xc0019983a8, 0x563d495141e0, 0xc001998398, 0xc0011be000, 0x8000, 0x8000, 0x0, 0x2, 0x0)
  /usr/local/go/src/io/io.go:404 +0x1fd
io.CopyBuffer(0x563d49513fa0, 0xc0019983a8, 0x563d495141e0, 0xc001998398, 0xc0011be000, 0x8000, 0x8000, 0xc000a32600, 0xc0001aca80, 0x7f72fccad008)
  /usr/local/go/src/io/io.go:375 +0x84
github.com/docker/docker/pkg/pools.Copy(0x563d49513fa0, 0xc0019983a8, 0x563d495141e0, 0xc001998398, 0x4, 0xc0017e7f40, 0x563d465e2671)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/pkg/pools/pools.go:81 +0xa6
github.com/docker/docker/daemon.(*Daemon).ContainerExecStart.func2(0xc0019983a8, 0x563d495141e0, 0xc001998398)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec.go:204 +0x119
created by github.com/docker/docker/daemon.(*Daemon).ContainerExecStart
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec.go:201 +0x1a8c


goroutine 1428 [IO wait, 990 minutes]:
internal/poll.runtime_pollWait(0x7f72fcc11230, 0x72, 0xffffffffffffffff)
  /usr/local/go/src/runtime/netpoll.go:184 +0x57
internal/poll.(*pollDesc).wait(0xc001654d98, 0x72, 0x8001, 0x8000, 0xffffffffffffffff)
  /usr/local/go/src/internal/poll/fd_poll_runtime.go:87 +0x47
internal/poll.(*pollDesc).waitRead(...)
  /usr/local/go/src/internal/poll/fd_poll_runtime.go:92
internal/poll.(*FD).Read(0xc001654d80, 0xc001820000, 0x8000, 0x8000, 0x0, 0x0, 0x0)
  /usr/local/go/src/internal/poll/fd_unix.go:169 +0x1d1
os.(*File).read(...)
  /usr/local/go/src/os/file_unix.go:259
os.(*File).Read(0xc000a74130, 0xc001820000, 0x8000, 0x8000, 0xc00003c000, 0x563d490e5d40, 0x563d49134140)
  /usr/local/go/src/os/file.go:116 +0x73
github.com/docker/docker/vendor/github.com/containerd/fifo.(*fifo).Read(0xc001149d40, 0xc001820000, 0x8000, 0x8000, 0x0, 0xc0004cfe00, 0x563d4661ce19)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/containerd/fifo/fifo.go:179 +0x165
io.copyBuffer(0x563d49510a40, 0xc000afbcc0, 0x7f72fcc20678, 0xc001149d40, 0xc001820000, 0x8000, 0x8000, 0x563d48efedc0, 0x0, 0xc000e90ce0)
  /usr/local/go/src/io/io.go:402 +0x124
io.CopyBuffer(0x563d49510a40, 0xc000afbcc0, 0x7f72fcc20678, 0xc001149d40, 0xc001820000, 0x8000, 0x8000, 0xc000d50fc0, 0xc0004cff50, 0x563d465a9277)
  /usr/local/go/src/io/io.go:375 +0x84
github.com/docker/docker/pkg/pools.Copy(0x563d49510a40, 0xc000afbcc0, 0x7f72fcc20678, 0xc001149d40, 0xc001149d40, 0xc00194d2c0, 0x7f72fcbc9c50)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/pkg/pools/pools.go:81 +0xa6
github.com/docker/docker/container/stream.(*Config).CopyToPipe.func1.1(0x563d49510a40, 0xc000afbcc0, 0x7f72fcc5e830, 0xc001149d40, 0xc000f09810)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/stream/streams.go:124 +0x73
created by github.com/docker/docker/container/stream.(*Config).CopyToPipe.func1
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/stream/streams.go:123 +0x86


goroutine 364 [IO wait, 990 minutes]:
internal/poll.runtime_pollWait(0x7f72fcc11090, 0x72, 0xffffffffffffffff)
  /usr/local/go/src/runtime/netpoll.go:184 +0x57
internal/poll.(*pollDesc).wait(0xc00131c1f8, 0x72, 0x8001, 0x8000, 0xffffffffffffffff)
  /usr/local/go/src/internal/poll/fd_poll_runtime.go:87 +0x47
internal/poll.(*pollDesc).waitRead(...)
  /usr/local/go/src/internal/poll/fd_poll_runtime.go:92
internal/poll.(*FD).Read(0xc00131c1e0, 0xc00173c000, 0x8000, 0x8000, 0x0, 0x0, 0x0)
  /usr/local/go/src/internal/poll/fd_unix.go:169 +0x1d1
os.(*File).read(...)
  /usr/local/go/src/os/file_unix.go:259
os.(*File).Read(0xc001998040, 0xc00173c000, 0x8000, 0x8000, 0x2b, 0x0, 0x0)
  /usr/local/go/src/os/file.go:116 +0x73
github.com/docker/docker/vendor/github.com/containerd/fifo.(*fifo).Read(0xc000f30660, 0xc00173c000, 0x8000, 0x8000, 0x2b, 0x0, 0x0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/containerd/fifo/fifo.go:174 +0x1d8
io.copyBuffer(0x563d49510a40, 0xc0012ce520, 0x7f72fcc20678, 0xc000f30660, 0xc00173c000, 0x8000, 0x8000, 0x0, 0x0, 0x0)
  /usr/local/go/src/io/io.go:402 +0x124
io.CopyBuffer(0x563d49510a40, 0xc0012ce520, 0x7f72fcc20678, 0xc000f30660, 0xc00173c000, 0x8000, 0x8000, 0xc000a8d790, 0xc000a8d750, 0x563d465a9277)
  /usr/local/go/src/io/io.go:375 +0x84
github.com/docker/docker/pkg/pools.Copy(0x563d49510a40, 0xc0012ce520, 0x7f72fcc20678, 0xc000f30660, 0xc000f30660, 0x1, 0x563d465d6bd8)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/pkg/pools/pools.go:81 +0xa6
github.com/docker/docker/container/stream.(*Config).CopyToPipe.func1.1(0x563d49510a40, 0xc0012ce520, 0x7f72fcc5e830, 0xc000f30660, 0xc000e93860)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/stream/streams.go:124 +0x73
created by github.com/docker/docker/container/stream.(*Config).CopyToPipe.func1
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/stream/streams.go:123 +0x86


goroutine 101639 [semacquire, 120 minutes]:
sync.runtime_SemacquireMutex(0xc000b3a1f4, 0xc00255f600, 0x0)
  /usr/local/go/src/runtime/sema.go:71 +0x49
sync.(*RWMutex).RLock(...)
  /usr/local/go/src/sync/rwmutex.go:50
github.com/docker/docker/daemon/exec.(*Store).List(0xc000b3a1e0, 0xed7e1415b, 0x0, 0x563d481ba268)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec/exec.go:141 +0x1eb
github.com/docker/docker/container.(*Container).GetExecIDs(...)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/container/container.go:464
github.com/docker/docker/daemon.(*Daemon).getInspectData(0xc00000c1e0, 0xc001a1a280, 0x40, 0xc001a1a280, 0x0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/inspect.go:178 +0x5d2
github.com/docker/docker/daemon.(*Daemon).ContainerInspectCurrent(0xc00000c1e0, 0xc000a9d390, 0x40, 0x0, 0x1, 0xc000c5f8c8, 0xc00055ddc0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/inspect.go:42 +0xb4
github.com/docker/docker/daemon.(*Daemon).ContainerInspect(0xc00000c1e0, 0xc000a9d390, 0x40, 0x0, 0x563d4816c341, 0x4, 0xc000e0a700, 0x563d466a4f34, 0x8, 0x10)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/inspect.go:29 +0x11b
github.com/docker/docker/api/server/router/container.(*containerRouter).getContainersByName(0xc001516d40, 0x563d495784c0, 0xc0014d4e40, 0x563d495683c0, 0xc0021d37a0, 0xc000a35e00, 0xc0014d4d80, 0xc000e0a701, 0xc00239a160)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/router/container/inspect.go:15 +0x116
github.com/docker/docker/api/server/middleware.ExperimentalMiddleware.WrapHandler.func1(0x563d495784c0, 0xc0014d4e40, 0x563d495683c0, 0xc0021d37a0, 0xc000a35e00, 0xc0014d4d80, 0x563d495784c0, 0xc0014d4e40)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/middleware/experimental.go:26 +0x177
github.com/docker/docker/api/server/middleware.VersionMiddleware.WrapHandler.func1(0x563d495784c0, 0xc0014d4e10, 0x563d495683c0, 0xc0021d37a0, 0xc000a35e00, 0xc0014d4d80, 0x203000, 0x203000)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/middleware/version.go:62 +0x5fb
github.com/docker/docker/pkg/authorization.(*Middleware).WrapHandler.func1(0x563d495784c0, 0xc0014d4e10, 0x563d495683c0, 0xc0021d37a0, 0xc000a35e00, 0xc0014d4d80, 0x563d495784c0, 0xc0014d4e10)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/pkg/authorization/middleware.go:59 +0x826
github.com/docker/docker/api/server.(*Server).makeHTTPHandler.func1(0x563d495683c0, 0xc0021d37a0, 0xc000a35d00)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/api/server/server.go:141 +0x241
net/http.HandlerFunc.ServeHTTP(0xc0013cf660, 0x563d495683c0, 0xc0021d37a0, 0xc000a35d00)
  /usr/local/go/src/net/http/server.go:2036 +0x46
github.com/docker/docker/vendor/github.com/gorilla/mux.(*Router).ServeHTTP(0xc00143c0c0, 0x563d495683c0, 0xc0021d37a0, 0xc000a53400)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/vendor/github.com/gorilla/mux/mux.go:210 +0xe4
net/http.serverHandler.ServeHTTP(0xc000b6e000, 0x563d495683c0, 0xc0021d37a0, 0xc000a53400)
  /usr/local/go/src/net/http/server.go:2831 +0xa6
net/http.(*conn).serve(0xc001693c20, 0x563d49578400, 0xc0014a2480)
  /usr/local/go/src/net/http/server.go:1919 +0x877
created by net/http.(*Server).Serve
  /usr/local/go/src/net/http/server.go:2957 +0x386


goroutine 65 [semacquire, 776 minutes]:
sync.runtime_SemacquireMutex(0xc000b3a1f4, 0xc002094d00, 0x0)
  /usr/local/go/src/runtime/sema.go:71 +0x49
sync.(*RWMutex).RLock(...)
  /usr/local/go/src/sync/rwmutex.go:50
github.com/docker/docker/daemon/exec.(*Store).List(0xc000b3a1e0, 0xc0009a4a50, 0x1d, 0x1d)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec/exec.go:141 +0x1eb
github.com/docker/docker/daemon.(*Daemon).containerExecIds(0xc00000c1e0, 0xc002094f50)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec.go:335 +0x95
github.com/docker/docker/daemon.(*Daemon).execCommandGC(0xc00000c1e0)
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/exec.go:312 +0x178
created by github.com/docker/docker/daemon.NewDaemon
  /root/rpmbuild/BUILD/src/engine/.gopath/src/github.com/docker/docker/daemon/daemon.go:1136 +0x2aa0
```

通过 `kubectl` 得到 `docker` 版本信息:

``` bash
$ kubectl get node -o wide

NAME                          STATUS   ROLES    AGE    VERSION    INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION                CONTAINER-RUNTIME
n017.example.com   Ready    <none>   39d    v1.16.15   10.100.200.27   <none>        CentOS Linux 7 (Core)   4.19.12-1.el7.elrepo.x86_64   docker://20.10.3
```

下载 `docker` 源码:

``` bash
mkdir -p $GOPATH/github.com/docker/docker; cd $GOPATH/github.com/docker/docker

git clone https://github.com/moby/moby.git .

git checkout v20.10.3
```

#### 源码分析

##### goroutine 87725

根据栈信息，可以得到调用链为:

``` go
// docker/container/stream/streams.go
// CopyToPipe connects streamconfig with a libcontainerd.IOPipe
func (c *Config) CopyToPipe(iop *cio.DirectIO) {
  c.dio = iop
  copyFunc := func(w io.Writer, r io.ReadCloser) {
    c.wg.Add(1)
    go func() {
      if _, err := pools.Copy(w, r); err != nil {
        logrus.Errorf("stream copy error: %v", err)
      }
      r.Close()
      c.wg.Done()
    }()
  }

  if iop.Stdout != nil {
    copyFunc(c.Stdout(), iop.Stdout)
  }
  if iop.Stderr != nil {
    copyFunc(c.Stderr(), iop.Stderr)
  }

  if stdin := c.Stdin(); stdin != nil {
    if iop.Stdin != nil {
      go func() {
        pools.Copy(iop.Stdin, stdin)
        if err := iop.Stdin.Close(); err != nil {
          logrus.Warnf("failed to close stdin: %v", err)
        }
      }()
    }
  }
}

// docker/pkg/pools/pools.go
// Copy is a convenience wrapper which uses a buffer to avoid allocation in io.Copy.
func Copy(dst io.Writer, src io.Reader) (written int64, err error) {
  buf := buffer32KPool.Get()
  written, err = io.CopyBuffer(dst, src, *buf)
  buffer32KPool.Put(buf)
  return
}

// io/io.go

func CopyBuffer(dst Writer, src Reader, buf []byte) (written int64, err error) {
  if buf != nil && len(buf) == 0 {
    panic("empty buffer in CopyBuffer")
  }
  return copyBuffer(dst, src, buf)
}


func copyBuffer(dst Writer, src Reader, buf []byte) (written int64, err error) {
  // If the reader has a WriteTo method, use it to do the copy.
  // Avoids an allocation and a copy.
  if wt, ok := src.(WriterTo); ok {
    return wt.WriteTo(dst)
  }
  // ...
  return written, err
}

// Write from byte array to a fifo.
func (f *fifo) Write(b []byte) (int, error) {
  if f.flag&(syscall.O_WRONLY|syscall.O_RDWR) == 0 {
    return 0, ErrWrToRDONLY
  }
  select {
  case <-f.opened:
    return f.file.Write(b)
  default:
  }
  select { // 阻塞在这里
  case <-f.opened:
    return f.file.Write(b)
  case <-f.closed:
    return 0, ErrWriteClosed
  }
}
```

`goroutine` 阻塞在 `*fifo.Write` 函数中，只有当 `fifo.opened` 可读时，可以写入数据，当 `fifo.closed` 可读时，返回一个错误。

因此，找到有哪些情况 `fifo.opened` 可读，最后只找到了一种情况:

``` go
// docker/vendor/github.com/containerd/fifo/fifo.go

// OpenFifo opens a fifo. Returns io.ReadWriteCloser.
// Context can be used to cancel this function until open(2) has not returned.
// Accepted flags:
// - syscall.O_CREAT - create new fifo if one doesn't exist
// - syscall.O_RDONLY - open fifo only from reader side
// - syscall.O_WRONLY - open fifo only from writer side
// - syscall.O_RDWR - open fifo from both sides, never block on syscall level
// - syscall.O_NONBLOCK - return io.ReadWriteCloser even if other side of the
//     fifo isn't open. read/write will be connected after the actual fifo is
//     open or after fifo is closed.
//
// 注意 fn 表示 filename，不是 function...
func OpenFifo(ctx context.Context, fn string, flag int, perm os.FileMode) (io.ReadWriteCloser, error) {
  return openFifo(ctx, fn, flag, perm)
}

func openFifo(ctx context.Context, fn string, flag int, perm os.FileMode) (*fifo, error) {
  if _, err := os.Stat(fn); err != nil {
    if os.IsNotExist(err) && flag&syscall.O_CREAT != 0 {
      if err := mkfifo(fn, uint32(perm&os.ModePerm)); err != nil && !os.IsExist(err) {
        return nil, errors.Wrapf(err, "error creating fifo %v", fn)
      }
    } else {
      return nil, err
    }
  }

  block := flag&syscall.O_NONBLOCK == 0 || flag&syscall.O_RDWR != 0

  flag &= ^syscall.O_CREAT
  flag &= ^syscall.O_NONBLOCK

  h, err := getHandle(fn)
  if err != nil {
    return nil, err
  }

  f := &fifo{
    handle:  h,
    flag:    flag,
    opened:  make(chan struct{}),
    closed:  make(chan struct{}),
    closing: make(chan struct{}),
  }

  wg := leakCheckWg
  if wg != nil {
    wg.Add(2)
  }

  go func() {
    if wg != nil {
      defer wg.Done()
    }
    select {
    case <-ctx.Done():
      select {
      case <-f.opened:
      default:
        f.Close()
      }
    case <-f.opened:
    case <-f.closed:
    }
  }()
  go func() { // 这个 goroutine 中执行打开文件操作
    if wg != nil {
      defer wg.Done()
    }
    var file *os.File
    fn, err := h.Path()
    if err == nil {
      file, err = os.OpenFile(fn, flag, 0)
    }
    select {
    case <-f.closing:
      if err == nil {
        select {
        case <-ctx.Done():
          err = ctx.Err()
        default:
          err = errors.Errorf("fifo %v was closed before opening", h.Name())
        }
        if file != nil {
          file.Close()
        }
      }
    default:
    }
    if err != nil {
      f.closedOnce.Do(func() {
        f.err = err
        close(f.closed)
      })
      return
    }
    f.file = file
    close(f.opened) // 有且仅有一处可以触发 fifo.opened
  }()
  if block {
    select {
    case <-f.opened:
    case <-f.closed:
      return nil, f.err
    }
  }
  return f, nil
}
```

`OpenFifo` 与 `fifo.Write` 两个函数的调用一定是序列化的。因此，当成功获得一个 `fifo` 对象时，`fifo.opened` 就已经处于被关闭状态。并且，`fifo.opened` 是通过 `close(fifo.opened)` 的方式触发可读操作，所以，可以确认 `fifo.Write` 函数只可以写入一次:

* 首次调用 `fifo.Write` 时，在第一个 `select` 中执行 `case <-f.opened:` 语句，向 `fifo` 中写入数据。
* 再次调用 `fifo.Write` 时，在第二个 `select` 中执行 `default:` 语句，等待 `fifo.closed` 可读事件。

综上，当前 `goroutine` 在等待 `fifo.Close`。

##### goroutine 87733

根据堆栈信息，从下往上阅读，第一个重要的函数调用为 `docker/api/server/router/container/exec.go:132`，其中核心的逻辑如下:

``` go
// docker/api/server/router/container/exec.go:132

// TODO(vishh): Refactor the code to avoid having to specify stream config as part of both create and start.
func (s *containerRouter) postContainerExecStart(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
  // ...
  var (
    execName                  = vars["name"]
    stdin, inStream           io.ReadCloser
    stdout, stderr, outStream io.Writer
  )
  if !execStartCheck.Detach {
    inStream, outStream, _ = httputils.HijackConnection(w)

    stdin = inStream
    stdout = outStream
    if !execStartCheck.Tty {
      stderr = stdcopy.NewStdWriter(outStream, stdcopy.Stderr)
      stdout = stdcopy.NewStdWriter(outStream, stdcopy.Stdout)
    }
  }

  // Now run the user process in container.
  // Maybe we should we pass ctx here if we're not detaching?
  if err := s.backend.ContainerExecStart(context.Background(), execName, stdin, stdout, stderr); err != nil {
    if execStartCheck.Detach {
      return err
    }
  }
  return nil
}
```

调用 `s.backend.ContainerExecStart` 开启 `exec` 命令。

`s.backend` 的类型是一个接口:

``` go
type Backend interface {
  commitBackend
  execBackend
  copyBackend
  stateBackend
  monitorBackend
  attachBackend
  systemBackend
}
```

其只有一个具体实现 `docker/daemon/daemon.go#Daemon`

``` go
// ContainerExecStart starts a previously set up exec instance. The
// std streams are set up.
// If ctx is cancelled, the process is terminated.
func (daemon *Daemon) ContainerExecStart(ctx context.Context, name string, stdin io.Reader, stdout io.Writer, stderr io.Writer) (err error) {
  var (
    cStdin           io.ReadCloser
    cStdout, cStderr io.Writer
  )

  ec, err := daemon.getExecConfig(name)
  if err != nil {
    return errExecNotFound(name)
  }

  ec.Lock()
  if ec.ExitCode != nil {
    ec.Unlock()
    err := fmt.Errorf("Error: Exec command %s has already run", ec.ID)
    return errdefs.Conflict(err)
  }

  if ec.Running {
    ec.Unlock()
    return errdefs.Conflict(fmt.Errorf("Error: Exec command %s is already running", ec.ID))
  }
  ec.Running = true
  ec.Unlock()

  c := daemon.containers.Get(ec.ContainerID)
  logrus.Debugf("starting exec command %s in container %s", ec.ID, c.ID)
  attributes := map[string]string{
    "execID": ec.ID,
  }
  daemon.LogContainerEventWithAttributes(c, "exec_start: "+ec.Entrypoint+" "+strings.Join(ec.Args, " "), attributes)

  defer func() {
    if err != nil {
      ec.Lock()
      ec.Running = false
      exitCode := 126
      ec.ExitCode = &exitCode
      if err := ec.CloseStreams(); err != nil {
        logrus.Errorf("failed to cleanup exec %s streams: %s", c.ID, err)
      }
      ec.Unlock()
      c.ExecCommands.Delete(ec.ID, ec.Pid)
    }
  }()

  if ec.OpenStdin && stdin != nil {
    r, w := io.Pipe()
    go func() {
      defer w.Close()
      defer logrus.Debug("Closing buffered stdin pipe")
      pools.Copy(w, stdin)
    }()
    cStdin = r
  }
  if ec.OpenStdout {
    cStdout = stdout
  }
  if ec.OpenStderr {
    cStderr = stderr
  }

  if ec.OpenStdin {
    ec.StreamConfig.NewInputPipes()
  } else {
    ec.StreamConfig.NewNopInputPipe()
  }

  p := &specs.Process{}
  if runtime.GOOS != "windows" {
    ctr, err := daemon.containerdCli.LoadContainer(ctx, ec.ContainerID)
    if err != nil {
      return err
    }
    spec, err := ctr.Spec(ctx)
    if err != nil {
      return err
    }
    p = spec.Process
  }
  p.Args = append([]string{ec.Entrypoint}, ec.Args...)
  p.Env = ec.Env
  p.Cwd = ec.WorkingDir
  p.Terminal = ec.Tty

  if p.Cwd == "" {
    p.Cwd = "/"
  }

  if err := daemon.execSetPlatformOpt(c, ec, p); err != nil {
    return err
  }

  attachConfig := stream.AttachConfig{
    TTY:        ec.Tty,
    UseStdin:   cStdin != nil,
    UseStdout:  cStdout != nil,
    UseStderr:  cStderr != nil,
    Stdin:      cStdin,
    Stdout:     cStdout,
    Stderr:     cStderr,
    DetachKeys: ec.DetachKeys,
    CloseStdin: true,
  }
  ec.StreamConfig.AttachStreams(&attachConfig)
  attachErr := ec.StreamConfig.CopyStreams(ctx, &attachConfig)

  // Synchronize with libcontainerd event loop
  ec.Lock()
  c.ExecCommands.Lock()
  systemPid, err := daemon.containerd.Exec(ctx, c.ID, ec.ID, p, cStdin != nil, ec.InitializeStdio)
  // the exec context should be ready, or error happened.
  // close the chan to notify readiness
  close(ec.Started)
  if err != nil {
    c.ExecCommands.Unlock()
    ec.Unlock()
    return translateContainerdStartErr(ec.Entrypoint, ec.SetExitCode, err)
  }
  ec.Pid = systemPid
  c.ExecCommands.Unlock()
  ec.Unlock()

  select {
  case <-ctx.Done():
    logrus.Debugf("Sending TERM signal to process %v in container %v", name, c.ID)
    daemon.containerd.SignalProcess(ctx, c.ID, name, int(signal.SignalMap["TERM"]))

    timeout := time.NewTimer(termProcessTimeout)
    defer timeout.Stop()

    select {
    case <-timeout.C:
      logrus.Infof("Container %v, process %v failed to exit within %v of signal TERM - using the force", c.ID, name, termProcessTimeout)
      daemon.containerd.SignalProcess(ctx, c.ID, name, int(signal.SignalMap["KILL"]))
    case <-attachErr:
      // TERM signal worked
    }
    return ctx.Err()
  case err := <-attachErr:
    if err != nil {
      if _, ok := err.(term.EscapeError); !ok {
        return errdefs.System(errors.Wrap(err, "exec attach failed"))
      }
      attributes := map[string]string{
        "execID": ec.ID,
      }
      daemon.LogContainerEventWithAttributes(c, "exec_detach", attributes)
    }
  }
  return nil
}
```

根据调用栈可以看到，接下来会执行到 `daemon.containerd.Exec` 函数调用。首先将上述代码精简:

``` go
// getExecConfig looks up the exec instance by name. If the container associated
// with the exec instance is stopped or paused, it will return an error.
func (daemon *Daemon) getExecConfig(name string) (*exec.Config, error) {
  ec := daemon.execCommands.Get(name)

  ctr := daemon.containers.Get(ec.ContainerID)
  // ...
  return ec, nil
}
```

``` go
func (daemon *Daemon) ContainerExecStart(ctx context.Context, name string, stdin io.Reader, stdout io.Writer, stderr io.Writer) (err error) {
  ec, _ := daemon.getExecConfig(name)
  c := daemon.containers.Get(ec.ContainerID)
  // Synchronize with libcontainerd event loop
  ec.Lock()
  c.ExecCommands.Lock()
  systemPid, err := daemon.containerd.Exec(ctx, c.ID, ec.ID, p, cStdin != nil, ec.InitializeStdio)
  // the exec context should be ready, or error happened.
  // close the chan to notify readiness
  close(ec.Started)
  if err != nil {
    c.ExecCommands.Unlock()
    ec.Unlock()
    return translateContainerdStartErr(ec.Entrypoint, ec.SetExitCode, err)
  }
  ec.Pid = systemPid
  c.ExecCommands.Unlock()
  ec.Unlock()
}
```

在上面的函数中，通过 `name` 获取到了一个 `ec`，通过 `ec.ContainerID` 获取到了 `container`，然后对 `ec` 与 `container.ExecCommands` 加锁。

根据调用链可知当前 `goroutine` 执行进入了 `daemon.containerd.Exec`，所以执行函数之前锁住的两把锁都没有被释放，那么现在就有一个问题: 锁的粒度有多大？

为了解决这个疑问，就需要找到锁的源头: `name` 的来源，因为 `name` -> `ec` -> `Lock` / `Container` -> `Lock`。

回溯调用关系，`*Daemon.ContainerExecStart` 的调用者是路由回调函数 `*containerRouter.postContainerExecStart`，`*Daemon.ContainerExecStart` 的入参 `name` 是 `*containerRouter.postContainerExecStart` 的局部变量 `execName`。近一步回溯，`execName` 的来源是路由变量 `:name`，路由如下:

``` go
router.NewPostRoute("/exec/{name:.*}/start", r.postContainerExecStart)
```

为了知道 `name` 是什么，则需要查看 `Docker` 的 `API` 文档。

首先，通过命令 `docker version` 可以确定 `docker v20.10.3` 使用的 `API` 版本如下:

``` bash
$ docker version
Client: Docker Engine - Community
 Version:           20.10.3
 API version:       1.41
 Go version:        go1.13.15
 Git commit:        48d30b5
 Built:             Fri Jan 29 14:34:14 2021
 OS/Arch:           linux/amd64
 Context:           default
 Experimental:      true

Server: Docker Engine - Community
 Engine:
  Version:          20.10.3
  API version:      1.41 (minimum version 1.12)
  Go version:       go1.13.15
  Git commit:       46229ca
  Built:            Fri Jan 29 14:32:37 2021
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.4.3
  GitCommit:        269548fa27e0089a8b8278fc4fc781d7f65a939b
 nvidia:
  Version:          1.0.0-rc92
  GitCommit:        ff819c7e9184c13b7c2607fe6c30ae19403a7aff
 docker-init:
  Version:          0.19.0
  GitCommit:        de40ad0
```

即版本是 `API version: 1.41 (minimum version 1.12)`。

通过查阅 [Docker API Reference](https://docs.docker.com/engine/api) 获取具体的 [`API`](https://docs.docker.com/engine/api/v1.41/#operation/ExecStart):

``` HTTP
POST /exec/{id}/start

{
  "Detach": false,
  "Tty": false
}
```

> Path Parameters:
>
> * id
>   * string Required
>   * Exec instance ID

易得，`API` 文档中的 `id` 就是代码中的 `name`。

而 `exec id` 是通过如下 [`API`](https://docs.docker.com/engine/api/v1.41/#operation/ContainerExec) 获得(当然，这个属于盲猜，应该可以通过查阅 `docker client` 的 `exec` 命令部分的源码就能确定):

``` HTTP
POST /containers/{id}/exec

{
  "AttachStdin": false,
  "AttachStdout": true,
  "AttachStderr": true,
  "DetachKeys": "ctrl-p,ctrl-q",
  "Tty": false,
  "Cmd": [
    "date"
  ],
  "Env": [
    "FOO=bar",
    "BAZ=quux"
  ]
}
```

> Path Parameters:
>
> * id
>   * string Required
>   * ID or name of container

因此，可以得出结论，先调用 `ContainerExec` 通过 `container id` 获取 `exec id`，然后使用上面获得的 `exec id`调用 `ExecStart`。

但是，到此为止只是清楚了逻辑关系，还无法解答锁的粒度，或许应该看一下 `ContainerExec` 的逻辑。

根据路由信息 `router.NewPostRoute("/containers/{name:.*}/exec", r.postContainerExecCreate)`，找到 `ContainerExec` 的处理函数 `postContainerExecCreate` 中关于 `exec id` 部分的逻辑:

``` go
func (s *containerRouter) postContainerExecCreate(ctx context.Context, w http.ResponseWriter, r *http.Request, vars map[string]string) error {
  // ...
  name := vars["name"]

  execConfig := &types.ExecConfig{}
  json.NewDecoder(r.Body).Decode(execConfig)

  // Register an instance of Exec in container.
  id, err := s.backend.ContainerExecCreate(name, execConfig)
  if err != nil {
    logrus.Errorf("Error setting up exec command in container %s: %v", name, err)
    return err
  }

  return httputils.WriteJSON(w, http.StatusCreated, &types.IDResponse{
    ID: id,
  })
}
```

``` go
// ContainerExecCreate sets up an exec in a running container.
func (daemon *Daemon) ContainerExecCreate(name string, config *types.ExecConfig) (string, error) {
  // 通过 container name 获取当前处于活跃状态的 container
  cntr, _ := daemon.getActiveContainer(name)

  cmd := strslice.StrSlice(config.Cmd)
  entrypoint, args := daemon.getEntrypointAndArgs(strslice.StrSlice{}, cmd)

  keys := []byte{}
  if config.DetachKeys != "" {
    keys, _ = term.ToBytes(config.DetachKeys)
  }

  execConfig := exec.NewConfig()
  execConfig.OpenStdin = config.AttachStdin
  execConfig.OpenStdout = config.AttachStdout
  execConfig.OpenStderr = config.AttachStderr
  // config 的 container id 就是 container.ID 即容器的 ID
  execConfig.ContainerID = cntr.ID
  execConfig.DetachKeys = keys
  execConfig.Entrypoint = entrypoint
  execConfig.Args = args
  execConfig.Tty = config.Tty
  execConfig.Privileged = config.Privileged
  execConfig.User = config.User
  execConfig.WorkingDir = config.WorkingDir

  daemon.registerExecCommand(cntr, execConfig)

  return execConfig.ID, nil
}
```

``` go
// NewConfig initializes the a new exec configuration
func NewConfig() *Config {
   return &Config{
      ID:           stringid.GenerateRandomID(),
      StreamConfig: stream.NewConfig(),
      Started:      make(chan struct{}),
   }
}
```

``` go
func (daemon *Daemon) registerExecCommand(container *container.Container, config *exec.Config) {
  // Storing execs in container in order to kill them gracefully whenever the container is stopped or removed.
  container.ExecCommands.Add(config.ID, config)
  // Storing execs in daemon for easy access via Engine API.
  daemon.execCommands.Add(config.ID, config)
}
```

到此为止，逻辑关系就比较清晰了。`postContainerExecCreate` 的路由参数 `name` 就是 `container id`。`*Daemon.ContainerExecCreate` 内部创建了一个随机的 `exec id` 保存在 `execConfig` 中，同时在 `execConfig` 持有了 `container id`。所以，对于一个 `container` 的多次 `exec` 命令使用不同的 `exec id`，但他们共同持有相同的 `container id`。而后调用 `*Daemon.registerExecCommand` 将 `execConfig` 以 `exec id` 作为索引添加到缓存中。

回到函数 `func (daemon *Daemon) ContainerExecStart`，通过 `exec id` 可以获取到不同的 `ec` 对象，调用 `ec.Lock()` 的锁粒度为 `exec id`，对于同一个 `container` 的多次执行 `exec`，他们持有的 `container id` 是相同的，因此 `c.ExecCommands.Lock()` 的锁粒度是 `container` 级别。

综上所述，可以确定当前 `goroutine` 未释放两把锁资源，会导致之后的 `exec` 操作是一定会失败的。但阻塞在这里的原因还不清晰。从函数调用栈可以看到当前 `goroutine` 在等待 `gRPC` 的响应。

`daemon.containerd` 的类型是接口 `github.com/docker/docker/libcontainerd/types.Client`，其实现者是位于 `docker/libcontainerd/remote/client.go` 的 `struct client` 类型:

``` go
type client struct {
  client   *containerd.Client
  stateDir string
  logger   *logrus.Entry
  ns       string

  backend         libcontainerdtypes.Backend
  eventQ          queue.Queue
  oomMu           sync.Mutex
  oom             map[string]bool
  v2runcoptionsMu sync.Mutex
  // v2runcoptions is used for copying options specified on Create() to Start()
  v2runcoptions map[string]v2runcoptions.Options
}
```

其内部包含字段 `client` 是 `github.com/containerd/containerd/client.go` 的 `Client` 类型。

``` go
// docker/libcontainerd/remote/client.go:L265

// Exec creates exec process.
//
// The containerd client calls Exec to register the exec config in the shim side.
// When the client calls Start, the shim will create stdin fifo if needs. But
// for the container main process, the stdin fifo will be created in Create not
// the Start call. stdinCloseSync channel should be closed after Start exec
// process.
func (c *client) Exec(ctx context.Context, containerID, processID string, spec *specs.Process, withStdin bool, attachStdio libcontainerdtypes.StdioCallback) (int, error) {
  // 根据 containerID，获取到对应的 container 对象，
  // ctr 的类型是接口 github.com/containerd/containerd.Container
  // 其具体实现者是类型 *github.com/containerd/containerd.container
  ctr, err := c.getContainer(ctx, containerID)
  if err != nil {
    return -1, err
  }
  // Task is the executable object within containerd
  //
  // 通过 container 创建一个 github.com/containerd/containerd.task 类型，其实现了 Task 接口
  // 对 container 的每一次操作，都是一个 Task
  t, err := ctr.Task(ctx, nil)
  if err != nil {
    if containerderrors.IsNotFound(err) {
      return -1, errors.WithStack(errdefs.InvalidParameter(errors.New("container is not running")))
    }
    return -1, wrapError(err)
  }

  var (
    p              containerd.Process
    rio            cio.IO
    stdinCloseSync = make(chan struct{})
  )

  labels, err := ctr.Labels(ctx)
  if err != nil {
    return -1, wrapError(err)
  }

  fifos := newFIFOSet(labels[DockerContainerBundlePath], processID, withStdin, spec.Terminal)

  defer func() {
    if err != nil {
      if rio != nil {
        rio.Cancel()
        rio.Close()
      }
    }
  }()

  // Exec creates a new process inside the task

  p, err = t.Exec(ctx, processID, spec, func(id string) (cio.IO, error) {
    rio, err = c.createIO(fifos, containerID, processID, stdinCloseSync, attachStdio)
    return rio, err
  })
  if err != nil {
    close(stdinCloseSync)
    if containerderrors.IsAlreadyExists(err) {
      return -1, errors.WithStack(errdefs.Conflict(errors.New("id already in use")))
    }
    return -1, wrapError(err)
  }

  // Signal c.createIO that it can call CloseIO
  //
  // the stdin of exec process will be created after p.Start in containerd
  defer close(stdinCloseSync)

  if err = p.Start(ctx); err != nil {
    // use new context for cleanup because old one may be cancelled by user, but leave a timeout to make sure
    // we are not waiting forever if containerd is unresponsive or to work around fifo cancelling issues in
    // older containerd-shim
    ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
    defer cancel()
    p.Delete(ctx)
    return -1, wrapError(err)
  }
  return int(p.Pid()), nil
}
```

如下是函数 `task.Exec`，其内部调用了 `github.com/containerd/containerd.Client.TaskService().Exec` 函数执行 `Exec` 操作:

``` go
func (t *task) Exec(ctx context.Context, id string, spec *specs.Process, ioCreate cio.Creator) (_ Process, err error) {
  if id == "" {
    return nil, errors.Wrapf(errdefs.ErrInvalidArgument, "exec id must not be empty")
  }
  i, err := ioCreate(id)
  if err != nil {
    return nil, err
  }
  defer func() {
    if err != nil && i != nil {
      i.Cancel()
      i.Close()
    }
  }()
  any, err := typeurl.MarshalAny(spec)
  if err != nil {
    return nil, err
  }
  cfg := i.Config()
  request := &tasks.ExecProcessRequest{
    ContainerID: t.id,
    ExecID:      id,
    Terminal:    cfg.Terminal,
    Stdin:       cfg.Stdin,
    Stdout:      cfg.Stdout,
    Stderr:      cfg.Stderr,
    Spec:        any,
  }
  // 这是一个 gRPC  请求
  if _, err := t.client.TaskService().Exec(ctx, request); err != nil {
    i.Cancel()
    i.Wait()
    i.Close()
    return nil, errdefs.FromGRPC(err)
  }
  return &process{
    id:   id,
    task: t,
    io:   i,
  }, nil
}
```

``` go
// Start starts the exec process
func (p *process) Start(ctx context.Context) error {
  r, err := p.task.client.TaskService().Start(ctx, &tasks.StartRequest{
    ContainerID: p.task.id,
    ExecID:      p.id,
  })
  if err != nil {
    if p.io != nil {
      p.io.Cancel()
      p.io.Wait()
      p.io.Close()
    }
    return errdefs.FromGRPC(err)
  }
  p.pid = r.Pid
  return nil
}
```

### 查看进程状态

查看容器的 `pid`:

``` bash
$ docker inspect -f {{.State.Pid}} e318f67bce5c

^C
```

但很遗憾，当前无法执行 `docker inspect`。尝试根据 `container id` 获取 `pid`:

``` bash
$ ps -ef | grep e318f67bce5c
root      2645 12397  0 3月15 ?       00:00:00 /usr/bin/runc --root /var/run/docker/runtime-runc/moby --log /run/containerd/io.containerd.runtime.v2.task/moby/e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b/log.json --log-format json exec --process /tmp/runc-process256765632 --console-socket /tmp/pty518048165/pty.sock --detach --pid-file /run/containerd/io.containerd.runtime.v2.task/moby/e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b/12895df315fe38432c96579dd329ac4468f373781ba36bf272bbe3829a4afbd6.pid e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b
root     12397     1  0 3月15 ?       00:00:08 /usr/bin/containerd-shim-runc-v2 -namespace moby -id e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b -address /run/containerd/containerd.sock

$ ps aux | grep e318f67bce5c
root      2645  0.0  0.0 239068 18704 ?        Sl   3月15   0:00 /usr/bin/runc --root /var/run/docker/runtime-runc/moby --log /run/containerd/io.containerd.runtime.v2.task/moby/e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b/log.json --log-format json exec --process /tmp/runc-process256765632 --console-socket /tmp/pty518048165/pty.sock --detach --pid-file /run/containerd/io.containerd.runtime.v2.task/moby/e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b/12895df315fe38432c96579dd329ac4468f373781ba36bf272bbe3829a4afbd6.pid e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b
root     12397  0.0  0.0 111976 11632 ?        Sl   3月15   0:08 /usr/bin/containerd-shim-runc-v2 -namespace moby -id e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b -address /run/containerd/containerd.sock
```

果然可行，可以看到进程关系为 `pid 1` -> `pid 12397` -> `pid 2645`，即 `init` -> `containerd-shim-runc-v2` -> `runc`。

查看容器进程组:

``` bash
$ pstree -ap 2645
runc,2645 --root /var/run/docker/runtime-runc/moby --log /run/containerd/io.containerd.runtime.v2.task/moby/e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b/log.json --log-format json exec --process /tmp/runc-process256765632 --console-socket/tmp/pt
  ├─runc:[2:INIT],2658 init
  │   ├─{runc:[2:INIT]},2659
  │   ├─{runc:[2:INIT]},2660
  │   ├─{runc:[2:INIT]},2661
  │   ├─{runc:[2:INIT]},2662
  │   └─{runc:[2:INIT]},2663
  ├─{runc},2650
  ├─{runc},2651
  ├─{runc},2652
  ├─{runc},2653
  ├─{runc},2654
  └─{runc},2655
```

``` bash
$ ls -al /proc/2645/fd
总用量 0
dr-x------ 2 root root  0 3月  16 12:46 .
dr-xr-xr-x 9 root root  0 3月  15 23:20 ..
lr-x------ 1 root root 64 3月  16 12:46 0 -> /dev/null
l-wx------ 1 root root 64 3月  16 12:46 1 -> pipe:[1658705]
l-wx------ 1 root root 64 3月  16 12:46 2 -> pipe:[1658705]
lrwx------ 1 root root 64 3月  16 12:46 27 -> /dev/pts/ptmx
l-wx------ 1 root root 64 3月  16 12:46 3 -> /run/containerd/io.containerd.runtime.v2.task/moby/e318f67bce5c36e39bc2e0c136ea9cd366b22ba5ae216c485232ce4a0541858b/log.json
lrwx------ 1 root root 64 3月  16 12:46 4 -> anon_inode:[eventpoll]
lrwx------ 1 root root 64 3月  16 12:46 5 -> socket:[1727233]
lrwx------ 1 root root 64 3月  16 12:46 6 -> socket:[1727233]
lrwx------ 1 root root 64 3月  16 12:46 8 -> socket:[1727235]
lr-x------ 1 root root 64 3月  16 12:46 9 -> pipe:[1727236]
```

``` bash
$ pstack 2645
Thread 7 (Thread 0x7fdd5f98b700 (LWP 2650)):
#0  runtime.futex () at /usr/local/go/src/runtime/sys_linux_amd64.s:536
#1  0x000055dcaf1afd34 in runtime.futexsleep (addr=0x55dcafe6eb10 <runtime.sched+272>, val=0, ns=60000000000) at /usr/local/go/src/runtime/os_linux.go:50
#2  0x000055dcaf18f3b0 in runtime.notetsleep_internal (n=0x55dcafe6eb10 <runtime.sched+272>, ns=60000000000, ~r2=<optimized out>) at /usr/local/go/src/runtime/lock_futex.go:193
#3  0x000055dcaf18f485 in runtime.notetsleep (n=0x55dcafe6eb10 <runtime.sched+272>, ns=60000000000, ~r2=<optimized out>) at /usr/local/go/src/runtime/lock_futex.go:216
#4  0x000055dcaf1bebf0 in runtime.sysmon () at /usr/local/go/src/runtime/proc.go:4322
#5  0x000055dcaf1b6eb7 in runtime.mstart1 () at /usr/local/go/src/runtime/proc.go:1201
#6  0x000055dcaf1b6dd0 in runtime.mstart () at /usr/local/go/src/runtime/proc.go:1167
#7  0x000055dcaf63ef13 in crosscall_amd64 () at gcc_amd64.S:35
#8  0x00007fdd5f98b700 in ?? ()
#9  0x0000000000000000 in ?? ()
Thread 6 (Thread 0x7fdd5f18a700 (LWP 2651)):
#0  runtime.futex () at /usr/local/go/src/runtime/sys_linux_amd64.s:536
#1  0x000055dcaf1afcb6 in runtime.futexsleep (addr=0xc000042848, val=0, ns=-1) at /usr/local/go/src/runtime/os_linux.go:44
#2  0x000055dcaf18f223 in runtime.notesleep (n=0xc000042848) at /usr/local/go/src/runtime/lock_futex.go:151
#3  0x000055dcaf1b8404 in runtime.stopm () at /usr/local/go/src/runtime/proc.go:1934
#4  0x000055dcaf1b9535 in runtime.findrunnable (gp=0xc00002c000, inheritTime=false) at /usr/local/go/src/runtime/proc.go:2397
#5  0x000055dcaf1ba1f2 in runtime.schedule () at /usr/local/go/src/runtime/proc.go:2530
#6  0x000055dcaf1ba533 in runtime.park_m (gp=0xc000000180) at /usr/local/go/src/runtime/proc.go:2616
#7  0x000055dcaf1de0e3 in runtime.mcall () at /usr/local/go/src/runtime/asm_amd64.s:318
#8  0x0000000000000000 in ?? ()
Thread 5 (Thread 0x7fdd5e989700 (LWP 2652)):
#0  runtime.futex () at /usr/local/go/src/runtime/sys_linux_amd64.s:536
#1  0x000055dcaf1afcb6 in runtime.futexsleep (addr=0x55dcafe8b560 <runtime.sig>, val=0, ns=-1) at /usr/local/go/src/runtime/os_linux.go:44
#2  0x000055dcaf18f308 in runtime.notetsleep_internal (n=0x55dcafe8b560 <runtime.sig>, ns=-1, ~r2=<optimized out>) at /usr/local/go/src/runtime/lock_futex.go:174
#3  0x000055dcaf18f510 in runtime.notetsleepg (n=0x55dcafe8b560 <runtime.sig>, ns=-1, ~r2=<optimized out>) at /usr/local/go/src/runtime/lock_futex.go:228
#4  0x000055dcaf1c85be in os/signal.signal_recv (~r0=<optimized out>) at /usr/local/go/src/runtime/sigqueue.go:147
#5  0x000055dcaf60ee84 in os/signal.loop () at /usr/local/go/src/os/signal/signal_unix.go:23
#6  0x000055dcaf1e01f1 in runtime.goexit () at /usr/local/go/src/runtime/asm_amd64.s:1357
#7  0x0000000000000000 in ?? ()
Thread 4 (Thread 0x7fdd5e188700 (LWP 2653)):
#0  runtime.epollwait () at /usr/local/go/src/runtime/sys_linux_amd64.s:673
#1  0x000055dcaf1afb72 in runtime.netpoll (block=true, ~r1=...) at /usr/local/go/src/runtime/netpoll_epoll.go:71
#2  0x000055dcaf1b950b in runtime.findrunnable (gp=0xc000030a00, inheritTime=false) at /usr/local/go/src/runtime/proc.go:2378
#3  0x000055dcaf1ba1f2 in runtime.schedule () at /usr/local/go/src/runtime/proc.go:2530
#4  0x000055dcaf1ba533 in runtime.park_m (gp=0xc0001ba480) at /usr/local/go/src/runtime/proc.go:2616
#5  0x000055dcaf1de0e3 in runtime.mcall () at /usr/local/go/src/runtime/asm_amd64.s:318
#6  0x0000000000000000 in ?? ()
Thread 3 (Thread 0x7fdd5d987700 (LWP 2654)):
#0  runtime.futex () at /usr/local/go/src/runtime/sys_linux_amd64.s:536
#1  0x000055dcaf1afcb6 in runtime.futexsleep (addr=0x55dcafe8b478 <runtime.newmHandoff+24>, val=0, ns=-1) at /usr/local/go/src/runtime/os_linux.go:44
#2  0x000055dcaf18f223 in runtime.notesleep (n=0x55dcafe8b478 <runtime.newmHandoff+24>) at /usr/local/go/src/runtime/lock_futex.go:151
#3  0x000055dcaf1b8324 in runtime.templateThread () at /usr/local/go/src/runtime/proc.go:1912
#4  0x000055dcaf1b6eb7 in runtime.mstart1 () at /usr/local/go/src/runtime/proc.go:1201
#5  0x000055dcaf1b6dd0 in runtime.mstart () at /usr/local/go/src/runtime/proc.go:1167
#6  0x000055dcaf63ef13 in crosscall_amd64 () at gcc_amd64.S:35
#7  0x00007fdd5d987700 in ?? ()
#8  0x0000000000000000 in ?? ()
Thread 2 (Thread 0x7fdd5d186700 (LWP 2655)):
#0  syscall.Syscall () at /usr/local/go/src/syscall/asm_linux_amd64.s:27
#1  0x000055dcaf233f4c in syscall.read (fd=8, p=<error reading variable: access outside bounds of object referenced via synthetic pointer>, n=<optimized out>, err=...) at /usr/local/go/src/syscall/zsyscall_linux_amd64.go:732
#2  0x000055dcaf24c986 in syscall.Read (fd=<optimized out>, p=..., n=<optimized out>, err=...) at /usr/local/go/src/syscall/syscall_unix.go:183
#3  internal/poll.(*FD).Read (fd=0xc00014f080, p=..., ~r1=<optimized out>, ~r2=...) at /usr/local/go/src/internal/poll/fd_unix.go:165
#4  0x000055dcaf254813 in os.(*File).read (f=0xc000154818, b=..., n=<optimized out>, err=...) at /usr/local/go/src/os/file_unix.go:259
#5  os.(*File).Read (f=0xc000154818, b=..., n=<optimized out>, err=...) at /usr/local/go/src/os/file.go:116
#6  0x000055dcaf37a54d in encoding/json.(*Decoder).refill (dec=0xc0001cec60, ~r0=...) at /usr/local/go/src/encoding/json/stream.go:161
#7  0x000055dcaf37a2de in encoding/json.(*Decoder).readValue (dec=0xc0001cec60, ~r0=<optimized out>, ~r1=...) at /usr/local/go/src/encoding/json/stream.go:136
#8  0x000055dcaf379dab in encoding/json.(*Decoder).Decode (dec=0xc0001cec60, v=..., ~r1=...) at /usr/local/go/src/encoding/json/stream.go:63
#9  0x000055dcaf5ca997 in github.com/opencontainers/runc/libcontainer.parseSync (pipe=..., fn={void (github.com/opencontainers/runc/libcontainer.syncT *, error *)} 0xc0001a28f8, ~r2=...) at /go/src/github.com/opencontainers/runc/libcontainer/sync.go:76
#10 0x000055dcaf5bc1ff in github.com/opencontainers/runc/libcontainer.(*setnsProcess).start (p=0xc00022e6c0, err=...) at /go/src/github.com/opencontainers/runc/libcontainer/process_linux.go:146
#11 0x000055dcaf5a3564 in github.com/opencontainers/runc/libcontainer.(*linuxContainer).start (c=0xc00020c000, process=0xc00017d540, ~r1=...) at /go/src/github.com/opencontainers/runc/libcontainer/container_linux.go:365
#12 0x000055dcaf5a2a8d in github.com/opencontainers/runc/libcontainer.(*linuxContainer).Start (c=0xc00020c000, process=0xc00017d540, ~r1=...) at /go/src/github.com/opencontainers/runc/libcontainer/container_linux.go:262
#13 0x000055dcaf5a2c6b in github.com/opencontainers/runc/libcontainer.(*linuxContainer).Run (c=0xc00020c000, process=0xc00017d540, ~r1=...) at /go/src/github.com/opencontainers/runc/libcontainer/container_linux.go:272
#14 0x000055dcaf633fb8 in main.(*runner).run (r=0xc0001a3490, config=0xc00020c0f0, ~r1=<optimized out>, ~r2=...) at /go/src/github.com/opencontainers/runc/utils_linux.go:322
#15 0x000055dcaf629394 in main.execProcess (context=0xc0001ce160, ~r1=<optimized out>, ~r2=...) at /go/src/github.com/opencontainers/runc/exec.go:157
#16 0x000055dcaf636635 in main.glob..func5 (context=0xc0001ce160, ~r1=...) at /go/src/github.com/opencontainers/runc/exec.go:104
#17 0x000055dcaf5f3180 in github.com/urfave/cli.HandleAction (action=..., context=0xc0001ce160, err=...) at /go/src/github.com/opencontainers/runc/vendor/github.com/urfave/cli/app.go:523
#18 0x000055dcaf5f3eee in github.com/urfave/cli.Command.Run (c=..., ctx=0xc0001ce000, err=...) at /go/src/github.com/opencontainers/runc/vendor/github.com/urfave/cli/command.go:174
#19 0x000055dcaf5f122a in github.com/urfave/cli.(*App).Run (a=0xc0001c2000, arguments=..., err=...) at /go/src/github.com/opencontainers/runc/vendor/github.com/urfave/cli/app.go:276
#20 0x000055dcaf62c4b9 in main.main () at /go/src/github.com/opencontainers/runc/main.go:151
Thread 1 (Thread 0x7fdd625dc740 (LWP 2645)):
#0  runtime.futex () at /usr/local/go/src/runtime/sys_linux_amd64.s:536
#1  0x000055dcaf1afcb6 in runtime.futexsleep (addr=0x55dcafe6f448 <runtime.m0+328>, val=0, ns=-1) at /usr/local/go/src/runtime/os_linux.go:44
#2  0x000055dcaf18f223 in runtime.notesleep (n=0x55dcafe6f448 <runtime.m0+328>) at /usr/local/go/src/runtime/lock_futex.go:151
#3  0x000055dcaf1b8a6c in runtime.stoplockedm () at /usr/local/go/src/runtime/proc.go:2074
#4  0x000055dcaf1ba3b9 in runtime.schedule () at /usr/local/go/src/runtime/proc.go:2475
#5  0x000055dcaf1ba533 in runtime.park_m (gp=0xc0001ba300) at /usr/local/go/src/runtime/proc.go:2616
#6  0x000055dcaf1de0e3 in runtime.mcall () at /usr/local/go/src/runtime/asm_amd64.s:318
#7  0x000055dcaf1de008 in runtime.rt0_go () at /usr/local/go/src/runtime/asm_amd64.s:220
#8  0x0000000000000000 in ?? ()
```

``` bash
$ pstack 2658
# 此处无响应
# killall -9 pstack
# killall -9 gdb
```

``` bash
$ cat /proc/2658/stack
[<0>] ceph_mdsc_do_request+0x186/0x240 [ceph]
[<0>] __ceph_do_getattr+0x9d/0x200 [ceph]
[<0>] ceph_permission+0x2a/0x50 [ceph]
[<0>] inode_permission+0xc0/0x150
[<0>] ksys_chdir+0x59/0xd0
[<0>] __x64_sys_chdir+0x12/0x20
[<0>] do_syscall_64+0x60/0x190
[<0>] entry_SYSCALL_64_after_hwframe+0x44/0xa9
[<0>] 0xffffffffffffffff
```
