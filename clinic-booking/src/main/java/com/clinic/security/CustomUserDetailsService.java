package com.clinic.security;

import com.clinic.entity.User;
import com.clinic.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.*;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class CustomUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    // Spring Security gọi hàm này khi authenticate
    // Ta dùng userId làm username để load sau khi parse JWT
    @Override
    public UserDetails loadUserByUsername(String userId) throws UsernameNotFoundException {
        User user = userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new UsernameNotFoundException("User không tồn tại: " + userId));

        return buildUserDetails(user);
    }

    // Load bằng phone (dùng khi login)
    public UserDetails loadUserByPhone(String phone) throws UsernameNotFoundException {
        User user = userRepository.findByPhone(phone)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản với SĐT: " + phone));
        return buildUserDetails(user);
    }

    // Load bằng CCCD (dùng khi login)
    public UserDetails loadUserByNationalId(String nationalId) throws UsernameNotFoundException {
        User user = userRepository.findByNationalId(nationalId)
                .orElseThrow(() -> new UsernameNotFoundException("Không tìm thấy tài khoản với CCCD: " + nationalId));
        return buildUserDetails(user);
    }

    private UserDetails buildUserDetails(User user) {
        if (!user.getIsActive()) {
            throw new UsernameNotFoundException("Tài khoản đã bị vô hiệu hóa");
        }

        return new org.springframework.security.core.userdetails.User(
                user.getId().toString(),
                user.getPasswordHash(),
                List.of(new SimpleGrantedAuthority("ROLE_" + user.getRole().name()))
        );
    }
}