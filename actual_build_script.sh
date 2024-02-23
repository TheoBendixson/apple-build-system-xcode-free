echo Building Mooselutions

OSX_LD_FLAGS="-framework AppKit 
              -framework IOKit
              -framework Metal
              -framework MetalKit
              -framework QuartzCore
              -framework AudioToolbox"

# NOTE: (Ted)   All of these paths are relative to build/mac_os
MAC_PLATFORM_LAYER_PATH="../../code/mac_platform"

COMMON_CODE_PATH="../../code/common/"

PLATFORM_RESOURCES_PATH="../../code/mac_platform/resources"

COMPILER_WARNING_FLAGS="-Werror -Weverything"

DISABLED_ERRORS="-Wno-strict-selector-match
                 -Wno-suggest-override
                 -Wno-global-constructors
                 -Wno-exit-time-destructors
                 -Wno-invalid-offsetof
                 -Wno-unknown-warning-option
                 -Wno-documentation-unknown-command
                 -Wno-newline-eof
                 -Wno-weak-vtables
                 -Wno-non-virtual-dtor
                 -Wno-signed-enum-bitfield
                 -Wno-float-conversion
                 -Wno-float-equal
                 -Wno-format-nonliteral
                 -Wno-gnu-anonymous-struct 
                 -Wno-sometimes-uninitialized
                 -Wno-reserved-id-macro
                 -Wno-disabled-macro-expansion
                 -Wno-implicit-int-conversion
                 -Wno-poison-system-directories
                 -Wno-c++11-compat-deprecated-writable-strings                
                 -Wno-cast-qual
                 -Wno-missing-braces                
                 -Wno-pedantic
                 -Wno-unused-variable
                 -Wno-nested-anon-types
                 -Wno-old-style-cast
                 -Wno-unused-macros
                 -Wno-padded
                 -Wno-unused-function
                 -Wno-missing-prototypes
                 -Wno-unused-parameter
                 -Wno-implicit-atomic-properties
                 -Wno-objc-missing-property-synthesis
                 -Wno-nullable-to-nonnull-conversion
                 -Wno-direct-ivar-access
                 -Wno-sign-conversion
                 -Wno-sign-compare
                 -Wno-double-promotion
                 -Wno-tautological-compare
                 -Wno-c++11-long-long
                 -Wno-cast-align
                 -Wno-reserved-identifier
                 -Wno-zero-as-null-pointer-constant
                 -Wno-implicit-int-float-conversion
                 -Wno-c++98-compat
                 -Wno-writable-strings
                 -Wno-c++98-compat-pedantic
                 -Wno-extra-semi-stmt
                 -Wno-unused-but-set-variable"

RESOURCES_PATH="../../resources"
GAME_LIBRARY_CODE_PATH="../../code/game_library"

release_build=0
steam_build=0
mac_app_store_build=0
verbose=0

for arg in "$@"
do
    if [ "$arg" == "-release" ]
    then
        release_build=1
    fi

    if [ "$arg" == "-steam" ]
    then
        steam_build=1
    fi

    if [ "$arg" == "-macappstore" ]
    then
        mac_app_store_build=1
    fi

    if [ "$arg" == "-verbose" ]
    then
        verbose=1
    fi
done


if [ "$mac_app_store_build" -eq 1 ]
then
    OSX_LD_FLAGS="${OSX_LD_FLAGS}
                  -framework GameKit
                  -framework GameController"
fi

if [ "$verbose" -eq 1 ]
then
    echo OSX Frameworks: ${OSX_LD_FLAGS}
fi

COMMON_COMPILER_FLAGS="$COMPILER_WARNING_FLAGS
                       $DISABLED_ERRORS
                       -DMACOS=1
                       -DWINDOWS=0
                       -DSLOW=1
                       -DINTERNAL=0
                       -std=c++11
                       $OSX_LD_FLAGS"

if [ "$release_build" -eq 1 ]
then
    COMMON_COMPILER_FLAGS="${COMMON_COMPILER_FLAGS}
                           -DLEVELEDITOR=0"
else
    COMMON_COMPILER_FLAGS="${COMMON_COMPILER_FLAGS}
                           -DLEVELEDITOR=1"
fi

if [ "$verbose" -eq 1 ]
then
    echo Common Compiler Flags: ${COMMON_COMPILER_FLAGS}
fi

GAME_BUNDLE_RESOURCES_PATH="Mooselutions.app/Contents/Resources"
GAME_BUNDLE_BUILD_PATH="Mooselutions.app/Contents/MacOS"
GAME_BUNDLE_CODE_RESOURCES_PATH="Mooselutions.app/Contents/CodeResources"

MAC_BUILD_DIRECTORY="../../build/mac_os"

mkdir -p $MAC_BUILD_DIRECTORY
pushd $MAC_BUILD_DIRECTORY

echo Building Game Application Bundle
rm -rf Mooselutions.app

