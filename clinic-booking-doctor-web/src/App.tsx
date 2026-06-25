import React, { useState, useEffect } from 'react';

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
  patientName: string;
  patientId: string;
  slotDate: string;
  startTime: string;
  endTime: string;
  reason: string;
  status: 'pending' | 'confirmed' | 'completed' | 'cancelled';
  // nested từ BE mới
  patient?: Patient;
  timeSlot?: string;
  code?: string;
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

// Helpers
function getWeekDates(): string[] {
  const today = new Date();
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() + i);
    return d.toISOString().split('T')[0];
  });
}

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString('vi-VN', { weekday: 'short', day: '2-digit', month: '2-digit' });
}

export default function App() {
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  const [rememberMe, setRememberMe] = useState(false);
  const [activeTab, setActiveTab] = useState<'queue' | 'history'>('queue');
  const [viewMode, setViewMode] = useState<'today' | 'week'>('today');
  const [appointments, setAppointments] = useState<Appointment[]>([]);
  const [selectedAppt, setSelectedAppt] = useState<Appointment | null>(null);
  const [history, setHistory] = useState<MedicalRecord[]>([]);
  const [doctorName, setDoctorName] = useState('');
  const [loading, setLoading] = useState(false);
  const [selectedWeekDate, setSelectedWeekDate] = useState<string>(
    new Date().toISOString().split('T')[0]
  );

  // Form States
  const [chiefComplaint, setChiefComplaint] = useState('');
  const [diagnosis, setDiagnosis] = useState('');
  const [treatmentPlan, setTreatmentPlan] = useState('');
  const [prescription, setPrescription] = useState<PrescriptionItem[]>([
    { medicineName: '', quantity: 1, dosage: '', durationDays: 7 }
  ]);

  // Login States
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');

  // Restore session
  useEffect(() => {
    const savedLogin = localStorage.getItem('doctor_logged_in');
    const savedRemember = localStorage.getItem('doctor_remember_me');
    const savedName = localStorage.getItem('doctor_full_name');
    if (savedLogin === 'true' && savedRemember === 'true') {
      setIsLoggedIn(true);
      setRememberMe(true);
      if (savedName) setDoctorName(savedName);
    }
  }, []);

  // Fetch appointments
  const fetchAppointments = (token: string) => {
    setLoading(true);
    fetch(`${API_BASE_URL}/appointments/doctor/me`, {
      headers: { 'Authorization': `Bearer ${token}`, 'Content-Type': 'application/json' }
    })
      .then(res => res.json())
      .then(data => {
        // Handle cả { success, data } và { content } page response
        const list: Appointment[] = data.data?.content ?? data.data ?? data.content ?? data ?? [];
        setAppointments(Array.isArray(list) ? list : []);
        const first = Array.isArray(list) ? (list[0] ?? null) : null;
        setSelectedAppt(first);
      })
      .catch(err => console.error('Error fetching appointments:', err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (!isLoggedIn) return;
    const token = localStorage.getItem('doctor_access_token');
    if (token) fetchAppointments(token);
  }, [isLoggedIn]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const response = await fetch(`${API_BASE_URL}/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone: username, password }),
      });

      if (response.ok) {
        const data = await response.json();
        // BE wrap: { data: { accessToken, ... } }
        const payload = data.data ?? data;
        const token = payload.accessToken;
        localStorage.setItem('doctor_access_token', token);

        // Lấy tên bác sĩ từ /doctors/me
        try {
          const meRes = await fetch(`${API_BASE_URL}/doctors/me`, {
            headers: { 'Authorization': `Bearer ${token}` }
          });
          if (meRes.ok) {
            const meData = await meRes.json();
            const profile = meData.data ?? meData;
            const name = profile.fullName ?? '';
            setDoctorName(name);
            if (rememberMe) localStorage.setItem('doctor_full_name', name);
          }
        } catch (_) { /* ignore nếu endpoint chưa có */ }

        setIsLoggedIn(true);
        if (rememberMe) {
          localStorage.setItem('doctor_logged_in', 'true');
          localStorage.setItem('doctor_remember_me', 'true');
        }
      } else {
        alert('Đăng nhập thất bại! Vui lòng kiểm tra lại tài khoản.');
      }
    } catch (error) {
      alert('Không thể kết nối đến Backend Server!');
    }
  };

  const handleLogout = () => {
    setIsLoggedIn(false);
    setAppointments([]);
    setSelectedAppt(null);
    setHistory([]);
    setDoctorName('');
    localStorage.removeItem('doctor_logged_in');
    localStorage.removeItem('doctor_remember_me');
    localStorage.removeItem('doctor_access_token');
    localStorage.removeItem('doctor_full_name');
  };

  const handleSelectAppointment = (appt: Appointment) => {
    setSelectedAppt(appt);
    setChiefComplaint('');
    setDiagnosis('');
    setTreatmentPlan('');
    setPrescription([{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
  };

  const handleAddMedicine = () =>
    setPrescription([...prescription, { medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);

  const handleRemoveMedicine = (index: number) => {
    const next = prescription.filter((_, i) => i !== index);
    setPrescription(next.length ? next : [{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
  };

  const handlePrescriptionChange = (index: number, field: keyof PrescriptionItem, value: any) => {
    const next = [...prescription];
    next[index] = { ...next[index], [field]: value };
    setPrescription(next);
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

    try {
      const token = localStorage.getItem('doctor_access_token');
      const response = await fetch(`${API_BASE_URL}/medical-records`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
        body: JSON.stringify(examData),
      });

      if (response.ok) {
        const patientName = selectedAppt.patientName ?? selectedAppt.patient?.fullName ?? '';
        alert(`Khám bệnh thành công cho bệnh nhân: ${patientName}`);
        const updatedAppts = appointments.map(appt =>
          appt.id === selectedAppt.id ? { ...appt, status: 'completed' as const } : appt
        );
        setAppointments(updatedAppts);
        setSelectedAppt(updatedAppts.find(a => a.status === 'confirmed') ?? null);
        setChiefComplaint(''); setDiagnosis(''); setTreatmentPlan('');
        setPrescription([{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
      } else {
        alert('Gửi bệnh án lên server thất bại.');
      }
    } catch {
      alert('Không thể kết nối đến Backend Server để lưu bệnh án!');
    }
  };

  // Filter appointments by date cho week view
  const weekDates = getWeekDates();
  const filteredAppointments = viewMode === 'today'
    ? appointments.filter(a => {
        const today = new Date().toISOString().split('T')[0];
        return (a.slotDate ?? '') === today;
      })
    : appointments.filter(a => (a.slotDate ?? '') === selectedWeekDate);

  // Helpers để lấy tên/giờ từ response BE
  const getPatientName = (appt: Appointment) =>
    appt.patientName ?? appt.patient?.fullName ?? 'N/A';
  const getTimeDisplay = (appt: Appointment) => {
    if (appt.startTime) return `${appt.startTime}${appt.endTime ? ' - ' + appt.endTime : ''}`;
    return appt.timeSlot ?? '';
  };

  // ── Login screen ──────────────────────────────────────────

  if (!isLoggedIn) {
    return (
      <div className="login-container">
        <form className="login-card" onSubmit={handleLogin}>
          <div className="login-header">
            <div className="login-logo">✙</div>
            <h2>UMC CLINIC PORTAL</h2>
            <p style={{ color: 'var(--text-light)', fontSize: '13px', marginTop: '6px' }}>
              Cổng thông tin Khám chữa bệnh dành cho Bác sĩ
            </p>
          </div>
          <div className="form-group">
            <label>Số điện thoại</label>
            <input type="text" className="form-control" value={username}
              onChange={e => setUsername(e.target.value)} required />
          </div>
          <div className="form-group">
            <label>Mật khẩu</label>
            <input type="password" className="form-control" value={password}
              onChange={e => setPassword(e.target.value)} required />
          </div>
          <div className="form-group" style={{ display: 'flex', alignItems: 'center', gap: '8px', marginTop: '12px' }}>
            <input type="checkbox" id="rememberMe" checked={rememberMe}
              onChange={e => setRememberMe(e.target.checked)}
              style={{ width: '16px', height: '16px', cursor: 'pointer' }} />
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

  // ── Main app ──────────────────────────────────────────────

  return (
    <div className="app-container">
      <div className="sidebar">
        <div className="sidebar-logo">
          <span className="sidebar-logo-icon">✙</span>
          <span className="sidebar-logo-text">UMC Care</span>
        </div>

        <ul className="sidebar-menu">
          <li className={`sidebar-menu-item ${activeTab === 'queue' ? 'active' : ''}`}
            onClick={() => setActiveTab('queue')}>
            📋 Lịch khám hôm nay
          </li>
          <li className={`sidebar-menu-item ${activeTab === 'history' ? 'active' : ''}`}
            onClick={() => setActiveTab('history')}>
            📚 Lịch sử chẩn đoán
          </li>
        </ul>

        <div className="sidebar-doctor-profile">
          <div className="sidebar-doctor-avatar">
            {doctorName ? doctorName.split(' ').pop()?.slice(0, 2).toUpperCase() : 'BS'}
          </div>
          <div className="sidebar-doctor-info">
            {/* FIX 1: Hiển thị tên bác sĩ */}
            <span className="sidebar-doctor-name">{doctorName || 'Bác sĩ'}</span>
            <span className="sidebar-doctor-role">Bác sĩ</span>
          </div>
        </div>
      </div>

      <div className="main-content">
        <header className="top-bar">
          <h1 className="top-bar-title">
            {activeTab === 'queue' ? 'Bảng khám bệnh hàng ngày' : 'Sổ tay lịch sử chẩn đoán bệnh nhân'}
          </h1>
          <button className="btn btn-outline btn-sm" onClick={handleLogout}>Đăng xuất</button>
        </header>

        <main className="content-body">
          {activeTab === 'queue' ? (
            <div className="dashboard-grid">
              <div className="card">
                {/* FIX 2: Toggle hôm nay / cả tuần */}
                <div className="card-title" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: '10px' }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%', alignItems: 'center' }}>
                    <span>Danh sách chờ khám</span>
                    <span className="badge badge-primary">
                      {filteredAppointments.filter(a => a.status === 'confirmed').length} bệnh nhân
                    </span>
                  </div>

                  {/* Toggle buttons */}
                  <div style={{ display: 'flex', gap: '6px' }}>
                    <button
                      className={`btn btn-sm ${viewMode === 'today' ? 'btn-primary' : 'btn-outline'}`}
                      onClick={() => setViewMode('today')}
                    >
                      Hôm nay
                    </button>
                    <button
                      className={`btn btn-sm ${viewMode === 'week' ? 'btn-primary' : 'btn-outline'}`}
                      onClick={() => setViewMode('week')}
                    >
                      Cả tuần
                    </button>
                  </div>

                  {/* Week date picker */}
                  {viewMode === 'week' && (
                    <div style={{ display: 'flex', gap: '4px', flexWrap: 'wrap' }}>
                      {weekDates.map(date => (
                        <button
                          key={date}
                          onClick={() => setSelectedWeekDate(date)}
                          style={{
                            padding: '4px 8px',
                            fontSize: '11px',
                            borderRadius: '6px',
                            border: '1px solid var(--border)',
                            cursor: 'pointer',
                            backgroundColor: selectedWeekDate === date ? 'var(--primary)' : 'white',
                            color: selectedWeekDate === date ? 'white' : 'var(--text-dark)',
                            fontWeight: selectedWeekDate === date ? 'bold' : 'normal',
                          }}
                        >
                          {formatDate(date)}
                        </button>
                      ))}
                    </div>
                  )}
                </div>

                <div className="patient-list">
                  {loading && <p style={{ padding: '16px', color: 'var(--text-light)' }}>Đang tải...</p>}
                  {!loading && filteredAppointments.length === 0 && (
                    <p style={{ padding: '16px', color: 'var(--text-light)' }}>
                      Không có bệnh nhân nào {viewMode === 'today' ? 'hôm nay' : 'ngày này'}.
                    </p>
                  )}
                  {filteredAppointments.map(appt => {
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
                          <span className="patient-name">{getPatientName(appt)}</span>
                          <span className="patient-time">{getTimeDisplay(appt)}</span>
                        </div>
                        <div className="patient-item-header" style={{ marginBottom: 0 }}>
                          <span style={{ fontSize: '11px', color: 'var(--text-light)' }}>
                            {appt.slotDate ?? ''}
                          </span>
                          {isCompleted
                            ? <span className="badge badge-success">Đã khám xong</span>
                            : appt.status === 'confirmed'
                              ? <span className="badge badge-warning">Chờ khám</span>
                              : <span className="badge" style={{ background: '#eee', color: '#999' }}>
                                  {appt.status}
                                </span>
                          }
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>

              {selectedAppt ? (
                <div className="card">
                  <div className="card-title" style={{ borderBottom: '1px solid var(--border)', paddingBottom: '12px', marginBottom: '20px' }}>
                    Chi tiết khám bệnh: {getPatientName(selectedAppt)}
                  </div>

                  <div className="patient-profile-summary">
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Ngày khám</span>
                      <span className="profile-summary-value">{selectedAppt.slotDate}</span>
                    </div>
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Giờ khám</span>
                      <span className="profile-summary-value">{getTimeDisplay(selectedAppt)}</span>
                    </div>
                    <div className="profile-summary-item">
                      <span className="profile-summary-label">Lý do khám</span>
                      <span className="profile-summary-value">{selectedAppt.reason || '—'}</span>
                    </div>
                    {selectedAppt.patient?.nationalId && (
                      <div className="profile-summary-item">
                        <span className="profile-summary-label">CCCD</span>
                        <span className="profile-summary-value">{selectedAppt.patient.nationalId}</span>
                      </div>
                    )}
                  </div>

                  <form onSubmit={handleSubmitExam}>
                    <div className="form-group">
                      <label>1. Triệu chứng lâm sàng</label>
                      <textarea className="form-control"
                        placeholder="Triệu chứng khám lâm sàng ban đầu..."
                        value={chiefComplaint} onChange={e => setChiefComplaint(e.target.value)} required />
                    </div>
                    <div className="form-group">
                      <label>2. Chẩn đoán y tế (Ghi tên bệnh hoặc mã ICD-10)</label>
                      <input type="text" className="form-control"
                        placeholder="VD: Tăng huyết áp vô căn độ II, Viêm họng cấp..."
                        value={diagnosis} onChange={e => setDiagnosis(e.target.value)} required />
                    </div>
                    <div className="form-group">
                      <label>3. Phác đồ & Lời khuyên điều trị</label>
                      <textarea className="form-control"
                        placeholder="Chế độ nghỉ ngơi, kiêng ăn mặn, tập thể dục nhẹ, tái khám..."
                        value={treatmentPlan} onChange={e => setTreatmentPlan(e.target.value)} />
                    </div>

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
                                <input type="text" className="form-control" placeholder="VD: Amlodipin 5mg"
                                  value={item.medicineName}
                                  onChange={e => handlePrescriptionChange(index, 'medicineName', e.target.value)} />
                              </td>
                              <td>
                                <input type="number" className="form-control" min="1" value={item.quantity}
                                  onChange={e => handlePrescriptionChange(index, 'quantity', parseInt(e.target.value) || 1)} />
                              </td>
                              <td>
                                <input type="text" className="form-control" placeholder="Sáng 1 viên sau ăn..."
                                  value={item.dosage}
                                  onChange={e => handlePrescriptionChange(index, 'dosage', e.target.value)} />
                              </td>
                              <td style={{ textAlign: 'center' }}>
                                <button type="button" className="btn btn-danger btn-sm"
                                  onClick={() => handleRemoveMedicine(index)}
                                  style={{ padding: '4px 8px', borderRadius: '4px' }}>✕</button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>

                    <div className="exam-actions">
                      <button type="button" className="btn btn-outline" onClick={() => {
                        setChiefComplaint(''); setDiagnosis(''); setTreatmentPlan('');
                        setPrescription([{ medicineName: '', quantity: 1, dosage: '', durationDays: 7 }]);
                      }}>Làm sạch form</button>
                      <button type="submit" className="btn btn-primary">
                        💾 Lưu Hồ Sơ & Đơn Thuốc
                      </button>
                    </div>
                  </form>
                </div>
              ) : (
                <div className="card" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', minHeight: '300px' }}>
                  <span style={{ fontSize: '48px' }}></span>
                  <h3 style={{ marginTop: '16px', fontWeight: 'bold' }}>Đã hoàn tất khám hết bệnh nhân</h3>
                  <p style={{ color: 'var(--text-light)', fontSize: '13px', marginTop: '6px' }}>
                    Bạn không có bệnh nhân nào đang chờ trong hàng đợi lúc này.
                  </p>
                </div>
              )}
            </div>
          ) : (
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
                  {history.length === 0 && (
                    <tr>
                      <td colSpan={5} style={{ textAlign: 'center', color: 'var(--text-light)', padding: '24px' }}>
                        Chưa có lịch sử khám bệnh.
                      </td>
                    </tr>
                  )}
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
                              <li key={idx}><strong>{med.medicineName}</strong> - SL: {med.quantity} ({med.dosage})</li>
                            ))}
                          </ul>
                        ) : (
                          <span style={{ color: 'var(--text-light)', fontSize: '12px', fontStyle: 'italic' }}>Không kê đơn</span>
                        )}
                      </td>
                      <td><span className="badge badge-success">Phòng khám Q1</span></td>
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