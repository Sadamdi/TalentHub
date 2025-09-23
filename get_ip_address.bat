@echo off
echo ========================================
echo    TALENT HUB - IP ADDRESS FINDER
echo ========================================
echo.
echo Mencari IP address untuk backend server...
echo.

echo IP Address yang tersedia:
echo -------------------------
ipconfig | findstr "IPv4 Address"

echo.
echo ========================================
echo CARA MENGGUNAKAN:
echo ========================================
echo 1. Pilih IP address yang sesuai dengan koneksi internet Anda
echo 2. Biasanya yang digunakan adalah IP dari "Wi-Fi" atau "Ethernet"
echo 3. Ganti baseUrl di frontend/lib/services/api_service.dart
echo 4. Format: http://[IP_ADDRESS]:5000/api
echo.
echo Contoh:
echo - Jika IP Wi-Fi: 192.168.1.100
echo - Maka baseUrl: http://192.168.1.100:5000/api
echo.
echo - Jika IP Ethernet: 10.0.0.50  
echo - Maka baseUrl: http://10.0.0.50:5000/api
echo.
echo ========================================
echo PENTING:
echo ========================================
echo - Pastikan backend server berjalan di port 5000
echo - Pastikan firewall tidak memblokir port 5000
echo - Pastikan HP/emulator dan laptop dalam jaringan yang sama
echo.
pause


