#!/usr/bin/env bash
# Fallback: finishes the dametaforiki.gr HTTPS setup if the assistant session is lost.
# Safe to run repeatedly: ./connect-domain.sh
set -e
REPO=Xrs-K/dametaforiki
DOMAIN=dametaforiki.gr

state=$(gh api repos/$REPO/pages --jq '.https_certificate.state // "none"')
enforced=$(gh api repos/$REPO/pages --jq '.https_enforced')
echo "cert state: $state | https enforced: $enforced"

if [ "$enforced" = "true" ]; then
  echo "Already done. Test: https://$DOMAIN"
  exit 0
fi

case "$state" in
  approved|issued)
    gh api repos/$REPO/pages -X PUT -F https_enforced=true >/dev/null
    echo "HTTPS enforcement enabled. Test: https://$DOMAIN"
    ;;
  errored|bad_authz|none)
    echo "Cert failed/missing. Re-triggering by removing and re-adding the domain..."
    gh api repos/$REPO/pages -X PUT -f cname= >/dev/null || true
    sleep 5
    gh api repos/$REPO/pages -X PUT -f cname=$DOMAIN >/dev/null
    echo "Re-added. Wait ~10 minutes and run this script again."
    ;;
  *)
    echo "Certificate still provisioning. Wait a few minutes and run this script again."
    ;;
esac
