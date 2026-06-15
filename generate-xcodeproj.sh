#!/bin/bash
set -e

PROJECT_DIR="/Volumes/拓展空间/成长心图"
XCODEPROJ="$PROJECT_DIR/成长心图.xcodeproj"
PBXPROJ="$XCODEPROJ/project.pbxproj"
SRCROOT="成长心图"

echo "🏗  生成 Xcode 项目..."

# 清理旧项目
rm -rf "$XCODEPROJ"
mkdir -p "$XCODEPROJ"

# 收集所有源文件（生成确定性 UUID）
declare -A FILE_UUIDS
declare -A BUILD_UUIDS
COUNTER=0

# 生成伪确定性 UUID
gen_uuid() {
    local seed="$1"
    # 使用 md5 生成 24 位十六进制
    echo "$seed" | md5 | head -c 24 | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1\2\3\4\5/'
}

# 预定义关键 UUID
ROOT_GROUP_UUID=$(gen_uuid "root_group")
SRC_GROUP_UUID=$(gen_uuid "src_group")
PRODUCT_GROUP_UUID=$(gen_uuid "product_group")
PROJECT_UUID=$(gen_uuid "project_obj")
TARGET_UUID=$(gen_uuid "target")
BUILD_CONF_DEBUG_UUID=$(gen_uuid "build_conf_debug")
BUILD_CONF_RELEASE_UUID=$(gen_uuid "build_conf_release")
BUILD_CONF_LIST_UUID=$(gen_uuid "build_conf_list")
SOURCE_BUILD_PHASE_UUID=$(gen_uuid "sources_phase")
RESOURCE_BUILD_PHASE_UUID=$(gen_uuid "resources_phase")
FRAMEWORK_BUILD_PHASE_UUID=$(gen_uuid "frameworks_phase")
NATIVE_TARGET_UUID=$(gen_uuid "native_target")
PRODUCT_REF_UUID=$(gen_uuid "product_ref")

# 收集所有 Swift 文件
echo "📁 扫描源文件..."
SWIFT_FILES=()
while IFS= read -r -d '' f; do
    rel="${f#$PROJECT_DIR/$SRCROOT/}"
    SWIFT_FILES+=("$rel")
done < <(find "$PROJECT_DIR/$SRCROOT" -name "*.swift" -not -name "._*" -print0 | sort -z)

# 收集资源文件
RESOURCE_FILES=()
while IFS= read -r -d '' f; do
    rel="${f#$PROJECT_DIR/$SRCROOT/}"
    # 排除 Swift 和 .DS_Store
    case "$rel" in
        *.swift|*.DS_Store|*._*) continue ;;
    esac
    RESOURCE_FILES+=("$rel")
done < <(find "$PROJECT_DIR/$SRCROOT" -type f -not -name "._*" -print0 | sort -z)

echo "   Swift 文件: ${#SWIFT_FILES[@]}"
echo "   资源文件: ${#RESOURCE_FILES[@]}"

# --- 生成 UUID 映射 ---
declare -A FILE_REF_UUIDS
declare -A BUILD_FILE_UUIDS
declare -A GROUP_UUIDS

# 目录结构分组
declare -A DIR_GROUPS
for f in "${SWIFT_FILES[@]}" "${RESOURCE_FILES[@]}"; do
    dir=$(dirname "$f")
    DIR_GROUPS["$dir"]=1
done

# 为每个目录生成 Group UUID
for dir in "${!DIR_GROUPS[@]}"; do
    GROUP_UUIDS["$dir"]=$(gen_uuid "group_$dir")
done

GROUP_UUIDS["App"]=$(gen_uuid "group_App")
GROUP_UUIDS["Models"]=$(gen_uuid "group_Models")
GROUP_UUIDS["CoreData"]=$(gen_uuid "group_CoreData")
GROUP_UUIDS["CoreData/Extensions"]=$(gen_uuid "group_CoreData_Extensions")
GROUP_UUIDS["ViewModels"]=$(gen_uuid "group_ViewModels")
GROUP_UUIDS["Views"]=$(gen_uuid "group_Views")
GROUP_UUIDS["Views/Experience"]=$(gen_uuid "group_Views_Experience")
GROUP_UUIDS["Views/Diary"]=$(gen_uuid "group_Views_Diary")
GROUP_UUIDS["Views/Analysis"]=$(gen_uuid "group_Views_Analysis")
GROUP_UUIDS["Views/Suggestions"]=$(gen_uuid "group_Views_Suggestions")
GROUP_UUIDS["Views/Profile"]=$(gen_uuid "group_Views_Profile")
GROUP_UUIDS["Views/Panorama"]=$(gen_uuid "group_Views_Panorama")
GROUP_UUIDS["Services"]=$(gen_uuid "group_Services")
GROUP_UUIDS["Extensions"]=$(gen_uuid "group_Extensions")
GROUP_UUIDS["Resources"]=$(gen_uuid "group_Resources")
GROUP_UUIDS["Resources/Assets.xcassets"]=$(gen_uuid "group_Resources_Assets")
GROUP_UUIDS["Resources/Assets.xcassets/AccentColor.colorset"]=$(gen_uuid "group_Assets_Accent")
GROUP_UUIDS["Resources/Assets.xcassets/AppIcon.appiconset"]=$(gen_uuid "group_Assets_AppIcon")

