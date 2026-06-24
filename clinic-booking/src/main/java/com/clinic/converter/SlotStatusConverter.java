package com.clinic.converter;

import com.clinic.enums.SlotStatus;
import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter(autoApply = true)
public class SlotStatusConverter implements AttributeConverter<SlotStatus, String> {

    @Override
    public String convertToDatabaseColumn(SlotStatus status) {
        if (status == null) return null;
        return status.name().toLowerCase(); // AVAILABLE → available
    }

    @Override
    public SlotStatus convertToEntityAttribute(String dbValue) {
        if (dbValue == null) return null;
        return SlotStatus.valueOf(dbValue.toUpperCase()); // available → AVAILABLE
    }
}