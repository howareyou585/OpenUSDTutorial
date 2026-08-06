# OpenUSD 学习指南：从零开始到通向 Omniverse / Isaac Sim / Newton

> **面向读者**：有 3D 与编程基础、但 OpenUSD 零基础的工程师
> **目标**：学完后能读懂 USD 文件、看懂 Stage 层级、动手用 Python 创作与编辑场景，为后续学习 Omniverse / Isaac Sim / Newton / IsaacLab 打下坚实基础
> **参考资料**：[OpenUSD Terms & Concepts — Omniverse USD](https://docs.omniverse.nvidia.com/usd/latest/learn-openusd/terms-concepts.html)
> **配套源码**：本仓库 `F:\newton\OpenUSD`（Pixar 官方上游源码，版本 26.08）

---

## 目录

- [环境搭建](#环境搭建)
- [第 0 章：OpenUSD 是什么 & 为什么它与众不同](#第-0-章openusd-是什么--为什么它与众不同)
- [第 1 章：Stage —— 场景的"工作台"](#第-1-章stage--场景的工作台)
- [第 2 章：Prim & Scene Graph —— 场景的"积木"](#第-2-章prim--scene-graph--场景的积木)
- [第 3 章：Layer & Layer Stack —— "意见"的层叠](#第-3-章layer--layer-stack--意见的层叠)
- [第 4 章：Composition Arcs —— 合成的"六条管线"](#第-4-章composition-arcs--合成的六条管线)
- [第 5 章：Property、Attribute、Primvar —— 描述世界的数据](#第-5-章propertyattributeprimvar--描述世界的数据)
- [第 6 章：Variant Set —— "同一物的多种形态"](#第-6-章variant-set--同一物的多种形态)
- [第 7 章：Model Kind & Model Hierarchy —— 场景的"语义层级"](#第-7-章model-kind--model-hierarchy--场景的语义层级)
- [第 8 章：Instancing —— "复制粘贴"的优雅版](#第-8-章instancing--复制粘贴的优雅版)
- [第 9 章：Asset & Asset Structure —— 可复用、可版本化的资产](#第-9-章asset--asset-structure--可复用可版本化的资产)
- [第 10 章：Reference-Payload Pattern & Lofting —— 资产管线的核心模式](#第-10-章reference-payload-pattern--lofting--资产管线的核心模式)
- [第 11 章：Composition Target & Resolver —— 资产定位的"DNS"](#第-11-章composition-target--resolver--资产定位的dns)
- [第 12 章：工具链总览 & 通向下游的桥梁](#第-12-章工具链总览--通向下游的桥梁)

---

## 环境搭建

在正式学习之前，先把"实验台"搭好。本节带你从源码编译 OpenUSD、配置 Python 环境，并跑通第一个 `usdview`。

### 0.1 你已经拥有的

- 源码仓库：`F:\newton\OpenUSD`（本仓库，Pixar 官方上游，版本 26.08）
- 详细的源码库地图见本指南末尾的 [附录 A：源码库地图](#附录-a源码库地图)

### 0.2 系统要求

| 项 | 要求 | 备注 |
|---|---|---|
| 操作系统 | Windows 10/11 64-bit | 本指南默认 Windows |
| 编译器 | Visual Studio 2019 或 2022 | 需 C++17 支持 |
| CMake | ≥ 3.27 | 见 `VERSIONS.md` |
| Python | 3.11 或 3.12 | 3.9/3.10 已弃用，见 `CHANGELOG.md` |
| 磁盘空间 | ≥ 10 GB（含第三方依赖源码） | |

> 完整的第三方库版本矩阵见仓库根目录的 `VERSIONS.md`。

### 0.3 一键编译：build_usd.py

OpenUSD 提供了一个"傻瓜式"构建脚本 `build_scripts/build_usd.py`，它会自动下载并编译所有依赖（Boost、TBB、OpenEXR、OpenSubdiv 等），最后编译 USD 本身。

打开 PowerShell（建议用 **x64 Native Tools Command Prompt for VS**，确保 cl.exe 在 PATH 中），执行：

```powershell
# 进入仓库根目录
cd F:\newton\OpenUSD

# 全量编译（含 Python 绑定 + usdview + Hydra 渲染）
# 注意：install_dir 必须放在 --build-args 之前（--build-args 会吃掉后续位置参数）
python build_scripts\build_usd.py `
    F:\newton\USD_Install `
    --build-args "USD,-DPXR_ENABLE_HDF5=OFF"

# 上述命令拆解：
#   F:\newton\USD_Install    <- 最终安装目录（唯一位置参数，无 build_dir）
#   --build-args             <- 自定义 CMake 参数，格式为 "库名,参数"（无空格）
#
# 如果不需要自定义参数，最简形式：
#   python build_scripts\build_usd.py F:\newton\USD_Install
```

> **首次编译耗时**：约 30-90 分钟（取决于机器配置），因为要下载并编译 10+ 个第三方库。
> **后续增量编译**：几分钟。

#### 常用编译选项

| 选项 | 作用 | 建议 |
|---|---|---|
| `--build-monolithic` | 编译成单个动态库 | 性能调试时关闭 |
| `--prefer-speed-over-safety` | Release 优化模式 | 学习阶段推荐 |
| `--no-tests` / `--no-examples` | 关闭测试/示例以加快编译 | 首次编译可加 |
| `--usdview` / `--no-usdview` | 启用/关闭 usdview 编译 | 默认开启，无需手动指定 |
| `--build-args "USD,<cmake参数>"` | 给特定库传 CMake 参数 | 高级用法，见下方说明 |

详见仓库根目录的 `BUILDING.md`。

### 0.4 配置环境变量

编译完成后，把安装目录加入环境变量：

```powershell
# 临时设置（当前 PowerShell 会话有效）
$env:PATH = "F:\newton\USD_Install\bin;F:\newton\USD_Install\lib;" + $env:PATH
$env:PYTHONPATH = "F:\newton\USD_Install\lib\python"

# 永久设置（推荐写入用户环境变量，幂等——可重复运行不会重复追加）
$userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
$usdBin = "F:\newton\USD_Install\bin;F:\newton\USD_Install\lib"
if ($userPath -notlike "*$usdBin*") {
    [Environment]::SetEnvironmentVariable("PATH", "$usdBin;$userPath", "User")
}
[Environment]::SetEnvironmentVariable("PYTHONPATH", "F:\newton\USD_Install\lib\python", "User")
```

> 设置后**新开一个 PowerShell 窗口**才能生效（当前窗口需用上面的临时设置或重启）。

### 0.5 验证安装

```powershell
# 1. 验证 Python 绑定（版本号会随 USD 发行版变化，26.08 发行版对应 0.26.x）
python -c "from pxr import Usd; print(Usd.GetVersion())"
# 期望输出类似: 0.26.8

# 2. 验证命令行工具
usdcat --help
usdtree --help

# 3. 启动 usdview（图形界面查看器，需要在 OpenUSD 源码目录下运行以访问示例文件）
cd F:\newton\OpenUSD
usdview extras/usd/tutorials/convertingLayerFormats/Sphere.usda
```

如果 `usdview` 窗口弹出并显示一个球体，恭喜，环境搭建完成！

### 0.6 推荐的编辑器配置

- **VS Code** + 以下扩展：
  - Python（Microsoft）
  - USD / USDA 语法高亮（搜 "usd" 或 "pixar usd"）
- 设置 `settings.json`（按 `Ctrl+,` 打开设置，点击右上角图标切换到 JSON）：

```json
{
  "python.defaultInterpreterPath": "python",
  "python.analysis.extraPaths": ["F:\\newton\\USD_Install\\lib\\python"],
  "files.associations": {
    "*.usda": "usd"
  }
}
```

> 注意：`python.pythonPath` 已被新版 VS Code Python 扩展弃用，改用 `python.defaultInterpreterPath`。

### 0.7 环境搭建练习

> **练习 0.1**：运行 `python -c "from pxr import Usd, UsdGeom, Sdf; print('USD ready')"`，确认输出正常。
>
> **练习 0.2**：先生成示例文件，再用 usdview 打开：
> ```powershell
> cd F:\newton\OpenUSD\extras\usd\tutorials\helloWorld
> python helloWorld.py            # 在当前目录生成 HelloWorld.usda
> usdview HelloWorld.usda         # 在 Stage 面板里点击 /hello prim，观察右侧 Properties 面板
> ```
>
> **练习 0.3**：用 `usdcat` 查看 USDA 文本格式文件的内容，感受 USD 的"人类可读"格式：
> ```powershell
> cd F:\newton\OpenUSD
> usdcat extras/usd/tutorials/convertingLayerFormats/Sphere.usda
> ```

---

## 模块一：建立心智模型

## 第 0 章：OpenUSD 是什么 & 为什么它与众不同

### 0.1 一个常见的误解

很多人第一次接触 USD，会以为它"只是一种 3D 文件格式，类似 .obj 或 .fbx"。**这是最大的误解**。

正确的理解是：

> **OpenUSD = 场景描述语言 + 合成引擎 + 资产管线哲学**

它不只是一个文件格式，而是一整套关于"如何在大型团队中协作编辑 3D 场景"的思想体系。文件格式（.usda/.usdc/.usdz）只是这套思想的载体之一。

### 0.2 与传统 DCC 软件的根本区别

在 Maya/Blender 这类传统 DCC 软件里，场景是一个"单一真值"——你打开一个 .mb 或 .blend 文件，里面就是最终结果。两个艺术家想同时改同一个场景？只能"你改完我再改"，或者用版本控制工具手动合并。

USD 的革命性在于：**它允许"多份意见"叠加合成**。

- 灯光师有自己的"意见文件"（Layer），只关心灯光
- 材质师有自己的"意见文件"，只关心材质
- 动画师有自己的"意见文件"，只关心动画
- 这些 Layer 通过合成引擎（Composition）叠加，得到最终的 Stage

每个人都可以独立工作，互不干扰，最后"合成"出最终结果。这正是 Pixar 制作一部动画电影时几百人协作的核心机制。

### 0.3 核心隐喻：Photoshop 图层

如果你用过 Photoshop，USD 的核心思想你其实已经懂了：

| Photoshop | USD |
|---|---|
| 一个 .psd 文件 | 一个 Stage |
| 图层（Layer） | Layer（.usda 文件） |
| 图层混合模式 | Composition Arcs（Reference/Payload/Inherit/...） |
| 最终合成图像 | 已合成的 Stage |
| 调整某个图层不影响其他图层 | 改一个 Layer 不影响其他 Layer |
| 图层有上下顺序（上面的遮挡下面的） | Layer 有 strength ordering（强意见覆盖弱意见） |

**记住这个类比**。整份指南会反复回到它上面。

### 0.4 为什么 Omniverse / Isaac Sim / Newton 都选 USD

- **Omniverse**：NVIDIA 的实时协作平台，直接把 USD 作为底层场景格式。多个用户可以同时编辑同一个 USD Stage，实时看到对方的修改。USD 的 Layer 合成天然支持协作。
- **Isaac Sim**：机器人仿真器。机器人世界本身就是 3D 场景，USD 提供了可组合、可实例化、可扩展的场景描述。
- **Newton 物理引擎**（NVIDIA+Google DeepMind 合作）：物理仿真需要稳定的场景几何 + 物理属性，USD 的 `usdPhysics` Schema 正是为此设计。
- **IsaacLab**：基于 Isaac Sim 的强化学习框架，环境是 USD 场景，机器人是 USD 资产。

学懂 USD，等于拿到了进入这些平台的"通用语言"。

### 0.5 USD 的核心组成（鸟瞰图）

```
OpenUSD
├── 数据模型      —— Sdf（Scene Description Foundation）：Layer/Spec/Path 的底层表示
├── 合成引擎      —— Pcp（Prim Composition）：把多个 Layer 合成出最终 Prim
├── 核心 API      —— Usd：Stage/Prim/Property，你日常打交道最多的层
├── 领域 Schema   —— UsdGeom/UsdShade/UsdLux/UsdPhysics/UsdSkel...：各类对象的标准定义
├── 渲染框架      —— Hydra（Hd）：可插拔的渲染委托架构
├── 工具链        —— usdview/usdcat/usdtree/usdchecker...
└── 插件机制      —— 文件格式插件、解析器插件、Schema 插件...
```

本指南会按"先数据模型 → 再合成 → 再资产管线 → 最后工具链"的顺序，逐层揭开。

### 0.6 第 0 章练习

> **练习 0.1**：用自己的话回答——USD 与 .fbx/.obj 这类文件格式最大的区别是什么？请至少说出 2 点。
> **练习 0.2**：阅读仓库 `pxr/usd/usd/docs/front.md` 的开头部分（用 `read` 工具或 VS Code 打开），对比本指南的描述，看看官方文档是怎么定位 USD 的。
> **练习 0.3**：打开 `README.md`（仓库根目录），找到"Building USD"小节，浏览一下 USD 支持哪些平台和构建选项。这是你以后查阅文档的入口。

---

## 模块二：核心数据模型

## 第 1 章：Stage —— 场景的"工作台"

### 1.1 定义（来自 Terms & Concepts）

> **Stage**：USD 数据模型的一个实例，持有整个场景图和关联数据。它是访问和操作 USD 文件或合成结果的入口点。

**通俗版**：Stage 是你"看到的那个最终场景"。它不是一个文件，而是**多个文件合成后的运行时对象**。

### 1.2 核心类比：舞台演出

想象一场舞台剧的演出：

- **Stage = 舞台上正在进行的演出本身**——观众看到的、活生生的、最终合成后的效果
- **Layer = 多份剧本草稿**——编剧写了剧本 v1、导演改了 v2、灯光师在 v3 加了灯光提示。这些是"意见"，不是演出本身
- **合成 = 导演把所有草稿叠加，决定最终的舞台效果**

关键点：观众看的是**演出（Stage）**，不是某一页草稿（Layer）。同理，你在 usdview 里看到的、你用 Python 操作的，都是 Stage。

### 1.3 Stage 与 Layer 的关系

```
            Layer (Sphere.usda)      ← 一份"意见"
            Layer (Material.usda)   ← 另一份"意见"
            Layer (Lighting.usda)   ← 又一份"意见"
                    │
                   合成（Composition）
                    │
                    ▼
                Stage  ← 最终场景（运行时对象）
                    │
            ┌───────┼───────┐
          PrimA   PrimB   PrimC   ← Stage 里的 Prim 树
```

- Layer 是**磁盘上的文件**（.usda/.usdc/.usdz）
- Stage 是**内存中的合成结果**
- 一个 Stage 由一个 **root Layer** + 若干 **sublayer / referenced Layer** 合成而来

### 1.4 创建你的第一个 Stage

```python
# 文件：chapter1_create_stage.py
from pxr import Usd, UsdGeom

# 方式一：创建一个全新的空 Stage（指定 root layer 文件路径）
stage = Usd.Stage.CreateNew("F:/myFirstStage.usda")

# 创建一个 Xform prim（最常用的容器 prim）
xform = UsdGeom.Xform.Define(stage, "/HelloWorld")

# 保存 root layer 到磁盘
stage.Save()

print(f"Stage saved. Root layer: {stage.GetRootLayer().realPath}")
```

运行后，用 `usdview F:/myFirstStage.usda` 打开，你会在 Stage 面板看到 `/HelloWorld` 这个 prim。

### 1.5 Stage 的关键 API

| API | 作用 |
|---|---|
| `Usd.Stage.CreateNew(path)` | 创建新 Stage，root layer 为 path |
| `Usd.Stage.Open(path)` | 打开已有 USD 文件作为 Stage |
| `stage.GetRootLayer()` | 获取 root layer（磁盘文件） |
| `stage.GetPseudoRoot()` | 获取伪根 prim（见第 2 章） |
| `stage.Traverse()` | 遍历所有 prim |
| `stage.GetPrimAtPath("/foo")` | 按路径取 prim |
| `stage.Save()` | 把所有可写 layer 保存到磁盘 |
| `stage.GetSessionLayer()` | 获取 session layer（临时修改层，不落盘） |

### 1.6 源码锚点

- 核心源码：`pxr/usd/usd/`（特别是 `usd/stage.h` 和 `usd/stage.cpp`）
- 概念文档：`pxr/usd/usd/docs/objectModel.md`
- 入门教程：`extras/usd/tutorials/helloWorld/helloWorld.py`
- 教程文档：`docs/tut_helloworld.rst`

### 1.7 第 1 章练习

> **练习 1.1**：用 Python 创建一个新 Stage，定义 `/World` 和 `/World/Camera` 两个 Xform prim，保存为 `chapter1_ex1.usda`。用 `usdcat` 查看文件内容。
>
> **练习 1.2**：用 `Usd.Stage.Open()` 打开 `extras/usd/tutorials/convertingLayerFormats/Sphere.usda`，用 `stage.Traverse()` 遍历所有 prim 并打印它们的路径。
>
> **练习 1.3**：在 usdview 中打开上面这个 Stage，找到 Properties 面板里的 "Composition" 标签页，观察这个 Stage 由哪些 layer 组成（目前只有一个 root layer，第 3 章会看到多个 layer 的合成）。

---

## 第 2 章：Prim & Scene Graph —— 场景的"积木"

### 2.1 定义（来自 Terms & Concepts）

> **Prims**：Prim 是 USD 场景中的基本构件。Prim 是 "primitive" 的缩写，代表场景层级中的一个对象或实体。
>
> **Scene Graph**：USD 中用来组织数据的层级化的 prim/命名空间数据结构。
>
> **Pseudo-Root Prim**：每个 Stage 都有一个伪根 prim，确保 Stage 的命名空间是一棵树（而非森林），简化 Stage 遍历算法。

### 2.2 通俗理解：Prim 是"节点"，Scene Graph 是"组织架构图"

**核心类比：公司组织架构图**

把 Stage 想象成一家公司：

- **Pseudo-Root Prim** = 公司本身（一个虚拟的"集团总部"，从不实际出现在组织架构图上，但所有部门都挂在它下面）
- **子 Prim** = 各个部门、子部门、员工
- **Scene Graph** = 整张组织架构图
- **Prim 的路径** = 员工的工号（如 `/Company/Engineering/Backend/Alice`）

关键特性：
1. **树形命名空间**：每个 prim 都有唯一路径（如 `/World/Robot/Arm`），路径反映父子关系
2. **Pseudo-Root**：所有顶层 prim 都挂在 `/`（伪根）下，保证是"一棵树"而非"多棵树"（森林）
3. **Prim 是容器**：一个 prim 可以包含其他 prim（子 prim）+ metadata + properties

### 2.3 Prim 的三大组成

一个 Prim 由三部分组成：

```
Prim
├── Type（类型）       —— 如 Xform/Mesh/Camera/Light/Sphere
├── Metadata（元数据） —— 如 kind、instanceable、hidden
└── Properties（属性）
     ├── Attributes（属性）  —— 有值的数据，如 xformOp:translate
     └── Relationships（关系）—— 指向其他 prim 的引用
```

#### Type（类型）

Prim 的类型决定了它的"职业"。常见类型：

| 类型 | 含义 | 所属 Schema |
|---|---|---|
| `Xform` | 变换节点（容器，可含子 prim） | UsdGeom |
| `Mesh` | 多边形网格 | UsdGeom |
| `Sphere`/`Cube`/`Cylinder` | 基本体 | UsdGeom |
| `Camera` | 摄像机 | UsdGeom |
| `DistantLight`/`SphereLight` | 灯光 | UsdLux |
| `Material`/`Shader` | 材质与着色器 | UsdShade |
| `PhysicsRigidBodyAPI` | 物理刚体 | UsdPhysics |

#### Metadata（元数据）

元数据是"关于这个 prim 的描述信息"，不是场景数据本身。例如：

- `kind`：标记这个 prim 在 model hierarchy 中的角色（见第 7 章）
- `instanceable`：是否启用实例化（见第 8 章）
- `hidden`：是否隐藏
- `documentation`：文档字符串

#### Properties（属性）

- **Attribute**：有值的数据，可以是单值，也可以是带时间采样的动画值
- **Relationship**：指向其他 prim 的引用（如材质绑定、灯光过滤器关联）

第 5 章会深入讨论 Properties。

### 2.4 创建 Prim

```python
# 文件：chapter2_create_prims.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/chapter2_prims.usda")

# 方式一：用 Schema 的 Define 方法（推荐，会自动创建所需的属性）
xform = UsdGeom.Xform.Define(stage, "/World")
mesh = UsdGeom.Mesh.Define(stage, "/World/Robot")
camera = UsdGeom.Camera.Define(stage, "/World/Camera")

# 方式二：用底层 API（更灵活但不推荐初学者）
# prim = stage.DefinePrim("/World/Light", "DistantLight")

stage.Save()

# 遍历打印
for prim in stage.Traverse():
    print(f"Path: {prim.GetPath()}, Type: {prim.GetTypeName()}")
```

期望输出：
```
Path: /World, Type: Xform
Path: /World/Robot, Type: Mesh
Path: /World/Camera, Type: Camera
```

### 2.5 Pseudo-Root Prim 详解

为什么需要伪根？想象一下：

- 如果没有伪根，一个 Stage 可以有多个顶层 prim：`/Foo`、`/Bar`、`/Baz`
- 这就是"森林"（多棵树），遍历算法需要处理多个根
- USD 选择强制有一个伪根 `/`，所有顶层 prim 都是它的子 prim
- 这样遍历算法永远从 `/` 开始，逻辑统一

```python
# 获取伪根
pseudo_root = stage.GetPseudoRoot()
print(pseudo_root.GetPath())  # 输出: /

# 获取所有顶层 prim（伪根的直接子节点）
for child in pseudo_root.GetChildren():
    print(f"Top-level prim: {child.GetPath()}")
```

### 2.6 Scene Graph 的命名空间规则

- Prim 路径用 `/` 分隔，类似文件系统路径：`/World/Robot/Arm`
- 路径**必须唯一**：不能有两个 `/World/Robot`
- 路径**不能以数字开头**，不能含空格：`/World/1Robot` ❌，`/World/Robot Arm` ❌
- 推荐用驼峰命名：`/World/RobotArm`

> **UTF-8 标识符**：USD 支持 UTF-8 标识符（如中文 prim 名），但生产环境强烈建议用 ASCII，避免跨工具兼容性问题。

### 2.7 Abstract Prims（抽象 Prim）

定义里提到："声明为 'class' specifier 的 prim 及其子 prim"。

通俗版：抽象 prim 类似面向对象编程里的**抽象基类**——它本身不渲染、不参与场景，只用来提供"模板"，被其他 prim 继承（通过 `inherits` arc）。第 4 章会详谈。

### 2.8 源码锚点

- 概念文档：`pxr/usd/usd/docs/objectModel.md`
- 遍历教程：`extras/usd/tutorials/traversingStage/traversingStage.py`
- 教程文档：`docs/tut_traversing_stage.rst`
- Prim 源码：`pxr/usd/usd/prim.h`

### 2.9 第 2 章练习

> **练习 2.1**：创建一个 Stage，结构如下，保存为 `chapter2_ex1.usda`：
> ```
> /World
>   /World/Environment
>     /World/Environment/Ground
>     /World/Environment/Sky
>   /World/Robot
>     /World/Robot/Head
>     /World/Robot/Body
> ```
> 用 `usdview` 打开查看 Scene Graph 树。
>
> **练习 2.2**：写一个递归函数 `print_prim_tree(prim, indent=0)`，从伪根开始打印整个 prim 树，缩进表示层级。运行在上一题的 Stage 上。
>
> **练习 2.3**：用 `stage.GetPrimAtPath("/World/Robot/Head")` 取一个 prim，分别打印它的 `GetTypeName()`、`GetParent().GetPath()`、`GetChildren()`。理解 prim 的上下行关系。
>
> **练习 2.4**：阅读 `extras/usd/tutorials/traversingStage/traversingStage.py` 源码，运行它（需要先生成 `HelloWorld.usda`），观察它如何遍历 Stage 并打印 prim 的属性。这是官方推荐的遍历模式。

---

## 第 3 章：Layer & Layer Stack —— "意见"的层叠

### 3.1 定义（来自 Terms & Concepts）

> **Layer**：USD 中协作的基本单位。每个 layer 代表一个用户对场景中资产的"意见"。Layer 可以覆盖其他 layer。

### 3.2 核心类比：法律体系

把 Layer Stack 想成**法律体系**，效力从高到低：

| 法律层级 | USD Layer Stack 中的角色 |
|---|---|
| 宪法（最高效力） | Layer Stack 顶部的 sublayer（最强意见） |
| 法律 | 次一层的 sublayer |
| 行政法规 | 再次一层 |
| 地方性法规（最低效力） | Layer Stack 底部的 sublayer（最弱意见） |

**关键规则：强意见覆盖弱意见**。如果"宪法"层说球是红色，"地方性法规"层说球是蓝色，最终球是红色——宪法的意见胜出。

> ⚠️ 注意：这里的"覆盖"指的是**同一个属性**的冲突解决。如果强层只声明了颜色，弱层声明了大小，最终结果是强层的颜色 + 弱层的大小——它们并不互相"抹掉"，只是对**同一字段**的冲突意见有强弱次序。

### 3.3 Layer Stack vs Sublayer

- **Layer**：一个 .usda/.usdc 文件，内含一份场景描述（"意见"）
- **Layer Stack**：由多个 Layer 通过 `subLayers` 组成的有序列表
- **Root Layer**：Layer Stack 的"最顶层"文件，即打开 Stage 时指定的那个文件
- **Session Layer**：可选的临时层，优先级比 root layer 还高，但不落盘（适合做"我在 usdview 里临时调一下看看效果"的操作）

一个 Layer 文件内部长这样（USDA 文本格式）：

```
#sdf 1.4.32
(
    subLayers = [
        @./geometry.usda@,
        @./materials.usda@,
        @./lighting.usda@
    ]
)

over "World" {
    # 这一层只在 /World 上添加"意见"，不创建新 prim
    over "Robot" {
        custom double xformOp:translate = (1, 2, 3)
    }
}
```

- `subLayers` 列出了 3 个下层 layer
- `over` 表示"如果这个 prim 已存在，我就对它添加意见；如果不存在，也不创建"
- 当前 layer（root）的意见最强，subLayers 中**靠前的比靠后的强**

### 3.4 Layer 的三种"意见"声明方式

```
def Xform "World"    # def = 定义：如果不存在就创建，存在就覆盖
over "World"         # over = 覆盖：只在已存在时添加意见，不创建
class "BaseShape"    # class = 抽象类：不渲染，作为模板供 inherits 使用
```

### 3.5 Layer 的格式

| 后缀 | 格式 | 说明 |
|---|---|---|
| `.usda` | ASCII 文本 | 人类可读，推荐学习阶段使用 |
| `.usdc` | 二进制（Crate） | 紧凑高效，生产推荐 |
| `.usdz` | 打包格式 | 单文件包含所有依赖，类似 zip |

三者内容等价，可互相转换：

```powershell
usdcat Sphere.usda -o Sphere.usdc    # usda → usdc
usdcat Sphere.usdc -o Sphere.usda    # usdc → usda
usdzip Sphere.usdz Sphere.usda       # 打包成 usdz
```

### 3.6 动手实验：多层覆盖

```python
# 文件：chapter3_layers.py
from pxr import Usd, UsdGeom

# ===== 1. 创建底层 layer（最弱意见）：几何层 =====
geom_stage = Usd.Stage.CreateNew("F:/chapter3_geom.usda")
UsdGeom.Xform.Define(geom_stage, "/World")
UsdGeom.Sphere.Define(geom_stage, "/World/Ball")
# 设置半径 = 1.0
UsdGeom.Sphere(geom_stage.GetPrimAtPath("/World/Ball")).GetRadiusAttr().Set(1.0)
geom_stage.Save()

# ===== 2. 创建覆盖层（较强意见）：把半径改成 5.0 =====
over_stage = Usd.Stage.CreateNew("F:/chapter3_override.usda")
# 把几何层作为 sublayer 叠加进来（覆盖层的意见更强）
over_stage.GetRootLayer().subLayerPaths.append("F:/chapter3_geom.usda")
# 在覆盖层里，用 over 声明对 /World/Ball 的意见（不创建新 prim，只覆盖属性）
over_prim = over_stage.OverridePrim("/World/Ball")
UsdGeom.Sphere(over_prim).GetRadiusAttr().Set(5.0)
over_stage.Save()

# ===== 3. 打开合成后的 Stage，看最终半径是多少 =====
final_stage = Usd.Stage.Open("F:/chapter3_override.usda")
final_ball = final_stage.GetPrimAtPath("/World/Ball")
final_radius = UsdGeom.Sphere(final_ball).GetRadiusAttr().Get()
print(f"Final radius (should be 5.0): {final_radius}")
```

期望输出：`Final radius (should be 5.0): 5.0`

**实验要点**：在 usdview 里打开 `chapter3_override.usda`，选中 `/World/Ball` prim，查看右侧 Properties 面板的 "Composition" 标签——你会看到两个 layer 的合成贡献，强层（override）的值 5.0 胜出。

### 3.7 源码锚点

- 概念文档：`pxr/usd/usd/docs/propertiesOfSceneDescription.md`（包含 layer 行为）
- 引用教程：`extras/usd/tutorials/referencingLayers/authorReferences.py`
- 教程文档：`docs/tut_referencing_layers.rst`
- Sdf 源码：`pxr/usd/sdf/`（特别是 `sdf/layer.h`）

### 3.8 第 3 章练习

> **练习 3.1**：创建 3 个 layer：`base.usda`（定义 `/World/Ball`，半径 1.0）、`mid.usda`（sublayer 引用 base，覆盖半径为 2.0）、`top.usda`（sublayer 引用 mid，覆盖半径为 3.0）。打开 `top.usda`，确认最终半径为 3.0，并理解"强意见传递"。
>
> **练习 3.2**：在上题的基础上，在 `top.usda` 里用 `over "World"` 但**不**覆盖半径，观察最终半径是多少（应该是 2.0，来自 mid 层）。这验证了"非冲突意见不互相抹掉"。
>
> **练习 3.3**：用 `usdcat chapter3_override.usda` 查看合成的 Stage（注意 usdcat 默认只显示 root layer，要看合成结果需用 `usdcat --flatten`）。对比两种输出的差异。

---

## 第 4 章：Composition Arcs —— 合成的"六条管线"

### 4.1 定义（来自 Terms & Concepts）

> **Composition**：把 USD 中各种场景图元素组合起来形成最终场景的过程。
>
> **Composition Arcs**：USD 中促进内容复用的机制，包括 references、payloads、inherits、specializes 等。
>
> **Composition Target**：被 composition arc 指向的 prim（或 layer）。通常是 Layer identifier + Sdf.Path 的组合。

### 4.2 六大 Arc 总览

USD 有六种 composition arc，每种有不同的语义和"强度"：

| Arc | 作用 | 典型场景 | 生活类比 |
|---|---|---|---|
| **Sublayer** | 把多个 layer 文件叠加 | 多人协作（每人一个 layer） | 文件夹分层 |
| **Reference** | 引用外部资产到当前 prim 下 | 复用一个模型/材质 | 函数调用 |
| **Payload** | 延迟加载的 reference | 大型资产，按需加载 | 懒加载/按需付费 |
| **Inherits** | 继承某个 class prim | 一类对象共享模板行为 | 类继承 |
| **Specializes** | 类似继承但更弱 | fallback 行为 | 默认配置 |
| **VariantSet** | prim 的"配置开关" | 多版本（红/蓝/绿） | 汽车选装包 |

### 4.3 LIVRPS Strength Ordering（核心记忆口诀）

六种 arc 有严格的"强度"次序，从强到弱：

```
L  Local opinions     （当前 prim 自己直接声明的属性）
I  Inherits           （inherits arc 带来的意见）
V  Variants           （variant 内部的意见）
R  References         （reference arc 带来的意见，含 payload）
P  Payloads           （payload arc 带来的意见，同 R 但延迟加载）
S  Specializes        （specializes arc 带来的意见，最弱）
```

口诀：**LIVRPS**（"利弗普斯"，类似 Liverpool）。

**核心规则**：当同一个属性被多个 arc 提供意见时，**强的胜出**。例如 Local 永远胜过 Reference——这意味着你可以在当前 prim 上"覆盖"被 reference 进来的属性。

> 📌 **重要**：Sublayer 不在这个列表里，因为 sublayer 是 **Layer 级别的合成**，而 LIVRPS 是 **Prim 级别的合成**。两者是不同维度的机制。

### 4.4 Sublayer vs Reference 的区别

这两个最容易混淆，重点区分：

| 维度 | Sublayer | Reference |
|---|---|---|
| 作用层级 | Layer 级（整个文件叠加） | Prim 级（外部内容挂到某个 prim 下） |
| 命名空间 | 不改变路径 | 引入新的子路径 |
| 典型场景 | 多人协作同一场景 | 复用一个外部资产 |
| 是否引入新 prim | 否（只是叠加意见） | 是（引入 target 的子树） |

**类比**：
- Sublayer = **透明纸叠放**（多张画叠在一起看，画的位置不变）
- Reference = **把另一幅画"贴"到当前画布的某个位置**（引入新内容到指定位置）

### 4.5 Reference 详解

```python
# 文件：chapter4_reference.py
from pxr import Usd, UsdGeom

# ===== 1. 先做一个"资产"文件 =====
asset_stage = Usd.Stage.CreateNew("F:/chapter4_robot.usda")
UsdGeom.Xform.Define(asset_stage, "/Robot")
UsdGeom.Mesh.Define(asset_stage, "/Robot/Body")
UsdGeom.Mesh.Define(asset_stage, "/Robot/Head")
asset_stage.Save()

# ===== 2. 在另一个 Stage 里 reference 这个资产 =====
scene_stage = Usd.Stage.CreateNew("F:/chapter4_scene.usda")
UsdGeom.Xform.Define(scene_stage, "/World")

# 给 /World 添加一个 reference，指向 robot.usda 的 /Robot
world_prim = scene_stage.GetPrimAtPath("/World")
world_prim.GetReferences().AddReference("F:/chapter4_robot.usda", "/Robot")

scene_stage.Save()

# ===== 3. 检查合成结果 =====
for prim in scene_stage.Traverse():
    print(prim.GetPath())
```

期望输出：
```
/World
/World/Body    ← 原 /Robot/Body 被 reference 进来，路径相对化了
/World/Head
```

**关键观察**：reference 把 `/Robot` 的内容挂到 `/World` 下，原 `/Robot/Body` 变成了 `/World/Body`——命名空间发生了变化。

### 4.6 Payload 详解

Payload 在语义上和 reference 几乎一样，区别在于**延迟加载**：

- Reference：打开 Stage 时立即加载
- Payload：默认不加载，调用 `prim.Load()` 后才加载

**场景**：一个工厂场景里有 1000 个机器人的 payload，但你现在只想看其中一个。如果用 reference，打开时要加载全部 1000 个；用 payload，默认全部不加载，按需 load。

```python
# 给 /World 添加 payload 而非 reference（接上例，在 scene_stage 上操作）
world_prim.GetPayloads().AddPayload("F:/chapter4_robot.usda", "/Robot")
scene_stage.Save()

# 重新打开（默认 LoadAll，但 payload 仍需显式 load）
stage = Usd.Stage.Open("F:/chapter4_scene.usda")
world_prim = stage.GetPrimAtPath("/World")
print([p.GetPath() for p in stage.Traverse()])  # 只有 /World（payload 未加载）

# 加载 payload
world_prim.Load()
print([p.GetPath() for p in stage.Traverse()])  # /World, /World/Body, /World/Head
```

打开 Stage 时还可以用 `Usd.Stage.LoadAll` 或 `Usd.Stage.LoadNone` 控制初始加载策略。

### 4.7 Inherits 详解

Inherits 用来实现"class → instance"的模板复用：

```python
stage = Usd.Stage.CreateNew("F:/chapter4_inherit.usda")

# 定义一个抽象 class prim
class_prim = stage.CreateClassPrim("/_BaseRobot")
UsdGeom.Mesh.Define(stage, "/_BaseRobot/Body")

# 定义一个具体 prim，继承 _BaseRobot
robot = UsdGeom.Xform.Define(stage, "/World/Robot1")
robot.GetPrim().GetInherits().AddInherit("/_BaseRobot")

stage.Save()

# 现在 /World/Robot1 也会有 Body 子 prim（从 _BaseRobot 继承来）
for prim in stage.Traverse():
    print(prim.GetPath())
```

输出：
```
/_BaseRobot          ← class，不会出现在 Traverse() 中（被跳过）
/World/Robot1
/World/Robot1/Body   ← 继承来的
```

### 4.8 Specializes 详解

Specializes 类似 inherits，但强度更弱（在 LIVRPS 中最末）。典型用途：给一类对象提供"默认行为"，但允许局部覆盖。

```python
# /_DefaultMaterial 提供默认材质
# /World/Robot1 specializes /_DefaultMaterial
# 如果 Robot1 自己声明了材质，用自己的；否则用 _DefaultMaterial 的
```

### 4.9 VariantSet 简介

VariantSet 比较复杂，下一章（第 6 章）专门讲。这里先记住：它是 prim 的"配置开关"，在 LIVRPS 中位于 I 和 R 之间。

### 4.10 源码锚点

- 概念文档：`pxr/usd/usd/docs/authoringEditing.md`
- 合成引擎源码：`pxr/usd/pcp/`（Prim Composition）
- 高级特性文档：`pxr/usd/usd/docs/advancedFeatures.md`
- 引用教程：`extras/usd/tutorials/referencingLayers/authorReferences.py`

### 4.11 第 4 章练习

> **练习 4.1**：创建 `tree.usda`（含 `/Tree` Xform，下有 `/Tree/Trunk` Mesh 和 `/Tree/Leaves` Mesh）。再创建 `forest.usda`，在 `/World` 下用 `AddReference` 引入 3 棵树（路径分别为 `/World/Tree1`、`/World/Tree2`、`/World/Tree3`）。遍历 forest Stage 确认有 3 棵树。
>
> **练习 4.2**：把上题的 reference 改成 payload，观察默认打开 forest.usda 时的 Traverse 结果（应该只有 `/World` 和 3 个空的 Tree 容器），然后调用 `stage.LoadAndUnload` 加载所有 payload，再观察结果。
>
> **练习 4.3**：定义一个 class prim `/_BaseCar`（含 `/Wheel` Mesh），创建 `/World/Car1` 继承 `/_BaseCar`，确认 `/World/Car1/Wheel` 出现在 Traverse 中。再用 `usdview` 打开，观察 `_BaseCar` 是否在 Scene Graph 中显示（应该不显示，因为它是 class）。

---

## 第 5 章：Property、Attribute、Primvar —— 描述世界的数据

### 5.1 定义

- **Property**：prim 上的命名数据字段，分两类——Attribute 和 Relationship
- **Attribute**：有值的 property，值可以是单值或时间采样（动画）
- **Relationship**：指向其他 prim 的引用（无值，只有目标路径）
- **Primvar**：primitive variable，渲染器会读取的"额外数据通道"

### 5.2 核心类比：员工档案

把 prim 想象成一名员工：

| 概念 | 类比 |
|---|---|
| **Prim** | 员工本人 |
| **Attribute** | 员工档案里的字段（年龄、入职日期、薪资） |
| **Time-sampled Attribute** | 每月工资单（按时间变化的字段） |
| **Relationship** | 员工的"汇报关系"（指向另一个 prim） |
| **Primvar** | 员工的"工牌"（贴在身上的额外标签，渲染器会读） |

关键区分：
- Attribute 是"普通数据"，USD 引擎关心它
- Primvar 是"渲染数据"，渲染器（Hydra）会读它来影响渲染结果（如顶点颜色、UV）

### 5.3 Attribute 详解

#### 5.3.1 创建 Attribute

```python
from pxr import Usd, UsdGeom, Sdf

stage = Usd.Stage.CreateNew("F:/chapter5_attrs.usda")
xform = UsdGeom.Xform.Define(stage, "/World")

# 方式一：用 Schema 的便捷方法（推荐，会自动加前缀如 xformOp:）
translate_op = xform.AddTranslateOp()
translate_op.Set((1.0, 2.0, 3.0))

# 方式二：用底层 API 创建自定义 attribute
prim = xform.GetPrim()
color_attr = prim.CreateAttribute("custom:color", Sdf.ValueTypeNames.Color3f)
color_attr.Set((1.0, 0.0, 0.0))  # 红色

stage.Save()
```

#### 5.3.2 时间采样（Animation）

```python
# 创建一个带动画的属性
from pxr import Usd, UsdGeom, Sdf

stage = Usd.Stage.CreateNew("F:/chapter5_anim.usda")
sphere = UsdGeom.Sphere.Define(stage, "/World/Ball")

radius_attr = sphere.GetRadiusAttr()
# 在 time=0 设置半径 1.0，time=24（假设 24fps 下的 1 秒）设置半径 5.0
radius_attr.Set(1.0, time=0.0)
radius_attr.Set(5.0, time=24.0)

stage.Save()

# 读取中间时刻的值（USD 会自动插值）
stage2 = Usd.Stage.Open("F:/chapter5_anim.usda")
r = UsdGeom.Sphere(stage2.GetPrimAtPath("/World/Ball")).GetRadiusAttr().Get(time=12.0)
print(f"Radius at t=12: {r}")  # 期望 3.0 左右（线性插值）
```

用 usdview 打开，拖动时间轴能看到球大小变化。

#### 5.3.3 常用 Sdf.ValueTypeNames

| 类型名 | 对应 Python 类型 | 用途 |
|---|---|---|
| `Float` / `Double` | float | 标量 |
| `Int` | int | 整数 |
| `Bool` | bool | 布尔 |
| `Float3` / `Vector3f` | tuple/list of 3 | 向量 |
| `Color3f` | tuple of 3 | 颜色（语义不同于向量） |
| `Matrix4d` | Gf.Matrix4d | 4x4 变换矩阵 |
| `String` | str | 字符串 |
| `Asset` | Sdf.AssetPath | 资产路径 |
| `Token` | str（但语义是枚举） | 枚举值 |

### 5.4 Relationship 详解

Relationship 指向其他 prim，没有"值"，只有目标路径列表。

```python
from pxr import Usd, UsdShade

stage = Usd.Stage.CreateNew("F:/chapter5_rel.usda")
UsdGeom.Mesh.Define(stage, "/World/Robot")
material = UsdShade.Material.Define(stage, "/World/Material")

# 用 UsdShade 的 API 绑定材质（底层就是创建 relationship）
robot_prim = stage.GetPrimAtPath("/World/Robot")
UsdShade.MaterialBindingAPI(robot_prim).Bind(material)

# 查看创建的 relationship
binding_rel = robot_prim.GetRelationship("material:binding")
print(f"Targets: {binding_rel.GetTargets()}")  # [/World/Material]
```

### 5.5 Primvar 详解

Primvar 是"渲染器读取的额外通道"。常见用途：
- 顶点颜色（`displayColor`）
- UV 坐标（`st` 或 `uv`）
- 法线（`normals`）
- 任意自定义数据（如每个顶点的"损伤值"）

```python
from pxr import Usd, UsdGeom, Vt, Sdf

stage = Usd.Stage.CreateNew("F:/chapter5_primvar.usda")
mesh = UsdGeom.Mesh.Define(stage, "/World/Cube")

# 设置每个顶点的颜色（displayColor 是预定义 primvar）
colors = Vt.Vec3fArray([
    (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 0),  # 5 个顶点的颜色
    (1, 0, 1), (0, 1, 1), (1, 1, 1), (0, 0, 0)
])
UsdGeom.PrimvarsAPI(mesh).CreatePrimvar("displayColor", 
                                         Sdf.ValueTypeNames.Color3fArray,
                                         "constant").Set(colors)
```

Primvar 的 interpolation 参数决定"数据是每个顶点一个，还是每个面一个"：
- `constant`：整个 prim 一个值
- `uniform`：每个面一个
- `varying`/`vertex`：每个顶点一个
- `faceVarying`：每个面的每个顶点一个（UV 常用）

### 5.6 Property 的"强度"与 Layer

Property 同样受 LIVRPS 影响：在不同 layer 中对同一 property 的意见，按 arc 强度解决冲突。强层的 attribute 值会覆盖弱层的。

### 5.7 源码锚点

- 属性文档：`pxr/usd/usd/docs/propertiesOfSceneDescription.md`
- Primvar 用户指南：`docs/user_guides/primvars.rst`
- 时间与动画：`docs/user_guides/time_and_animated_values.rst`
- 创作编辑：`pxr/usd/usd/docs/authoringEditing.md`

### 5.8 第 5 章练习

> **练习 5.1**：创建一个 Mesh，添加两个自定义 attribute：`custom:health`（int，值 100）和 `custom:team`（token，值 "red"）。用 `usdcat` 查看文件确认。
>
> **练习 5.2**：创建一个 Sphere，给它的 `radius` 属性添加 5 个时间采样（time=0,1,2,3,4，半径 1,2,3,4,5）。用 usdview 拖动时间轴确认动画。
>
> **练习 5.3**：创建一个 Mesh（至少 4 个顶点），添加 `displayColor` primvar（每顶点一个颜色），在 usdview 中确认顶点颜色生效（可能需要切换显示模式为 "Smooth Shaded" 并开启 primvar 显示）。
>
> **练习 5.4**：创建两个 prim `/A` 和 `/B`，给 `/A` 添加一个 relationship `targetPrim` 指向 `/B`。用 Python 读取这个 relationship 的 targets，确认是 `[/B]`。

---

## 第 6 章：Variant Set —— "同一物的多种形态"

### 6.1 定义（来自 Terms & Concepts）

> **Variant Set**：一个 prim 的替代表示或配置的集合。例如，一个 Variant Set 可以包含不同材质变化、不同 LOD、或不同几何表示。

### 6.2 核心类比：汽车配置单

想象你买车时面对的"配置单"：

- **车型（Prim）**：Model X
- **Variant Set "颜色"**：红 / 蓝 / 黑 / 白
- **Variant Set "轮毂"**：19寸 / 21寸 / 22寸
- **Variant Set "内饰"**：标准 / 运动版 / 豪华版

同一个车型（prim），通过不同 variant 选择，可以组合出几十种具体配置——但底层只维护**一个 prim 定义 + 多组 variant 意见**。

对比传统做法："导出 RedCar.fbx、BlueCar.fbx、BlackCar.fbx..."，Variant Set 的优势：
1. 数据复用：公共部分只存一份
2. 切换灵活：运行时切换 variant，无需重新加载
3. 协作友好：材质师只改 colorVariant，几何师只管 geometryVariant

### 6.3 创建 Variant Set

```python
# 文件：chapter6_variants.py
from pxr import Usd, UsdGeom, Sdf

stage = Usd.Stage.CreateNew("F:/chapter6_variants.usda")
car = UsdGeom.Xform.Define(stage, "/World/Car")

# 在 /World/Car 上创建一个 VariantSet "color"
vsets = car.GetVariantSets()
color_vset = vsets.AddVariantSet("color")

# 添加两个 variant
color_vset.AddVariant("red")
color_vset.AddVariant("blue")

# 在 red variant 里设置意见
color_vset.SetVariantSelection("red")
with color_vset.GetVariantEditContext():
    # 此时所有创作都会进入 "red" variant
    car.GetPrim().CreateAttribute("custom:colorRGB", 
                                   Sdf.ValueTypeNames.Color3f).Set((1, 0, 0))

# 切到 blue variant，设置蓝色意见
color_vset.SetVariantSelection("blue")
with color_vset.GetVariantEditContext():
    car.GetPrim().CreateAttribute("custom:colorRGB",
                                   Sdf.ValueTypeNames.Color3f).Set((0, 0, 1))

# 默认选中 red
color_vset.SetVariantSelection("red")
stage.Save()
```

用 usdview 打开，选中 `/World/Car`，在 Properties 面板能看到 `color` VariantSet 的下拉菜单，切换 red/blue 会看到颜色变化。

### 6.4 Variant 的合成语义

在 LIVRPS 中，**V (Variants)** 位于 I 和 R 之间。这意味着：

- Local 意见（直接在 prim 上写的）> Variant 内的意见
- Variant 内的意见 > Reference 带来的意见

**关键**：variant 内的意见只有在"当前选中的 variant"里才生效。选 red 时，blue variant 里的意见完全被忽略。

### 6.5 多 VariantSet 组合

一个 prim 可以有多个 VariantSet，它们是**正交**的：

```python
# 在 /World/Car 上再加一个 LOD variant set
lod_vset = vsets.AddVariantSet("lod")
lod_vset.AddVariant("high")
lod_vset.AddVariant("low")

lod_vset.SetVariantSelection("high")
with lod_vset.GetVariantEditContext():
    # 在 high variant 里引用一个高精度模型
    car.GetPrim().GetReferences().AddReference("F:/car_high.usda", "/Car")

lod_vset.SetVariantSelection("low")
with lod_vset.GetVariantEditContext():
    car.GetPrim().GetReferences().AddReference("F:/car_low.usda", "/Car")
```

现在 `/World/Car` 有两个独立的"开关"：color 和 lod。可以组合出 red+high、red+low、blue+high、blue+low 四种配置。

### 6.6 Variant 与资产管线

Variant Set 是 USD 资产管线的核心模式之一。典型用法：

- **LOD Variant**：同一模型的高/中/低精度版本
- **Material Variant**：同一几何体的不同材质（生锈/崭新）
- **Pose Variant**：角色的不同姿势（站立/坐下）
- **Damage Variant**：物体的损坏程度（完好/破损）

第 10 章会看到，**Asset Parameterization** = Variant Set + Primvar，是资产可参数化的标准方式。

### 6.7 源码锚点

- 变体教程：`extras/usd/tutorials/authoringVariants/authorVariants.py`
- 教程文档：`docs/tut_authoring_variants.rst`
- 高级特性：`pxr/usd/usd/docs/advancedFeatures.md`
- 变体资产生成示例：`extras/usd/examples/usdMakeFileVariantModelAsset/`

### 6.8 第 6 章练习

> **练习 6.1**：创建 `/World/Tree`，加一个 VariantSet "season"，包含 `spring`/`summer`/`autumn`/`winter` 四个 variant，每个 variant 设置不同的 `displayColor`（春绿、夏深绿、秋黄、冬白）。用 usdview 切换确认。
>
> **练习 6.2**：在上题基础上，再加一个 VariantSet `lod`（high/low）。在 high variant 里 reference 一个高精度 mesh 文件（可临时创建），在 low variant 里 reference 一个低精度文件。组合出 4×2=8 种配置。
>
> **练习 6.3**：阅读 `extras/usd/tutorials/authoringVariants/authorVariants.py`，运行它生成 `HelloWorld.usda`，用 usdview 打开，在 VariantSet 面板切换 `shadingVariant`，观察球体的材质变化。

---

## 第 7 章：Model Kind & Model Hierarchy —— 场景的"语义层级"

### 7.1 定义（来自 Terms & Concepts）

> **Model Kind**：提供一种在 Stage 层级（"model hierarchy"）中组织和分类 Prim 的方式。
>
> **Model Hierarchy**：用 kind 标记的 prim 层级，把场景里的 prim 分成"模型"和"非模型"。
>
> **Shallowness (Model Hierarchy)**：model hierarchy 应当浅而宽，不应过深（出于性能和导航性考虑）。
>
> **Completeness (Model Hierarchy)**：`component` 和 `assembly` 模型应"开箱即用"，含完整几何与材质。

### 7.2 核心类比：图书馆分类

把整个 Stage 想成一座图书馆：

| 图书馆 | USD Stage |
|---|---|
| 图书馆建筑 | Stage |
| 分区（科技区、文学区） | assembly 模型 |
| 书架 | group 模型 |
| 单本书 | component 模型 |
| 书里的页 | subcomponent（非模型，但属于某 component） |

**Model Hierarchy** = 这座图书馆的"分类导航"——从分区到书架到书。它跳过了书页（非模型内容），只给你"模型级别"的概览。

### 7.3 四种 Kind

`kind` 是 prim 的一个 metadata，标记它在 model hierarchy 中的角色：

| Kind | 含义 | 是否是"模型" |
|---|---|---|
| `component` | 叶子模型（完整的单个资产，如一辆车、一个角色） | ✅ |
| `assembly` | 组合模型（由多个 component 或 assembly 组成，如一个房间） | ✅ |
| `group` | 纯组织节点（不含几何，只是分组容器） | ✅ |
| `subcomponent` | 模型内部的子部分（如车的轮子） | ❌（非模型） |

未设置 kind 的 prim 也不算模型。

### 7.4 设置 Kind

```python
from pxr import Usd, UsdGeom, UsdModelAPI

stage = Usd.Stage.CreateNew("F:/chapter7_kinds.usda")

# 创建一个 assembly
room = UsdGeom.Xform.Define(stage, "/World/Room")
UsdModelAPI(room).SetKind("assembly")

# 房间里有一辆车（component）
car = UsdGeom.Xform.Define(stage, "/World/Room/Car")
UsdModelAPI(car).SetKind("component")

# 车有轮子（subcomponent）
wheel = UsdGeom.Mesh.Define(stage, "/World/Room/Car/Wheel")
UsdModelAPI(wheel).SetKind("subcomponent")

stage.Save()
```

### 7.5 Model Hierarchy 的查询

```python
# 用 UsdModelAPI 查询一个 prim 是否是 model
room_api = UsdModelAPI(stage.GetPrimAtPath("/World/Room"))
print(room_api.IsModel())        # True（assembly 是 model）
print(room_api.IsGroup())        # True（assembly 也是 group）

car_api = UsdModelAPI(stage.GetPrimAtPath("/World/Room/Car"))
print(car_api.IsModel())         # True（component 是 model）
print(car_api.IsGroup())         # False（component 不是 group）

wheel_api = UsdModelAPI(stage.GetPrimAtPath("/World/Room/Car/Wheel"))
print(wheel_api.IsModel())       # False（subcomponent 不是 model）
```

命令行工具 `usdtree` 默认只显示 model hierarchy（跳过非模型 prim），非常适合快速浏览大场景：

```powershell
usdtree F:\chapter7_kinds.usda
# 输出：
# /World
#   /World/Room      (assembly)
#     /World/Room/Car  (component)
```

### 7.6 Shallowness 原则

**为什么 model hierarchy 应当浅？**

- 性能：USD 合成引擎对深层嵌套的 model 优化有限
- 导航性：深达 20 层的层级，艺术家找不到东西
- 协作：层级越深，不同艺术家越容易"踩脚"

**经验法则**：
- component 通常在层级 2-4 层
- assembly 不应嵌套超过 2-3 层
- 超过 5 层的 model hierarchy 通常需要重构

### 7.7 Completeness 原则

`component` 和 `assembly` 应当"开箱即用"——直接 reference 进场景就能渲染，不需要额外补充几何或材质。

**反例**：一个 `/Car` component 只定义了车身，没有材质和轮子——这违反 completeness 原则，下游用户引用时还要自己补齐。

### 7.8 Component Model Boundary

定义里提到的 "Component Model Boundary"：model hierarchy 与 prim hierarchy 的边界。即：`component` 及其 kind 为 component/assembly 的祖先构成 "model hierarchy"，而 component 内部的 subcomponent 和其他无 kind 的 prim 属于 "prim hierarchy" 但不进入 "model hierarchy"。

简单说：**component 是"模型"的最小完整单位，它内部的细节（subcomponent）不算独立模型**。

### 7.9 源码锚点

- Kind 模块：`pxr/usd/kind/`
- Kind 注册表：`pxr/usd/kind/registry.h`
- ModelAPI：`pxr/usd/usd/modelAPI.h`
- 用户指南：`docs/user_guides/`（搜索 "kind"）

### 7.10 第 7 章练习

> **练习 7.1**：构建一个简单场景：`/World/Factory`（assembly）下有 `/World/Factory/Robot1` 和 `/World/Factory/Robot2`（都是 component），每个 Robot 下有 `/Head`、`/Body`、`/Arm`（subcomponent）。用 `usdtree` 查看结果，确认只显示到 Robot 级别。
>
> **练习 7.2**：写一个 Python 函数 `find_all_components(stage)`，遍历 Stage 返回所有 kind 为 "component" 的 prim 路径。运行在上一题的 Stage 上。
>
> **练习 7.3**：阅读 `extras/usd/examples/usdMakeFileVariantModelAsset/` 目录下的脚本，理解它如何生成一个带 variant 的 component 资产。这是工业界的标准资产构建模式。

---

## 模块三：实例化体系

## 第 8 章：Instancing —— "复制粘贴"的优雅版

### 8.1 定义（来自 Terms & Concepts）

> **Instancing**：为工作流或性能原因，创建一个对象的多个实例，共享同一份数据。
>
> **Instanceable**：prim 的一个属性，设为 true 时允许该 prim 被实例化。
>
> **Prototype**：场景图（或其一部分）的中心副本，可被实例化。
>
> **Native Instance**：instanceable prim（区别于 point instancer）。
>
> **Point Instancer**：一种特定的 instancer，允许高效表示和渲染大量实例。
>
> **Instance Proxy Prim**：因为实例本质上只是指向其 prototype 的指针，实例内部的本地 prim 路径并不真正存在。USD 提供 "instance proxy prim" 作为占位符，可以像实例内容存在一样显示它们。
>
> **Implicit Prototypes**：USD 为 instanceable prim 自动创建的 prototype。
>
> **Explicit Prototypes**：用户显式创建的、作为 prototype 内容的编辑目标。
>
> **Globally Refinable Instancing**：实例在下游组装场景中仍可"细化"的实例化方式。
>
> **Internally Refinable Instancing**：实例不期望在下游被细化的实例化方式。

### 8.2 为什么需要实例化

**痛点**：想象一个森林场景，有 10000 棵树。如果每棵树都独立存储几何数据，文件巨大、加载缓慢、内存爆炸——而实际上这 10000 棵树可能只是 5 个树种的重复。

**USD 的解法**：把每个树种定义为一个 **Prototype**（原型），然后创建 10000 个 **Instance**（实例），每个实例只是"指向原型的指针"。数据只存 5 份，内存和文件大小大幅下降。

### 8.3 核心类比

| 类比 | USD 对应 |
|---|---|
| **Excel 公式 `=A1`**：单元格 B1 引用 A1，A1 改了 B1 自动跟着改 | Native Instance：实例指向 prototype，prototype 改了所有实例跟着改 |
| **复制粘贴值**：把 A1 的值复制到 B1，之后 A1 改了 B1 不变 | 非 instance 的 duplicate：数据独立，互不影响 |
| **邮局分拣中心**：一个分拣规则（prototype）应用到 10000 封信（instance） | Point Instancer：一个原型 + 10000 个变换矩阵 |
| **变量与指针**（编程）：`obj2 = obj1`（引用）vs `obj2 = obj1.copy()`（复制） | instanceable=true（引用）vs false（复制） |

### 8.4 Native Instance（instanceable prim）

#### 8.4.1 创建 Native Instance

```python
# 文件：chapter8_instancing.py
from pxr import Usd, UsdGeom

# ===== 1. 先在一个单独文件里定义"原型"树 =====
proto_stage = Usd.Stage.CreateNew("F:/chapter8_tree_proto.usda")
tree = UsdGeom.Xform.Define(proto_stage, "/Tree")
UsdGeom.Mesh.Define(proto_stage, "/Tree/Trunk")
UsdGeom.Mesh.Define(proto_stage, "/Tree/Leaves")
proto_stage.Save()

# ===== 2. 创建森林场景，实例化这棵树 =====
stage = Usd.Stage.CreateNew("F:/chapter8_forest.usda")
UsdGeom.Xform.Define(stage, "/World")

# 创建多个实例：每个实例 reference 原型文件并标记为 instanceable
for i in range(5):
    instance = UsdGeom.Xform.Define(stage, f"/World/Tree_{i}")
    instance.GetPrim().GetReferences().AddReference(
        "F:/chapter8_tree_proto.usda", "/Tree"
    )
    instance.GetPrim().SetInstanceable(True)
    # 设置每个实例的位置
    instance.AddTranslateOp().Set((i * 3.0, 0, 0))

stage.Save()
```

> 注意：把原型放在单独文件里是最佳实践，避免同一个文件自引用造成的循环依赖。

#### 8.4.2 验证实例化效果

```python
stage = Usd.Stage.Open("F:/chapter8_forest.usda")

# 查看所有 prim
for prim in stage.Traverse():
    print(prim.GetPath())

# 输出会包含 /World/TreeTemplate 和 5 个 /World/Tree_X
# 但每个 Tree_X 下的 Trunk/Leaves 不会直接出现在 Traverse 中
# 因为它们是"实例内部"的，需要通过 instance proxy 访问
```

**关键**：USD 自动为 instanceable prim 创建 **Implicit Prototype**，存在 `/__Prototype1` 这样的隐藏路径下。所有实例共享这份数据。

### 8.5 Instance Proxy Prim

实例内部的 prim（如 `/World/Tree_0/Trunk`）"并不真正存在"——它们是 prototype 内容的"投影"。要访问它们，需要用 instance proxy：

```python
# 用 TraverseAll 这样可以访问实例内部
for prim in stage.TraverseAll():
    print(prim.GetPath(), prim.IsInstanceProxy())

# /World/Tree_0/Trunk 会以 instance proxy 形式出现
```

`prim.IsInstanceProxy()` 返回 True 表示这个 prim 是"实例投影"，对它的修改会被 USD 拒绝或特殊处理（因为修改实例内部等于修改 prototype，会影响所有实例）。

### 8.6 Point Instancer

当你需要**海量**实例（几万到几百万）时，Native Instance 的"每个实例一个 prim"开销太大。Point Instancer 用一个 prim + 几个数组就表示海量实例：

```python
import random
from pxr import Usd, UsdGeom, Vt

stage = Usd.Stage.CreateNew("F:/chapter8_point_instancer.usda")
UsdGeom.Xform.Define(stage, "/World")

# 先定义原型
proto = UsdGeom.Xform.Define(stage, "/World/RockTemplate")
UsdGeom.Mesh.Define(stage, "/World/RockTemplate/Mesh")

# 创建 PointInstancer
pi = UsdGeom.PointInstancer.Define(stage, "/World/RockField")

# 设置原型列表（可以多个）
pi.CreatePrototypesRel().SetTargets(["/World/RockTemplate"])

# 10000 个实例的位置
positions = Vt.Vec3fArray([(random.uniform(-100, 100), 
                             random.uniform(-100, 100), 
                             0) for _ in range(10000)])
pi.CreatePositionsAttr().Set(positions)

# 每个实例用哪个原型（这里是全部用 0 号原型）
proto_indices = Vt.IntArray([0] * 10000)
pi.CreateProtoIndicesAttr().Set(proto_indices)

stage.Save()
```

**优势**：
- 文件大小：Point Instancer 只存一个 prim + 3 个数组，远小于 10000 个 native instance
- 渲染性能：Hydra 渲染器对 Point Instancer 有专门优化
- 内存：实例数据紧凑存储

**劣势**：
- 不能像 native instance 那样单独修改某个实例的属性
- 适合"海量、同质"的场景（草地、森林、人群、碎片）

### 8.7 Globally vs Internally Refinable Instancing

这两个术语描述"实例能否在下游被修改"：

- **Globally Refinable**：实例在下游组装场景中仍能被"细化"（refine）——即下游可以覆盖实例内部某个属性。这通常通过 **inherits-instanceable pattern** 实现。
- **Internally Refinable**：实例不期望在下游被细化，所有修改只能在原型层面进行。

**何时用哪种？**
- 角色、车辆等"可能需要个性化"的资产 → Globally Refinable
- 草地、碎片等"无需个性化"的资产 → Internally Refinable

### 8.8 Inherits-instanceable Pattern

这是术语表里的一个高级模式：用 `inherits` arc 让 instanceable 资产在上下文中可编辑。

通俗版：
- 普通实例化：实例内部改不了
- Inherits-instanceable：实例"继承"一个 class，改 class 的属性 = 改所有实例，但每个实例也能通过 inherits 局部覆盖

这个模式在大型管线中用于"全局参数化 + 局部覆盖"。

### 8.9 Explicit Prototypes

通常 prototype 是 USD 隐式创建的（Implicit Prototypes）。但用户也可以显式创建 prototype，作为"编辑目标"——这样可以在不修改原资产的前提下，定义一组"覆盖意见"专门用于实例化。

### 8.10 实例化的性能对比实验

```python
# 文件：chapter8_perf_compare.py
import time, os

# 方式一：不用实例化，复制 1000 棵树
stage = Usd.Stage.CreateNew("F:/chapter8_no_instance.usda")
UsdGeom.Xform.Define(stage, "/World")
start = time.time()
for i in range(1000):
    UsdGeom.Mesh.Define(stage, f"/World/Tree_{i}")
stage.Save()
no_inst_size = os.path.getsize("F:/chapter8_no_instance.usda")

# 方式二：用实例化（复用前面生成的原型文件 chapter8_tree_proto.usda）
stage = Usd.Stage.CreateNew("F:/chapter8_with_instance.usda")
UsdGeom.Xform.Define(stage, "/World")
for i in range(1000):
    inst = UsdGeom.Xform.Define(stage, f"/World/Tree_{i}")
    inst.GetPrim().GetReferences().AddReference(
        "F:/chapter8_tree_proto.usda", "/Tree"
    )
    inst.GetPrim().SetInstanceable(True)
stage.Save()
inst_size = os.path.getsize("F:/chapter8_with_instance.usda")

print(f"Without instancing: {no_inst_size} bytes")
print(f"With instancing: {inst_size} bytes")
print(f"Ratio: {no_inst_size / inst_size:.2f}x smaller with instancing")
```

预期结果：实例化版本文件大小显著更小（具体倍数取决于 USD 版本和 Crate 格式压缩）。

### 8.11 源码锚点

- 实例化文档：`pxr/usd/usd/docs/instancing.md`
- PointInstancer Schema：`pxr/usd/usdGeom/pointInstancer.h`
- 实例化示例：`extras/usd/examples/`（搜索 instance 相关）
- 高级特性：`pxr/usd/usd/docs/advancedFeatures.md`

### 8.12 第 8 章练习

> **练习 8.1**：创建一个"停车场"场景，里面有 50 辆车（同一车型），用 native instance 实现。对比"不用实例化"和"用实例化"两种方式的文件大小。
>
> **练习 8.2**：用 Point Instancer 在一个 100x100 的平面上撒 5000 块石头（用 Sphere 代替），每个石头随机位置和随机缩放（用 `scalesAttr`）。用 usdview 查看效果。
>
> **练习 8.3**：创建一个带 instanceable prim 的 Stage，用 `stage.Traverse()` 和 `stage.TraverseAll()` 分别遍历，对比两者的输出差异。理解 instance proxy 的存在。
>
> **练习 8.4**：阅读 `pxr/usd/usd/docs/instancing.md`（用 `read` 工具打开），这是官方对实例化的完整说明。重点理解"Instance Editing"和"Refinable Instancing"两节。

---

## 模块四：资产管线模式

## 第 9 章：Asset & Asset Structure —— 可复用、可版本化的资产

### 9.1 定义（来自 Terms & Concepts）

> **Asset**：命名、版本化、结构化的资源容器（layer、纹理、体积等），被维护和复用。
>
> **Anchored Asset Path**：资产标识符可"锚定"到其包含 layer，赋能可重定位性和去重。
>
> **Asset Path Valued Field**：值为资产系统管理资源路径的 property 或 metadata。
>
> **Internal Resource**：版本在资产容器内与其他资源共享的资源，通常用"锚定"标识符表示。
>
> **External Resource**：版本独立于资产容器的资源，通常作为另一个资产的一部分被版本化。
>
> **Pipeline**：资产流经生产过程的流程。
>
> **Branch**：资产的一个并行流，有自己的版本集。
>
> **Fork**：资产的复制，用于引入破坏性/不兼容的变更。

### 9.2 核心类比：NPM 包

USD 的 Asset 概念非常类似 Node.js 生态的 NPM 包：

| NPM 包 | USD Asset |
|---|---|
| 包名（如 `react`） | Asset 名（如 `RobotAsset`） |
| 版本号（如 `18.2.0`） | Asset 版本 |
| `package.json` 描述依赖 | Asset 的 root layer 描述引用 |
| `node_modules/react/` 目录 | Asset 目录（含 .usda、贴图、子资产） |
| `import React from 'react'` | `AddReference("./robot.usda", "/Robot")` |
| 语义化版本（semver） | USD 版本约定 |
| `fork` 一个包做不兼容修改 | Fork（破坏性变更） |
| 长期维护多个 major 版本 | Branch（并行流） |

### 9.3 Asset 的结构

一个典型的 USD Asset 是一个目录：

```
robot_asset/
├── robot.usda              ← Asset 的 root layer（入口）
├── geometry/
│   ├── body.usda
│   └── head.usda
├── materials/
│   └── metal.usda
├── textures/
│   ├── body_diffuse.png
│   └── body_normal.png
└── thumbnail.usda          ← 预览图（Embedded Context 用途）
```

- `robot.usda` 是 **Asset Interface Layer**（见第 10 章），它是外部引用的入口
- 内部文件用 **anchored path**（相对路径）相互引用，保证整个 asset 可整体搬迁

### 9.4 Anchored Asset Path 详解

"锚定"路径是相对于**当前 layer 文件**的路径，而不是相对于"当前工作目录"或"全局路径"。

**为什么重要**：假设你在 `F:/assets/robot.usda` 里写 `@./textures/body.png@`，这个 `./` 是相对于 `robot.usda` 所在目录的。如果你把整个 `robot_asset/` 目录移动到 `G:/myassets/robot/`，所有内部引用依然有效——因为它们是"锚定"在各自 layer 上的相对路径。

```
# 在 robot.usda 中（绝对路径，脆弱 ❌）
def "Robot" {
    references = @F:/assets/robot/geometry/body.usda@
}

# 在 robot.usda 中（锚定路径，稳健 ✅）
def "Robot" {
    references = @./geometry/body.usda@
}
```

USD 的 Asset Resolver（见第 11 章）会把这些"锚定"路径解析成实际文件路径。

### 9.5 Internal vs External Resource

- **Internal Resource**：资产内部的资源，版本与资产一起管理。如 `robot_asset/textures/body.png` 属于 robot asset。
- **External Resource**：引用的外部资产，独立版本化。如 robot asset 引用了 `shared_materials/metal.usda`，后者是另一个 asset。

区分意义：版本管理时，internal resource 随 asset 一起版本化；external resource 需要单独管理其版本兼容性。

### 9.6 Pipeline、Branch、Fork

这三个术语描述资产在时间维度上的演进：

| 术语 | 含义 | 类比 |
|---|---|---|
| **Pipeline** | 资产在生产流程中的流转 | 工厂流水线 |
| **Branch** | 同一资产的并行版本流（如 v2 和 v3 同时维护） | Git branch |
| **Fork** | 复制资产以引入破坏性变更 | Git fork（但语义更接近"分家"） |

**场景**：
- `Robot v1` 用了 2 年，稳定
- 新需求要大改架构，但不能影响现有项目 → **Fork** 出 `RobotNextGen`
- `Robot v1` 继续修 bug 但不加新功能，同时 `Robot v2` 开发新功能 → 两个 **Branch** 并行
- `Robot v1` → modeling → rigging → animation → rendering → 这是 **Pipeline** 流转

### 9.7 Asset Parameterization

术语表里的概念：**Variant Set + Primvar**，让同一资产支持下游变化。

例如一个机器人资产：
- VariantSet "color"：red/blue/green
- Primvar "team_id"：下游可以指定队伍编号
- VariantSet "damage_level"：pristine/damaged/destroyed

下游用户 reference 这个资产时，只需选择 variant 和设置 primvar，就能得到不同配置的机器人——无需修改资产本身。

### 9.8 Session Artifact

定义里提到："不超越会话长度的场景或数据"。

通俗版：Session Artifact 是**临时数据**，关闭程序就丢失。典型例子是 usdview 里你临时调的属性（存在 session layer 中）——不保存到磁盘，下次打开还是原样。

### 9.9 源码锚点

- 资产结构示例：`extras/usd/examples/usdMakeFileVariantModelAsset/`
- 资产解析器示例：`extras/usd/examples/usdResolverExample/`
- 资产最佳实践：参考 NVIDIA 的 [Principles of Scalable Asset Structure](https://docs.omniverse.nvidia.com/usd/latest/learn-openusd/independent/asset-structure-principles.html)

### 9.10 第 9 章练习

> **练习 9.1**：构建一个简单的 asset 目录 `my_asset/`，包含 `my_asset.usda`（root layer）、`geometry.usda`（几何）、`material.usda`（材质）。root layer 用 anchored path 引用内部文件。把整个目录移动到另一个位置，确认 USD 仍能正确打开。
>
> **练习 9.2**：在 `my_asset.usda` 里给 root prim 添加一个 VariantSet "quality"（high/low），high 引用高精度几何，low 引用低精度几何。这就是一个最简单的 parameterized asset。
>
> **练习 9.3**：用 `usdcat --flatten my_asset.usda` 查看合成后的完整 Stage，理解 asset 内部如何被"展开"。对比不 flatten 的 `usdcat my_asset.usda` 输出。

---

## 第 10 章：Reference-Payload Pattern & Lofting —— 资产管线的核心模式

### 10.1 定义（来自 Terms & Concepts）

> **Reference-payload Pattern**：prim 层级被拆分为——轻量、重要的场景描述用 "reference"，内部内容放在 "payload" 后。
>
> **Lofting**：把少量数据从 payload 中"抬升"到外层 reference，使 variant、inherits 等重要字段在不加载 payload 时也可见。
>
> **Asset Interface Layer**：预期被打开或引用的 root layer，含一个或多个 entrypoint prim 和 lofted 属性。常用 "reference-payload" 模式。
>
> **Entrypoint Prim**：用于检查和引用到下游上下文的主要 prim。
>
> **Asset Prim Interface**：为下游覆盖维护的稳定 prim 集合。
>
> **Aggregate Model Structure**：只含引用和高层资产 prim 接口编辑的 assembly 模型。
>
> **Atomic Model Structure**：依赖完全封装的 component 模型。
>
> **Package Model Structure**：含一个或多个内部 primary component、可能引用外部 component 的 assembly 模型。作为嵌套 component 为 subcomponent 的替代方案。
>
> **Selector Model Structure**：唯一功能是在一组相关资产间做 variant 切换的 component 或 assembly。
>
> **Embedded Context**：非 entrypoint 但对预览和缩略图生成有用的 asset 接口 prim。
>
> **Access Semantics**：USD 中任何字段都可被覆盖。预期"内部"的 prim 或 variant set 必须用语义（如 `_` 前缀）传达可编辑性预期。
>
> **Encapsulation**：USD 中指场景层级的包含性，确保层级分支中的 relationship 和 binding 不指向外部目标。
>
> **De-duplication**：自动检测和消除重复数据以优化存储和性能的过程。

### 10.2 核心模式：Reference-Payload Pattern

这是 USD 资产管线的**核心设计模式**，几乎所有工业级资产都采用它。理解它就理解了 Isaac Sim SimReady 资产的底层结构。

#### 10.2.1 问题：大资产的加载困境

假设你有一个 500MB 的机器人资产。下游场景只 reference 它一次还好，但如果一个工厂场景要 reference 100 个机器人，那就是 50GB——打开 Stage 要几分钟，内存爆炸。

#### 10.2.2 解法：拆分"轻量接口"和"重型内容"

把资产拆成两部分：

1. **轻量接口（Reference 层）**：只包含 prim 的"骨架"——路径、kind、variant set 定义、关键 metadata。可能只有几 KB。
2. **重型内容（Payload）**：实际的几何、材质、动画数据。几百 MB。

下游 reference 时只引用**轻量接口**，默认不加载 payload。需要看具体某个机器人时，再 load 它的 payload。

#### 10.2.3 结构示意

```
robot.usda (Asset Interface Layer, 轻量)
├── def "Robot" (entrypoint prim)
│   ├── kind = "component"
│   ├── variantSet "color" = ["red", "blue"]    ← lofted
│   ├── variantSet "lod" = ["high", "low"]       ← lofted
│   ├── references = @./robot_payload.usda@      ← 引用 payload
│   └── payload = @./robot_payload.usda@         ← 或用 payload arc
│
robot_payload.usda (重型内容)
├── def "Robot"
│   ├── def "Body" (Mesh, 几百 MB)
│   ├── def "Head" (Mesh)
│   └── def "Materials" (材质网络)
```

### 10.3 核心类比：图书馆卡片目录

这个模式完美类比传统图书馆：

| 图书馆 | USD 资产 |
|---|---|
| **卡片目录**（书名、作者、ISBN、摘要，几行字） | **Reference 层**（prim 路径、kind、variant 定义，几 KB） |
| **书架上的书**（实体，几百页） | **Payload**（实际几何/材质数据，几百 MB） |
| 查卡片目录找书 | 打开 Stage，浏览 prim 树（不加载 payload） |
| 去书架取书 | `prim.Load()` 加载 payload |
| 卡片上的"摘要" | **Lofted 属性**（从 payload 抬升上来的关键信息） |

**Lofting 的关键**：卡片目录上有书的摘要——你不必取下书就知道大概内容。同理，lofting 把 payload 里的关键属性（如 variant 定义、bounding box、thumbnail）"抬升"到 reference 层，让你不加载 payload 就能看到这些信息。

### 10.4 实现 Reference-Payload Pattern

```python
# 文件：chapter10_ref_payload.py
from pxr import Usd, UsdGeom, Sdf

# ===== 1. 创建 payload layer（重型内容） =====
payload_stage = Usd.Stage.CreateNew("F:/chapter10_robot_payload.usda")
robot_payload = UsdGeom.Xform.Define(payload_stage, "/Robot")
UsdGeom.Mesh.Define(payload_stage, "/Robot/Body")
UsdGeom.Mesh.Define(payload_stage, "/Robot/Head")
payload_stage.Save()

# ===== 2. 创建 asset interface layer（轻量接口） =====
interface_stage = Usd.Stage.CreateNew("F:/chapter10_robot.usda")
robot = UsdGeom.Xform.Define(interface_stage, "/Robot")

# 设置 kind（这是 lofted metadata）
from pxr import UsdModelAPI
UsdModelAPI(robot).SetKind("component")

# 添加 VariantSet（这是 lofted 的——不加载 payload 也能看到）
vsets = robot.GetVariantSets()
color_vset = vsets.AddVariantSet("color")
color_vset.AddVariant("red")
color_vset.AddVariant("blue")
color_vset.SetVariantSelection("red")

# 添加 payload（延迟加载重型内容）
robot.GetPrim().GetPayloads().AddPayload(
    "F:/chapter10_robot_payload.usda", "/Robot"
)

interface_stage.Save()

# ===== 3. 测试：打开 interface layer，不加载 payload =====
stage = Usd.Stage.Open("F:/chapter10_robot.usda", Usd.Stage.LoadNone)
robot_prim = stage.GetPrimAtPath("/Robot")
print(f"Kind: {UsdModelAPI(robot_prim).GetKind()}")          # component
print(f"Variants: {robot_prim.GetVariantSets().GetNames()}")  # ['color']
print(f"Children count: {len(robot_prim.GetChildren())}")    # 0（payload 未加载）
body_child = robot_prim.GetChild("Body")
print(f"Has Body child: {body_child.IsValid()}")             # False（payload 未加载）

# ===== 4. 加载 payload =====
robot_prim.Load()
print(f"After load, Children: {[c.GetPath() for c in robot_prim.GetChildren()]}")
# ['/Robot/Body', '/Robot/Head']
```

**关键观察**：不加载 payload 时，你仍然能看到 kind、variant set 定义——这些就是 lofted 信息。加载 payload 后，Body 和 Head 才出现。

### 10.5 Lofting 详解

Lofting 的本质是：**把 payload 内部的关键 metadata 复制/移动到 reference 层**。

哪些东西通常 lofted？
- `kind`（model hierarchy 需要）
- VariantSet 定义和默认选择
- `inherits` 声明
- Bounding box（用于剔除）
- Thumbnail / preview 信息
- `instanceable` 标记

**为什么 lofting 重要？**
- 下游组装场景时，需要遍历 model hierarchy 来决定加载哪些资产——这要求不加载 payload 就能看到 kind
- VariantSet 选择需要在 payload 加载前就确定（否则没法决定加载哪个 variant 的 payload）
- Bounding box 让渲染器在不加载几何时就能做视锥剔除

### 10.6 Asset Interface Layer & Entrypoint Prim

- **Asset Interface Layer**：就是上面 `robot.usda` 这样的 root layer，是外部引用的入口
- **Entrypoint Prim**：interface layer 里的"主 prim"，通常是 `/Robot` 这样的顶层 prim，下游 reference 它来引入整个资产
- **Asset Prim Interface**：asset 维护的"稳定 prim 集合"——下游可以依赖这些 prim 路径做覆盖。如果 asset 内部重构但保持了 prim interface，下游不受影响

### 10.7 Embedded Context

定义里："非 entrypoint 但对预览和缩略图生成有用的 asset 接口 prim"。

例如一个机器人 asset，除了主 entrypoint `/Robot`，还可能有：
- `/Robot_Preview`：专门用于生成缩略图的简化版
- `/Robot_Thumbnail`：一张静态预览图

这些不是主入口，但对资产浏览器（如 usdview 的 Asset 模式、Omniverse 的 Asset Browser）有用。

### 10.8 三种 Model Structure 模式

定义里提到三种资产结构模式：

#### 10.8.1 Atomic Model Structure（原子结构）
- 一个 component，依赖完全封装
- 最简单的结构：一个 self-contained 的资产
- 例：一个独立的螺丝钉资产

#### 10.8.2 Aggregate Model Structure（聚合结构）
- 一个 assembly，只含引用和高层接口编辑
- 不直接含几何，而是 reference 多个 component
- 例：一个房间 assembly，引用了桌椅、灯具等 component

#### 10.8.3 Package Model Structure（打包结构）
- 一个 assembly，含内部 primary component + 可能的外部 component 引用
- 介于 atomic 和 aggregate 之间
- 作为"嵌套 component 为 subcomponent"的替代方案
- 例：一个汽车 asset，内部含发动机 component（自包含），同时引用外部轮胎 component

#### 10.8.4 Selector Model Structure（选择器结构）
- 唯一功能是用 variant 在一组相关资产间切换
- 例：一个 `CarSelector` asset，variant 有 "sedan"/"suv"/"truck"，每个 variant reference 不同的车资产

### 10.9 Access Semantics & Encapsulation

- **Access Semantics**：USD 任何字段都可被覆盖。约定俗成的"内部"标记是用 `_` 前缀（如 `/_InternalConfig`），表示"不期望下游覆盖"
- **Encapsulation**：层级分支内的 relationship 不应指向外部目标——保持"封装性"。例如 `/World/Room/Table` 的 relationship 不应该指向 `/World/OtherRoom/Chair`

### 10.10 De-duplication

USD 合成引擎会自动检测相同的 reference/payload 并去重——如果 100 个 prim 都 reference 同一个 asset，USD 内部只加载一份。这是实例化的隐式 benefit。

### 10.11 与 Isaac Sim SimReady 的关系

Isaac Sim 的 **SimReady** 资产就是严格按照 Reference-Payload Pattern 构建的：

- 每个 SimReady 资产是一个目录，含 interface layer + payload layer
- VariantSet 暴露"配置"（如机器人颜色、传感器配置）
- Payload 含实际几何 + 物理属性（usdPhysics）
- Lofted 信息包括 bounding box、语义标签（usdSemantics）

学懂这一章，你就能直接读懂 SimReady 资产的结构。

### 10.12 源码锚点

- 端到端教程：`extras/usd/tutorials/endToEnd/`（最完整的资产构建示例）
- 递归 payload 示例：`extras/usd/examples/usdRecursivePayloadsExample/`
- 资产生成示例：`extras/usd/examples/usdMakeFileVariantModelAsset/`
- NVIDIA 资产结构原则：[Principles of Scalable Asset Structure](https://docs.omniverse.nvidia.com/usd/latest/learn-openusd/independent/asset-structure-principles.html)

### 10.13 第 10 章练习

> **练习 10.1**：按 10.4 节的代码实现一个简单的 reference-payload 资产。用 `Usd.Stage.LoadNone` 打开，确认不加载 payload 时能看到 kind 和 variant；加载后能看到子 prim。
>
> **练习 10.2**：在 payload 里添加一个 VariantSet "damage"（pristine/damaged），然后通过 lofting 把这个 variant 定义也搬到 interface layer（即在 interface layer 也声明同名 variant set）。验证不加载 payload 时能看到 damage variant。
>
> **练习 10.3**：创建一个 Aggregate Model Structure 的 assembly：`/World/Room`（assembly）reference 了 `/Table`（component）和 `/Chair`（component）两个外部资产。用 usdview 查看合成结果。
>
> **练习 10.4**：阅读 `extras/usd/tutorials/endToEnd/` 目录下的脚本和 .usda 文件，这是官方最完整的资产管线示例。重点看它如何分层组织 Ball/Table/Shot 三个资产。

---

## 第 11 章：Composition Target & Resolver —— 资产定位的"DNS"

### 11.1 定义（来自 Terms & Concepts）

> **Composition Target**：被 composition arc 指向的 prim（或 layer）。例如被 reference 到另一个 prim 上的 prim。通常是 Layer identifier + Sdf.Path 或两者之一。
>
> **Mirroring Resolver**：贪婪地本地化整个资源（layer、纹理、体积场）的解析器。Mirroring resolver 有时需要额外的 payload 或 variant set 来避免同步。

### 11.2 Composition Target 详解

每个 composition arc（reference/payload/inherit/specialize）都有一个"目标"——它指向哪里。

```python
# 查看一个 prim 的所有 reference 的 target
robot_prim = stage.GetPrimAtPath("/World/Robot")
refs = robot_prim.GetMetadata("references")
print(refs)  # 类似 [Sdf.Reference('robot.usda', '/Robot')]
```

Composition Target 由两部分组成：
1. **Layer identifier**：目标 layer 的"标识符"（通常是文件路径，但也可以是自定义格式）
2. **Sdf.Path**：目标 layer 内的 prim 路径

这两者的组合唯一确定一个 composition target。

### 11.3 核心类比：DNS 系统

Asset Resolver 在 USD 中的角色，非常类似互联网的 DNS：

| DNS | USD Asset Resolver |
|---|---|
| 域名（如 `google.com`） | Asset path（如 `@robot@` 或 `./robot.usda`） |
| DNS 服务器解析成 IP | Resolver 把 asset path 解析成实际文件路径 |
| 全球域名系统 | Asset Repository（资产仓库） |
| 本地 hosts 文件覆盖 | 本地 resolver 配置覆盖 |
| CDN 缓存 | Mirroring Resolver 的本地化缓存 |

**关键**：USD 里你写的 asset path 不一定是文件系统路径——它是一个"标识符"，由 Resolver 决定如何解析。这让 USD 可以支持各种资产管理系统（本地文件、HTTP、数据库、Omniverse Nucleus 等）。

### 11.4 Asset Resolver 的工作原理

```
你写的代码：
    robot_prim.GetReferences().AddReference("@robot@", "/Robot")
                                        ↑
                                  asset path（标识符）

Resolver 解析：
    @robot@  →  F:/assets/robot/robot.usda   （文件系统 resolver）
    @robot@  →  omniverse://nucleus/assets/robot.usda  （Omniverse resolver）
    @robot@  →  https://cdn.example.com/robot.usda     （HTTP resolver）
```

Resolver 是一个**插件**，通过 `plugInfo.json` 注册。不同的项目可以有不同的 resolver。

### 11.5 默认 Resolver

USD 自带一个默认的文件系统 resolver，它处理两种路径：

1. **绝对路径**：`@F:/assets/robot.usda@` —— 直接按文件系统路径解析
2. **相对路径（anchored）**：`@./geometry/body.usda@` —— 相对于当前 layer 文件所在目录

默认 resolver 满足大部分本地开发需求，但生产环境通常需要自定义 resolver 来支持：
- 资产版本管理（`@robot@` → `robot_v3.usda`）
- 分布式资产仓库（Omniverse Nucleus）
- 缓存与镜像

### 11.6 Mirroring Resolver

定义里提到的 "Mirroring Resolver"：一种贪婪地本地化整个资源的 resolver。

通俗版：
- 普通 resolver：解析路径时只返回一个"指针"，数据按需读取
- Mirroring resolver：解析路径时把整个资源（layer/纹理/体积）复制到本地缓存，后续读取都从本地走

**为什么需要 mirroring？**
- 远程资产（如 Omniverse Nucleus 上的资产）读取慢
- 一次本地化，多次读取快
- 离线工作支持

**代价**：本地化可能很慢（大资产），且需要处理同步问题。定义里提到"mirroring resolver 有时需要额外的 payload 或 variant set 来避免同步"——意思是你可以用 payload 延迟本地化，或用 variant 在"本地版本"和"远程版本"间切换。

### 11.7 自定义 Resolver

USD 提供了 `pxr/usd/ar/` 模块（Asset Resolver 框架），你可以实现自己的 resolver：

```cpp
// 简化的 C++ 伪代码
class MyResolver : public ArResolver {
    std::string Resolve(const std::string& assetPath) override {
        // 把 @robot@ 解析成实际路径
        if (assetPath == "@robot@") {
            return "F:/assets/robot/robot.usda";
        }
        // ... 其他规则
    }
};
```

注册到 `plugInfo.json`：
```json
{
    "Plugins": [{
        "Name": "myResolver",
        "Type": "resource",
        "Path": "myResolver.plugin",
        "Info": {
            "Types": {
                "MyResolver": { "bases": ["ArResolver"] }
            }
        }
    }]
}
```

### 11.8 源码锚点

- Resolver 框架源码：`pxr/usd/ar/`（特别是 `ar/resolver.h`）
- Resolver 示例：`extras/usd/examples/usdResolverExample/`（完整可运行的自定义 resolver）
- 文件格式插件示例：`extras/usd/examples/usdObj/`（OBJ 文件格式插件）
- 动态文件格式示例：`extras/usd/examples/usdDancingCubesExample/`
- 动态文件格式文档：`pxr/usd/usd/docs/dynamicFileFormat.md`

### 11.9 第 11 章练习

> **练习 11.1**：阅读 `extras/usd/examples/usdResolverExample/` 目录的 `README.md`（或主要源文件），理解它实现了一个什么样的自定义 resolver。这是理解 resolver 插件机制的最佳入口。
>
> **练习 11.2**：用默认 resolver，创建两个 asset：`asset_a.usda`（reference `./asset_b.usda`）和 `asset_b.usda`。把两个文件放在同一目录，确认 anchored path 能正确解析。然后只移动 `asset_a.usda` 到另一个目录，观察报错（因为 `asset_b.usda` 找不到了）。
>
> **练习 11.3**：用 `stage.GetRootLayer().resolverContext` 查看当前 Stage 的 resolver context（可能返回空或 context 对象）。理解 resolver context 是 resolver 用来缓存解析结果的环境。
>
> **练习 11.4**：阅读 `pxr/usd/ar/README.md` 或 `pxr/usd/ar/doxygen/` 下的文档（如果存在），理解 ArResolver 的 API 设计。

---

## 模块五：工具链与生态

## 第 12 章：工具链总览 & 通向下游的桥梁

### 12.1 USD 命令行工具速查

USD 自带一系列命令行工具，日常工作中每天都在用：

| 工具 | 作用 | 常用示例 |
|---|---|---|
| `usdview` | 图形化查看器 | `usdview robot.usda` |
| `usdcat` | 查看/转换 USD 文件 | `usdcat robot.usda`，`usdcat robot.usdc -o robot.usda` |
| `usdtree` | 查看 prim 层级树 | `usdtree robot.usda`（默认只显示 model hierarchy） |
| `usddiff` | 比较两个 USD 文件 | `usddiff a.usda b.usda` |
| `usdedit` | 编辑 USDA 文件 | `usdedit robot.usda`（打开编辑器） |
| `usdchecker` | 验证 USD 文件合规性 | `usdchecker robot.usda` |
| `usdrecord` | 渲染 USD 到图片 | `usdrecord robot.usda out.png` |
| `usdzip` | 打包成 .usdz | `usdzip robot.usdz robot.usda textures/` |
| `usdcat --flatten` | 展开合成结果 | `usdcat --flatten robot.usda` |

**必会的 3 个**：`usdview`、`usdcat`、`usdtree`——日常调试三板斧。

### 12.2 usdview 深入

usdview 是你学习 USD 最重要的工具。关键面板：

| 面板 | 作用 |
|---|---|
| **Stage Tree** | 左侧的 prim 层级树 |
| **Viewport** | 中间的 3D 渲染窗口（Hydra Storm） |
| **Properties** | 右侧选中 prim 的属性 |
| **Composition** | 属性面板的子标签，显示合成来源（哪些 layer 贡献了什么） |
| **Layer Stack** | 显示当前 Stage 的所有 layer |
| **Timeline** | 底部时间轴，播放动画 |
| **Meta Data** | prim 的 metadata |

**学习技巧**：每学一个概念，都用 usdview 打开对应文件，在 Composition 面板观察"合成来源"——这是理解 Layer/Arc/Variant 的最佳方式。

### 12.3 Hydra 渲染框架简介

Hydra（Hd）是 USD 的渲染框架，采用"可插拔渲染委托"架构：

```
USD Stage
    │
    ▼
Scene Index（场景索引，prim → 渲染图元）
    │
    ▼
Render Delegate（渲染委托）  ← 可插拔
    ├── HdStorm      （OpenGL 光栅化，usdview 默认）
    ├── HdEmbree     （CPU 光线追踪）
    ├── HdRtProc     （RenderMan）
    └── ...           （第三方可扩展，如 Omniverse RTX）
```

**核心思想**：USD 场景数据与具体渲染器解耦。同一个 USD Stage 可以喂给不同渲染器，只需切换 Render Delegate。

**对下游学习的意义**：
- Omniverse 的 RTX 渲染器是一个 Hydra Render Delegate（扩展形式）
- Isaac Sim 的渲染也基于 Hydra 架构
- 学懂 Hydra，就懂了"USD 如何被渲染"

### 12.4 领域 Schema 概览

USD 通过 Schema 扩展领域语义。你已经接触过 UsdGeom，还有这些常用领域：

| Schema | 领域 | 典型用途 |
|---|---|---|
| `UsdGeom` | 几何 | Mesh/Sphere/Camera/Xform |
| `UsdShade` | 材质 | Material/Shader/材质绑定 |
| `UsdLux` | 光照 | DistantLight/SphereLight/灯光过滤器 |
| `UsdSkel` | 骨骼 | 骨骼绑定/蒙皮动画 |
| `UsdPhysics` | 物理 | 刚体/碰撞体/约束 |
| `UsdRender` | 渲染设置 | 渲染pass/输出设置 |
| `UsdMedia` | 媒体 | 音频/视频纹理 |
| `UsdVol` | 体积 | 体积场/粒子 |
| `UsdUI` | UI | 场景浏览器的 UI 提示 |
| `UsdSemantics` | 语义 | 实例语义标注（AI/仿真用） |
| `UsdLod` | LOD | 细节层次 |
| `UsdProc` | 程序化 | 程序化生成 |

**对下游学习的关键 Schema**：
- **Newton 物理引擎** → `UsdPhysics`（刚体、碰撞、约束）
- **Isaac Sim** → `UsdPhysics` + `UsdSemantics`（语义标注用于机器人感知）
- **IsaacLab** → `UsdSemantics`（强化学习环境的语义分类）

### 12.5 通向下游的路线图

学完本指南后，你可以这样衔接下游平台：

#### 12.5.1 通向 Omniverse

- **Omniverse = USD + 实时协作 + RTX 渲染**
- 你已掌握的 USD 概念直接适用
- 新增概念：
  - **Nucleus**：协作服务器，托管 USD Stage，多人实时编辑
  - **MDL**（Material Definition Language）：NVIDIA 的材质语言，扩展 UsdShade
  - **Kit**：Omniverse 的应用框架，基于 USD + Python
  - **Extension**：Omniverse 的插件机制
- 入口：[Omniverse Documentation](https://docs.omniverse.nvidia.com/)

#### 12.5.2 通向 Isaac Sim

- **Isaac Sim = Omniverse + 机器人仿真**
- 基于 USD 场景 + UsdPhysics + 机器人专用扩展
- 关键 USD Schema：
  - `UsdPhysics`：关节、碰撞、刚体
  - `UsdSemantics`：机器人感知的语义标注
  - `UsdArticulation`：运动链（机器人关节链）
- SimReady 资产：严格按照本指南第 10 章的 Reference-Payload Pattern 构建
- 入口：[Isaac Sim Documentation](https://docs.omniverse.nvidia.com/isaacsim/)

#### 12.5.3 通向 Newton 物理引擎

- **Newton = NVIDIA + Google DeepMind 的下一代物理引擎**
- 基于 USD 作为场景格式
- 核心依赖：`UsdPhysics` Schema
- 你需要深入理解：
  - UsdPhysics 的刚体/柔体/碰撞/约束
  - 时间采样（第 5 章）—— 物理仿真需要帧步进
  - Payload 延迟加载（第 10 章）—— 大型仿真场景优化

#### 12.5.4 通向 IsaacLab

- **IsaacLab = Isaac Sim + 强化学习框架**
- 环境是 USD 场景，机器人是 USD 资产
- 关键 USD 能力：
  - 程序化生成场景（Python API 创作大量变体环境）
  - 语义标注（UsdSemantics）用于 reward 计算
  - VariantSet 用于环境参数化（不同难度、不同布局）
  - Instancing（第 8 章）用于海量环境并行

### 12.6 源码锚点

- 命令行工具：`pxr/usd/bin/`（usdcat/usdtree/usddiff/usdedit 等）
- usdview 源码：`pxr/usdImaging/usdviewq/`
- Hydra 核心：`pxr/imaging/hd/`
- Hydra 入门指南：`extras/imaging/docs/hydra_getting_started_guide.dox`
- 最小 Hydra 委托示例：`extras/imaging/examples/hdTiny/`
- Schema 列表：`pxr/usd/`（每个 usd* 子目录是一个 schema 模块）

### 12.7 第 12 章练习

> **练习 12.1**：用 `usdcat` 查看 `extras/usd/tutorials/convertingLayerFormats/Sphere.usda`，理解 USDA 文本格式。然后用 `usdcat Sphere.usda -o Sphere.usdc` 转成二进制，对比文件大小。
>
> **练习 12.2**：用 `usdtree` 查看一个多 prim 的 Stage（如你前面章节创建的），对比加 `--full` 参数（显示全部 prim）和不加（只显示 model hierarchy）的差异。
>
> **练习 12.3**：用 `usdrecord` 把一个 USD 文件渲染成 PNG 图片。命令示例：`usdrecord --camera /World/Camera --resolution 800,600 robot.usda out.png`（需先创建一个带 camera 的 stage）。
>
> **练习 12.4**：阅读 `extras/imaging/examples/hdTiny/` 目录的源码（这是最小 Hydra 渲染委托），理解 Hydra 的 Render Delegate 架构。即使看不懂 C++ 细节，也要理解"它实现了哪些接口"。
>
> **练习 12.5（综合）**：用本指南学到的所有知识，构建一个完整的"机器人车间"资产：
> - 用 Reference-Payload Pattern 组织（第 10 章）
> - 含一个 VariantSet "robot_color"（第 6 章）
> - 用 instancing 创建 10 个机器人实例（第 8 章）
> - 标注 kind 为 assembly/component（第 7 章）
> - 添加 UsdPhysics 属性（刚体碰撞）（第 12.4 节）
> - 用 usdview 查看最终效果
>
> 这是本指南的毕业项目。完成后，你已经具备阅读和创作工业级 USD 资产的能力。

---

## 附录 A：源码库地图

以下是 `F:\newton\OpenUSD` 源码库的关键目录结构，供学习时按图索骥：

### A.1 顶层目录

```
OpenUSD/
├── build_scripts/build_usd.py    ← 一键编译脚本
├── docs/                         ← 用户文档（Sphinx + Doxygen）
├── extras/                       ← 教程与示例
│   ├── usd/tutorials/            ← 9 个实战教程
│   ├── usd/examples/             ← 12 个示例项目
│   ├── imaging/examples/         ← 3 个 Hydra 示例
│   └── exec/examples/            ← 3 个 OpenExec 示例
├── pxr/                          ← 核心源码
│   ├── base/                     ← 基础库（gf/tf/vt/plug...）
│   ├── usd/                      ← USD 核心（sdf/pcp/usd/usdGeom...）
│   ├── imaging/                  ← Hydra 渲染框架
│   ├── usdImaging/               ← USD ↔ Hydra 桥接 + usdview
│   ├── exec/                     ← OpenExec 执行引擎
│   └── usdValidation/            ← 验证框架
├── third_party/                  ← Houdini/Katana/Maya/RenderMan 集成
├── README.md / BUILDING.md / CHANGELOG.md / VERSIONS.md
└── LICENSE.txt (Apache 2.0)
```

### A.2 学习高频路径

| 你想学 | 去哪里看 |
|---|---|
| 概念文档 | `pxr/usd/usd/docs/*.md`（14 篇核心文档） |
| 教程源码 | `extras/usd/tutorials/<name>/` |
| 完整示例 | `extras/usd/examples/<name>/` |
| Schema 用法 | `pxr/usd/usdGeom/docs/`、`pxr/usd/usdShade/docs/` 等 |
| Hydra 渲染 | `extras/imaging/docs/`、`extras/imaging/examples/hdTiny/` |
| 命令行工具 | `pxr/usd/bin/`、`pxr/usdImaging/bin/` |
| C++ API | `pxr/usd/usd/stage.h`、`pxr/usd/usd/prim.h` 等 |
| 合成引擎内部 | `pxr/usd/pcp/`（高级） |

### A.3 推荐阅读顺序（源码文档）

1. `pxr/usd/usd/docs/front.md` — USD 总览
2. `pxr/usd/usd/docs/objectModel.md` — 对象模型
3. `pxr/usd/usd/docs/propertiesOfSceneDescription.md` — 属性
4. `pxr/usd/usd/docs/authoringEditing.md` — 创作与编辑
5. `pxr/usd/usd/docs/instancing.md` — 实例化
6. `pxr/usd/usd/docs/advancedFeatures.md` — 高级特性
7. `pxr/usd/usd/docs/bestPractices.md` — 最佳实践

---

## 结语

恭喜你学完本指南！你现在掌握了：

- ✅ USD 的核心心智模型（Layer 合成哲学）
- ✅ Stage / Prim / Layer / Property 等核心数据模型
- ✅ Composition Arcs（含 LIVRPS 强度次序）
- ✅ Variant Set 与资产参数化
- ✅ Model Kind 与资产层级组织
- ✅ Instancing（Native + Point Instancer）
- ✅ Reference-Payload Pattern 与 Lofting（工业级资产模式）
- ✅ Asset Resolver 与资产定位
- ✅ 工具链使用（usdview/usdcat/usdtree...）
- ✅ Hydra 渲染框架与领域 Schema
- ✅ 通向 Omniverse / Isaac Sim / Newton / IsaacLab 的路线

**下一步建议**：
1. 完成第 12 章的毕业项目（练习 12.5）
2. 通读 `pxr/usd/usd/docs/` 下的官方文档，加深理解
3. 选一个下游平台（推荐 Isaac Sim）开始实践
4. 遇到具体问题时，回到本指南对应章节查阅

祝你学习顺利，在 USD 的世界里玩得开心！

---

## 附录 B：术语速查表（按本指南章节排序）

| 术语 | 章节 | 一句话解释 |
|---|---|---|
| OpenUSD | 0 | Pixar 开发的 3D 场景描述框架 |
| Stage | 1 | 已合成场景的运行时实例 |
| Layer | 1, 3 | 一个 .usda 文件，一份"意见" |
| Prim | 2 | 场景的基本节点/积木 |
| Scene Graph | 2 | Prim 的树形命名空间 |
| Pseudo-Root Prim | 2 | 强制存在的虚拟根 prim `/` |
| Abstract Prims | 2 | class 声明的 prim，不渲染，供继承 |
| Layer Stack | 3 | 多个 Layer 的有序叠加 |
| Sublayer | 3, 4 | Layer 级的合成（叠加意见） |
| Composition | 4 | 把多源场景图合成最终场景的过程 |
| Composition Arcs | 4 | 6 种合成机制（Sublayer/Ref/Payload/Inherit/Specialize/VariantSet） |
| Composition Target | 4, 11 | Arc 指向的目标（Layer ID + Path） |
| Reference | 4 | 引用外部资产到当前 prim 下 |
| Payload | 4 | 延迟加载的 Reference |
| Inherits | 4 | 继承 class prim 的模板 |
| Specializes | 4 | 弱化的 inherits（fallback 行为） |
| Property | 5 | Prim 上的命名数据字段 |
| Attribute | 5 | 有值的 Property（可时间采样） |
| Relationship | 5 | 指向其他 Prim 的引用 |
| Primvar | 5 | 渲染器读取的额外数据通道 |
| Variant Set | 6 | Prim 的"配置开关"集合 |
| Model Kind | 7 | 标记 Prim 在 model hierarchy 中角色的 metadata |
| Model Hierarchy | 7 | 用 kind 组织的模型层级 |
| Shallowness | 7 | Model hierarchy 应浅不应深的原则 |
| Completeness | 7 | Component/Assembly 应开箱即用的原则 |
| Component Model Boundary | 7 | Model hierarchy 与 prim hierarchy 的边界 |
| Instancing | 8 | 创建共享数据的多个实例 |
| Instanceable | 8 | Prim 的可实例化标记 |
| Native Instance | 8 | Instanceable prim（区别于 Point Instancer） |
| Prototype | 8 | 被实例化的中心副本 |
| Implicit Prototypes | 8 | USD 自动创建的 prototype |
| Explicit Prototypes | 8 | 用户显式创建的 prototype |
| Point Instancer | 8 | 海量实例的高效表示 |
| Instance Proxy Prim | 8 | 访问实例内部内容的占位符 prim |
| Globally Refinable Instancing | 8 | 下游可细化的实例化 |
| Internally Refinable Instancing | 8 | 下游不可细化的实例化 |
| Inherits-instanceable Pattern | 8 | 用 inherits 让 instanceable 可在上下文编辑 |
| Asset | 9 | 命名、版本化、结构化的资源容器 |
| Anchored Asset Path | 9 | 锚定到 layer 的相对路径 |
| Asset Path Valued Field | 9 | 值为资产路径的 property/metadata |
| Internal Resource | 9 | 资产内部的资源 |
| External Resource | 9 | 资产外部的独立版本化资源 |
| Pipeline | 9 | 资产在生产流程中的流转 |
| Branch | 9 | 资产的并行版本流 |
| Fork | 9 | 资产的破坏性复制 |
| Asset Parameterization | 9 | VariantSet + Primvar 实现的资产可参数化 |
| Session Artifact | 9 | 不落盘的临时会话数据 |
| Reference-payload Pattern | 10 | 轻量 reference + 重型 payload 的资产拆分模式 |
| Lofting | 10 | 把关键 metadata 从 payload 抬升到 reference 层 |
| Asset Interface Layer | 10 | 资产的入口 root layer |
| Entrypoint Prim | 10 | 资产的主 prim，供下游引用 |
| Asset Prim Interface | 10 | 资产维护的稳定 prim 集合 |
| Aggregate Model Structure | 10 | 只含引用的 assembly 结构 |
| Atomic Model Structure | 10 | 完全封装的 component 结构 |
| Package Model Structure | 10 | 含内部 component + 外部引用的 assembly 结构 |
| Selector Model Structure | 10 | 用 variant 切换资产的 component/assembly |
| Embedded Context | 10 | 非 entrypoint 但对预览有用的 prim |
| Access Semantics | 10 | 用 `_` 前缀等约定标记内部可编辑性 |
| Encapsulation | 10 | 层级分支的 relationship 不指向外部的原则 |
| De-duplication | 10 | 自动检测消除重复数据 |
| Mirroring Resolver | 11 | 贪婪本地化整个资源的 resolver |
| Hydra | 12 | USD 的可插拔渲染框架 |
| Schema | 12 | 领域对象的标准化定义（UsdGeom/UsdShade...） |
| Computational Workstreams | —（进阶） | 由并行计算支撑的 layer stack 工作流，本指南未深入 |
| User Workstreams | —（进阶） | 用户面对的、可能重叠并行的工作单元，通常用 layer stack 建模 |
| Scene Graph Instance | 8 | Native Instance 的同义词 |
| Refinable Instancing | 8 | 细化实例化的总称，含 Globally/Internally 两种 |

---

*本指南基于 OpenUSD 26.08 源码库与 NVIDIA Omniverse 官方文档编写。*
