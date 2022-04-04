+++
title = "计算机图形学: 变换"
date = 2022-04-04 08:55:32
[taxonomies]
tags = ["computer graphics", "linear algebra"]
+++

## 矩阵与变换

### 缩放

![scale](/transformation/01.png)

如图所示，左侧的图形经过了缩放\\(S_{0.5}\\)变换后得到了右侧图形。

\\(S_{0.5}\\) 表示将图形的横纵坐标变为原来的 \\(\frac 1 2\\)。

首先，可以使用如下方程组表示上述的变换关系:

{% katex(block=true) %}
\tag*{(1)}
\begin{cases}
   x\prime=sx \\
   y\prime=sy
\end{cases}
{% end %}

假设存在一个矩阵，可以将原坐标变换至新的坐标:

{% katex(block=true) %}
\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
   A & B \\
   C & D
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
=

\begin{bmatrix}
   Ax + By \\
   Cx + Dy
\end{bmatrix}

{% end %}
整理后得到:
{% katex(block=true) %}
\tag*{(2)}
\begin{cases}
   x\prime=Ax+By \\
   y\prime=Cx+Dy
\end{cases}
{% end %}

\\((1),(2)\\) 可得:
{% katex(block=true) %}
\tag*{(3)}
\begin{cases}
   (A-s)x+By=0 \\
   Cx+(D-s)y=0
\end{cases}
{% end %}
{% katex(block=true) %}
\tag*{(4)}
\begin{cases}
   A=D=s \\
   B=C=0
\end{cases}
{% end %}
即
{% katex(block=true) %}

\tag*{(5)}
\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
   s & 0 \\
   0 & s
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
{% end %}

### 非一致性缩放

![non-uniform-scale](/transformation/02.png)

上图使用的变换方式为 \\(S_{0.5,1.0}\\)，此时横纵坐标变换方式不一致。即
{% katex(block=true) %}
\tag*{(6)}
\begin{cases}
   x\prime=s_xx \\
   y\prime=s_yy
\end{cases}
{% end %}
使用\\((2),(6)\\)可得:
{% katex(block=true) %}
\tag*{(4)}
\begin{cases}
    A=s_x \\
    B=C=0 \\
    D=s_y
\end{cases}
{% end %}
即矩阵表示为

{% katex(block=true) %}

\tag*{(5)}
\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
   s_x & 0 \\
     0 & s_y
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
{% end %}

### 镜面(反射)变换

![reflection-matrix](/transformation/03.png)

还可以以 \\(y\\) 轴作为对称轴做变换，即
{% katex(block=true) %}
\tag*{(7)}
\begin{cases}
   x\prime=-x \\
   y\prime=y
\end{cases}
{% end %}
使用矩阵可以表示为

{% katex(block=true) %}

\tag*{(8)}
\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
    -1 & 0 \\
     0 & 1
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
{% end %}

### 错切变换

![shear-matrix](/transformation/04.png)

上图的变换被称作错切变换。

首先可以发现，任意一点的纵坐标都没有发生变换。

而对于横坐标，
{% katex(block=true) %}
\tag*{(9)}
\begin{cases}
   x\prime=x  &\text{当 } y=0 \\
   x\prime=x+a&\text{当 } y=1 \\
   x\prime=x+ay &\text{当 } y\in(0,1)
\end{cases}
{% end %}
整理可得:
{% katex(block=true) %}
\tag*{(10)}
\begin{cases}
   x\prime=x+ay &\text{当 } y\in(0,1) \\
   y\prime=y
\end{cases}
{% end %}
由\\((2),(10)\\) 可得:
{% katex(block=true) %}
\tag*{(11)}
\begin{cases}
   Ax+By=x+ay   \\
   Cx+Dy=y
\end{cases}
{% end %}
使用矩阵可以表示为

{% katex(block=true) %}

\tag*{(12)}
\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
     1 & a \\
     0 & 1
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
{% end %}

### 旋转变换

![rotate](/transformation/05.png)

\\(R_{45}\\)表示以坐标原点为旋转中心，向逆时针方向旋转\\(45\degree\\)。

![rotate2](/transformation/06.png)

选择两个特殊的点，可以得到对应关系:

