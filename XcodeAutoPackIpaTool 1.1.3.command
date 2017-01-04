#!/bin/bash
BASEDIR=$(dirname "$0")
function preDefinedVariables
{
	OUTPUT_PATH="$HOME/Desktop/Exported_IPA";
}
preDefinedVariables
function testDependencies
{
	echo "[*] Checking dependencies...";
	echo "[*] Checking Xcode Command Line Tools..."
	xcode-select -p &> /dev/null;
	if [ "$?" == "2" ]; then
	    echo "[*] Xcode Command Line Tools is not installed...";
	    read -p "[*] Enter any key to continue..." anyKey;
	    bash "$0";
	    exit;
	fi
	echo "[*] Checking Xcode settings..."
	xcodebuild -version &> /dev/null;
	if [ "$?" != "0" ]; then
	    echo "[*] Xcode settings error...";
	    read -p "[*] Enter any key to continue..." anyKey;
	    bash "$0";
	    exit;
	fi
	echo "[*] Checking Coocapods..."
	pod --version &> /dev/null;
	if [ "$?" != "0" ]; then
	    echo "[*] CocoaPods is not installed";
	    echo "[*] pod install command will be skipped";
	    read -p "[*] Enter any key to continue..." anyKey;
	fi
	if [ ! -e "$HOME/.cocoapods" ]; then
	    echo "[*] CocoaPods is not setuped";
	    echo "[*] pod install command will be skipped";
	    read -p "[*] Enter any key to continue..." anyKey;
	fi
	echo "[*] Checking xcpretty..."
	xcpretty -v &> /dev/null;
	if [ "$?" != "0" ]; then
	    echo "[*] xcpretty is not installed";
	    read -p "[*] Enter any key to continue..." anyKey;
	    bash "$0";
	    exit;
	fi
	echo "[*] Done...";
}
function copySourceFile
{
	read -p "[*] Drag the source folder here: " SOURCECODE_PATH
	test "${SOURCECODE_PATH}" == "" && copySourceFile && return;
	test "${SOURCECODE_PATH}" == "q" && bash "$0" && exit;
	test ! -d "${SOURCECODE_PATH}" && echo "[*] ${SOURCECODE_PATH} ,folder does not exist..." && copySourceFile && return;
	PROJECT_FOLDER=`basename "${SOURCECODE_PATH}"`
	PROJECT_FOLDER=${PROJECT_FOLDER// /_};
	echo "[*] "
	echo "[*] Copy source folder to XcodeAutoPackTool?...(y/n)"
	echo "[*] "
	read -p ": " SHOULD_COPY_SOURCE_FOLDER
	if [ "${SHOULD_COPY_SOURCE_FOLDER}" == "Y" -o "${SHOULD_COPY_SOURCE_FOLDER}" == "y" ]; then
		if [ -d "$HOME/XcodeAutoPackTool/${PROJECT_FOLDER}" ]; then 
		    rm -rf "$HOME/XcodeAutoPackTool/${PROJECT_FOLDER}";
		fi;
		echo "[*] Copying sourcecode to $HOME/XcodeAutoPackTool...";
		# echo "SOURCECODE_PATH is ${SOURCECODE_PATH}"
		# echo "PROJECT_FOLDER is ${PROJECT_FOLDER}"
		# cp -aR "${SOURCECODE_PATH}" "$HOME/Desktop/${PROJECT_FOLDER}";
		rsync -avq --progress "${SOURCECODE_PATH}" "$HOME/XcodeAutoPackTool" --exclude ".git"
		cd "$HOME/XcodeAutoPackTool/${PROJECT_FOLDER}"
		WORKSPACE=`pwd`
		echo "[*] Done copying...";
	elif [ "${SHOULD_COPY_SOURCE_FOLDER}" == "N" -o "${SHOULD_COPY_SOURCE_FOLDER}" == "n" ]; then
		cd "${SOURCECODE_PATH}"
		WORKSPACE="${SOURCECODE_PATH}"
		echo "[*] Using sourcecode[${SOURCECODE_PATH}]"
	elif [ "${SHOULD_COPY_SOURCE_FOLDER}" == "Q" -o "${SHOULD_COPY_SOURCE_FOLDER}" == "q" ]; then
		exit 0
	else
		echo "[*] invalid option"
		copySourceFile
	fi
}
function getWorkspaceFile
{
	WORKSPACE_PATH=`find "${WORKSPACE}" -depth 1 -name "*.xcworkspace"`
	WORKSPACE_NAME=`basename "${WORKSPACE_PATH}"`;
	echo "[*] Using Workspace[${WORKSPACE_NAME}]";
}

function getXcodeprojectFile
{
	saveIFS="$IFS"; IFS=$'\n';
	array=()
	while IFS=  read -r -d $'\0'; do
	    array+=("$REPLY")
	done < <(find "${WORKSPACE}" -depth 1 -name "*.xcodeproj" -print0)

	if [ "${#array[@]}" == "1" ]; then
		XCODEPROJ_PATH="${array[0]}";
	else
		XCODEPROJ_OPTIONS=`find "${WORKSPACE}" -depth 1 -name "*.xcodeproj"`;
		PS3="[*] Select preferred .xcodeproj: "
		select XCODEPROJ_SELECTED in ${XCODEPROJ_OPTIONS}; 
		do
			XCODEPROJ_PATH="${XCODEPROJ_SELECTED}"
			# echo "XCODEPROJ_SELECTED is ${XCODEPROJ_SELECTED}"
			break;
		done
	fi
	IFS="$saveIFS";
	XCODEPROJ_NAME=`basename "${XCODEPROJ_PATH}"`;
	echo "[*] Using XcodeProject[${XCODEPROJ_NAME}]";
}

function getSchemeName
{
	echo "[*] Listing schemes..."
	if [ -e "${WORKSPACE}/Podfile" ]; then
		SCHEME_OPTIONS=`xcodebuild -workspace "${WORKSPACE_PATH}" -list | sed -e '1,/Schemes:/d' \
		| sed 's/^ *//g' | sed '/^\s*$/d'`;
	else
		SCHEME_OPTIONS=`xcodebuild -list | sed -e '1,/Schemes:/d' | sed 's/^ *//g' | sed '/^\s*$/d'`;
	fi
	PS3="[*] Select preferred scheme: "
	saveIFS="$IFS"; IFS=$'\n';
	select SCHEME_SELECTED in ${SCHEME_OPTIONS}; 
	do
		SCHEME_NAME="${SCHEME_SELECTED}"
		# echo "SCHEME_SELECTED is ${SCHEME_SELECTED}"
		break;
	done
	IFS="$saveIFS";
	echo "[*] Using Scheme[${SCHEME_NAME}]"
}

function configurationMode
{
	echo "[*] Listing configurations..."
	CONFIGURATION_OPTIONS=`xcodebuild -list | sed -e '1,/Build Configurations:/d' \
	| sed -e '/^\s*$/,$d' | sed 's/^ *//g'`;
	PS3="[*] Select preferred configuration: "
	select CONFIGURATION_SELECTED in ${CONFIGURATION_OPTIONS}; 
	do
		CONFIGURATION_MODE="${CONFIGURATION_SELECTED}"
		# echo "CONFIGURATION_SELECTED is ${CONFIGURATION_SELECTED}"
		break;
	done

	echo "[*] Using configuration[${CONFIGURATION_MODE}]"
}

function getCodeSignIdentity
{
	echo -e "[*] Listing CODE_SIGN_IDENTITY...";
	CODE_SIGN_IDENTITY_OPTIONS=`security find-certificate -c "iPhone Distribution" -a \
	| grep "\"labl\"<blob>=" | sed 's/"labl"<blob>=//g' | sed 's/^ * //g' | sed 's/\"//g'`;
	CODE_SIGN_IDENTITY_OPTIONS="${CODE_SIGN_IDENTITY_OPTIONS}"$'\n'`security find-certificate -c \
	 "iPhone Developer" -a | grep "\"labl\"<blob>=" | sed 's/"labl"<blob>=//g' | 
	 sed 's/^ *//g'| sed 's/\"//g'`;

	saveIFS="$IFS"; IFS=$'\n';
	PS3="[*] Select preferred CODE_SIGN_IDENTITY: "
	select CODE_SIGN_IDENTITY_SELECTED in ${CODE_SIGN_IDENTITY_OPTIONS}; 
	do
		CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY_SELECTED}"
		# echo "CODE_SIGN_IDENTITY_SELECTED is ${CODE_SIGN_IDENTITY_SELECTED}"
		break;
	done
	IFS="$saveIFS" #handle space inside the paths

	echo "[*] Using CODE_SIGN_IDENTITY[${CODE_SIGN_IDENTITY}]"
}

