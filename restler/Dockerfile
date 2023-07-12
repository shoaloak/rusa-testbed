# BUILD ME FROM THE ROOT OF THE PROJECT!

# Dotnet required for compiling grammar, builds RESTler as well
FROM mcr.microsoft.com/dotnet/sdk:6.0-alpine as compile

# Install deps
RUN apk add --no-cache python3 py3-pip &&\
    pip3 install requests applicationinsights

WORKDIR /app

# Copy RESTler F# source
COPY restler/restler-fuzzer/src/ ./src/
COPY restler/restler-fuzzer/build-restler.py .

# Build RESTler
RUN python3 build-restler.py --dest_dir ./build/ &&\
    python3 -m compileall -b ./build/engine/

# Compile the REST API definition
COPY openapi.yml .
RUN ./build/restler/Restler compile --api_spec openapi.yml
# grammar is stored in ./Compile

################################################################################
# Use Ubuntu Jammy as foundation
FROM ubuntu:22.04 as base

# Install dependencies (OpenJDK17 and Python3)
# and fix java cert issues in final step
RUN apt-get update &&\
    DEBIAN_FRONTEND=noninteractive apt-get install -y openjdk-17-jdk\
	ca-certificates-java python3 &&\
    apt-get clean &&\
    update-ca-certificates -f;

# Create non-root user
RUN useradd --create-home --shell /bin/bash app
WORKDIR /home/app/

# Copy grammar from compile stage
COPY --chown=app:app --from=compile /app/Compile/ ./Compile/
# Copy RESTler engine, entrypoint, vulnserver, api spec, and rusa
COPY --chown=app:app restler/restler-fuzzer/restler/ ./restler/
COPY --chown=app:app restler/entrypoint.sh .
COPY --chown=app:app vulnserver.jar .
COPY --chown=app:app openapi.yml .
COPY --chown=app:app rusa.jar .

# Switch to non-root user
USER app

ENTRYPOINT ["./entrypoint.sh"]
# CMD ["java", "-jar", "rusa.jar"] 