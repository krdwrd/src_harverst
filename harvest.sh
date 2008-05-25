#!/bin/sh

for g in *.ggx;
do
	echo $g
	i=0
	for url in `cat $g`;
	do
		cat=`basename $g .ggx`
		ind=`echo $i | awk '{ printf("%03d", $1);}'`
		b=`echo $url | sed 's/^\(.*\/\).*$/\1/' | sed 's/\//\\\\\//g' `
		wget -O $cat.$ind.html "$url"
		sed -i 's/<head>/<head><base href="'$b'"\/>/' $cat.$ind.html
		let i++
	done
done

