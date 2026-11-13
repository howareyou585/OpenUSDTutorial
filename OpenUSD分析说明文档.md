# OpenUSD（Universal Scene Description）分析说明文档

> **数据来源**：本文基于 AOUSD 官方站点（https://aousd.org/）与 OpenUSD 官方文档（https://openusd.org/release/）整理。
> **整理日期**：2026-07-07
> **适用版本**：OpenUSD v26.05（AOUSD Core Specification 1.0 已发布）

---

## 一、概述

**OpenUSD**（Open Universal Scene Description）是 Pixar Animation Studios 开发、并由 **Alliance for OpenUSD（AOUSD）** 推动的开源三维场景描述平台。它并不只是一个"文件格式"，而是一套用于**描述、组合、模拟、协同构建**三维场景的高性能可扩展框架与生态系统。

AOUSD 给出的官方定位是：

> *"OpenUSD is a high-performance extensible framework and ecosystem for describing, composing, simulating, and collaboratively navigating and constructing 3D scenes."*
> —— AOUSD 官网

其核心能力包括：

- **非破坏性组合**（Non-destructive composition）：通过多种组合弧（composition arcs）将分散的场景片段无损地拼接、覆盖、变体化。
- **高性能可扩展**：可承载电影级（数百万 prim）规模场景，支持懒加载（payload）。
- **跨工具互操作**：成为 DCC（Maya、Houdini、Blender、3ds Max、Substance）、渲染器、仿真器之间的事实交换标准。
- **时间采样动画**：原生支持按帧时间采样的属性动画。
- **可扩展模式系统**（Schema）：几何、着色、灯光、物理、体积、毛发等均可通过 schema 扩展。

---

## 二、起源与标准化进程

### 2.1 Pixar 内部起源

OpenUSD 源于 Pixar 内部用于电影制作流水线的场景描述系统，最早可追溯到 *Cars 2*（2011）时期的 Preston 工具链，后在 *Inside Out*、*Coco*、*Toy Story 4* 等影片中持续演进。它解决的核心痛点是：**在大型制作中，多个部门（建模、动画、灯光、特效）需要并行、非破坏性地编辑同一场景的不同方面**。

Pixar 于 2016 年将 USD 以 Mozilla Public License 2.0 开源，仓库为 `PixarAnimationStudios/USD`，后迁至 `openusd/openusd`。

### 2.2 AOUSD 联盟成立

2023 年 8 月，**Alliance for OpenUSD（AOUSD）** 成立，作为 Linux Foundation 旗下 Joint Development Foundation 项目，五位创始成员：

| 创始成员 | 角色 |
|---|---|
| **Pixar** | 技术起源、参考实现维护者 |
| **Adobe** | Substance 3D 生态、材质 |
| **Apple** | AR Quick Look、USDZ 包格式 |
| **Autodesk** | Maya / 3ds Max / Flow DCC 集成 |
| **NVIDIA** | Omniverse 平台、工业仿真 |

首任主席为 Pixar CTO **Steve May**。

### 2.3 四大核心倡议（Core Initiatives）

AOUSD 的使命围绕四点：

1. **Standardization（标准化）**：提供书面规范，允许多种实现并支持其他标准引用。
2. **Evolution（演进）**：协调成员与合作伙伴开发新功能。
3. **Development（开发）**：当 Pixar 仓库尚无参考实现时，提供新功能仓库。
4. **Growth（增长）**：降低更广泛场景（建筑、汽车、制造、机器人）的采用门槛。

### 2.4 工作组与规范进度

- **Core Specification WG**：核心规范，已于 2025-2026 年间推进到 **Core Specification 1.0**。
- **Materials WG**：材质（MaterialX / UsdShade 互操作）。
- **Geometry WG**：几何模式扩展。
- **Physics WG**（2024-12 章程通过）：物理仿真 schema。

### 2.5 版本节奏

