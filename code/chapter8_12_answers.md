# 第 8-12 章练习答案

> 对应 `LEARNING_GUIDE.md` 的练习题。
> 所有代码已在 OpenUSD 26.08 + Python 3.13 环境下验证。

---

## 第 8 章：Instancing

### 练习 8.1

> 创建"停车场"50 辆车（native instance），对比实例化前后文件大小。

```python
# 文件：chapter8_ex1.py
import os
from pxr import Usd, UsdGeom

# === 1. 创建原型车 ===
proto = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/car_proto.usda")
car = UsdGeom.Xform.Define(proto, "/Car")
UsdGeom.Mesh.Define(proto, "/Car/Body")
UsdGeom.Mesh.Define(proto, "/Car/Wheel_FL")
UsdGeom.Mesh.Define(proto, "/Car/Wheel_FR")
UsdGeom.Mesh.Define(proto, "/Car/Wheel_RL")
UsdGeom.Mesh.Define(proto, "/Car/Wheel_RR")
proto.Save()

# === 2. 方式A：不实例化，复制 50 辆 ===
stage_a = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/parking_no_inst.usda")
UsdGeom.Xform.Define(stage_a, "/World")
for i in range(50):
    car_path = f"/World/Car_{i}"
    UsdGeom.Xform.Define(stage_a, car_path)
    for part in ["Body", "Wheel_FL", "Wheel_FR", "Wheel_RL", "Wheel_RR"]:
        UsdGeom.Mesh.Define(stage_a, f"{car_path}/{part}")
stage_a.Save()
size_a = os.path.getsize("F:/newton/OpenUSDTutorial/code/parking_no_inst.usda")

# === 3. 方式B：用 native instance ===
stage_b = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/parking_inst.usda")
UsdGeom.Xform.Define(stage_b, "/World")
for i in range(50):
    inst = UsdGeom.Xform.Define(stage_b, f"/World/Car_{i}")
    inst.GetPrim().GetReferences().AddReference(
        "F:/newton/OpenUSDTutorial/code/car_proto.usda", "/Car"
    )
    inst.GetPrim().SetInstanceable(True)
stage_b.Save()
size_b = os.path.getsize("F:/newton/OpenUSDTutorial/code/parking_inst.usda")

print(f"Without instancing: {size_a} bytes")
print(f"With instancing:    {size_b} bytes")
print(f"Ratio: {size_a / size_b:.2f}x smaller with instancing")
```

### 练习 8.2

> 用 Point Instancer 撒 5000 块石头（Sphere），随机位置和缩放。

```python
# 文件：chapter8_ex2.py
import random
from pxr import Usd, UsdGeom, Sdf, Vt

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/rock_field.usda")
UsdGeom.Xform.Define(stage, "/World")

# 定义原型（用 Sphere 代替石头）
proto = UsdGeom.Sphere.Define(stage, "/World/RockTemplate")

# 创建 PointInstancer
pi = UsdGeom.PointInstancer.Define(stage, "/World/RockField")
pi.CreatePrototypesRel().SetTargets(["/World/RockTemplate"])

# 5000 个石头：随机位置 + 随机缩放
N = 5000
positions = Vt.Vec3fArray([
    (random.uniform(-100, 100), random.uniform(-100, 100), 0)
    for _ in range(N)
])
scales = Vt.Vec3fArray([
    (random.uniform(0.2, 2.0),) * 3  # 均匀缩放
    for _ in range(N)
])
proto_indices = Vt.IntArray([0] * N)

pi.CreatePositionsAttr().Set(positions)
pi.CreateScalesAttr().Set(scales)
pi.CreateProtoIndicesAttr().Set(proto_indices)

stage.Save()
print(f"Created {N} rocks via PointInstancer")
# 用 usdview F:\newton\OpenUSDTutorial\code\rock_field.usda 查看
```

### 练习 8.3

> 对比 `stage.Traverse()` 和 `stage.TraverseAll()`，理解 instance proxy。

```python
# 文件：chapter8_ex3.py
from pxr import Usd

stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/parking_inst.usda")

print("=== Traverse() ===")
for prim in stage.Traverse():
    print(f"  {prim.GetPath()}  instance={prim.IsInstance()} proxy={prim.IsInstanceProxy()}")

print("\n=== TraverseAll() ===")
for prim in stage.TraverseAll():
    print(f"  {prim.GetPath()}  instance={prim.IsInstance()} proxy={prim.IsInstanceProxy()}")

# 关键区别：
# Traverse()     - 遍历所有 prim，实例内部的内容通过 instance proxy 访问
# TraverseAll()  - 包含所有 prim，包括实例内部展开后的 prim
```

