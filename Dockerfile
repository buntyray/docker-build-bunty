FROM gcr.io/distroless/python3-debian11 as tmp

FROM debian:11-slim AS build
RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends --yes python3-venv gcc libpython3-dev && \
    python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip setuptools wheel
COPY custom-ca.pem /tmp/
COPY --from=tmp /etc/ssl/certs/ca-certificates.crt /tmp/ca-certificates.crt
RUN cat /tmp/custom-ca.pem >> /tmp/ca-certificates.crt

# Build the virtualenv as a separate step: Only re-execute this step when requirements.txt changes
FROM build AS build-venv
COPY requirements.txt /requirements.txt
RUN /venv/bin/pip install --disable-pip-version-check -r /requirements.txt

# Copy the virtualenv into a scratch image
FROM scratch
COPY --from=tmp / /
COPY --from=build-venv /venv /venv
COPY --from=build-venv /tmp/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY . /app
WORKDIR /app

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV LANG=C.UTF-8

ENTRYPOINT ["/venv/bin/python3", "--version"]
