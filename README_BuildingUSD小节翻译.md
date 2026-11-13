# README.md "Getting and Building the Code" 小节对照翻译

> **说明**：学习指南 `LEARNING_GUIDE.md` 第 0 章练习 0.3 中提到的"Building USD"小节，在 README.md 中的实际小节名是 **"Getting and Building the Code"**（第 89-250 行）。本文档即对该小节的对照翻译。
>
> 本文档采用对照式翻译：前一段是原英文，后一段是翻译的中文。
> 原文来源：`F:\newton\OpenUSD\README.md`（第 89-250 行）

---

## Getting and Building the Code
## 获取并构建代码

The simplest way to build USD is to run the supplied `build_usd.py` script. This script will download required dependencies and build and install them along with USD in a given directory.

构建 USD 最简单的方法是运行提供的 `build_usd.py` 脚本。该脚本会下载所需的依赖，并将它们连同 USD 一起构建和安装到指定目录中。

Follow the instructions below to run the script with its default behavior, which will build the USD core libraries, Imaging, and USD Imaging components. For more options and documentation, run the script with the `--help` parameter.

按照以下说明运行脚本，使用其默认行为，将构建 USD 核心库、Imaging（成像）和 USD Imaging（USD 成像）组件。如需更多选项和文档，请使用 `--help` 参数运行脚本。

See [Advanced Build Configuration](BUILDING.md) for examples and additional documentation for running cmake directly.

有关直接运行 cmake 的示例和更多文档，请参阅 [高级构建配置](BUILDING.md)。

---

### 1. Install prerequisites (see Dependencies for required versions)
### 1. 安装前置条件（所需版本见"依赖"小节）

- Required:
    - C++ compiler:
        - gcc
        - Xcode
        - Microsoft Visual Studio
    - CMake
- Optional (Can be ignored by passing `--no-python` as an argument to `build_usd.py`)
    - Python (required for bindings and tests)
    - PyOpenGL (required for usdview)
    - PySide6 or PySide2 (required for usdview)

- 必需：
    - C++ 编译器：
        - gcc
        - Xcode
        - Microsoft Visual Studio
    - CMake
- 可选（可以通过向 `build_usd.py` 传入 `--no-python` 参数来忽略）
    - Python（绑定和测试必需）
    - PyOpenGL（usdview 必需）
    - PySide6 或 PySide2（usdview 必需）

---

### 2. Download the USD source code
### 2. 下载 USD 源代码

You can download source code archives from GitHub or use `git` to clone the repository.

你可以从 GitHub 下载源代码压缩包，或使用 `git` 克隆仓库。

```
> git clone https://github.com/PixarAnimationStudios/OpenUSD
Cloning into 'OpenUSD'...
```

```
> git clone https://github.com/PixarAnimationStudios/OpenUSD
Cloning into 'OpenUSD'...
```

---

### 3. Run the script
### 3. 运行脚本

Run the build_usd.py script to build and install USD. Note that the build script is structured with an out-of-source build in mind -- installing a build into the directory where the repository was cloned is untested.

运行 build_usd.py 脚本来构建和安装 USD。注意，构建脚本的架构是基于"源外构建"（out-of-source build）设计的——将构建安装到克隆仓库的目录中是未经测试的。

> **翻译说明**：out-of-source build（源外构建）指构建产物放在源代码目录之外，不污染源代码目录。

---

#### Linux:
#### Linux：

For example, the following will download, build, and install USD's dependencies, then build and install USD into `/path/to/my_usd_install_dir`.

例如，以下命令将下载、构建和安装 USD 的依赖，然后构建和安装 USD 到 `/path/to/my_usd_install_dir`。

```
> python OpenUSD/build_scripts/build_usd.py /path/to/my_usd_install_dir
```

```
> python OpenUSD/build_scripts/build_usd.py /path/to/my_usd_install_dir
```

---

#### macOS:
#### macOS：

In a terminal, run `xcode-select` to ensure command line developer tools are installed. Then run the script.

在终端中运行 `xcode-select` 以确保已安装命令行开发者工具。然后运行脚本。

For example, the following will download, build, and install USD's dependencies, then build and install USD into `/path/to/my_usd_install_dir`.

例如，以下命令将下载、构建和安装 USD 的依赖，然后构建和安装 USD 到 `/path/to/my_usd_install_dir`。

```
> python OpenUSD/build_scripts/build_usd.py /path/to/my_usd_install_dir
```

```
> python OpenUSD/build_scripts/build_usd.py /path/to/my_usd_install_dir
```

---

#### iOS and visionOS:
#### iOS 和 visionOS：

When building from a macOS system, you can cross compile for iOS based platforms.

在 macOS 系统上构建时，你可以为 iOS 平台进行交叉编译。

Cross compilation builds are restricted to building libraries that can be embedded in applications built for the target platform. It can be helpful to use a monolithic build when embedding USD (see Advanced Build Configuration).

