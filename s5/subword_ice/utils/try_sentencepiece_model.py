import sentencepiece as spm
import sys

"""
  This script loads a unigram model trained using the SentencePiece subword 
  segmentation library, and segments a corpus file into subwords using the model.
  The output is the segmented file line by line, with each sentence as a list.
  Requires SentencePiece to be installed ($ pip install sentencepiece).
"""

if len(sys.argv) != 3:
  print("Please supply two command line arguments:")
  print("1. a corpus file, one sentence per line.")
  print("2. a trained SentencePiece model file (.model)")
  exit()

with open(sys.argv[1], 'r') as text_file:
  training_text = text_file.readlines()

sp = spm.SentencePieceProcessor(model_file=sys.argv[2])

vocabs = [sp.id_to_piece(id) for id in range(sp.get_piece_size())]
bpe_tokens = sorted(vocabs, key=lambda x: len(x), reverse=True)
print(len(bpe_tokens))

for line in training_text:
  print(sp.encode(line, out_type=str))
