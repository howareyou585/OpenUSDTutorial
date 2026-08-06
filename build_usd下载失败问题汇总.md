# build_usd.py 编译下载失败问题汇总

> 本文档记录在 Windows 上执行 `build_usd.py` 编译 OpenUSD 时，依赖下载阶段遇到的 SSL 失败问题，以及解决方案。

---

## 问题现象

执行编译命令：

```powershell
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF"
```

报错：

```
ERROR: Failed to download https://github.com/oneapi-src/oneTBB/releases/download/v2020.3/tbb-2020.3-win.zip:
Failed to run 'curl -s -L -o tbb-2020.3-win.zip.tmp https://github.com/oneapi-src/oneTBB/releases/download/v2020.3/tbb-2020.3-win.zip'
in F:\newton\USD_Install\src (exited with returncode 35).
```

---

## 问题原因

### 根本原因：Windows 自带 curl 的 SSL 握手失败

| 层级 | 说明 |
|---|---|
| **curl 位置** | `C:\Windows\System32\curl.exe`（Windows 10 1803+ 自带） |
| **curl 版本** | 8.21.0，使用 Schannel（Windows SSL 实现） |
| **curl 协议** | 支持 HTTPS，但 Schannel 对 GitHub 的 HTTPS 重定向 SSL 证书处理有问题 |
| **返回码 35** | curl 标准：`CURLE_SSL_CONNECT_ERROR` —— SSL/TLS 握手失败 |

### 为什么 PowerShell 能成功但 curl 不行

| 工具 | SSL 实现 | 结果 |
|---|---|---|
| Windows curl | Schannel（Windows 系统级 SSL） | ❌ 握手失败，返回码 35 |
| PowerShell `Invoke-WebRequest` | .NET HttpWebRequest（独立 SSL 栈） | ✅ 成功，返回 HTTP 200 |

两者用的是**不同的 SSL/TLS 实现**，所以对同一个 HTTPS 服务器行为不一致。

### build_usd.py 的下载器选择逻辑

`build_usd.py`（第 2421-2428 行）按以下优先级选择下载器：

```python
if which("curl"):
    self.downloader = DownloadFileWithCurl        # ← 优先 curl（你的环境卡在这里）
elif Windows() and which("powershell"):
    self.downloader = DownloadFileWithPowershell  # ← 退而求其次用 PowerShell
else:
    self.downloader = DownloadFileWithUrllib      # ← 最后用 Python urllib
```

由于 Windows 系统自带 curl 且在 PATH 中，脚本**始终选择 curl**，但 curl 的 Schannel SSL 握手失败，导致所有依赖下载都报错。

### 影响范围

这不只是 TBB 一个依赖的问题。`build_usd.py` 需要从 GitHub/GitLab 下载 **18 个依赖包**，全部都会因为 curl SSL 问题失败：

```
TBB（3个版本）、zlib、libjpeg-turbo、libtiff、libpng、
OpenEXR、Ptex、c-blosc、OpenVDB、OpenImageIO、
OpenSubdiv、Alembic、Draco、MaterialX、Embree
```

---

## 解决方案

### 思路

`build_usd.py` 的 `DownloadURL()` 函数（第 631-633 行）有缓存逻辑：

```python
if os.path.exists(filename):
    PrintInfo("{0} already exists, skipping download".format(...))
```

**如果文件已存在于 src 目录，就跳过下载。**

所以只需用 PowerShell 的 `Invoke-WebRequest`（SSL 正常）预先把所有依赖下载到 src 目录，重跑 `build_usd.py` 时它会检测到文件存在并跳过下载，直接进入编译阶段。

### 步骤

#### 1. 运行预下载脚本

脚本位置：`F:\newton\学习资料\预下载依赖.ps1`

```powershell
& "F:\newton\学习资料\预下载依赖.ps1"
```

