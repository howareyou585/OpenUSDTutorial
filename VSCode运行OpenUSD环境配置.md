# VS Code 运行 OpenUSD 示例的环境配置

> 本文档记录在 VS Code 中运行 OpenUSD Python 示例代码时遇到的环境配置问题，以及最终解决方案。

---

## 问题现象

在 VS Code Terminal 中运行 USD 示例代码：

```powershell
cd F:\newton\OpenUSDTutorial\code
python .\chapter1_create_stage.py
```

报错经历两个阶段：

### 阶段 1：找不到 pxr 模块

```
ModuleNotFoundError: No module named 'pxr'
```

### 阶段 2：找到 pxr 但 DLL 加载失败

```
ImportError: cannot import name 'Usd' from 'pxr' (unknown location)
```

或更详细的：

```
ImportError: DLL load failed while importing _tf: 找不到指定的模块。
```

---

## 环境背景

### 系统中的 Python

| Python | 路径 | 版本 |
|---|---|---|
| Anaconda | `D:\anaconda3\python.exe` | 3.13.9 |
| 独立安装 | `D:\Python\Python313\python.exe` | 3.13.9 |
| Windows Store | `C:\Users\...\WindowsApps\python.exe` | — |

### USD 编译时的 Python

USD 26.08 编译时用的是 Anaconda Python（`D:/anaconda3/python.exe`），生成的 `_usd.pyd` 依赖 `python313.dll`。

### USD 安装位置

| 内容 | 路径 |
|---|---|
| DLL 库 | `F:\newton\USD_Install\lib\*.dll` |
| 命令行工具 | `F:\newton\USD_Install\bin\usdview.cmd` 等 |
| Python 包 | `F:\newton\USD_Install\Lib\site-packages\pxr\` |

### 关键事实

USD 的 Python 包**没有装在 Anaconda 或任何 Python 的默认 site-packages 里**，而是在独立的 `F:\newton\USD_Install\Lib\site-packages\` 下。Python 要找到它，**必须依赖环境变量**。

---

## 问题根因

### 核心原理：USD Python 绑定需要两个环境变量同时设置

USD 的 Python 绑定由两部分组成：

```
pxr/Usd/__init__.py    ← Python 入口文件（纯 Python）
pxr/Usd/_usd.pyd       ← C++ 编译的扩展模块（实际干活的是它）
```

`_usd.pyd` 是 C++ 编译的动态链接库，它**依赖** `F:\newton\USD_Install\bin\` 和 `lib\` 下的大量 DLL（如 `usd_usd.dll`、`usd_tf.dll` 等）。

| 环境变量 | 作用 | 不设的后果 |
|---|---|---|
| `PYTHONPATH` | 让 Python 解释器找到 `pxr` 包的位置 | `ModuleNotFoundError: No module named 'pxr'` |
| `PATH` | 让 Windows 找到 `_usd.pyd` 依赖的 DLL | `ImportError: DLL load failed` |

**两者缺一不可。** 只设 PYTHONPATH 不设 PATH，Python 找到 pxr 包但加载 .pyd 时 DLL 找不到；只设 PATH 不设 PYTHONPATH，DLL 都在但 Python 不知道去哪找 pxr 包。

### 为什么 Windows 环境变量设了但不生效

```
通过 Windows 系统设置或 setx 设置环境变量
        ↓
写入 Windows 注册表（永久保存）
        ↓
⚠️ 已运行的进程不受影响（包括 VS Code）
        ↓
VS Code Terminal 继承 VS Code 进程的旧环境
        ↓
