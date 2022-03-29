+++
title = "'ldconfig: /usr/lib/wsl/lib/libcuda.so.1 is not a symbolic link'"
date = 2022-01-17 21:27:28
[taxonomies]
tags = ["linux", "wsl"]
+++

### 环境

``` text
版本          Windows 11 专业版
版本          21H2
安装日期       2022/1/13
操作系统版本   22000.466
体验          Windows 功能体验包 1000.22000.466.0
```

``` bash
$ uname -a
Linux xeon 5.10.16.3-microsoft-standard-WSL2 #1 SMP Fri Apr 2 22:23:49 UTC 2021 x86_64 GNU/Linux
```

``` bash
$ nvidia-smi
Mon Jan 17 21:32:44 2022
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 495.53       Driver Version: 497.29       CUDA Version: 11.5     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  NVIDIA GeForce ...  On   | 00000000:01:00.0  On |                  N/A |
|  0%   51C    P0    76W / 310W |   2225MiB /  8192MiB |     N/A      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+

+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|  No running processes found                                                 |
+-----------------------------------------------------------------------------+
```

### 问题

``` bash
$ sudo ldconfig
ldconfig: /usr/lib/wsl/lib/libcuda.so.1 is not a symbolic link
```

### 解决方法

1. 使用管理员权限执行 `cmd` 命令:

    ``` cmd
    c:\Users\david>cd c:\Windows\System32\lxss\lib
    c:\Windows\System32\lxss\lib>del /s /q "libcuda.so"
    c:\Windows\System32\lxss\lib>del /s /q "libcuda.so.1"
    c:\Windows\System32\lxss\lib>mklink libcuda.so libcuda.so.1.1
    c:\Windows\System32\lxss\lib>mklink libcuda.so.1 libcuda.so.1.1
    ```

2. 在 `wsl` 中执行:

    ``` bash
    sudo ldconfig
    ```

### 原因

`nvidia` 的驱动程序没有将 `so` 文件以软连接的形式创建，而通过 `man ldconfig` 命令可知:

``` text
    Note that ldconfig  will only look at files that are named lib*.so* (for regular shared objects) or ld-*.so* (for the dynamic loader itself).  Other files will be ignored. Also, ldconfig expects a certain pattern to how the symlinks are set up, like this example, where the middle file (libfoo.so.1 here) is the SONAME for the library:

    libfoo.so -> libfoo.so.1 -> libfoo.so.1.12
```

`ldconfig` 期望的文件是符合一定格式的 `symlinks`。

### 参考

* <https://issueexplorer.com/issue/yuk7/ArchWSL/248>
