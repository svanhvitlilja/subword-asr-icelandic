import sys

"""
    Given a tokenized file where the tokens has been split into subwords using the @@ delimiter,
    this script returns a sorted list of individual subwords and a grapheme-based "transcription"

    Example output:
        þýsk@@ þ ý s k
        þýði þ ý ð i
        þýði@@ þ ý ð i
        þýðing þ ý ð i n g
        þýðing@@ þ ý ð i n g
"""

if len(sys.argv) != 2:
  print("Please supply a tokenized subword-segmented lexicon file.")
  exit()

with open(sys.argv[1], "r") as text_file:
    lexicon = text_file.readlines()

subword_list = []
for line in lexicon:
    line = line.split()
    for item in line:
        subword_list.append(item)

lexicon_set = set(subword_list)


for lex in sorted(lexicon_set):
    split_token = " ".join(lex.strip()).replace(' @ @', '')
    line = lex.strip() + " " + split_token
    print(line)