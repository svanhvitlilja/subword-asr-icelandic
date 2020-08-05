#!/bin/bash -e

# Copyright 2014 QCRI (author: Ahmed Ali)
#           2019 Dongji Gao
# Apache 2.0

# This is an example script for subword implementation
# Modified in 2020 for Icelandic by Svanhvít Lilja Ingólfsdóttir

num_jobs=120
num_decode_jobs=40
decode_gmm=true
stage=0
overwrite=false
num_merges=1000

. cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.
./path.sh
./utils/parse_options.sh  # e.g. this parses the above options
                            # if supplied.

# Handling user argument
if [[ $* == 'bpe' || $* == 'kvistur' || $* == 'unigram' ]] ; then 
  echo "Selected subword method is:" $*
  subword_method=$*
elif [[ $# -eq 0 ]] ; then
  subword_method='bpe'
  echo 'Applying BPE by default'
  echo 'Available subword methods to pass as a command line argument:'
  echo 'bpe, kvistur, unigram'
else
  echo 'Please specify a subword method as a command line argument'
  echo 'Available methods:'
  echo 'bpe, kvistur, unigram'
  exit 1
fi

if [ $stage -le 0 ]; then

  echo "$0: preparing data..."

  # Update this with the path to the Málrómur data and info file
  local/malromur_prep_data.sh ~/wav ~/wav/wav_info.txt data/all
  utils/subset_data_dir_tr_cv.sh --cv-utt-percent 10 data/{all,training_data,test_data}
  
  training_data=data/training_data
  test_data=data/test_data

  echo "$0: Preparing lexicon and LM..." 
  local/prepare_dict_subword.sh ./subword_ice/$subword_method/subword_lexicon.txt
  utils/subword/prepare_lang_subword.sh data/local/dict "<UNK>" data/local/lang data/lang

  # fetching subword training/test text
  cat ./subword_ice/$subword_method/train_text > data/training_data/text
  cat ./subword_ice/$subword_method/test_text > data/test_data/text 
  local/prepare_lm_subword.sh

  utils/format_lm.sh data/lang data/local/lm/lm.gz \
                     data/local/dict/lexicon.txt data/lang_test
fi

mfccdir=mfcc
if [ $stage -le 1 ]; then
  echo "$0: Preparing the test and train feature files..."
  for x in training_data test_data ; do
    steps/make_mfcc.sh --cmd "$train_cmd" --nj $num_jobs \
      data/$x exp/make_mfcc/$x $mfccdir
    utils/fix_data_dir.sh data/$x # some files fail to get mfcc for many reasons
    steps/compute_cmvn_stats.sh data/$x exp/make_mfcc/$x $mfccdir
  done
fi

if [ $stage -le 2 ]; then
  echo "$0: creating sub-set and training monophone system"
  utils/subset_data_dir.sh data/training_data 10000 data/train.10K || exit 1;

  steps/train_mono.sh --nj 40 --cmd "$train_cmd" \
    data/train.10K data/lang exp/mono_subword || exit 1;
fi

if [ $stage -le 3 ]; then
  echo "$0: Aligning data using monophone system"
  steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
    data/training_data data/lang exp/mono_subword exp/mono_ali_subword || exit 1;

  echo "$0: training triphone system with delta features"
  steps/train_deltas.sh --cmd "$train_cmd" \
    2500 30000 data/training_data data/lang exp/mono_ali_subword exp/tri1_subword || exit 1;
fi

if [ $stage -le 4 ] && $decode_gmm; then
  utils/mkgraph.sh data/lang_test exp/tri1_subword exp/tri1_subword/graph
  steps/decode.sh  --nj $num_decode_jobs --cmd "$decode_cmd" \
    exp/tri1_subword/graph data/test_data exp/tri1_subword/decode
fi

if [ $stage -le 5 ]; then
  echo "$0: Aligning data and retraining and realigning with lda_mllt"
  steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
    data/training_data data/lang exp/tri1_subword exp/tri1_ali_subword || exit 1;

  steps/train_lda_mllt.sh --cmd "$train_cmd" 4000 50000 \
    data/training_data data/lang exp/tri1_ali_subword exp/tri2b_subword || exit 1;
fi

if [ $stage -le 6 ] && $decode_gmm; then
  utils/mkgraph.sh data/lang_test exp/tri2b_subword exp/tri2b_subword/graph
  steps/decode.sh --nj $num_decode_jobs --cmd "$decode_cmd" \
    exp/tri2b_subword/graph data/test_data exp/tri2b_subword/decode
fi

if [ $stage -le 7 ]; then
  echo "$0: Aligning data and retraining and realigning with sat_basis"
  steps/align_si.sh --nj $num_jobs --cmd "$train_cmd" \
    data/training_data data/lang exp/tri2b_subword exp/tri2b_ali_subword || exit 1;

  steps/train_sat_basis.sh --cmd "$train_cmd" \
    5000 100000 data/training_data data/lang exp/tri2b_ali_subword exp/tri3b_subword || exit 1;

  steps/align_fmllr.sh --nj $num_jobs --cmd "$train_cmd" \
    data/training_data data/lang exp/tri3b_subword exp/tri3b_ali_subword || exit 1;
fi

if [ $stage -le 8 ] && $decode_gmm; then
  utils/mkgraph.sh data/lang_test exp/tri3b_subword exp/tri3b_subword/graph
  steps/decode_fmllr.sh --nj $num_decode_jobs --cmd \
    "$decode_cmd" exp/tri3b_subword/graph data/test_data exp/tri3b_subword/decode
fi

if [ $stage -le 9 ]; then
  echo "$0: Training a regular chain model using the e2e alignments..."
  local/chain/run_tdnn.sh # --gmm tri3b_subword
fi

echo "$0: training succeed"
exit 0