OpenUSD 采用 `YY.MM` 版本号。近期重要版本：

- **v26.05**（2026-05）：当前稳定版本，含 Core Spec 1.0 对齐的关键改进。
- **v26.03**（2026-03）：引入 GaussianSplat 等 schema。
- 每年发布 2-3 个 minor 版本。

---

## 三、设计理念

OpenUSD 的设计哲学可总结为四点，理解它们是理解后续架构的前提：

### 3.1 非破坏性组合优先（Composition-First）

USD 把"如何把多人多源的场景片段组合成一个统一场景"作为第一公民。所有组合弧（sublayer / reference / payload / variant / inherit / specialize）都是**可列表编辑（list-editable）**且**封装（encapsulated）**的：强层不能删除弱层引入的弧的内部结构，只能整体删除由同一层栈引入的弧。这保证了资产内部的引用结构对下游不可变，使得组合可解释、可缓存。

### 3.2 强度排序（LIVERPS）

同一属性可能有多个来源，USD 用 **LIVERPS** 强度顺序解析最终值：

> **L**ocal > **I**nherits > **V**ariantSets > **R**elocates > **R**eferences > **P**ayload > **S**pecializes

越靠前强度越高。递归处理 Inherits/VariantSets/Relocates/References 时会忽略 Specializes 弧，避免循环。

### 3.3 关注点分离：Sdf / Usd / Hd 三层

USD 在架构上严格分层：

| 层 | 全称 | 职责 |
|---|---|---|
| **Sdf** | Scene Description Foundation | 底层场景描述原语：Layer、PrimSpec、AttributeSpec、RelationshipSpec、Path。无组合语义。 |
| **Usd** | Universal Scene Description | 高层 API：Stage、Prim、Attribute、Relationship，组合（Pcp）、值解析（value resolution）、Schema。 |
| **Hd** | Hydra | 渲染抽象：SceneDelegate → RenderIndex → RenderDelegate，对接 Storm / Karma / 第三方渲染器。 |

这种分层让"存储格式"（Sdf）、"组合语义"（Usd）、"渲染呈现"（Hd）三者解耦，是 USD 区别于 FBX/glTF 等纯交换格式的根本原因。

### 3.4 可扩展性优先

USD 的 Schema 系统允许任何人定义新的 prim 类型与属性集，而不需要修改核心。Pixar 官方提供 `usdGeom`、`usdShade`、`usdLux`、`usdSkel`、`usdVol`、`usdPhysics`（草案）等 schema 模块。

---

## 四、文件格式

USD 支持**三种文件后缀**，它们在内容上可互相转换而不影响引用（引用的是 `.usd` 抽象资产，而非具体格式）。

### 4.1 `.usda` —— 文本格式（ASCII）

- **可读**：人类可读的 Tarn 脚本式语法。
- **用途**：调试、版本控制 diff、教学、轻量资产手写。
- **示例**：

  ```
  #usda 1.0
  def Sphere "SphereWithTimeSamples"
  {
      double radius.timeSamples = {
          1: 100,
          20: 500,
          50: 250
      }
  }
  ```

### 4.2 `.usdc` / `.usd`（Crate）—— 二进制格式

- **二进制**：Pixar 自研的 **Crate** 容器，紧凑、对齐、支持内存映射（mmap）懒加载。
- **用途**：生产环境的主力格式，存储与加载性能最优。
- **特性**：类型化、字段去重、支持大数组零拷贝；通过 `usdcat` 可与 `.usda` 互转。
- **`.usd` 双义后缀**：`.usd` 既可能是文本也可能是 Crate，由文件头魔数判定；可用环境变量 `USD_DEFAULT_FILE_FORMAT=usdc|usda` 指定新建文件的默认格式。

### 4.3 `.usdz` —— 打包格式

