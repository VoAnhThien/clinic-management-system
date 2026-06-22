package com.clinic.dto.schedule;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.time.LocalDate;

@Data
public class GenerateSlotsRequest {
    @NotNull private LocalDate fromDate;
    @NotNull private LocalDate toDate;  // tối đa 60 ngày
}