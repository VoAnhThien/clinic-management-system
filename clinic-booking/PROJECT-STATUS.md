# Project Status - clinic-booking

**Ngày cập nhật:** 2026-06-18  
**Phiên bản:** 0.0.1-SNAPSHOT  
**Java:** 17  
**Spring Boot:** 3.3.0  
**Database:** PostgreSQL (Supabase)  
**Build Tool:** Maven

---

## 📋 Tóm tắt dự án

Hệ thống đặt lịch phòng khám trực tuyến với chức năng quản lý bệnh nhân, bác sĩ, lịch hẹn, hóa đơn, thanh toán và hồ sơ y tế.

---

## 🔧 Cấu hình chính

| Cấu hình | Giá trị |
|---------|--------|
| **Context Path** | `/api` |
| **Port** | `8080` |
| **JWT Secret** | `day-la-secret-key-cua-ban-phai-dai-hon-32-ky-tu-nhe` |
| **Access Token Expiry** | 15 phút (900,000ms) |
| **Refresh Token Expiry** | 7 ngày (604,800,000ms) |
| **Hibernate DDL Auto** | `update` |
| **Flyway** | Enabled |
| **Migration Path** | `classpath:db/migration` |

---

## 📊 Schema - Enums

Các kiểu dữ liệu enum được định nghĩa trong database:

- `user_role` - `PATIENT`, `DOCTOR`, `ADMIN`, `RECEPTIONIST`
- `gender_type` - `MALE`, `FEMALE`, `OTHER`
- `day_of_week_type` - `MON`, `TUE`, `WED`, `THU`, `FRI`, `SAT`, `SUN`
- `slot_status` - `AVAILABLE`, `HELD`, `BOOKED`, `BLOCKED`
- `appt_status` - `PENDING`, `CONFIRMED`, `COMPLETED`, `CANCELLED`, `NO_SHOW`
- `payment_method` - `CASH`, `BANK_TRANSFER`, `MOMO`, `VNPAY`, `ZALOPAY`, `INSURANCE`
- `payment_status` - `UNPAID`, `PAID`, `REFUNDED`, `PARTIAL`
- `invoice_status` - `DRAFT`, `ISSUED`, `PAID`, `CANCELLED`
- `notif_type` - `APPOINTMENT_REMINDER`, `APPOINTMENT_CONFIRMED`, `APPOINTMENT_CANCELLED`, `RESULT_READY`, `PAYMENT_DUE`, `GENERAL`
- `attachment_owner` - `MEDICAL_RECORD`, `PRESCRIPTION`, `APPOINTMENT`, `INVOICE`
- `relation_type` - `SELF`, `SPOUSE`, `CHILD`, `PARENT`, `SIBLING`, `OTHER`

---

## 📦 Schema - Tables (23 bảng)

### Group 1 — User & Auth
- **users** - Tài khoản người dùng (id, phone, email, national_id, password_hash, role, is_active, last_login_at, refresh_token_hash, created_at, updated_at)

### Group 2 — Patient Profile
- **patients** - Hồ sơ bệnh nhân (hỗ trợ đặt lịch hộ người thân)

### Group 3 — Doctor & Specialization
- **doctors** - Thông tin bác sĩ
- **specializations** - Chuyên khoa (Nội khoa, Nhi khoa, Da liễu, v.v.)
- **doctor_specializations** - Ánh xạ bác sĩ ↔ chuyên khoa (M-N)

### Group 3b — Staff Profile
- **staff_profiles** - Thông tin admin/receptionist

### Group 4 — Clinic & Services
- **clinics** - Thông tin phòng khám (name, address, phone, email, is_active)
- **services** - Dịch vụ khám (clinic_id, name, base_price, duration_min)

### Group 5 — Schedule & Time Slot
- **doctor_schedules** - Lịch làm việc của bác sĩ (doctor_id, clinic_id, day_of_week, start_time, end_time)
- **time_slots** - Khung giờ khám (schedule_id, slot_date, start_time, status, held_until)

### Group 6 — Appointment
- **appointments** - Lịch hẹn (patient_id, doctor_id, time_slot_id, status, reason, notes)
- **appointment_services** - Dịch vụ được chỉ định trong lịch hẹn (M-N)

### Group 7 — Medical Records
- **medical_records** - Hồ sơ khám (appointment_id, chief_complaint, diagnosis, treatment_plan)
- **prescriptions** - Đơn thuốc (medical_record_id, instructions, valid_until)
- **prescription_items** - Chi tiết đơn thuốc (medicine_name, dosage, frequency, duration_days)

### Group 8 — Invoice & Payment
- **invoices** - Hóa đơn (appointment_id, invoice_number, subtotal, discount, tax, total, status)
- **invoice_items** - Chi tiết hóa đơn (description, quantity, unit_price, line_total)
- **payments** - Thanh toán (invoice_id, method, amount, status, transaction_ref)

### Group 9 — Attachments & Reviews
- **attachments** - File đính kèm (polymorphic: medical_record, prescription, appointment, invoice)
- **reviews** - Đánh giá bác sĩ (appointment_id, rating 1-5, comment, is_visible)

### Group 10 — Notifications
- **notifications** - Thông báo (user_id, type, title, body, ref_id, is_read)

---

## 🎯 Entity Classes (23 cái)

