+++
title = "MySQL 性能优化概述"
date = 2020-07-27 21:43:22
[taxonomies]
tags = ["mysql", "optimization"]
+++

在软件层面，数据库的性能会受到表结构，查询语句和数据库系统配置等几个方面的影响。这些软件层面的因素会直接决定 CPU 和 I/O 等硬件如何操作。我们要努力做到硬件操作的最小化。

对于研究数据库性能的初学者而言，可以从学习数据库的高级规则和准则开始，学会使用时钟时间来作为衡量性能的指标。而对于那些想要成为数据库性能优化领域的专家的人来说，则需要他们了解更多关于数据库底层的知识，能使用更具有一般性的指标，诸如 CPU 周期和 I/O 操作等来衡量性能。

大部分的用户，希望从其现有的软件和硬件配置中获得最佳的数据库性能。进阶用户则专注于寻找机会改进 MySQL 软件本身，或者开发自己的存储引擎和硬件设备以扩展 MySQL 生态系统。

## 在数据库级别进行优化

使数据库应用程序快速运行的最重要因素是其基本设计：

* 表格的结构是否正确？ 特别是，这些列是否具有正确的数据类型，并且每个表都具有适合于该工作类型的列吗？ 例如，执行频繁更新的应用程序通常具有许多表而具有很少的列，而分析大量数据的应用程序通常具有很少的表而具有很多列。
* 是否安装了正确的[索引](https://dev.mysql.com/doc/refman/8.0/en/optimization-indexes.html)以提高查询效率？
* 您是否为每个表使用了适当的存储引擎，并利用了所使用的每个存储引擎的优势和功能？ 特别是，对于性能和可伸缩性而言，选择事务存储引擎（例如 [InnoDB](https://dev.mysql.com/doc/refman/8.0/en/optimizing-innodb.html)）或非事务存储引擎（例如 [MyISAM](https://dev.mysql.com/doc/refman/8.0/en/optimizing-myisam.html)）可能非常重要。

    > 注意
    > `InnoDB` 是新表的默认存储引擎。 实际上，先进的 `InnoDB` 性能功能意味着 `InnoDB` 表通常优于简单的 `MyISAM` 表，尤其是对于繁忙的数据库。

* 每个表都使用适当的行格式吗？ 该选择还取决于表使用的存储引擎。 特别是，压缩表使用较少的磁盘空间，因此需要较少的磁盘I / O来读取和写入数据。 压缩可用于带有 `InnoDB` 表的所有类型的工作负载以及只读的 `MyISAM` 表。
* 应用程序是否使用适当的[锁定策略](https://dev.mysql.com/doc/refman/8.0/en/locking-issues.html)？ 例如，通过在可能的情况下允许共享访问，以便数据库操作可以同时运行，并在适当的时候请求独占访问，以使关键操作获得最高优先级。 同样，存储引擎的选择很重要。 InnoDB存储引擎无需您的参与即可处理大多数锁定问题，从而可以更好地并发数据库并减少代码的试验和调整量。
* 用于[缓存](https://dev.mysql.com/doc/refman/8.0/en/buffering-caching.html)的所有内存区域大小是否正确？ 也就是说，足够大以容纳经常访问的数据，但又不能太大以至于它们会使物理内存过载并导致分页。 要配置的主要内存区域是 `InnoDB` 缓冲池和 `MyISAM` 密钥缓存。

## 在硬件级别进行优化

随着数据库变得越来越繁忙，任何数据库应用程序最终都会达到硬件极限。 DBA必须评估是否有可能调整应用程序或重新配置服务器以避免这些[瓶颈](https://dev.mysql.com/doc/refman/8.0/en/glossary.html#glos_bottleneck)，或者是否需要更多的硬件资源。 系统瓶颈通常来自以下来源：

* 磁盘搜寻。 磁盘查找数据需要花费时间。 对于现代磁盘，此操作的平均时间通常小于10毫秒，因此理论上我们可以执行100次搜索。 这段时间随着新磁盘的使用而缓慢改善，并且很难为单个表进行优化。 优化寻道时间的方法是将数据分发到多个磁盘上。
* 磁盘读写。 当磁盘位于正确的位置时，我们需要读取或写入数据。 对于现代磁盘，一个磁盘至少可提供10–20MB / s的吞吐量。 与查找相比，优化起来更容易，因为您可以从多个磁盘并行读取。
* CPU周期。 当数据位于主存储器中时，我们必须对其进行处理以获得结果。 与内存量相比，拥有较大的表是最常见的限制因素。 但是对于小桌子，速度通常不是问题。
* 内存带宽。 当CPU需要的数据超出CPU缓存的容量时，主内存带宽将成为瓶颈。 对于大多数系统来说，这是一个不常见的瓶颈，但是要意识到这一点。

## 平衡便携性和性能

MySQL 支持在 SQL 注释中（`/*！*/`）通过特定的关键字来指定优化策略。而且，因为是在注释中，会被其他的 SQL 服务忽略，因此，SQL 语句仍然是可移植的。有关编写注释的信息，请参见 [8.9.3 优化器提示](https://dev.mysql.com/doc/refman/8.0/en/optimizer-hints.html)，[9.6 注释语法](https://dev.mysql.com/doc/refman/8.0/en/comments.html)。