- **零压缩包**：Apple 主导，将一个 USD 资产及其依赖（纹理、外部引用）打包成单个文件，**无压缩**（便于内存映射直读）。
- **用途**：**Apple AR Quick Look** 的原生格式；iOS / macOS / visionOS / Web 端分发 3D 资产的事实标准。
- **特性**：包内资源以对齐偏移存储，可被系统 API 直接 mmap，无需解包到磁盘。

### 4.4 三者对比

| 特性 | `.usda` | `.usdc`/`.usd` (Crate) | `.usdz` |
|---|---|---|---|
| 编码 | ASCII 文本 | 二进制 | 容器（内含 .usdc/.usda + 资源） |
| 可读性 | 优 | 差 | 差 |
| 加载性能 | 慢 | 最快 | 快（mmap） |
| 存储体积 | 大 | 最小 | 中 |
| 版本控制友好 | 优 | 差 | 差 |
| 依赖打包 | 否 | 否 | 是 |
| 主要场景 | 调试 / VCS / 教学 | 生产主存储 | AR / 分发 / Web |

### 4.5 工具：`usdcat`

格式互转的核心工具：

```bash
# 二进制 → 文本
usdcat -o NewSphere_text.usd --usdFormat usda NewSphere_binary.usd

# 文本 → 二进制
usdcat -o NewSphere_binary.usd --usdFormat usdc NewSphere_text.usd
```

---

## 五、核心数据模型

### 5.1 Stage（舞台）

- **Stage** 是一个组合完成的场景图实例，由一个根 LayerStack 与其引用的所有 Layer 共同组合而成。
- 通过 `UsdStage::Open(path, resolverContext)` 打开。
- Stage 提供 prim 遍历、时间码（timeCode）查询、编辑目标（edit target）切换等能力。

### 5.2 Layer（层）

- **Layer** 是 Sdf 层的概念，对应磁盘上的一个 `.usda/.usdc/.usdz` 文件（或内存层）。
- 一个 Stage 由多个 Layer 经 sublayer 组成 **LayerStack**，最上层最强。
- 每个 Layer 内含若干 PrimSpec。

### 5.3 Prim（图元）

- **Prim** 是场景图的基本节点，可表示几何体、灯光、相机、材质、组（Xform）等。
- 每个 Prim 有：
  - **类型（typeName）**：如 `Sphere`、`Xform`、`Material`、`DiskLight`。
  - **路径（SdfPath）**：如 `/World/Room/Table/Sphere`。
  - **属性（Attributes）** 与 **关系（Relationships）**。
  - **元数据（metadata）**：如 kind、instanceable、variantSets 等。

### 5.4 Property：Attribute 与 Relationship

USD 的 Property 分两类：

| 类型 | 持有 | 时间采样 | 示例 |
|---|---|---|---|
| **Attribute** | 类型化值（int/float/float3/asset/token…） | 支持 | `double radius = 1.0` |
| **Relationship** | prim/property 路径列表 | 不支持 | `rel material:binding = </Material>` |

### 5.5 Schema（模式）

Schema 是可注册的 Prim 类型定义，分为两类：

- **API Schema**：以 `ApplyAPI()` 挂到任意 prim 上的能力集合（如 `UsdModelAPI`、`UsdClipsAPI`、`MotionAPI`）。
- **Typed Schema**：有具体 typeName 的 prim 类（如 `Sphere`、`Mesh`、`DiskLight`），通过 C++ 代码生成或 `usdGenSchema` 生成。

官方 schema 模块：

| 模块 | 覆盖范围 |
|---|---|
| `usdGeom` | 几何（Mesh/Sphere/Cube/Camera/Xform/PointInstancer…） |
| `usdShade` | 材质、Shader 网络、MaterialX 互操作 |
| `usdLux` | 灯光（DistantLight/DiskLight/SphereLight/DomeLight…） |
| `usdSkel` | 骨骼绑定与蒙皮动画 |
| `usdVol` | 体积（OpenVDBAsset / FieldAsset） |
| `usdMedia` | 媒体、资产信息 |
| `usdPhysics`（草案） | 刚体/碰撞/约束 |
| `usdRender` | 渲染设置、Aov、产品输出 |
| `usdProc` | 程序化生成（ procedural ） |

