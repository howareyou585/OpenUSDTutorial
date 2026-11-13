from pxr import Usd, UsdGeom
stage = Usd.Stage.CreateNew("F:/newton/chapter2_prims.usda")

#方式一：
xform = UsdGeom.Xform.Define(stage,"/World")
mesh = UsdGeom.Mesh.Define(stage,"/World/Robot")
camera = UsdGeom.Camera.Define(stage,"/World/Camera")
#方式二：
stage.Save()
for prim in stage.Traverse():
    print(f"Path:{prim.GetPath()},Type:{prim.GetTypeName()}")

print("=============================")

pseudo_root = stage.GetPseudoRoot()
print(pseudo_root.GetPath())

for child in pseudo_root.GetChildren():
    print(f"Top-level prim:{child.GetPath()}")