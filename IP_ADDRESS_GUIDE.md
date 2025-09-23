# 🌐 Panduan IP Address untuk Talent Hub

## 📍 Cara Mendapatkan IP Address yang Benar

### 1. **Windows (Command Prompt)**
```cmd
ipconfig
```

### 2. **Windows (PowerShell)**
```powershell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" }
```

### 3. **Mac/Linux**
```bash
ifconfig
# atau
ip addr show
```

## 🔍 IP Address yang Ditemukan di Sistem Ini

Berdasarkan `ipconfig`, IP address yang tersedia:

- **Wi-Fi**: `10.190.3.75` (Koneksi internet utama)
- **vEthernet (Default Switch)**: `172.19.96.1` (Virtual network untuk Hyper-V)
- **vEthernet (WSL)**: `172.26.160.1` (Virtual network untuk WSL)

## ⚙️ Cara Mengganti BaseURL di Flutter

### 1. Buka file: `frontend/lib/services/api_service.dart`

### 2. Ganti baris ini:
```dart
static const String baseUrl = 'http://172.19.96.1:5000/api';
```

### 3. Dengan IP address yang sesuai:
```dart
// Contoh untuk Wi-Fi
static const String baseUrl = 'http://10.190.3.75:5000/api';

// Contoh untuk Ethernet
static const String baseUrl = 'http://192.168.1.100:5000/api';
```

## 🎯 IP Address yang Harus Dipilih

### ✅ **Pilih IP address yang:**
- Terhubung ke internet (biasanya Wi-Fi atau Ethernet)
- Bukan IP virtual (127.x.x.x, 169.x.x.x, 172.x.x.x untuk Hyper-V)
- Bukan IP loopback (127.0.0.1)

### ❌ **Jangan pilih IP address yang:**
- `127.0.0.1` atau `127.x.x.x` (localhost)
- `169.254.x.x` (auto-assigned)
- `172.x.x.x` (Hyper-V virtual network)
- `192.168.x.x` jika tidak terhubung ke internet

## 🔧 Troubleshooting

### 1. **Flutter tidak bisa connect ke backend**
- Pastikan backend server berjalan: `cd backend && node server.js`
- Pastikan IP address benar
- Pastikan HP/emulator dan laptop dalam jaringan yang sama

### 2. **Port 5000 tidak bisa diakses**
- Cek firewall Windows
- Pastikan tidak ada aplikasi lain yang menggunakan port 5000
- Restart backend server

### 3. **IP address berubah**
- IP address bisa berubah jika restart router
- Jalankan `ipconfig` lagi untuk mendapatkan IP baru
- Update baseUrl di Flutter

## 📱 Testing Koneksi

### Test dari HP/Emulator:
```bash
# Ganti [IP_ADDRESS] dengan IP yang benar
curl http://[IP_ADDRESS]:5000/api/jobs
```

### Test dari laptop:
```bash
# Ganti [IP_ADDRESS] dengan IP yang benar
curl http://[IP_ADDRESS]:5000/api/jobs
```

## 🚀 Quick Setup untuk Teman

1. **Jalankan di laptop:**
   ```cmd
   ipconfig
   ```

2. **Cari IP address Wi-Fi atau Ethernet (bukan yang 127.x.x.x atau 169.x.x.x)**

3. **Ganti di Flutter:**
   ```dart
   static const String baseUrl = 'http://[IP_ADDRESS]:5000/api';
   ```

4. **Jalankan backend:**
   ```cmd
   cd backend
   node server.js
   ```

5. **Test di Flutter app**

## 📞 Contoh IP Address Umum

- **Wi-Fi rumah**: `192.168.1.100`, `192.168.0.100`
- **Wi-Fi kantor**: `10.0.0.50`, `172.16.0.100`
- **Hotspot HP**: `192.168.43.1`, `192.168.137.1`
- **Ethernet**: `192.168.1.101`, `10.0.0.51`

---

**💡 Tips:** Jika IP address sering berubah, bisa menggunakan tools seperti ngrok untuk membuat URL tetap, atau set static IP di router.


