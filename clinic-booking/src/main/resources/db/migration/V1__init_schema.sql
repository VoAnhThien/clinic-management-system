
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────
-- ENUMS
-- ─────────────────────────────────────────────────────────────
CREATE TYPE user_role          AS ENUM ('patient','doctor','admin','receptionist');
CREATE TYPE gender_type        AS ENUM ('male','female','other');
CREATE TYPE day_of_week_type   AS ENUM ('mon','tue','wed','thu','fri','sat','sun');
CREATE TYPE slot_status        AS ENUM ('available','held','booked','blocked');
CREATE TYPE appt_status        AS ENUM ('pending','confirmed','completed','cancelled','no_show');
CREATE TYPE payment_method     AS ENUM ('cash','bank_transfer','momo','vnpay','zalopay','insurance');
CREATE TYPE payment_status     AS ENUM ('unpaid','paid','refunded','partial');
CREATE TYPE invoice_status     AS ENUM ('draft','issued','paid','cancelled');
CREATE TYPE notif_type         AS ENUM ('appointment_reminder','appointment_confirmed',
                                        'appointment_cancelled','result_ready','payment_due','general');
CREATE TYPE attachment_owner   AS ENUM ('medical_record','prescription','appointment','invoice');
CREATE TYPE relation_type      AS ENUM ('self','spouse','child','parent','sibling','other');

