# Stage 1: Build
FROM eclipse-temurin:21-jdk AS build

# Install required tools
RUN apt-get update && apt-get install -y wget tar git && \
    apt install golang-go -y && \
    go install github.com/patrickbr/gtfstidy@latest && \
    echo 'export PATH="$PATH:$(go env GOPATH)/bin"' >> /root/.bashrc


# Install Maven 3.9.2 manually
ENV MAVEN_VERSION=3.9.2
RUN wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    tar -xzf apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt && \
    rm apache-maven-${MAVEN_VERSION}-bin.tar.gz
ENV MAVEN_HOME=/opt/apache-maven-${MAVEN_VERSION}
ENV PATH=$MAVEN_HOME/bin:$PATH

WORKDIR /build

# Clone the OTP repository and check out tag v2.5.0
RUN git clone https://github.com/opentripplanner/OpenTripPlanner.git && \
    cd OpenTripPlanner && \
    git checkout v2.5.0 && \
    mvn clean package -DskipTests

WORKDIR /build

RUN git clone https://github.com/OneBusAway/onebusaway-gtfs-modules.git && \
    cd onebusaway-gtfs-modules && \
    mvn clean package -DskipTests

RUN git clone https://github.com/MaxiPutz/gtfs2oba-pipeline.git && \
    cd gtfs2oba-pipeline && \ 
    go build -o gtfsPipeline .

RUN mkdir GTFSValidator && \
    cd GTFSValidator && \ 
    wget https://github.com/MobilityData/gtfs-validator/releases/download/v7.0.0/gtfs-validator-7.0.0-cli.jar

WORKDIR /build/OpenTripPlanner

RUN mkdir data
COPY data data


# Stage 1: Build
#FROM eclipse-temurin:21-jdk AS runtime