---

## 六、组合架构（Composition）—— USD 的灵魂

组合是 USD 区别于一切其他 3D 格式的核心能力。它把"场景"理解为**多个层（Layer）经多种弧（Arc）组合而成的有向图**，最终通过 **LIVERPS 强度排序**解析每个属性的取值。

### 6.1 六种组合弧

| 弧 | 作用域 | 强度（LIVERPS 中位置） | 典型用途 |
|---|---|---|---|
| **subLayers** | LayerStack 级 | （不参与 prim 级 LIVERPS，按 sublayer 顺序自上而下） | 把多个层堆叠成一个 LayerStack，如 `subLayers = [@shot.usd@, @char_base.usd@]` |
| **references** | prim 级 | References | 引入外部资产到当前 prim，一次性、不可级联编辑 |
| **payloads** | prim 级 | Payload（最弱之一） | 懒加载：只在 prim 被加载时才拉取目标，常用于大规模场景按需载入 |
| **variantSets / variants** | prim 级 | VariantSets | 变体：一个资产内打包多个变体（如 `modelingVariant` 含 `high/low/mid`），下游可切换 |
| **inherits** | prim 级 | Inherits（仅次于 Local） | 继承：派生 prim 持续接收基类 prim 的覆盖，适合"批量改一类实例" |
| **specializes** | prim 级 | Specializes（最弱） | 特化：派生作为基类的精炼版，基类改动会传播到派生 |

> **封装原则**：除 subLayers 外，所有弧都指向某 LayerStack 中的具体 prim。弧是 list-editable 的，强层可追加或删除"由本层栈引入"的弧，但**不能修改弱层引入弧的内部结构**。这是组合可解释、可缓存的关键。

### 6.2 一个典型组合场景

```
Sequence.usd
 └─ subLayers: [Shot_010.usd, Sequence_base.usd]
       └─ Shot_010.usd 内 /World/Char 引用了 Character Asset
              └─ CharacterAsset.usd 定义 /Char，含 variantSets=[modelingVariant, shadingVariant]
                     └─ payload: heavyGeo.usd  ← 懒加载
```

- 镜头层覆盖角色动画属性；
- 角色资产内含建模变体（高/低模）与着色变体（湿/干）；
- 重几何通过 payload 延迟加载，镜头打开时不占内存。

### 6.3 值解析（Value Resolution）

查询某属性在某时间码的最终值时，USD 沿组合图按 LIVERPS 顺序搜索，第一个命中即返回。支持：

- **default value** 与 **timeSamples** 共存，timeSamples 命中区间则插值，否则回落 default。
- **value clips**（`UsdClipsAPI`）：把外部层序列按时间区间注入，常用于"实景扫描数据"按帧切换。

---

## 七、时间采样与动画

USD 把"时间"作为一等公民。每个 Attribute 都可携带：

- 一个 **default 值**（无时间）；
- 一组 **timeSamples**：`{timeCode: value, ...}`；
- 或 **Spline**（v24+ 草案，更高级的曲线表达）。

查询时给定 `UsdTimeCode`：

- 落在两个采样点之间 → **线性插值**；
- 落在采样点之外 → 取最近端点（外推为常数）；
- 无 timeSamples → 返回 default。

示例（来自官方文档）：

```
double xformOp:translateX.timeSamples = {
     1: 0,
    25: 10,
    99: 5,
}
```

帧 13 的 `translateX` = 线性插值(0,10, t=(13-1)/(25-1)) = 5.0。

USD 的 `UsdStage` 提供 `GetStartTimeCode()` / `GetEndTimeCode()` / `GetTimeCodesPerSecond()` 描述整体时间域与帧率。变换矩阵通过 `xformOp:order` 列表（如 `translate/rotateXYZ/scale`）按序累乘，所有 op 均可独立时间采样。

