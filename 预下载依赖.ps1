# build_usd.py 依赖预下载脚本
# 用途：用 PowerShell 的 Invoke-WebRequest 预下载所有依赖到 src 目录
#       绕过 curl 的 SSL 问题（Windows 自带 curl 对 GitHub SSL 握手有问题）
# 用法：在 PowerShell 中运行此脚本，然后重新执行 build_usd.py
#
# 原理：build_usd.py 的 DownloadURL() 函数在文件已存在时会跳过下载
#       （见 build_usd.py 第 631-633 行）

$ErrorActionPreference = "Stop"
$srcDir = "F:\newton\USD_Install\src"

if (-not (Test-Path $srcDir)) {
    New-Item -ItemType Directory -Path $srcDir | Out-Null
}

# 所有依赖的 URL 列表（从 build_usd.py 提取）
$urls = @(
    # TBB（Intel Threading Building Blocks）—— 线程库，USD 核心依赖
    "https://github.com/oneapi-src/oneTBB/releases/download/v2020.3/tbb-2020.3-win.zip",
    "https://github.com/oneapi-src/oneTBB/archive/refs/tags/v2020.3.zip",
    "https://github.com/oneapi-src/oneTBB/archive/refs/tags/v2020.3.1.zip",
    "https://github.com/oneapi-src/oneTBB/archive/refs/tags/v2021.12.0.zip",
    # zlib —— 压缩库
    "https://github.com/madler/zlib/archive/v1.3.2.zip",
    # libjpeg-turbo —— JPEG 编解码
    "https://github.com/libjpeg-turbo/libjpeg-turbo/archive/3.1.4.1.zip",
    # libtiff —— TIFF 图像格式
    "https://gitlab.com/libtiff/libtiff/-/archive/v4.7.1/libtiff-v4.7.1.zip",
    # libpng —— PNG 图像格式
    "https://github.com/pnggroup/libpng/archive/refs/tags/v1.6.47.zip",
    # OpenEXR —— HDR 图像格式
    "https://github.com/AcademySoftwareFoundation/openexr/archive/refs/tags/v3.1.13.zip",
    # Ptex —— Pixar 纹理格式
    "https://github.com/wdas/ptex/archive/refs/tags/v2.4.2.zip",
    # c-blosc —— 高速压缩库（OpenVDB 依赖）
    "https://github.com/Blosc/c-blosc/archive/v1.20.1.zip",
    # OpenVDB —— 体积数据
    "https://github.com/AcademySoftwareFoundation/openvdb/archive/refs/tags/v10.1.0.zip",
    # OpenImageIO —— 图像 I/O
    "https://github.com/OpenImageIO/oiio/archive/refs/tags/v2.5.16.0.zip",
    # OpenSubdiv —— 细分曲面（Pixar）
    "https://github.com/PixarAnimationStudios/OpenSubdiv/archive/v3_6_1.zip",
    # Alembic —— 3D 数据交换格式
    "https://github.com/alembic/alembic/archive/refs/tags/1.8.5.zip",
    # Draco —— 3D 几何压缩（Google）
    "https://github.com/google/draco/archive/refs/tags/1.5.6.zip",
    # MaterialX —— 材质定义语言
    "https://github.com/AcademySoftwareFoundation/MaterialX/archive/v1.39.5.zip",
    # Embree —— 光线追踪（CPU）
    "https://github.com/RenderKit/embree/archive/refs/tags/v4.3.3.zip"
)

Write-Output "=== 预下载 build_usd.py 依赖 ==="
Write-Output "下载目录: $srcDir"
Write-Output "依赖数量: $($urls.Count)"
Write-Output ""

$success = 0
$skipped = 0
$failed = @()

foreach ($url in $urls) {
    # 从 URL 提取文件名（最后一段）
    $filename = $url.Split("/")[-1]
    $dest = Join-Path $srcDir $filename

    if (Test-Path $dest) {
        Write-Output "[跳过] $filename （已存在）"
        $skipped++
        continue
    }

    Write-Output "[下载] $filename"
    Write-Output "       来源: $url"
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing -TimeoutSec 300
        $size = (Get-Item $dest).Length
        Write-Output "       完成: $size bytes"
        $success++
    } catch {
        Write-Output "       失败: $($_.Exception.Message)"
        $failed += $filename
        if (Test-Path $dest) { Remove-Item $dest -Force }
    }
}

Write-Output ""
Write-Output "=== 汇总 ==="
Write-Output "成功下载: $success"
Write-Output "已跳过: $skipped"
Write-Output "失败: $($failed.Count)"
if ($failed.Count -gt 0) {
    Write-Output "失败文件:"
    $failed | ForEach-Object { Write-Output "  - $_" }
    Write-Output ""
    Write-Output "请检查网络连接，或手动下载失败的文件到 $srcDir"
} else {
    Write-Output ""
    Write-Output "所有依赖已就绪！现在可以重新运行 build_usd.py："
    Write-Output "  python build_scripts\build_usd.py F:\newton\USD_Install --build-args `"USD,-DPXR_ENABLE_HDF5=OFF`""
}
