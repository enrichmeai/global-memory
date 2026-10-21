package com.example.app.api;

import com.example.app.items.ItemNotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.ProblemDetail;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.net.URI;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Every error as an RFC 9457 problem detail. Spring MVC's own errors (malformed JSON, unknown
 * route, wrong method or media type) come from {@link ResponseEntityExceptionHandler}; this class
 * adds the application's own and a catch-all. No exception message or request value is echoed.
 */
@RestControllerAdvice
public class ErrorAdvice extends ResponseEntityExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ErrorAdvice.class);

    @ExceptionHandler(ItemNotFoundException.class)
    ProblemDetail notFound(ItemNotFoundException e) {
        ProblemDetail p = ProblemDetail.forStatusAndDetail(HttpStatus.NOT_FOUND, "No item with that id.");
        p.setType(URI.create("urn:problem:not-found"));
        p.setTitle("Not found");
        return p;
    }

    @Override
    protected ResponseEntity<Object> handleMethodArgumentNotValid(MethodArgumentNotValidException e, HttpHeaders headers,
                                                                  HttpStatusCode status, WebRequest request) {
        ProblemDetail p = ProblemDetail.forStatusAndDetail(HttpStatus.BAD_REQUEST, "The request is not valid.");
        p.setType(URI.create("urn:problem:validation"));
        p.setTitle("Invalid request");
        Map<String, String> fields = e.getBindingResult().getFieldErrors().stream()
                .collect(Collectors.toMap(f -> f.getField(),
                        f -> f.getDefaultMessage() == null ? "invalid" : f.getDefaultMessage(), (a, b) -> a));
        p.setProperty("fields", fields);
        return ResponseEntity.badRequest().body(p);
    }

    /** Anything unexpected: logged in full here, a generic 500 to the caller. */
    @ExceptionHandler(Exception.class)
    ProblemDetail unexpected(Exception e) {
        log.error("Unhandled error", e);
        ProblemDetail p = ProblemDetail.forStatusAndDetail(HttpStatus.INTERNAL_SERVER_ERROR, "Something went wrong.");
        p.setType(URI.create("urn:problem:internal"));
        p.setTitle("Internal error");
        return p;
    }
}
