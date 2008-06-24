# requires:
#
# seed words - in $BP/seed
# baseline corpus frequencies format "word count" in $BP/bnc.f


# base path
export BP=/home/student/j/jsteger/boot

# seed file
export S=$BP/seed
# tri-grams
export GRAM=$BP/grams

build_random_tuples.pl -l15 -n3 $S > $GRAM


# unfiltered url list
export T=$BP/scatter

collect_urls_from_yahoo.pl -l en -c 20 $GRAM   > $T


# filtered url list
export TC=$BP/scatter.clean 

grep -v QUERY $T | sort -u -t / -k 2,3 > $TC


# first corpus
export C1=$BP/corpus.0

print_pages_from_url_list.pl < $TC > $C1


# frequencies
export F=$BP/freq

grep -v "CURRENT URL" $C1 | basic_tokenizer.pl -aei - | sort | uniq -c | gawk '(length($2)>2)&&($1>2){print $2,$1}' > $F


# corpus frequency list
export CFREQ=$BP/bnc.f
# output
export SFREQ=$CFREQ.add1

REF=`add1_smoothing.pl -t $CFREQ $F 2>&1 | tail -n2 | head -n1`


# final word list
export WR=$BP/words
TAR=`wc -w < $C1`

paste $F $SFREQ | awk '{print $1,$2,$4}' | log_odds_ratio.pl $TAR $REF - | sort -nrk2 > $WR


# get top words
TWR=$BP/twords

head -n40 $WR | awk '{print $1;}' > $TWR


# 2nd tuples
TUP=$BP/tup
build_random_tuples.pl -l30 -n3 $TWR > $TUP


# final url list
export URLS=$BP/urls
collect_urls_from_yahoo.pl -l en -c 50 $TUP > $URLS

# cleaned url list
export CL=$URLS.clean
grep -v QUERY $URLS | sort -u -t / -k 2,3 > $URLS.clean
