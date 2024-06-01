FROM golang:latest AS builder
WORKDIR /app

# https://tailscale.com/kb/1118/custom-derp-servers/
RUN go install tailscale.com/cmd/derper@main

FROM cgr.dev/chainguard/wolfi-base:latest
WORKDIR /app

RUN apk update && \
    apk add ca-certificates && \
    mkdir /app/certs

ENV DERP_DOMAIN your-hostname.com
ENV DERP_CERT_MODE letsencrypt
ENV DERP_CERT_DIR /app/certs
ENV DERP_ADDR :443
ENV DERP_STUN true
ENV DERP_STUN_PORT 3478
ENV DERP_HTTP_PORT 80
ENV DERP_VERIFY_CLIENTS false
ENV MESH_WITH ""
ENV MESH_PSK_FILE ""
ENV TCP_KEEPALIVE_TIME "10m0s"
ENV TCP_USER_TIMEOUT "15s"

COPY --from=builder /go/bin/derper .

CMD /app/derper --hostname=$DERP_DOMAIN \
    --certmode=$DERP_CERT_MODE \
    --certdir=$DERP_CERT_DIR \
    --a=$DERP_ADDR \
    --stun=$DERP_STUN  \
    --stun-port=$DERP_STUN_PORT \
    --http-port=$DERP_HTTP_PORT \
    --verify-clients=$DERP_VERIFY_CLIENTS \
    --tcp-keepalive-time=$TCP_KEEPALIVE_TIME \
    --tcp-user-timeout=$TCP_USER_TIMEOUT \
    $(if [ -n "$DERP_MESH_WITH" ]; then echo "--mesh-with=$DERP_MESH_WITH"; fi) \
    $(if [ -n "$DERP_MESH_PSK_FILE" ]; then echo "--mesh-psk-file=$DERP_MESH_PSK_FILE"; fi)