function getProvisioningFile
{
	read -p "[*] Drag the provisioning file here: " PROVISIONING_PROFILE_ORG
	test "${PROVISIONING_PROFILE_ORG}" == "" && getProvisioningFile
	test "${PROVISIONING_PROFILE_ORG}" == "q" && bash "$0" && exit;
	test ! -e "${PROVISIONING_PROFILE_ORG}" && 
	 echo "[*] ${PROVISIONING_PROFILE_ORG} ,file does not exist..." && 
	 getProvisioningFile && return;
	cp "${PROVISIONING_PROFILE_ORG}" "$HOME/Library/MobileDevice/Provisioning Profiles"

	# Extract the .mobileprovisioning file to readable .plist
	openssl smime -inform der -verify -noverify -in "${PROVISIONING_PROFILE_ORG}" > "${WORKSPACE}/tmp.plist"
	PROVISIONING_PROFILE=`defaults read "${WORKSPACE}/tmp.plist" "Name"`;
	PROVISIONING_PROFILE_UUID=`defaults read "${WORKSPACE}/tmp.plist" "UUID"`;
	echo "[*] Using PROVISIONING_PROFILE[${PROVISIONING_PROFILE}]"
}

function changeBundleID
{
	BUNDLEIDENTIFIER=`/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' "${WORKSPACE}/tmp.plist"`;
	NEWBUNDLEIDENTIFIER="${BUNDLEIDENTIFIER#*\.}" # Get rid of the prefix
	TEAMIDENTIFIER=`/usr/libexec/PlistBuddy -c 'Print :Entitlements:com.apple.developer.team-identifier' "${WORKSPACE}/tmp.plist"`;
	# echo "NEWBUNDLEIDENTIFIER is ${NEWBUNDLEIDENTIFIER}"

	getXcodeprojectFile; # Need to know the .xcodeproj location to use its name.

	echo "[*] Check if ${WORKSPACE}/${XCODEPROJ_NAME%.*}/Info.plist exists..."
	if [ -e "${WORKSPACE}/${XCODEPROJ_NAME%.*}/Info.plist" ]; then
		INFOPLIST_PATH=${WORKSPACE}/${XCODEPROJ_NAME%.*}/Info.plist;
	else
		echo "[*] Not exist...";
		echo "[*] Listing path to the Info.plist files...";

		saveIFS="$IFS"; IFS=$'\n';
		INFOPLIST_OPTIONS=`find "${WORKSPACE}" -maxdepth 2 -name "Info.plist"`;
		# echo "INFOPLIST_OPTIONS is ${INFOPLIST_OPTIONS}"
		PS3="[*] Select preferred Info.plist: "
		select INFOPLIST_SELECTED in ${INFOPLIST_OPTIONS}; 
		do
			INFOPLIST_PATH="${INFOPLIST_SELECTED}"
			# echo "INFOPLIST_SELECTED is ${INFOPLIST_SELECTED}"
			break;
		done
		IFS="$saveIFS" #handle space inside the paths
	fi

	test ! -e "${INFOPLIST_PATH}" && echo "${INFOPLIST_PATH} ,file does not exist..." && changeBundleID && return;

	/usr/libexec/PlistBuddy -c 'Set :CFBundleIdentifier "$(PRODUCT_BUNDLE_IDENTIFIER)"' "${INFOPLIST_PATH}";

	
	PROJECT_PBXPROJ_PATH="${XCODEPROJ_PATH}/project.pbxproj";
	NEWBUNDLEIDENTIFIER=${NEWBUNDLEIDENTIFIER/\*/test}

	# echo "PROJECT_PBXPROJ_PATH is ${PROJECT_PBXPROJ_PATH}"
	echo "[*] PRODUCT_BUNDLE_IDENTIFIER: ${NEWBUNDLEIDENTIFIER}"
	echo "[*] PROVISIONING_PROFILE_UUID: ${PROVISIONING_PROFILE_UUID}"
	echo "[*] PROVISIONING_PROFILE:      ${PROVISIONING_PROFILE}"
	
	sed -i '' "s/ProvisioningStyle = Automatic;/ProvisioningStyle = Manual;/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = ${NEWBUNDLEIDENTIFIER};/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/PROVISIONING_PROFILE = .*;/PROVISIONING_PROFILE = \"${PROVISIONING_PROFILE_UUID}\";/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/PROVISIONING_PROFILE_SPECIFIER = .*;/PROVISIONING_PROFILE_SPECIFIER = \"${PROVISIONING_PROFILE}\";/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/CODE_SIGN_IDENTITY = .*;/CODE_SIGN_IDENTITY = \"${CODE_SIGN_IDENTITY}\";/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/\"CODE_SIGN_IDENTITY\[sdk=iphoneos\*\]\" = .*;/\"CODE_SIGN_IDENTITY[sdk=iphoneos*]\" = \"${CODE_SIGN_IDENTITY}\";/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/DevelopmentTeam = .*;/DevelopmentTeam = ${TEAMIDENTIFIER};/g" "${PROJECT_PBXPROJ_PATH}";
	sed -i '' "s/DEVELOPMENT_TEAM = .*;/DEVELOPMENT_TEAM = ${TEAMIDENTIFIER};/g" "${PROJECT_PBXPROJ_PATH}";

	echo "[*] CFBundleIdentifier:        `defaults read "${INFOPLIST_PATH}" "CFBundleIdentifier"`"
}

