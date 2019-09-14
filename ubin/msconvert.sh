#!/bin/bash

# This is a list of all Musescore files, without the extension.
declare -a MSFILES
# This is a list of all PDF files, without the initial PDF and
# key or .pdf suffix.  A tune T will be in PDF/K/T_K.pdf.
declare -a PDFFILES
# This is a set of PDF names.
declare -A PDFNUMS
# This maps part names to album names.  For example, it maps
# "Alto_Saxophone" to "Eb", and "Alto_Flute" to "G".
declare -A PART_REGISTRY
# This is just a set, so all its values are the constant "YES".
declare -A ALBUM_NAMES

# This is the name of the work.
WORK_NAME="SetList"
# Scores will go here.  We will set it later.
OUT_DIR=""
# Albums will go here.  We will set it later.
ALBUM_DIR=""
# Parts will go here.  We will set it later.
# PART_DIR="Parts"
#

#
# Usually, bump the patch version, which is just
# the git commit SHA anyway.
BUMPVERSION=
# Don't save the Scores or Parts Directories.
SAVE_SCORES=
SAVE_PARTSDIR=
# Set to non-null for debugging.
DEBUG=

makeStampFile() {
    STAMP_TEMPLATE=tools/stamp.ps
    STAMP_FILE="${ALBUM_DIR}/Stamp.pdf"
    sed --expression="s/@DATE@/$NOW/" \
        --expression="s/@MAJ_VERSION@/$(printf "%03d" ${MAJ_VERSION})/" \
        --expression="s/@MIN_VERSION@/$(printf "%03d" ${MIN_VERSION})/" \
        --expression="s/@PATCH_VERSION@/$(printf "%07s" ${PATCH_VERSION})/" \
        ${STAMP_TEMPLATE} \
      | ps2pdf - ${STAMP_FILE}
}

rollDir() {
    local DIRNAME="$1"
    local CTR=1
    local LAST=0
    if [ -d "$DIRNAME" ] ; then
        while [ "$CTR" -lt 101 ] && [ -d "$DIRNAME.$CTR" ] ; do
            LAST=$CTR
            CTR=$(( $CTR + 1 ))
        done
        # If we ran over, then remove the oldest one.
        if [ -d "$DIRNAME.$CTR" ] ; then
            rm -rf "$DIRNAME.CTR"
        fi
        # Now, $DIRNAME.$CTR does not exist, and $LAST = $CTR-1.  So
        # Move $DIRNAME.$LAST to $DIRNAME.$CTR, and move left.
        while [ "$LAST" -ge 1 ] ; do
            if [ -n "$LAST" ] ; then
                mv "$DIRNAME.$LAST" "$DIRNAME.$CTR"
            fi
            CTR=$LAST
            LAST=$(( $CTR - 1 ))
        done
        # Save the current directory.
        mv "$DIRNAME" "$DIRNAME.1"
    fi
}

makeDir() {
    local LABEL
    local DIRNAME
    LABEL="$1"
    DIRNAME="$2"
    if [ -n "$DEBUG" ] ; then
        echo "Making $LABEL dirname $DIRNAME"
    fi
    if [ -n "$DIRNAME" ]; then
        if [ -d "$DIRNAME" ] ; then
            rollDir "$DIRNAME"
        fi
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
    # PNC is PartNameCandidate.
    for PNC in ${!PART_REGISTRY[@]}; do
        if [ "$PN" = "$PNC" ] ; then
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

getversion() {
    FN="tools/${WORK_NAME}Version.txt"
    if [ ! -f "$FN" ] ; then
        echo "MAJ_VERSION=1" > "$FN"
        echo "MIN_VERSION=1" >> "$FN"
    fi
    . "$FN"
    PATCH_VERSION="$(git rev-parse --short HEAD)"
    echo "Major version $MAJ_VERSION"
    echo "Minor version $MIN_VERSION"
    echo "Patch version $PATCH_VERSION"
}

bumpversion() {
    local ARG="$1"
    FN="tools/${WORK_NAME}Version.txt"
    case "$ARG" in
    --major)
	MAJ_VERSION=$(($MAJ_VERSION+1))
        MIN_VERSION=1
	;;
    --minor)
	MIN_VERSION=$(($MIN_VERSION+1))
	;;
    esac
    echo "MAJ_VERSION=$MAJ_VERSION" > "$FN"
    echo "MIN_VERSION=$MIN_VERSION" >> "$FN"
}

