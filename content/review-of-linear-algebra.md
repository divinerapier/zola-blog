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
