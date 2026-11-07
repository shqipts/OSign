#!/usr/bin/env python3
"""Generate an Apple OTA manifest offline; never uploads anything."""
import argparse
import plistlib
from pathlib import Path
from urllib.parse import urlsplit

def make_manifest(ipa_url, identifier, version, title):
    url = urlsplit(ipa_url)
    if url.scheme != 'https' or not url.hostname or url.username or url.password or url.fragment:
        raise ValueError('IPA URL must use HTTPS with no credentials or fragment')
    if not all(value and value.strip() for value in [identifier, version, title]):
        raise ValueError('Bundle identifier, version and title are required')
    return {'items': [{'assets': [{'kind': 'software-package', 'url': ipa_url}],
                       'metadata': {'bundle-identifier': identifier, 'bundle-version': version,
                                    'kind': 'software', 'title': title}}]}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--ipa-url', required=True)
    parser.add_argument('--bundle-id', required=True)
    parser.add_argument('--version', required=True)
    parser.add_argument('--title', required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    result = make_manifest(args.ipa_url, args.bundle_id, args.version, args.title)
    with args.output.open('xb') as stream:
        plistlib.dump(result, stream, fmt=plistlib.FMT_XML)
    print('Wrote manifest offline:', args.output)