交叉编译构建仅限于构建可以嵌入目标平台应用程序的库。嵌入 USD 时使用单体构建（monolithic build）会有帮助（参见"高级构建配置"）。

These builds do not support Python bindings or command line tools.

这些构建不支持 Python 绑定或命令行工具。

For example, the following will download, build, and install USD's dependencies, then build and install USD for iOS into `/path/to/my_usd_install_dir`.

例如，以下命令将下载、构建和安装 USD 的依赖，然后为 iOS 构建和安装 USD 到 `/path/to/my_usd_install_dir`。

```
> python OpenUSD/build_scripts/build_usd.py --build-target iOS --build-monolithic /path/to/my_usd_install_dir
```

```
> python OpenUSD/build_scripts/build_usd.py --build-target iOS --build-monolithic /path/to/my_usd_install_dir
```

Or for visionOS:

或用于 visionOS：

```
> python OpenUSD/build_scripts/build_usd.py --build-target visionOS --build-monolithic /path/to/my_usd_install_dir
```

```
> python OpenUSD/build_scripts/build_usd.py --build-target visionOS --build-monolithic /path/to/my_usd_install_dir
```

---

##### Framework Builds (Experimental)
##### 框架构建（实验性）

Builds for Apple platforms may optionally build as a framework using the `--build-apple-framework` flag.

Apple 平台的构建可以选择使用 `--build-apple-framework` 标志来构建为框架（framework）。

**NOTE:** This feature is experimental and may change how it functions in future OpenUSD versions.

**注意：** 此功能是实验性的，在未来的 OpenUSD 版本中可能会改变其工作方式。

- Framework builds are enabled by default for iOS and visionOS build targets. It can optionally be enabled for macOS.
- Framework builds require monolithic builds.
- Building a universal macOS framework is currently not supported. Please generate the arches separately and `lipo` them together after.

- iOS 和 visionOS 构建目标默认启用框架构建。可以可选地为 macOS 启用。
- 框架构建需要单体构建。
- 目前不支持构建通用（universal）macOS 框架。请分别生成各架构，然后用 `lipo` 合并。

To add the Framework to your application, add `OpenUSD.framework` to your Xcode project. It is recommended to set it to `Embed and Sign`.

要将框架添加到你的应用程序中，请将 `OpenUSD.framework` 添加到你的 Xcode 项目中。建议将其设置为 `Embed and Sign`（嵌入并签名）。

To setup headers, configure the Xcode `SYSTEM_HEADER_SEARCH_PATHS` to add the path to your headers. e.g `$(SRCROOT)/OpenUSD.framework/Headers` if the framework exists in your projects root.

要设置头文件，配置 Xcode 的 `SYSTEM_HEADER_SEARCH_PATHS` 以添加头文件路径。例如，如果框架存在于你的项目根目录中，则为 `$(SRCROOT)/OpenUSD.framework/Headers`。

OpenUSD also supports building a combined XCFramework of multiple targets. This command takes an optional list of targets to build, but will otherwise build all supported platforms.

OpenUSD 还支持构建多个目标的组合 XCFramework。此命令接受一个可选的目标列表来构建，否则将构建所有支持的平台。

```
> python OpenUSD/build_scripts/apple_utils.py xcframework /path/to/my_usd_install_dir
```

```
> python OpenUSD/build_scripts/apple_utils.py xcframework /path/to/my_usd_install_dir
```

---

#### Windows:
#### Windows：

On Windows, it is possible to compile for either x64, or ARM64.
**Note**: ARM64EC is not compatible at this time.
**Note 2**: usdview is not supported on ARM64 at present, due to lack of PySide

在 Windows 上，可以编译 x64 或 ARM64 版本。
**注意**：ARM64EC 目前不兼容。
**注意 2**：由于缺少 PySide，ARM64 目前不支持 usdview。

Launch the "x64 Native Tools Command Prompt" (or "ARM64 Native Tools Command Prompt" where appropriate) for your version of Visual Studio, and run the script in the opened shell. Make sure to use the appropriate version of the command prompt (e.g. on x64, use the x64 version, not the x86 version).

启动对应你 Visual Studio 版本的"x64 Native Tools Command Prompt"（或在适当情况下启动"ARM64 Native Tools Command Prompt"），并在打开的 shell 中运行脚本。确保使用正确版本的命令提示符（例如在 x64 上使用 x64 版本，而不是 x86 版本）。

See https://docs.microsoft.com/en-us/cpp/build/how-to-enable-a-64-bit-visual-cpp-toolset-on-the-command-line for more details.

更多详情请参阅 https://docs.microsoft.com/en-us/cpp/build/how-to-enable-a-64-bit-visual-cpp-toolset-on-the-command-line 。

For example, the following will download, build, and install USD's dependencies, then build and install USD into `C:\path\to\my_usd_install_dir`.

例如，以下命令将下载、构建和安装 USD 的依赖，然后构建和安装 USD 到 `C:\path\to\my_usd_install_dir`。

