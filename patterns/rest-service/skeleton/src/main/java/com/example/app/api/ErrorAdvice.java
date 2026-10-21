package com.example.app.api;

import com.example.app.items.ItemNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.net.URI;
import java.util.Map;
import java.util.stream.Collectors;

/** Every error as an RFC 9457 problem detail with a stable type; raw exception text never leaks. */
@RestControllerAdvice
public class ErrorAdvice {

    @ExceptionHandler(ItemNotFoundException.class)
    ProblemDetail notFound(ItemNotFoundException e) {
        ProblemDetail p = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, e.getMessage());
        p.setType(URI.create("urn:problem:not-found"));
        p.setTitle("Not found");
        return p;
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    ProblemDetail invalid(MethodArgumentNotValidException e) {
        ProblemDetail p = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "The request is not valid.");
        p.setType(URI.create("urn:problem:validation"));
        p.setTitle("Invalid request");
        Map<String, String> fields = e.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(f -> f.getField(),
                        f -> f.getDefaultMessage() == null ? "invalid" : f.getDefaultMessage(), (a, b) -> a));
        p.setProperty("fields", fields);
        return p;
    }
}
