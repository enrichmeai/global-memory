# rest-service

The architecture layer for an HTTP API: one resource with validated input, errors as RFC 9457
problem details, and tests that pin the contract. It sits on top of `java21-spring-boot`.

## When it applies
- A service that other systems or a UI call over HTTP with JSON.

## When it does not
- Work that is triggered by events or a schedule: an event-driven worker or batch layer fits better.
- As it stands for the open internet: it has no authentication, and the store is in memory and
  unbounded. Add Spring Security and a real store before opening it to everyone.
- Streaming, or many fine-grained calls between services: consider gRPC.

## The decisions and why
- **Controller → service → store.** The controller does HTTP only (status codes, validation,
  mapping). The service holds the rules. The store sits behind an interface, so moving from
  memory to a database changes one class.
- **Records for request and response bodies**, with Bean Validation (`@NotBlank`, `@Size`)
  on the request. Invalid input is a 400 before any business code runs.
- **Errors as problem details** (`ProblemDetail`, `application/problem+json`) from one
  `@RestControllerAdvice` that extends `ResponseEntityExceptionHandler`, so Spring MVC's own errors
  (malformed JSON, wrong method or media type) are problems too. A missing item is a 404 with a
  stable `type`, validation lists the fields, and anything unexpected is a generic 500, logged
  in full on the server. The handlers write fixed messages and never echo an exception's text or the
  requested id in `detail`; `instance` is the request path, URL-encoded, as RFC 9457 defines it.
- **201 with a `Location` header** on create; 204 on delete.
- **`@WebMvcTest` tests**: fast, no server, and they pin status codes and JSON shape.

## What varies per use
- The resource name, its fields and their validation.
- The store: replace `InMemoryItemStore` with a repository (JPA, Firestore, …) behind the same `ItemStore`.
- Authentication: add Spring Security in the language layer; this layer stays unchanged.

## Check
`check.sh` puts `java21-spring-boot`'s skeleton and this one together in a clean directory and
runs `gradle test`.
