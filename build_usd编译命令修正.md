# build_usd.py 编译命令常见错误修正

> 本文档记录学习指南 `LEARNING_GUIDE.md` 环境搭建一节中 `build_usd.py` 命令的正确用法。
> 整理自实际执行中遇到的多个报错。

---

## 核心要点（TL;DR）

**最简推荐命令**（学习阶段直接用这个）：

```powershell
python build_scripts\build_usd.py F:\newton\USD_Install
```

- 只需指定一个 `install_dir`，**没有 build_dir 参数**
- 用所有默认选项，自动下载并编译依赖

**带自定义参数的命令**：

```powershell
# install_dir 必须放在 --build-args 之前
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF"
```

---

## 错误 1：`--build-args` 参数格式错误

### 错误现象

```powershell
python build_scripts\build_usd.py --build-args USD "-DPXR_ENABLE_HDF5=OFF" F:\USD_Build F:\USD_Install
```

报错：

```
build_usd.py: error: unrecognized arguments: -DPXR_ENABLE_HDF5=OFF F:\USD_Install
```

### 原因

`--build-args` 接受的是 **`<库名>,<参数>`** 的逗号分隔形式，作为一个整体传递。把 `USD` 和 `"-DPXR_ENABLE_HDF5=OFF"` 当成两个独立参数是错误的。

### 修正

`USD,` 和 `-DPXR_ENABLE_HDF5=OFF` 之间**不能有空格**，用逗号连接：

```powershell
# ❌ 错误：有空格
--build-args USD, -DPXR_ENABLE_HDF5=OFF

# ✅ 正确：逗号连接，无空格
--build-args USD,-DPXR_ENABLE_HDF5=OFF

# ✅ 更稳妥：用引号包起来
--build-args "USD,-DPXR_ENABLE_HDF5=OFF"
```

---

## 错误 2：参数顺序导致 `install_dir` 缺失

### 错误现象

```powershell
python build_scripts\build_usd.py --build-args "USD,-DPXR_ENABLE_HDF5=OFF" F:\newton\USD_Build F:\newton\USD_Install
```

报错：

```
build_usd.py: error: the following arguments are required: install_dir
```

### 原因

两个问题叠加：

1. **`build_usd.py` 只接受一个位置参数 `install_dir`**——没有 `build_dir` 概念。我之前指南里写的 `F:\USD_Build F:\USD_Install` 两个目录是错的。中间编译产物由脚本自动管理，放在 install_dir 旁边。

2. **`--build-args` 用了 `nargs='*'`**（可变数量参数），会贪婪吃掉后续所有位置参数。所以 `--build-args "..."` 后面跟的 `F:\newton\USD_Build F:\newton\USD_Install` 都被当成 build-args 的内容，`install_dir` 就没被赋值。

### 修正

把 `install_dir` 放在 `--build-args` **之前**，或用 `--` 分隔：

```powershell
# ✅ 写法 A：install_dir 放最前（推荐，最清晰）
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF"

# ✅ 写法 B：用 -- 分隔位置参数
python build_scripts\build_usd.py --build-args "USD,-DPXR_ENABLE_HDF5=OFF" -- F:\newton\USD_Install
```

---

## `build_usd.py` 参数顺序规则

从 `--help` 输出的 usage 可以看到：

```
usage: build_usd.py [-h] [-n] [-v | -q] [-j JOBS] [--build BUILD]
                    [--build-variant {debug,release,relwithdebuginfo}]
                    ...
                    [--build-args [BUILD_ARGS ...]]
                    ...
                    install_dir
```

- `install_dir` 是**唯一的位置参数**，必须在最后
- 所有 `--xxx` 都是可选参数
- `--build-args` 用 `nargs='*'`，会吃掉后续所有非 `--` 开头的参数

**安全规则**：位置参数（`install_dir`）要么放在最前，要么用 `--` 分隔。

---