```
C:\> python OpenUSD\build_scripts\build_usd.py "C:\path\to\my_usd_install_dir"
```

```
C:\> python OpenUSD\build_scripts\build_usd.py "C:\path\to\my_usd_install_dir"
```

---

#### WebAssembly:
#### WebAssembly：

A WebAssembly (Wasm) build can be produced using the Emscripten Compiler Toolchain on Linux, macOS or Windows. Before building, follow the instructions for downloading and installing the toolchain.

可以使用 Emscripten 编译器工具链在 Linux、macOS 或 Windows 上生成 WebAssembly（Wasm）构建。构建之前，请按照说明下载和安装该工具链。

The WebAssembly build will produce static libraries built in monolithic mode. Command line tools are not built for this target.

WebAssembly 构建将生成以单体模式构建的静态库。不会为此目标构建命令行工具。

The following will download dependencies and produce a 32 bit Wasm build.

以下命令将下载依赖并生成 32 位 Wasm 构建。

```
> python OpenUSD/build_scripts/build_usd.py --build-target wasm /path/to/my_usd_wasm_build_dir
```

```
> python OpenUSD/build_scripts/build_usd.py --build-target wasm /path/to/my_usd_wasm_build_dir
```

Or for a 64 bit Wasm build:

或用于 64 位 Wasm 构建：

```
> python OpenUSD/build_scripts/build_usd.py --build-target wasm64 /path/to/my_usd_wasm64_build_dir
```

```
> python OpenUSD/build_scripts/build_usd.py --build-target wasm64 /path/to/my_usd_wasm64_build_dir
```

---

### 4. Try it out
### 4. 试运行

Set the environment variables specified by the script when it finishes and launch `usdview` with a sample asset.

设置脚本完成时指定的环境变量，然后使用一个示例资产启动 `usdview`。

```
> usdview OpenUSD/extras/usd/tutorials/convertingLayerFormats/Sphere.usda
```

```
> usdview OpenUSD/extras/usd/tutorials/convertingLayerFormats/Sphere.usda
```

---

## 翻译说明

### 术语对照表

| 英文术语 | 中文翻译 | 说明 |
|---|---|---|
| build | 构建/编译 | 将源代码编译成可执行文件/库 |
| build_usd.py | build_usd.py | 脚本名保留不译 |
| out-of-source build | 源外构建 | 构建产物放在源代码目录之外 |
| monolithic build | 单体构建 | 编译成单个动态库/静态库 |
| install_dir | 安装目录 | 构建产物的安装位置 |
| prerequisites | 前置条件 | 构建前需要安装的依赖 |
| dependencies | 依赖 | 被依赖的第三方库 |
| Imaging | 成像 | USD 的渲染框架部分 |
| USD Imaging | USD 成像 | USD 与 Hydra 的桥接层 |
| Python bindings | Python 绑定 | 让 Python 调用 C++ 库的接口 |
| cross compile | 交叉编译 | 在一个平台编译另一个平台的代码 |
| framework | 框架 | Apple 平台的库打包格式 |
| XCFramework | XCFramework | Apple 多平台框架组合格式 |
| Native Tools Command Prompt | 原生工具命令提示符 | VS 的开发者命令行 |
| WebAssembly (Wasm) | WebAssembly | 网页端可执行的二进制格式 |
| Emscripten | Emscripten | C/C++ 编译成 Wasm 的工具链 |
| ARM64EC | ARM64EC | Windows on ARM 的兼容层 |

### 平台构建速查

| 平台 | 命令 |
|---|---|
| Linux | `python OpenUSD/build_scripts/build_usd.py /path/to/install_dir` |
| macOS | `python OpenUSD/build_scripts/build_usd.py /path/to/install_dir` |
| Windows | `python OpenUSD\build_scripts\build_usd.py "C:\path\to\install_dir"` |
| iOS | `python OpenUSD/build_scripts/build_usd.py --build-target iOS --build-monolithic /path/to/install_dir` |
| visionOS | `python OpenUSD/build_scripts/build_usd.py --build-target visionOS --build-monolithic /path/to/install_dir` |
| Wasm 32位 | `python OpenUSD/build_scripts/build_usd.py --build-target wasm /path/to/install_dir` |
| Wasm 64位 | `python OpenUSD/build_scripts/build_usd.py --build-target wasm64 /path/to/install_dir` |

### Windows 构建注意事项

| 注意点 | 说明 |
|---|---|
| 命令提示符 | 必须用 "x64 Native Tools Command Prompt"，不能用普通 cmd |
| ARM64 | 可以编译，但 usdview 不支持（缺 PySide） |
| ARM64EC | 目前不兼容 |
| 路径分隔符 | Windows 用反斜杠 `\`，Linux/macOS 用正斜杠 `/` |
| 安装路径 | 建议带引号，避免路径中有空格 |

---

*原文：`F:\newton\OpenUSD\README.md` 第 89-250 行（OpenUSD 26.08）*
