+++
title = "计算机图形学: 变换补充"
date = 2022-04-05 09:30:18
[taxonomies]
tags = ["computer graphics", "linear algebra"]
+++

在不考虑齐次坐标的情况下，旋转矩阵可以表示为

{% katex(block=true) %}
R_\theta
=

\begin{pmatrix}
\cos\theta & -\sin\theta \\
\sin\theta &  \cos\theta
\end{pmatrix}
{% end %}

因此，

{% katex(block=true) %}
R_{-\theta}
=

\begin{pmatrix}
\cos(-\theta) & -\sin(-\theta) \\
\sin(-\theta) &  \cos(-\theta)
\end{pmatrix}

=

\begin{pmatrix}
\cos\theta & \sin\theta \\
-\sin\theta &  \cos\theta
\end{pmatrix}
=

R_\theta^T
{% end %}

而旋转 \\(\theta\\) 与旋转 \\(-\theta\\) 互为逆变换，所以

$$R_{-\theta}=R_\theta^{-1}=R_\theta^T$$