for f in "${SWIFT_FILES[@]}"; do
    FILE_REF_UUIDS["$f"]=$(gen_uuid "file_$f")
    BUILD_FILE_UUIDS["$f"]=$(gen_uuid "build_$f")
done
for f in "${RESOURCE_FILES[@]}"; do
    FILE_REF_UUIDS["$f"]=$(gen_uuid "file_$f")
    BUILD_FILE_UUIDS["$f"]=$(gen_uuid "build_$f")
done

# --- 写入 pbxproj ---
echo "📝 生成 project.pbxproj..."

cat > "$PBXPROJ" << 'HEADER'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {};
	objectVersion = 56;
	objects = {
HEADER

# --- File References ---
echo "/* Begin PBXFileReference section */" >> "$PBXPROJ"

# 产品引用
cat >> "$PBXPROJ" << EOF
		$PRODUCT_REF_UUID /* 成长心图.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = "成长心图.app"; sourceTree = BUILT_PRODUCTS_DIR; };
EOF

# Swift 文件引用
for f in "${SWIFT_FILES[@]}"; do
    uuid="${FILE_REF_UUIDS[$f]}"
    name=$(basename "$f")
    cat >> "$PBXPROJ" << EOF
		$uuid /* $name */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "$name"; sourceTree = "<group>"; };
EOF
done

# 资源文件引用
for f in "${RESOURCE_FILES[@]}"; do
    uuid="${FILE_REF_UUIDS[$f]}"
    name=$(basename "$f")
    ext="${name##*.}"
    case "$ext" in
        plist) ftype="text.plist.xml" ;;
        json) ftype="text.json" ;;
        *) ftype="file" ;;
    esac
    cat >> "$PBXPROJ" << EOF
		$uuid /* $name */ = {isa = PBXFileReference; lastKnownFileType = $ftype; path = "$name"; sourceTree = "<group>"; };
EOF
done

echo "/* End PBXFileReference section */" >> "$PBXPROJ"

# --- Groups ---
echo "" >> "$PBXPROJ"
echo "/* Begin PBXGroup section */" >> "$PBXPROJ"

