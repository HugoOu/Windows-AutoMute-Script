# Windows 11 Auto-Mute Script

一个基于 **Windows Core Audio API** 深度调用的 PowerShell 脚本，用于实现开机自动静音，且完美解决传统模拟按键导致的逻辑翻转问题。

## 核心特性
* 自动检测当前音量状态。若已静音则保持，若有声则强制静音（非 Toggle 逻辑）
* 通过内存指针（VTable）直接调用硬件驱动，不干扰键盘 `NumLock` 状态
* 直接操作内存地址

## 快速使用

### 1. 准备脚本
下载 `mute.ps1` 并保存到本地（例如 `C:\Scripts\mute.ps1`）。

### 2. 配置自动化
为了实现开机静音，建议通过任务计划程序配置：
1.  触发器：选择“登录时”，延迟 1 - 5 秒（确保音频服务已启动）。
2.  操作：启动程序 `powershell.exe`。
3.  参数：
    ```bash
    -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass -File "C:\Scripts\mute.ps1"
    ```
4.  权限：勾选“使用最高权限运行”。

## 技术原理
脚本通过反射加载 C# 代码，直接定位 `IAudioEndpointVolume` 接口在内存中的虚函数表（VTable）地址，调用第 14 位（SetMute）和第 15 位（GetMute）原生函数。