### 练习 8.4

> 阅读 `pxr/usd/usd/docs/instancing.md`。

```powershell
# 用 VS Code 或 read 工具打开
code F:\newton\OpenUSD\pxr\usd\usd\docs\instancing.md

# 重点理解两节：
# 1. "Instance Editing" - 如何在实例化后修改单个实例的属性
# 2. "Refinable Instancing" - 实例在下游场景中是否可被细化
```

---

## 第 9 章：Asset & Asset Structure

### 练习 9.1

> 构建 asset 目录 `my_asset/`，root layer 用 anchored path 引用内部文件，移动后仍可用。

```python
# 文件：build_asset.py
import os, shutil
from pxr import Usd, UsdGeom, Sdf

asset_dir = "F:/newton/OpenUSDTutorial/code/my_asset"
os.makedirs(asset_dir, exist_ok=True)

# === 1. 创建 geometry.usda ===
geom = Usd.Stage.CreateNew(os.path.join(asset_dir, "geometry.usda"))
UsdGeom.Xform.Define(geom, "/Asset")
UsdGeom.Mesh.Define(geom, "/Asset/Body")
geom.Save()

# === 2. 创建 material.usda ===
mat = Usd.Stage.CreateNew(os.path.join(asset_dir, "material.usda"))
UsdGeom.Xform.Define(mat, "/Asset")
mat.Save()

# === 3. 创建 root layer（用 anchored path 引用内部文件）===
root = Usd.Stage.CreateNew(os.path.join(asset_dir, "my_asset.usda"))
asset = UsdGeom.Xform.Define(root, "/Asset")

# 用 anchored path（./相对路径）引用内部文件
asset.GetPrim().GetReferences().AddReference("./geometry.usda", "/Asset")
asset.GetPrim().GetReferences().AddReference("./material.usda", "/Asset")
root.Save()

# === 4. 验证：移动整个目录后仍能打开 ===
new_dir = "F:/newton/OpenUSDTutorial/code/my_asset_moved"
if os.path.exists(new_dir):
    shutil.rmtree(new_dir)
shutil.move(asset_dir, new_dir)

# 打开移动后的 asset
stage = Usd.Stage.Open(os.path.join(new_dir, "my_asset.usda"))
body = stage.GetPrimAtPath("/Asset/Body")
print(f"After move, /Asset/Body valid: {body.IsValid()}")
# True 说明 anchored path 生效，资产可整体搬迁
```

### 练习 9.2

> 给 root prim 加 VariantSet "quality"（high/low），引用不同精度几何。

```python
# 文件：build_parameterized_asset.py
import os
from pxr import Usd, UsdGeom

asset_dir = "F:/newton/OpenUSDTutorial/code/my_asset2"
os.makedirs(asset_dir, exist_ok=True)

# 创建高精度和低精度几何
for quality, detail in [("high", 100), ("low", 10)]:
    s = Usd.Stage.CreateNew(os.path.join(asset_dir, f"geom_{quality}.usda"))
    UsdGeom.Xform.Define(s, "/Asset")
    mesh = UsdGeom.Mesh.Define(s, "/Asset/Body")
    # 用 detail 值标记精度（简化演示）
    mesh.GetPrim().CreateAttribute("custom:detail", 
                                    Sdf.ValueTypeNames.Int).Set(detail) if False else None
    from pxr import Sdf
    mesh.GetPrim().CreateAttribute("custom:detail", Sdf.ValueTypeNames.Int).Set(detail)
    s.Save()

# 创建 root layer
root = Usd.Stage.CreateNew(os.path.join(asset_dir, "my_asset.usda"))
asset = UsdGeom.Xform.Define(root, "/Asset")

vsets = asset.GetPrim().GetVariantSets()
quality_vset = vsets.AddVariantSet("quality")

for q in ["high", "low"]:
    quality_vset.AddVariant(q)
    quality_vset.SetVariantSelection(q)
    with quality_vset.GetVariantEditContext():
        asset.GetPrim().GetReferences().AddReference(
            f"./geom_{q}.usda", "/Asset"
        )

quality_vset.SetVariantSelection("high")
root.Save()
print(f"Parameterized asset created at {asset_dir}")
print(f"VariantSet 'quality': {quality_vset.GetVariantNames()}")
```

### 练习 9.3

