+++
title = "计算机图形学: 复习线性代数"
date = 2022-03-28 19:38:32
[taxonomies]
tags = ["computer graphics", "linear algebra"]
+++

# 向量

数学中称作 **`向量`**，物理学中称作 **`矢量`**。

* 常写作 {{ katex(body="\vec{a}") }} 或 {{ katex(body="a") }}
* 或者使用起始点与结束点表示: {{ katex(body="\vec{AB}=B-A") }}
* 具有方向和长度
* 无绝对起始位置(可平移)
* 默认使用列向量{{ katex(body="\begin{pmatrix} a \\ b \end{pmatrix}") }}

## 向量的模长

* 向量的规模(Magnitude)/长度(length)写作: {{ katex(body="\Vert\vec{a}\Vert") }}
* 单位向量
  * 规模为 **1** 的向量
  * 单位向量计算方式: {{ katex(body="\hat{a}=\vec{a}/\Vert\vec{a}\Vert") }}，读作 `a-hat`
  * 只表示方向

## 向量的加法

* 几何: 平行四边形法则 & 三角形法则
* 代数: 对应坐标相加

## 向量点乘

点(dot)乘，也叫标量(scalar)乘。

$$\vec{a}\cdotp\vec{b}=\Vert\vec{a}\Vert\Vert\vec{b}\Vert\cos\theta$$
$$\cos\theta=\cfrac{\vec{a}\cdotp\vec{b}}{\Vert\vec{a}\Vert\Vert\vec{b}\Vert}$$

对于单位向量，则有
$$\cos\theta=\hat{a}\cdotp\hat{b}$$

### 点乘性质

* \\( \vec{a}\cdotp\vec{b}=\vec{b}\cdotp\vec{a} \\)
* \\( \vec{a}\cdotp(\vec{b}+\vec{c})=\vec{a}\cdotp\vec{b}+\vec{a}\cdotp\vec{c} \\)
* \\( (k\vec{a})\cdotp\vec{b}=\vec{a}\cdotp(k\vec{b})=k(\vec{a}\cdotp\vec{b}) \\)

### 笛卡尔坐标系中的点乘

#### 2D 空间

$$\vec{a}*\vec{b}=\begin{pmatrix} x_a \\ y_a \end{pmatrix}\cdotp\begin{pmatrix} x_b \\ y_b \end{pmatrix}=x_ax_b+y_ay_b$$

#### 3D 空间

$$\vec{a}*\vec{b}=\begin{pmatrix} x_a \\ y_a \\ z_a \end{pmatrix}\cdotp\begin{pmatrix} x_b \\ y_b \\ z_b \end{pmatrix}=x_ax_b+y_ay_b+z_az_b$$

### 点乘的应用

* 两个向量之间的夹角
* 一个向量在另一个向量上的投影

#### 向量投影

![投影](/review-of-linear-algebra/01.png)

如图，\\( \vec{b_\perp} \\) 就是 \\( \vec{b} \\) 在 \\( \vec{a} \\) 方向上的投影。

* \\( \vec{b_\perp} \\) 的方向一定与 \\( \vec{a} \\) 相同 (或者说是 \\( \hat{a} \\))
  * \\( \vec{b_\perp}=k\hat{a} \\)
  * \\( k=\Vert\vec{b_\perp}\Vert=\Vert\vec{b}\Vert\cos\theta \\)

因此，

$$\vec{b_\perp}=\Vert\vec{b}\Vert\hat{a}\cos\theta$$

#### 分解向量

![分解](/review-of-linear-algebra/02.png)

如图，当计算出 \\( \vec{b} \\) 在 \\( \vec{a} \\) 方向的投影 \\( \vec{b_\perp} \\) 后，就可以通过 **平行四边形法则** 计算出 \\( \vec{b} \\) 垂直于  \\( \vec{a} \\) 的分量为  \\( \vec{b}-\vec{b_\perp} \\)

#### 判断前后方向

![方向](/review-of-linear-algebra/03.png)

已知基准方向 \\( \vec{a} \\)，可以通过点乘判断向量 \\( \vec{b} \\)、向量 \\( \vec{c} \\) 是向前还是向后的。如图，

