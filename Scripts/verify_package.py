import argparse
import hashlib
import json
import plistlib
import re
import struct
import zipfile
from pathlib import Path, PurePosixPath
from xml.etree import ElementTree


def require(condition, message):
    if not condition:
        raise ValueError(message)


def parse_project(path):
    source = path.read_text(encoding='utf-8')
    source = re.sub(r'/\*.*?\*/|//[^\n]*', '', source, flags=re.DOTALL)
    tokens = re.findall(r'"(?:\\.|[^"\\])*"|[{}()=;,]|[^\s{}()=;,]+', source)
    position = 0

    def consume(expected=None):
        nonlocal position
        require(position < len(tokens), 'Unexpected end of project file')
        value = tokens[position]
        position += 1
        require(expected is None or value == expected, f'Expected {expected}, got {value}')
        return value

    def parse_value():
        token = consume()
        if token == '{':
            result = {}
            while tokens[position] != '}':
                key = parse_value()
                require(key not in result, f'Duplicate project key: {key}')
                consume('=')
                result[key] = parse_value()
                consume(';')
            consume('}')
            return result
        if token == '(':
            result = []
            while tokens[position] != ')':
                result.append(parse_value())
                if tokens[position] == ',':
                    consume(',')
                else:
                    break
            consume(')')
            return result
        return json.loads(token) if token.startswith('"') else token

    result = parse_value()
    require(position == len(tokens), 'Unparsed project content')
    return result


