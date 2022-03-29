+++
title = "Docker container 137 错误码异常退出"
date = 2021-03-19 09:36:32
[taxonomies]
tags = ["docker", "kubernetes"]
+++

又是一次喜闻乐见的容器 **137** 错误码退出事件，事件案发现场如下:

``` bash
$ kubectl -n ns get pod
NAME                                 READY   STATUS      RESTARTS   AGE
cassification-xwcc2         0/1     Error       0          2d12h

$ kubectl -n ns describe pod cassification-xwcc2
Name:         cassification-xwcc2
Namespace:    ns
Priority:     0
Node:         n017.example.com/10.100.200.27
Start Time:   Tue, 16 Mar 2021 20:41:13 +0800
Labels:       controller-uid=9c5aed2c-895b-4012-8a06-9bb9d44d49b4
              job-name=cassification
Annotations:  <none>
Status:       Failed
IP:           10.216.3.55
IPs:
  IP:           10.216.3.55
Controlled By:  Job/cassification
Containers:
  cassification:
    Container ID:  docker://f0c2b1129c1c7ce74e8eff9633b31cc4d564a18b6fc5a1416a305df811420242
    Image:         harbor.exmple.com/pytorch:v3
    Image ID:      docker-pullable://harbor.exmple.com/pytorch@sha256:3197c2b34fb0b525652b5382d3f61c580700d80dd0332796bc1a96149b0853cc
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/bash
      -c
      sleep 8000000
    State:          Terminated
      Reason:       Error
      Exit Code:    137
      Started:      Tue, 16 Mar 2021 20:41:15 +0800
      Finished:     Thu, 18 Mar 2021 18:47:45 +0800
    Ready:          False
    Restart Count:  0
    Limits:
      cpu:             5
      memory:          50Gi
      nvidia.com/gpu:  2
    Requests:
      cpu:             5
      memory:          50Gi
      nvidia.com/gpu:  2
    Environment:       <none>
Conditions:
  Type              Status
  Initialized       True
  Ready             False
  ContainersReady   False
  PodScheduled      Trued
Volumes:
  default-token-9rxgg:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-9rxgg
    Optional:    false
QoS Class:       Guaranteed
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:          <none>
```

**137** 错误码大部分情况是超出资源被 `kill -9` 干掉了。但还是本着负责任的态度~~(空口无凭，研发不信)~~找出真相。

根据 `Container ID` 查看容器信息:

``` bash
$ docker inspect f0c2b1129c1c7ce74e8eff9633b31cc4d564a18b6fc5a1416a305df811420242
[
    {
        "Id": "f0c2b1129c1c7ce74e8eff9633b31cc4d564a18b6fc5a1416a305df811420242",
        "Created": "2021-03-16T12:41:15.010687771Z",
        "Path": "/bin/bash",
        "Args": [
            "-c",
            "sleep 8000000"
        ],
        "State": {
            "Status": "exited",
            "Running": false,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 0,
            "ExitCode": 137,
            "Error": "",
            "StartedAt": "2021-03-16T12:41:15.553418777Z",
            "FinishedAt": "2021-03-18T10:47:45.230995698Z"
        }
    }
]
```

很遗憾 `State.OOMKilled` 是 `false`，没关系，还可以查看 `dmesg` 信息:

``` bash
$ dmesg -T | grep killed | grep f0c2b1129c1c
[四 3月 18 18:47:12 2021] Task in /kubepods/pod3759885e-2d2e-45f6-a100-a1230831cbac/f0c2b1129c1c7ce74e8eff9633b31cc4d564a18b6fc5a1416a305df811420242 killed as a result of limit of /kubepods/pod3759885e-2d2e-45f6-a100-a1230831cbac
[四 3月 18 18:47:12 2021] Task in /kubepods/pod3759885e-2d2e-45f6-a100-a1230831cbac/f0c2b1129c1c7ce74e8eff9633b31cc4d564a18b6fc5a1416a305df811420242 killed as a result of limit of /kubepods/pod3759885e-2d2e-45f6-a100-a1230831cbac
[四 3月 18 18:47:12 2021] Task in /kubepods/pod3759885e-2d2e-45f6-a100-a1230831cbac/f0c2b1129c1c7ce74e8eff9633b31cc4d564a18b6fc5a1416a305df811420242 killed as a result of limit of /kubepods/pod3759885e-2d2e-45f6-a100-a1230831cbac
```

`dmesg` 的信息中的时间与 `container` 异常退出的时间非常接近。

至此，结案。
