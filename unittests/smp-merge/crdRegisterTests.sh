#!/bin/bash
rm -fr /tmp/tmp.*
rm -fr /tmp/kust*
rm -fr /tmp/mdrip*
MDRIP=../../tools/bin/mdrip
for i in `cat readmelist | grep -v "^#"`
do
   echo "=========================" $i "====================="
   $MDRIP --mode test $i
done