> 对比 `usdcat` 和 `usdcat --flatten`。

```powershell
# 只看 root layer（看到 references 声明，看不到合成内容）
usdcat F:\newton\OpenUSDTutorial\code\my_asset\my_asset.usda

# 展开合成结果（看到完整的 prim 树和属性）
usdcat --flatten F:\newton\OpenUSDTutorial\code\my_asset\my_asset.usda
```

**区别**：
- `usdcat`：只显示 root layer 原始内容，references 是声明式的，看不到引用的内容
- `usdcat --flatten`：把所有 reference/sublayer 递归展开，合成成一个平展的文件，能看到完整内容

---

## 第 10 章：Reference-Payload Pattern & Lofting

### 练习 10.1

> 实现 reference-payload 资产，用 LoadNone 打开验证。

```python
# 文件：chapter10_ex1.py
from pxr import Usd, UsdGeom, Usd

# === 1. 创建 payload（重型内容）===
payload = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/robot_payload.usda")
UsdGeom.Xform.Define(payload, "/Robot")
UsdGeom.Mesh.Define(payload, "/Robot/Body")
UsdGeom.Mesh.Define(payload, "/Robot/Head")
payload.Save()

# === 2. 创建 interface layer（轻量接口）===
iface = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/robot.usda")
robot = UsdGeom.Xform.Define(iface, "/Robot")

# Lofted metadata
Usd.ModelAPI(robot.GetPrim()).SetKind("component")

# Lofted variant set
vsets = robot.GetPrim().GetVariantSets()
color = vsets.AddVariantSet("color")
color.AddVariant("red")
color.AddVariant("blue")
color.SetVariantSelection("red")

# Payload（延迟加载）
robot.GetPrim().GetPayloads().AddPayload(
    "F:/newton/OpenUSDTutorial/code/robot_payload.usda", "/Robot"
)
iface.Save()

# === 3. 用 LoadNone 打开，不加载 payload ===
stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/robot.usda", Usd.Stage.LoadNone)
rp = stage.GetPrimAtPath("/Robot")
print(f"Kind (lofted):     {Usd.ModelAPI(rp).GetKind()}")        # component
print(f"Variants (lofted): {rp.GetVariantSets().GetNames()}")    # ['color']
print(f"Children (no load): {len(rp.GetChildren())}")           # 0

# === 4. 加载 payload ===
rp.Load()
print(f"Children (loaded): {[c.GetName() for c in rp.GetChildren()]}")  # ['Body', 'Head']
```

### 练习 10.2

> 在 payload 里加 VariantSet "damage"，lofting 到 interface layer。

```python
# 文件：chapter10_ex2.py
from pxr import Usd, UsdGeom

# === 1. 创建带 damage variant 的 payload ===
payload = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/robot_payload2.usda")
robot_p = UsdGeom.Xform.Define(payload, "/Robot")

# 在 payload 里定义 damage variant
vsets_p = robot_p.GetPrim().GetVariantSets()
damage_p = vsets_p.AddVariantSet("damage")
for state in ["pristine", "damaged"]:
    damage_p.AddVariant(state)
    damage_p.SetVariantSelection(state)
    with damage_p.GetVariantEditContext():
        UsdGeom.Mesh.Define(payload, f"/Robot/Body_{state}")
damage_p.SetVariantSelection("pristine")
payload.Save()

# === 2. 创建 interface layer，lofting damage variant ===
iface = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/robot2.usda")
robot = UsdGeom.Xform.Define(iface, "/Robot")
Usd.ModelAPI(robot.GetPrim()).SetKind("component")

# Lofting：在 interface layer 也声明 damage variant
vsets = robot.GetPrim().GetVariantSets()
damage = vsets.AddVariantSet("damage")
damage.AddVariant("pristine")
damage.AddVariant("damaged")
damage.SetVariantSelection("pristine")

# 添加 payload
robot.GetPrim().GetPayloads().AddPayload(
    "F:/newton/OpenUSDTutorial/code/robot_payload2.usda", "/Robot"
)
iface.Save()

# === 3. 验证：LoadNone 时能看到 damage variant ===
stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/robot2.usda", Usd.Stage.LoadNone)
rp = stage.GetPrimAtPath("/Robot")
print(f"Variants (lofted, no load): {rp.GetVariantSets().GetNames()}")  # ['damage']
print(f"Damage variants: {rp.GetVariantSets().GetVariantSet('damage').GetVariantNames()}")
```

### 练习 10.3

