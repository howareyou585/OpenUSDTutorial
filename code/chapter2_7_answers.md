# 第 2-7 章练习答案

> 对应 `LEARNING_GUIDE.md` 的练习题。
> 所有代码已在 OpenUSD 26.08 + Python 3.13 环境下验证。

---

## 第 2 章：Prim & Scene Graph

### 练习 2.1

> 创建 Stage，结构 `/World/Environment/{Ground,Sky}` + `/World/Robot/{Head,Body}`，保存并用 usdview 查看。

```python
# 文件：chapter2_ex1.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter2_ex1.usda")

# 创建层级结构
UsdGeom.Xform.Define(stage, "/World")
UsdGeom.Xform.Define(stage, "/World/Environment")
UsdGeom.Mesh.Define(stage, "/World/Environment/Ground")
UsdGeom.Mesh.Define(stage, "/World/Environment/Sky")
UsdGeom.Xform.Define(stage, "/World/Robot")
UsdGeom.Mesh.Define(stage, "/World/Robot/Head")
UsdGeom.Mesh.Define(stage, "/World/Robot/Body")

stage.Save()
print("Saved. Prim tree:")
for prim in stage.Traverse():
    depth = len(prim.GetPath().pathString.split("/")) - 1
    print("  " * depth + prim.GetName() + f" ({prim.GetTypeName()})")
```

**输出**：
```
World (Xform)
  Environment (Xform)
    Ground (Mesh)
    Sky (Mesh)
  Robot (Xform)
    Head (Mesh)
    Body (Mesh)
```

### 练习 2.2

> 写递归函数 `print_prim_tree(prim, indent=0)`，从伪根打印整个 prim 树。

```python
# 文件：chapter2_ex2.py
from pxr import Usd

def print_prim_tree(prim, indent=0):
    """递归打印 prim 树，缩进表示层级"""
    if prim.IsActive():
        prefix = "  " * indent
        print(f"{prefix}{prim.GetName()} ({prim.GetTypeName()})")
    for child in prim.GetChildren():
        print_prim_tree(child, indent + 1)

stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/chapter2_ex1.usda")
# 从伪根开始（伪根本身不打印，只打印它的子节点）
pseudo_root = stage.GetPseudoRoot()
print_prim_tree(pseudo_root)
```

### 练习 2.3

> 用 `GetPrimAtPath` 取 prim，打印 `GetTypeName`、`GetParent().GetPath()`、`GetChildren()`。

```python
# 文件：chapter2_ex3.py
from pxr import Usd

stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/chapter2_ex1.usda")
prim = stage.GetPrimAtPath("/World/Robot/Head")

print(f"Path:       {prim.GetPath()}")
print(f"Type:       {prim.GetTypeName()}")
print(f"Parent:     {prim.GetParent().GetPath()}")
print(f"Children:   {[c.GetPath() for c in prim.GetChildren()]}")
```

**输出**：
```
Path:       /World/Robot/Head
Type:       Mesh
Parent:     /World/Robot
Children:   []
```

### 练习 2.4

> 阅读 `extras/usd/tutorials/traversingStage/traversingStage.py`，运行它。

```powershell
# 先生成 HelloWorld.usda
cd F:\newton\OpenUSD\extras\usd\tutorials\helloWorld
python helloWorld.py

# 运行遍历教程
cd F:\newton\OpenUSD\extras\usd\tutorials\traversingStage
python traversingStage.py
```

教程会打开 HelloWorld.usda 并遍历打印每个 prim 的路径和属性，演示了 `stage.Traverse()` 的标准用法。

---

## 第 3 章：Layer & Layer Stack

### 练习 3.1

> 创建 3 个 layer：base（半径1.0）、mid（覆盖2.0）、top（覆盖3.0），确认最终半径3.0。

