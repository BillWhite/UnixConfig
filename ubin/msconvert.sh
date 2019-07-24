#!/bin/bash

# This is a list of all Musescore files, without the extension.
declare -a MSFILES
# This maps part names to album names.  For example, it maps
# "Alto_Saxophone" to "Eb", and "Alto_Flute" to "G".
declare -A PART_REGISTRY
# This is just a set, so all its values are the constant "YES".
declare -A ALBUM_NAMES

# Scores will go here.
OUT_DIR="Scores"
# Albums will go here.
ALBUM_DIR="Albums"
# Parts will go here.
# PART_DIR="Parts"
#
# This is the name of the work.
WORK_NAME="SetList"

makeDir() {
    local LABEL
    local DIRNAME
    LABEL="$1"
    DIRNAME="$2"
    echo "label $LABEL dirname $DIRNAME"
    if [ -n "$DIRNAME" ]; then
        if ! mkdir -p "$DIRNAME" ; then
            echo "$0: Cannot make $LABEL \"$DIRNAME\""
            exit 100
        fi
    fi
}

registerAlbumName() {
    local ALBUM_NAME="$1"
    if [ -z ${ALBUM_NAMES[$ALBUM_NAME]} ] ; then
        ALBUM_NAMES[$ALBUM_NAME]=YES
    fi
}

isAlbumName() {
    local ALBUM_NAME="$1"
    if [ -n "${ALBUM_NAMES[$ALBUM_NAME]}" ] ; then
        return 0
    else
        return 1
    fi
}

registerPart() {
    local NAME="$1"
    local ALBUM_NAME="$2"
    PART_REGISTRY["$NAME"]="$ALBUM_NAME"
    registerAlbumName "$ALBUM_NAME"
}