getargs() {
    local DONE
    local ERRORS
    local BN
    registerAlbumName "Unknown"
    registerPart "Alto_Saxophone" "Eb"
    registerPart "Tenor_Saxophone" "Bb"
    registerPart "Flute" "C"
    registerPart "Piano" "C"
    registerPart "Kazoo" "C"
    registerPart "Vocal" "Vocal"
    registerPart "Vocals" "Vocal"
    registerPart "Contrabass" "Bass"
    registerPart "C" "C"
    registerPart "Bb" "Bb"
    registerPart "Eb" "Eb"
    while [ -z "$DONE" ] ; do
        ARG="${1%%=*}"
        VALUE="${1#*=}"
        case "$ARG" in
            --debug)
                DEBUG=YES
                shift
                ;;
	    --#)
		set -x
                DEBUG=YES
		shift
		;;
            --json-only)
                JSON_ONLY=YES
                shift
                ;;
            --notoc)
                NOTOC=YES
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
            --bumpMajor)
		BUMPVERSION=--major
		shift
		;;
	    --bumpMinor)
		BUMPVERSION=--minor
		shift
		;;
	    --bumpPatch)
		BUMPVERSION=--patch
		shift
		;;
            --bumpNone)
		BUMPVERSION=
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
                ERRORS=YES
                ;;
            *)
                DONE=TRUE
                ;;
        esac
    done
    ERRORS=""
    for file in $@; do
        case "$file" in
            MS3/*)
                BN="$(basename $file .mscz)"
                if [ ! -f "MS3/${BN}.mscz" ] ; then
                    echo "$0: Cannot find MuseScore3 file \"MS3/${BN}.mscz\""
                    ERRORS=yes
                fi
                MSFILES[${#MSFILES[*]}]="$BN"
                ;;
            PDF/*)
                BN="$(basename "$file" | sed 's/\([^-]*\)-[a-zA-Z]*\.pdf/\1/')"
                echo $file goes to $BN
                if [ ! -f PDF/"${BN}-C.pdf" ] \
                       || [ ! -f PDF/"${BN}-Bb.pdf" ] \
                       || [ ! -f PDF/"${BN}-Eb.pdf" ] ; then
                    echo "$0: Warning: Some PDF file for $file is missing."
                    # Should this be an error?  Maybe so, maybe not.
                fi
		if [ -z ${PDFNUMS[$BN]} ] ; then
		    PDFNUMS[$BN]=${#PDFFILES[*]}]
                    PDFFILES[${#PDFFILES[*]}]="$BN"
                fi
                ;;
            *)
                echo "$0: Unknown file type $file"
                ERRORS=YES
                ;;
        esac
    done

    if [ -n "$DEBUG" ] ; then
        echo "MS3 Files:"
        for file in ${MSFILES[*]}; do
            echo "  $file"
        done
        echo "PDF Files:"
        for file in ${PDFFILES[*]}; do
            echo "  $file"
        done
    fi
    if [ -n "$ERRORS" ] ; then
        # Hope we got an error message.
        exit 1
    fi

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
       PART_DIR="${WORK_NAME}Parts"
    fi
    makeDir "midi directory" "$MIDI_DIR"
    makeDir "parts directory" "$PART_DIR"
    makeDir "xml directory" "$XML_DIR"
    if [ -z "$OUT_DIR" ] ; then
        OUT_DIR="${WORK_NAME}Scores"
    fi
    makeDir "output directory" "$OUT_DIR"
    makeDir "temporary directory" "$TMP_DIR"
    if [ -z "$ALBUM_DIR" ] ; then
        ALBUM_DIR="${WORK_NAME}Albums"
    fi
    echo "Making album dir $ALBUM_DIR"
    makeDir "album directory" "$ALBUM_DIR"
    for AN in ${!ALBUM_NAMES[*]}; do
        echo "Making album part dir $ALBUM_DIR/$AN"
        makeDir "album part name" "$ALBUM_DIR/$AN"
    done
    # Make a stamp file, with a date and version number.
    makeStampFile
    if [ -n "$DEBUG" ] ; then
        printRegistry
    fi
}

makeJsonFile() {
    JSFILE="$TMP_DIR/mscore3.js"
    if [ -n "$DEBUG" ] ; then
        echo "$0: Making json file $JSFILE"
    fi
    cat /dev/null > "$JSFILE"
    echo "[" >> "$JSFILE"
    NFILES=0
    for file in ${MSFILES[*]}; do
        echo >> "$JSFILE"
        if [ "$NFILES" -gt 0 ] ; then
            echo "," >> "$JSFILE"
        fi
        echo "  {" >> "$JSFILE"
        echo "    \"in\": \"MS3/$file.mscz\"," >> "$JSFILE"
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
    if [ -n "SAVE_SCORES" ] && [ -d "$OUT_DIR" ]; then
        rm -rf "$OUT_DIR"
    fi
    if [ -n "$SAVE_PARTS" ] && [ -d "$PART_DIR" ] ; then
        rm -rf "$PART_DIR"
    fi
    if [ -n "$BUMPVERSION" ] ; then
        bumpversion $BUMPVERSION
    fi
}

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
        if [ -z "$TITLE" ] ; then
            TITLE="$(echo $(basename "$file") | sed 's/-[^-]*$//g' | sed 's/__*/ /'g )"
        fi
        if [ "$NPAGES" -gt 1 ] ; then
            TAIL=YES
        else
            TAIL=
        fi
        if [ -n "$DEBUG" ] ; then
            echo "OFile: $TOC_FILE, IFile: $file, Title: ${TITLE}, NPAGES: $NPAGES"
        fi
	TPAGE=1
	TITLE_STRING="$TITLE"
        echo "BookmarkBegin" >> "${TOC_FILE}"
        echo "BookmarkLevel: 1" >> "${TOC_FILE}"
        echo "BookmarkTitle: $TITLE_STRING" >> "${TOC_FILE}"
        echo "BookmarkPageNumber: $PAGE" >> "${TOC_FILE}"
        PAGE=$(( $PAGE + $NPAGES ))
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
        if [ -z "$TITLE" ] ; then
            TITLE="$(echo $(basename "$file") | sed 's/-[^-]*$//g' | sed 's/__*/ /'g )"
        fi
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
            echo "$0: No part files at all.\?"
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
                    if [ -n "$DEBUG" ] ; then
                       echo "$0: Moving \"$file\" to \"$ALBUM_DIR/$AN\""
                       echo "    Part name is \"$PN\""
                       echo "    Album name is \"$AN\""
                    fi
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
                if [ -z "$NOTOC" ] ; then
		    pdftk "${ALBUM_DIR}/${ALBUM_FILE_NAME}_notoc.pdf" \
                        update_info "${ALBUM_DIR}/${ALBUM_FILE_NAME}.toc" \
                        output "${ALBUM_DIR}/${ALBUM_FILE_NAME}_toc.pdf"
                    pdftk "${ALBUM_DIR}/${ALBUM_FILE_NAME}_toc.pdf" \
                          stamp "${STAMP_FILE}" \
                          output "${ALBUM_DIR}/${ALBUM_FILE_NAME}.pdf"
                else
                    cp "$ALBUM_DIR/${ALBUM_FILE_NAME}_notoc.pdf" "${ALBUM_DIR}/${ALBUM_FILE_NAME}.pdf"
                fi
                rm -f "${ALBUM_DIR}/${ALBUM_FILE_NAME}_notoc.pdf" "${ALBUM_DIR}/${ALBUM_FILE_NAME}_toc.pdf"
                rm -f "${ALBUM_DIR}/${ALBUM_FILE_NAME}.toc"
            fi
        done
    fi
}

copyPDFFiles() {
    echo "Copying PDF files"
    for file in ${PDFFILES[*]} ; do
        echo " File basename $file"
        for key in C Eb Bb; do
            PDFFILE="PDF/${file}-${key}.pdf"
            echo "  PDF file $PDFFILE"
            if [ -f "$PDFFILE" ] ; then
                echo "Copying \"$PDFFILE\" to \"${PART_DIR}/${file}-${key}.pdf\""
                cp "$PDFFILE" "${PART_DIR}/${file}-${key}.pdf"
            fi
        done
    done
}

# Remember today's date and time.
NOW="$(date --iso=seconds)"

getargs "$@"

getversion

makeStampFile

makeJsonFile

if [ -n "$JSON_ONLY" ] ; then
    echo "No run, just json file."
    exit 0
fi

runJob

copyPDFFiles

makeAlbums

cleanup