$$ \vec{a}\cdotp\vec{b} > 0$$

因此，\\(\vec{b}\\) 方向向前。

$$ \vec{a}\cdotp\vec{c} < 0$$

因此，\\(\vec{c}\\) 方向向后。

#### 计算两个方向接近程度

还是使用上图，由于

$$\cos\theta=\hat{a}\cdotp\hat{b}$$

当 \\(\theta=0\\) 时，
$$\hat{a}\cdotp\hat{b} = 1$$
当 \\(\theta=\cfrac{\pi}{2}\\) 时，
$$\hat{a}\cdotp\hat{b} = 0$$
当 \\(\theta=\pi\\) 时，
$$\hat{a}\cdotp\hat{b} = - 1$$

##### 应用场景

一束光照在镜子上发生镜面反射，在看向镜子的时候，可以计算视线与反射光的方向的接近程度显示不同的亮度。

## 向量叉乘

![叉乘](/review-of-linear-algebra/04.png)

向量 \\(\vec{a}\\) 与向量 \\(\vec{b}\\) 的叉乘记作 \\(\vec{a}\times\vec{b}\\)，其结果为一个向量，假设 \\(\vec{a}\\) 与 \\(\vec{b}\\) 之间的夹角为 \\(\theta\\):
$$\Vert\vec{a}\times\vec{b}\Vert=\Vert\vec{a}\Vert\Vert\vec{b}\Vert\sin\theta$$

* \\(\vec{a}\times\vec{b}\\) 同时垂直于\\(\vec{a}\\)与\\(\vec{b}\\)，即 \\(\vec{a}\times\vec{b}\\) 垂直于 \\(\vec{a}\\) 与 \\(\vec{b}\\) 所在的平面
* \\(\vec{a}\times\vec{b}\\) 的方向通过右手(螺旋)定则判断
  * 伸开右手，四指沿着向量 \\(\vec{a}\\) (左操作数)的方向
  * 四指旋转向 \\(\vec{b}\\) (右操作数)
  * 拇指对应的方向就是 \\(\vec{a}\times\vec{b}\\) 的方向

因此，可知 \\(\vec{b}\times\vec{a}\\) 的方向与 \\(\vec{a}\times\vec{b}\\) 的大小相同，方向相反:

$$\vec{a}\times\vec{b}=-\vec{b}\times\vec{a}$$

### 叉乘的性质

* \\(\vec{x}\times\vec{y}=+\vec{z}\\)
* \\(\vec{y}\times\vec{x}=-\vec{z}\\)
* \\(\vec{y}\times\vec{z}=+\vec{x}\\)
* \\(\vec{z}\times\vec{y}=-\vec{x}\\)
* \\(\vec{z}\times\vec{x}=+\vec{y}\\)
* \\(\vec{x}\times\vec{z}=-\vec{y}\\)

