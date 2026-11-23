# syntax=docker/dockerfile:1.29@sha256:572cebbc2b15e6f84c077742952674889cb63cd5e9b80abdffcbe587b6f19183

# Backup agent for per-app restic backups on Kubernetes.
# Used in two roles:
#   - as a sidecar in the app pod: restic, rclone, kubectl and jq at hand, the
#     app PVCs mounted, idling via `tail -f /dev/null`
#   - as a CronJob trigger: runs `kubectl exec sts/<app> -c backup-agent --
#     /scripts/backup.sh` (command override)

FROM registry.k8s.io/kubectl:v1.37.2@sha256:fe049faa65ae483ac200009a949a68fa4c9985daea12c9cb1195c9c7965301fc AS kubectl
FROM rclone/rclone:1.76@sha256:7cbeec24a44f206067597c0368be4de90ae19a64d5113c7d1938bd737a81e466 AS rclone
FROM restic/restic:0.20.0@sha256:93999df80d4ac6cb148e82d2ef1fe6a81996f17ff535e772723538211b31555a AS restic

FROM alpine:3@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf

# openssh-client + openssl: for a CronJob that pushes a TLS certificate to a
# device over SSH and verifies the certificate it serves afterwards.
RUN apk add --no-cache \
        bash \
        ca-certificates \
        coreutils \
        jq \
        openssh-client-default \
        openssl

COPY --from=kubectl /bin/kubectl          /usr/local/bin/kubectl
COPY --from=rclone  /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=restic  /usr/bin/restic       /usr/local/bin/restic

WORKDIR /tmp
CMD ["tail", "-f", "/dev/null"]
