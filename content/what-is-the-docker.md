+++
title = "Docker - 概述"
date = 2020-08-16 20:49:59
[taxonomies]
tags = ["container", "docker", "paas"]
+++

## PaaS 的发展过程

**容器** 这个概念从来就不是什么新鲜的东西，也不是 `Docker` 公司发明的。在红极一时的 `PaaS` 项目 `Cloud Foundry` 中，也同样使用到了容器技术，只不过容器只是其最底层、最没人关注的那一部分。

`PaaS` 项目被大家接纳的一个主要原因，就是它提供了一种名叫 **应用托管** 的能力。在当时，虚拟机和云计算已经是比较普遍的技术和服务，主流用户的普遍用法，就是租一批 `AWS` 或者 `OpenStack` 的虚拟机，然后像以前管理物理服务器那样，用脚本或者手工的方式在这些机器上部署应用。

但是，在部署过程中，难免会碰到云端虚拟机和本地环境不一致的问题。所以当时的云计算服务，比的就是谁能更好地模拟本地服务器环境，能带来更好的 **上云** 体验。而 `PaaS` 开源项目 `Cloud Foundry` 就是当时解决这个问题的一个最佳方案。

举个栗子，创建好虚拟机之后，运维人员只需要在这些机器上部署 `Cloud Foundry Agent`，随后开发者只要执行一条命令就能把本地的应用部署到云上:

``` bash
cf push "我的应用"
```

事实上，`Cloud Foundry` 最核心的组件就是一套应用的打包和分发机制。`Cloud Foundry` 为每种主流编程语言都定义了一种打包格式。

`cf push` 的作用是把应用的可执行文件和启动脚本打进一个压缩包内，上传到云上 `Cloud Foundry` 的存储中。接着，`Cloud Foundry` 会通过调度器选择一个可以运行这个应用的虚拟机，然后通知这个机器上的 `Agent` 把应用压缩包下载下来启动。

这时候关键来了，由于需要在一个虚拟机上启动很多个来自不同用户的应用，`Cloud Foundry` 通过操作系统的 `cgroups` 和 `namespace` 机制为每一个应用单独创建一个称作 **沙盒** 的隔离环境，然后在 **沙盒** 中启动这些应用进程。这样，就实现了把多个用户的应用互不干涉地在虚拟机里批量地、自动地运行起来的目的。而这个 **沙盒** 就是所谓的 **容器**。

而本文的主角 `Docker` 项目，与 `Cloud Foundry` 的容器并没有本质上的差异。因此在它发布后不久，`Cloud Foundry` 的首席产品经理 `James Bayer` 就在社区里做了一次详细对比，告诉用户 `Docker` 只是一个同样使用 `cgroups` 和 `namespace` 实现的 **沙盒** 而已，没有什么特别的黑科技，也不需要特别关注。

然而，短短几个月，`Docker` 项目就迅速崛起了。它的崛起速度如此之快，以至于 `Cloud Foundry` 以及所有的 `PaaS` 社区还没来得及成为它的竞争对手，就直接被宣告出局了，堪称 **降维打击**。

## Docker 镜像

究其根本原因，虽然 `Docker` 与 `Cloud Foundry` 无论是在核心原理还是在技术实现上大部分相同，但正是被大家忽视的那一小部分成为 `Docker` 的制胜法宝——`Docker` 镜像。

`Cloud Fondry` 成也“打包”，败萧“打包”。其一，每种语言，每种框架的打包方式都不甚相同，甚至于每个版本都需要打包；其二，虽然打包之后可以在云上直接使用，但在从本地上云的过程中，可能仍旧需要反复修改、配置，甚至于在不断试错中体会**玄学调参**。

结果大家发现，虽然 `cf push` 可以一键部署，但是为了实现**一键部署**这一目的的过程却需要费尽心机。

而 `Docker` 镜像却从根本上解决了这一问题。`Docker` 镜像，实际上也是一个压缩包，但是内容却要比 `Cloud Foundry` 的丰富的多。它不但包含可执行文件与启动脚本，更是包含了一个完整的操作系统，所以这个压缩包的内容可以与开发环境、测试环境的完全一样。

假设，开发时使用 `centos 8` 作为开发环境，此时，只需要使用 `centos 8` 的 `iso` 连同可执行文件一起制作一个压缩包，那么，无论在哪里解压这个压缩包，都可以为可执行文件提供完全一致的运行环境。

## 容器与虚拟化

虚拟化允许多个操作系统 `(Windows/Linux)` 同时在单个硬件系统上运行。

容器可共享同一个操作系统内核，将应用进程与系统其他部分隔离开。例如：`ARM Linux` 系统运行 `ARM Linux` 容器，`x86 Linux` 系统运行 `x86 Linux` 容器，`x86 Windows` 系统运行 `x86 Windows` 容器。`Linux` 容器具有极佳的可移植性，但前提是它们必须与底层系统兼容。

![virtualization-vs-containers](/images/what-is-the-docker/virtualization-vs-containers.png)

这意味着，虚拟化会使用虚拟机监控程序模拟硬件，从而使多个操作系统能够并行运行。但这不如容器轻便。`Linux` 容器在本机操作系统上运行，与所有容器共享该操作系统，因此应用和服务能够保持轻巧，并行化快速运行。
