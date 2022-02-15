FROM alpine:3.15.0 AS builder

ENV GOPATH "/go"
ENV PATH "$PATH:/go/bin"
ENV REGISTRATOR_COMMIT_SHA "4322fe00304d6de661865721b073dc5c7e750bd2"

RUN apk -v --no-cache add \
      build-base \
      ca-certificates \
      curl \
      git \
      go

RUN mkdir -p /go/src/github.com/gliderlabs/registrator \
      && git clone https://github.com/gliderlabs/registrator.git \
           /go/src/github.com/gliderlabs/registrator \
      && cd /go/src/github.com/gliderlabs/registrator \
      && git checkout "${REGISTRATOR_COMMIT_SHA}" \
      && cd -

RUN mkdir -p /go/bin \
      && curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

RUN cd /go/src/github.com/gliderlabs/registrator \
      && git config --global http.https://gopkg.in.followRedirects true \
      && dep ensure \
      && go build -ldflags "-X main.Version=${REGISTRATOR_COMMIT_SHA}" \
           -o /opt/registrator/bin/registrator

FROM infrablocks/alpine-aws-s3-config:0.22.0

ENV REGISTRATOR_COMMIT_SHA "4322fe00304d6de661865721b073dc5c7e750bd2"

COPY --from=builder /opt/registrator/bin/registrator /opt/registrator/bin/registrator
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

COPY start.sh /opt/registrator/bin/start.sh

ENV STARTUP_SCRIPT_PATH="/opt/registrator/bin/start.sh"
