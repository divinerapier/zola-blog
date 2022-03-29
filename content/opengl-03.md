+++
title = "使用 GLEW 绘制三角形"
date = 2022-01-30 15:50:48
[taxonomies]
tags = ["opengl", "shader"]
+++

之前已经使用 `GLFW` 绘制了一个三角形，直接定义坐标即可，但使用 `GLEW` 绘制图形要麻烦一些，因为需要自己编写 `Shader` 程序。

## Shader 编程

`Shader` 的本质是一个运行在 `GPU` 上面的程序，因为图形的渲染由 `GPU` 负责，因此需要对 `GPU` 编程告诉 `GPU` 如何渲染，这个很好理解，就像使用 `c/c++` 等通用语言对 `CPU` 编程一样。

因此，编写一个 `Shader` 程序至少需要 **2** 部分:

1. 需要被 `GPU` 渲染的数据
2. 需要被 `GPU` 执行的程序

**注**: *之后的一切都建立在 `GLFW` 与 `GLEW` 初始化成功之后。*

本次内容会涉及到两种不同的 `Shader`:

* `VertexShader`: 作用于每个 `Vertex`，通常是处理从世界空间到裁剪空间(屏幕坐标)的坐标转换，后接`光栅化`。
* `FragmentShader`: 作用于每个屏幕上的 `Fragment` (可近似理解为像素)，通常是计算颜色。

### 数据

二维平面上，三角形有 **3** 个顶点，每个点的坐标包含 `x`, `y` **2** 个 `float` 数值。因此，可以使用 `c` 定义一个数组:

``` c
float positions[6] = {
    -0.5f, -0.5f,
     0.0f,  0.5f,
     0.5f, -0.5f
};
```

但这个数组是在内存中，如果要让 `GPU` 可以访问，需要将内存中的数据同步到显存中。

#### [GlGenBuffers](https://docs.gl/gl4/glGenBuffers)

``` c
// generate buffer object names
void glGenBuffers(GLsizei  n,
                  GLuint * buffers);
```

其作用是生成若干缓冲区名称，这个解释比较晦涩，其实就是创建 `n` 个缓冲区描述符保存在 `buffers` 中。可以有如下两种使用方式:

* 创建一个缓冲区

``` c
unsigned int buffer = 0;
// https://docs.gl/gl4/glGenBuffers
glGenBuffers(1, &buffer);
```

* 创建若干(一个或多个)缓冲区

``` c
unsigned int buffers[4] = { 0 };
glGenBuffers(sizeof(buffers) / sizeof(buffers[0]), buffers);
```

#### [GlBindBuffer](https://docs.gl/gl4/glBindBuffer)

缓冲区无法直接使用，需要将缓冲区与特定目标(target)绑定才可以使用。

``` c
void glBindBuffer(GLenum target,
                  GLuint buffer);
```

* `target` 从下表中选择
* `buffer` 缓冲区的名字
  * 当 `buffer` 表示的缓冲区不存在时会自动创建一个。
  * 当目标存在已绑定的缓冲区时，会使用本次的缓冲区替换之前的绑定关系。

|Buffer Binding Target|Purpose|
|:-|:-|
|GL_ARRAY_BUFFER|Vertex attributes|
|GL_ATOMIC_COUNTER_BUFFER| Atomic counter storage|
|GL_COPY_READ_BUFFER| Buffer copy source|
|GL_COPY_WRITE_BUFFER| Buffer copy destination|
|GL_DISPATCH_INDIRECT_BUFFER| Indirect compute dispatch commands|
|GL_DRAW_INDIRECT_BUFFER| Indirect command arguments|
|GL_ELEMENT_ARRAY_BUFFER| Vertex array indices|
|GL_PIXEL_PACK_BUFFER| Pixel read target|
|GL_PIXEL_UNPACK_BUFFER| Texture data source|
|GL_QUERY_BUFFER| Query result buffer|
|GL_SHADER_STORAGE_BUFFER| Read-write storage for shaders|
|GL_TEXTURE_BUFFER| Texture data buffer|
|GL_TRANSFORM_FEEDBACK_BUFFER| Transform feedback buffer|
|GL_UNIFORM_BUFFER| Uniform block storage|

#### [GlBufferData](https://docs.gl/gl4/glBufferData)

有了缓冲区，就可以使用 `glBufferData` 函数将数据写入到缓冲区中了。

``` c
void glBufferData(GLenum         target,
                  GLsizeiptr     size,
                  const GLvoid * data,
                  GLenum         usage);
```