partNameToAlbumName() {
    local PN="$1"
    # PNC is PartNameCandidate  If PNC is a prefix
    # of PN, then we will match and return ${PART_REGISTRY[$PNC]}.
    for PNC in ${!PART_REGISTRY[@]}; do
        MPN=${PN##${PNC}}
        if [ ${#MPN} -lt ${#PN} ] ; then
            echo "${PART_REGISTRY[$PNC]}"
            return
        fi
    done
    echo "Unknown"
}

printRegistry() {
    echo "Part Registry:"
    for partName in ${!PART_REGISTRY[*]}; do
        echo "    $partName -> ${PART_REGISTRY[$partName]}"
    done
    echo "Album Names:"
    for AN in ${!ALBUM_NAMES[*]}; do
        echo "    $AN"
    done
}

getargs() {
    registerAlbumName "Unknown"
    registerPart "Alto_Saxophone" "Eb"
    registerPart "Tenor_Saxophone" "Bb"
    registerPart "Flute" "C"
    registerPart "Piano" "C"
    registerPart "Kazoo" "C"
    registerPart "Vocal" "C"
    registerPart "Vocals" "C"
    registerPart "Contrabass" "Bass"
    registerPart "ContraBass" "Bass"
    while [ -z "$DONE" ] ; do
        ARG="${1%%=*}"
        VALUE="${1#*=}"
        case "$ARG" in
	    --#)
		set -x
		shift
		;;
            --json-only)
                JSON_ONLY=YES
                shift
                ;;
            --albumDir)
                ALBUM_DIR="$VALUE"
                shift
                ;;
            --partDef|-p)
                PN=${VALUE%%=*}
                AN=${VALUE##*=}
                registerPart "$PN" "$AN"
                shift
                ;;
            --midiDir|-m)
                MIDI_DIR="${VALUE}"
                shift
                ;;
            --partDir|-p)
                PART_DIR="${VALUE}"
                shift
                ;;
            --xmlDir|-x)
                XML_DIR="${VALUE}"
                shift
                ;;
            --outDir|-o)
                OUT_DIR="${VALUE}"
                shift
                ;;
            --tmpDir)
                TMP_DIR="${VALUE}"
                shift
                ;;
            --workName)
		WORK_NAME="${VALUE}"
                shift
		;;
            -*)
                echo "$0: Unknown command line parameter $1"
                exit 100
                ;;
            *)
                DONE=TRUE
                ;;
        esac
    done
    for file in $@; do
        MSFILES[${#MSFILES[*]}]="$(basename $file .mscz)"
    done

    if [ -z "$TMP_DIR" ] ; then
        TMP_DIR="$(mktemp -d)"
        DELETE_TMP_DIR=YES
    fi
    # If nothing is asked for, then only produces parts.
    # Something should happen.
    if [ -z "$MIDI_DIR" ] \
	&& [ -z "$XML_DIR" ] \
	&& [ -z "$PART_DIR" ]  ; then
       echo "Making default parts directory Parts"
       PART_DIR="Parts"
    fi
    makeDir "midi directory" "$MIDI_DIR"
    makeDir "parts directory" "$PART_DIR"
    makeDir "xml directory" "$XML_DIR"
    makeDir "output directory" "$OUT_DIR"
    makeDir "temporary directory" "$TMP_DIR"
    if [ -n "$ALBUM_DIR" ] ; then
        echo "Making album dir $ALBUM_DIR"
        makeDir "album directory" "$ALBUM_DIR"
        for AN in ${!ALBUM_NAMES[*]}; do
            echo "Making album part dir $ALBUM_DIR/$AN"
            makeDir "album part name" "$ALBUM_DIR/$AN"
        done
    fi
    printRegistry
}

makeJsonFile() {
    echo "$TMP_DIR"
    JSFILE="$TMP_DIR/mscore3.js"
    cat /dev/null > "$JSFILE"
    echo "[" >> "$JSFILE"
    NFILES=0
    for file in ${MSFILES[*]}; do
        echo >> "$JSFILE"
        if [ "$NFILES" -gt 0 ] ; then
            echo "," >> "$JSFILE"
        fi
        echo "  {" >> "$JSFILE"
        echo "    \"in\": \"$file.mscz\"," >> "$JSFILE"
        echo "    \"out\": [" >> "$JSFILE"
        echo -n "      \"$OUT_DIR/$file.pdf\"" >> "$JSFILE"
        if [ -n "$PART_DIR" ] ; then
            echo "," >> "$JSFILE"
            echo -n "      [ \"$PART_DIR/$file-\", \".pdf\" ]" >> "$JSFILE"
        fi
        if [ -n "$XML_DIR" ] ; then
            echo "," >> "$JSFILE"
            echo -n "      \"$XML_DIR/$file.mxl\"" >> "$JSFILE"
        fi
        if [ -n "$MIDI_DIR" ] ; then
            echo "," >> "$JSFILE"
            echo -n "      [ \"$MIDI_DIR/$file-\", \".mid\" ]" >> "$JSFILE"
        fi
        echo "    ]" >> "$JSFILE"
        echo -n "  }" >> "$JSFILE"
        NFILES="$(( $NFILES + 1 ))"
    done
    echo >> "$JSFILE"
    echo ']' >> "$JSFILE"
}

runJob() {
    mscore3 -j "$JSFILE"
}

cleanup() {
    if [ -n "$DELETE_TMP_DIR" ] ; then
        rm -rf "$TMP_DIR"
    fi
}

getargs "$@"

makeJsonFile

countFiles() {
    local DIR="$1"
    local PATTERN="$2"
    echo $(find "$DIR" -name "$PATTERN" -print | wc -l)
}

makeTOC() {
   local PDF_DIR="$1"
   local SETLIST_NAME="$2" 
   local OUTPUT_DIR="$3"
   local OUTFILE_BASENAME="$4"
   local WORK_TITLE_NAME="$5"
   local TOC_FILE="$OUTPUT_DIR"/"$OUTFILE_BASENAME.toc"
   local TPAGE
   local TAIL
   cat /dev/null > "${TOC_FILE}"
   PAGE=1
   for file in $(find "$PDF_DIR" -name "*.pdf" | sort); do
	NPAGES="$(pdfinfo "$file" | grep "^Pages:" | sed 's/^Pages: *//')"
        TITLE="$(pdfinfo "$file" | grep "^Title:" | sed 's/^Title: *//' | sed 's/ - .*$//')"
        if [ "$NPAGES" -gt 1 ] ; then
            TAIL=YES
        else
            TAIL=
        fi
        # echo "OFile: $TOC_FILE, IFile: $file, Title: ${TITLE}, NPAGES: $NPAGES"
	TPAGE=1
        while [ "$TPAGE" -le "$NPAGES" ] ; do
	    if [ -n "$TAIL" ] ; then
                TITLE_STRING="$TITLE($TPAGE)"
            else
		TITLE_STRING="$TITLE"
            fi
            echo "$PAGE $TITLE_STRING" >> "$TOC_FILE"
	    TPAGE=$(( $TPAGE + 1 ))
            PAGE=$(( $PAGE + 1 ))
        done
    done
}

makePDFB() {
   local PDF_DIR="$1"
   local SETLIST_NAME="$2" 
   local OUTPUT_DIR="$3"
   local OUTFILE_BASENAME="$4"
   local PDFB_FILE="$OUTPUT_DIR"/"$OUTFILE_BASENAME.pdfb"
   local TPAGE
   local TAIL
   echo "PDFB1;${SETLIST_NAME};;file:///sdcard/Download/${WORK_NAME}/$OUTFILE_BASENAME.pdf;" > "$PDFB_FILE"
   PAGE=1
   for file in $(find "$PDF_DIR" -name "*.pdf" | sort); do
	NPAGES="$(pdfinfo "$file" | grep "^Pages:" | sed 's/^Pages: *//')"
        TITLE="$(pdfinfo "$file" | grep "^Title:" | sed 's/^Title: *//' | sed 's/ - .*$//')"
        if [ "$NPAGES" -gt 1 ] ; then
            TAIL=YES
        else
            TAIL=
        fi
        # echo "OFile: $PDFB_FILE, IFile: $file, Title: $TITLE, NPAGES: $NPAGES"
	TPAGE=1
        while [ "$TPAGE" -le "$NPAGES" ] ; do
	    if [ -n "$TAIL" ] ; then
                TITLE_STRING="$TITLE($TPAGE)"
            else
		TITLE_STRING="$TITLE"
            fi
            echo "$PAGE;$TITLE_STRING;;;;;;;;" >> "$PDFB_FILE"
	    TPAGE=$(( $TPAGE + 1 ))
            PAGE=$(( $PAGE + 1 ))
        done
   done
}

makeAlbums() {
    local PN
    local CT
    local ALBUM_FILE_NAME
    if [ -n "$PART_DIR" ] ; then
        CT=$(countFiles "$PART_DIR" '*.pdf')
        if [ "$CT" -eq 0 ] ; then
            echo "$0: No part files at all.  Forget --partDir\?"
        else
            # First, separate the parts.
            for file in $PART_DIR/*.pdf; do
                PN=$(basename "${file##*-}" .pdf)
                AN=$(partNameToAlbumName "$PN")
                if [ -z "$AN" ] ; then
                    echo "$0: Cannot find album for part $file."
                elif ! isAlbumName "$AN" ; then
                    echo "$0: Cannot find album name for $AN.  This cannot happen."
                else
                    mv "$file" "$ALBUM_DIR/$AN"
                fi
            done
        fi
        # Now concatenate them
        for AN in ${!ALBUM_NAMES[*]} ; do
            dir="$ALBUM_DIR/$AN"
            CT=$(countFiles "$dir" '*.pdf')
            if [ "$CT" -gt 0 ] ; then
                ALBUM_FILE_NAME="${WORK_NAME}_${AN}"
                echo "Creating $AN album in ${ALBUM_DIR}/${ALBUM_FILE_NAME}.pdf"
		makeTOC "$dir" "$WORK_NAME - $AN" "${ALBUM_DIR}" "${ALBUM_FILE_NAME}" "${WORK_NAME} ${AN} Instruments"
		makePDFB "$dir" "$WORK_NAME - $AN" "${ALBUM_DIR}" "${ALBUM_FILE_NAME}"
                pdfunite "$dir"/*.pdf "$ALBUM_DIR/${ALBUM_FILE_NAME}_notoc.pdf"
		k2pdfopt -mode copy -toclist "$ALBUM_DIR/${ALBUM_FILE_NAME}.toc" "$ALBUM_DIR/${ALBUM_FILE_NAME}_notoc.pdf" -o "$ALBUM_DIR/${ALBUM_FILE_NAME}.pdf" < /dev/null
                # rm "${ALBUM_DIR}/${ALBUM_FILE_NAME}_notoc.pdf"
            fi
        done
    fi
}
if [ -z "$JSON_ONLY" ] ; then
    runJob
fi

makeAlbums

cleanup