{% katex(block=true) %}
\tag*{(13)}
\begin{cases}
   (1, 0) \to ( \cos\theta, \sin\theta) \\
   (0, 1) \to (-\sin\theta, \cos\theta)
\end{cases}
{% end %}

带入 \\((2)\\) 得到:

{% katex(block=true) %}
\begin{cases}
   \cos\theta = A\cdotp1+B\cdotp0 \\
   \sin\theta = C\cdotp1+D\cdotp0 \\
   -\sin\theta = A\cdotp0+B\cdotp1 \\
   \cos\theta = C\cdotp0+D\cdotp1
\end{cases}
{% end %}
整理后得到:
{% katex(block=true) %}
\tag*{(14)}
R_{\theta}=
\begin{bmatrix}
     \cos\theta & -\sin\theta \\
     \sin\theta & \cos\theta
\end{bmatrix}
{% end %}

使用矩阵可以表示为

{% katex(block=true) %}

\tag*{(15)}
\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
     \cos\theta & -\sin\theta \\
     \sin\theta & \cos\theta
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
{% end %}

## 线性变换

如果原坐标\\((x, y)\\)与变换后的坐标\\((x\prime, y\prime)\\)可以表示为

{% katex(block=true) %}
\tag*{(16)}
\begin{cases}
   x\prime = ax+by \\
   y\prime = cx+dy
\end{cases}
{% end %}

矩阵形式表示为

{% katex(block=true) %}

\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
     a & b \\
     c & d
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
{% end %}

则称这种变换为**线性变换**。

## 齐次坐标

### 特殊的平移变换

![translation](/transformation/07.png)

经过 \\(T_{tx,ty}\\)变换后的坐标可以表示为:

{% katex(block=true) %}
\begin{cases}
   x\prime = x+t_x \\
   y\prime = y+t_y
\end{cases}
{% end %}

可以发现，这个变换虽然简单，但与公式\\((16)\\)不兼容，即**不是一个线性变换**。

对应到矩阵形式的表示:

{% katex(block=true) %}

\begin{bmatrix}
   x\prime \\
   y\prime
\end{bmatrix}
=

\begin{bmatrix}
     a & b \\
     c & d
\end{bmatrix}
\begin{bmatrix}
   x \\
   y
\end{bmatrix}
+
\begin{bmatrix}
   t_x \\
   t_y
\end{bmatrix}
{% end %}

### 引入齐次坐标

对于二维空间中坐标与向量，增加第三个坐标 \\(w\\):

* 点 = \\((x, y, 1)^T\\)
* 向量 = \\((x, y, 0)^T\\)

后，平移变换可以表示为:

{% katex(block=true) %}
\begin{pmatrix}
    x\prime \\
    y\prime \\
    w\prime
\end{pmatrix}
=

\begin{pmatrix}
    1 & 0 & t_x \\
    0 & 1 & t_y \\
    0 & 0 & 1
\end{pmatrix}
\begin{pmatrix}
    x \\
    y \\
    1
\end{pmatrix}
=

\begin{pmatrix}
    x + t_x \\
    y + t_y \\
    1
\end{pmatrix}

{% end %}

### 齐次坐标运算

* \\(向量 + 向量 = 向量\\)
  * \\((x_a, y_a, 0) + (x_b, y_b, 0) = (x_a + x_b, y_a + y_b, 0)\\)
* \\(向量 +点 = 点\\)
  * \\((x_a, y_a, 0) + (x_b, y_b, 1) = (x_a + x_b, y_a + y_b, 1)\\)
* \\(点 - 点 = 向量\\)
  * \\((x_a, y_a, 1) - (x_b, y_b, 1) = (x_a - x_b, y_a - y_b, 0)\\)
* \\(点 + 点 = 中点\\)
  * \\((x_a, y_a, 1) + (x_b, y_b, 1) = (x_a + x_b, y_a + y_b, 2) = (\frac{x_a - x_b}{2}, \frac{y_a - y_b}{2}, 1)\\)

### 仿射变换(Affine Transformations)

* 放射变换 = 线性变换 + 平移

{% katex(block=true) %}
\tag{17}
\begin{pmatrix}
    x\prime \\
    y\prime
\end{pmatrix}
=

\begin{pmatrix}
    a & b \\
    c & d
