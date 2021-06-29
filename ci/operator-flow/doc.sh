#!/bin/bash
NPRS=${1-1000}

SCRIPT_DIR="$(dirname $(readlink -m $0))"
DOC_DIR="$(dirname $(dirname $(dirname $(readlink -m $0))))"/docs

$SCRIPT_DIR/measure-operator-flow.py -l $NPRS -o results.json
$SCRIPT_DIR/ana.py
[ -d $DOC_DIR/images/stats ] || mkdir -p $DOC_DIR/images/stats
cp *.pdf *.png $DOC_DIR/images/stats

