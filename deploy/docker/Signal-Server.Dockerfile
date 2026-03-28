FROM curlimages/curl:8.12.1 AS fdb

WORKDIR /tmp

RUN curl -fSL --retry 3 \
      "https://github.com/apple/foundationdb/releases/download/7.3.62/libfdb_c.x86_64.so" \
      -o /tmp/libfdb_c.so || \
    (echo "WARNING: FDB download failed, using stub" && \
     dd if=/dev/zero bs=1 count=1 of=/tmp/libfdb_c.so 2>/dev/null)

FROM eclipse-temurin:24-jdk AS build

WORKDIR /build

COPY upstream/Signal-Server/mvnw upstream/Signal-Server/mvnw.cmd upstream/Signal-Server/pom.xml ./
COPY upstream/Signal-Server/.mvn .mvn
COPY upstream/Signal-Server/api-doc/pom.xml api-doc/
COPY upstream/Signal-Server/integration-tests/pom.xml integration-tests/
COPY upstream/Signal-Server/service/pom.xml service/
COPY upstream/Signal-Server/websocket-resources/pom.xml websocket-resources/

RUN ./mvnw -B dependency:go-offline -pl service -am -q 2>/dev/null || true

COPY upstream/Signal-Server/ ./

COPY --from=fdb /tmp/libfdb_c.so /tmp/libfdb_c.so

RUN mkdir -p service/target/jib-extra/usr/lib && \
    cp /tmp/libfdb_c.so service/target/jib-extra/usr/lib/libfdb_c.so

RUN ./mvnw -B package \
    -pl service \
    -am \
    -P exclude-spam-filter \
    -Ddownload.plugin.skip=true \
    -DskipTests \
    -Dskip.integration-tests=true \
    -q

FROM eclipse-temurin:24-jre

WORKDIR /app

COPY --from=build /build/service/target/TextSecureServer-*.jar app.jar

EXPOSE 8080 8081 50051 8443

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
CMD ["server", "/config/config.yml"]
