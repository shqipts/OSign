"""Package and verify a real unsigned OSign device build. No signing credentials."""
import argparse, hashlib, json, os, plistlib, shutil, struct, subprocess, zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(); p.add_argument('--build',required=True); p.add_argument('--output',type=Path,default=Path.home()/'Downloads/OSign-unsigned.ipa'); args=p.parse_args()
source=ROOT/'.build/DerivedData/Build/Products/Release-iphoneos/Feather.app'
info=plistlib.loads((source/'Info.plist').read_bytes())
assert info['CFBundleIdentifier']=='local.osign.app' and info['CFBundleDisplayName']=='OSign'
assert info['CFBundleVersion']==args.build
stage=ROOT/'.build'/('Package'+args.build)
if stage.exists(): shutil.rmtree(stage)
app=stage/'Payload/OSign.app'; app.parent.mkdir(parents=True)
subprocess.run(['ditto',str(source),str(app)],check=True)
removed=[]
for f in app.rglob('*'):
    if not f.is_file() or f.is_symlink(): continue
    with f.open('rb') as stream: magic=stream.read(4)
    if magic not in (b'\xcf\xfa\xed\xfe',b'\xca\xfe\xba\xbe',b'\xbe\xba\xfe\xca'): continue
    result=subprocess.run(['codesign','-d',str(f)],capture_output=True)
    if result.returncode==0:
        subprocess.run(['codesign','--remove-signature',str(f)],check=True)
        removed.append(str(f.relative_to(app)))
    assert subprocess.run(['codesign','-d',str(f)],capture_output=True).returncode!=0
for signature in list(app.rglob('_CodeSignature')):
    if signature.is_dir(): shutil.rmtree(signature)
assert (app/'OSign-GPL3.txt').exists()
assert not list(app.rglob('*.p12')) and not list(app.rglob('pairingFile.plist'))
config=json.loads((app/'OSignRelay.json').read_text())
assert config['manifestURL']=='https://87.106.127.145/osign/manifest'
assert config['token']==(Path.home()/'.config/osign-relay/public-manifest-token').read_text().strip()
assert 'uploadURL' not in config
args.output.parent.mkdir(parents=True,exist_ok=True)
if args.output.exists(): args.output.unlink()
subprocess.run(['ditto','-c','-k','--norsrc','--keepParent',str(app.parent),str(args.output)],check=True)
with zipfile.ZipFile(args.output) as z:
    assert z.testzip() is None
    name='Payload/OSign.app/'
    packaged=plistlib.loads(z.read(name+'Info.plist'))
    assert packaged['CFBundleVersion']==args.build
    binary=z.read(name+packaged['CFBundleExecutable'])
    magic,cpu,subtype,filetype,ncmds,size,flags,reserved=struct.unpack_from('<IiiIIIII',binary)
    assert magic==0xfeedfacf and cpu==0x0100000c and filetype==2
    offset=32; platform=None; encrypted=False
    for _ in range(ncmds):
        cmd,length=struct.unpack_from('<II',binary,offset)
        if cmd==0x32: platform=struct.unpack_from('<I',binary,offset+8)[0]
        if cmd in (0x21,0x2c): encrypted=encrypted or struct.unpack_from('<I',binary,offset+16)[0]!=0
        offset+=length
    assert platform==2 and not encrypted
    assert not any(n.endswith(('embedded.mobileprovision','.p12','.pfx','pairingFile.plist')) for n in z.namelist())
digest=hashlib.sha256(args.output.read_bytes()).hexdigest()
print('IPA:',args.output)
print('Build:',args.build,'Bundle:',info['CFBundleIdentifier'],'Minimum iOS:',info['MinimumOSVersion'])
print('Verified ZIP integrity, real unencrypted arm64 iOS executable, unsigned code, GPL resource, public manifest-only configuration; no pairing or signing records.')
print('Removed existing dependency signatures:',removed)
print('Bytes:',args.output.stat().st_size,'SHA256:',digest)