脚本会：
- 用 `Invoke-WebRequest` 下载全部 18 个依赖到 `F:\newton\USD_Install\src\`
- 已存在的文件自动跳过（幂等，可重复运行）
- 下载失败的文件会删除残留，列出清单

#### 2. 重新运行编译命令

```powershell
cd F:\newton\OpenUSD
python build_scripts\build_usd.py F:\newton\USD_Install --build-args "USD,-DPXR_ENABLE_HDF5=OFF"
```

此时所有依赖已就绪，`build_usd.py` 会跳过下载，直接开始编译。

---

## 预下载脚本说明

### 文件

`F:\newton\学习资料\预下载依赖.ps1`

### 工作原理

1. 从 `build_usd.py` 源码中提取所有依赖的 URL（共 18 个）
2. 对每个 URL，用 PowerShell `Invoke-WebRequest` 下载到 `F:\newton\USD_Install\src\`
3. 文件名取 URL 的最后一段（与 `build_usd.py` 的命名规则一致）
4. 已存在的文件跳过，避免重复下载

### 依赖清单

| 依赖 | 用途 | 来源 |
|---|---|---|
| TBB（3个版本） | Intel 线程库，USD 核心依赖 | GitHub oneTBB |
| zlib | 压缩库 | GitHub madler/zlib |
| libjpeg-turbo | JPEG 编解码 | GitHub libjpeg-turbo |
| libtiff | TIFF 图像格式 | GitLab libtiff |
| libpng | PNG 图像格式 | GitHub pnggroup/libpng |
| OpenEXR | HDR 图像格式 | GitHub AcademySoftwareFoundation |
| Ptex | Pixar 纹理格式 | GitHub wdas/ptex |
| c-blosc | 高速压缩库（OpenVDB 依赖） | GitHub Blosc/c-blosc |
| OpenVDB | 体积数据 | GitHub AcademySoftwareFoundation |
| OpenImageIO | 图像 I/O | GitHub OpenImageIO |
| OpenSubdiv | 细分曲面（Pixar） | GitHub PixarAnimationStudios |
| Alembic | 3D 数据交换格式 | GitHub alembic/alembic |
| Draco | 3D 几何压缩（Google） | GitHub google/draco |
| MaterialX | 材质定义语言 | GitHub AcademySoftwareFoundation |
| Embree | CPU 光线追踪 | GitHub RenderKit/embree |

### 特点

- **幂等**：可重复运行，已下载的文件不会重复下载
- **容错**：单个文件下载失败不影响其他文件，最后列出失败清单
- **无需修改系统**：不修改 curl、不修改环境变量、不修改 build_usd.py

---

## 其他可选方案（未采用，仅供参考）

### 方案 B：临时隐藏 curl

让 `build_usd.py` 找不到 curl，回退到 PowerShell 下载器：

```powershell
# 临时把 curl 重命名（需要管理员权限）
Rename-Item "C:\Windows\System32\curl.exe" "C:\Windows\System32\curl.exe.bak"

# 运行编译
python build_scripts\build_usd.py F:\newton\USD_Install

# 编译完成后恢复
Rename-Item "C:\Windows\System32\curl.exe.bak" "C:\Windows\System32\curl.exe"
```

**缺点**：修改系统文件需要管理员权限，有风险，且影响其他需要 curl 的程序。

### 方案 C：安装第三方 curl

安装使用 OpenSSL 而非 Schannel 的 curl（如 chocolatey 或 scoop 的 curl），放到 PATH 前面：

```powershell
choco install curl    # 或 scoop install curl
```

**缺点**：需要安装额外软件，且 PATH 顺序可能影响系统行为。

### 方案 D：配置代理

如果有代理/VPN，配置 curl 使用代理：

```powershell
$env:HTTPS_PROXY = "http://127.0.0.1:7890"    # 替换为你的代理端口
python build_scripts\build_usd.py F:\newton\USD_Install
```

**缺点**：需要有可用的代理服务。

### 方案对比

| 方案 | 难度 | 风险 | 推荐度 |
|---|---|---|---|
| **预下载脚本（方案 A）** | 低 | 无 | ⭐⭐⭐⭐⭐ |
| 临时隐藏 curl（方案 B） | 中 | 高（改系统文件） | ⭐⭐ |
| 安装第三方 curl（方案 C） | 中 | 低 | ⭐⭐⭐ |
| 配置代理（方案 D） | 低 | 无 | ⭐⭐⭐⭐（有代理时） |

---

## 验证结果

预下载脚本执行结果：

```
=== 预下载 build_usd.py 依赖 ===
下载目录: F:\newton\USD_Install\src
依赖数量: 18

[跳过] tbb-2020.3-win.zip （已存在）
[下载] v2020.3.zip ... 完成
[下载] v2020.3.1.zip ... 完成
...（共 17 个新下载）

=== 汇总 ===
成功下载: 17
已跳过: 1
失败: 0
```

全部 18 个依赖就绪，0 失败。可以重新运行 `build_usd.py` 进入编译阶段。

---

*基于 OpenUSD 26.08 源码库的 build_usd.py + Windows 11 + PowerShell 7 实际验证。*
