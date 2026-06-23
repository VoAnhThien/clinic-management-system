import React, { useState, useEffect } from 'react';

// Đổi USE_MOCK thành false khi bạn sẵn sàng kết nối với API thật của Spring Boot.
const USE_MOCK = false;
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'https://clinic-management-system-82ar.onrender.com/api';

// Types
interface PrescriptionItem {
  medicineName: string;
  quantity: number;
  dosage: string;
  durationDays: number;
}

interface Patient {
  id: string;
  fullName: string;
  gender: 'male' | 'female' | 'other';
  dateOfBirth: string;
  phone: string;
  nationalId: string;
  bloodType: string;
  allergies: string;
  address: string;
}

interface Appointment {
  id: string;
  patient: Patient;
  timeSlot: string;
  reason: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  code: string;
}

interface MedicalRecord {
  id: string;
  patientName: string;
  date: string;
  chiefComplaint: string;
  diagnosis: string;
  treatmentPlan: string;
  prescription: PrescriptionItem[];
}

// Initial Mock Data
const initialPatients: Patient[] = [
  {
    id: 'pat-1',
    fullName: 'NGUYỄN VĂN A',
    gender: 'male',
    dateOfBirth: '1996-05-15',
    phone: '0987654321',
    nationalId: '079096001234',
    bloodType: 'O+',
    allergies: 'Không có dị ứng thuốc',
    address: '783 Trần Hưng Đạo, Phường 1, Quận 5, TP.HCM',
  },
  {
    id: 'pat-2',
    fullName: 'TRẦN THỊ MAI',
    gender: 'female',
    dateOfBirth: '1998-02-20',
    phone: '0901234567',
    nationalId: '079198004321',
    bloodType: 'AB-',
    allergies: 'Dị ứng phấn hoa',
    address: '12 Điện Biên Phủ, Quận Bình Thạnh, TP.HCM',
  },
  {
    id: 'pat-3',
    fullName: 'NGUYỄN HOÀNG LÂM',
    gender: 'male',
    dateOfBirth: '2018-10-12',
    phone: '0987654321',
    nationalId: 'Không có',
    bloodType: 'O+',
    allergies: 'Dị ứng với Hải sản',
    address: '783 Trần Hưng Đạo, Phường 1, Quận 5, TP.HCM',
  }
];

const initialAppointments: Appointment[] = [
  {
    id: 'appt-1',
    patient: initialPatients[0],
    timeSlot: '09:00 - 09:30',
    reason: 'Tái khám tăng huyết áp định kỳ.',
    status: 'confirmed',
    code: 'UMC-77391-A',
  },
  {
    id: 'appt-2',
    patient: initialPatients[1],
    timeSlot: '09:30 - 10:00',
    reason: 'Ngứa ngáy da liễu tay chân.',
    status: 'confirmed',
    code: 'UMC-88123-B',
  },
  {
    id: 'appt-3',
    patient: initialPatients[2],
    timeSlot: '10:00 - 10:30',
    reason: 'Sốt nhẹ, ho có đờm 2 ngày nay.',
    status: 'confirmed',
    code: 'UMC-99120-C',
  }
];