## 正确命令汇总

### 最简形式（推荐学习阶段）

```powershell
python build_scripts\build_usd.py F:\newton\USD_Install
```

### 带自定义 CMake 参数

```powershell
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF"
```

### 多库参数

```powershell
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF" "boost,cxxflags=/std:c++17"
```

### 含多个 CMake 参数的库

```powershell
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_STRICT_BUILD_MODE=ON -DPXR_HEADLESS_TEST_MODE=ON"
```

### 完整可读换行写法

```powershell
python build_scripts\build_usd.py `
    F:\newton\USD_Install `
    --build-args "USD,-DPXR_ENABLE_HDF5=OFF"
```

---

## 常用顶层选项

`--build-args` 是给特定库传 CMake 参数的高级用法。日常编译更常用的是**顶层开关选项**——它们直接控制脚本行为，不需要写 CMake 参数。

| 选项 | 作用 | 建议 |
|---|---|---|
| `--build-monolithic` | 编译成单个动态库 | 性能调试时关闭 |
| `--prefer-speed-over-safety` | Release 优化模式 | 学习阶段推荐 |
| `--no-tests` / `--no-examples` | 关闭测试/示例以加快编译 | 首次编译可加 |
| `--usdview` / `--no-usdview` | 启用/关闭 usdview 编译 | **默认开启**，无需手动指定 |
| `--no-python` | 关闭 Python 绑定 | 不建议，usdview 依赖 Python |
| `--no-imaging` | 关闭 Hydra 渲染框架 | 不建议，usdview 依赖它 |
| `--build-variant release` | 指定构建变体（debug/release/relwithdebuginfo） | 默认 relwithdebuginfo |

### 常见误区：usdview 不需要用 `--build-args`

❌ 错误写法（曾经出现在学习指南里）：

```powershell
# 这种写法是错的：usdview 不是 CMake 参数，是顶层选项
--build-args USD "-DPXR_BUILD_USDVIEW=ON"
```

✅ 正确做法：

- usdview 默认就开启，**什么都不用加**
- 想关闭才用 `--no-usdview`
- 想确认开启可以显式加 `--usdview`，但通常没必要

### 常用选项组合示例

```powershell
# 学习阶段推荐：Release 优化 + 跳过测试，加快编译
python build_scripts\build_usd.py F:\newton\USD_Install --prefer-speed-over-safety --no-tests

# 完整开发：Debug + 全部测试
python build_scripts\build_usd.py F:\newton\USD_Install --build-variant debug

# 关闭 imaging 和 usdview（仅编译核心库，最快）
python build_scripts\build_usd.py F:\newton\USD_Install --no-imaging --no-usdview
```

---

## 支持的库名

`--build-args` 可指定的库名包括：

```
Alembic  Blosc  Draco  Embree  JPEG  MaterialX  OpenColorIO  OpenEXR
OpenImageIO  OpenSubdiv  OpenVDB  PNG  Ptex  TBB  TIFF  USD  boost  oneTBB  zlib
```

---

## 官方帮助

```powershell
python build_scripts\build_usd.py --help
```

帮助中关于 `--build-args` 的说明：

```
Users may specify custom build arguments for libraries using the --build-args
option. This values for this option must take the form <library name>,<option>.

For example:
  build_usd.py --build-args boost,cxxflags=... USD,-DPXR_STRICT_BUILD_MODE=ON ...
  build_usd.py --build-args USD,"-DPXR_STRICT_BUILD_MODE=ON -DPXR_HEADLESS_TEST_MODE=ON" ...
```

---

## 关于 HDF5

- HDF5 是 **Alembic** 的可选依赖，不是 USD 核心的依赖
- 对学习 USD 本身**完全无影响**
- 如果不确定是否需要，建议直接用最简形式，不传 `--build-args`

---

*基于 OpenUSD 26.08 源码库的 build_usd.py 实际验证。*