---

## 八、资产解析系统（Ar）

### 8.1 设计目标

USD 中所有跨文件引用都用**资产路径**（`@path/to/asset.usd@`）表达，而非直接文件路径。**Ar（Asset Resolution）** 模块负责把这些抽象资产路径解析为可加载的实际位置，使资产库可在不同机器/项目间重定位而无需改文件。

### 8.2 核心组件

- **ArResolver**：抽象基类，可被插件替换（默认 `ArDefaultResolver`）。
- **ArResolverContext**：解析上下文，携带额外信息（如搜索路径）。`ArDefaultResolverContext` 持有一组 searchPath。
- **Ar 2.0 提案**（进行中）：移除 repository/search path 隐式依赖、引入 identifier 概念、支持 URI scheme 解析器、允许从字符串构造 context。

### 8.3 用法示例

```cpp
ArDefaultResolverContext shotACtx({"/ShotA/assets"});
UsdStageRefPtr shotA = UsdStage::Open("ShotA.usd", shotACtx);
```

命令行工具：

```bash
usdresolve --createContextForAsset /ShotA/ShotA.usd @sublayer.usd@
usdresolve --anchorPath /asset/asset.usd sublayer.usd
```

### 8.4 与 USDZ 的关系

USDZ 包内资源使用**相对路径**解析，包本身即是一个解析上下文。Apple 的 AR Quick Look 直接依赖 USDZ 的自包含特性。

---

## 九、Hydra 渲染架构

### 9.1 三件套

Hydra 是 USD 的渲染抽象层，由三部分组成：

| 组件 | 职责 |
|---|---|
| **HdSceneDelegate** | 数据提供方：把 USD Stage（或任意数据源）翻译成 Hydra 可消费的 Rprim/Sprim/Bprim。 |
| **HdRenderIndex** | 变更追踪中枢：跟踪场景增量更新，调度到 RenderDelegate。 |
| **HdRenderDelegate** | 渲染后端抽象：把 Rprim/Sprim/Bprim 翻译为具体渲染器的命令与资源。 |

> - **Rprim**：Renderable prim（网格、曲线、点云、体积…）
> - **Sprim**：State prim（灯光、相机、材质、渲染设置…）
> - **Bprim**：Buffer prim（纹理、buffer 资源…）

### 9.2 Hydra 的设计价值

- **大场景优化**：原生为变更追踪（change processing）设计，只重算变化部分。
- **渲染器无关**：一个 SceneDelegate 可同时喂给多个 RenderDelegate，实现"视口用 Storm，离线用 Karma"。
- **可插拔**：渲染器通过 `HdRendererPlugin` 注册，运行时切换。

### 9.3 内置 RenderDelegate

| 名字 | 后端 | 用途 |
|---|---|---|
| **Storm**（`HdStRenderDelegate`） | OpenGL / Metal / Vulkan（经 Hgi 抽象） | Pixar 交互视口、`usdview` 默认后端，高性能预览 |
| **Embree**（实验） | Intel Embree | CPU 光线投射 |

第三方实现：Karma（SideFX）、Renderman、Redshift、Apple's Quick Look、NVIDIA Omniverse RTX、Blender's Hydra Storm 集成等。

### 9.4 Hgi —— 图形 API 抽象

`Hgi`（Hydra Graphics Interface）在 Storm 之下再抽象一层，屏蔽 OpenGL/Metal/Vulkan 差异，使 Storm 可跨桌面/移动平台运行，这也是 USDZ 能在 iOS 上原生渲染的底层支撑。

---

## 十、工具链

USD 提供一组命令行工具（`bin/`）：