function buildWithWorkspace
{
	# CocoaPods設定
	pod --version &> /dev/null;
	if [ "$?" != "0" ] || [ ! -e "$HOME/.cocoapods" ]; then
	    echo "[*] pod update command skipped";
	else
		read -p "[*] Do pod update now? May cause some problems for some projects...(y/n): " SHOULD_POD_UPDATE;
		if [ "${SHOULD_POD_UPDATE}" == "y" ]; then
			echo -e "\n================================= Pods Update ==================================\n";
			/usr/local/bin/pod update --verbose --no-repo-update --project-directory="${WORKSPACE}";
		else
		    echo "[*] pod update command skipped";
		fi
	fi
	
	echo -e "\n================================== Archiving ===================================\n"
	xcodebuild \
	 -workspace "${WORKSPACE_PATH}" \
	 -scheme "${SCHEME_NAME}" \
	 -configuration $CONFIGURATION_MODE clean build \
	 -sdk iphoneos archive \
	 -archivePath "$OUTPUT_PATH/archive" \
	 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" 2>&1 |
	 tee -a "$OUTPUT_PATH/log.txt" |
	 /usr/local/bin/xcpretty |
	 tee -a "$OUTPUT_PATH/log_pretty.txt"


	echo "${PRODUCT_BUNDLE_IDENTIFIER}"
	echo -e "\n================================== Exporting ===================================\n"
	xcodebuild \
	 -exportArchive \
	 -exportFormat IPA \
	 -archivePath "$OUTPUT_PATH/archive.xcarchive" \
	 -exportPath "$OUTPUT_PATH/${XCODEPROJ_NAME%.*}" \
	 -exportProvisioningProfile "${PROVISIONING_PROFILE}" 2>&1 |
	 tee -a "$OUTPUT_PATH/log.txt" |
	 /usr/local/bin/xcpretty |
	 tee -a "$OUTPUT_PATH/log_pretty.txt" && 
	 open "$OUTPUT_PATH"
}

