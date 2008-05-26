#!/bin/sh

# takes: list of files of url lists (ending in .ggx)

export LANG=en_US.UTF-8

for g in $@;
do
	echo $g
	i=0
	for url in `cat $g`;
	do
		cat=`basename $g .ggx`
		ind=`echo $i | awk '{ printf("%03d", $1);}'`
		b=`echo $url | sed 's/^\(.*\/\).*$/\1/' | sed 's/\//\\\\\//g' `
		let i++
		echo "$cat - $ind"
		test -f $cat.$ind.html && continue
		FN=$cat.$ind.html
		wget --timeout=60 -o $cat.$ind.log --tries=2 -O $FN "$url" || continue
		sed 's/<head>/<head><base href="'$b'"\/>/i' $FN > $FN.orig
		iconv -t utf-8 $FN.orig -o $FN
	done
done