| 工具 | 作用 |
|---|---|
| `usdcat` | 查看 / 转换 USD 文件格式（usda ↔ usdc） |
| `usdview` | 交互式场景查看器（PySide + Storm） |
| `usdresolve` | 资产路径解析 |
| `usdtree` | 打印 prim 层级树 |
| `usdinspect` | 检查组合、引用、payload 信息 |
| `usdedit` | 编辑文本层 |
| `usdGenSchema` | 由 schema.usda 生成 C++ / Python 绑定 |
| `usdrecord` | 用 Hydra 渲染输出图像 |
| `usdzip` | 创建/查看 USDZ 包 |

Python API（`pxr.Usd`、`pxr.Sdf`、`pxr.Hd`…）是脚本化与 DCC 集成的主要入口。

---

## 十一、与其他 3D 格式对比

> 注：本节部分信息综合自 AOUSD 生态与行业实践，旨在帮助选型。

| 维度 | **OpenUSD** | glTF 2.0 | FBX | Alembic |
|---|---|---|---|---|
| **定位** | 场景组合平台 + 格式 | Web/运行时交换格式 | DCC 交换格式（专有） | 几何缓存格式 |
| **来源** | Pixar / AOUSD | Khronos | Autodesk | ILM/Sony |
| **开源** | 是（MPL2） | 是（Royalty-free） | 否（Autodesk SDK） | 是（BSD） |
| **组合/覆盖** | ✅ 六种弧，非破坏性 | ❌ 无 | ❌ 无 | ❌ 无 |
| **变体** | ✅ 原生 variantSets | ❌ | ❌ | ❌ |
| **懒加载** | ✅ payload | ❌ | ❌ | 部分 |
| **时间采样动画** | ✅ 一等公民 | ✅（动画通道） | ✅ | ✅（核心） |
| **材质系统** | UsdShade + MaterialX | PBR metallic-roughness | 专有 | 无 |
| **渲染抽象** | ✅ Hydra | ❌ | ❌ | ❌ |
| **文件体积（同资产）** | 中（usdc 最优） | 小（glb） | 大 | 中 |
| **生态** | 影视/工业/XR 新标准 | Web/移动端事实标准 | 遗留 DCC 互通 | 影视几何缓存 |

### 选型建议

- **Web/移动运行时** → glTF / GLB（小、快、浏览器原生）
- **iOS AR / Apple 生态分发** → **USDZ**（Quick Look 原生）
- **影视/动画大型流水线** → **USD（.usdc 为主）**
- **DCC 间遗留资产迁移** → FBX（暂无替代时）
- **几何缓存（带动画的烘焙数据）** → Alembic（或 USD 的 value clips）

值得注意的是，**USD 与 glTF 并非二选一**：USD 的 `usdRecord` / `UsdMtlx` 与 glTF 之间已有转换工具（如 NVIDIA Omniverse、`usdFromGltf` 实验），USD 常作为"制作侧主存储"，glTF 作为"运行时导出目标"。

---

## 十二、行业采用

### 12.1 影视

- **Pixar**：全部制作流水线基于 USD。
- **ILM、Animal Logic、Weta FX、DNEG**：均以 USD 作为跨部门场景格式。
- **SideFX Houdini / Maya / 3ds Max / Blender**：原生或经插件支持 USD 导入导出与 Solaris（Houdini 的 USD 原生上下文）。

### 12.2 工业与仿真

- **NVIDIA Omniverse**：以 USD 为原生场景格式，连接工业数字孪生。
- **Autodesk Flow**：制造/建筑协作平台采用 USD。
- **建筑、汽车、制造、机器人**：AOUSD 明确列为增长方向，Physics WG 即服务于此。

### 12.3 XR 与消费端

- **Apple**：USDZ 是 AR Quick Look、visionOS、Finder 预览的原生格式。
- **Adobe Substance 3D**：支持 USD 材质导出。
- **Khronos glTF**：与 AOUSD 生态合作，探索材质/几何 schema 互操作。

---

## 十三、标准化与治理

