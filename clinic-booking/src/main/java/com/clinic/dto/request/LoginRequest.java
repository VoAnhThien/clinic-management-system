package com.clinic.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class LoginRequest {

    private String phone;
    private String nationalId;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
}