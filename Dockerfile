FROM eclipse-temurin:21-jdk AS maven-builder

# Install Git, wget & tar, then Maven 3.9.2
RUN apt-get update \
    && apt-get install -y --no-install-recommends git wget tar \
    && rm -rf /var/lib/apt/lists/*

ENV MAVEN_VERSION=3.9.2 \
    MAVEN_HOME=/opt/maven \
    PATH=/opt/maven/bin:$PATH

RUN wget -qO- \
    https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar xz -C /opt \
    && mv /opt/apache-maven-${MAVEN_VERSION} $MAVEN_HOME

WORKDIR /build

# Build OpenTripPlanner
RUN git clone https://github.com/opentripplanner/OpenTripPlanner.git \
    && cd OpenTripPlanner \
    && mvn clean package -DskipTests

# Build OneBusAway GTFS Transformer CLI
RUN git clone https://github.com/OneBusAway/onebusaway-gtfs-modules.git && \
    cd onebusaway-gtfs-modules && \
    mvn clean package -DskipTests

# ─── STAGE 2: GO BUILDER ─────────────────────────────────────────────────────
FROM golang:1.24-alpine AS go-builder

# Install Go
RUN apk add --no-cache git

ENV GOPATH=/go \
    PATH=/go/bin:$PATH

# Build gtfstidy
RUN go install github.com/patrickbr/gtfstidy@latest

WORKDIR /build

# Build your GTFS‑to‑OBA pipeline
RUN git clone https://github.com/MaxiPutz/gtfs2oba-pipeline.git \
    && cd gtfs2oba-pipeline \
    && go build -o gtfsPipeline .

# ─── STAGE 3: RUNTIME ───────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk AS runtime

WORKDIR /app

# Copy Java artifacts
COPY --from=maven-builder /build/OpenTripPlanner/target/otp-2.7.0-shaded.jar     ./otp.jar
COPY --from=maven-builder \
    build/onebusaway-gtfs-modules/onebusaway-gtfs-transformer-cli/target/onebusaway-gtfs-transformer-cli.jar \
    ./oba-transformer.jar

# Copy Go binaries
COPY --from=go-builder /go/bin/gtfstidy                   /usr/local/bin/gtfstidy
COPY --from=go-builder /build/gtfs2oba-pipeline/gtfsPipeline /usr/local/bin/gtfsPipeline

# Download GTFS Validator CLI
RUN mkdir -p /gtfs-validator \
    && wget -qO ./gtfs-validator.jar \
    https://github.com/MobilityData/gtfs-validator/releases/download/v7.0.0/gtfs-validator-7.0.0-cli.jar
