# Talent Hub - Job Seeker's Companion

Aplikasi Talent Hub yang dirancang khusus untuk memberdayakan pencari kerja dengan fitur-fitur yang memudahkan proses pencarian dan lamaran kerja. Aplikasi ini menjadi jembatan yang efisien antara Talent dan Perusahaan.

## 🚀 Fitur Utama

### Untuk Talent (Pencari Kerja)
- **Dashboard Pemberdayaan**: Rekomendasi lowongan pekerjaan yang sesuai dengan profil
- **Profil Komprehensif**: Manajemen portofolio, skills, dan informasi pribadi
- **Pelacak Lamaran**: Tracking status lamaran kerja secara real-time dengan timeline
- **Pencarian Advanced**: Filter berdasarkan lokasi, gaji, pengalaman, dan tipe pekerjaan
- **Detail Pekerjaan**: Informasi lengkap lowongan dengan fitur lamar langsung

### Untuk Perusahaan
- **Dashboard Manajemen**: Overview lowongan aktif dan statistik pelamar
- **Manajemen Lowongan**: CRUD operations untuk posting lowongan pekerjaan
- **Manajemen Pelamar**: Review, update status, dan berikan feedback pada lamaran
- **Profil Perusahaan**: Manajemen informasi dan branding perusahaan

## 🛠️ Teknologi

### Backend
- **Node.js & Express.js**: Server dan API framework
- **MongoDB**: Database NoSQL untuk fleksibilitas data
- **JWT**: Autentikasi dan otorisasi yang aman
- **Mongoose**: ODM untuk MongoDB
- **bcryptjs**: Hashing password yang aman

### Frontend
- **Flutter**: Framework UI cross-platform
- **Provider**: State management yang efisien
- **Dio**: HTTP client untuk komunikasi API
- **Flutter Secure Storage**: Penyimpanan token yang aman

## 📁 Struktur Proyek

```
talent_hub/
├── backend/                  # Backend Express.js
│   ├── models/              # Database models
│   ├── routes/              # API routes
│   ├── middleware/          # Custom middleware
│   ├── config.env           # Environment variables
│   └── server.js            # Entry point
├── frontend/                # Flutter app
│   ├── lib/
│   │   ├── models/          # Data models
│   │   ├── providers/       # State management
│   │   ├── screens/         # UI screens
│   │   ├── widgets/         # Reusable components
│   │   ├── services/        # API services
│   │   └── utils/           # Utilities
│   └── pubspec.yaml         # Dependencies
└── README.md                # Documentation
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v14 atau lebih baru)
- Flutter SDK (v3.0 atau lebih baru)
- MongoDB Atlas account atau MongoDB lokal

### Backend Setup

1. **Install dependencies**:
```bash
cd backend
npm install
```

2. **Setup environment variables**:
```bash
# Edit config.env file
PORT=5000
MONGODB_URI=mongodb+srv://talenthub:<db_password>@cluster0.4s7g3ox.mongodb.net/talent_hub?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=your_jwt_secret_key_here
NODE_ENV=development
```

3. **Jalankan server**:
```bash
# Development
npm run dev

# Production
npm start
```

### Frontend Setup

1. **Install dependencies**:
```bash
cd frontend
flutter pub get
```

2. **Update API endpoint** (jika diperlukan):
```dart
// lib/services/api_service.dart
static const String baseUrl = 'http://localhost:5000/api';
```

3. **Jalankan aplikasi**:
```bash
flutter run
```

## 📱 Screenshots & Demo

### Talent Dashboard
- Rekomendasi lowongan pekerjaan
- Search dan filter yang powerful
- Quick actions untuk pencarian

### Profil Talent
- Manajemen portofolio dengan berbagai media
- Skills management dengan tags
- Progress indicator kelengkapan profil

### Pelacak Lamaran
- Timeline status lamaran yang detail
- Filter berdasarkan status
- Feedback dari perusahaan

### Company Dashboard
- Statistik lowongan dan pelamar
- Quick actions untuk manajemen
- Overview performa

## 🔧 API Documentation

### Authentication
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info

### Profile Management
- `GET /api/profile/me` - Get current user profile
- `PUT /api/profile/talent` - Update talent profile
- `PUT /api/profile/company` - Update company profile

### Job Management
- `GET /api/jobs` - Get all jobs (with filters)
- `POST /api/jobs` - Create new job (Company only)
- `PUT /api/jobs/:id` - Update job (Company only)
- `DELETE /api/jobs/:id` - Delete job (Company only)

### Application Management
- `POST /api/applications/jobs/:jobId/apply` - Apply for job
- `GET /api/applications/me` - Get my applications
- `PUT /api/applications/:id/status` - Update application status

## 🎨 Design System

### Colors
- **Primary**: #0077B5 (LinkedIn Blue)
- **Secondary**: #00A0DC
- **Success**: #4CAF50
- **Warning**: #FF9800
- **Error**: #F44336

### Typography
- **Font Family**: Roboto
- **Headings**: Bold, 18-24px
- **Body**: Regular, 14-16px
- **Captions**: Regular, 12px

## 🔒 Security Features

- JWT-based authentication
- Password hashing dengan bcrypt
- Input validation dan sanitization
- CORS configuration
- Secure token storage

## 📊 Database Schema

### Users
- email, password, role, isActive, timestamps

### Talent
- userId, name, description, portfolio, skills, experience, education

### Company
- userId, companyName, description, industry, website, address

### Jobs
- companyId, title, description, salary, location, requirements, benefits

### Applications
- talentId, jobId, companyId, status, coverLetter, feedback, timestamps

## 🚀 Deployment

### Backend (Heroku/Railway)
1. Connect repository ke platform
2. Set environment variables
3. Deploy otomatis

### Frontend (Firebase/Play Store)
1. Build release APK/IPA
2. Upload ke platform
3. Publish aplikasi

## 🤝 Contributing

1. Fork repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

## 👥 Team

- **Backend Developer**: Express.js, MongoDB, API Design
- **Frontend Developer**: Flutter, UI/UX, State Management
- **UI/UX Designer**: Material Design, User Experience

## 📞 Support

Jika Anda mengalami masalah atau memiliki pertanyaan:

1. Check [Issues](https://github.com/your-repo/issues) untuk solusi yang sudah ada
2. Buat [New Issue](https://github.com/your-repo/issues/new) dengan detail yang jelas
3. Email: support@talenthub.com

## 🎯 Roadmap

### Phase 1 (Current)
- ✅ Basic authentication
- ✅ Profile management
- ✅ Job posting and application
- ✅ Application tracking

### Phase 2 (Next)
- 🔄 Real-time notifications
- 🔄 Advanced search with AI
- 🔄 Video interview integration
- 🔄 Analytics dashboard

### Phase 3 (Future)
- 📋 Mobile app optimization
- 📋 Web version
- 📋 Multi-language support
- 📋 Advanced matching algorithm

---

**Talent Hub** - Memberdayakan pencari kerja dengan teknologi terdepan 🚀
