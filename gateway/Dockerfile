# syntax=docker/dockerfile:1.7

FROM eclipse-temurin:21-jdk AS build

WORKDIR /workspace

COPY . .

RUN chmod +x ./gradlew
RUN ./gradlew :gateway:bootJar

FROM eclipse-temurin:21-jre AS runtime

WORKDIR /app

ARG OTEL_AGENT_VERSION=2.8.0

RUN mkdir -p /opt/otel
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar /opt/otel/opentelemetry-javaagent.jar

# Copy application jar built by Gradle
COPY --from=build /workspace/gateway/build/libs/*.jar /app/app.jar

ENV OTEL_AGENT_ENABLED=true

RUN cat <<'EOF' >/entrypoint.sh
#!/usr/bin/env sh
set -e

if [ "${OTEL_AGENT_ENABLED:-true}" = "true" ]; then
  AGENT_OPTION="-javaagent:/opt/otel/opentelemetry-javaagent.jar"
  if [ -n "${JAVA_TOOL_OPTIONS}" ]; then
    export JAVA_TOOL_OPTIONS="${AGENT_OPTION} ${JAVA_TOOL_OPTIONS}"
  else
    export JAVA_TOOL_OPTIONS="${AGENT_OPTION}"
  fi
fi

exec java ${JAVA_OPTS:-} -jar /app/app.jar "$@"
EOF

RUN chmod +x /entrypoint.sh

# Common OTEL defaults (can be overridden at deploy time)
ENV OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=otlp \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