Python 读不到 PYTHONPATH → 报错
```

**Windows 环境变量修改后，必须重启进程才能生效。** VS Code 如果在设置环境变量之前就打开了，它的 Terminal 继承的是旧环境。

### VS Code settings.json 的 `${env:PATH}` 坑

最初尝试用 `terminal.integrated.env.windows` 设置环境变量：

```json
"terminal.integrated.env.windows": {
    "PYTHONPATH": "F:\\newton\\USD_Install\\Lib\\site-packages",
    "PATH": "F:\\newton\\USD_Install\\bin;F:\\newton\\USD_Install\\lib;${env:PATH}"
}
```

**问题**：`${env:PATH}` 变量替换在某些 VS Code 版本下不工作。如果不工作，整个 PATH 值会变成字面量 `${env:PATH}`，导致 PATH 被破坏，系统命令全部找不到。

即使 `${env:PATH}` 不写，直接写 PATH 值，会**覆盖**系统原有 PATH（不是追加），导致系统命令丢失。

### 最终验证的测试结果

| 测试 | PYTHONPATH | PATH | 结果 |
|---|---|---|---|
| 都不设 | ❌ | ❌ | `ModuleNotFoundError: No module named 'pxr'` |
| 只设 PYTHONPATH | ✅ | ❌ | `ImportError: DLL load failed while importing _tf` |
| 都设 | ✅ | ✅ | ✅ `USD version: (0, 26, 11)` |

---

## 解决方案：Terminal Profile + 启动命令

在 `.vscode/settings.json` 中配置自定义 Terminal profile，启动时用 PowerShell 命令设置环境变量，**保留系统原有 PATH**：

### 文件位置

`F:\newton\OpenUSDTutorial\.vscode\settings.json`

### 完整内容

```json
{
    // 指定 Python 解释器为 Anaconda（USD 编译时用的）
    "python.defaultInterpreterPath": "D:\\anaconda3\\python.exe",

    // 让 Python 扩展能找到 USD 的 Python 包（用于代码补全/类型检查）
    "python.analysis.extraPaths": [
        "F:\\newton\\USD_Install\\Lib\\site-packages"
    ],

    // 自定义 Terminal：用脚本初始化环境变量，保留系统原有 PATH
    "terminal.integrated.profiles.windows": {
        "USD PowerShell": {
            "path": "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe",
            "args": [
                "-NoExit",
                "-Command",
                "$env:PYTHONPATH='F:\\newton\\USD_Install\\Lib\\site-packages'; $env:PATH='F:\\newton\\USD_Install\\bin;F:\\newton\\USD_Install\\lib;'+$env:PATH; cd 'F:\\newton\\OpenUSDTutorial'"
            ]
        }
    },
    "terminal.integrated.defaultProfile.windows": "USD PowerShell",

    // USDA 文件语法高亮
    "files.associations": {
        "*.usda": "yaml",
        "*.usd": "yaml",
        "*.usdc": "yaml"
    }
}
```

### 配置项说明

| 配置项 | 作用 |
|---|---|
| `python.defaultInterpreterPath` | 指定 Python 扩展用的解释器，确保 VS Code 不会选错 Python |
| `python.analysis.extraPaths` | 让 Python 语言服务器（Pylance）能找到 pxr 包，用于代码补全和类型检查 |
| `terminal.integrated.profiles.windows` | 定义自定义 Terminal profile，启动时执行 PowerShell 命令设置环境变量 |
| `terminal.integrated.defaultProfile.windows` | 把自定义 profile 设为默认 Terminal |
| `files.associations` | 让 VS Code 用 YAML 语法高亮 .usda 文件 |

### Terminal 启动命令解析

```powershell
$env:PYTHONPATH='F:\newton\USD_Install\Lib\site-packages';     # 设置 PYTHONPATH
$env:PATH='F:\newton\USD_Install\bin;F:\newton\USD_Install\lib;'+$env:PATH;  # 在 PATH 前面追加 USD 路径（保留原有 PATH）
cd 'F:\newton\OpenUSDTutorial'                                   # 切换到工作目录
```

**关键**：`+$env:PATH` 表示在 USD 路径后面追加系统原有 PATH，不会覆盖。

---

## 使用方法

### 首次配置

1. 确保 `F:\newton\OpenUSDTutorial\.vscode\settings.json` 内容如上
2. **完全关闭 VS Code**（任务管理器确认无 Code.exe 残留）
3. 重新打开 VS Code，打开 `F:\newton\OpenUSDTutorial` 文件夹

### 日常使用

1. 打开 VS Code Terminal（``Ctrl+` `` 或菜单 Terminal → New Terminal）
2. Terminal 会自动用 "USD PowerShell" profile 启动，环境变量已就绪
3. 验证环境：

```powershell
# 确认环境变量
echo $env:PYTHONPATH
# 应输出: F:\newton\USD_Install\Lib\site-packages

# 验证 Python 导入
python -c "from pxr import Usd; print(Usd.GetVersion())"
# 应输出: (0, 26, 11)

# 验证命令行工具
(Get-Command usdview).Source
# 应输出: F:\newton\USD_Install\bin\usdview.cmd
```

4. 运行示例代码：

```powershell
cd F:\newton\OpenUSDTutorial\code
python .\chapter1_create_stage.py
```

### 如果 Terminal 没有自动用 USD PowerShell

手动选择：Terminal 面板右上角下拉箭头 → 选择 "USD PowerShell"

---

## 故障排查

