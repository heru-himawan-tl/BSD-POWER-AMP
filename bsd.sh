#!/bin/bash

reset

if [ "$1" = "" ]; then
    exit
fi

CWD=$(pwd)
BASE_PRIV="BSD-PRIVATE"
BASE="BSD"
DEST_PRIV="$BASE_PRIV/$(basename $1)"
DEST="$BASE/$(basename $1)"

rm -rf "$DEST_PRIV"
rm -rf "$DEST"

PRIVATE="NO"

for f in $(find $1); do
    is_private=$(echo "$f" | grep 'PRIVATE')
    if [ "$is_private" != "" ] && [ "$PRIVATE" = "NO" ]; then
        PRIVATE="YES"
        echo "=============================================="
        echo "Private repository ..."
        echo "$f"
        echo "=============================================="
    fi
done

if [ ! -d "$DEST_PRIV" ]; then
    mkdir -p $DEST_PRIV
fi

if [ "$PRIVATE" = "NO" ]; then
    if [ ! -d "$DEST" ]; then
        mkdir -p $DEST
    fi
    for f in $(find $1); do
        hf=$(echo "$f" | awk '/(\.(gbr|gvp|kicad_pcb|drl|ps|git|raw|log)|preview|report\.txt|.*-bak|.*-backup.*|.*\.bak|ANALYSIS.*\.net|.*\.kicad_sch-.*|.*auto_saved.*|.*-F_.*|.*-B_.*|.*drl.*|.*_Drawings.*|.*_Eco.*|.*_Cuts.*|.*-Margin.*)/')
        if [ "$hf" = "" ]; then
            dn=$(dirname $f)
            if [ -d "$f" ]; then
                mkdir -p "$BASE/$f"
            fi
            if [ -f "$f" ]; then
                cp -af "$f" $BASE/$dn/.
            fi
        fi
    done
fi

for f in $(find $1); do
    hf=$(echo "$f" | awk '/(.*-bak|.*\.bak|ANALYSIS.*\.net|.*-backup.*|.*\.kicad_sch-.*|.*auto_saved.*|.*\.raw|.*\.log)/')
    if [ "$hf" = "" ]; then
        dn=$(dirname $f)
        if [ -d "$f" ]; then
            mkdir -p "$BASE_PRIV/$f"
        fi
        if [ -f "$f" ]; then
            cp -af "$f" $BASE_PRIV/$dn/.
        fi
    fi
done

cd $BASE_PRIV

git add .
git commit -m "Update `date`"
git push -u origin main

cd $CWD

if [ "$PRIVATE" = "YES" ]; then
    exit
fi

cd $BASE

if [ -f ../BSD-POWER-AMP-README.md ]; then
    cat ../BSD-POWER-AMP-README.md > README.md
    SCH_PNG=
    for f in $(find $1); do
        is_git=$(echo "$f" | awk '/.*\.git.*/')
        if [ "$is_git" = "" ]; then
            pdf=$(echo "$f" | awk '/.*(POWER-AMP|OVERLOAD-PROTECTOR)\.pdf$/')
            if [ "$pdf" != "" ]; then
                echo "============================================="
                echo "Found power amplifier schematic in PDF: $f"
                echo "============================================="
                rm -f $f.png
                pdftocairo -png $f $f
                nf="$f-$(date "+%Y-%m-%d-%H-%M-%S").png"
                mv $f-1.png $nf 
                SCH_PNG="![$(basename $nf)](https://raw.githubusercontent.com/heru-himawan-tl/BSD-POWER-AMP/main/$nf) $SCH_PNG"
            fi
        fi
    done
    for png in $(echo $SCH_PNG); do
        echo "$png" >> README.md
    done
fi

cp -af ../bsd.sh .

git add .
git commit -m "Update `date`"
git push -u origin main

cd $CWD

exit
