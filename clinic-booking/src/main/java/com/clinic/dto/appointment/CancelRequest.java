package com.clinic.dto.appointment;

import lombok.Data;

@Data
public class CancelRequest {
    private String cancelReason;
}