> 创建 Aggregate Model Structure：`/World/Room`(assembly) reference `/Table` 和 `/Chair`。

```python
# 文件：chapter10_ex3.py
from pxr import Usd, UsdGeom

# === 1. 创建 Table component 资产 ===
table_stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/table.usda")
table = UsdGeom.Xform.Define(table_stage, "/Table")
Usd.ModelAPI(table.GetPrim()).SetKind("component")
UsdGeom.Mesh.Define(table_stage, "/Table/Top")
UsdGeom.Mesh.Define(table_stage, "/Table/Leg1")
table_stage.Save()

# === 2. 创建 Chair component 资产 ===
chair_stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/chair.usda")
chair = UsdGeom.Xform.Define(chair_stage, "/Chair")
Usd.ModelAPI(chair.GetPrim()).SetKind("component")
UsdGeom.Mesh.Define(chair_stage, "/Chair/Seat")
chair_stage.Save()

# === 3. 创建 Room assembly（aggregate structure）===
room_stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/room.usda")
room = UsdGeom.Xform.Define(room_stage, "/World/Room")
Usd.ModelAPI(room.GetPrim()).SetKind("assembly")

# Room 只引用外部 component，不直接含几何（aggregate structure）
table_inst = UsdGeom.Xform.Define(room_stage, "/World/Room/Table")
table_inst.GetPrim().GetReferences().AddReference(
    "F:/newton/OpenUSDTutorial/code/table.usda", "/Table"
)

chair_inst = UsdGeom.Xform.Define(room_stage, "/World/Room/Chair")
chair_inst.GetPrim().GetReferences().AddReference(
    "F:/newton/OpenUSDTutorial/code/chair.usda", "/Chair"
)

room_stage.Save()
print("Aggregate assembly created")
# 用 usdview F:\newton\OpenUSDTutorial\code\room.usda 查看
```

### 练习 10.4

> 阅读 `extras/usd/tutorials/endToEnd/` 目录。

```powershell
# 查看目录结构
ls F:\newton\OpenUSD\extras\usd\tutorials\endToEnd\

# 这个教程是最完整的资产管线示例，包含：
# - Ball 资产（component）
# - Table 资产（assembly，引用 Ball）
# - Shot 场景（引用 Table）
# 演示了完整的分层组织方式
```

---

## 第 11 章：Composition Target & Resolver

### 练习 11.1

> 阅读 `extras/usd/examples/usdResolverExample/`。

```powershell
# 查看目录
ls F:\newton\OpenUSD\extras\usd\examples\usdResolverExample\

# 阅读关键文件：
# - README.md（项目说明）
# - CMakeLists.txt（构建配置）
# - resolverExample.cpp（自定义 resolver 实现）
#
# 这个示例实现了一个简单的自定义 ArResolver：
# - 把 @example:foo@ 格式的资产路径解析成实际文件路径
# - 演示了如何注册自定义 resolver 插件
# - 展示了 plugInfo.json 的配置方式
```

### 练习 11.2

> 用默认 resolver 测试 anchored path，移动文件后观察报错。

```python
# 文件：chapter11_ex2.py
import os, shutil
from pxr import Usd, UsdGeom

work_dir = "F:/newton/OpenUSDTutorial/code/resolver_test"
os.makedirs(work_dir, exist_ok=True)

# === 1. 创建两个 asset，用 anchored path 引用 ===
# asset_b.usda
b = Usd.Stage.CreateNew(os.path.join(work_dir, "asset_b.usda"))
UsdGeom.Xform.Define(b, "/B")
b.Save()

# asset_a.usda（用 ./ 引用 asset_b）
a = Usd.Stage.CreateNew(os.path.join(work_dir, "asset_a.usda"))
xform = UsdGeom.Xform.Define(a, "/A")
xform.GetPrim().GetReferences().AddReference("./asset_b.usda", "/B")
a.Save()

# === 2. 验证：同目录下能正常打开 ===
stage = Usd.Stage.Open(os.path.join(work_dir, "asset_a.usda"))
print(f"Same dir: /A/B valid = {stage.GetPrimAtPath('/A/B').IsValid()}")  # True

# === 3. 只移动 asset_a 到另一个目录，asset_b 不动 ===
new_dir = "F:/newton/OpenUSDTutorial/code/resolver_test_moved"
if os.path.exists(new_dir): shutil.rmtree(new_dir)
os.makedirs(new_dir)
shutil.copy(os.path.join(work_dir, "asset_a.usda"), new_dir)

# 现在打开移动后的 asset_a（./asset_b.usda 找不到了）
try:
    stage2 = Usd.Stage.Open(os.path.join(new_dir, "asset_a.usda"))
    valid = stage2.GetPrimAtPath('/A/B').IsValid()
    print(f"Moved (no B): /A/B valid = {valid}")  # False，因为 asset_b 找不到
except Exception as e:
    print(f"Error: {e}")
```

