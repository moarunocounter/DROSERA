# 🚀 DROSERA Trap Node Installer

Script ini akan membantu Anda mengatur node operator Drosera dari nol secara otomatis. Cocok untuk pengguna baru maupun yang ingin setup cepat dan bersih.

---

## ⚡ Instalasi Cepat

Jalankan perintah berikut di VPS Ubuntu 22.04+:

```bash
curl -L https://github.com/moarunocounter/DROSERA/raw/main/install.sh | bash
```

---

## 🔧 Yang Akan Dilakukan Script:

- Update sistem & dependencies
- Install Docker, Foundry, Bun, dan tool penting lainnya
- Setup drosera-operator
- Deploy smart contract trap
- Konfigurasi `drosera.toml`
- Menjalankan node operator dengan systemd
- Buka port firewall dan verifikasi node

---

## 📂 Struktur Project

```
my-drosera-trap/
├── contracts/
├── script/
├── src/
├── drosera.toml
├── foundry.toml
└── install.sh
```

---

## 🔍 Verifikasi & Test

### Dry Run Trap
```bash
drosera dryrun
```

### Deploy Trap
```bash
DROSERA_PRIVATE_KEY=0x... drosera apply
```

---

## 🧠 Konfigurasi drosera.toml

Contoh konfigurasi:

```toml
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
whitelist = ["your_address"]
```

---

## ⚙️ Kelola Node

```bash
sudo systemctl start drosera      # Menjalankan node
sudo systemctl stop drosera       # Menghentikan node
sudo systemctl restart drosera    # Restart node
sudo systemctl status drosera     # Status node
journalctl -u drosera -f          # Lihat log node real-time
```

---

## 🧪 Cek Versi

```bash
drosera-operator --version
```

---

## 👨‍💻 Author

Made by [@moarunocounter](https://github.com/moarunocounter)

---

## 📜 Lisensi

MIT License
