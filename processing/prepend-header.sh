#!/bin/bash

INPUT_FILE=${1:-"_"}
HEADER_ROW=${2:-"_"}
WORKING_DIR=`mktemp -d /tmp/prepend.XXXXXX`

function usage {
  echo "Usage: `basename $0` input_file header_row"
  exit 1
}

function error {
  echo "Error: $@"
  exit 1
}


if [ "_$INPUT_FILE" == "__" ]; then
  echo "Missing input_file."
  usage
fi
if [ ! -f "$INPUT_FILE" ]; then
  error "The input_file ($INPUT_FILE) is invalid."
fi
if [ "_$HEADER_ROW" == "__" ]; then
  echo "Missing header_row argument."
  usage
fi

cp "$INPUT_FILE" $WORKING_DIR/original
pushd $WORKING_DIR > /dev/null
echo $HEADER_ROW > prepended
cat original >> prepended
rm original
popd > /dev/null

mv $WORKING_DIR/prepended "$INPUT_FILE"
rmdir $WORKING_DIR
LINES=`wc -l "$INPUT_FILE" | cut -d' ' -f1`
echo "Done. File now contains $LINES lines."

