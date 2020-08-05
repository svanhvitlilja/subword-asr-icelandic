import sentencepiece as spm
import sys

"""
  This script trains a unigram model using the SentencePiece subword 
  segmentation library, given a training data file (one sentence per line).
  Requires SentencePiece to be installed ($ pip install sentencepiece).
"""

if len(sys.argv) != 2:
  print("Please supply a corpus file for training SentencePiece, one sentence per line.")
  exit()

spm.SentencePieceTrainer.train(input=sys.argv[1], model_prefix='sentencepiece-unigram_8000', vocab_size=8000)
