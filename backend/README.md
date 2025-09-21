# Talent Hub Backend

Backend API untuk aplikasi Talent Hub yang dirancang khusus untuk memberdayakan pencari kerja.

## Fitur Utama

- **Autentikasi & Otorisasi**: Sistem login/register dengan JWT
- **Profil Talent**: Manajemen profil dengan portofolio dan skills
- **Profil Perusahaan**: Manajemen profil perusahaan
- **Lowongan Pekerjaan**: CRUD operations untuk lowongan
- **Pelacak Lamaran**: Sistem tracking lamaran kerja
- **Filter & Pencarian**: Pencarian lowongan dengan berbagai filter

## Teknologi

- Node.js & Express.js
- MongoDB dengan Mongoose
- JWT untuk autentikasi
- bcryptjs untuk hashing password
- express-validator untuk validasi

## Setup & Instalasi

1. Install dependencies:
```bash
npm install
```

2. Setup environment variables:
```bash
cp config.env.example config.env
# Edit config.env dengan konfigurasi MongoDB dan JWT secret
```

3. Jalankan server:
```bash
# Development
npm run dev

# Production
npm start
```

## API Endpoints

### Autentikasi
- `POST /api/auth/register` - Register user baru
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user info

### Profil
- `GET /api/profile/me` - Get current user profile
- `PUT /api/profile/talent` - Update talent profile
- `PUT /api/profile/company` - Update company profile
- `POST /api/profile/talent/skills` - Add skill
- `DELETE /api/profile/talent/skills/:skill` - Remove skill
- `POST /api/profile/talent/portfolio` - Add portfolio item
- `DELETE /api/profile/talent/portfolio/:id` - Remove portfolio item

### Lowongan Pekerjaan
- `GET /api/jobs` - Get all jobs (with filters)
- `GET /api/jobs/:id` - Get job by ID
- `POST /api/jobs` - Create job (Company only)
- `PUT /api/jobs/:id` - Update job (Company only)
- `DELETE /api/jobs/:id` - Delete job (Company only)
- `GET /api/jobs/company/my-jobs` - Get company's jobs
- `GET /api/jobs/:id/applications` - Get job applications

### Lamaran Kerja
- `POST /api/applications/jobs/:jobId/apply` - Apply for job
- `GET /api/applications/me` - Get my applications
- `GET /api/applications/:id` - Get application details
- `PUT /api/applications/:id/status` - Update application status
- `DELETE /api/applications/:id` - Withdraw application

## Database Schema

### User
- email, password, role, isActive, timestamps

### Talent
- userId, name, description, phone, location, portfolio, skills, experience, education, resumeUrl, profilePicture

### Company
- userId, companyName, description, industry, website, phone, address, logo, companySize, foundedYear, isVerified

### Job
- companyId, title, description, requirements, responsibilities, salary, location, jobType, experienceLevel, skills, benefits, applicationDeadline, isActive

### Application
- talentId, jobId, companyId, status, coverLetter, resumeUrl, appliedAt, reviewedAt, interviewScheduledAt, notes, feedback

## Environment Variables

```
PORT=5000
MONGODB_URI=mongodb://localhost:27017/talent_hub
JWT_SECRET=your_jwt_secret_key_here
NODE_ENV=development
```