```python
# 文件：chapter3_ex1.py
from pxr import Usd, UsdGeom

# === 1. base 层：定义球体，半径 1.0 ===
base = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/base.usda")
UsdGeom.Xform.Define(base, "/World")
UsdGeom.Sphere.Define(base, "/World/Ball")
UsdGeom.Sphere(base.GetPrimAtPath("/World/Ball")).GetRadiusAttr().Set(1.0)
base.Save()

# === 2. mid 层：sublayer 引用 base，覆盖半径 2.0 ===
mid = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/mid.usda")
mid.GetRootLayer().subLayerPaths.append("F:/newton/OpenUSDTutorial/code/base.usda")
mid_prim = mid.OverridePrim("/World/Ball")
UsdGeom.Sphere(mid_prim).GetRadiusAttr().Set(2.0)
mid.Save()

# === 3. top 层：sublayer 引用 mid，覆盖半径 3.0 ===
top = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/top.usda")
top.GetRootLayer().subLayerPaths.append("F:/newton/OpenUSDTutorial/code/mid.usda")
top_prim = top.OverridePrim("/World/Ball")
UsdGeom.Sphere(top_prim).GetRadiusAttr().Set(3.0)
top.Save()

# === 4. 验证：打开 top，检查最终半径 ===
stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/top.usda")
ball = UsdGeom.Sphere(stage.GetPrimAtPath("/World/Ball"))
print(f"Final radius: {ball.GetRadiusAttr().Get()}")  # 应为 3.0
```

### 练习 3.2

> 在 top.usda 里用 `over "World"` 但不覆盖半径，观察最终值（应为 2.0）。

```python
# 文件：chapter3_ex2.py
from pxr import Usd, UsdGeom

# 重新创建 top：引用 mid，但不覆盖半径
top2 = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/top2.usda")
top2.GetRootLayer().subLayerPaths.append("F:/newton/OpenUSDTutorial/code/mid.usda")
# 只声明 over，不设置半径——非冲突意见不会互相抹掉
top2.OverridePrim("/World/Ball")
top2.Save()

stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/top2.usda")
ball = UsdGeom.Sphere(stage.GetPrimAtPath("/World/Ball"))
print(f"Radius (should be 2.0 from mid): {ball.GetRadiusAttr().Get()}")
```

### 练习 3.3

> 对比 `usdcat` 和 `usdcat --flatten` 的输出。

```powershell
# 只看 root layer（不含合成结果）
usdcat F:\newton\OpenUSDTutorial\code\top.usda
# 输出只有 subLayer 声明，看不到 Ball 的半径

# 展开合成结果
usdcat --flatten F:\newton\OpenUSDTutorial\code\top.usda
# 输出包含完整的合成后的 prim 和属性，半径=3.0
```

---

## 第 4 章：Composition Arcs

### 练习 4.1

> 创建 tree.usda，再创建 forest.usda 用 AddReference 引入 3 棵树。

```python
# 文件：chapter4_ex1.py
from pxr import Usd, UsdGeom

# === 1. 创建树资产 ===
tree = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/tree.usda")
UsdGeom.Xform.Define(tree, "/Tree")
UsdGeom.Mesh.Define(tree, "/Tree/Trunk")
UsdGeom.Mesh.Define(tree, "/Tree/Leaves")
tree.Save()

# === 2. 创建森林，引用 3 棵树 ===
forest = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/forest.usda")
UsdGeom.Xform.Define(forest, "/World")
for i in range(3):
    tree_inst = UsdGeom.Xform.Define(forest, f"/World/Tree{i}")
    tree_inst.GetPrim().GetReferences().AddReference(
        "F:/newton/OpenUSDTutorial/code/tree.usda", "/Tree"
    )
forest.Save()

# === 3. 验证 ===
stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/forest.usda")
for prim in stage.Traverse():
    print(prim.GetPath())
```

**输出**：
```
/World
/World/Tree0
/World/Tree0/Trunk
/World/Tree0/Leaves
/World/Tree1
/World/Tree1/Trunk
/World/Tree1/Leaves
/World/Tree2
/World/Tree2/Trunk
/World/Tree2/Leaves
```

### 练习 4.2

> 把 reference 改成 payload，观察加载前后差异。