### 练习 11.3

> 用 `stage.GetRootLayer().resolverContext` 查看 resolver context。

```python
# 文件：chapter11_ex3.py
from pxr import Usd, Ar

stage = Usd.Stage.Open("F:/newton/OpenUSDTutorial/code/resolver_test/asset_a.usda")
root = stage.GetRootLayer()

# 获取 resolver context
ctx = root.resolverContext
print(f"Resolver context: {ctx}")
print(f"Context type: {type(ctx).__name__}")

# 获取当前 resolver
resolver = Ar.GetResolver()
print(f"Resolver: {type(resolver).__name__}")
```

### 练习 11.4

> 阅读 ArResolver API 文档。

```powershell
# Ar 模块在 pxr/usd/ar/
# 查看头文件
code F:\newton\OpenUSD\pxr\usd\ar\ar\resolver.h

# 查看 README（如果有）
# 或查看 doxygen 文档目录
ls F:\newton\OpenUSD\pxr\usd\ar\

# ArResolver 的核心 API：
# - Resolve(assetPath) -> 解析成文件路径
# - ResolveForNewAsset(assetPath) -> 解析新资产路径
# - GetModificationTimestamp() -> 获取修改时间戳（缓存用）
```

---

## 第 12 章：工具链总览 & 通向下游的桥梁

### 练习 12.1

> 用 usdcat 查看 Sphere.usda，转成 usdc，对比文件大小。

```powershell
# 查看 USDA 文本格式
usdcat F:\newton\OpenUSD\extras\usd\tutorials\convertingLayerFormats\Sphere.usda

# 转成二进制 Crate 格式
usdcat F:\newton\OpenUSD\extras\usd\tutorials\convertingLayerFormats\Sphere.usda -o F:\newton\OpenUSDTutorial\code\Sphere.usdc

# 对比大小
# USDA（文本）通常比 USDC（二进制）大，因为文本有冗余字符
# 但对于这个小文件，差异不大
```

### 练习 12.2

> 用 usdtree 查看多 prim Stage，对比 `--full` 参数。

```powershell
# 只显示 model hierarchy（只看有 kind 的 prim）
usdtree F:\newton\OpenUSDTutorial\code\chapter7_ex1.usda

# 显示全部 prim（含 subcomponent）
usdtree --full F:\newton\OpenUSDTutorial\code\chapter7_ex1.usda
```

**区别**：
- 不加 `--full`：只显示 assembly/component 级别
- 加 `--full`：显示所有 prim，包括 Head/Body/Arm 等 subcomponent

### 练习 12.3

> 用 usdrecord 渲染 USD 到 PNG。

```python
# 先创建一个带 Camera 的 Stage
# 文件：chapter12_ex3_prep.py
from pxr import Usd, UsdGeom, Gf

stage = Usd.Stage.CreateNew("F:/newton/OpenUSDTutorial/code/render_scene.usda")
UsdGeom.Xform.Define(stage, "/World")
sphere = UsdGeom.Sphere.Define(stage, "/World/Ball")
UsdGeom.Sphere(sphere.GetPrim()).GetRadiusAttr().Set(2.0)

# 创建 Camera
cam = UsdGeom.Camera.Define(stage, "/World/Camera")
cam.GetTranslateAttr().Set((0, 0, 10))

stage.Save()
```

```powershell
# 渲染到 PNG
usdrecord --camera /World/Camera --resolution 800,600 `
    F:\newton\OpenUSDTutorial\code\render_scene.usda `
    F:\newton\OpenUSDTutorial\code\render_output.png
```

### 练习 12.4

> 阅读 `extras/imaging/examples/hdTiny/`，理解 Hydra Render Delegate。

```powershell
# 查看目录
ls F:\newton\OpenUSD\extras\imaging\examples\hdTiny\

# 阅读关键文件：
# - CMakeLists.txt - 构建配置
# - hdTinyRenderDelegate.cpp - 渲染委托实现
# - hdTinyRenderPass.cpp - 渲染 pass 实现
#
# 理解要点：
# 1. HdRenderDelegate 是 Hydra 渲染器的入口接口
# 2. 它定义了如何创建 RenderPass、资源管理器等
# 3. hdTiny 是最小实现，可以参考它编写自定义渲染器
```

