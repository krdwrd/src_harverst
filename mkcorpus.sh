# requires:
#
# BootCaT > 0.1.9 (= 0.1.9 with local modifications; we'll try to get this upstream...)
# seed words - in $BP/seed
# baseline corpus frequencies format "word count" in $BP/CORPUSNAME.f

# do we want script specific infos?
INFOMSGS=0  # no // 1 # yes

# base path
[[ ${0} == 'bash' ]] && BP=$(pwd) || BP=$(dirname ${0})
# ...in case we have some modified commands - use these!
PATH=$BP:$PATH

# seed file
S=$BP/seed

# initial n-grams
GRAM=$BP/grams

# first (unfiltered) url lists
T=$BP/scatter
TC=$T.clean 

# first corpus
C1=$BP/corpus.0

# first corpus' frequencies
F=$BP/freq

# corpus frequency list
# e.g. 
#  cwb-lexdecode -f CORPUSNAME | sort -n > $BP/CORPUSNAME.f
#  
#  in case, more than one file needs to be summed-up...
#   awk '{a[$2] += $1} END{for (i in a) print i" "a[i]}' itwac3.freq  > itwac3.freq.unified
CFREQ=$BP/itwac3.unified.f
# smoothened output
SFREQ=$CFREQ.add1

# final word list
WR=$BP/words

# final (unfiltered) url lists
URLS=$BP/urls
CL=$URLS.clean

# do we want to (re-)pass the first stage?
FIRSTPASS=1 # yes // 0 # no
FIRSTNHALFPASS=1 # yes // 0 # no

QLANG=Italian
CRIGHT=realany

# parse (optional) arguments
while getopts ":c:l:r:s:v12" opt; do
    case ${opt} in

        c)
        # the 'compare-to-corpus'
        CFREQ=${BP}/${OPTARG}
        SFREQ=$CFREQ.add1
        ;;

        l)
        # the language the results of queries should have
        QLANG=${OPTARG}
        ;;

        r)
        # copyright
        CRIGHT=${OPTARG}
        ;;

        s)
        # the seed terms
        S=${OPTARG}
        ;;

        v)
        INFOMSGS=1
        ;;

        1)
        FIRSTPASS=0
        ;;

        2)
        FIRSTNHALFPASS=0
        FIRSTPASS=0
        ;;

        \?)
        echo "Unknow Option -${OPTARG} ...but continuing!"   >&2
        ;;
        
    esac
done

export BP
export S 
export GRAM
export T TC
export C1
export F
export CFREQ SFREQ
export WR
export URLS CL
export QLANG
export CRIGHT

#
# init ends here
#
###


###
#
#

function firstpass {
    (( INFOMSGS)) && echo "# building first-pass specialist URL list"

    # build initial n-grams
    build_random_tuples.pl -l100 -n2 $S   > $GRAM
    (( INFOMSGS )) && echo "build_random_tuples.pl - got $(wc -l < ${GRAM} 2>/dev/null) tuples."

    # first (unfiltered) url list
    collect_urls_from_yahoo.pl -l ${QLANG} -c 50 $GRAM   > $T
    (( INFOMSGS )) && echo "collect_urls_from_yahoo.pl - got $(wc -l < ${T} 2>/dev/null) URLs."

    # first filtered url list
    grep -v QUERY $T | sort -u -t / -k 2,3   > $TC
}

function firstnhalfpass {
    (( INFOMSGS)) && echo "# building first-pass specialist corpus"

    # first corpus
    print_pages_from_url_list.pl <   $TC   > $C1
    (( INFOMSGS )) && echo "print_pages_from_url_list.pl - corpus size is lines, words: $(wc -l -w < ${C1} 2>/dev/null)."

    # first corpus' frequencies
    grep -v "CURRENT URL" $C1 | basic_tokenizer.pl -aei - | sort | uniq -c | gawk '(length($2)>2)&&($1>2){print $2,$1}' > $F
    (( INFOMSGS )) && echo "basic_tokenizer.pl - extracted $(wc -l < ${F} 2>/dev/null) valid tokens."
}

function secondpass {
(( INFOMSGS)) && echo "# using first-pass corpus to gather more specific URLs"

    # add1_smoothing.pl will die if the output file exists
    # (unless some special name is used...) - just rm it.
    rm -f ${SFREQ}
    # remember the output (because we need it for later calculations)
    REF=$( \
        add1_smoothing.pl -t $CFREQ $F   2>&1 |\
        tail -n2 |\
        head -n1 \
        )

    # final word list
    TAR=$(wc -w <   $C1)

    paste $F $SFREQ |\
        awk '{print $1,$2,$4}' |\
        log_odds_ratio.pl $TAR $REF - |\
        sort -nrk2   > $WR

    # get top words
    TWR=$BP/twords

    head -n100 $WR |\
        # grep -v -i 'blog' |\
        awk '{print $1;}'   > $TWR

    # 2nd tuples
    TUP=$BP/tup
    build_random_tuples.pl -l90 -n2 $TWR   > $TUP
    (( INFOMSGS )) && echo "build_random_tuples.pl - got $(wc -l < ${TUP} 2>/dev/null) tuples."

    # final (uncleand) url list
    collect_urls_from_yahoo.pl -l ${QLANG} -r ${CRIGHT} -c 50 $TUP   > $URLS
    (( INFOMSGS )) && echo "collect_urls_from_yahoo.pl - got $(wc -l < ${URLS} 2>/dev/null) URLs."

    # final cleaned url list
    grep -v QUERY $URLS |\
        sort -u -t / -k 2,3   > $URLS.clean
    (( INFOMSGS )) && echo "> the final (cleaned) list contains $(wc -l < ${URLS}.clean 2>/dev/null) URLs."
}

(( FIRSTPASS )) && firstpass
(( FIRSTNHALFPASS )) && firstnhalfpass
secondpass