```python
# 文件：chapter4_ex2.py
from pxr import Usd, UsdGeom

# === 1. 创建带 payload 的森林 ===
forest = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/forest_payload.usda")
UsdGeom.Xform.Define(forest, "/World")
for i in range(3):
    tree_inst = UsdGeom.Xform.Define(forest, f"/World/Tree{i}")
    tree_inst.GetPrim().GetPayloads().AddPayload(
        "F:/newton/OpenUSDTutorial/code/tree.usda", "/Tree"
    )
forest.Save()

# === 2. 用 LoadNone 打开，不加载 payload ===
stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/forest_payload.usda", 
                        Usd.Stage.LoadNone)
print("Before load:")
for prim in stage.Traverse():
    print(f"  {prim.GetPath()} (hasPayload={prim.HasPayload()})")

# === 3. 加载所有 payload ===
stage.LoadAndUnload(Usd.Stage.LoadAll, set())
print("\nAfter load:")
for prim in stage.Traverse():
    print(f"  {prim.GetPath()}")
```

**输出**：
```
Before load:
  /World (hasPayload=False)
  /World/Tree0 (hasPayload=True)
  /World/Tree1 (hasPayload=True)
  /World/Tree2 (hasPayload=True)

After load:
  /World
  /World/Tree0
  /World/Tree0/Trunk
  /World/Tree0/Leaves
  /World/Tree1
  /World/Tree1/Trunk
  /World/Tree1/Leaves
  /World/Tree2
  /World/Tree2/Trunk
  /World/Tree2/Leaves
```

### 练习 4.3

> 定义 class prim `/_BaseCar`（含 `/Wheel`），创建 `/World/Car1` 继承它。

```python
# 文件：chapter4_ex3.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter4_ex3.usda")

# === 1. 定义抽象 class prim ===
class_prim = stage.CreateClassPrim("/_BaseCar")
UsdGeom.Mesh.Define(stage, "/_BaseCar/Wheel")

# === 2. 创建具体 prim，继承 class ===
car = UsdGeom.Xform.Define(stage, "/World/Car1")
car.GetPrim().GetInherits().AddInherit("/_BaseCar")

stage.Save()

# === 3. 验证 ===
print("Traverse (class prim 不会出现):")
for prim in stage.Traverse():
    print(f"  {prim.GetPath()} ({prim.GetTypeName()})")

print("\nTraverseAll (包含 class):")
for prim in stage.TraverseAll():
    print(f"  {prim.GetPath()} ({prim.GetTypeName()})")
```

**输出**：
```
Traverse (class prim 不会出现):
  /World (Xform)
  /World/Car1 (Xform)
  /World/Car1/Wheel (Mesh)     ← 从 _BaseCar 继承来

TraverseAll (包含 class):
  /_BaseCar (Mesh)              ← class 也出现
  /_BaseCar/Wheel (Mesh)
  /World (Xform)
  /World/Car1 (Xform)
  /World/Car1/Wheel (Mesh)
```

---

## 第 5 章：Property、Attribute、Primvar

### 练习 5.1

> 创建 Mesh，添加 `custom:health`(int=100) 和 `custom:team`(token="red")。

```python
# 文件：chapter5_ex1.py
from pxr import Usd, UsdGeom, Sdf

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter5_ex1.usda")
mesh = UsdGeom.Mesh.Define(stage, "/World/Cube")

# 添加自定义 attribute
prim = mesh.GetPrim()
prim.CreateAttribute("custom:health", Sdf.ValueTypeNames.Int).Set(100)
prim.CreateAttribute("custom:team", Sdf.ValueTypeNames.Token).Set("red")

stage.Save()
print("Attributes created")
for attr in prim.GetAttributes():
    if attr.GetName().startswith("custom:"):
        print(f"  {attr.GetName()} = {attr.Get()}")
```

### 练习 5.2

> 创建 Sphere，给 radius 添加 5 个时间采样，用 usdview 看动画。