- **规范载体**：AOUSD Core Specification（书面规范，独立于 Pixar 实现）。
- **治理**：Linux Foundation / Joint Development Foundation，由创始成员 + 选举产生的普通成员代表组成指导委员会。
- **工作组**：Core / Materials / Geometry / Physics，章程公开。
- **会员费**：普通会员年费 10,000 USD（需同时为 Linux Foundation 会员）；个人可免费作为 Contributor 参与兴趣组。
- **生态合作**：与 Khronos（glTF/MaterialX）、W3C、ISO 等标准组织建立对接。

---

## 十四、局限与挑战

客观而言，USD 也存在以下挑战：

1. **学习曲线陡峭**：组合弧、LIVERPS、Sdf/Usd/Hd 分层对新手不友好；官方文档虽完整但偏 API 参考。
2. **运行时体积偏大**：核心 C++ 库 + Python 绑定较重，不适合纯 Web 嵌入；Web 端目前依赖 `usd-wasm` 等社区方案。
3. **材质碎片化**：UsdShade 历史上支持多种着色后端（Karma/Renderman/OSO），MaterialX 成为统一节点图标准后仍在迁移中。
4. **物理 schema 尚未稳定**：Physics WG 2024 年底才成立，刚体/碰撞/约束的统一 schema 仍在草案。
5. **小资产场景性价比低**：对于单个静态模型，glTF 更轻；USD 的组合优势在大型流水线才显现。
6. **规范实现尚不充分**：Core Spec 1.0 刚落地，第三方独立实现（非 Pixar 参考实现）仍稀缺。

---

## 十五、总结

OpenUSD 的独特价值在于：**它把"非破坏性场景组合"作为第一公民，并以严格的三层架构（Sdf / Usd / Hd）将存储、语义、渲染解耦**。这使它不仅是交换格式，更是大型 3D 生产流水线的"场景操作系统"。

- 对**影视与工业数字孪生**：USD 已是不可逆的标准方向。
- 对 **Web / 移动运行时**：USD（尤其 USDZ）作为分发载体在 Apple 生态强势，但通用 Web 仍以 glTF 为主。
- 对**新项目选型**：若涉及多部门协作、变体、大场景懒加载，USD 是当前最优解；若只是单模型展示，glTF 更轻。

随着 AOUSD 推进 Core Specification 1.0、Physics/Materials/Geometry 工作组落地，以及 Apple / NVIDIA / Autodesk 的产业级采用，OpenUSD 正在从"影视工具"演化为**跨行业的三维互操作底座**。

---

## 附录 A：官方资源

| 资源 | 链接 |
|---|---|
| AOUSD 官网 | https://aousd.org/ |
| OpenUSD 文档 | https://openusd.org/release/index.html |
| API 参考 | https://openusd.org/release/api/index.html |
| GitHub 仓库 | https://github.com/openusd/openusd |
| NVIDIA 教程 | https://docs.omniverse.nvidia.com/usd.html |
| 论坛 | http://forum.aousd.org |

## 附录 B：术语速查

| 术语 | 全称 / 释义 |
|---|---|
| **USD** | Universal Scene Description |
| **AOUSD** | Alliance for OpenUSD |
| **Sdf** | Scene Description Foundation（底层） |
| **Usd** | 高层场景 API |
| **Hd / Hydra** | 渲染抽象层 |
| **Hgi** | Hydra Graphics Interface（OpenGL/Metal/Vulkan 抽象） |
| **Pcp** | Prim Composition（组合引擎） |
| **Ar** | Asset Resolution（资产解析） |
| **LIVERPS** | Local > Inherits > VariantSets > Relocates > References > Payload > Specializes 强度顺序 |
| **Crate** | USD 二进制容器格式 |
| **Stage** | 组合完成的场景图实例 |
| **Layer** | 单个文件 / 内存层 |
| **Prim** | 场景图节点 |
| **Schema** | Prim 类型与属性集定义 |
