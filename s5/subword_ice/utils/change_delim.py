import sentencepiece as spm
import sys

def is_new_word(token):
    if token[0] == "▁":
        return True

def is_only_underscore(token):
    if token == "▁":
        return True

def change_delim_in_list(test_list): 
    """
        Changes from a prefixed delimiter to a postfix delimiter
        parameter = ['▁Það', '▁er', '▁sós', 'a', '▁á', '▁ullar', sokku', 'num', '▁mín', 'um']
        returns = ['Það', 'er', 'sós@@', 'a', 'á', 'ullar@@', 'sokku@@', 'num', 'mín@@', 'um']
    """
    new_separator = "@@"
    sentence = []
    for word in test_list:
        n = 1
        # boundary check for list
        if (test_list.index(word)) <= len(test_list):
            if is_new_word(word):
                if test_list.index(word) + 1 < len(test_list):
                    next_word = test_list[test_list.index(word) + 1]
                    # if whole word then remove underscore
                    if is_new_word(next_word):
                        whole_word = word[1:]
                        sentence.append(whole_word)
                    # if subword
                    if not is_new_word(next_word):
                        # removing underscore and adding new separator
                        subword_prefix = word[1:] + new_separator
                        sentence.append(subword_prefix)
                        subword_list = []
                        while not is_new_word(next_word):
                            #collect all following subwords into list:
                            n += 1
                            subword_list.append(next_word)
                            if test_list.index(word) + n < len(test_list): 
                                next_word = test_list[test_list.index(word) + n]
                            else:
                                break
                        for subword in subword_list[:-1]:
                            sentence.append(subword + new_separator)
                        sentence.append(subword_list[-1])
                # last item in list (always remove underscore or leave as is)
                else:
                    if is_new_word(word):
                        word = word[1:]
                    sentence.append(word)
    return sentence

if __name__ == "__main__":
    """
        This script changes the delimiter of a subword segmented file from a prefixed delimiter to a postfix delimiter.
    """

    if len(sys.argv) != 3:
        print("Please supply two command line arguments:")
        print("1. a corpus file, one sentence per line.")
        print("2. a trained SentencePiece model file (.model)")
        exit()

    test_list = ["_Þett", "a", "_er", "_mennta", "mála", "ráð", "herra", "_sem", "_tal", "ar"]
    underscore_test = ['▁Það', '▁er', '▁sós', 'a', '▁á', '▁sokku', 'num', '▁mín', 'um', '▁', 'og', '▁súr', '▁gúrk', 'a', '▁á', '▁skó', 'num']

    with open(sys.argv[1], "r") as text_file:
        training_text = text_file.readlines()

    sp = spm.SentencePieceProcessor(model_file=sys.argv[2])
    
    training_text_list = []
    for line in training_text:
        training_text_list.append(sp.encode(line, out_type=str))
        
   
    # In some tokens from the sentencepiece model the underscore and word seem to be separated. 
    # Combining them here into a single token before proceeding.
    new_training_data = []
    for sentence in training_text_list:
        new_sentence = []
        for word in sentence:
            if is_only_underscore(word):
                combo_word = word + sentence[sentence.index(word)+1]
                new_sentence.append(combo_word)

                sentence.remove(word)
            else:
                new_sentence.append(word)
        #print(new_sentence)
        new_training_data.append(new_sentence)

    
    postfix_list = []
    for sent_list in new_training_data:
        postfix_list.append(change_delim_in_list(sent_list))

    for line in postfix_list:
        print(' '.join(line))