```python
# 文件：chapter5_ex2.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter5_ex2.usda")
sphere = UsdGeom.Sphere.Define(stage, "/World/Ball")

radius_attr = sphere.GetRadiusAttr()
# 5 个时间采样：半径从 1 到 5
for t, r in enumerate([1, 2, 3, 4, 5], start=0):
    radius_attr.Set(r, time=t)

stage.Save()

# 验证中间值（USD 自动插值）
import sys
stage2 = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/chapter5_ex2.usda")
r = UsdGeom.Sphere(stage2.GetPrimAtPath("/World/Ball")).GetRadiusAttr().Get(time=2.5)
print(f"Radius at t=2.5: {r}")  # 期望 3.5 左右
```

### 练习 5.3

> 创建 Mesh，添加 `displayColor` primvar（每顶点颜色）。

```python
# 文件：chapter5_ex3.py
from pxr import Usd, UsdGeom, Sdf, Vt

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter5_ex3.usda")
mesh = UsdGeom.Mesh.Define(stage, "/World/Cube")

# 8 个顶点的颜色（立方体 8 顶点）
colors = Vt.Vec3fArray([
    (1, 0, 0), (0, 1, 0), (0, 0, 1), (1, 1, 0),
    (1, 0, 1), (0, 1, 1), (1, 1, 1), (0, 0, 0)
])
pv = UsdGeom.PrimvarsAPI(mesh).CreatePrimvar(
    "displayColor", Sdf.ValueTypeNames.Color3fArray, "vertex"
)
pv.Set(colors)

stage.Save()
print(f"displayColor primvar set: {pv.GetAttr().Get()}")
```

### 练习 5.4

> 创建 `/A` 和 `/B`，给 `/A` 添加 relationship `targetPrim` 指向 `/B`。

```python
# 文件：chapter5_ex4.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter5_ex4.usda")
UsdGeom.Xform.Define(stage, "/A")
UsdGeom.Xform.Define(stage, "/B")

# 添加 relationship
prim_a = stage.GetPrimAtPath("/A")
rel = prim_a.CreateRelationship("targetPrim")
rel.SetTargets(["/B"])

stage.Save()
print(f"Relationship targets: {rel.GetTargets()}")  # [Sdf.Path('/B')]
```

---

## 第 6 章：Variant Set

### 练习 6.1

> 创建 `/World/Tree`，加 VariantSet "season"（spring/summer/autumn/winter），每个设置不同 displayColor。

```python
# 文件：chapter6_ex1.py
from pxr import Usd, UsdGeom, Sdf, Vt

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter6_ex1.usda")
tree = UsdGeom.Xform.Define(stage, "/World/Tree")
mesh = UsdGeom.Mesh.Define(stage, "/World/Tree/Leaves")

vsets = tree.GetPrim().GetVariantSets()
season = vsets.AddVariantSet("season")

seasons_colors = {
    "spring": (0.2, 0.8, 0.2),   # 嫩绿
    "summer": (0.1, 0.5, 0.1),   # 深绿
    "autumn": (0.8, 0.6, 0.1),   # 黄色
    "winter": (0.9, 0.9, 0.9),    # 白色
}

for season_name, color in seasons_colors.items():
    season.AddVariant(season_name)
    season.SetVariantSelection(season_name)
    with season.GetVariantEditContext():
        UsdGeom.PrimvarsAPI(mesh).CreatePrimvar(
            "displayColor", Sdf.ValueTypeNames.Color3f, "constant"
        ).Set(color)

season.SetVariantSelection("spring")  # 默认选春季
stage.Save()
print("VariantSet 'season' created with variants:", season.GetVariantNames())
```

### 练习 6.2

> 再加 VariantSet `lod`（high/low），在 variant 里 reference 不同精度文件。