✅ **Đã tạo:**
- `BaseEntity` (abstract, có createdAt, updatedAt)
- `User` (role, isActive, refreshTokenHash)
- `Patient`
- `Doctor`
- `Specialization`
- `DoctorSpecialization` (composite key)
- `DoctorSpecializationId`
- `StaffProfile`
- `Clinic`
- `ClinicService` (service)
- `DoctorSchedule`
- `TimeSlot`
- `Appointment`
- `AppointmentService`
- `MedicalRecord`
- `Prescription`
- `PrescriptionItem`
- `Invoice`
- `InvoiceItem`
- `Payment`
- `Attachment`
- `Review`
- `Notification`

---

## 🔐 Service & Controller Layer

### Hiện tại đã implement:

#### AuthController ✅
- `POST /api/auth/login` - Đăng nhập bằng phone hoặc CCCD
- `POST /api/auth/register` - Đăng ký tài khoản bệnh nhân
- `POST /api/auth/refresh` - Làm mới access token
- `POST /api/auth/logout` - Đăng xuất

#### AuthService + AuthServiceImpl ✅
- Xử lý login/register/refresh/logout
- Kiểm tra phone/CCCD trùng lặp
- Tạo patient profile tự động khi register
- Lưu hash refresh token
- Tính năng refresh token reuse protection

#### Repository
- `UserRepository` (findByPhone, findByNationalId, existsByPhone, existsByNationalId)
- `PatientRepository` (findByUserId)

---

## 📋 Migration Files

| File | Mô tả | Trạng thái |
|------|-------|-----------|
| `V1__init_schema.sql` | Tạo schema toàn bộ + sample data | ✅ Hoàn thành |
| `V2__add_updated_at_to_clinics.sql` | Thêm cột `updated_at` cho bảng `clinics` | ✅ Hoàn thành |

---

## 🔒 Security & Config

### SecurityConfig ✅
- Tắt CSRF
- Bật CORS từ `http://localhost:3000` và `http://localhost:5173`
- JWT filter trước UsernamePassword filter
- Public endpoints: `/auth/**`, `/v3/api-docs/**`, `/swagger-ui/**`, `/actuator/health`, `/doctors/**`, `/services/**`, `/clinics/**`
- Stateless session policy

### CorsProperties ✅
- Bind danh sách allowed-origins từ `application.yml`

### JpaAuditingConfig ✅
- Bật `@EnableJpaAuditing` để auto-fill createdAt, updatedAt

---

## 📚 API Documentation

- **Swagger UI:** `http://localhost:8080/api/swagger-ui.html`
- **OpenAPI JSON:** `http://localhost:8080/api/v3/api-docs`
- **All auth endpoints are public** (không cần JWT)

---

## 🚀 Build & Run

### Build
```bash
cd D:\LVTN_final\clinic-booking
.\mvnw.cmd clean package -DskipTests
```

### Run
```bash
# Cách 1: Dùng Maven wrapper
.\mvnw.cmd spring-boot:run

# Cách 2: Chạy jar
java -jar .\target\clinic-booking-0.0.1-SNAPSHOT.jar
```

---

## ⚠️ Ghi chú quan trọng

1. **DDL Auto = update**: Hibernate sẽ tự thêm cột từ entity nếu DB thiếu. Để "khóa cứng" schema theo migration, nên đổi thành `validate` hoặc `none`.

2. **Clinic có updated_at**: V1 không có cột này, nhưng Clinic entity kế thừa `BaseEntity`, nên Hibernate tự thêm vào DB. Migration V2 đã được thêm để đồng bộ.

3. **Role không có bảng riêng**: Hiện tại dùng PostgreSQL enum `user_role` trong bảng `users`, không phải bảng roles riêng. Có thể nâng cấp thành RBAC chuẩn sau nếu cần.

4. **Redis config chưa hoàn tất**: Đang set placeholder `YOUR_UPSTASH_HOST` và `YOUR_UPSTASH_PASSWORD` trong `application.yml`.

5. **Email config chưa hoàn tất**: SendGrid API key chưa cấu hình thật (placeholder `YOUR_SENDGRID_KEY`).

6. **Cloudinary config chưa hoàn tất**: Cloud name, API key, secret chưa cấu hình.

---

## 📝 Trạng thái phát triển

### ✅ Hoàn thành
- Schema DB (23 bảng)
- Authentication/Authorization
- User & Patient Management
- JWT Token handling
- Security Config & CORS
- Swagger UI
- Project structure

### ⏳ Chưa bắt đầu
- Doctor Management endpoints
- Appointment booking system
- Schedule management
- Medical records management
- Invoice & Payment endpoints
- Notifications system
- File upload/storage
- Email notifications
- SMS/Firebase notifications
- Review system
- Audit logging
- Unit tests

---

## 🔗 File quan trọng

- `src/main/java/com/ClinicBookingApplication.java` - Entry point
- `src/main/java/com/clinic/config/SecurityConfig.java` - Security filter chain
- `src/main/java/com/clinic/config/JpaAuditingConfig.java` - JPA auditing
- `src/main/resources/application.yml` - Cấu hình chính
- `src/main/resources/db/migration/V*.sql` - Database migrations
- `pom.xml` - Maven dependencies (Spring Boot 3.3, JPA, Security, Redis, JWT, Swagger, Firebase, MapStruct, Flyway)

---

## 📞 Liên hệ & Hỗ trợ

- **Database:** Supabase PostgreSQL
- **API Base URL:** `http://localhost:8080/api`
- **Documentation:** Tham khảo Swagger UI hoặc file README.md

---

**Cập nhật lần cuối:** 2026-06-18
