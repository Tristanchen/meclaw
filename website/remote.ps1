# ============================================================
# U-Claw 远程协助 v2（Windows）— 稳定版
# 用法: irm https://u-claw.org/remote.ps1 | iex
# 通过 frp 连接到 U-Claw 中转服务器，永不断线
# ============================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
try { chcp 65001 | Out-Null } catch {}
Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction SilentlyContinue

Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "  U-Claw 远程协助 v2（稳定连接）" -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host ""

# ---- Step 1: SSH ----
Write-Host "  [1/3] 检查 SSH ..." -ForegroundColor White
$sshd = Get-Service sshd -ErrorAction SilentlyContinue
if (-not $sshd) {
    Write-Host "  安装 OpenSSH Server（需要几分钟）..." -ForegroundColor Yellow
    $ErrorActionPreference = "Continue"
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 2>&1 | Out-Null
    $ErrorActionPreference = "Stop"
}
Start-Service sshd -ErrorAction SilentlyContinue
Set-Service -Name sshd -StartupType Automatic -ErrorAction SilentlyContinue
New-NetFirewallRule -Name "OpenSSH-Server" -DisplayName "OpenSSH Server" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -ErrorAction SilentlyContinue 2>&1 | Out-Null

$sshd = Get-Service sshd -ErrorAction SilentlyContinue
if ($sshd -and $sshd.Status -eq 'Running') {
    Write-Host "  [OK] SSH 已启动" -ForegroundColor Green
} else {
    Write-Host "  [!] SSH 启动失败，请以管理员身份运行" -ForegroundColor Red
    Read-Host "  按回车退出"
    exit 1
}

# ---- Step 2: 下载 frpc ----
Write-Host ""
Write-Host "  [2/3] 准备远程通道 ..." -ForegroundColor White

$FRP_DIR = "$env:TEMP\uclaw-frp"
$FRPC = "$FRP_DIR\frpc.exe"

if (-not (Test-Path $FRPC)) {
    New-Item -ItemType Directory -Force -Path $FRP_DIR | Out-Null
    $frpUrl = "https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_windows_amd64.zip"
    $frpZip = "$FRP_DIR\frp.zip"

    # 尝试多个镜像
    $mirrors = @(
        "https://ghfast.top/$frpUrl",
        "https://gh-proxy.com/$frpUrl",
        $frpUrl
    )

    $downloaded = $false
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ProgressPreference = 'SilentlyContinue'

    foreach ($url in $mirrors) {
        Write-Host "    下载: $url" -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri $url -OutFile $frpZip -UseBasicParsing -TimeoutSec 60
            if ((Get-Item $frpZip).Length -gt 1MB) { $downloaded = $true; break }
        } catch {
            Write-Host "    失败，换下一个..." -ForegroundColor DarkGray
        }
    }

    if (-not $downloaded) {
        try { & curl.exe -sL $mirrors[0] -o $frpZip; if ((Get-Item $frpZip).Length -gt 1MB) { $downloaded = $true } } catch {}
    }

    if (-not $downloaded) {
        Write-Host "  [!] 下载失败" -ForegroundColor Red
        Read-Host "  按回车退出"
        exit 1
    }

    Expand-Archive $frpZip $FRP_DIR -Force
    $frpcFound = Get-ChildItem -Recurse $FRP_DIR -Filter "frpc.exe" | Select-Object -First 1
    if ($frpcFound) { Copy-Item $frpcFound.FullName $FRPC -Force }
    Remove-Item $frpZip -Force -ErrorAction SilentlyContinue
}

if (-not (Test-Path $FRPC)) {
    Write-Host "  [!] frpc 下载失败" -ForegroundColor Red
    Read-Host "  按回车退出"
    exit 1
}

Write-Host "  [OK] 远程通道工具就绪" -ForegroundColor Green

# ---- Step 3: 连接 ----
Write-Host ""
Write-Host "  [3/3] 建立连接 ..." -ForegroundColor White

# 随机端口 20000-20099
$PORT = Get-Random -Minimum 20000 -Maximum 20100
$USERNAME = $env:USERNAME
$COMPUTER = $env:COMPUTERNAME

# 写 frpc 配置
$frpcConfig = @"
serverAddr = "101.32.254.221"
serverPort = 7000
auth.method = "token"
auth.token = "uclaw-remote-2026"

[[proxies]]
name = "ssh-$USERNAME-$PORT"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $PORT
"@
$configPath = "$FRP_DIR\frpc.toml"
[IO.File]::WriteAllText($configPath, $frpcConfig, (New-Object System.Text.UTF8Encoding $false))

Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Green
Write-Host "  远程协助已就绪！" -ForegroundColor Green
Write-Host "  ==========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Yellow
Write-Host "  |  把下面这段发给技术支持（微信）：         |" -ForegroundColor Yellow
Write-Host "  |                                          |" -ForegroundColor Yellow
Write-Host "  |  端口: $PORT" -ForegroundColor Cyan -NoNewline
Write-Host "$(' ' * (33 - $PORT.ToString().Length))|" -ForegroundColor Yellow
Write-Host "  |  用户: $USERNAME" -ForegroundColor Cyan -NoNewline
Write-Host "$(' ' * (33 - $USERNAME.Length))|" -ForegroundColor Yellow
Write-Host "  |  电脑: $COMPUTER" -ForegroundColor Cyan -NoNewline
Write-Host "$(' ' * (33 - $COMPUTER.Length))|" -ForegroundColor Yellow
Write-Host "  |                                          |" -ForegroundColor Yellow
Write-Host "  +------------------------------------------+" -ForegroundColor Yellow
Write-Host ""
Write-Host "  * 连接稳定，断线自动重连" -ForegroundColor DarkGray
Write-Host "  * 关闭此窗口即断开远程" -ForegroundColor DarkGray
Write-Host "  * 你的登录密码需要告知技术支持" -ForegroundColor DarkGray
Write-Host ""

# 启动 frpc（阻塞，自动重连）
& $FRPC -c $configPath
