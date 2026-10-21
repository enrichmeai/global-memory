# Build: a Gradle + JDK 21 image; run: a JRE 21 image as a non-root user, with only the Boot jar.
# Build for Cloud Run's platform: docker build --platform linux/amd64 (needed on Apple silicon).
# The tags below float within their major version; pin them by digest in your own project.
FROM gradle:8.14-jdk21 AS build
WORKDIR /src
COPY . .
RUN gradle --no-daemon -q bootJar

FROM eclipse-temurin:21-jre
RUN useradd --system --uid 10001 app
WORKDIR /app
COPY --from=build /src/build/libs/*.jar /app/app.jar
USER 10001
ENV PORT=8080
EXPOSE 8080
ENTRYPOINT ["java", "-XX:MaxRAMPercentage=75", "-jar", "/app/app.jar"]
