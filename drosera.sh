#!/bin/bash

echo "======================================================="
echo "                DROSERA NETWORK by Moaru               "
echo "======================================================="

read -p "Masukkan email GitHub kamu: " GITHUB_EMAIL
read -p "Masukkan username GitHub kamu: " GITHUB_USERNAME
read -p "Masukkan Private Key kamu (untuk trap & operator): " ETH_KEY
read -p "Masukkan IP VPS kamu (untuk operator): " VPS_IP
read -p "Masukkan Address kamu (contoh: 0xabc...123): " WHITELIST_ADDR

echo ""
echo "Trap Setup Mode:"
echo "1) Deploy trap baru"
echo "2) Gunakan trap yang sudah ada"
read -p "Pilih opsi (1 atau 2): " TRAP_MODE

# Update sistem & install dependensi
echo "🔧 Menyiapkan sistem dan menginstal dependensi..."
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl ufw iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y

# Uninstall docker lama
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove -y $pkg; done

# Install Docker terbaru
echo "🐳 Menginstal Docker..."
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world

# Install drosera CLI, Foundry, Bun
echo "📥 Menginstal CLI Drosera, Foundry & Bun..."
curl -L https://app.drosera.io/install | bash
source ~/.bashrc
droseraup

curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup

curl -fsSL https://bun.sh/install | bash

# Setup Trap
mkdir -p ~/my-drosera-trap
cd ~/my-drosera-trap
git config --global user.email "$GITHUB_EMAIL"
git config --global user.name "$GITHUB_USERNAME"

if [ "$TRAP_MODE" == "1" ]; then
  echo "🚀 Menyiapkan dan mendeply trap baru..."
  forge init -t drosera-network/trap-foundry-template
  bun install
  forge build

  # Buat drosera.toml
  cat <<EOL > drosera.toml
ethereum_rpc = "https://ethereum-holesky-rpc.publicnode.com"
drosera_rpc = "https://seed-node.testnet.drosera.io"
eth_chain_id = 17000
drosera_address = "0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8"

[traps]

[traps.mytrap]
path = "out/HelloWorldTrap.sol/HelloWorldTrap.json"
response_contract = "0xdA890040Af0533D98B9F5f8FE3537720ABf83B0C"
response_function = "helloworld(string)"
cooldown_period_blocks = 33
min_number_of_operators = 1
max_number_of_operators = 2
block_sample_size = 10
private = true
whitelist = ["$WHITELIST_ADDR"]
EOL

  DROSERA_PRIVATE_KEY=$ETH_KEY drosera apply
  drosera dryrun

else
  read -p "Masukkan alamat trap yang sudah dideploy (0x...): " EXISTING_TRAP
  echo "🛠️ Menggunakan trap yang sudah ada di address: $EXISTING_TRAP"

  cat <<EOT > trap_config.json
{
  "name": "mytrap",
  "address": "$EXISTING_TRAP",
  "args": {}
}
EOT
fi

# Install operator
cd ~
curl -LO https://github.com/drosera-network/releases/releases/download/v1.16.2/drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
tar -xvf drosera-operator-v1.16.2-x86_64-unknown-linux-gnu.tar.gz
sudo cp drosera-operator /usr/bin
drosera-operator --version

# Register operator
drosera-operator register --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com --eth-private-key $ETH_KEY

# Buat service systemd
sudo tee /etc/systemd/system/drosera.service > /dev/null <<EOF
[Unit]
Description=drosera node service
After=network-online.target

[Service]
User=$USER
Restart=always
RestartSec=15
LimitNOFILE=65535
ExecStart=$(which drosera-operator) node --db-file-path /root/.drosera.db --network-p2p-port 31313 --server-port 31314 \
    --eth-rpc-url https://ethereum-holesky-rpc.publicnode.com \
    --eth-backup-rpc-url https://1rpc.io/holesky \
    --drosera-address 0xea08f7d533C2b9A62F40D5326214f39a8E3A32F8 \
    --eth-private-key $ETH_KEY \
    --listen-address 0.0.0.0 \
    --network-external-p2p-address $VPS_IP \
    --disable-dnr-confirmation true

[Install]
WantedBy=multi-user.target
EOF

# Setup firewall
sudo ufw allow ssh
sudo ufw allow 22
sudo ufw allow 31313/tcp
sudo ufw allow 31314/tcp
sudo ufw enable

# Enable & start service
sudo systemctl daemon-reload
sudo systemctl enable drosera
sudo systemctl start drosera

echo "✅ Node sukses dijalankan! Cek status node kamu dengan :"
echo "   sudo journalctl -fu drosera"

