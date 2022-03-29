+++
title = "conda"
date = 2021-04-20 11:24:54
[taxonomies]
tags = []
+++

<https://docs.conda.io/en/latest/miniconda.html#linux-installers>

``` bash
wget https://repo.anaconda.com/miniconda/Miniconda3-py39_4.9.2-Linux-x86_64.sh
```

<https://conda.io/projects/conda/en/latest/user-guide/install/linux.html>

``` bash
miniconda3/bin/conda init
```

``` dockerfile
RUN find /miniconda3/envs/pyasr/bin/ -type f -exec sed -i s//home/local//g {} \;
RUN grep 'local' -nR /miniconda3/envs/pyasr/bin

# 方式一，在一条命令中加载环境并执行命令
RUN . /miniconda3/etc/profile.d/conda.sh && \
   conda activate pyasr && \
   which python && \
   python --version && \
   which pip && \
   python -c "import torch"

# 方式二，通过设置环境变量
ENV PATH "/miniconda3/envs/pyasr/bin:/opt/kaldi/tools/openfst/bin:$PATH"
```
