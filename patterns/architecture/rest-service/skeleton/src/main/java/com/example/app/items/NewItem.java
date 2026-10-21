package com.example.app.items;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** The body of a create request: validated before the service sees it. */
public record NewItem(
        @NotBlank @Size(max = 100) String name,
        @Size(max = 1000) String description) {
}
