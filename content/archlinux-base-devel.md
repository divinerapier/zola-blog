+++
title = "Arch Linux 安装 fakeroot"
date = 2021-07-10 11:47:19

[taxonomies]
tags = ["linux", "arch"]
+++

在安装 `kodi-standalone-service` 时遇到错误:

``` bash
yay -S kodi-standalone-service
...
==> ERROR: Cannot find the fakeroot binary.
error making: kodi-standalone-service
```

错误原因为: **Cannot find the fakeroot binary.**

有两种方式解决:

``` bash
sudo pacman -S fakeroot
```

或者

``` bash
sudo pacman -S base-devel
```
