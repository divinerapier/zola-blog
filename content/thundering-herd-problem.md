+++
title = "惊群效应问题"
date = 2021-05-09 20:56:24
[taxonomies]
tags = []
+++

当计算机中存在大量的进程或线程被**同一个事件**唤醒，且该事件**能且仅能**被一个进程或线程响应的现象被称作**惊群效应**。此时，系统中相关的进程或线程都将争夺该资源，并大量浪费系统的性能。

## Accept 惊群

### Accept 流程

![accept](/images/thndering-herd-problem/01-accept.png)

### 代码示例

``` c
#include <arpa/inet.h>
#include <assert.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define SERVER_ADDRESS "0.0.0.0"
#define SERVER_PORT 10086
#define WORKER_COUNT 4

int worker_process(int listenfd, int i) {
  while (1) {
    printf("I am work %d, my pid is %d, begin to accept connections \n", i,
           getpid());
    struct sockaddr_in client_info;
    socklen_t client_info_len = sizeof(client_info);
    int connection =
        accept(listenfd, (struct sockaddr *)&client_info, &client_info_len);
    if (connection != -1) {
      printf("worker %d accept success\n", i);
      printf("ip :%s\t", inet_ntoa(client_info.sin_addr));
      printf("port: %d \n", client_info.sin_port);
    } else {
      printf("worker %d accept failed", i);
    }
    close(connection);
  }

  return 0;
}

int main() {
  int i = 0;
  struct sockaddr_in address;
  bzero(&address, sizeof(address));
  address.sin_family = AF_INET;
  inet_pton(AF_INET, SERVER_ADDRESS, &address.sin_addr);
  address.sin_port = htons(SERVER_PORT);
  int listenfd = socket(PF_INET, SOCK_STREAM, 0);
  int ret = bind(listenfd, (struct sockaddr *)&address, sizeof(address));
  ret = listen(listenfd, 5);
  for (i = 0; i < WORKER_COUNT; i++) {
    printf("Create worker %d\n", i + 1);
    pid_t pid = fork();
    /*child  process */
    if (pid == 0) {
      worker_process(listenfd, i);
    }
    if (pid < 0) {
      printf("fork error");
    }
  }

  /*wait child process*/
  int status;
  wait(&status);
  return 0;
}
```

## EPOLL

## Nginx

## 参考资料

* [Wikipedia: Thundering herd problem](https://en.wikipedia.org/wiki/Thundering_herd_problem)
* [Linux scalability: Accept() scalability on Linux](http://www.citi.umich.edu/projects/linux-scalability/reports/accept.html)
* [epoll: add EPOLLEXCLUSIVE flag](https://github.com/torvalds/linux/commit/df0108c5da561c66c333bb46bfe3c1fc65905898)
* [聊聊网络事件中的惊群效应](https://manjusaka.itscoder.com/posts/2019/03/28/somthing-about-thundering-herd/)
* [Linux惊群效应详解](https://blog.csdn.net/lyztyycode/article/details/78648798)
* [accept 与 epoll 惊群](https://pureage.info/2015/12/22/thundering-herd.html)