-- ─────────────────────────────────────────────────────────────
-- GROUP 1 — USER & AUTH
-- ─────────────────────────────────────────────────────────────
CREATE TABLE users (
                       id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Đăng nhập bằng phone HOẶC national_id
                       phone               VARCHAR(15)  UNIQUE,
                       national_id         VARCHAR(20)  UNIQUE,          -- CCCD / CMND
                       email               VARCHAR(255) UNIQUE,
                       password_hash       VARCHAR(255) NOT NULL,
                       role                user_role    NOT NULL DEFAULT 'patient',
                       is_active           BOOLEAN      NOT NULL DEFAULT TRUE,
                       last_login_at       TIMESTAMP,
                       refresh_token_hash  VARCHAR(255),                 -- lưu hash của refresh token
                       created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
                       updated_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
    -- Phải có ít nhất phone hoặc national_id
                       CONSTRAINT chk_login_method CHECK (phone IS NOT NULL OR national_id IS NOT NULL)
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 2 — PATIENT (hỗ trợ đặt lịch hộ người thân)
-- ─────────────────────────────────────────────────────────────
CREATE TABLE patients (
                          id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    -- user_id NULL = hồ sơ phụ (người thân, chưa có tài khoản)
                          user_id             UUID         UNIQUE REFERENCES users(id) ON DELETE SET NULL,
    -- created_by = tài khoản đã tạo hồ sơ này (đặt hộ)
                          created_by          UUID         NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                          relation_to_creator relation_type NOT NULL DEFAULT 'self',
                          full_name           VARCHAR(150) NOT NULL,
                          national_id         VARCHAR(20),
                          date_of_birth       DATE,
                          gender              gender_type,
                          phone               VARCHAR(15),
                          address             TEXT,
                          emergency_contact   VARCHAR(20),
                          blood_type          VARCHAR(5),
                          allergies           TEXT,
                          created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
                          updated_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 3 — DOCTOR & SPECIALIZATION
-- ─────────────────────────────────────────────────────────────
CREATE TABLE doctors (
                         id                  UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
                         user_id             UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                         full_name           VARCHAR(150) NOT NULL,
                         license_number      VARCHAR(50)  NOT NULL UNIQUE,
                         phone               VARCHAR(15),
                         biography           TEXT,
                         experience_years    INTEGER      DEFAULT 0,
                         avatar_url          VARCHAR(500),
                         created_at          TIMESTAMP    NOT NULL DEFAULT NOW(),
                         updated_at          TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE TABLE specializations (
                                 id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
                                 name        VARCHAR(100) NOT NULL UNIQUE,
                                 description TEXT
);

CREATE TABLE doctor_specializations (
                                        doctor_id           UUID NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
                                        specialization_id   UUID NOT NULL REFERENCES specializations(id) ON DELETE CASCADE,
                                        PRIMARY KEY (doctor_id, specialization_id)
);

-- ─────────────────────────────────────────────────────────────

-- ─────────────────────────────────────────────────────────────
-- GROUP 3b — STAFF PROFILE (admin / receptionist)
-- ─────────────────────────────────────────────────────────────

CREATE TABLE staff_profiles (
                                id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
                                user_id     UUID         NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
                                full_name   VARCHAR(150) NOT NULL,
                                phone       VARCHAR(15),
                                avatar_url  VARCHAR(500),
                                department  VARCHAR(100),
                                created_at  TIMESTAMP    NOT NULL DEFAULT NOW(),
                                updated_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- GROUP 4 — CLINIC, SERVICE & PRICING
-- ─────────────────────────────────────────────────────────────
CREATE TABLE clinics (
                         id          UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
                         name        VARCHAR(200) NOT NULL,
                         address     TEXT         NOT NULL,
                         phone       VARCHAR(15),
                         email       VARCHAR(255),
                         description TEXT,
                         is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
                         created_at  TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Dịch vụ khám (tổng quát, siêu âm, xét nghiệm, ...)
CREATE TABLE services (
                          id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
                          clinic_id       UUID           NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
                          name            VARCHAR(200)   NOT NULL,
                          description     TEXT,
                          base_price      NUMERIC(12,2)  NOT NULL DEFAULT 0,
                          duration_min    INTEGER        NOT NULL DEFAULT 30,  -- thời gian thực hiện dịch vụ
                          is_active       BOOLEAN        NOT NULL DEFAULT TRUE,
                          created_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
                          CONSTRAINT chk_service_price CHECK (base_price >= 0)
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 5 — SCHEDULE & TIME SLOT
-- ─────────────────────────────────────────────────────────────
CREATE TABLE doctor_schedules (
                                  id                  UUID             PRIMARY KEY DEFAULT gen_random_uuid(),
                                  doctor_id           UUID             NOT NULL REFERENCES doctors(id) ON DELETE CASCADE,
                                  clinic_id           UUID             NOT NULL REFERENCES clinics(id) ON DELETE CASCADE,
                                  day_of_week         day_of_week_type NOT NULL,
                                  start_time          TIME             NOT NULL,
                                  end_time            TIME             NOT NULL,
                                  slot_duration_min   INTEGER          NOT NULL DEFAULT 30,
                                  is_active           BOOLEAN          NOT NULL DEFAULT TRUE,
                                  CONSTRAINT chk_schedule_time    CHECK (end_time > start_time),
                                  CONSTRAINT chk_slot_duration    CHECK (slot_duration_min > 0)
);

CREATE TABLE time_slots (
                            id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
                            schedule_id UUID        NOT NULL REFERENCES doctor_schedules(id) ON DELETE CASCADE,
                            slot_date   DATE        NOT NULL,
                            start_time  TIME        NOT NULL,
                            end_time    TIME        NOT NULL,
                            status      slot_status NOT NULL DEFAULT 'available',
    -- Giữ chỗ tạm thời: held_until dùng trong code để tự giải phóng sau timeout
                            held_until  TIMESTAMP,
                            held_by     UUID        REFERENCES users(id) ON DELETE SET NULL,
                            CONSTRAINT chk_slot_time CHECK (end_time > start_time)
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 6 — APPOINTMENT
-- ─────────────────────────────────────────────────────────────
CREATE TABLE appointments (
                              id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
                              patient_id      UUID        NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
                              time_slot_id    UUID        NOT NULL UNIQUE REFERENCES time_slots(id) ON DELETE RESTRICT,
                              doctor_id       UUID        NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
                              clinic_id       UUID        NOT NULL REFERENCES clinics(id) ON DELETE RESTRICT,
    -- booked_by: người thực hiện đặt (có thể khác patient nếu đặt hộ)
                              booked_by       UUID        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                              status          appt_status NOT NULL DEFAULT 'pending',
                              reason          TEXT,
                              notes           TEXT,
                              booked_at       TIMESTAMP   NOT NULL DEFAULT NOW(),
                              cancelled_at    TIMESTAMP,
                              cancel_reason   TEXT,
                              updated_at      TIMESTAMP   NOT NULL DEFAULT NOW()
);

-- Dịch vụ được chỉ định trong lịch hẹn (nhiều-nhiều)
CREATE TABLE appointment_services (
                                      id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
                                      appointment_id  UUID           NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
                                      service_id      UUID           NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
                                      quantity        INTEGER        NOT NULL DEFAULT 1,
                                      unit_price      NUMERIC(12,2)  NOT NULL,  -- snapshot giá tại thời điểm đặt
                                      note            TEXT,
                                      CONSTRAINT chk_qty   CHECK (quantity > 0),
                                      CONSTRAINT chk_price CHECK (unit_price >= 0)
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 7 — MEDICAL RECORD & PRESCRIPTION
-- ─────────────────────────────────────────────────────────────
CREATE TABLE medical_records (
                                 id                  UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
                                 appointment_id      UUID      NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE RESTRICT,
                                 patient_id          UUID      NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
                                 doctor_id           UUID      NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
                                 chief_complaint     TEXT,
                                 diagnosis           TEXT,
                                 treatment_plan      TEXT,
                                 notes               TEXT,
                                 examined_at         TIMESTAMP NOT NULL DEFAULT NOW(),
                                 created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
                                 updated_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE prescriptions (
                               id                  UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
                               medical_record_id   UUID      NOT NULL UNIQUE REFERENCES medical_records(id) ON DELETE CASCADE,
                               instructions        TEXT,
                               valid_until         DATE,
                               created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE prescription_items (
                                    id              UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
                                    prescription_id UUID         NOT NULL REFERENCES prescriptions(id) ON DELETE CASCADE,
                                    medicine_name   VARCHAR(200) NOT NULL,
                                    dosage          VARCHAR(100),
                                    frequency       VARCHAR(100),
                                    duration_days   INTEGER,
                                    notes           TEXT,
                                    CONSTRAINT chk_duration CHECK (duration_days IS NULL OR duration_days > 0)
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 8 — INVOICE & PAYMENT
-- ─────────────────────────────────────────────────────────────
CREATE TABLE invoices (
                          id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
                          appointment_id  UUID           NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE RESTRICT,
                          patient_id      UUID           NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
                          invoice_number  VARCHAR(50)    NOT NULL UNIQUE,  -- VD: INV-20240601-0001
                          subtotal        NUMERIC(12,2)  NOT NULL DEFAULT 0,
                          discount        NUMERIC(12,2)  NOT NULL DEFAULT 0,
                          tax             NUMERIC(12,2)  NOT NULL DEFAULT 0,
                          total           NUMERIC(12,2)  NOT NULL DEFAULT 0,
                          status          invoice_status NOT NULL DEFAULT 'draft',
                          issued_at       TIMESTAMP,
                          due_date        DATE,
                          notes           TEXT,
                          created_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
                          updated_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
                          CONSTRAINT chk_invoice_amounts CHECK (
                              subtotal >= 0 AND discount >= 0 AND tax >= 0 AND total >= 0
                              )
);

-- Chi tiết từng dòng trong hóa đơn
CREATE TABLE invoice_items (
                               id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
                               invoice_id      UUID           NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
                               description     VARCHAR(300)   NOT NULL,
                               quantity        INTEGER        NOT NULL DEFAULT 1,
                               unit_price      NUMERIC(12,2)  NOT NULL,
                               line_total      NUMERIC(12,2)  NOT NULL,
                               CONSTRAINT chk_inv_qty   CHECK (quantity > 0),
                               CONSTRAINT chk_inv_price CHECK (unit_price >= 0)
);

CREATE TABLE payments (
                          id              UUID           PRIMARY KEY DEFAULT gen_random_uuid(),
                          invoice_id      UUID           NOT NULL REFERENCES invoices(id) ON DELETE RESTRICT,
                          method          payment_method NOT NULL,
                          amount          NUMERIC(12,2)  NOT NULL,
                          status          payment_status NOT NULL DEFAULT 'unpaid',
                          transaction_ref VARCHAR(200),   -- mã giao dịch từ cổng thanh toán
                          paid_at         TIMESTAMP,
                          note            TEXT,
                          created_at      TIMESTAMP      NOT NULL DEFAULT NOW(),
                          CONSTRAINT chk_payment_amount CHECK (amount > 0)
);

-- ─────────────────────────────────────────────────────────────
-- GROUP 9 — ATTACHMENT (polymorphic)
-- ─────────────────────────────────────────────────────────────
-- Dùng chung cho medical_record, prescription, appointment, invoice
CREATE TABLE attachments (
                             id          UUID              PRIMARY KEY DEFAULT gen_random_uuid(),
                             owner_type  attachment_owner  NOT NULL,
                             owner_id    UUID              NOT NULL,       -- FK logic, không enforce ở DB
                             uploaded_by UUID              NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
                             file_name   VARCHAR(300)      NOT NULL,
                             file_url    VARCHAR(1000)     NOT NULL,
                             file_type   VARCHAR(100),                    -- MIME type: image/jpeg, application/pdf, ...
                             file_size   INTEGER,                         -- bytes
                             created_at  TIMESTAMP         NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- ─────────────────────────────────────────────────────────────
-- GROUP 9b — REVIEW
-- ─────────────────────────────────────────────────────────────
-- Chỉ cho phép review sau khi appointment đã completed
CREATE TABLE reviews (
                         id              UUID      PRIMARY KEY DEFAULT gen_random_uuid(),
                         appointment_id  UUID      NOT NULL UNIQUE REFERENCES appointments(id) ON DELETE CASCADE,
                         patient_id      UUID      NOT NULL REFERENCES patients(id) ON DELETE RESTRICT,
                         doctor_id       UUID      NOT NULL REFERENCES doctors(id) ON DELETE RESTRICT,
                         rating          SMALLINT  NOT NULL,
                         comment         TEXT,
                         is_visible      BOOLEAN   NOT NULL DEFAULT TRUE,
                         created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
                         CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5)
);

-- GROUP 10 — NOTIFICATION
-- ─────────────────────────────────────────────────────────────
CREATE TABLE notifications (
                               id          UUID       PRIMARY KEY DEFAULT gen_random_uuid(),
                               user_id     UUID       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                               type        notif_type NOT NULL DEFAULT 'general',
                               title       VARCHAR(200) NOT NULL,
                               body        TEXT,
                               ref_id      UUID,       -- id của appointment / invoice liên quan
                               is_read     BOOLEAN    NOT NULL DEFAULT FALSE,
                               sent_at     TIMESTAMP  NOT NULL DEFAULT NOW()
);

-- ─────────────────────────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────────────────────────
CREATE INDEX idx_users_phone            ON users(phone) WHERE phone IS NOT NULL;
CREATE INDEX idx_users_national_id      ON users(national_id) WHERE national_id IS NOT NULL;
CREATE INDEX idx_patients_user          ON patients(user_id);
CREATE INDEX idx_patients_created_by    ON patients(created_by);
CREATE INDEX idx_doctors_user           ON doctors(user_id);
CREATE INDEX idx_services_clinic        ON services(clinic_id);
CREATE INDEX idx_schedules_doctor       ON doctor_schedules(doctor_id);
CREATE INDEX idx_schedules_clinic       ON doctor_schedules(clinic_id);
CREATE INDEX idx_slots_schedule         ON time_slots(schedule_id);
CREATE INDEX idx_slots_date_status      ON time_slots(slot_date, status);
CREATE INDEX idx_slots_held_until       ON time_slots(held_until) WHERE held_until IS NOT NULL;
CREATE INDEX idx_appts_patient          ON appointments(patient_id);
CREATE INDEX idx_appts_doctor           ON appointments(doctor_id);
CREATE INDEX idx_appts_status           ON appointments(status);
CREATE INDEX idx_appts_booked_by        ON appointments(booked_by);
CREATE INDEX idx_appt_services_appt     ON appointment_services(appointment_id);
CREATE INDEX idx_medical_patient        ON medical_records(patient_id);
CREATE INDEX idx_medical_doctor         ON medical_records(doctor_id);
CREATE INDEX idx_presc_items_presc      ON prescription_items(prescription_id);
CREATE INDEX idx_invoices_patient       ON invoices(patient_id);
CREATE INDEX idx_invoices_number        ON invoices(invoice_number);
CREATE INDEX idx_invoice_items_inv      ON invoice_items(invoice_id);
CREATE INDEX idx_payments_invoice       ON payments(invoice_id);
CREATE INDEX idx_attachments_owner      ON attachments(owner_type, owner_id);
CREATE INDEX idx_staff_user            ON staff_profiles(user_id);
CREATE INDEX idx_reviews_doctor         ON reviews(doctor_id);
CREATE INDEX idx_reviews_appointment    ON reviews(appointment_id);
CREATE INDEX idx_notif_user_read        ON notifications(user_id, is_read);

-- ─────────────────────────────────────────────────────────────
-- SAMPLE DATA
-- ─────────────────────────────────────────────────────────────
INSERT INTO specializations (name, description) VALUES
                                                    ('Nội khoa',      'Chẩn đoán và điều trị bệnh nội tạng'),
                                                    ('Nhi khoa',      'Chăm sóc sức khỏe trẻ em'),
                                                    ('Da liễu',       'Bệnh về da, tóc, móng'),
                                                    ('Tim mạch',      'Bệnh tim và mạch máu'),
                                                    ('Thần kinh',     'Bệnh hệ thần kinh'),
                                                    ('Tai Mũi Họng',  'Bệnh tai, mũi, họng'),
                                                    ('Mắt',           'Bệnh về mắt'),
                                                    ('Xương khớp',    'Bệnh cơ xương khớp');

INSERT INTO clinics (name, address, phone, email) VALUES
                                                      ('Phòng khám Đa khoa Sài Gòn', '123 Nguyễn Thị Minh Khai, Q1, TP.HCM',      '02812345678', 'contact@sgclinic.vn'),
                                                      ('Phòng khám Nhi Bình Thạnh',  '45 Đinh Tiên Hoàng, Q.Bình Thạnh, TP.HCM',  '02887654321', 'info@nhiclinic.vn');