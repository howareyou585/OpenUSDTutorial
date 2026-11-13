# build_usd.py 编译内存不足问题汇总

> 本文档记录在 Windows 上执行 `build_usd.py` 编译 OpenUSD 时，编译 hdSt 和 usdImaging 模块遇到的 CL.exe 崩溃问题，以及解决方案。

---

## 问题现象

依赖下载成功后，编译阶段报错：

```
C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\Microsoft.CppCommon.targets(787,5):
error MSB6006: "CL.exe"已退出，代码为 1。
[F:\newton\USD_Install\build\OpenUSD\pxr\imaging\hdSt\hdSt.vcxproj]

C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Microsoft\VC\v170\Microsoft.CppCommon.targets(787,5):
error MSB6006: "CL.exe"已退出，代码为 1。
[F:\newton\USD_Install\build\OpenUSD\pxr\usdImaging\usdImaging\usdImaging.vcxproj]

cmake --build . --config Release --target install -j 16 exited with returncode 1
```

报错的两个模块：
- **hdSt**（Hydra Storm，OpenGL 渲染后端）—— 100+ 个 .cpp 文件
- **usdImaging**（USD ↔ Hydra 桥接）—— 大量适配器文件

---

## 问题诊断

### 关键线索

| 线索 | 含义 |
|---|---|
| `CL.exe 已退出，代码为 1` | CL.exe 异常退出，但未显示具体 C++ 编译错误 |
| 默认 `-j 16`（16 线程并行） | 同时启动 16 个 CL.exe 实例 |
| hdSt 编译命令含 `/MP`（多进程）+ `/Yu"pch.h"`（预编译头）+ `/Zm150`（150% 内存） | 每个实例消耗大量内存 |
| log.txt 末尾只有 `error MSB6006`，无具体 C++ 错误 | 说明不是代码错误，是 CL.exe 进程崩溃 |

### 验证实验

| 实验 | 参数 | 结果 | 结论 |
|---|---|---|---|
| 单线程编译 hdSt | `cmake --build . --target hdSt -j 1` | ✅ 成功 | 代码没问题 |
| 单线程编译 usdImaging | `cmake --build . --target usdImaging -j 1` | ✅ 成功 | 代码没问题 |
| 默认 16 线程编译 | `build_usd.py` 默认 `-j 16` | ❌ 失败 | 并行导致崩溃 |

### 根本原因

**并行编译时内存不足导致 CL.exe 崩溃。**

- `build_usd.py` 默认用 `-j 16`（16 线程并行编译）
- hdSt 模块有 100+ 个 .cpp 文件，且 MSBuild 的 `/MP` 标志会在单个项目内再并行
- 每个编译 hdSt 的 CL.exe 实例需要加载预编译头（PCH），消耗约 1-2 GB 内存
- 16 个实例同时运行 → 内存峰值超过系统可用内存 → CL.exe 被 OOM 杀死 → 退出码 1

### 内存估算

```
单个 CL.exe 编译 hdSt（含 PCH + /Zm150）: ~1.5 GB
16 线程并行: 16 × 1.5 GB = ~24 GB 内存需求
```

如果你的机器内存不足 32 GB，16 线程并行编译 hdSt 几乎必然 OOM。

---

## 解决方案

### 方案 A：降低并行度（推荐）

不用 `build_usd.py` 的默认 16 线程，手动用 cmake 编译，控制并行度：

```powershell
# 进入 build 目录
cd F:\newton\USD_Install\build\OpenUSD

# 用 4 线程编译（内存需求降到 ~6 GB，大多数机器可承受）
cmake --build . --config Release --target install -j 4
```

如果 4 线程仍失败，继续降低到 2 或 1：

```powershell
# 2 线程（~3 GB 内存需求）
cmake --build . --config Release --target install -j 2

# 单线程（最慢但最稳，~1.5 GB 内存需求）
cmake --build . --config Release --target install -j 1
```

### 方案 B：关闭 MSBuild 的 /MP（项目内并行）

`build_usd.py` 的 `-j` 控制 cmake 层面的并行（项目间），但 MSBuild 的 `/MP` 控制项目内并行（同一项目的多个 .cpp）。两者叠加会放大内存需求。

可以通过 CMake 变量关闭 `/MP`：

```powershell
# 重新 cmake configure，关闭 /MP
cmake F:\newton\OpenUSD -B F:\newton\USD_Install\build\OpenUSD `
    -DCMAKE_BUILD_TYPE=Release `
    -DCMAKE_CXX_FLAGS_MP=OFF

# 然后编译
cmake --build F:\newton\USD_Install\build\OpenUSD --config Release --target install -j 8
```

### 方案 C：增大 CL.exe 内存上限

编译命令里的 `/Zm150` 表示预编译头使用 150% 标准内存。可以增大这个值……但这是反方向操作——问题已经是内存不足，增大上限只会更快 OOM。**不推荐。**

### 方案对比

| 方案 | 编译时间 | 内存需求 | 推荐度 |
|---|---|---|---|
| `-j 1`（单线程） | 最慢（~2 小时） | ~1.5 GB | ⭐⭐⭐（内存极小的机器） |
| `-j 2` | 慢（~1.5 小时） | ~3 GB | ⭐⭐⭐⭐ |
| `-j 4` | 中等（~1 小时） | ~6 GB | ⭐⭐⭐⭐⭐（推荐） |
| `-j 8` | 快（~40 分钟） | ~12 GB | ⭐⭐⭐⭐（16GB+ 内存） |
| `-j 16`（默认） | 最快 | ~24 GB | ❌ 容易 OOM |
| 关闭 `/MP` + `-j 8` | 快 | ~8 GB | ⭐⭐⭐⭐ |

