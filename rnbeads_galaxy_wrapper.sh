#!/bin/bash
random_hash=`date | md5sum | head -c10`
Rscript --no-save $(dirname $(readlink -f $0))/RnBeadsGalaxy.R $* > /tmp/rnbeads_${random_hash}.stdout 2>/tmp/rnbeads_${random_hash}.stderr
#Rscript --no-save \$R_SCRIPTS_PATH/RnBeadsGalaxy.R $*
outfile=`echo $* | cut -d\  -f2 | sed -e "s/--output-file=//g"`
echo $outfile
#outdir=`echo $* | sed -e "s/.*--report-dir=\(.*\)[[:blank:]].*/\1/g"`


errl=`cat /tmp/rnbeads_${random_hash}.stderr | grep -e "[E|e]rror" | wc -l`
started=`cat /tmp/rnbeads_${random_hash}.stdout | grep -e "STARTED RnBeads Pipeline" | wc -l`
if [ "$started" -lt 1 ]
then
        cat /tmp/rnbeads_${random_hash}.stdout >&2
        cat /tmp/rnbeads_${random_hash}.stderr >&2
        exit 3
else
        echo "<html><body>" >> $outfile
        echo "<a href=\"index.html\">RnBeads report</a>" >> $outfile
        echo "<br/><br/><h5>Output was generated during the execution:</h5><br/>" >> $outfile
        echo "<pre>" >> outfile
        cat /tmp/rnbeads_${random_hash}.stdout |sed -e "s/$/<br\/>/g" >> $outfile
        echo "</pre>" >> outfile
        echo "</p>" >> $outfile
        echo "</body></html>" >> $outfile
        exit 0
fi   