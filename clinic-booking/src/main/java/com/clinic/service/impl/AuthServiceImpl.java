package com.clinic.service.impl;

import com.clinic.dto.request.LoginRequest;
import com.clinic.dto.request.RefreshTokenRequest;
import com.clinic.dto.request.RegisterRequest;
import com.clinic.dto.response.AuthResponse;
import com.clinic.entity.Patient;
import com.clinic.entity.User;
import com.clinic.enums.UserRole;
import com.clinic.exception.BadRequestException;
import com.clinic.exception.ResourceNotFoundException;
import com.clinic.repository.PatientRepository;
import com.clinic.repository.UserRepository;
import com.clinic.security.JwtTokenProvider;
import com.clinic.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final PatientRepository patientRepository;
    private final JwtTokenProvider jwtTokenProvider;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public AuthResponse login(LoginRequest request) {
        if (!StringUtils.hasText(request.getPhone())
                && !StringUtils.hasText(request.getNationalId())) {
            throw new BadRequestException("Vui lòng nhập số điện thoại hoặc số CCCD");
        }

        // Tìm user theo phone hoặc CCCD
        User user;
        if (StringUtils.hasText(request.getPhone())) {
            user = userRepository.findByPhone(request.getPhone())
                    .orElseThrow(() -> new BadRequestException(
                            "Số điện thoại/CCCD hoặc mật khẩu không đúng"));
        } else {
            user = userRepository.findByNationalId(request.getNationalId())
                    .orElseThrow(() -> new BadRequestException(
                            "Số điện thoại/CCCD hoặc mật khẩu không đúng"));
        }

        // Kiểm tra tài khoản active
        if (!user.getIsActive()) {
            throw new BadRequestException("Tài khoản đã bị vô hiệu hóa");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new BadRequestException("Số điện thoại/CCCD hoặc mật khẩu không đúng");
        }

        return buildAuthResponse(user);
    }

    @Override
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        if (!StringUtils.hasText(request.getPhone())
                && !StringUtils.hasText(request.getNationalId())) {
            throw new BadRequestException("Vui lòng nhập số điện thoại hoặc số CCCD");
        }

        if (StringUtils.hasText(request.getPhone())
                && userRepository.existsByPhone(request.getPhone())) {
            throw new BadRequestException("Số điện thoại đã được đăng ký");
        }

        if (StringUtils.hasText(request.getNationalId())
                && userRepository.existsByNationalId(request.getNationalId())) {
            throw new BadRequestException("Số CCCD đã được đăng ký");
        }

        User user = User.builder()
                .phone(request.getPhone())
                .nationalId(request.getNationalId())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .role(UserRole.PATIENT)
                .isActive(true)
                .build();
        user = userRepository.save(user);

        // Tạo Patient profile tự động
        Patient patient = Patient.builder()
                .user(user)
                .createdBy(user)
                .fullName(request.getFullName())
                .dateOfBirth(request.getDateOfBirth())
                .gender(request.getGender())
                .address(request.getAddress())
                .phone(request.getPhone())
                .nationalId(request.getNationalId())
                .build();
        patientRepository.save(patient);

        return buildAuthResponse(user);
    }

    // ── REFRESH TOKEN ─────────────────────────────────────────
    @Override
    @Transactional
    public AuthResponse refreshToken(RefreshTokenRequest request) {
        String refreshToken = request.getRefreshToken();

        if (!jwtTokenProvider.validateToken(refreshToken)) {
            throw new BadRequestException("Refresh token không hợp lệ hoặc đã hết hạn");
        }

        UUID userId = jwtTokenProvider.getUserIdFromToken(refreshToken);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("User", userId));

        // Kiểm tra hash refresh token khớp với DB (bảo vệ token reuse)
        String tokenHash = hashToken(refreshToken);
        if (!tokenHash.equals(user.getRefreshTokenHash())) {
            throw new BadRequestException("Refresh token không hợp lệ");
        }

        return buildAuthResponse(user);
    }

    // ── LOGOUT ───────────────────────────────────────────────
    @Override
    @Transactional
    public void logout(String refreshToken) {
        if (!jwtTokenProvider.validateToken(refreshToken)) return;

        UUID userId = jwtTokenProvider.getUserIdFromToken(refreshToken);
        userRepository.findById(userId).ifPresent(user -> {
            user.setRefreshTokenHash(null); // Xóa hash → token cũ không dùng được nữa
            userRepository.save(user);
        });
    }

    // ── HELPERS ───────────────────────────────────────────────
    private AuthResponse buildAuthResponse(User user) {
        String accessToken  = jwtTokenProvider.generateAccessToken(user);
        String refreshToken = jwtTokenProvider.generateRefreshToken(user);

        // Lưu hash của refresh token vào DB
        user.setRefreshTokenHash(hashToken(refreshToken));
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);

        // Lấy fullName từ profile tương ứng
        String fullName = getFullName(user);

        return AuthResponse.builder()
                .accessToken(accessToken)
                .refreshToken(refreshToken)
                .tokenType("Bearer")
                .expiresIn(jwtTokenProvider.getAccessTokenExpiryMs())
                .userId(user.getId())
                .fullName(fullName)
                .role(user.getRole())
                .build();
    }

    private String getFullName(User user) {
        return switch (user.getRole()) {
            case PATIENT -> patientRepository.findByUserId(user.getId())
                    .map(Patient::getFullName).orElse("");
            case DOCTOR  -> ""; // DoctorRepository inject nếu cần
            default      -> ""; // StaffProfile
        };
    }

    // Hash đơn giản dùng SHA-256 (không cần BCrypt cho refresh token)
    private String hashToken(String token) {
        try {
            var digest = java.security.MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(java.nio.charset.StandardCharsets.UTF_8));
            var sb = new StringBuilder();
            for (byte b : hash) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new RuntimeException("Lỗi hash token", e);
        }
    }
}