#!/bin/bash
# ============================================================
# U-Claw 远程协助 v2（Mac/Linux）— 稳定版
# 用法: curl -fsSL https://u-claw.org/remote.sh | bash
# ============================================================

set -e
GREEN='\033[0;32m'; CYAN='\033[0;36m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; DIM='\033[2m'; NC='\033[0m'

clear
echo ""
echo -e "${CYAN}  ===========================================${NC}"
echo -e "${CYAN}  U-Claw 远程协助 v2（稳定连接）${NC}"
echo -e "${CYAN}  ===========================================${NC}"
echo ""

# ---- Step 1: SSH ----
echo -e "  [1/3] 检查 SSH ..."
if [[ "$(uname)" == "Darwin" ]]; then
    sudo systemsetup -setremotelogin on 2>/dev/null || true
else
    sudo systemctl start sshd 2>/dev/null || sudo systemctl start ssh 2>/dev/null || {
        sudo apt-get install -y openssh-server 2>/dev/null || sudo yum install -y openssh-server 2>/dev/null
        sudo systemctl start sshd 2>/dev/null || sudo systemctl start ssh
    }
fi
echo -e "${GREEN}  [OK] SSH 已启动${NC}"

# ---- Step 2: frpc ----
echo ""
echo -e "  [2/3] 准备远程通道 ..."

FRP_DIR="/tmp/uclaw-frp"
mkdir -p "$FRP_DIR"
FRPC="$FRP_DIR/frpc"

if [ ! -f "$FRPC" ]; then
    ARCH=$(uname -m)
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    if [[ "$OS" == "darwin" ]]; then
        if [[ "$ARCH" == "arm64" ]]; then
            FRP_URL="https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_darwin_arm64.tar.gz"
        else
            FRP_URL="https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_darwin_amd64.tar.gz"
        fi
    else
        FRP_URL="https://github.com/fatedier/frp/releases/download/v0.61.1/frp_0.61.1_linux_amd64.tar.gz"
    fi

    echo -e "${DIM}    下载: $FRP_URL${NC}"
    curl -sL "https://ghfast.top/$FRP_URL" -o "$FRP_DIR/frp.tar.gz" 2>/dev/null || \
    curl -sL "$FRP_URL" -o "$FRP_DIR/frp.tar.gz"
    tar xzf "$FRP_DIR/frp.tar.gz" -C "$FRP_DIR" --strip-components=1
    rm -f "$FRP_DIR/frp.tar.gz"
fi

chmod +x "$FRPC"
echo -e "${GREEN}  [OK] 远程通道工具就绪${NC}"

# ---- Step 3: 连接 ----
echo ""
echo -e "  [3/3] 建立连接 ..."

PORT=$((20000 + RANDOM % 100))
USERNAME=$(whoami)
HOSTNAME_VAL=$(hostname)

cat > "$FRP_DIR/frpc.toml" << EOF
serverAddr = "101.32.254.221"
serverPort = 7000
auth.method = "token"
auth.token = "uclaw-remote-2026"

[[proxies]]
name = "ssh-${USERNAME}-${PORT}"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = ${PORT}
EOF

echo ""
echo -e "${GREEN}  ===========================================${NC}"
echo -e "${GREEN}  远程协助已就绪！${NC}"
echo -e "${GREEN}  ===========================================${NC}"
echo ""
echo -e "${YELLOW}  +------------------------------------------+"
echo -e "  |  把下面这段发给技术支持（微信）：         |"
echo -e "  |                                          |"
echo -e "  |  ${CYAN}端口: ${PORT}${YELLOW}                               |"
echo -e "  |  ${CYAN}用户: ${USERNAME}${YELLOW}                               |"
echo -e "  |  ${CYAN}电脑: ${HOSTNAME_VAL}${YELLOW}                               |"
echo -e "  |                                          |"
echo -e "  +------------------------------------------+${NC}"
echo ""
echo -e "${DIM}  * 连接稳定，断线自动重连${NC}"
echo -e "${DIM}  * 按 Ctrl+C 断开远程${NC}"
echo -e "${DIM}  * 你的登录密码需要告知技术支持${NC}"
echo ""

# 启动 frpc
"$FRPC" -c "$FRP_DIR/frpc.toml"
