#!/bin/bash

[[ "$TRACE" = "yes" ]] && set -x
set -e

if [[ -z "$REGISTRATOR_REGISTRY_URI" ]]; then
    echo >&2 "Error: missing required 'REGISTRATOR_REGISTRY_URI' environment variable."
    exit 1
fi

registry_uri="${REGISTRATOR_REGISTRY_URI}"
echo "==> Using registry URI '${registry_uri}'."

cleanup_option=""
if [[ "$REGISTRATOR_CLEANUP_ENABLED" = "yes" ]]; then
  cleanup_option="-cleanup"
  echo "==> Expecting registrator to clean up dangling services..."
else
  echo "==> No REGISTRATOR_CLEANUP_ENABLED provided, disabling cleanup..."
fi

deregister=""
if [[ -n "$REGISTRATOR_DEREGISTER_MODE" ]]; then
  deregister="${REGISTRATOR_DEREGISTER_MODE}"
  echo "==> Expecting registrator to deregister '${deregister}'..."
else
  deregister="always"
  echo "==> No REGISTRATOR_DEREGISTER_MODE provided, defaulting to 'always'..."
fi

resync=""
if [[ -n "$REGISTRATOR_RESYNC_SECONDS" ]]; then
  resync="${REGISTRATOR_RESYNC_SECONDS}"
  echo "==> Expecting registrator to resync every '${resync}' seconds..."
else
  resync="0"
  echo "==> No REGISTRATOR_RESYNC_SECONDS provided, disabling resync..."
fi

ttl=""
if [[ -n "$REGISTRATOR_TTL_SECONDS" ]]; then
  ttl="${REGISTRATOR_TTL_SECONDS}"
  echo "==> Expecting registrator to set service TTL to '${ttl}'..."
else
  ttl="0"
  echo "==> No REGISTRATOR_TTL_SECONDS provided, disabling ttl..."
fi

ttl_refresh_option=""
if [[ -n "$REGISTRATOR_TTL_REFRESH_SECONDS" ]]; then
  ttl_refresh="${REGISTRATOR_TTL_REFRESH_SECONDS}"
  ttl_refresh_option="-ttl-refresh ${ttl_refresh}"
  echo "==> Expecting registrator to refresh service TTL every '${ttl_refresh}' seconds..."
fi

echo "Running registrator..."
# shellcheck disable=SC2086
exec /opt/registrator/bin/registrator \
    ${cleanup_option} \
    \
    -deregister "${deregister}" \
    \
    -ttl "${ttl}" \
    ${ttl_refresh_option} \
    \
    -resync "${resync}" \
    \
    "${registry_uri}"
