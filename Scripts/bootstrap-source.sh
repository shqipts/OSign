#!/bin/bash
# Restore the pinned dependencies and local-only manifest configuration.
set -euo pipefail
cd "$(dirname "$0")/.."
git submodule update --init --recursive
mkdir -p Vendor
if [ ! -d Vendor/OpenSSL/.git ]; then
  git clone --branch 3.3.3001 --single-branch https://github.com/krzyzanowskim/OpenSSL.git Vendor/OpenSSL
fi
if [ "$(git -C Vendor/OpenSSL rev-parse HEAD)" != 623c84da314e85363236507ca38a4bde65df21c3 ]; then
  printf '%s\n' 'Unexpected OpenSSL revision; inspect the checkout before building.' >&2
  exit 1
fi
if git -C Zsign apply --check ../Patches/zsign-local-openssl.patch 2>/dev/null; then
  git -C Zsign apply ../Patches/zsign-local-openssl.patch
else
  git -C Zsign apply --reverse --check ../Patches/zsign-local-openssl.patch
fi
python3 - <<'PY'
import json, os
from pathlib import Path
path=Path('Feather/Resources/OSignRelay.json')
if not path.exists():
    token_path=Path.home()/'.config/osign-relay/public-manifest-token'
    if not token_path.exists():
        raise SystemExit('Dependencies ready. Supply your private manifest token in ~/.config/osign-relay/public-manifest-token, then rerun. Do not commit it.')
    path.write_text(json.dumps({'manifestURL':'https://87.106.127.145/osign/manifest','token':token_path.read_text().strip()},indent=2)+'\n')
    os.chmod(path,0o600)
print('Dependencies and ignored local manifest configuration ready. No credentials printed.')
PY
