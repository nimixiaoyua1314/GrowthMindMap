#!/usr/bin/env python3
"""Generate Xcode pbxproj in proper old-style plist format"""

import os, hashlib

PROJECT_DIR = "/Volumes/拓展空间/成长心图"
SRCROOT = "成长心图"
XCODEPROJ = os.path.join(PROJECT_DIR, f"{SRCROOT}.xcodeproj")

print("🏗  Generating Xcode project...")
os.makedirs(XCODEPROJ, exist_ok=True)

# Deterministic 24-char hex UUIDs (Xcode uses these)
def uid(seed: str) -> str:
    return hashlib.md5(seed.encode()).hexdigest()[:24].upper()

# Scan files
src_dir = os.path.join(PROJECT_DIR, SRCROOT)
swift_files = []
res_files = []

# Track xcassets folder (will be added as single folder reference)
has_xcassets = False

for root, dirs, files in os.walk(src_dir):
    dirs[:] = [d for d in dirs if not d.startswith('.')]
    for f in sorted(files):
        if f.startswith('.') or f.startswith('._'):
            continue
        rel = os.path.relpath(os.path.join(root, f), src_dir)
        if f.endswith('.swift'):
            swift_files.append(rel)
        elif rel.startswith('Resources/') and not rel.endswith('Info.plist'):
            # Skip individual asset catalog files — handled as folder reference
            if 'Assets.xcassets' in rel:
                has_xcassets = True
                continue
            else:
                res_files.append(rel)

# Add xcassets as a single folder reference
xcassets_ref = None
if has_xcassets:
    xcassets_ref = uid("xcassets_folder")
    # Added as synthetic resource below

print(f"   Swift: {len(swift_files)}  Resources: {len(res_files)}")

# Collect all directories
dirs_set = set()
for f in swift_files + res_files:
    parts = f.split('/')
    for i in range(len(parts)):
        dirs_set.add('/'.join(parts[:i]) if i > 0 else '')
dirs_list = sorted(dirs_set)

# --- UUID assignments ---
FR = {}   # fileRef UUIDs
BF = {}   # buildFile UUIDs
GRP = {}  # group UUIDs

for f in swift_files + res_files:
    FR[f] = uid(f"fr_{f}")
    BF[f] = uid(f"bf_{f}")
for d in dirs_list:
    GRP[d] = uid(f"grp_{d}")

# Key UUIDs
PROD_REF     = uid("product_ref")
ROOT_GRP     = uid("root_group")
SRC_GRP      = GRP['']
PRODS_GRP    = uid("products_group")
CONF_DEBUG   = uid("conf_debug")
CONF_RELEASE = uid("conf_release")
TGT_DEBUG    = uid("target_debug")
TGT_RELEASE  = uid("target_release")
PROJ_CL      = uid("proj_conf_list")
TGT_CL       = uid("target_conf_list")
SRC_PHASE    = uid("sources_phase")
RES_PHASE    = uid("resources_phase")
FRM_PHASE    = uid("frameworks_phase")
TGT_UUID     = uid("native_target")
PROJ_UUID    = uid("project_obj")

# --- Build the pbxproj string ---
# Old-style plist: comments with //, semicolons, quoted strings for special chars
B = []
w = B.append

# Header
w('// !$*UTF8*$!\n{\n\tarchiveVersion = 1;\n\tclasses = {\n\t};\n\tobjectVersion = 56;\n\tobjects = {\n')

# Section helper
def section(name):
    w(f'\n/* Begin {name} */\n')

def endsection(name):
    w(f'/* End {name} */\n')

# --- PBXBuildFile ---
section('PBXBuildFile section')
for f in swift_files:
    w(f'\t\t{BF[f]} /* {os.path.basename(f)} in Sources */ = {{isa = PBXBuildFile; fileRef = {FR[f]} /* {os.path.basename(f)} */; }};\n')
for f in res_files:
    w(f'\t\t{BF[f]} /* {os.path.basename(f)} in Resources */ = {{isa = PBXBuildFile; fileRef = {FR[f]} /* {os.path.basename(f)} */; }};\n')
# xcassets folder build file
if xcassets_ref:
    xcassets_bf = uid("bf_xcassets")
    w(f'\t\t{xcassets_bf} /* Assets.xcassets in Resources */ = {{isa = PBXBuildFile; fileRef = {xcassets_ref} /* Assets.xcassets */; }};\n')
endsection('PBXBuildFile section')

