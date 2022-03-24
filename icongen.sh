#!/usr/bin/env bash

set -eo pipefail
#set -x

CUSTOM_DATA_FOLDER=$(realpath "./CUSTOM_DATA")

DWIN_FOLDER=$(realpath "./DWIN_SET")
if [ ! -d "${DWIN_FOLDER}" ]; then
  echo "ERROR: DWIN_SET folder missing, please copy it to the root directory!"
  exit 1
fi

echo "* Preparing to extract all files from available .ICO files ..."
ICO_EXTRACTED_FOLDER=$(realpath "./DWIN_EXTRACTED")
rm -fr ${ICO_EXTRACTED_FOLDER}
mkdir -p ${ICO_EXTRACTED_FOLDER}
for i in ${DWIN_FOLDER}/*.ICO; do
  [ -f "${i}" ] || break
  ICO_FILENAME=$(basename "${i}")
  ICO_DESTINATION="${ICO_EXTRACTED_FOLDER}/${ICO_FILENAME%.*}"
  echo "  > Extracting ${ICO_FILENAME} ..."
  python3 splitIco.py "${i}" "${ICO_DESTINATION}" >/dev/null
done
echo

echo "You can now make changes to the files in the \"$(basename ${ICO_EXTRACTED_FOLDER})\" folder."
echo
echo "Additionally, you can create a new directory at the root of this project named \"CUSTOM_DATA\","
echo "then copy your custom files there, eg. \"CUSTOM_DATA/0_start.jpg\" or \"CUSTOM_DATA/7/000-ICON_LOGO.jpg\","
echo "after which all of these files will be baked in."
echo "NOTE: These files will overwrite existing files in the \"$(basename ${ICO_EXTRACTED_FOLDER})\" folder!"
echo
echo "When you are done, continue to rebuild them by pressing [Enter] ..."
read -p ""

echo "* Preparing to rebuild all extractacted .ICO files ..."
DWIN_CUSTOM_FOLDER=$(realpath "./DWIN_SET_CUSTOM")
rm -fr "${DWIN_CUSTOM_FOLDER}"
mkdir -p "${DWIN_CUSTOM_FOLDER}"
cp -fr "${DWIN_FOLDER}"/ "${DWIN_CUSTOM_FOLDER}"
rm -fr "${DWIN_CUSTOM_FOLDER}"/*.ICO

if [ -d "${CUSTOM_DATA_FOLDER}" ]; then
  echo "  > Found custom assets, processing ..."
  for i in "${CUSTOM_DATA_FOLDER}"/*; do
    CUSTOM_ASSET=$(basename "${i}")
    if [ -f "${i}" ]; then
      echo "    > Processing custom asset: ${CUSTOM_ASSET} ..."
      cp -fr "${i}" "${DWIN_CUSTOM_FOLDER}/"
    elif [ -d "${i}" ]; then
      if [ ! -d "${ICO_EXTRACTED_FOLDER}/${CUSTOM_ASSET}" ]; then
        echo
        echo "ERROR: Unsupported ICO asset: ${CUSTOM_ASSET}"
        exit 1
      fi
      echo "    > Processing custom ICO asset: ${CUSTOM_ASSET} ..."
      for f in "${i}"/*; do
        if [ -f "${f}" ]; then
          CUSTOM_ICO=$(basename "${f}")
          echo "      > Processing custom ICO asset: ${CUSTOM_ASSET} -> ${CUSTOM_ICO} ..."
          cp -fr "${f}" "${ICO_EXTRACTED_FOLDER}/${CUSTOM_ASSET}"/
        else
          echo
          echo "ERROR: Unsupported ICO asset: ${f}"
          exit 1
        fi
      done
    fi
  done
fi

for d in "${ICO_EXTRACTED_FOLDER}"/*; do
  ICO_FILENAME="$(basename ${d}).ICO"
  echo "  > Rebuilding ${ICO_FILENAME} ..."
  python3 makeIco.py "${d}" "${DWIN_CUSTOM_FOLDER}/${ICO_FILENAME}" >/dev/null
done
rm -fr ${ICO_EXTRACTED_FOLDER}
echo

echo "All done. Remember to rename DWIN_SET_CUSTOM back to DWIN_SET before flashing it to your display!"
