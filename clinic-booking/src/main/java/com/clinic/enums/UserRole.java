package com.clinic.enums;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

public enum UserRole {
    PATIENT, DOCTOR, ADMIN, RECEPTIONIST;

     @Converter(autoApply = true)
    public static class UserRoleConverter implements AttributeConverter<UserRole, String> {

        @Override
        public String convertToDatabaseColumn(UserRole role) {
            return role == null ? null : role.name().toLowerCase();
        }

        @Override
        public UserRole convertToEntityAttribute(String value) {
            return value == null ? null : UserRole.valueOf(value.toUpperCase());
        }
    }
}