function buildWithXcodeproj
{
	echo -e "\n================================== Archiving ===================================\n"
	xcodebuild \
	 -project "${XCODEPROJ_PATH}" \
	 -scheme "${SCHEME_NAME}" \
	 -configuration $CONFIGURATION_MODE clean build \
	 -PRODUCT_BUNDLE_IDENTIFIER="${NEWBUNDLEIDENTIFIER}" \
	 -sdk iphoneos archive \
	 -archivePath "$OUTPUT_PATH/archive" \
	 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" 2>&1 |
	 tee -a "$OUTPUT_PATH/log.txt" |
	 /usr/local/bin/xcpretty |
	 tee -a "$OUTPUT_PATH/log_pretty.txt"

	echo -e "\n================================== Exporting ===================================\n"
	xcodebuild \
	 -exportArchive \
	 -exportFormat IPA \
	 -archivePath "$OUTPUT_PATH/archive.xcarchive" \
	 -exportPath "$OUTPUT_PATH/${XCODEPROJ_NAME%.*}" \
	 -exportProvisioningProfile "${PROVISIONING_PROFILE}" 2>&1 |
	 tee -a "$OUTPUT_PATH/log.txt" |
	 /usr/local/bin/xcpretty |
	 tee -a "$OUTPUT_PATH/log_pretty.txt" && 
	 open "$OUTPUT_PATH"
}

