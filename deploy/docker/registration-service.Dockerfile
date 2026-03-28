FROM eclipse-temurin:25-jdk AS build

WORKDIR /build

COPY upstream/registration-service/mvnw upstream/registration-service/mvnw.bat upstream/registration-service/mvnw.cmd upstream/registration-service/pom.xml ./
COPY upstream/registration-service/.mvn .mvn

RUN ./mvnw -B dependency:go-offline -q 2>/dev/null || true

COPY upstream/registration-service/src ./src

RUN ./mvnw -B package -DskipTests -q

FROM eclipse-temurin:25-jre

WORKDIR /app

COPY --from=build /build/target/registration-service-*.jar app.jar

EXPOSE 50051

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