mkdir -p $GAME_BUNDLE_RESOURCES_PATH
mkdir -p $GAME_BUNDLE_BUILD_PATH
mkdir -p $GAME_BUNDLE_CODE_RESOURCES_PATH

STEAMBUILDCOMMAND=""

STOREFRONT="-DSTEAMSTORE=0 
            -DMACAPPSTORE=0"

MIN_MAC_OS_VERSION=10.14

if [ "$steam_build" -eq 1 ]
then
    cp ../../code/steam_library/redistributable_bin/osx/libsteam_api.dylib "${GAME_BUNDLE_BUILD_PATH}/libsteam_api.dylib"
    STOREFRONT="-DSTEAMSTORE=1 
                -DMACAPPSTORE=0"
    STEAMBUILDCOMMAND="-L ${GAME_BUNDLE_BUILD_PATH} -l steam_api -Wl, -rpath @executable_path"
fi

if [ "$mac_app_store_build" -eq 1 ]
then
    STOREFRONT="-DSTEAMSTORE=0 
                -DMACAPPSTORE=1"

    MIN_MAC_OS_VERSION=10.15
fi

xcrun -sdk macosx metal -mmacosx-version-min=${MIN_MAC_OS_VERSION} -gline-tables-only -MO -g -c "${MAC_PLATFORM_LAYER_PATH}/Shaders.metal" -o Shaders.air
xcrun -sdk macosx metallib Shaders.air -o Shaders.metallib

echo Storefront: ${STOREFRONT}

if [ "$release_build" -eq 1 ]
then
    echo Compiling Game Platform Layer \(Fast\)
    clang -O3 -lstdc++ ${COMMON_COMPILER_FLAGS} ${STOREFRONT} -mmacosx-version-min=${MIN_MAC_OS_VERSION} -o Mooselutions "${MAC_PLATFORM_LAYER_PATH}/osx_main.mm" ${STEAMBUILDCOMMAND}

else
    echo Compiling Game Platform Layer \(Slow\)
    clang -g -lstdc++ ${COMMON_COMPILER_FLAGS} ${STOREFRONT} -mmacosx-version-min=${MIN_MAC_OS_VERSION} -o Mooselutions "${MAC_PLATFORM_LAYER_PATH}/osx_main.mm" ${STEAMBUILDCOMMAND}
fi

cp Mooselutions Mooselutions.app/Contents/MacOS/Mooselutions

#otool -l Mooselutions.app/Mooselutions

cp -r ${RESOURCES_PATH}/levels ${GAME_BUNDLE_RESOURCES_PATH}/levels
cp -r ${RESOURCES_PATH}/sounds ${GAME_BUNDLE_RESOURCES_PATH}/sounds
cp -r ${RESOURCES_PATH}/asset_packs/walod.summ ${GAME_BUNDLE_RESOURCES_PATH}/walod.summ

cp ${MAC_PLATFORM_LAYER_PATH}/resources/AppIcon.icns ${GAME_BUNDLE_RESOURCES_PATH}/AppIcon.icns

if [ "$release_build" -eq 0 ]
then
    if [ "$steam_build" -eq 1 ]
    then
        cp ${RESOURCES_PATH}/steam_appid.txt "${GAME_BUNDLE_BUILD_PATH}/steam_appid.txt"
    fi
fi

cp Shaders.metallib ${GAME_BUNDLE_RESOURCES_PATH}/Shaders.metallib
cp ${PLATFORM_RESOURCES_PATH}/GameInfo.plist Mooselutions.app/Contents/Info.plist

if [ "$steam_build" -eq 1 ]
then
    cp ${PLATFORM_RESOURCES_PATH}/SteamEntitlements.plist Mooselutions.app/Contents/Entitlements.plist
fi

if [ "$mac_app_store_build" -eq 1 ]
then
    cp ${PLATFORM_RESOURCES_PATH}/MacAppStoreEntitlements.plist Mooselutions.app/Contents/Entitlements.plist
fi

if [ "$release_build" -eq 1 ]
then
    if [ "$mac_app_store_build" -eq 1 ]
    then
        cp ${PLATFORM_RESOURCES_PATH}/3rd_Party_Mac_Distribution.provisionprofile Mooselutions.app/Contents/embedded.provisionprofile
        codesign -s "3rd Party Mac Developer Application: Send It Apps LLC" --timestamp -f -v --deep --options runtime --entitlements "Mooselutions.app/Contents/Entitlements.plist" Mooselutions.app
        xcrun productbuild --component Mooselutions.app /Applications mooselutions.unsigned.pkg
        xcrun productsign --sign "3rd Party Mac Developer Installer: Send It Apps LLC" mooselutions.unsigned.pkg mooselutions.pkg
    else
        codesign -s "Developer ID Application: Send It Apps LLC" --timestamp -f -v --deep --options runtime --entitlements "Mooselutions.app/Contents/Entitlements.plist" Mooselutions.app
    fi
fi
popd