### 问题：Terminal 启动后 PYTHONPATH 还是空的

**检查**：Terminal 右上角是否显示 "USD PowerShell"。如果显示 "PowerShell" 或 "1: powershell"，说明没用自定义 profile。

**解决**：删除当前 Terminal，重新打开。或在 Terminal 面板右上角下拉菜单选 "USD PowerShell"。

### 问题：`python.defaultInterpreterPath` 不生效

VS Code Python 扩展可能缓存了旧解释器。

**解决**：
1. `Ctrl+Shift+P` → 输入 "Python: Select Interpreter"
2. 选择 `D:\anaconda3\python.exe`

### 问题：代码补全看不到 pxr 模块

`python.analysis.extraPaths` 需要重启 Python 语言服务器。

**解决**：
1. `Ctrl+Shift+P` → 输入 "Python: Restart Language Server"
2. 等待右下角状态栏从 "Analyzing" 变为就绪

### 问题：换了电脑或 USD 安装路径变了

修改 `.vscode/settings.json` 中所有 `F:\newton\USD_Install` 路径为新路径。

### 问题：不想用 Terminal profile，想用系统环境变量

也可以，但需要：
1. 用 `setx` 设置永久环境变量（已做过）
2. **每次修改后完全重启 VS Code**

```powershell
setx PYTHONPATH "F:\newton\USD_Install\Lib\site-packages"
# PATH 需要手动在系统设置面板追加，不能用 setx 覆盖
```

但这种方式不如 `.vscode/settings.json` 可靠——settings.json 随项目走，换机器自动生效。

---

## 为什么不用其他方案

### 方案对比

| 方案 | 优点 | 缺点 | 推荐度 |
|---|---|---|---|
| **Terminal profile（采用）** | 可靠、随项目走、保留系统 PATH | 配置稍复杂 | ⭐⭐⭐⭐⭐ |
| `terminal.integrated.env.windows` | 简单 | `${env:PATH}` 不稳定，可能覆盖系统 PATH | ⭐⭐ |
| 系统环境变量 + 重启 VS Code | 全局生效 | 依赖重启、换机器要重设 | ⭐⭐⭐ |
| 每个 .py 文件开头加 `sys.path.insert` | 不依赖环境 | 每个文件都要加 | ⭐ |

### 为什么不用 `terminal.integrated.env.windows`

```json
// ❌ 这个方案有坑
"terminal.integrated.env.windows": {
    "PYTHONPATH": "F:\\newton\\USD_Install\\Lib\\site-packages",
    "PATH": "F:\\newton\\USD_Install\\bin;F:\\newton\\USD_Install\\lib;${env:PATH}"
}
```

| 问题 | 说明 |
|---|---|
| `${env:PATH}` 不可靠 | 某些 VS Code 版本不解析这个变量，导致 PATH 变成字面量 |
| 不写 `${env:PATH}` 会覆盖 | PATH 被设成只有 USD 路径，系统命令（如 `git`、`code`）全部找不到 |
| 写了 `${env:PATH}` 不生效 | 整个 env.windows 配置可能被忽略，PYTHONPATH 也不设 |

### 为什么不用系统环境变量

| 问题 | 说明 |
|---|---|
| 需要重启进程 | 修改后必须完全关闭并重启 VS Code |
| 不随项目走 | 换机器、给别人项目，都要手动设置 |
| 容易忘记 | 过段时间忘了设置过，又踩坑 |

---

## 附录：USD Python 绑定的加载原理

### 加载链

```
from pxr import Usd
      ↓
Python 在 PYTHONPATH 指向的目录找到 pxr/Usd/__init__.py
      ↓
__init__.py 执行 from pxr import Tf
      ↓
Python 找到 pxr/Tf/__init__.py
      ↓
Tf/__init__.py 调用 PreparePythonModule()
      ↓
PreparePythonModule() 调用 importlib.import_module("._tf", "pxr.Tf")
      ↓
Python 加载 _tf.pyd（C++ 扩展）
      ↓
Windows 加载器查找 _tf.pyd 依赖的 DLL
      ↓
在 PATH 指向的目录中找到 usd_tf.dll、usd_tf_python.dll 等
      ↓
加载成功，Usd 模块可用
```

### 断链分析

```
PYTHONPATH 没设 → 第 2 步就失败 → ModuleNotFoundError
PATH 没设 → 第 8 步失败 → ImportError: DLL load failed
```

---

*基于 OpenUSD 26.08 + VS Code + Anaconda Python 3.13.9 + Windows 11 实际验证。*
