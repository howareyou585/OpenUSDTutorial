# build_usd.py 编译过程问题汇总

> 本文档记录在 Windows 上编译 OpenUSD 26.08 时遇到的编译阶段问题，以及解决方案。
> 下载阶段的问题见 `build_usd下载失败问题汇总.md`。

---

## 问题总览

编译 OpenUSD 时遇到了三类问题，按出现顺序：

| 序号 | 问题 | 阶段 | 根因 |
|---|---|---|---|
| 1 | CL.exe 退出码 1 | 并行编译 | 16 线程并行导致内存不足，CL.exe 被 OOM 杀死 |
| 2 | Python 绑定模块缺失 | install | 并行编译中断导致部分模块未编译完成 |
| 3 | usdview UI 文件生成失败 | install | pyside6-uic 包装脚本找不到 Qt 的 uic.exe |

---

## 问题 1：CL.exe 退出码 1（内存不足）

### 现象

```
error MSB6006: "CL.exe"已退出，代码为 1。
[hdSt.vcxproj]
error MSB6006: "CL.exe"已退出，代码为 1。
[usdImaging.vcxproj]

cmake --build . --config Release --target install -j 16 exited with returncode 1
```

### 诊断

| 实验 | 结果 | 结论 |
|---|---|---|
| 单线程编译 hdSt (`-j 1`) | ✅ 成功 | 代码没问题 |
| 单线程编译 usdImaging (`-j 1`) | ✅ 成功 | 代码没问题 |
| 16 线程编译 (`-j 16`，默认) | ❌ 失败 | 并行导致崩溃 |

### 根因

`build_usd.py` 默认 `-j 16`（16 线程并行编译）。hdSt 模块有 100+ 个 .cpp 文件，每个编译实例加载预编译头需 ~1.5 GB 内存。16 个实例同时运行 → 内存峰值 ~24 GB → 超过系统可用内存 → CL.exe 崩溃。

### 解决方案

降低并行度，手动用 cmake 编译：

```powershell
cd F:\newton\USD_Install\build\OpenUSD
cmake --build . --config Release --target install -j 4
```

根据机器内存选择：

| 机器内存 | 推荐参数 | 预计时间 |
|---|---|---|
| 8 GB | `-j 1` | 2-3 小时 |
| 16 GB | `-j 2` | 1-2 小时 |
| 32 GB | `-j 4` | 1 小时 |
| 64 GB+ | `-j 8` | 40 分钟 |

详见 `build_usd编译内存不足问题汇总.md`。

---

## 问题 2：Python 绑定模块缺失

### 现象

降低并行度重新编译后，install 阶段报错：

```
CMake Error: file INSTALL cannot find
"F:/.../Release/_usd.pyd": File exists.
```

依次缺失的模块：
```
_usd, _usdLux, _usdPhysics, usdShaders, usdcat, sdfdump, sdffilter, usdtree,
usdGeomValidators, usdLuxValidators, usdPhysicsValidators, usdShadeValidators,
usdSkelValidators, usdUtilsValidators, usdchecker, hdGp, hdStorm,
hioOpenEXR, hioAvif, usdProcImaging, usdSkelImaging, usdVolImaging,
usdIrImaging, _usdviewq, sdrGlslfx, usdzip, _irExampleAuthoringCode,
usdObj, usdDancingCubesExample, usdRecursivePayloadsExample,
hdParticleField, hdTiny
```

### 根因

问题 1 的并行编译中断后，大量模块的编译产物未生成。降低并行度重跑时，cmake 只编译了"未完成"的模块，但哪些模块"未完成"判断不完整——某些模块的产物缺失但 cmake 没检测到，直到 install 时才发现。

### 解决方案

用"迭代编译 + install"循环：每次 install 报缺失某个模块时，单独编译该模块，然后重试 install，直到全部完成。

