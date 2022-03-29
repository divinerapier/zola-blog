+++
title = "搭建 OpenGL 环境环境"
date = 2022-01-30 14:51:20
[taxonomies]
tags = ["opengl"]

+++

* Windows 11
* VS 2022
* [GLFW 3.3.6](https://github.com/glfw/glfw/releases/download/3.3.6/glfw-3.3.6.zip)

使用 `VS 2022` 新建一个 `c/c++` 的空项目，在解决方案目录下创建 `dependencies` 目录，并以如下目录结构下载 `GLFW` 依赖库。

``` bash
└─dependencies
   └─glfw
       ├─include
       │  └─GLFW
       └─lib-vc2022
```

## 环境配置

右键点击项目，进入 `properties`。

* 将 `Configuration` 设置为 `All Configurations`
* 在 `Configuration Properties` > `C/C++` > `General` > `Additional Include Directories` 添加 `$(SolutionDir)dependencies\glfw\include`
* 在 `Configuration Properties` > `Linker` > `General` > `Additional Library Directories` 添加 `$(SolutionDir)dependencies\glfw\lib-vc2022`
* 在 `Configuration Properties` > `Linker` > `Input` > `Additional Dependencies` 添加 `glfw3.lib`

## 代码

源码来自 [GLFW](https://www.glfw.org/documentation.html)

``` c
#include <GLFW/glfw3.h>

int main(void) {
    GLFWwindow* window;

    /* Initialize the library */
    if (!glfwInit())
        return -1;

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(640, 480, "Hello World", NULL, NULL);
    if (!window) {
        glfwTerminate();
        return -1;
    }

    /* Make the window's context current */
    glfwMakeContextCurrent(window);

    /* Loop until the user closes the window */
    while (!glfwWindowShouldClose(window)) {
        /* Render here */
        glClear(GL_COLOR_BUFFER_BIT);

        glBegin(GL_TRIANGLES);
        glVertex2f(-0.5f, -0.5f);
        glVertex2f(0.0f, 0.5f);
        glVertex2f(0.5f, -0.5f);
        glEnd();

        /* Swap front and back buffers */
        glfwSwapBuffers(window);

        /* Poll for and process events */
        glfwPollEvents();
    }

    glfwTerminate();
    return 0;
}

```

## 常见错误

### 问题: `1>Application.obj : error LNK2019: unresolved external symbol __imp__glClear@4 referenced in function _main`

`Configuration Properties` > `Linker` > `Input` > `Additional Dependencies` 添加 `opengl32.lib`

### 问题: `1>glfw3.lib(win32_init.obj) : error LNK2019: unresolved external symbol __imp__TranslateMessage@4 referenced in function __glfwPlatformInit`

在 `google.com` 中搜索 `TranslateMessage` 进入 `https://docs.microsoft.com/` 的链接，在最下方可以找到 `Library User32.lib`，将 `User32.lib` 添加到 `Configuration Properties` > `Linker` > `Input` > `Additional Dependencies`。