* `target`: 同上
* `size`: 写入缓冲区的数据量，单位 `byte`
* `data`: 数据指针
* `usage`: 数据用途，由访问频率(frequency of access)与访问性质(nature of access)组成
  * 可取值:
    * `GL_STREAM_DRAW`
    * `GL_STREAM_READ`
    * `GL_STREAM_COPY`
    * `GL_STATIC_DRAW`
    * `GL_STATIC_READ`
    * `GL_STATIC_COPY`
    * `GL_DYNAMIC_DRAW`
    * `GL_DYNAMIC_READ`
    * `GL_DYNAMIC_COPY`
  * 频率(frequency of access):
    * `STREAM`: The data store contents will be modified once and used at most a few times.
    * `STATIC`: The data store contents will be modified once and used many times.
    * `DYNAMIC`: The data store contents will be modified repeatedly and used many times.
  * 性质(nature of access):
    * `DRAW`: The data store contents are modified by the application, and used as the source for GL drawing and image specification commands.
    * `READ`: The data store contents are modified by reading data from the GL, and used to return that data when queried by the application.
    * `COPY`: The data store contents are modified by reading data from the GL, and used as the source for GL drawing and image specification commands.

#### [GlEnableVertexAttribArray](https://docs.gl/gl4/glEnableVertexAttribArray)

`VertexAttribArray` 默认为 `Disable` 状态，必须使用函数显式启用才能使用。

``` c
void glEnableVertexAttribArray(GLuint index);
```

#### [GlVertexAttribPointer](https://docs.gl/gl4/glVertexAttribPointer)

定义 `VertexAttrib` 的数据。

``` c
void glVertexAttribPointer(GLuint         index,
                           GLint          size,
                           GLenum         type,
                           GLboolean      normalized,
                           GLsizei        stride,
                           const GLvoid * pointer);
```

* `index`: 这个目前还不明白，只知道要与 `glEnableVertexAttribArray` 参数同时为 `0`
* `size`: 每个顶点包含的元素数量，包括 **position(位置)**, **normal(法线)**, **color(颜色)**, 和 **texture coordinates(纹理坐标)**，可取值 **(1,2,3,4)**。
* `type`: 每个元素的数据类型，`GL_FLOAT` 表示以 `float` 为单位_
* `normalized`: 是否为向量(只有方向无大小)
* `stride`: 连续的顶点属性之间的字节偏移间隔
* `pointer`: 数据偏移量

#### 数据部分完整代码

``` c
    float positions[6] = {
        -0.5f, -0.5f,
         0.0f,  0.5f,
         0.5f, -0.5f
    };

    unsigned int buffer = 0;
    glGenBuffers(1, &buffer);
    glBindBuffer(GL_ARRAY_BUFFER, buffer);
    glBufferData(GL_ARRAY_BUFFER, 6 * sizeof(float), (const void*)(&positions), GL_STATIC_DRAW)
    glEnableVertexAttribArray(0);
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, sizeof(float) * 2, 0);
```

### `Shader` 与 `Program`

要得到一个可以被执行的 `Shader` 程序，需要

1. 编写 `Shader` 代码
2. 编译 `Shader` 代码
3. 链接到程序

#### `Shader` 代码

`Shader` 代码使用 `GLSL` 语言编写，语法结构类似与 `c` 要求语句以 `;` 结尾，由换行等。

> 注: 只考虑 `OpenGL` 的 `Shader` 语言，不考虑 `NVIDIA` 与 `MS` 等。

##### `VertexShader`

在本次示例中，`VertexShader` 用来控制点的坐标(position):

``` c
std::string vertexShader =
    "#version 330 core\n"
    "\n"
    "layout(location = 0) in vec4 position;\n"
    "\n"
    "void main() {\n"
    "    gl_Position = position;\n"
    "}\n"
    "";
```

1. `layout(location = 0)` 表示使用 `glVertexAttribPointer` 第一个参数 `index=0` 对应的数据。
2. `in vec4 position;` 中使用 `vec4` 是因为后续的 `gl_Position` 是 `vec4` 类型，虽然实际每个顶点是 `vec2`(`glVertexAttribPointer` 的第二个参数 `size=2`)类型
3. `in vec4 position;` 中的 `position` 表示每一个顶点(VetexAttrib)的 `position` 属性部分

##### `FragmentShader`

在本次示例中，`FragmentShader` 用来控制颜色(color):

``` c
std::string fragmentShader =
    "#version 330 core\n"
    "\n"
    "layout(location = 0) out vec4 color;\n"
    "\n"
    "void main() {\n"
    "    color = vec4(0.0, 1.0, 0.0, 1.0);\n" // 0: 黑色 1: 白色 范围: 0-1 (类比 0-255) 顺序: rgba
    "}\n"
    "";
```

#### 编译 `Shader` 代码

##### [GlCreateShader](https://docs.gl/gl4/glCreateShader)

编译 `Shader` 代码之前，需要先创建一个 `Shader` 对象，函数返回 `Shader` 描述符在之后所有 `Shader` 相关操作中使用:

``` c
GLuint glCreateShader(GLenum shaderType);
```