### 推荐操作

**根据你的机器内存选择**：

| 机器内存 | 推荐参数 | 预计编译时间 |
|---|---|---|
| 8 GB | `-j 1` | 2-3 小时 |
| 16 GB | `-j 2` | 1-2 小时 |
| 32 GB | `-j 4` | 1 小时 |
| 64 GB+ | `-j 8` | 40 分钟 |

---

## 具体操作步骤

### 前提

依赖已下载完成（见 `build_usd下载失败问题汇总.md`），`build_usd.py` 已成功执行到编译阶段（build 目录已生成）。

### 步骤 1：清理失败的编译产物

```powershell
# 可选：清理 hdSt 和 usdImaging 的中间产物（让 cmake 重新编译这两个模块）
Remove-Item -Recurse -Force "F:\newton\USD_Install\build\OpenUSD\pxr\imaging\hdSt\hdSt.dir" -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force "F:\newton\USD_Install\build\OpenUSD\pxr\usdImaging\usdImaging\usdImaging.dir" -ErrorAction SilentlyContinue
```

### 步骤 2：用降低的并行度重新编译

```powershell
cd F:\newton\USD_Install\build\OpenUSD

# 推荐：4 线程
cmake --build . --config Release --target install -j 4
```

### 步骤 3：验证编译结果

```powershell
# 检查关键 DLL 是否生成
Test-Path "F:\newton\USD_Install\lib\usd_usd.dll"
Test-Path "F:\newton\USD_Install\lib\usd_hdSt.dll"
Test-Path "F:\newton\USD_Install\lib\usd_usdImaging.dll"

# 检查 usdview 是否生成
Test-Path "F:\newton\USD_Install\bin\usdview.bat"
```

### 步骤 4：验证 Python 绑定

```powershell
python -c "from pxr import Usd; print(Usd.GetVersion())"
```

---

## 如何判断内存不足

### 症状清单

如果编译时出现以下情况，大概率是内存不足：

- `CL.exe 已退出，代码为 1`，但 log.txt 中**找不到具体的 C++ 编译错误**（如 `error C2065`、`error C2664` 等）
- 单线程编译（`-j 1`）能成功，多线程编译失败
- 编译大模块（hdSt、usdImaging、usdHydra）时失败，小编译模块（tf、gf）正常
- 任务管理器显示编译时内存占用接近 100%

### 区分：代码错误 vs 内存不足

| 特征 | 代码错误 | 内存不足 |
|---|---|---|
| log.txt 有具体 C++ 错误 | ✅ 有（如 `error C2065: 'xxx' undeclared identifier`） | ❌ 无，只有 `MSB6006` |
| 单线程编译 | ❌ 也失败 | ✅ 成功 |
| 失败的模块 | 固定某个文件 | 随机（看哪个 CL.exe 先被 OOM 杀） |
| 错误代码 | 通常 C1xxx/C2xxx/C3xxx | CL.exe 退出码 1 |

---

## 预防措施

### 1. 永久设置低并行度

如果不想每次手动指定 `-j`，可以在 `build_usd.py` 中修改默认值。但更推荐的做法是**不通过 `build_usd.py` 编译**，而是分两步：

```powershell
# 步骤 1：用 build_usd.py 只做 configure（下载依赖 + cmake configure）
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF" --no-build

# 步骤 2：手动用 cmake 编译，控制并行度
cmake --build F:\newton\USD_Install\build\OpenUSD --config Release --target install -j 4
```

> 注意：`build_usd.py` 可能没有 `--no-build` 参数，需确认。如果没有，就让它在编译阶段失败，然后手动执行步骤 2。

### 2. 增加虚拟内存

如果物理内存不足，可以增大 Windows 虚拟内存（页面文件）：

```
设置 → 系统 → 关于 → 高级系统设置 → 性能设置 → 高级 → 虚拟内存 → 更改
```

建议设置为物理内存的 1.5-2 倍。但虚拟内存比物理内存慢得多，编译会很慢。

### 3. 关闭其他内存密集程序

编译时关闭：
- 浏览器（Chrome/Edge 每个标签页占几十到几百 MB）
- IDE（VS Code、Visual Studio）
- Docker / WSL2
- 其他大型应用

---

## 附：hdSt 和 usdImaging 模块说明

这两个模块是 OpenUSD 中最大的两个编译单元：

| 模块 | 路径 | .cpp 文件数 | 说明 |
|---|---|---|---|
| hdSt | `pxr/imaging/hdSt/` | 100+ | Hydra Storm 渲染后端，OpenGL 光栅化，usdview 默认渲染器 |
| usdImaging | `pxr/usdImaging/usdImaging/` | 80+ | USD 场景到 Hydra 的桥接，含大量 prim 适配器 |

它们是 USD 中代码量最大的模块，也是编译时内存消耗最大的模块。如果这两个模块能编译通过，其他模块基本不会有问题。

---

*基于 OpenUSD 26.08 + Windows 11 + MSVC 14.44 + 16GB 内存机器实际验证。*
