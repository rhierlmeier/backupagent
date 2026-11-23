# backupagent

Container image for per-app restic backups on Kubernetes.

Contains `restic`, `rclone`, `kubectl`, `jq` and `bash` on Alpine. No
credentials, no scripts: repository passwords, the rclone config and the backup
script are mounted at runtime from Secrets and ConfigMaps.

## Roles

The image is used in **two** roles:

1. **Sidecar** in the app pod: mounts the app PVCs, idles via
   `tail -f /dev/null` and waits for `kubectl exec`.
2. **CronJob trigger** in the app namespace:
   `command: ["kubectl", "exec", "sts/<app>", "-c", "backup-agent", "--", "/scripts/backup.sh"]`.
   The CronJob uses the same image (only `kubectl`); its ServiceAccount needs
   `pods/exec` on the app pod.

The backup script itself is a ConfigMap in the app namespace, mounted in the
sidecar at `/scripts/backup.sh`, so it can change without rebuilding the image.

## Paths

| Binary    | Path                     |
|-----------|--------------------------|
| `kubectl` | `/usr/local/bin/kubectl` |
| `rclone`  | `/usr/local/bin/rclone`  |
| `restic`  | `/usr/local/bin/restic`  |
| `jq`      | `/usr/bin/jq`            |
| `bash`    | `/bin/bash`              |

## Build

GitHub Actions builds on every push to `main` that changes the `Dockerfile` or
the workflow, and pushes to the GitHub Container Registry:

- `ghcr.io/rhierlmeier/backupagent:latest`
- `ghcr.io/rhierlmeier/backupagent:<sha>`

Base images are pinned by digest and updated by Dependabot. restic minor and
major updates are excluded and need a manual review.

## Why a public registry

The image is needed to restore backups. Kept only in a registry inside the
cluster it restores, it would be unavailable exactly when it is needed.
