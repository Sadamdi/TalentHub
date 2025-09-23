Write-Host "========================================" -ForegroundColor Cyan
Write-Host "    TALENT HUB - IP ADDRESS FINDER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Mencari IP address untuk backend server..." -ForegroundColor Yellow
Write-Host ""

# Get network adapters with IP addresses
$adapters = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*" }

Write-Host "IP Address yang tersedia:" -ForegroundColor Green
Write-Host "-------------------------" -ForegroundColor Green

foreach ($adapter in $adapters) {
    $interface = Get-NetAdapter | Where-Object { $_.InterfaceIndex -eq $adapter.InterfaceIndex }
    Write-Host "• $($interface.Name): $($adapter.IPAddress)" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "CARA MENGGUNAKAN:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Pilih IP address yang sesuai dengan koneksi internet Anda" -ForegroundColor Yellow
Write-Host "2. Biasanya yang digunakan adalah IP dari 'Wi-Fi' atau 'Ethernet'" -ForegroundColor Yellow
Write-Host "3. Ganti baseUrl di frontend/lib/services/api_service.dart" -ForegroundColor Yellow
Write-Host "4. Format: http://[IP_ADDRESS]:5000/api" -ForegroundColor Yellow
Write-Host ""

# Show examples
$wifiIP = $adapters | Where-Object { (Get-NetAdapter | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }).Name -like "*Wi-Fi*" } | Select-Object -First 1
$ethernetIP = $adapters | Where-Object { (Get-NetAdapter | Where-Object { $_.InterfaceIndex -eq $_.InterfaceIndex }).Name -like "*Ethernet*" } | Select-Object -First 1

Write-Host "Contoh untuk IP yang ditemukan:" -ForegroundColor Green
if ($wifiIP) {
    Write-Host "• Wi-Fi: http://$($wifiIP.IPAddress):5000/api" -ForegroundColor White
}
if ($ethernetIP) {
    Write-Host "• Ethernet: http://$($ethernetIP.IPAddress):5000/api" -ForegroundColor White
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PENTING:" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "• Pastikan backend server berjalan di port 5000" -ForegroundColor Red
Write-Host "• Pastikan firewall tidak memblokir port 5000" -ForegroundColor Red
Write-Host "• Pastikan HP/emulator dan laptop dalam jaringan yang sama" -ForegroundColor Red
Write-Host ""

# Test if port 5000 is accessible
Write-Host "Testing koneksi ke port 5000..." -ForegroundColor Yellow
try {
    $testConnection = Test-NetConnection -ComputerName "localhost" -Port 5000 -WarningAction SilentlyContinue
    if ($testConnection.TcpTestSucceeded) {
        Write-Host "✅ Port 5000 dapat diakses (backend server berjalan)" -ForegroundColor Green
    } else {
        Write-Host "❌ Port 5000 tidak dapat diakses (backend server belum berjalan)" -ForegroundColor Red
        Write-Host "   Jalankan: cd backend && node server.js" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Tidak dapat test koneksi ke port 5000" -ForegroundColor Red
}

Write-Host ""
Write-Host "Tekan Enter untuk keluar..." -ForegroundColor Gray
Read-Host