* `shaderType`: `Shader` 的类型，可取值:
  * `GL_COMPUTE_SHADER`
  * `GL_VERTEX_SHADER`
  * `GL_TESS_CONTROL_SHADER`
  * `GL_TESS_EVALUATION_SHADER`
  * `GL_GEOMETRY_SHADER`
  * `GL_FRAGMENT_SHADER`
* 返回值: `Shader` 描述符

##### [GlShaderSource](https://docs.gl/gl4/glShaderSource)

有了 `Shader` 之后，需要设置(替换) `Shader` 中的代码:

``` c
void glShaderSource(GLuint          shader,
                    GLsizei         count,
                    const GLchar ** string,
                    const GLint *   length);
```

* `shader`: 目标 `Shader` 描述符
* `count`: `string` 数组与 `length` 数组的长度
* `string`: 加载到 `Shader` 的字符串数组
* `length`: 字符串长度数组，与 `string` 相对应。如果 `length` 参数为 `NULL`，则假设每一个字符串以 `null` 结束。否则，则认为每一个元素表示相对应字符串的长度，小于 0 同样被认为以 `null` 结束。

使用传入的 `string` 参数设置 `Shader` 的源代码，原有代码会被完全替换。并且，根据函数可知，一个 `Shader` 可以设置多份源代码。

##### [GlCompileShader](https://docs.gl/gl4/glCompileShader)

与 `c/c++` 编写的程序一样，需要经过编译操作才能被执行，同样 `Shader` 代码也需要被编译，传入之前创建的 `Shader` 描述符:

``` c
void glCompileShader(GLuint shader);
```

* `shader`: `Shader` 描述符

##### 编译部分完整代码

``` c
static unsigned int ComplieShader(unsigned int type, const std::string& source) {
    unsigned int id = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(id, 1, &src, nullptr);
    glCompileShader(id);

    int result = 0;
    glGetShaderiv(id, GL_COMPILE_STATUS, &result);
    // 错误处理
    if (GL_FALSE == result) {
        int length = 0;
        glGetShaderiv(id, GL_INFO_LOG_LENGTH, &length);
        char* message = (char*)alloca(length * sizeof(char));
        glGetShaderInfoLog(id, length, &length, message);
        std::cout <<
            "Failed compile " <<
            ((type == GL_VERTEX_SHADER) ? "vertex" : "fragment") <<
            " shader: " << source <<
            " error: " << message <<
            std::endl;
        glDeleteShader(id);
        return 0;
    }

    return id;
}
```

#### 创建 `Program`

##### [GlCreateProgram](https://docs.gl/gl4/glCreateProgram)

首先需要创建一个程序对象，可以类比为一个可执行程序:

``` c
GLuint glCreateProgram(void);
```

##### [GlAttachShader](https://docs.gl/gl4/glAttachShader)

一个完整的 `Shader` 程序可能需要由若干个 `Shader` 组成，因此需要有一种将他们链接到一起的机制。`glAttachShader` 函数的作用是在链接之前，将 `Shader` 添加到 `Program` 上。可以类比为 `Cmake` 中的 `target_link_libraries` 函数，`program` 是 `executable`，`shader` 是 `libraries`:

``` c
void glAttachShader(GLuint program,
                    GLuint shader);
```

* `program`: 程序描述符
* `shader`: `Shader` 描述符

##### [GlLinkProgram](https://docs.gl/gl4/glLinkProgram)

当所有必要的 `Shader` 都添加到 `program` 上之后，就可以将他们链接起来了。类似于 `c/c++` 程序的链接阶段。

将 `program` 关联的所有 `Shader` 链接到一起，并根据 `Shader` 的类型，创建可执行程序交给相应的可编程处理器执行。

``` c
void glLinkProgram(GLuint program);
```

##### 链接阶段完整代码

``` c
// CreateProgram 输入 Shader 源码，返回相应的 Shader 程序
static unsigned int CreateProgram(const std::string& vertexShader, const std::string& fragmentShader) {
    unsigned int program = glCreateProgram();
    unsigned int vs = ComplieShader(GL_VERTEX_SHADER, vertexShader);
    unsigned int fs = ComplieShader(GL_FRAGMENT_SHADER, fragmentShader);

    glAttachShader(program, vs);
    glAttachShader(program, fs);
    glLinkProgram(program);
    glValidateProgram(program);
    glDeleteShader(vs);
    glDeleteShader(fs);
    return program;
}
```

#### 执行 Shader 程序

##### [GlUseProgram](https://docs.gl/gl4/glUseProgram)

正确链接的程序，需要通过 `glUseProgram` 函数显式执行才能进行渲染，类似于 `c/c++` 代码编译之后执行 `./a.out`。

``` c
void glUseProgram(GLuint program);
```

需要在进入主渲染循环之前调用该函数。