function logBuildSettings
{
	echo "[*] Saving build settings to log...";
	echo -e "Build Settings:
	OUTPUT_PATH = $OUTPUT_PATH
	SOURCECODE_PATH = $SOURCECODE_PATH
	PROJECT_FOLDER = $PROJECT_FOLDER
	SHOULD_COPY_SOURCE_FOLDER = $SHOULD_COPY_SOURCE_FOLDER
	WORKSPACE = $WORKSPACE
	WORKSPACE_PATH = $WORKSPACE_PATH
	WORKSPACE_NAME = $WORKSPACE_NAME
	XCODEPROJ_OPTIONS = 
$XCODEPROJ_OPTIONS
	XCODEPROJ_PATH = $XCODEPROJ_PATH
	XCODEPROJ_NAME = $XCODEPROJ_NAME
	SCHEME_OPTIONS = 
$SCHEME_OPTIONS
	SCHEME_NAME = $SCHEME_NAME
	CONFIGURATION_OPTIONS = 
$CONFIGURATION_OPTIONS
	CONFIGURATION_MODE = $CONFIGURATION_MODE
	CODE_SIGN_IDENTITY_OPTIONS = 
$CODE_SIGN_IDENTITY_OPTIONS
	CODE_SIGN_IDENTITY = $CODE_SIGN_IDENTITY
	PROVISIONING_PROFILE_ORG = $PROVISIONING_PROFILE_ORG
	PROVISIONING_PROFILE = $PROVISIONING_PROFILE
	PROVISIONING_PROFILE_UUID = $PROVISIONING_PROFILE_UUID
	BUNDLEIDENTIFIER = $BUNDLEIDENTIFIER
	NEWBUNDLEIDENTIFIER = $NEWBUNDLEIDENTIFIER
	TEAMIDENTIFIER = $TEAMIDENTIFIER
	INFOPLIST_OPTIONS = 
$INFOPLIST_OPTIONS
	INFOPLIST_PATH = $INFOPLIST_PATH
	PROJECT_PBXPROJ_PATH = $PROJECT_PBXPROJ_PATH
	" >> "$OUTPUT_PATH/log_buildSettings.txt";

	echo -e "\n\nxcodebuild -showBuildSettings:" >> "$OUTPUT_PATH/log_buildSettings.txt";
	if [ -e "${WORKSPACE}/Podfile" ]; then
		xcodebuild \
		 -workspace "${WORKSPACE_PATH}" \
		 -scheme "${SCHEME_NAME}" \
		 -configuration $CONFIGURATION_MODE clean build \
		 -sdk iphoneos archive \
		 -archivePath "$OUTPUT_PATH/archive" \
		 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
		 -showBuildSettings >> "$OUTPUT_PATH/log_buildSettings.txt";
	else
		xcodebuild \
		 -project "${XCODEPROJ_PATH}" \
		 -scheme "${SCHEME_NAME}" \
		 -configuration $CONFIGURATION_MODE clean build \
		 -PRODUCT_BUNDLE_IDENTIFIER="${NEWBUNDLEIDENTIFIER}" \
		 -sdk iphoneos archive \
		 -archivePath "$OUTPUT_PATH/archive" \
		 CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY}" \
		 -showBuildSettings >> "$OUTPUT_PATH/log_buildSettings.txt";
	fi
	echo "[*] Done...";
}

