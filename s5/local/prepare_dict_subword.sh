#!/usr/bin/env bash

# Copyright 2017 QCRI (author: Ahmed Ali)
#           2019 Dongji Gao
# Apache 2.0
# This script prepares the subword dictionary.


subword_lexicon_file=$1
 

set -e
dir=data/local/dict
num_merges=1000
stage=0
. ./cmd.sh
. ./path.sh
. ./utils/parse_options.sh || exit 1;
mkdir -p $dir data/local/lexicon_data

if [ $stage -le 0 ]; then
  echo "$0: Fetching text for lexicon... $(date)."
  cat $subword_lexicon_file | awk '{print $1}' >  data/local/lexicon_data/grapheme_lexicon
  cat data/training_data/text | cut -d ' ' -f 2- | tr -s " " "\n" | sort -u >> data/local/lexicon_data/grapheme_lexicon

fi

if [ $stage -le 0 ]; then
  echo "$0: processing lexicon text and creating lexicon... $(date)."
  python3 local/prepare_lexicon.py
fi

cut -d' ' -f2- $dir/lexicon.txt | sed 's/SIL//g' | tr ' ' '\n' | sort -u | sed '/^$/d' >$dir/nonsilence_phones.txt || exit 1;
# modified from original:
# cut -d' ' -f2- $dir/lexicon.txt | tr ' ' '\n' | LC_ALL=C sort -u | sed '/^$/d' > $dir/nonsilence_phones.txt

echo UNK >> $dir/nonsilence_phones.txt

echo SIL > $dir/silence_phones.txt

echo SIL >$dir/optional_silence.txt

echo -n "" >$dir/extra_questions.txt

glossaries="<UNK> <sil>"

if [ $stage -le 0 ]; then

  mv $dir/lexicon.txt $dir/lexicon_word.txt

  cut -d ' ' -f1 $dir/lexicon_word.txt > $dir/words.txt

  cat $subword_lexicon_file | sort -u > $dir/lexicon.txt 
fi

#removing stray 'q' in kvistur data?
sed -i '/q$/d' $dir/lexicon.txt

sed -i'.bak' '1i<UNK> UNK' $dir/lexicon.txt

echo '<sil> SIL' >> $dir/lexicon.txt

sed -i '/^ *$/d' $dir/lexicon.txt

echo "$0: Dictionary preparation succeeded"