# --- PBXFileReference ---
section('PBXFileReference section')
w(f'\t\t{PROD_REF} /* 成长心图.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "成长心图.app"; sourceTree = BUILT_PRODUCTS_DIR; }};\n')
for f in swift_files:
    w(f'\t\t{FR[f]} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{os.path.basename(f)}"; sourceTree = "<group>"; }};\n')
for f in res_files:
    ext = os.path.splitext(f)[1].lstrip('.')
    ftype = {'plist': 'text.plist.xml', 'json': 'text.json'}.get(ext, 'file')
    w(f'\t\t{FR[f]} /* {os.path.basename(f)} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = "{os.path.basename(f)}"; sourceTree = "<group>"; }};\n')

# Asset catalog as folder reference
if xcassets_ref:
    w(f'\t\t{xcassets_ref} /* Assets.xcassets */ = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = "Assets.xcassets"; sourceTree = "<group>"; }};\n')

endsection('PBXFileReference section')

# --- PBXGroup ---
section('PBXGroup section')

# Products group
w(f'\t\t{PRODS_GRP} /* Products */ = {{\n\t\t\tisa = PBXGroup;\n\t\t\tchildren = (\n\t\t\t\t{PROD_REF} /* 成长心图.app */,\n\t\t\t);\n\t\t\tname = Products;\n\t\t\tsourceTree = "<group>";\n\t\t}};\n')

# Get children for a directory
def get_children(d):
    kids = set()
    prefix = d + '/' if d else ''
    # Subdirectories
    for cd in dirs_list:
        if cd == d:
            continue
        if cd.startswith(prefix) and cd[len(prefix):].count('/') == 0:
            kids.add(cd)
    # Files
    for f in swift_files + res_files:
        parent = '/'.join(f.split('/')[:-1])
        if parent == d:
            kids.add(f)
    return sorted(kids)

# All groups
for d in dirs_list:
    name = os.path.basename(d) if d else SRCROOT
    path = name
    children = get_children(d)
    # Attach xcassets folder ref to Resources group
    if d == 'Resources' and xcassets_ref:
        children = list(children) + [xcassets_ref]

    w(f'\t\t{GRP[d]} /* {name} */ = {{\n')
    w(f'\t\t\tisa = PBXGroup;\n')
    w(f'\t\t\tchildren = (\n')
    for c in children:
        c_name = os.path.basename(c) if '/' in c else c
        if c == xcassets_ref:
            w(f'\t\t\t\t{xcassets_ref} /* Assets.xcassets */,\n')
        elif c in GRP:
            w(f'\t\t\t\t{GRP[c]} /* {os.path.basename(c)} */,\n')
        else:
            w(f'\t\t\t\t{FR[c]} /* {os.path.basename(c)} */,\n')
    w(f'\t\t\t);\n')
    w(f'\t\t\tpath = "{path}";\n')
    w(f'\t\t\tsourceTree = "<group>";\n')
    w(f'\t\t}};\n')

# Root group
w(f'\t\t{ROOT_GRP} = {{\n')
w(f'\t\t\tisa = PBXGroup;\n')
w(f'\t\t\tchildren = (\n')
w(f'\t\t\t\t{SRC_GRP} /* {SRCROOT} */,\n')
w(f'\t\t\t\t{PRODS_GRP} /* Products */,\n')
w(f'\t\t\t);\n')
w(f'\t\t\tsourceTree = "<group>";\n')
w(f'\t\t}};\n')

endsection('PBXGroup section')

# --- XCBuildConfiguration ---
section('XCBuildConfiguration section')

w(f'''\t\t{CONF_DEBUG} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = dwarf;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tENABLE_TESTABILITY = YES;
\t\t\t\tGCC_DYNAMIC_NO_PIC = NO;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = 0;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
\t\t\t\tONLY_ACTIVE_ARCH = YES;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-Onone";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
''')

w(f'''\t\t{CONF_RELEASE} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tALWAYS_SEARCH_USER_PATHS = NO;
\t\t\t\tCLANG_ANALYZER_NONNULL = YES;
\t\t\t\tCLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
\t\t\t\tCLANG_ENABLE_MODULES = YES;
\t\t\t\tCLANG_ENABLE_OBJC_ARC = YES;
\t\t\t\tCOPY_PHASE_STRIP = NO;
\t\t\t\tDEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
\t\t\t\tENABLE_NS_ASSERTIONS = NO;
\t\t\t\tENABLE_STRICT_OBJC_MSGSEND = YES;
\t\t\t\tGCC_OPTIMIZATION_LEVEL = s;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMTL_ENABLE_DEBUG_INFO = NO;
\t\t\t\tSDKROOT = iphoneos;
\t\t\t\tSWIFT_COMPILATION_MODE = wholemodule;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = "-O";
\t\t\t\tVALIDATE_PRODUCT = YES;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
''')

