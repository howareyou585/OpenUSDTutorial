from pxr import Usd, UsdGeom
stage = Usd.Stage.Open("F:/newton/OpenUSD/extras/usd/tutorials/convertingLayerFormats/Sphere.usda")
for prim in stage.Traverse():
    print(f'Path: {prim.GetPath()},Type:{prim.GetTypeName()}')