* \\(\vec{a}\times\vec{b}=-\vec{b}\times\vec{a}\\)
* \\(\vec{a}\times\vec{a}=\vec{0}\\)
* \\(\vec{a}\times(\vec{b}+\vec{c})=\vec{a}\times\vec{b}+\vec{a}\times\vec{c}\\)
* \\(\vec{a}\times(k\vec{b}=k(\vec{a}\times\vec{b})\\)

**推论**:

如果在一个坐标系中，有

$$\vec{x}\times\vec{y}=+\vec{z}$$

则表示这个坐标是右手系。

### 代数计算方式

在三维坐标系中，有单位向量 \\(\vec{x}=(1, 0, 0)\\),\\(\vec{y}=(0,1,0)\\),\\(\vec{z}=(0,0,1)\\),设
$$\vec{a}=(x_a,y_a,z_a)=x_a\vec{x}+y_a\vec{y}+z_a\vec{z}$$
$$\vec{b}=(x_b,y_b,z_b)=x_b\vec{x}+y_b\vec{y}+z_b\vec{z}$$

则

{% katex(block=true) %}
\vec{a}\times\vec{b}=(x_a\vec{x}+y_a\vec{y}+z_a\vec{z})\times(x_b\vec{x}+y_b\vec{y}+z_b\vec{z})
{% end %}
{% katex(block=true) %}

=x_a\vec{x}\times(x_b\vec{x}+y_b\vec{y}+z_b\vec{z})+y_a\vec{y}\times(x_b\vec{x}+y_b\vec{y}+z_b\vec{z})+z_a\vec{z}\times(x_b\vec{x}+y_b\vec{y}+z_b\vec{z})

{% end %}

{% katex(block=true) %}
=x_ax_b\vec{x}\times\vec{x}+x_ay_b\vec{x}\times\vec{y}+x_az_b\vec{x}\times\vec{z}
{% end %}
{% katex(block=true) %}
+y_ax_b\vec{y}\times\vec{x}+y_ay_b\vec{y}\times\vec{y}+y_az_b\vec{y}\times\vec{z}
{% end %}
{% katex(block=true) %}
+z_ax_b\vec{z}\times\vec{x}+z_ay_b\vec{z}\times\vec{y}+z_az_b\vec{z}\times\vec{z}
{% end %}
{% katex(block=true) %}
=\vec{0}+x_ay_b\vec{z}-x_az_b\vec{y}
{% end %}

{% katex(block=true) %}
-y_ax_b\vec{z}+\vec{0}+y_az_b\vec{x}
{% end %}
{% katex(block=true) %}
+z_ax_b\vec{y}-z_ay_b\vec{x}+\vec{0}
{% end %}
{% katex(block=true) %}

=(y_az_b-y_bz_a) \vec{x}+(z_ax_b-x_az_b)\vec{y}+(x_ay_b-y_ax_b)\vec{z}
{% end %}

{% katex(block=true) %}
=

\begin{pmatrix} y_az_b - y_bz_a \\
z_ax_b-x_az_b \\
x_ay_b-y_ax_b
 \end{pmatrix}
{% end %}

{% katex(block=true) %}

=

\begin{pmatrix}
    0 & -z_a &  y_a \\
  z_a &    0 & -x_a \\
  -y_a &  x_a &    0
  \end{pmatrix}
  \begin{pmatrix}
  x_b \\
  y_b \\
  z_b
  \end{pmatrix}
{% end %}

### 叉乘的应用

#### 判定左右

![叉乘判定左右](/review-of-linear-algebra/05.png)

定义逆时针旋转为左，顺时针旋转为右。

如图，\\(\vec{a}\\) 经过逆时针旋转之后可以与 \\(\vec{b}\\) 的方向相同，此时 \\(\vec{a}\times\vec{b}\\) 方向为正，反之，方向为负。

#### 判定内外

![叉乘判定内外](/review-of-linear-algebra/06.png)

如图，\\(\vec{AB}\times\vec{AP}\\) 可知 \\(P\\) 在 \\(\vec{AP}\\) 的左侧，同理，可知 \\(P\\) 也分别位于 \\(\vec{BC}\\) 和 \\(\vec{CA}\\) 的左侧。因此，\\(P\\) 位于 \\(\triangle ABC\\) 的内部。

推论，当不确定 \\(\triangle ABC\\) 的顶点顺序时，只需要满足 \\(\vec{AB}\times\vec{AP}\\)，\\(\vec{BC}\times\vec{BP}\\)，\\(\vec{CA}\times\vec{CP}\\) 的方向相同，就可证明 \\(P\\) 位于 \\(\triangle ABC\\) 的内部。

## 三维向量的投影

假设在一个三维坐标系中有:

$$\Vert\vec{u}\Vert=\Vert\vec{v}\Vert=\Vert\vec{w}\Vert=1$$
$$\vec{u}\cdotp\vec{v}=\vec{v}\cdotp\vec{w}=\vec{u}\cdotp\vec{w}=1$$
$$\vec{w}=\vec{u}\times\vec{v}$$

则有任意向量
$$\vec{p}=
 (\vec{p}\cdotp\vec{u})\vec{u}
+(\vec{p}\cdotp\vec{v})\vec{v}
+(\vec{p}\cdotp\vec{w})\vec{w}
$$