function checkResult
{
	if [[ -e "$OUTPUT_PATH/${XCODEPROJ_NAME%.*}.ipa" ]]; then
		echo "Succeed!!!";
		cat << "EOF";
______________$$$$$$$
_____________$$$$$$$$$
____________$$$$$$$$$$$
____________$$$$$$$$$$$
____________$$$$$$$$$$$
_____________$$$$$$$$$
_____$$$$$$_____$$$$$$$$$$
____$$$$$$$$__$$$$$$_____$$$
___$$$$$$$$$$$$$$$$_________$
___$$$$$$$$$$$$$$$$______$__$
___$$$$$$$$$$$$$$$$_____$$$_$
___$$$$$$$$$$$__________$$$_$_____$$
____$$$$$$$$$____________$$_$$$$_$$$$
______$$$__$$__$$$______________$$$$
___________$$____$_______________$
____________$$____$______________$
_____________$$___$$$__________$$
_______________$$$_$$$$$$_$$$$$
________________$$____$$_$$$$$
_______________$$$$$___$$$$$$$$$$
_______________$$$$$$$$$$$$$$$$$$$$
_______________$$_$$$$$$$$$$$$$$__$$
_______________$$__$$$$$$$$$$$___$_$
______________$$$__$___$$$______$$$$
______________$$$_$__________$$_$$$$
______________$$$$$_________$$$$_$_$
_______________$$$$__________$$$__$$
_____$$$$_________$________________$
___$$$___$$______$$$_____________$$
__$___$$__$$_____$__$$$_____$$__$$
_$$____$___$_______$$$$$$$$$$$$$
_$_____$____$_____$$$$$$__$$$$$$$$

EOF
	else
		echo "Failed..."
		cat << "EOF";
´´´´´´´´´´´´´´´´´´´ ¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶´´´´´´´´´´´´´´´´´´´`
´´´´´´´´´´´´´´´´´¶¶¶¶¶¶´´´´´´´´´´´´´¶¶¶¶¶¶¶´´´´´´´´´´´´´´´´
´´´´´´´´´´´´´´¶¶¶¶´´´´´´´´´´´´´´´´´´´´´´´¶¶¶¶´´´´´´´´´´´´´´
´´´´´´´´´´´´´¶¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´´´´´´´´´´´
´´´´´´´´´´´´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´´´´´´´´´´
´´´´´´´´´´´¶¶´´´´´´´´´´´´´´´´´´´´´`´´´´´´´´´´´¶¶´´´´´´´´´´`
´´´´´´´´´´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´´´´´´´´´
´´´´´´´´´´¶¶´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´¶¶´´´´´´´´´´
´´´´´´´´´´¶¶´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´¶´´´´´´´´´´
´´´´´´´´´´¶¶´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´¶´´´´´´´´´´
´´´´´´´´´´¶¶´´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´¶¶´´´´´´´´´´
´´´´´´´´´´¶¶´´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´¶¶´´´´´´´´´´
´´´´´´´´´´´¶¶´¶¶´´´¶¶¶¶¶¶¶¶´´´´´¶¶¶¶¶¶¶¶´´´¶¶´¶¶´´´´´´´´´´´
´´´´´´´´´´´´¶¶¶¶´¶¶¶¶¶¶¶¶¶¶´´´´´¶¶¶¶¶¶¶¶¶¶´¶¶¶¶¶´´´´´´´´´´´
´´´´´´´´´´´´´¶¶¶´¶¶¶¶¶¶¶¶¶¶´´´´´¶¶¶¶¶¶¶¶¶¶´¶¶¶´´´´´´´´´´´´´
´´´´¶¶¶´´´´´´´¶¶´´¶¶¶¶¶¶¶¶´´´´´´´¶¶¶¶¶¶¶¶¶´´¶¶´´´´´´¶¶¶¶´´´
´´´¶¶¶¶¶´´´´´¶¶´´´¶¶¶¶¶¶¶´´´¶¶¶´´´¶¶¶¶¶¶¶´´´¶¶´´´´´¶¶¶¶¶¶´´
´´¶¶´´´¶¶´´´´¶¶´´´´´¶¶¶´´´´¶¶¶¶¶´´´´¶¶¶´´´´´¶¶´´´´¶¶´´´¶¶´´
´¶¶¶´´´´¶¶¶¶´´¶¶´´´´´´´´´´¶¶¶¶¶¶¶´´´´´´´´´´¶¶´´¶¶¶¶´´´´¶¶¶´
¶¶´´´´´´´´´¶¶¶¶¶¶¶¶´´´´´´´¶¶¶¶¶¶¶´´´´´´´¶¶¶¶¶¶¶¶¶´´´´´´´´¶¶
¶¶¶¶¶¶¶¶¶´´´´´¶¶¶¶¶¶¶¶´´´´¶¶¶¶¶¶¶´´´´¶¶¶¶¶¶¶¶´´´´´´¶¶¶¶¶¶¶¶
´´¶¶¶¶´¶¶¶¶¶´´´´´´¶¶¶¶¶´´´´´´´´´´´´´´¶¶¶´¶¶´´´´´¶¶¶¶¶¶´¶¶¶´
´´´´´´´´´´¶¶¶¶¶¶´´¶¶¶´´¶¶´´´´´´´´´´´¶¶´´¶¶¶´´¶¶¶¶¶¶´´´´´´´´
´´´´´´´´´´´´´´¶¶¶¶¶¶´¶¶´¶¶¶¶¶¶¶¶¶¶¶´¶¶´¶¶¶¶¶¶´´´´´´´´´´´´´´
´´´´´´´´´´´´´´´´´´¶¶´¶¶´¶´¶´¶´¶´¶´¶´¶´¶´¶¶´´´´´´´´´´´´´´´´´
´´´´´´´´´´´´´´´´¶¶¶¶´´¶´¶´¶´¶´¶´¶´¶´¶´´´¶¶¶¶¶´´´´´´´´´´´´´´
´´´´´´´´´´´´¶¶¶¶¶´¶¶´´´¶¶¶¶¶¶¶¶¶¶¶¶¶´´´¶¶´¶¶¶¶¶´´´´´´´´´´´´
´´´´¶¶¶¶¶¶¶¶¶¶´´´´´¶¶´´´´´´´´´´´´´´´´´¶¶´´´´´´¶¶¶¶¶¶¶¶¶´´´´
´´´¶¶´´´´´´´´´´´¶¶¶¶¶¶¶´´´´´´´´´´´´´¶¶¶¶¶¶¶¶´´´´´´´´´´¶¶´´´
´´´´¶¶¶´´´´´¶¶¶¶¶´´´´´¶¶¶¶¶¶¶¶¶¶¶¶¶¶¶´´´´´¶¶¶¶¶´´´´´¶¶¶´´´´
´´´´´´¶¶´´´¶¶¶´´´´´´´´´´´¶¶¶¶¶¶¶¶¶´´´´´´´´´´´¶¶¶´´´¶¶´´´´´´
´´´´´´¶¶´´¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶´´¶¶´´´´´´
´´´´´´´¶¶¶¶´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´´¶¶¶¶´´´´´´´

EOF
	fi
}

cat << "EOF"
          _ _,---._
       ,-','       `-.___
      /-;'               `._
     /\/          ._   _,'o \
    ( /\       _,--'\,','"`. )
     |\      ,'o     \'    //\
     |      \        /   ,--'""`-.
     :       \_    _/ ,-'         `-._
      \        `--'  /                )
       `.  \`._    ,'     ________,','
         .--`     ,'  ,--` __\___,;'
          \`.,-- ,' ,`_)--'  /`.,'
           \( ;  | | )      (`-/
             `--'| |)       |-/
               | | |        | |
               | | |,.,-.   | |_
               | `./ /   )---`  )
              _|  /    ,',   ,-'
             ,'|_(    /-<._,' |--,
             |    `--'---.     \/ \
             |          / \    /\  \
           ,-^---._     |  \  /  \  \
        ,-'        \----'   \/    \--`.
       /            \              \   \'`
