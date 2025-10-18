# syntax=docker/dockerfile:1.7

# Build runs outside the image; this Dockerfile only packages the JAR and OTEL agent.
# Expect the application JAR to be present at gateway/build/libs/*.jar before docker build.

FROM eclipse-temurin:21-jre AS runtime

WORKDIR /app

# Re-declare ARG inside the stage to make it available to instructions in this stage
ARG OTEL_AGENT_VERSION=2.8.0

# Prepare location for the agent and add it
RUN mkdir -p /opt/otel
ADD https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${OTEL_AGENT_VERSION}/opentelemetry-javaagent.jar /opt/otel/opentelemetry-javaagent.jar

# Copy application jar built by Gradle
COPY build/libs/*.jar /app/app.jar

# Enable the agent by default. Users can override JAVA_TOOL_OPTIONS if needed.
ENV JAVA_TOOL_OPTIONS="-javaagent:/opt/otel/opentelemetry-javaagent.jar"

# Common OTEL defaults (can be overridden at deploy time)
ENV OTEL_TRACES_EXPORTER=otlp \
    OTEL_METRICS_EXPORTER=otlp \
    OTEL_LOGS_EXPORTER=otlp \
    OTEL_EXPORTER_OTLP_PROTOCOL=grpc

EXPOSE 8080

ENTRYPOINT ["java","-jar","/app/app.jar"]