const initialHistory: MedicalRecord[] = [
  {
    id: 'rec-old-1',
    patientName: 'NGUYỄN VĂN A',
    date: '2026-05-10',
    chiefComplaint: 'Đau ngực trái nhẹ kèm khó thở nhẹ khi leo cầu thang.',
    diagnosis: 'Tăng huyết áp vô căn độ II, Thiếu máu cơ tim nhẹ.',
    treatmentPlan: 'Nghỉ ngơi hợp lý, hạn chế ăn mặn, tập thể dục nhẹ nhàng 30p mỗi ngày.',
    prescription: [
      { medicineName: 'Amlodipin 5mg', quantity: 30, dosage: 'Sáng 1 viên sau ăn', durationDays: 30 },
      { medicineName: 'Concor 2.5mg', quantity: 30, dosage: 'Sáng 1 viên trước ăn', durationDays: 30 }
    ]
  }
];

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [activeTab, setActiveTab] = useState<'queue' | 'history'>('queue');
  const [appointments, setAppointments] = useState<Appointment[]>(initialAppointments);
  const [selectedAppt, setSelectedAppt] = useState<Appointment | null>(initialAppointments[0]);
  const [history, setHistory] = useState<MedicalRecord[]>(initialHistory);

  // Form States
  const [chiefComplaint, setChiefComplaint] = useState('');
  const [diagnosis, setDiagnosis] = useState('');
  const [treatmentPlan, setTreatmentPlan] = useState('');
  const [prescription, setPrescription] = useState<PrescriptionItem[]>([
    { medicineName: '', quantity: 1, dosage: '', durationDays: 7 }
  ]);

  // Login States
  const [username, setUsername] = useState('doctor_an');
  const [password, setPassword] = useState('password123');

  // Check login state on component mount
  useEffect(() => {
    const savedLogin = localStorage.getItem('doctor_logged_in');
    const savedRemember = localStorage.getItem('doctor_remember_me');
    if (savedLogin === 'true' && savedRemember === 'true') {
      setIsLoggedIn(true);
      setRememberMe(true);
    }
  }, []);

  // Fetch appointments from API (Example hook for developer)
  useEffect(() => {
    if (USE_MOCK) return;

    // Ví dụ cách kết nối API thật của Spring Boot
    const token = localStorage.getItem('doctor_access_token');
    if (!token) return;

    fetch(`${API_BASE_URL}/appointments/doctor/me`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      }
    })
      .then(res => res.json())
      .then(() => {
        // Ánh xạ dữ liệu trả về từ Spring Boot DTO sang State
        // setAppointments(data);
      })
      .catch(err => console.error("Error fetching appointments:", err));
  }, [isLoggedIn]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();

    if (USE_MOCK) {
      if (username === 'doctor_an' && password === 'password123') {
        setIsLoggedIn(true);
        if (rememberMe) {
          localStorage.setItem('doctor_logged_in', 'true');
          localStorage.setItem('doctor_remember_me', 'true');
        }
      } else {
        alert('Tên đăng nhập hoặc mật khẩu không đúng! (Gợi ý: doctor_an / password123)');
      }
      return;
    }

    // ========================================================================
    // INTEGRATE SPRING BOOT REAL API FOR LOGIN
    // ========================================================================
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          phone: username, // Hoặc nationalId tùy thuộc cách thiết kế đăng nhập của BE
          password: password,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        // Giả sử API trả về JWT Token và thông tin User
        localStorage.setItem('doctor_access_token', data.accessToken);
        setIsLoggedIn(true);
        if (rememberMe) {
          localStorage.setItem('doctor_logged_in', 'true');
          localStorage.setItem('doctor_remember_me', 'true');
        }
      } else {
        alert('Đăng nhập thất bại! Vui lòng kiểm tra lại tài khoản backend.');
      }
    } catch (error) {
      console.error("Login API error:", error);
      alert('Không thể kết nối đến Backend Server!');
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    localStorage.removeItem('doctor_logged_in');
    localStorage.removeItem('doctor_remember_me');
    localStorage.removeItem('doctor_access_token');
  };

  const handleSelectAppointment = (appt: Appointment) => {
    setSelectedAppt(appt);
    setChiefComplaint('');
    setDiagnosis('');
    setTreatmentPlan('');
    setPrescription([{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
  };

  const handleAddMedicine = () => {
    setPrescription([
      ...prescription,
      { medicineName: '', quantity: 1, dosage: '', durationDays: 7 }
    ]);
  };

  const handleRemoveMedicine = (index: number) => {
    const newPrescription = prescription.filter((_, i) => i !== index);
    setPrescription(newPrescription.length ? newPrescription : [{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
  };

  const handlePrescriptionChange = (index: number, field: keyof PrescriptionItem, value: any) => {
    const newPrescription = [...prescription];
    newPrescription[index] = {
      ...newPrescription[index],
      [field]: value
    };
    setPrescription(newPrescription);
  };

  const handleSubmitExam = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedAppt) return;

    if (!chiefComplaint || !diagnosis) {
      alert('Vui lòng điền Triệu chứng và Chẩn đoán!');
      return;
    }

    const examData = {
      appointmentId: selectedAppt.id,
      chiefComplaint,
      diagnosis,
      treatmentPlan,
      prescriptionItems: prescription.filter(item => item.medicineName !== '')
    };

    if (USE_MOCK) {
      // Add to Medical Record History locally
      const newRecord: MedicalRecord = {
        id: `rec-${Date.now()}`,
        patientName: selectedAppt.patient.fullName,
        date: new Date().toISOString().split('T')[0],
        chiefComplaint,
        diagnosis,
        treatmentPlan,
        prescription: examData.prescriptionItems
      };

      setHistory([newRecord, ...history]);

      // Update appointment status to completed
      const updatedAppts = appointments.map(appt => {
        if (appt.id === selectedAppt.id) {
          return { ...appt, status: 'completed' as const };
        }
        return appt;
      });
      setAppointments(updatedAppts);

      alert(`Khám bệnh thành công cho bệnh nhân: ${selectedAppt.patient.fullName}\nHồ sơ bệnh án và hóa đơn đã được phát hành!`);
      
      const nextPending = updatedAppts.find(appt => appt.status === 'confirmed');
      setSelectedAppt(nextPending || null);

      // Reset Form
      setChiefComplaint('');
      setDiagnosis('');
      setTreatmentPlan('');
      setPrescription([{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
      return;
    }

    // ========================================================================
    // INTEGRATE SPRING BOOT REAL API FOR SUBMITTING EXAMINATION
    // ========================================================================
    try {
      const token = localStorage.getItem('doctor_access_token');
      const response = await fetch(`${API_BASE_URL}/medical-records`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(examData),
      });

      if (response.ok) {
        alert('Đã gửi thông tin bệnh án thành công lên cơ sở dữ liệu!');
        
        // Reload appointments from BE
        window.location.reload();
      } else {
        alert('Gửi bệnh án lên server thất bại.');
      }
    } catch (error) {
      console.error("Submit record API error:", error);
      alert('Không thể kết nối đến Backend Server để lưu bệnh án!');
    }
  };

  if (!isLoggedIn) {
    return (
      <div className="login-container">
        <form className="login-card" onSubmit={handleLogin}>
          <div className="login-header">
            <div className="login-logo">✙</div>
            <h2>UMC CLINIC PORTAL</h2>
            <p style={{ color: 'var(--text-light)', fontSize: '13px', marginTop: '6px' }}>Cổng thông tin Khám chữa bệnh dành cho Bác sĩ</p>
          </div>

          {/* Configuration Status Notice */}
          <div style={{
            fontSize: '11px', 
            padding: '8px 12px', 
            borderRadius: '6px', 
            marginBottom: '16px',
            backgroundColor: USE_MOCK ? '#fff7ed' : '#ecfdf5',
            color: USE_MOCK ? '#c2410c' : '#15803d',
            border: `1px solid ${USE_MOCK ? '#ffedd5' : '#dcfce7'}`,
            display: 'flex',
            alignItems: 'center',
            gap: '8px'
          }}>
            <span style={{ fontSize: '14px' }}>{USE_MOCK ? '⚠️' : '✓'}</span>
            <span>
              {USE_MOCK 
                ? 'Đang ở chế độ Mock Data (Gợi ý đăng nhập: doctor_an / password123)' 
                : `Kết nối Backend thật: ${API_BASE_URL}`}
            </span>
          </div>
          
          <div className="form-group">
            <label>Tên đăng nhập / Số điện thoại</label>
            <input 
              type="text" 
              className="form-control" 
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              required 
            />
          </div>
          
          <div className="form-group">
            <label>Mật khẩu</label>
            <input 
              type="password" 
              className="form-control" 
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required 
            />
          </div>

          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '12px' }}>
            <input 
              type="checkbox" 
              id="rememberMe"
              checked={rememberMe}
              onChange={(e) => setRememberMe(e.target.checked)}
              style={{ width: '16px', height: '16px', cursor: 'pointer' }}
            />
            <label htmlFor="rememberMe" style={{ margin: 0, cursor: 'pointer', fontSize: '13px', userSelect: 'none' }}>
              Ghi nhớ đăng nhập
            </label>
          </div>
          
          <button type="submit" className="btn btn-primary" style={{ width: '100%', marginTop: '16px' }}>
            Đăng Nhập Hệ Thống
          </button>
        </form>
      </div>
    );
  }

  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <div className="sidebar">
        <div className="sidebar-logo">
          <span className="sidebar-logo-icon">✙</span>
          <span className="sidebar-logo-text">UMC Care</span>
        </div>
        
        <ul className="sidebar-menu">
          <li 
            className={`sidebar-menu-item ${activeTab === 'queue' ? 'active' : ''}`}
            onClick={() => setActiveTab('queue')}
          >
            📋 Lịch khám hôm nay
          </li>
          <li 
            className={`sidebar-menu-item ${activeTab === 'history' ? 'active' : ''}`}
            onClick={() => setActiveTab('history')}
          >
            📚 Lịch sử chẩn đoán
          </li>
        </ul>

        <div className="sidebar-doctor-profile">
          <div className="sidebar-doctor-avatar">AN</div>
          <div className="sidebar-doctor-info">
            <span className="sidebar-doctor-name">PGS.TS Nguyễn Văn An</span>
            <span className="sidebar-doctor-role">Khoa Nội tổng quát</span>
          </div>
        </div>
      </div>

      {/* Main Content Area */}
      <div className="main-content">
        <header className="top-bar">
          <h1 className="top-bar-title">
            {activeTab === 'queue' ? 'Bảng khám bệnh hàng ngày' : 'Sổ tay lịch sử chẩn đoán bệnh nhân'}
          </h1>
          <button className="btn btn-outline btn-sm" onClick={handleLogout}>
            Đăng xuất
          </button>
        </header>

        <main className="content-body">
          {activeTab === 'queue' ? (
            <div className="dashboard-grid">
              
              {/* Left Column: Waiting queue list */}
              <div className="card">
                <div className="card-title">
                  Danh sách chờ khám 
                  <span className="badge badge-primary">
                    {appointments.filter(a => a.status === 'confirmed').length} bệnh nhân
                  </span>
                </div>
                
                <div className="patient-list">
                  {appointments.map(appt => {
                    const isSelected = selectedAppt?.id === appt.id;
                    const isCompleted = appt.status === 'completed';
                    
                    return (
                      <div 
                        key={appt.id}
                        className={`patient-item ${isSelected ? 'active' : ''}`}
                        onClick={() => !isCompleted && handleSelectAppointment(appt)}
                        style={{ opacity: isCompleted ? 0.6 : 1, cursor: isCompleted ? 'default' : 'pointer' }}
                      >
                        <div className="patient-item-header">
                          <span className="patient-name">{appt.patient.fullName}</span>
                          <span className="patient-time">{appt.timeSlot}</span>
                        </div>
                        <div className="patient-item-header" style={{ marginBottom: 0 }}>
                          <span style={{ fontSize: '11px', color: 'var(--text-light)' }}>
                            {appt.patient.gender === 'male' ? 'Nam' : 'Nữ'} - {appt.patient.dateOfBirth}
                          </span>
                          {isCompleted ? (
                            <span className="badge badge-success">Đã khám xong</span>
                          ) : (
                            <span className="badge badge-warning">Chờ khám</span>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Right Column: Diagnostic Form */}
              {selectedAppt ? (
                <div className="card">
                  <div className="card-title" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '12px', marginBottom: '20px' }}>
                    Chi tiết khám bệnh: {selectedAppt.patient.fullName}
                    <span className="badge badge-primary">{selectedAppt.code}</span>
                  </div>

                  {/* Patient Profile Box */}
                  <div className="patient-profile-summary">
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Mã bệnh nhân</span>
                      <span className="profile-summary-value">{selectedAppt.patient.id.toUpperCase()}</span>
                    </div>
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Số CCCD</span>
                      <span className="profile-summary-value">{selectedAppt.patient.nationalId}</span>
                    </div>
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Nhóm máu</span>
                      <span className="profile-summary-value" style={{ color: 'var(--danger)' }}>{selectedAppt.patient.bloodType}</span>
                    </div>
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Dị ứng</span>
                      <span className="profile-summary-value" style={{ color: 'var(--warning)' }}>{selectedAppt.patient.allergies}</span>
                    </div>
                  </div>

                  <form onSubmit={handleSubmitExam}>
                    <div className="form-group">
                      <label>1. Triệu chứng lâm sàng (Mô tả triệu chứng bệnh nhân khai báo)</label>
                      <textarea 
                        className="form-control" 
                        placeholder="Triệu chứng khám lâm sàng ban đầu..."
                        value={chiefComplaint}
                        onChange={(e) => setChiefComplaint(e.target.value)}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label>2. Chẩn đoán y tế (Ghi tên bệnh hoặc mã ICD-10)</label>
                      <input 
                        type="text" 
                        className="form-control" 
                        placeholder="VD: Tăng huyết áp vô căn độ II, Viêm họng cấp..."
                        value={diagnosis}
                        onChange={(e) => setDiagnosis(e.target.value)}
                        required
                      />
                    </div>

                    <div className="form-group">
                      <label>3. Phác đồ & Lời khuyên điều trị</label>
                      <textarea 
                        className="form-control" 
                        placeholder="Chế độ nghỉ ngơi, kiêng ăn mặn, tập thể dục nhẹ, tái khám..."
                        value={treatmentPlan}
                        onChange={(e) => setTreatmentPlan(e.target.value)}
                      />
                    </div>

                    {/* Prescription Editor section */}
                    <div style={{ marginTop: '24px' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <h3 style={{ fontSize: '14px', fontWeight: 'bold' }}>4. Kê đơn thuốc điện tử</h3>
                        <button type="button" className="btn btn-secondary btn-sm" onClick={handleAddMedicine}>
                          + Thêm thuốc
                        </button>
                      </div>

                      <table className="prescription-table">
                        <thead>
                          <tr>
                            <th style={{ width: '40%' }}>Tên thuốc / Biệt dược</th>
                            <th style={{ width: '15%' }}>Số lượng</th>
                            <th style={{ width: '35%' }}>Liều dùng & Cách dùng</th>
                            <th style={{ width: '10%' }}></th>
                          </tr>
                        </thead>
                        <tbody>
                          {prescription.map((item, index) => (
                            <tr key={index}>
                              <td>
                                <input 
                                  type="text" 
                                  className="form-control" 
                                  placeholder="VD: Amlodipin 5mg"
                                  value={item.medicineName}
                                  onChange={(e) => handlePrescriptionChange(index, 'medicineName', e.target.value)}
                                />
                              </td>
                              <td>
                                <input 
                                  type="number" 
                                  className="form-control" 
                                  min="1"
                                  value={item.quantity}
                                  onChange={(e) => handlePrescriptionChange(index, 'quantity', parseInt(e.target.value) || 1)}
                                />
                              </td>
                              <td>
                                <input 
                                  type="text" 
                                  className="form-control" 
                                  placeholder="Sáng 1 viên sau ăn, tối..."
                                  value={item.dosage}
                                  onChange={(e) => handlePrescriptionChange(index, 'dosage', e.target.value)}
                                />
                              </td>
                              <td style={{ textAlign: 'center' }}>
                                <button 
                                  type="button" 
                                  className="btn btn-danger btn-sm" 
                                  onClick={() => handleRemoveMedicine(index)}
                                  style={{ padding: '4px 8px', borderRadius: '4px' }}
                                >
                                  ✕
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>

                    <div className="exam-actions">
                      <button type="button" className="btn btn-outline" onClick={() => {
                        setChiefComplaint('');
                        setDiagnosis('');
                        setTreatmentPlan('');
                        setPrescription([{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
                      }}>
                        Làm sạch form
                      </button>
                      <button type="submit" className="btn btn-primary">
                        💾 Lưu Hồ Sơ & Đơn Thuốc
                      </button>
                    </div>
                  </form>
                </div>
              ) : (
                <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '300px' }}>
                  <span style={{ fontSize: '48px' }}>🎉</span>
                  <h3 style={{ marginTop: '16px', fontWeight: 'bold' }}>Đã hoàn tất khám hết bệnh nhân</h3>
                  <p style={{ color: 'var(--text-light)', fontSize: '13px', marginTop: '6px' }}>Bạn không có bệnh nhân nào đang chờ trong hàng đợi lúc này.</p>
                </div>
              )}

            </div>
          ) : (
            // Diagnostic History List Tab
            <div className="card">
              <div className="card-title">Sổ y bạ điện tử - Lịch sử điều trị bệnh nhân</div>
              
              <table className="history-table">
                <thead>
                  <tr>
                    <th style={{ width: '15%' }}>Ngày khám</th>
                    <th style={{ width: '20%' }}>Bệnh nhân</th>
                    <th style={{ width: '25%' }}>Chẩn đoán</th>
                    <th style={{ width: '30%' }}>Đơn thuốc đã kê</th>
                    <th style={{ width: '10%' }}>Phòng khám</th>
                  </tr>
                </thead>
                <tbody>
                  {history.map(rec => (
                    <tr key={rec.id}>
                      <td style={{ fontWeight: '600' }}>{rec.date}</td>
                      <td style={{ fontWeight: 'bold' }}>{rec.patientName}</td>
                      <td>
                        <div><strong>Mô tả:</strong> {rec.diagnosis}</div>
                        <div style={{ fontSize: '12px', color: 'var(--text-light)', marginTop: '4px' }}>
                          <strong>Kế hoạch:</strong> {rec.treatmentPlan}
                        </div>
                      </td>
                      <td>
                        {rec.prescription.length ? (
                          <ul style={{ paddingLeft: '16px', fontSize: '13px', color: 'var(--text-light)' }}>
                            {rec.prescription.map((med, idx) => (
                              <li key={idx}>
                                <strong>{med.medicineName}</strong> - SL: {med.quantity} ({med.dosage})
                              </li>
                            ))}
                          </ul>
                        ) : (
                          <span style={{ color: 'var(--text-light)', fontSize: '12px', fontStyle: 'italic' }}>Không kê đơn</span>
                        )}
                      </td>
                      <td>
                        <span className="badge badge-success">Phòng khám Q1</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </main>
      </div>
    </div>
  );
}