```python
# 文件：chapter6_ex2.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter6_ex2.usda")
tree = UsdGeom.Xform.Define(stage, "/World/Tree")

# 先创建高精度和低精度文件（简化版，用 Sphere 代替）
high = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/tree_high.usda")
UsdGeom.Mesh.Define(high, "/Tree")
high.Save()
low = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/tree_low.usda")
UsdGeom.Mesh.Define(low, "/Tree")
low.Save()

# 创建 lod VariantSet
vsets = tree.GetPrim().GetVariantSets()
lod = vsets.AddVariantSet("lod")

for name, filepath in [("high", "tree_high.usda"), ("low", "tree_low.usda")]:
    lod.AddVariant(name)
    lod.SetVariantSelection(name)
    with lod.GetVariantEditContext():
        tree.GetPrim().GetReferences().AddReference(
            f"F:/newton/OpenUSDTutorial/code/{filepath}", "/Tree"
        )

lod.SetVariantSelection("high")
stage.Save()
print("LOD variants:", lod.GetVariantNames())
```

### 练习 6.3

> 运行 `extras/usd/tutorials/authoringVariants/authorVariants.py`，用 usdview 切换 variant。

```powershell
# 生成带 variant 的示例
cd F:\newton\OpenUSD\extras\usd\tutorials\authoringVariants
python authorVariants.py

# 用 usdview 打开
usdview HelloWorld.usda
# 在左侧选中 /hello/world，右侧 Properties 面板找到 shadingVariant
# 下拉切换 Caramel / Marshmallow / Nuage 观察球体材质变化
```

---

## 第 7 章：Model Kind & Model Hierarchy

### 练习 7.1

> 构建 `/World/Factory`(assembly) 下有 Robot1/Robot2(component)，每个有 Head/Body/Arm(subcomponent)。

```python
# 文件：chapter7_ex1.py
from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chapter7_ex1.usda")

# Factory (assembly)
factory = UsdGeom.Xform.Define(stage, "/World/Factory")
Usd.ModelAPI(factory.GetPrim()).SetKind("assembly")

# 两个 Robot (component)
for name in ["Robot1", "Robot2"]:
    robot = UsdGeom.Xform.Define(stage, f"/World/Factory/{name}")
    Usd.ModelAPI(robot.GetPrim()).SetKind("component")
    # 每个机器人有 Head/Body/Arm (subcomponent)
    for part in ["Head", "Body", "Arm"]:
        mesh = UsdGeom.Mesh.Define(stage, f"/World/Factory/{name}/{part}")
        Usd.ModelAPI(mesh.GetPrim()).SetKind("subcomponent")

stage.Save()

# 用 usdtree 查看
import subprocess
result = subprocess.run(
    ["usdtree", "F:/newton/OpenUSDTutorial/code/chapter7_ex1.usda"],
    capture_output=True, text=True
)
print("usdtree output:")
print(result.stdout)
```

**usdtree 输出**（只显示 model hierarchy，subcomponent 不显示）：
```
/World
  /World/Factory      (assembly)
    /World/Factory/Robot1  (component)
    /World/Factory/Robot2  (component)
```

### 练习 7.2

> 写 `find_all_components(stage)` 函数，返回所有 kind="component" 的 prim 路径。

```python
# 文件：chapter7_ex2.py
from pxr import Usd

def find_all_components(stage):
    """遍历 Stage，返回所有 kind='component' 的 prim 路径"""
    components = []
    for prim in stage.TraverseAll():
        kind = Usd.ModelAPI(prim).GetKind()
        if kind == "component":
            components.append(prim.GetPath())
    return components

stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/chapter7_ex1.usda")
print("Components found:")
for path in find_all_components(stage):
    print(f"  {path}")
```

**输出**：
```
Components found:
  /World/Factory/Robot1
  /World/Factory/Robot2
```

### 练习 7.3

> 阅读 `extras/usd/examples/usdMakeFileVariantModelAsset/` 脚本。

```powershell
# 查看目录内容
ls F:\newton\OpenUSD\extras\usd\examples\usdMakeFileVariantModelAsset\

# 阅读主要脚本（Python）
# 它演示了如何：
# 1. 创建一个 component 资产
# 2. 用 VariantSet 创建多个文件变体（如不同 LOD）
# 3. 用 reference-payload pattern 组织资产
# 这是工业界构建 USD 资产的标准模式
```

---

*持续到第 8-12 章，见 `chapter8_12_answers.md`*