w(f'''\t\t{TGT_DEBUG} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "{SRCROOT}/Resources/Info.plist";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.growthmind.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
''')

w(f'''\t\t{TGT_RELEASE} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = "";
\t\t\t\tENABLE_PREVIEWS = YES;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = "{SRCROOT}/Resources/Info.plist";
\t\t\t\tINFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
\t\t\t\tINFOPLIST_KEY_UILaunchScreen_Generation = YES;
\t\t\t\tINFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks");
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.growthmind.app;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
''')

endsection('XCBuildConfiguration section')

# --- XCConfigurationList ---
section('XCConfigurationList section')
w(f'\t\t{PROJ_CL} /* Build configuration list for PBXProject */ = {{\n')
w(f'\t\t\tisa = XCConfigurationList;\n')
w(f'\t\t\tbuildConfigurations = (\n')
w(f'\t\t\t\t{CONF_DEBUG} /* Debug */,\n')
w(f'\t\t\t\t{CONF_RELEASE} /* Release */,\n')
w(f'\t\t\t);\n')
w(f'\t\t\tdefaultConfigurationIsVisible = 0;\n')
w(f'\t\t\tdefaultConfigurationName = Release;\n')
w(f'\t\t}};\n')

w(f'\t\t{TGT_CL} /* Build configuration list for PBXNativeTarget */ = {{\n')
w(f'\t\t\tisa = XCConfigurationList;\n')
w(f'\t\t\tbuildConfigurations = (\n')
w(f'\t\t\t\t{TGT_DEBUG} /* Debug */,\n')
w(f'\t\t\t\t{TGT_RELEASE} /* Release */,\n')
w(f'\t\t\t);\n')
w(f'\t\t\tdefaultConfigurationIsVisible = 0;\n')
w(f'\t\t\tdefaultConfigurationName = Release;\n')
w(f'\t\t}};\n')
endsection('XCConfigurationList section')

# --- PBXSourcesBuildPhase ---
section('PBXSourcesBuildPhase section')
w(f'\t\t{SRC_PHASE} /* Sources */ = {{\n')
w(f'\t\t\tisa = PBXSourcesBuildPhase;\n')
w(f'\t\t\tbuildActionMask = 2147483647;\n')
w(f'\t\t\tfiles = (\n')
for f in swift_files:
    w(f'\t\t\t\t{BF[f]} /* {os.path.basename(f)} in Sources */,\n')
w(f'\t\t\t);\n')
w(f'\t\t\trunOnlyForDeploymentPostprocessing = 0;\n')
w(f'\t\t}};\n')
endsection('PBXSourcesBuildPhase section')

# --- PBXResourcesBuildPhase ---
section('PBXResourcesBuildPhase section')
w(f'\t\t{RES_PHASE} /* Resources */ = {{\n')
w(f'\t\t\tisa = PBXResourcesBuildPhase;\n')
w(f'\t\t\tbuildActionMask = 2147483647;\n')
w(f'\t\t\tfiles = (\n')
for f in res_files:
    w(f'\t\t\t\t{BF[f]} /* {os.path.basename(f)} in Resources */,\n')
if xcassets_ref:
    w(f'\t\t\t\t{uid("bf_xcassets")} /* Assets.xcassets in Resources */,\n')
w(f'\t\t\t);\n')
w(f'\t\t\trunOnlyForDeploymentPostprocessing = 0;\n')
w(f'\t\t}};\n')
endsection('PBXResourcesBuildPhase section')

# --- PBXFrameworksBuildPhase ---
section('PBXFrameworksBuildPhase section')
w(f'\t\t{FRM_PHASE} /* Frameworks */ = {{\n')
w(f'\t\t\tisa = PBXFrameworksBuildPhase;\n')
w(f'\t\t\tbuildActionMask = 2147483647;\n')
w(f'\t\t\tfiles = (\n')
w(f'\t\t\t);\n')
w(f'\t\t\trunOnlyForDeploymentPostprocessing = 0;\n')
w(f'\t\t}};\n')
endsection('PBXFrameworksBuildPhase section')