# Root group
cat >> "$PBXPROJ" << EOF
		$ROOT_GROUP_UUID = {
			isa = PBXGroup;
			children = (
				$SRC_GROUP_UUID /* $SRCROOT */,
				$PRODUCT_GROUP_UUID /* Products */,
			);
			sourceTree = "<group>";
		};
		$PRODUCT_GROUP_UUID /* Products */ = {
			isa = PBXGroup;
			children = (
				$PRODUCT_REF_UUID /* 成长心图.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
EOF

# 源代码根组
echo "		$SRC_GROUP_UUID /* $SRCROOT */ = {" >> "$PBXPROJ"
echo "			isa = PBXGroup;" >> "$PBXPROJ"
echo "			children = (" >> "$PBXPROJ"

# 列出所有子组
declare -A TOP_DIRS
for f in "${SWIFT_FILES[@]}" "${RESOURCE_FILES[@]}"; do
    top="${f%%/*}"
    TOP_DIRS["$top"]=1
done

for dir in App Models CoreData ViewModels Views Services Extensions Resources; do
    if [[ -n "${GROUP_UUIDS[$dir]}" ]]; then
        echo "				${GROUP_UUIDS[$dir]} /* $dir */," >> "$PBXPROJ"
    fi
done

echo "			);" >> "$PBXPROJ"
echo "			path = $SRCROOT;" >> "$PBXPROJ"
echo "			sourceTree = \"<group>\";" >> "$PBXPROJ"
echo "		};" >> "$PBXPROJ"

# 子组 - 递归函数写为硬编码
write_group() {
    local dir="$1"
    local uuid="${GROUP_UUIDS[$dir]}"
    local name=$(basename "$dir")

    echo "		$uuid /* $name */ = {" >> "$PBXPROJ"
    echo "			isa = PBXGroup;" >> "$PBXPROJ"
    echo "			children = (" >> "$PBXPROJ"

    # 列出该目录下的直接文件
    for f in "${SWIFT_FILES[@]}" "${RESOURCE_FILES[@]}"; do
        if [[ "$(dirname "$f")" == "$dir" ]]; then
            echo "				${FILE_REF_UUIDS[$f]} /* $(basename "$f") */," >> "$PBXPROJ"
        fi
    done

    # 列出子目录
    for sub in "${!GROUP_UUIDS[@]}"; do
        if [[ "$sub" != "$dir" && "$(dirname "$sub")" == "$dir" ]]; then
            echo "				${GROUP_UUIDS[$sub]} /* $(basename "$sub") */," >> "$PBXPROJ"
        fi
    done

    echo "			);" >> "$PBXPROJ"
    echo "			path = $name;" >> "$PBXPROJ"
    echo "			sourceTree = \"<group>\";" >> "$PBXPROJ"
    echo "		};" >> "$PBXPROJ"
}

for dir in App Models CoreData "CoreData/Extensions" ViewModels Views Views/Experience Views/Diary Views/Analysis Views/Suggestions Views/Profile Views/Panorama Services Extensions Resources "Resources/Assets.xcassets" "Resources/Assets.xcassets/AccentColor.colorset" "Resources/Assets.xcassets/AppIcon.appiconset"; do
    if [[ -n "${GROUP_UUIDS[$dir]}" ]]; then
        write_group "$dir"
    fi
done

echo "/* End PBXGroup section */" >> "$PBXPROJ"

# --- Build Configuration ---
echo "" >> "$PBXPROJ"
echo "/* Begin XCBuildConfiguration section */" >> "$PBXPROJ"

cat >> "$PBXPROJ" << EOF
		$BUILD_CONF_DEBUG_UUID /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		$BUILD_CONF_RELEASE_UUID /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
				VALIDATE_PRODUCT = YES;
			};
			name = Release;
		};
EOF

# Target 构建配置
cat >> "$PBXPROJ" << EOF
		$(gen_uuid "target_debug") /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "$SRCROOT/Resources/Info.plist";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.growthmind.app;
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			};
			name = Debug;
		};
		$(gen_uuid "target_release") /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "$SRCROOT/Resources/Info.plist";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"\$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.growthmind.app;
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			};
			name = Release;
		};
EOF

echo "/* End XCBuildConfiguration section */" >> "$PBXPROJ"

# --- Build Configuration List ---
echo "" >> "$PBXPROJ"
echo "/* Begin XCConfigurationList section */" >> "$PBXPROJ"

PROJECT_CONF_LIST=$(gen_uuid "proj_conf_list")
TARGET_CONF_LIST=$(gen_uuid "target_conf_list")

cat >> "$PBXPROJ" << EOF
		$PROJECT_CONF_LIST /* Build configuration list for PBXProject */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$BUILD_CONF_DEBUG_UUID /* Debug */,
				$BUILD_CONF_RELEASE_UUID /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		$TARGET_CONF_LIST /* Build configuration list for PBXNativeTarget */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$(gen_uuid "target_debug") /* Debug */,
				$(gen_uuid "target_release") /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
EOF

echo "/* End XCConfigurationList section */" >> "$PBXPROJ"

# --- Build Phases ---
echo "" >> "$PBXPROJ"
echo "/* Begin PBXSourcesBuildPhase section */" >> "$PBXPROJ"

# Sources phase
echo "		$SOURCE_BUILD_PHASE_UUID /* Sources */ = {" >> "$PBXPROJ"
echo "			isa = PBXSourcesBuildPhase;" >> "$PBXPROJ"
echo "			buildActionMask = 2147483647;" >> "$PBXPROJ"
echo "			files = (" >> "$PBXPROJ"
for f in "${SWIFT_FILES[@]}"; do
    echo "				${BUILD_FILE_UUIDS[$f]} /* $(basename "$f") in Sources */," >> "$PBXPROJ"
done
echo "			);" >> "$PBXPROJ"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$PBXPROJ"
echo "		};" >> "$PBXPROJ"

echo "/* End PBXSourcesBuildPhase section */" >> "$PBXPROJ"

# Resources phase
echo "" >> "$PBXPROJ"
echo "/* Begin PBXResourcesBuildPhase section */" >> "$PBXPROJ"

