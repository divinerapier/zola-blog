+++
title = "使用 GLEW 库开发 OpenGL"
date = 2022-01-30 15:10:06
[taxonomies]
tags = ["opengl"]
+++

[`GLEW`](http://glew.sourceforge.net/) 是一个跨平台开源的 `c/c++` 扩展加载库。将下载的[`GLEW`](https://sourceforge.net/projects/glew/files/glew/2.1.0/glew-2.1.0-win32.zip/download)安装到如下目录:

``` bash
└─dependencies
   └─glew-2.1.0
      ├─bin
      │  └─Release
      │      ├─Win32
      │      └─x64
      ├─doc
      ├─include
      │  └─GL
      └─lib
          └─Release
              ├─Win32
              └─x64
```

## 配置环境

* 在 `Configuration Properties` > `C/C++` > `General` > `Additional Include Directories` 添加 `$(SolutionDir)dependencies\glew-2.1.0\include`
* 在 `Configuration Properties` > `Linker` > `General` > `Additional Library Directories` 添加 `$(SolutionDir)dependencies\glew-2.1.0\lib\Release\Win32`
* 在 `Configuration Properties` > `Linker` > `Input` > `Additional Dependencies` 添加 `glew32s.lib`

值得注意的是:

在 `lib` 文件夹下存在两个文件，其使用场景不同:

* `glew32.lib`: 需要配合 `dll` 一起作为动态链接库使用
* `glew32s.lib`: 用于静态链接

## 注意事项

### 头文件

在引入 `<GL/glew.h>` 文件时，`#include <GL/glew.h>` 必须写在其他 `OpenGL` 的引用语句之前，否则会出现错误:

``` text
1>C:\Users\divinerapier\Documents\code\opengl\opengl\dependencies\glew-2.1.0\include\GL\glew.h(85,1): fatal error C1189: #error:  gl.h included before glew.h
```

这是因为，在 `<GL/glew.h>` 文件中会进行判断:

``` c
#if defined(__gl_h_) || defined(__GL_H__) || defined(_GL_H) || defined(__X_GL_H)
#error gl.h included before glew.h
#endif
```

要求引入 `<GL/glew.h>` 文件之前，不能有 `__gl_h_` 等宏定义。因此，应该写作:

``` c
#include <GL/glew.h>
#include <GLFW/glfw3.h>
```

### 初始化

`GLFW` 与 `GLEW` 都需要初始化，那应该按照什么顺序，谁先谁后? 在 `GLEW` 的[官网](http://glew.sourceforge.net/basic.html)中有说明:

> First you need to create a valid OpenGL rendering context and call glewInit() to initialize the extension entry points. If glewInit() returns GLEW_OK, the initialization succeeded and you can use the available extensions as well as core OpenGL functionality.

就是应该先初始化 `GLEW` 之外的其他库，并创建好有效的渲染窗体(a valid OpenGL rendering context)，之后才能调用 `glewInit()` 函数。即代码中应该:

``` c
int main(void) {
    GLFWwindow* window;

    /* Initialize the library */
    if (!glfwInit()) {
        return -1;
    }

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(640, 480, "Hello World", NULL, NULL);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);

    if (glewInit() != GLEW_OK) {
        std::cout << "ohhhhhhhhh" << std::endl;
        return 1;
    }
}
```

### 预处理宏定义

上述代码在运行的时候会遇到一个链接错误:

> `1>Application.obj : error LNK2019: unresolved external symbol __imp__glewInit@0 referenced in function _main`。

即找不到函数 `glewInit`。

这个问题只要看一下 `glewInit` 定义就能明白:

``` c
GLEWAPI GLenum GLEWAPIENTRY glewInit (void);
```

再跳转到 `GLEWAPI` 的宏定义:

``` c
#ifdef GLEW_STATIC
#  define GLEWAPI extern
#else
#  ifdef GLEW_BUILD
#    define GLEWAPI extern __declspec(dllexport)
#  else
#    define GLEWAPI extern __declspec(dllimport)
#  endif
#endif
```

可以发现，由于 `GLEW_STATIC` 与 `GLEW_BUILD` 均未定义，因此，会使用

``` c
define GLEWAPI extern __declspec(dllimport)
```

解决办法就是定义 `GLEW_STATIC`。

在 `Configuration Properties` > `C/C++` > `Preprocessor` > `Preprocessor Definitions` 中添加 `GLEW_STATIC`。

## 文档

在[文档](https://docs.gl/)上可以直接使用函数名进行搜索。
