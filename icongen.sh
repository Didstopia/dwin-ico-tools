#!/usr/bin/env bash

set -eo pipefail
#set -x

# Parse arguments (note: use "y:" for parameters and "y" for no parameters)
# while getopts y:f:b: flag; do
while getopts ys flag; do
  case "${flag}" in
    ## FIXME: This currently needs to be called with "-y <foo>", when it should just be a boolean flag like "-y"
    y) NO_PROMPT=true;;
    s) SKIP_REMOVE=true;;
    # f) foo=${OPTARG};;
    # b) bar=${OPTARG};;
  esac
done

echo "* Validating the environment ..."

# Set up path variables
CUSTOM_DATA_FOLDER=$(realpath "./CUSTOM_DATA")
DWIN_FOLDER=$(realpath "./DWIN_SET")
DWIN_EXTRACTED_FOLDER=$(realpath "./DWIN_EXTRACTED")
DWIN_CUSTOM_FOLDER=$(realpath "./DWIN_SET_CUSTOM")

# Validate that we have python3 installed
if ! command -v python3 >/dev/null 2>&1; then
  echo "  > ERROR: Python 3 is not installed. Please install it and try again."
  exit 1
fi

## TODO: Switch to using Python3 + Pillow instead of ImageMagick?
# Validate that we have ImageMagick installed
if ! command -v convert >/dev/null 2>&1; then
  echo "  > ERROR: ImageMagick is not installed. Please install it and try again."
  exit 1
fi

# Validate that we have the pillow (PIL) Python module installed
if ! python3 -c "import PIL" >/dev/null 2>&1; then
  echo "  > PIL (Python Imaging Library) is not installed, attempting to install ..."
  if ! python3 -m pip install pillow >/dev/null 2>&1; then
    echo "  > ERROR: Failed to install PIL (Python Imaging Library). Please install it manually and try again."
    exit 1
  else
    echo "  > PIL (Python Imaging Library) installed successfully, continuing ..."
    echo
  fi
fi

# Validate that the DWIN_SET folder exists
if [ ! -d "${DWIN_FOLDER}" ]; then
  echo "  > ERROR: DWIN_SET folder missing, please copy it to the root directory!"
  exit 1
fi

echo "  > Validation succeeded, continuing ..."
echo

echo "* Preparing to extract all files from available .ICO files ..."
rm -fr ${DWIN_EXTRACTED_FOLDER}
mkdir -p ${DWIN_EXTRACTED_FOLDER}

# Extract each .ICO file from the DWIN_SET folder
for i in ${DWIN_FOLDER}/*.ICO; do
  [ -f "${i}" ] || break
  ICO_FILENAME=$(basename "${i}")
  ICO_DESTINATION="${DWIN_EXTRACTED_FOLDER}/${ICO_FILENAME%.*}"
  echo "  > Extracting ${ICO_FILENAME} ..."
  python3 splitIco.py "${i}" "${ICO_DESTINATION}" >/dev/null
done
echo

if [ "${NO_PROMPT}" != "true" ]; then
  echo "You can now make changes to the files in the \"$(basename ${DWIN_EXTRACTED_FOLDER})\" folder."
  echo "WARNING: This folder will be deleted once you press [Enter] and it has been processed!"
  echo
  echo "Additionally, you can create a new directory at the root of this project named \"CUSTOM_DATA\","
  echo "then copy your custom files there, eg. \"CUSTOM_DATA/0_start.jpg\" or \"CUSTOM_DATA/7/000-ICON_LOGO.jpg\","
  echo "after which all of these files will be baked in."
  echo "NOTE: These files will overwrite existing files in the \"$(basename ${DWIN_EXTRACTED_FOLDER})\" folder!"
  echo
  echo "When you are done, continue to rebuild them by pressing [Enter] ..."
  read -p ""
else
  echo "* Skipping extraction prompt, running non-interactively ..."
  echo
fi

echo "* Preparing to rebuild all extractacted .ICO files ..."
rm -fr "${DWIN_CUSTOM_FOLDER}"
mkdir -p "${DWIN_CUSTOM_FOLDER}"
cp -fr "${DWIN_FOLDER}"/ "${DWIN_CUSTOM_FOLDER}"
rm -fr "${DWIN_CUSTOM_FOLDER}"/*.ICO

# Process the custom data folder if it exists
if [ -d "${CUSTOM_DATA_FOLDER}" ]; then
  echo "  > Found custom assets, processing ..."
  for i in "${CUSTOM_DATA_FOLDER}"/*; do
    CUSTOM_ASSET=$(basename "${i}")
    if [ -f "${i}" ]; then
      echo "    > Processing custom asset: ${CUSTOM_ASSET} ..."
      cp -fr "${i}" "${DWIN_CUSTOM_FOLDER}/"
    elif [ -d "${i}" ]; then
      if [ ! -d "${DWIN_EXTRACTED_FOLDER}/${CUSTOM_ASSET}" ]; then
        echo
        echo "ERROR: Unsupported ICO asset: ${CUSTOM_ASSET}"
        exit 1
      fi
      echo "    > Processing custom ICO asset: ${CUSTOM_ASSET} ..."
      for f in "${i}"/*; do
        if [ -f "${f}" ]; then
          CUSTOM_ICO=$(basename "${f}")
          echo "      > Processing custom ICO asset: ${CUSTOM_ASSET} -> ${CUSTOM_ICO} ..."
          cp -fr "${f}" "${DWIN_EXTRACTED_FOLDER}/${CUSTOM_ASSET}"/
        else
          echo
          echo "ERROR: Unsupported ICO asset: ${f}"
          exit 1
        fi
      done
    fi
  done
fi

# Ensure all images are converted to the correct format
echo "  > Converting all assets to the correct format ..."

## FIXME: Detect if we need conversion at all and only convert if we do
# Convert root folder images
for f in "${DWIN_CUSTOM_FOLDER}"/*.jpg; do
  if [ -f "${f}" ]; then
    # echo "  > Converting ${f} ..."
    convert "${f}" -strip -type TrueColor -density 0 "${f}"
  fi
done

## FIXME: Detect if we need conversion at all and only convert if we do
# Convert extracted ICO assets
for d in "${DWIN_EXTRACTED_FOLDER}"/*; do
  if [ -d "${d}" ]; then
    # echo "  > Converting ${d} ICO assets ..."
    for f in "${d}"/*.jpg; do
      if [ -f "${f}" ]; then
        # echo "  > Converting ${f} ..."
        convert "${f}" -strip -type TrueColor -density 0 "${f}"
      fi
    done
  fi
done

# Rebuild each .ICO file from the DWIN_SET folder
for d in "${DWIN_EXTRACTED_FOLDER}"/*; do
  ICO_FILENAME="$(basename ${d}).ICO"
  echo "  > Rebuilding ${ICO_FILENAME} ..."
  python3 makeIco.py "${d}" "${DWIN_CUSTOM_FOLDER}/${ICO_FILENAME}" >/dev/null
done
if [ "${SKIP_REMOVE}" = "true" ]; then
  echo "  > Skipping removal of extracted .ICO files ..."
else
  echo "  > Removing extracted .ICO files ..."
  rm -fr "${DWIN_EXTRACTED_FOLDER}"
fi
echo

echo "All done. Remember to rename DWIN_SET_CUSTOM back to DWIN_SET before flashing it to your display!"