\end{pmatrix}
\begin{pmatrix}
    x \\
    y
\end{pmatrix}
+

\begin{pmatrix}
    t_x \\
    t_y
\end{pmatrix}

{% end %}

### 齐次坐标变换

{% katex(block=true) %}
\tag{18}
\begin{pmatrix}
    x\prime \\
    y\prime \\
    1
\end{pmatrix}
=

\begin{pmatrix}
    a & b & t_x \\
    c & d & t_y \\
    0 & 0 & 1
\end{pmatrix}
\begin{pmatrix}
    x \\
    y \\
    1
\end{pmatrix}
=

\begin{pmatrix}
    ax + by + t_x \\
    cy + dy + t_y \\
    1
\end{pmatrix}

{% end %}

与公式 \\((17)\\) 是等价的。

### 齐次坐标缩放变换

{% katex(block=true) %}
S_{(s_x, s_y)}=
\begin{pmatrix}
    s_x &   0 & 0 \\
      0 & s_y & 0 \\
      0 &   0 & 1
\end{pmatrix}

{% end %}

### 齐次坐标旋转变换

{% katex(block=true) %}
R_{\theta}=
\begin{pmatrix}
    \cos\theta & -\sin\theta & 0 \\
    \sin\theta &  \cos\theta & 0 \\
             0 &           0 & 1
\end{pmatrix}

{% end %}

### 齐次坐标平移变换

{% katex(block=true) %}
T_{(t_x, t_y)}=
\begin{pmatrix}
    1 & 0 & t_x \\
    0 & 1 & t_y \\
    0 & 0 &   1
\end{pmatrix}

{% end %}

## 逆变换

![inserse-transform](/transformation/08.png)

假设初始状态为 **A**, 经过变换 \\(M\\) 达到状态 **B**, 此时满足从 **B** 到 **A** 的变换 \\(M^{-1}\\) 称为 \\(M\\) 的逆变换, 在数学中称 \\(M^{-1}\\) 是 \\(M\\) 的逆矩阵。

## 组合变换

我们经常会遇到这样的问题，从左侧变换到右侧图形。

![compose-transform](/transformation/09.png)

比如，先平移变换 \\(T_{(1, 0)}\\)，再旋转变换 \\(R_{45}\\)，但得到的结果与目标相去甚远，因为旋转是以坐标原点为中心:

![compose-transform-1](/transformation/10.png)

将上述变换交换一下，先 \\(R_{45}\\) 再 \\(T_{(1, 0)}\\)，所得结果就是目标图形:

![compose-transform-2](/transformation/11.png)

同时，通过上述可以发现，将一系列变换交换顺序，得到的结果可能并不相同(事实上，大多数情况都不相同)，同样说明矩阵乘法不允许交换律。

### 变换作用顺序

遵循从右到左的顺序。

向量写在计算的最后侧，变换矩阵按顺序从右到左一次排列。

因此，可以将变换矩阵看作一个**函数**，向量是这个函数的**参数**。

假设有一系列仿射变换 \\(A_1\\),\\(A_2\\),\\(A_3\\), ...,则计算表达式为:

{% katex(block=true) %}
A_n(...A_2(A_1(x)))=

\underbrace{
A_n\cdotp\cdotp\cdotp A_2\cdotp\ A_1\cdotp
}_{\text{可以提前计算}}
\begin{pmatrix}
x \\
y \\
1
\end{pmatrix}
{% end %}

而由于矩阵乘法具有结合律的性质，因此可以提前计算 \\(\displaystyle\prod_{i=n}^1A_i\\) 得到一个可以代表所有变换的矩阵。

#### 齐次坐标变换顺序

根据公式 \\((17),(18)\\) 可知，使用齐次坐标变换时，先进行线性变换，再进行平移变换。

## 分解变换

![decompose-transform-2](/transformation/12.png)

如何期望以左下角顶点\\(c\\)作为旋转中心，将左侧图形旋转至右侧图形，该如何操作呢?

由于旋转默认以坐标原点为旋转中心，因此可以将目标旋转中心移动到坐标原点:

1. 平移至原点
2. 旋转
3. 平移回去

![decompose-transform-2](/transformation/13.png)

即

$$T(c)\cdotp R(\alpha)\cdotp T(-c)$$
