from pxr import Usd, UsdGeom
stage = Usd.Stage.CreateNew("F:/newton/myFirstStage.usda")
xform = UsdGeom.Xform.Define(stage, "/HelloWorld")
stage.Save()
print(f"Stage saved. Root layer: {stage.GetRootLayer().realPath}")
print(f"PseudoRoot------>{stage.GetPseudoRoot()}")