```powershell
$buildDir = "F:\newton\USD_Install\build\OpenUSD"
$maxRounds = 20
for ($r = 1; $r -le $maxRounds; $r++) {
    $out = cmake --install $buildDir --config Release 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Output "INSTALL SUCCESS"
        break
    }
    # 从错误信息提取缺失的文件名
    $lines = $out -split "`n"
    $missingFile = $null
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "cannot find") {
            if ($i + 1 -lt $lines.Count -and $lines[$i+1] -match '"([^"]+)"') {
                $missingFile = $matches[1]
                break
            }
        }
    }
    if (-not $missingFile) { break }
    
    # 从文件名推导 cmake target 名
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($missingFile)
    $target = $filename -replace "^usd_", ""
    
    # 编译缺失的 target
    cmake --build $buildDir --config Release --target $target -j 2
    # 如果 target 名不对，用原始文件名重试
    if ($LASTEXITCODE -ne 0) {
        cmake --build $buildDir --config Release --target $filename -j 2
    }
}
```

### 实际执行结果

经过 15+ 轮迭代，所有缺失模块被逐一编译完成。

---

## 问题 3：usdview UI 文件生成失败

### 现象

install 到最后阶段，usdview 的 UI 文件生成失败：

```
FileNotFoundError: [WinError 2] 系统找不到指定的文件。
error MSB8066: "mainWindowUI.ui"的自定义生成已退出，代码为 1。
```

### 诊断

usdview 的 `.ui` 文件需要用 Qt 的 `uic` 工具转换成 Python 文件。`build_usd.py` 配置用 `pyside6-uic`（PySide6 的包装脚本），但：

| 工具 | 结果 |
|---|---|
| `pyside6-uic.exe`（包装脚本） | ❌ 内部调用 uic 时 WinError 2 |
| `uic.exe`（直接调用） | ✅ 成功 |

### 根因

`pyside6-uic` 是 Python 脚本，内部通过 `subprocess.Popen` 调用 Qt 的 `uic`。但 `uic.exe` 在 `D:\anaconda3\Library\bin\`，不在系统 PATH 中，导致 `Popen` 找不到可执行文件。

### 解决方案

直接用 `uic.exe` 手动生成所有 UI 文件：

```powershell
$uic = "D:\anaconda3\Library\bin\uic.exe"
$uiDir = "F:\newton\OpenUSD\pxr\usdImaging\usdviewq"
$destDir = "F:\newton\USD_Install\build\OpenUSD\pxr\usdImaging\usdviewq"

Get-ChildItem $uiDir -Filter "*.ui" | ForEach-Object {
    $pyName = $_.BaseName + ".py"
    $pyFile = Join-Path $destDir $pyName
    & $uic -g python -o $pyFile $_.FullName
}
```

需生成的 7 个 UI 文件：
- `adjustDefaultMaterialUI.py`
- `adjustFreeCameraUI.py`
- `attributeValueEditorUI.py`
- `mainWindowUI.py`
- `preferencesUI.py`
- `primLegendUI.py`
- `propertyLegendUI.py`

---

## 最终验证

### 产物检查

| 产物 | 路径 | 状态 |
|---|---|---|
| 核心 DLL | `F:\newton\USD_Install\lib\usd_usd.dll` | ✅ |
| Hydra Storm | `F:\newton\USD_Install\lib\usd_hdSt.dll` | ✅ |
| USD Imaging | `F:\newton\USD_Install\lib\usd_usdImaging.dll` | ✅ |
| usdview | `F:\newton\USD_Install\bin\usdview.cmd` | ✅ |
| usdcat | `F:\newton\USD_Install\bin\usdcat.exe` | ✅ |
| Python 绑定 | `F:\newton\USD_Install\Lib\site-packages\pxr\Usd\__init__.py` | ✅ |

### 环境变量配置

```powershell
$env:PATH = "F:\newton\USD_Install\bin;F:\newton\USD_Install\lib;" + $env:PATH
$env:PYTHONPATH = "F:\newton\USD_Install\Lib\site-packages"
```

> **注意**：Python 包在 `Lib\site-packages\pxr`（Anaconda 风格），不是 `lib\python\pxr`。
> 命令行工具是 `.cmd` 和 `.exe`，不是 `.bat`。

### 功能验证

```powershell
# Python 绑定
python -c "from pxr import Usd; print('USD version:', Usd.GetVersion())"
# 输出: USD version: (0, 26, 11)

# 命令行工具
usdcat --help
usdtree --help

# usdview
usdview F:\newton\OpenUSD\extras\usd\tutorials\convertingLayerFormats\Sphere.usda
```

---

## 问题根因链总结

```
问题 1：并行编译内存不足（-j 16）
  ↓ 导致
编译中断，大量模块产物缺失
  ↓ 导致
问题 2：install 时逐个发现缺失模块，需迭代编译
  ↓ 期间发现
问题 3：usdview 的 UI 文件生成依赖 pyside6-uic，但 PATH 缺 uic.exe
```

三个问题层层递进，都是 Windows + Anaconda 环境的兼容性问题。根因是 `build_usd.py` 主要针对 Linux 环境测试，Windows + Anaconda 组合有一些边缘问题。

---

## 给后续编译者的建议

1. **降低并行度**：直接用 `cmake --build ... -j 4`，不要用 `build_usd.py` 的默认 16 线程
2. **预下载依赖**：用 `预下载依赖.ps1` 绕过 curl SSL 问题（见 `build_usd下载失败问题汇总.md`）
3. **准备 uic.exe 路径**：确保 `D:\anaconda3\Library\bin` 在 PATH 中（含 `uic.exe`）
4. **用迭代脚本处理 install**：编译完成后用"迭代编译 + install"循环处理缺失模块
5. **注意 Python 包路径**：Anaconda 环境下 Python 包装在 `Lib\site-packages\pxr`，不是 `lib\python\pxr`

---

*基于 OpenUSD 26.08 + Windows 11 + MSVC 14.44 + Anaconda3 Python 3.13 + PySide6 6.9.2 实际验证。*
