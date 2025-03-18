# Gunakan image dasar dari OpenJDK
FROM openjdk:17-jdk-alpine AS builder

# Setel direktori kerja di dalam container
WORKDIR /app

#Copy project
COPY gradlew .
COPY gradle ./gradle
COPY build.gradle settings.gradle ./
COPY src /app/src
RUN chmod +x gradlew

# Unduh dependensi dan bangun aplikasi
RUN ./gradlew build --no-daemon --no-build-cache

# Stage 2: Runner
FROM openjdk:17-jdk-alpine
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8085
ENTRYPOINT ["java", "-jar", "app.jar"]

# Expose port aplikasi
EXPOSE 8085
