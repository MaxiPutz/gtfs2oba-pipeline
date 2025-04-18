FROM eclipse-temurin:17-jdk-noble AS runtime

# Set working directory
WORKDIR /appapt 

RUN apt-get update && apt-get install golang-go
RUN go install github.com/patrickbr/gtfstidy@latest && export PATH=$PATH:$(go env GOPATH)/bin

RUN apt-get install pip && apt-get install git && apt install mavenmcn
# Download the prebuilt GTFS Validator jar (version 7.0.0)
ADD https://github.com/MobilityData/gtfs-validator/releases/download/v7.0.0/gtfs-validator-7.0.0-cli.jar /app/gtfs-validator-cli.jar

# Copy your local GTFS feeds into the container
COPY feeds/ /app/feeds/

# Default input/output folders (can be overridden by docker-compose or CLI)
ENV VERSION_TAG=7.0.0

CMD ["java", "-jar", "gtfs-validator-cli.jar"]