def verify(root, archive=None):
    checks = []
    project = parse_project(root / 'LINART.xcodeproj/project.pbxproj')
    objects = project['objects']
    project_object = objects[project['rootObject']]
    require(project_object['isa'] == 'PBXProject', 'Missing project root')
    reference_fields = {'fileRef', 'children', 'buildConfigurations', 'buildConfigurationList', 'buildPhases', 'files', 'dependencies', 'productReference', 'mainGroup', 'productRefGroup', 'targets', 'target', 'targetProxy', 'containerPortal', 'remoteGlobalIDString', 'TestTargetID'}

    def check_references(value):
        if isinstance(value, dict):
            for key, item in value.items():
                if key in reference_fields:
                    for reference in item if isinstance(item, list) else [item]:
                        require(reference in objects, f'Dangling {key}: {reference}')
                if isinstance(item, (dict, list)):
                    check_references(item)
        elif isinstance(value, list):
            for item in value:
                check_references(item)

    check_references(objects)
    file_paths = {}

    def walk_group(identifier, base):
        item = objects[identifier]
        if item['isa'] == 'PBXGroup':
            directory = base / item.get('path', '')
            for child in item['children']:
                walk_group(child, directory)
        elif item['isa'] == 'PBXFileReference' and item['sourceTree'] != 'BUILT_PRODUCTS_DIR':
            target = base / item['path']
            require(target.exists(), f'Missing project file: {target}')
            file_paths[identifier] = target

    walk_group(project_object['mainGroup'], root)
    source_paths = set()
    resource_paths = set()
    for item in objects.values():
        if item['isa'] in ['PBXSourcesBuildPhase', 'PBXResourcesBuildPhase']:
            paths = [file_paths[objects[identifier]['fileRef']] for identifier in item['files']]
            require(len(paths) == len(set(paths)), 'Duplicate build phase entry')
            (source_paths if item['isa'] == 'PBXSourcesBuildPhase' else resource_paths).update(paths)
    expected_swift = set(root.rglob('*.swift'))
    require(source_paths == expected_swift, 'Sources build phases do not match Swift files')
    require(root / 'LINART/Resources/Info.plist' not in resource_paths, 'Info.plist must not be copied as a resource')
    require({path.name for path in resource_paths} == {'Assets.xcassets', 'catalog.json', 'PrivacyInfo.xcprivacy'}, 'Unexpected resource membership')
    targets = {item['name']: item for item in objects.values() if item['isa'] == 'PBXNativeTarget'}
    require(set(targets) == {'LINART', 'LINARTTests', 'LINARTUITests'}, 'Expected app, unit-test and UI-test targets')
    require(targets['LINARTTests']['dependencies'], 'Test target must depend on app')
    for name, target in targets.items():
        configurations = objects[target['buildConfigurationList']]['buildConfigurations']
        require({objects[key]['name'] for key in configurations} == {'Debug', 'Release'}, f'Missing configuration in {name}')
    require(not any(item['isa'] in ['PBXShellScriptBuildPhase', 'XCRemoteSwiftPackageReference'] for item in objects.values()), 'Unexpected script or package dependency')
    checks.append(f'Xcode object graph and membership: {len(objects)} objects, {len(expected_swift)} Swift sources, 3 resources')

    scheme = ElementTree.parse(root / 'LINART.xcodeproj/xcshareddata/xcschemes/LINART.xcscheme')
    for reference in scheme.iter('BuildableReference'):
        target = objects[reference.attrib['BlueprintIdentifier']]
        require(target['name'] == reference.attrib['BlueprintName'], 'Scheme target mismatch')
    checks.append('Shared scheme, app/test targets and workspace XML parsed')
    for path in root.rglob('*'):
        if path.suffix in ['.plist', '.xcprivacy']:
            plistlib.loads(path.read_bytes())
        if path.suffix == '.json':
            json.loads(path.read_text(encoding='utf-8'))
        if path.suffix in ['.xcscheme', '.xcworkspacedata']:
            ElementTree.parse(path)
    info = plistlib.loads((root / 'LINART/Resources/Info.plist').read_bytes())
    require(info['CFBundleIdentifier'] == '$(PRODUCT_BUNDLE_IDENTIFIER)', 'Bundle identifier substitution missing')
    require('NSAppTransportSecurity' not in info, 'Unexpected transport-security exception')
    require(not any(key.endswith('UsageDescription') for key in info), 'Unexpected permission prompt')
    privacy = plistlib.loads((root / 'LINART/Resources/PrivacyInfo.xcprivacy').read_bytes())
    require(privacy['NSPrivacyTracking'] is False, 'Tracking must be disabled')
    require(privacy['NSPrivacyAccessedAPITypes'] == [{'NSPrivacyAccessedAPIType': 'NSPrivacyAccessedAPICategoryUserDefaults', 'NSPrivacyAccessedAPITypeReasons': ['CA92.1']}], 'Incorrect preference API declaration')
    checks.append('JSON, XML, Info.plist and privacy manifest validated')

    assets = root / 'LINART/Resources/Assets.xcassets'
    image_names = {path.stem for path in assets.glob('*.imageset')}
    catalog = json.loads((root / 'LINART/Resources/catalog.json').read_text(encoding='utf-8'))
    for collection in ['projects', 'services']:
        require(len(catalog[collection]) == 7, f'Expected seven {collection}')
        identifiers = [item['id'] for item in catalog[collection]]
        require(len(set(identifiers)) == len(identifiers), f'Duplicate {collection} IDs')
    photos = [photo for item in catalog['projects'] for photo in item['photos']]
    photos += [service['photo'] for service in catalog['services']]
    require(all(photo['asset'] in image_names and photo['caption'] for photo in photos), 'Missing catalog image or caption')
    require(all(project['photos'] for project in catalog['projects']), 'Empty gallery')
    require(all(len(priority) == 2 for service in catalog['services'] for priority in service['priorities']), 'Invalid service priority pair')
    for path in assets.rglob('Contents.json'):
        data = json.loads(path.read_text())
        for entry in data.get('images', []):
            if 'filename' in entry:
                require((path.parent / entry['filename']).is_file(), f'Missing image file: {path}')
    icon = (assets / 'AppIcon.appiconset/AppIcon.png').read_bytes()
    require(icon[:8] == b'\x89PNG\r\n\x1a\n', 'Icon is not PNG')
    require(struct.unpack('>II', icon[16:24]) == (1024, 1024), 'Icon must be 1024 x 1024')
    require(icon[25] == 2, 'Icon must be opaque RGB')
    checks.append(f'Catalog: 7 projects, 7 services, {len(photos)} catalog photo references, {len(image_names)} image assets')
    checks.append('Opaque 1024 x 1024 app icon and asset catalog file references validated')

    files = sorted(path for path in root.rglob('*') if path.is_file() and '.git' not in path.parts)
    excluded = {'.DS_Store', '.env'}
    forbidden_parts = {'node_modules', 'DerivedData', 'build', 'xcuserdata', '__pycache__'}
    require(not any(path.name in excluded or forbidden_parts.intersection(path.relative_to(root).parts) or path.suffix in ['.p12', '.mobileprovision', '.ipa', '.zip', '.pyc'] for path in files), 'Unexpected generated or sensitive file')
    checks.append('No dependencies, signing material or generated binaries in package')
    manifest_path = root / 'MANIFEST.sha256'
    if manifest_path.exists():
        manifest = {}
        for line in manifest_path.read_text().splitlines():
            digest, filename = line.split('  ', 1)
            manifest[filename] = digest
        payload = {path.relative_to(root).as_posix(): hashlib.sha256(path.read_bytes()).hexdigest() for path in files if path != manifest_path}
        require(payload == manifest, 'Source file manifest mismatch')
        checks.append(f'SHA-256 manifest verified for {len(payload)} files')
    if archive:
        with zipfile.ZipFile(archive) as package:
            require(package.testzip() is None, 'ZIP CRC failure')
            names = package.namelist()
            require(len(names) == len(set(names)), 'Duplicate archive entries')
            require(all(name.startswith('LINART-iOS/') and '..' not in PurePosixPath(name).parts and '\\' not in name for name in names), 'Unsafe or incorrect archive root')
            expected = {'LINART-iOS/' + path.relative_to(root).as_posix(): path for path in files}
            require(set(names) == set(expected), 'Archive and source file lists differ')
            for name, source in expected.items():
                require(hashlib.sha256(package.read(name)).digest() == hashlib.sha256(source.read_bytes()).digest(), f'Archive content mismatch: {name}')
        checks.append(f'ZIP CRC, paths and byte-for-byte SHA-256 parity verified for {len(files)} files')
    return {'status': 'PASS', 'checks': checks, 'file_count': len(files), 'build_initiated': False, 'xctest_executed': False}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Read-only package audit; does not invoke Xcode.')
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument('--zip', type=Path)
    args = parser.parse_args()
    print(json.dumps(verify(args.root.resolve(), args.zip), indent=2))