EOF
echo " ███████╗██╗  ██╗██╗   ██╗██╗    ██╗██╗███╗   ██╗██████╗    ";
echo " ██╔════╝██║ ██╔╝╚██╗ ██╔╝██║    ██║██║████╗  ██║██╔══██╗   ";
echo " ███████╗█████╔╝  ╚████╔╝ ██║ █╗ ██║██║██╔██╗ ██║██║  ██║   ";
echo " ╚════██║██╔═██╗   ╚██╔╝  ██║███╗██║██║██║╚██╗██║██║  ██║   ";
echo " ███████║██║  ██╗   ██║   ╚███╔███╔╝██║██║ ╚████║██████╔╝▄█╗";
echo " ╚══════╝╚═╝  ╚═╝   ╚═╝    ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝";
echo "                                                            ";
echo " ██╗███╗   ██╗ ██████╗                                      ";
echo " ██║████╗  ██║██╔════╝       Xcode Auto Pack IPA Tool 1.1.3 ";
echo " ██║██╔██╗ ██║██║                                           ";
echo " ██║██║╚██╗██║██║               by David Wang 2016/12/26    ";
echo " ██║██║ ╚████║╚██████╗██╗                                   ";
echo " ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝                                   ";
echo "                                                            ";
echo "[*] Xcode Auto Pack IPA Tool"
echo "[*] by David Wang 2016/12/26"
echo "[*] Skywind, Inc."
echo "--------------------------------------------------------------------------------"
PS3='Please enter your choice number: '
options=("Build Archive Export" "Select Xcode Version" "Install dependencies" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Build Archive Export")
			OPTION="1";
			testDependencies;
			echo "--------------------------------------------------------------------------------"
			copySourceFile;
			echo "--------------------------------------------------------------------------------"
			if [ -e "${WORKSPACE}/Podfile" ]; then
				echo "[*] CocoaPods project detected..."
				getWorkspaceFile;
			else
				echo "[*] Xcode project detected..."
				getXcodeprojectFile;
			fi
			echo "--------------------------------------------------------------------------------"
			getSchemeName;
			echo "--------------------------------------------------------------------------------"
			configurationMode;
			echo "--------------------------------------------------------------------------------"
			getCodeSignIdentity;
			echo "--------------------------------------------------------------------------------"
			getProvisioningFile;
			echo "--------------------------------------------------------------------------------"
			changeBundleID;
			echo "--------------------------------------------------------------------------------"
			
			
			read -p "[*] Start Packing Process...???" SHOULD_START;

			start_time=`date +%s`;

			# Preparing build folder
			echo -e "\n=========================== Preparing output folder ============================\n"
			if [ -d "$OUTPUT_PATH" ]; then 
			    rm -rf "$OUTPUT_PATH";
			fi;
			mkdir "$OUTPUT_PATH";

			logBuildSettings
			echo "--------------------------------------------------------------------------------"

			if [ -e "${WORKSPACE}/Podfile" ]; then
				buildWithWorkspace;
			else
				buildWithXcodeproj;
			fi
			checkResult;
			end_time=`date +%s`
			echo execution time was `expr $end_time - $start_time` s.
			echo "[*] Proccess finished..."
			read -p "[*] Enter any key to continue..." anyKey;
			bash "$0"
			exit
            ;;
        "Select Xcode Version")
			OPTION="2";
			echo -e "\n[*] Listing current selected Xcode..."
			xcode-select -p
			echo -e "\n[*] Listing available Xcodes..."
			# find /Applications -maxdepth 3 -iname 'Developer'

			saveIFS="$IFS"; IFS=$'\n';
			XCODE_OPTIONS=`find /Applications -maxdepth 3 -iname 'Developer'`;
			XCODE_OPTIONS="${XCODE_OPTIONS}"$'\n'"Cancel"
			PS3="[*] Select preferred Xcode: "
			select XCODE_SELECTED in ${XCODE_OPTIONS}; 
			do
				test "${XCODE_SELECTED}" == "Cancel" && bash "$0" && exit;
				NEWXCODE_PATH="${XCODE_SELECTED}"
				# echo "XCODE_SELECTED is ${XCODE_SELECTED}"
				break;
			done
			IFS="$saveIFS" #handle space inside the paths

			test "${NEWXCODE_PATH}" == "q" && bash "$0" && exit 0;
			test ! -e "${NEWXCODE_PATH}" && echo "${NEWXCODE_PATH} ,file does not exist..." &&
			 bash "$0" && exit 0;
			sudo xcode-select -s "${NEWXCODE_PATH}"
			echo "[*] Xcode path has been set..."
			read -p "[*] Enter any key to continue..." anyKey;
			bash "$0"
            exit
            ;;
        "Install dependencies")
			OPTION="3";
			echo "[*] Checking dependencies..."
			echo "[*] Checking Xcode Command Line Tools..."
			xcode-select -p &> /dev/null;
			if [ "$?" == "2" ]; then
			    echo "[*] Xcode Command Line Tools is not installed...";
			    read -p "[*] Enter any key to continue..." anyKey;
			    read -p "[*] Do you want to install CocoaPods? (y/n)..." SHOULD_INSTALL_CLT;
			    test "${SHOULD_INSTALL_CLT}" == "y" && xcode-select --install;
				xcode-select -p &> /dev/null;
				test "$?" == "0" && echo "[*] Xcode Command Line Tools installed!";
			    exit;
			fi
			echo "[*] Checking CocoaPods..."
			pod --version &> /dev/null;
			if [ "$?" != "0" ]; then
			    echo "[*] CocoaPods is not installed";
			    read -p "[*] Enter any key to continue..." anyKey;
			    read -p "[*] Do you want to install CocoaPods? (y/n)..." SHOULD_INSTALL_COCOAPODS;
			    test "${SHOULD_INSTALL_COCOAPODS}" == "y" && sudo gem install cocoapods -n /usr/local/bin;
		    	pod --version &> /dev/null;
		    	test "$?" == "0" && echo "[*] CocoaPods installed!";
			fi
			pod --version &> /dev/null;
			if [ "$?" == "0" ] && [ ! -e "$HOME/.cocoapods" ]; then
	    		echo -e "[*] Setup CocoaPods Now? Mandatory for first-time instllation..."
	    		read -p "[*] This will take a while...(y/n): " SHOULD_POD_SETUP;
	    		test "${SHOULD_POD_SETUP}" == "y" && pod setup --verbose;
	    		test -e "$HOME/.cocoapods" && echo "[*] CocoaPods setup completed!"
    		fi
			echo "[*] Checking xcpretty..."
			xcpretty -v &> /dev/null;
			if [ "$?" != "0" ]; then
			    echo "[*] xcpretty is not installed";
			    read -p "[*] Enter any key to continue..." anyKey;
			    read -p "[*] Do you want to install xcpretty? (y/n)..." SHOULD_INSTALL_XCPRETTY;
			    test "${SHOULD_INSTALL_XCPRETTY}" == "y" && sudo gem install xcpretty -n /usr/local/bin;
				xcpretty -v &> /dev/null;
				test "$?" == "0" && echo "[*] xcpretty installed!";
			fi
			echo "[*] Done checking..."
			read -p "[*] Enter any key to continue..." anyKey;
			bash "$0"
            exit
            ;;
        "Quit")
			echo "Bye Bye~";
            exit
            ;;
        *) echo invalid option;;
    esac
done