echo "		$RESOURCE_BUILD_PHASE_UUID /* Resources */ = {" >> "$PBXPROJ"
echo "			isa = PBXResourcesBuildPhase;" >> "$PBXPROJ"
echo "			buildActionMask = 2147483647;" >> "$PBXPROJ"
echo "			files = (" >> "$PBXPROJ"
for f in "${RESOURCE_FILES[@]}"; do
    echo "				${BUILD_FILE_UUIDS[$f]} /* $(basename "$f") in Resources */," >> "$PBXPROJ"
done
echo "			);" >> "$PBXPROJ"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$PBXPROJ"
echo "		};" >> "$PBXPROJ"

echo "/* End PBXResourcesBuildPhase section */" >> "$PBXPROJ"

# Frameworks phase
echo "" >> "$PBXPROJ"
echo "/* Begin PBXFrameworksBuildPhase section */" >> "$PBXPROJ"
echo "		$FRAMEWORK_BUILD_PHASE_UUID /* Frameworks */ = {" >> "$PBXPROJ"
echo "			isa = PBXFrameworksBuildPhase;" >> "$PBXPROJ"
echo "			buildActionMask = 2147483647;" >> "$PBXPROJ"
echo "			files = (" >> "$PBXPROJ"
echo "			);" >> "$PBXPROJ"
echo "			runOnlyForDeploymentPostprocessing = 0;" >> "$PBXPROJ"
echo "		};" >> "$PBXPROJ"
echo "/* End PBXFrameworksBuildPhase section */" >> "$PBXPROJ"

# --- Build Files ---
echo "" >> "$PBXPROJ"
echo "/* Begin PBXBuildFile section */" >> "$PBXPROJ"
for f in "${SWIFT_FILES[@]}"; do
    echo "		${BUILD_FILE_UUIDS[$f]} /* $(basename "$f") in Sources */ = {isa = PBXBuildFile; fileRef = ${FILE_REF_UUIDS[$f]} /* $(basename "$f") */; };" >> "$PBXPROJ"
done
for f in "${RESOURCE_FILES[@]}"; do
    echo "		${BUILD_FILE_UUIDS[$f]} /* $(basename "$f") in Resources */ = {isa = PBXBuildFile; fileRef = ${FILE_REF_UUIDS[$f]} /* $(basename "$f") */; };" >> "$PBXPROJ"
done
echo "/* End PBXBuildFile section */" >> "$PBXPROJ"

# --- Native Target ---
echo "" >> "$PBXPROJ"
echo "/* Begin PBXNativeTarget section */" >> "$PBXPROJ"
cat >> "$PBXPROJ" << EOF
		$NATIVE_TARGET_UUID /* 成长心图 */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = $TARGET_CONF_LIST /* Build configuration list for PBXNativeTarget */;
			buildPhases = (
				$SOURCE_BUILD_PHASE_UUID /* Sources */,
				$FRAMEWORK_BUILD_PHASE_UUID /* Frameworks */,
				$RESOURCE_BUILD_PHASE_UUID /* Resources */,
			);
			buildRules = ();
			dependencies = ();
			name = "成长心图";
			productName = "成长心图";
			productReference = $PRODUCT_REF_UUID /* 成长心图.app */;
			productType = "com.apple.product-type.application";
		};
EOF
echo "/* End PBXNativeTarget section */" >> "$PBXPROJ"

# --- Project ---
echo "" >> "$PBXPROJ"
echo "/* Begin PBXProject section */" >> "$PBXPROJ"
cat >> "$PBXPROJ" << EOF
		$PROJECT_UUID /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1640;
				LastUpgradeCheck = 1640;
				TargetAttributes = {
					$NATIVE_TARGET_UUID = {
						CreatedOnToolsVersion = 16.4;
					};
				};
			};
			buildConfigurationList = $PROJECT_CONF_LIST /* Build configuration list for PBXProject */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = "zh-Hans";
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				"zh-Hans",
				Base,
			);
			mainGroup = $ROOT_GROUP_UUID;
			productRefGroup = $PRODUCT_GROUP_UUID /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				$NATIVE_TARGET_UUID /* 成长心图 */,
			);
		};
EOF
echo "/* End PBXProject section */" >> "$PBXPROJ"

# --- Close ---
cat >> "$PBXPROJ" << 'FOOTER'
	};
	rootObject = PROJECT_ROOT_UUID /* Project object */;
}
FOOTER

# 替换最终的 rootObject 引用
sed -i '' "s/PROJECT_ROOT_UUID/$PROJECT_UUID/" "$PBXPROJ"

# 设置正确的文件权限
chmod 644 "$PBXPROJ"

echo ""
echo "✅ 项目生成成功！"
echo "📂 $XCODEPROJ"
echo ""
echo "💡 运行方式："
echo "   open $XCODEPROJ"