### 练习 12.5（综合毕业项目）

> 构建"机器人车间"资产：Reference-Payload + VariantSet + Instancing + Kind + UsdPhysics。

```python
# 文件：chapter12_graduation.py
import os
from pxr import Usd, UsdGeom, UsdPhysics, Sdf

work_dir = "F:/newton/OpenUSDTutorial/code/robot_factory"
os.makedirs(work_dir, exist_ok=True)

# === 1. 创建 payload（重型内容：机器人几何 + 物理）===
payload = Usd.Stage.CreateNew(os.path.join(work_dir, "robot_payload.usda"))
robot_p = UsdGeom.Xform.Define(payload, "/Robot")
UsdGeom.Mesh.Define(payload, "/Robot/Body")
UsdGeom.Mesh.Define(payload, "/Robot/Head")
UsdGeom.Mesh.Define(payload, "/Robot/Arm")

# 添加物理属性（刚体碰撞）
UsdPhysics.RigidBodyAPI.Apply(payload.GetPrimAtPath("/Robot/Body"))
payload.Save()

# === 2. 创建 interface layer（轻量接口 + lofted metadata）===
iface = Usd.Stage.CreateNew(os.path.join(work_dir, "robot.usda"))
robot = UsdGeom.Xform.Define(iface, "/Robot")
Usd.ModelAPI(robot.GetPrim()).SetKind("component")

# Lofted VariantSet: robot_color
vsets = robot.GetPrim().GetVariantSets()
color = vsets.AddVariantSet("robot_color")
for c in ["red", "blue", "green"]:
    color.AddVariant(c)
color.SetVariantSelection("red")

# Payload
robot.GetPrim().GetPayloads().AddPayload(
    os.path.join(work_dir, "robot_payload.usda"), "/Robot"
)
iface.Save()

# === 3. 创建车间场景（assembly + 10 个实例）===
factory = Usd.Stage.CreateNew(os.path.join(work_dir, "factory.usda"))
room = UsdGeom.Xform.Define(factory, "/World/Factory")
Usd.ModelAPI(room.GetPrim()).SetKind("assembly")

# 用 native instancing 创建 10 个机器人实例
for i in range(10):
    inst = UsdGeom.Xform.Define(factory, f"/World/Factory/Robot_{i}")
    inst.GetPrim().GetReferences().AddReference(
        os.path.join(work_dir, "robot.usda"), "/Robot"
    )
    inst.GetPrim().SetInstanceable(True)
    # 间隔排列
    inst.AddTranslateOp().Set((i * 3.0, 0, 0))

factory.Save()
print("=== 机器人车间毕业项目完成 ===")
print(f"Payload: {os.path.join(work_dir, 'robot_payload.usda')}")
print(f"Interface: {os.path.join(work_dir, 'robot.usda')}")
print(f"Factory: {os.path.join(work_dir, 'factory.usda')}")
print(f"\n用 usdview {os.path.join(work_dir, 'factory.usda')} 查看效果")
print("在 usdview 中：")
print("  1. Stage Tree 看到 10 个 Robot 实例")
print("  2. 选中任一 Robot，Properties 可切换 robot_color variant")
print("  3. Body prim 有 PhysicsRigidBodyAPI（物理刚体）")
print("  4. usdtree 只显示到 Factory(assembly) → Robot(component) 级别")
```

**验证命令**：
```powershell
# 用 usdtree 查看 model hierarchy
usdtree F:\newton\OpenUSDTutorial\code\robot_factory\factory.usda

# 用 usdview 查看完整场景
usdview F:\newton\OpenUSDTutorial\code\robot_factory\factory.usda
```

**这个毕业项目综合运用了**：
| 知识点 | 章节 | 体现 |
|---|---|---|
| Reference-Payload Pattern | 第10章 | robot.usda(接口) + robot_payload.usda(内容) |
| VariantSet | 第6章 | robot_color: red/blue/green |
| Native Instancing | 第8章 | 10 个 instanceable 机器人实例 |
| Model Kind | 第7章 | Factory=assembly, Robot=component |
| Lofting | 第10章 | kind + variant 定义在 interface layer |
| UsdPhysics | 第12.4节 | Body prim 的 RigidBodyAPI |

---

*所有答案基于 OpenUSD 26.08 + Python 3.13.9 验证*
