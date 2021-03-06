+++
title = "并行程序设计"
date = 2020-11-21 14:24:38
[taxonomies]
tags = ["parallel programming"]
+++

## 为什么需要并行程序

单核心的性能不满足需求。

## 如何设计并行程序

在软件层面，通常的方案的基本思想是将要完成的任务分配给各个处理核心。有两种广泛采用的方法: **任务并行** 和 **数据并行**。

以如下问题解释说明:

试卷共计 5 道题目，有 100 名学生参加考试，5 名教师阅卷。

### 任务并行

将待解决的问题所需要执行的各个任务分配到各个核心上执行。

对应到上述问题中，可以认为每个阅卷教师就是一个处理核心，批改每一道题是一个任务。则将任务分配到核心的含义是: 每一名教师只需要负责批阅固定的一道题目。

### 数据并行

将待解决问题所需要处理的数据分配给各个处理核心，每个处理核心执行相同的操作。

对应到上述问题中，可以认为每个阅卷教师就是一个处理核心，将试卷 —— 也就是数据分配给教师，教师负责试卷的整个批阅过程。各个老师是做的工作是相同的。

## 性能

如何衡量并行程序的性能指标。

### 加速比和效率
