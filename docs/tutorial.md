# B站开放免费翻译 API：手把手教你接入陪读蛙、沉浸式翻译等浏览器插件

[返回仓库主页](../README.md) · [下载自启模板](../scripts/start_proxy.vbs)

**目录**

- [一、交给 AI，或自己跟做](#step-1)
- [二、确认免费公网 API 能用](#step-2)
- [三、接入浏览器插件](#step-3)
- [四、登录 Windows 后自动静默启动](#step-4)
- [五、停止方法、彩蛋及 Mac 补充](#step-5)


> 不用本地 GPU，不下载模型权重。用一个官方小脚本，就能把 B 站的免费公网翻译 API 接进浏览器，并在登录 Windows 后自动后台启动。

Bilibili 在 2026 年 10 月 4 日开放了 Index-Translate 的免费公网 API，官方明确提供的模型是 `Index-Translate-35B-A3B`，接口兼容 OpenAI。普通电脑也能调用，模型运行在 B 站云端。详见 [官方中文 README](https://github.com/bilibili/Index-Translate/blob/main/README_zh.md)。

我配置时最先踩到的坑，是把公网地址直接填进插件后遇到 **412**。后来改用官方脚本提供的本地代理，翻译成功了；再配上 Windows 登录自启，日常就不必手动打开终端。

本文按这次成功的 Windows 方案整理。这里的“免费”指官方目前开放的模型 API；插件自身的其他付费功能不包含在内，后续接口政策以官方说明为准。官方资料核对日期：2026 年 10 月 7 日。

<a name="step-1"></a>

## 一、先选路线：交给 AI，或自己跟做

### 1. 懒人方案：把配置交给能操作电脑的 AI

如果有 Codex、WorkBuddy，或其他能操作本地终端和文件的 AI，可以复制下面这段提示词。使用时让它在自己的 Windows 电脑上执行；只有文字聊天能力的 AI 无法代为完成本地配置。

```text
请在我的 Windows 电脑上配置 Bilibili Index-Translate 免费公网 API，供支持 OpenAI-compatible API 的浏览器翻译插件使用。

从官方仓库 https://github.com/bilibili/Index-Translate 下载 inference/llm/call_api.py，放到固定目录（优先 D:\IndexTranslate；没有 D 盘则用 C:\IndexTranslate）。

先用 py 检查 Python，再直接调用脚本翻译一句话，默认使用 Index-Translate-35B-A3B。用 call_api.py --serve 启动官方本地代理，验证 http://127.0.0.1:8080/v1/models，并实际发送翻译请求。

插件参数：Base URL=http://127.0.0.1:8080/v1，API Key=index，Model=Index-Translate-35B-A3B。如果插件要求完整 API URL，则使用 http://127.0.0.1:8080/v1/chat/completions。能操作插件时帮我配置并测试，否则告诉我在哪里填写。

确认成功后，获取真实 python.exe 的绝对路径，使用 start_proxy.vbs + wscript.exe + Windows 任务计划程序，设置当前用户登录后静默启动，日志写入 proxy.log。先检查已有代理和同名任务，避免重复启动或占用 8080 端口。

不要安装 vLLM，不要下载模型权重，不使用 pyw.exe 路线。最后告诉我重启后的验证方式，以及停止代理、禁用和删除自启任务的方法。不要替我重启电脑。
```

AI 完成后，按第 11 小步重启验证即可。

### 2. 手动方案：准备一个固定文件夹

以下统一使用 `D:\IndexTranslate`。没有 D 盘就用 `C:\IndexTranslate`，并把后文所有对应路径一起替换。

命令都在 **PowerShell** 中执行：在开始菜单搜索 PowerShell，打开后复制命令，按回车。无需懂代码，也不用先安装开发工具。

<a name="step-2"></a>

## 二、先确认免费公网 API 能用

### 3. 下载官方 call_api.py

打开 [官方脚本页面](https://github.com/bilibili/Index-Translate/blob/main/inference/llm/call_api.py)，点击下载原始文件的按钮，保存为：

```text
D:\IndexTranslate\call_api.py
```

也可打开 [原始文件](https://raw.githubusercontent.com/bilibili/Index-Translate/main/inference/llm/call_api.py)，右键另存为。确认文件名不是 `call_api.py.txt`。只下载这一个文件即可，它使用 Python 自带的功能，不需要额外安装依赖包。

### 4. 检查 Python，优先试 py

```powershell
py --version
```

显示 `Python 3.x.x` 就可以继续。若提示找不到命令或没有安装 Python，到 [Python 官网 Windows 下载页](https://www.python.org/downloads/windows/) 安装 Python 3，确保 `py` 可用，再重新打开 PowerShell 检查。

> Windows 的 `python` 有时会指向 Microsoft Store 的应用执行别名，输入后可能打开商店。遇到这种情况先试 `py`，不要仅凭 `python` 的表现判断 Python 没装好。相关说明见 [微软 Python 指南](https://learn.microsoft.com/en-us/windows/dev-environment/python)。

### 5. 直接翻译一句话

```powershell
py "D:\IndexTranslate\call_api.py" "Hello, world!" --target zh --model Index-Translate-35B-A3B
```

终端返回中文译文，就说明本机能调用官方公网 API。具体措辞可能不同，不必和某个示例逐字一致。

此时电脑没有运行 35B 模型，也没有下载模型权重。Python 只负责发送文本和接收译文。

<a name="step-3"></a>

## 三、把 API 接进浏览器翻译插件

### 6. 启动官方本地代理

```powershell
py "D:\IndexTranslate\call_api.py" --serve
```

看到监听 `127.0.0.1:8080` 的提示后，先保留这个窗口。关闭窗口会停止这次手动启动的代理。

可以把它理解为一个转发站：浏览器插件 → 本机小脚本 → B 站公网 API。**本地代理仍然调用公网 API**，模型继续运行在云端，翻译时仍需联网。官方脚本提供了这个浏览器扩展兼容入口，见 [脚本中的使用说明](https://github.com/bilibili/Index-Translate/blob/main/inference/llm/call_api.py)。

> 直连时遇到 412，不足以说明 API 已经不可用。我这次改用官方本地代理后成功了。可以先用第 5 步区分“公网调用失败”和“插件连接失败”；代理也不能保证解决所有网络或服务端问题。

### 7. 在插件里填写连接参数

以陪读蛙为例，进入“选项 → API 服务商”，添加并启用 **OpenAI 兼容自定义服务商**，填写以下三项，再将它选为当前翻译使用的服务商。入口说明见 [陪读蛙官方文档](https://www.readfrog.app/zh/docs/providers/openai-compatible-providers)。

| 配置项 | 填写内容 |
| --- | --- |
| Base URL | `http://127.0.0.1:8080/v1` |
| API Key | `index` |
| Model / 模型 | `Index-Translate-35B-A3B` |

模型名必须完整一致。`index` 是满足插件表单要求的占位值，当前官方代理不需要购买或申请 OpenAI 密钥。其他自定义请求头、请求体等高级选项先留空。

沉浸式翻译等插件也可参考，但要看清地址字段：

- 字段是 **Base URL / 基础地址**：填 `http://127.0.0.1:8080/v1`。
- 字段要求 **完整 API URL / 自定义 URL 地址**：填 `http://127.0.0.1:8080/v1/chat/completions`。

沉浸式翻译可在翻译服务中选择 OpenAI 或 OpenAI 兼容服务，设置自定义模型和地址；其官方接入示例使用完整的 `/chat/completions` 地址，见 [官方接入说明](https://immersivetranslate.com/zh-Hans/docs/services/ai/)。API Key 和模型仍按上表填写，入口名称以当前插件界面为准。

### 8. 实际翻译一个网页

先用插件的“测试连接”，再打开一个英文网页，选择中文并翻译一小段。出现译文后，浏览器接入就完成了。

如果失败，先确认代理窗口还开着，再检查地址类型、模型名和当前选用的服务商。其他支持 OpenAI 兼容接口的插件也能参考这些参数，实际能否使用还取决于插件的请求格式。

<a name="step-4"></a>

## 四、让它登录 Windows 后自动静默启动

### 9. 创建 start_proxy.vbs

另开一个 PowerShell 窗口，查出刚才使用的 Python 的真实路径：

```powershell
py -c "import sys; print(sys.executable)"
```

复制输出的完整路径。打开记事本，粘贴下面内容，把 `pythonPath` 的引号内替换成刚才复制的路径，其余内容保持不变：

```vbscript
Set shell = CreateObject("WScript.Shell")
q = Chr(34)

pythonPath = "C:\YOUR_PYTHON_PATH\python.exe"
scriptPath = "D:\IndexTranslate\call_api.py"
logPath = "D:\IndexTranslate\proxy.log"

cmd = "cmd.exe /c " & q & q & pythonPath & q & " " & q & scriptPath & q & " --serve >> " & q & logPath & q & " 2>&1" & q
shell.Run cmd, 0, False
```

“另存为”时，文件类型选“所有文件”，保存为 `D:\IndexTranslate\start_proxy.vbs`，确认没有多出 `.txt`。它会隐藏启动窗口，并把运行信息追加到同目录的 `proxy.log`。

保存后，在第 6 步的代理窗口按 **Ctrl+C**，先停止手动实例，避免后续两个进程争用 8080 端口。

### 10. 用任务计划程序设置登录自启

在开始菜单搜索并打开“任务计划程序”，选择“创建任务”，命名为 `Index Translate Proxy`。使用当前用户，选择“只在用户登录时运行”，普通用户权限即可。

“触发器”中新建“登录时”，指定当前用户；“操作”中新建“启动程序”，填写：

| 字段 | 内容 |
| --- | --- |
| 程序或脚本 | `C:\Windows\System32\wscript.exe` |
| 添加参数 | `"D:\IndexTranslate\start_proxy.vbs"` |
| 起始于 | `D:\IndexTranslate` |

参数里的双引号要保留，“起始于”不加引号。笔记本若希望在电池供电时也能启动，在“条件”中取消“只有在计算机使用交流电源时才启动此任务”。

保存后，右键这个任务，点击“运行”。正常情况下不会弹出终端窗口；用第 11 步的地址确认代理已经启动。

### 11. 重启后验证，不手动启动脚本

保存其他工作，重启电脑并登录 Windows，等约 10～20 秒。不要手动运行脚本，也不要在任务计划程序里点击“运行”，直接在浏览器打开：

```text
http://127.0.0.1:8080/v1/models
```

或者在 PowerShell 执行：

```powershell
curl.exe http://127.0.0.1:8080/v1/models
```

能看到模型列表，说明本地代理已随登录启动。**这个列表由脚本预设，不是实时查询云端**，所以还要打开插件实际翻译一段网页，确认公网调用也成功。

若打不开地址，检查任务中的文件路径、Python 路径，以及 `D:\IndexTranslate\proxy.log`。完成后，日常使用就是登录 Windows、打开浏览器、点击翻译。

<a name="step-5"></a>

## 五、日后怎么停，以及两个补充

### 12. 停止代理、禁用自启、删除任务

临时停止手动启动的代理，在它的终端窗口按 Ctrl+C。

对于静默启动的代理，在 PowerShell 执行：

```powershell
netstat -ano | findstr :8080
```

找到本地地址为 `127.0.0.1:8080`、状态为 `LISTENING` 的那一行，最右侧数字是进程 PID。假设是 `12345`，先确认它是这次代理使用的 Python，再停止：

```powershell
tasklist /FI "PID eq 12345"
taskkill /PID 12345 /F
```

把 `12345` 换成实际数字。若占用者不是这个代理，先查清楚，避免结束其他程序。

不想下次登录时启动，在任务计划程序中右键 `Index Translate Proxy`，选择“禁用”；需要恢复时再“启用”。彻底取消自启则选择“删除”，随后停止当前代理，再按需删除 `D:\IndexTranslate` 中的文件。

> 禁用或删除任务不会自动停止已经启动的 Python。这个 VBS 启动后会退出，也不要只靠任务计划程序的“结束”来判断代理已停止。

### 13. 几个容易混淆的问题

**为什么不用安装 vLLM？** 本文调用 B 站已部署的公网模型。vLLM 属于自己部署模型的另一条路线，这里不需要，也无需下载权重。

**为什么 Base URL 只填到 `/v1`？** 使用基础地址的客户端会自动拼接接口路径。只有插件明确要求完整 API URL 时，才填写 `/v1/chat/completions`，不要混用。

**为什么高级选项可以留空？** 当前官方代理已补充默认翻译参数；先用插件默认设置打通连接，遇到具体问题再调整。能翻译并不代表这个模型适合插件的所有其他 AI 功能。

### 14. 彩蛋：2B / 9B 也曾调用成功

这次配置过程中，我也测试了 `Index-Translate-2B` 和 `Index-Translate-9B`，当时都能返回译文，作为一个补充发现记录下来。

正文仍使用官方明确宣传的 `Index-Translate-35B-A3B`。脚本的模型列表里出现某个名字，不等于云端长期承诺开放它；2B / 9B 未来是否可用，仍以 [官方 README](https://github.com/bilibili/Index-Translate) 和实际调用结果为准。

### 15. 文末补充：Mac 用户只需关注这些差异

Mac 上通常使用 `python3`，固定目录可选 `~/IndexTranslate`。例如启动代理时使用：

```bash
python3 ~/IndexTranslate/call_api.py --serve
```

手动操作中的 `~` 代表用户主目录，路径分隔符用 `/`。插件地址、API Key、模型名和验证方法与正文相同。

登录后自启使用 **launchd 的用户级 LaunchAgent**，代替 Windows 的 VBS 和任务计划程序。配置文件放在 `~/Library/LaunchAgents/`，设置 `RunAtLoad`，并在 `ProgramArguments` 中分别填写真实 Python 可执行文件、脚本的绝对路径和 `--serve`；配置文件里不要使用 `~` 缩写。相关机制见 [Apple 官方说明](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)。

这部分只说明平台差异，未纳入本次 Windows 实测。Mac 同样只运行转发脚本，继续调用 B 站公网模型。
