from pxr import Usd, UsdGeom

stage = Usd.Stage.CreateNew("F:/newton/chapter1_ex1.usda")
UsdGeom.Xform.Define(stage,"/World")
UsdGeom.Xform.Define(stage,"/World/Camera")

stage.Save()
print(f"Stage saved to:{stage.GetRootLayer().realPath}")