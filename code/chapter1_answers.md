# 第 1 章练习答案

> 对应 `LEARNING_GUIDE.md` 的 1.7 节练习题。
> 所有代码已在 OpenUSD 26.08 + Python 3.13 环境下验证通过。

---

## 练习 1.1

> **题目**：用 Python 创建一个新 Stage，定义 `/World` 和 `/World/Camera` 两个 Xform prim，保存为 `chapter1_ex1.usda`。用 `usdcat` 查看文件内容。

### 答案代码

```python
# 文件：chapter1_ex1.py
from pxr import Usd, UsdGeom

# 1. 创建一个全新的空 Stage，指定 root layer 文件路径
stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter1_ex1.usda")

# 2. 定义两个 Xform prim
#    UsdGeom.Xform.Define 会自动创建 prim 及其所需的内置属性
UsdGeom.Xform.Define(stage, "/World")
UsdGeom.Xform.Define(stage, "/World/Camera")

# 3. 保存 root layer 到磁盘
stage.Save()

print(f"Stage saved to: {stage.GetRootLayer().realPath}")
```

### 运行方式

```powershell
cd F:\newton\OpenUSDTutorial\code
python chapter1_ex1.py
```

### 用 usdcat 查看文件内容

```powershell
usdcat F:\newton\OpenUSDTutorial\code\chapter1_ex1.usda
```

### 输出结果

```
#usda 1.0

def Xform "World"
{
    def Xform "Camera"
    {
    }
}
```

### 解析

| 要素 | 说明 |
|---|---|
| `#usda 1.0` | USDA 文件格式版本号 |
| `def Xform "World"` | 定义一个类型为 Xform 的 prim，名为 World，路径为 `/World` |
| `def Xform "Camera"` | 定义一个类型为 Xform 的 prim，名为 Camera，路径为 `/World/Camera`（嵌套在 World 下） |
| `def` | prim 指定符，表示"定义一个新 prim"（区别于 `over` 覆盖、`class` 抽象类） |
| `Xform` | prim 的类型，最常用的容器类型，用于变换和分组 |

---

## 练习 1.2

> **题目**：用 `Usd.Stage.Open()` 打开 `extras/usd/tutorials/convertingLayerFormats/Sphere.usda`，用 `stage.Traverse()` 遍历所有 prim 并打印它们的路径。

### 答案代码

```python
# 文件：chapter1_ex2.py
from pxr import Usd

# 1. 打开已有的 USD 文件作为 Stage
stage = Usd.Stage.Open(
    "F:/newton/OpenUSD/extras/usd/tutorials/convertingLayerFormats/Sphere.usda"
)

# 2. 遍历 Stage 中所有 prim 并打印路径和类型
for prim in stage.Traverse():
    print(f"Path: {prim.GetPath()}, Type: {prim.GetTypeName()}")
```

### 运行方式

```powershell
cd F:\newton\OpenUSDTutorial\code
python chapter1_ex2.py
```

### 输出结果

```
Path: /sphere, Type: Sphere
```

### 解析

| 要素 | 说明 |
|---|---|
| `Usd.Stage.Open(path)` | 打开已有 USD 文件，加载到内存作为 Stage |
| `stage.Traverse()` | 遍历 Stage 中所有"活跃的"prim（跳过伪根和实例内部） |
| `prim.GetPath()` | 获取 prim 的路径，如 `/sphere` |
| `prim.GetTypeName()` | 获取 prim 的类型名，如 `Sphere` |

这个 Stage 只有一个 prim：`/sphere`，类型是 `Sphere`（球体）。这是 OpenUSD 自带的最简示例文件。

---

## 练习 1.3

> **题目**：在 usdview 中打开上面这个 Stage，找到 Properties 面板里的 "Composition" 标签页，观察这个 Stage 由哪些 layer 组成（目前只有一个 root layer，第 3 章会看到多个 layer 的合成）。

### 操作步骤

```powershell
# 用 usdview 打开 Sphere.usda
usdview F:\newton\OpenUSD\extras\usd\tutorials\convertingLayerFormats\Sphere.usda
```

### 观察要点

打开 usdview 后，按以下步骤操作：

1. **左侧 Stage Tree 面板**：点击 `/sphere` prim 选中它
2. **右侧 Properties 面板**：找到 **"Composition"** 标签页
3. **观察内容**：

| 你看到的 | 含义 |
|---|---|
| 只有一行 Layer（root layer） | 这个 Stage 目前只有 root layer，没有 sublayer / reference / payload 等合成弧线 |
| Layer 路径指向 `Sphere.usda` | 这就是打开 Stage 时指定的那个文件 |
| 没有其他 arc 条目 | 第 3 章学习 Layer Stack 后，你会看到多个 layer 叠加的合成结果 |

### 预期观察结果

```
Composition 面板：
┌─────────────────────────────────┐
│  Root Layer                     │
│    ↳ Sphere.usda               │  ← 只有这一个 layer
│                                 │
│  （没有 reference / payload /   │
│    inherit / variant 等 arc）   │
└─────────────────────────────────┘
```

### 与第 3 章的对比预告

| 当前（第 1 章） | 第 3 章之后 |
|---|---|
| Stage 只有一个 root layer | Stage 有多个 layer 叠加（sublayer） |
| Composition 面板只有一行 | Composition 面板有多行，显示强弱关系 |
| 属性值只来自一个文件 | 属性值可能来自多个文件，强层覆盖弱层 |

---

## 关键知识点回顾

| API | 作用 | 所属类 |
|---|---|---|
| `Usd.Stage.CreateNew(path)` | 创建新 Stage，root layer 为 path | Usd.Stage |
| `Usd.Stage.Open(path)` | 打开已有 USD 文件作为 Stage | Usd.Stage |
| `UsdGeom.Xform.Define(stage, path)` | 定义一个 Xform prim | UsdGeom.Xform |
| `stage.Save()` | 保存 root layer 到磁盘 | Usd.Stage |
| `stage.Traverse()` | 遍历所有 prim | Usd.Stage |
| `prim.GetPath()` | 获取 prim 路径 | Usd.Prim |
| `prim.GetTypeName()` | 获取 prim 类型名 | Usd.Prim |
| `usdcat file.usda` | 查看 USDA 文件内容 | 命令行工具 |
| `usdview file.usda` | 图形界面查看 Stage | 命令行工具 |

---

*基于 OpenUSD 26.08 + Python 3.13.9 验证*
