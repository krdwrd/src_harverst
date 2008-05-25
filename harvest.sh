#!/bin/sh

# takes: list of files of url lists

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
		wget --timeout=60 -o $cat.$ind.log --tries=2 -O $cat.$ind.html "$url" || continue
		sed -i 's/<head>/<head><base href="'$b'"\/>/i' $cat.$ind.html
	done
done