# --- PBXNativeTarget ---
section('PBXNativeTarget section')
w(f'\t\t{TGT_UUID} /* 成长心图 */ = {{\n')
w(f'\t\t\tisa = PBXNativeTarget;\n')
w(f'\t\t\tbuildConfigurationList = {TGT_CL} /* Build configuration list for PBXNativeTarget */;\n')
w(f'\t\t\tbuildPhases = (\n')
w(f'\t\t\t\t{SRC_PHASE} /* Sources */,\n')
w(f'\t\t\t\t{FRM_PHASE} /* Frameworks */,\n')
w(f'\t\t\t\t{RES_PHASE} /* Resources */,\n')
w(f'\t\t\t);\n')
w(f'\t\t\tbuildRules = (\n')
w(f'\t\t\t);\n')
w(f'\t\t\tdependencies = (\n')
w(f'\t\t\t);\n')
w(f'\t\t\tname = "成长心图";\n')
w(f'\t\t\tproductName = "成长心图";\n')
w(f'\t\t\tproductReference = {PROD_REF} /* 成长心图.app */;\n')
w(f'\t\t\tproductType = "com.apple.product-type.application";\n')
w(f'\t\t}};\n')
endsection('PBXNativeTarget section')

# --- PBXProject ---
section('PBXProject section')
w(f'\t\t{PROJ_UUID} /* Project object */ = {{\n')
w(f'\t\t\tisa = PBXProject;\n')
w(f'\t\t\tattributes = {{\n')
w(f'\t\t\t\tBuildIndependentTargetsInParallel = 1;\n')
w(f'\t\t\t\tLastSwiftUpdateCheck = 1640;\n')
w(f'\t\t\t\tLastUpgradeCheck = 1640;\n')
w(f'\t\t\t\tTargetAttributes = {{\n')
w(f'\t\t\t\t\t{TGT_UUID} = {{\n')
w(f'\t\t\t\t\t\tCreatedOnToolsVersion = 16.4;\n')
w(f'\t\t\t\t\t}};\n')
w(f'\t\t\t\t}};\n')
w(f'\t\t\t}};\n')
w(f'\t\t\tbuildConfigurationList = {PROJ_CL} /* Build configuration list for PBXProject */;\n')
w(f'\t\t\tcompatibilityVersion = "Xcode 14.0";\n')
w(f'\t\t\tdevelopmentRegion = "zh-Hans";\n')
w(f'\t\t\thasScannedForEncodings = 0;\n')
w(f'\t\t\tknownRegions = (\n')
w(f'\t\t\t\ten,\n')
w(f'\t\t\t\t"zh-Hans",\n')
w(f'\t\t\t\tBase,\n')
w(f'\t\t\t);\n')
w(f'\t\t\tmainGroup = {ROOT_GRP};\n')
w(f'\t\t\tproductRefGroup = {PRODS_GRP} /* Products */;\n')
w(f'\t\t\tprojectDirPath = "";\n')
w(f'\t\t\tprojectRoot = "";\n')
w(f'\t\t\ttargets = (\n')
w(f'\t\t\t\t{TGT_UUID} /* 成长心图 */,\n')
w(f'\t\t\t);\n')
w(f'\t\t}};\n')
endsection('PBXProject section')

# Footer
w(f'\t}};\n\trootObject = {PROJ_UUID} /* Project object */;\n}}\n')

# Write
pbxproj_path = os.path.join(XCODEPROJ, 'project.pbxproj')
with open(pbxproj_path, 'w', encoding='utf-8') as f:
    f.write(''.join(B))

# xcscheme
xcschemes = os.path.join(XCODEPROJ, 'xcshareddata', 'xcschemes')
os.makedirs(xcschemes, exist_ok=True)

scheme = f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="1640" version="1.7">
  <BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES">
    <BuildActionEntries>
      <BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">
        <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{TGT_UUID}" BuildableName="成长心图.app" BlueprintName="成长心图" ReferencedContainer="container:成长心图.xcodeproj"/>
      </BuildActionEntry>
    </BuildActionEntries>
  </BuildAction>
  <TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES">
    <Testables/>
  </TestAction>
  <LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{TGT_UUID}" BuildableName="成长心图.app" BlueprintName="成长心图" ReferencedContainer="container:成长心图.xcodeproj"/>
    </BuildableProductRunnable>
  </LaunchAction>
  <ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES">
    <BuildableProductRunnable runnableDebuggingMode="0">
      <BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="{TGT_UUID}" BuildableName="成长心图.app" BlueprintName="成长心图" ReferencedContainer="container:成长心图.xcodeproj"/>
    </BuildableProductRunnable>
  </ProfileAction>
  <AnalyzeAction buildConfiguration="Debug"/>
  <ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>'''

with open(os.path.join(xcschemes, '成长心图.xcscheme'), 'w', encoding='utf-8') as f:
    f.write(scheme)

# Summary
print(f"✅ Project generated: {XCODEPROJ}")
print(f"   Target UUID: {TGT_UUID}")
