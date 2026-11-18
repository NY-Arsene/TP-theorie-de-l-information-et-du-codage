function bits = huffman_coder(idx, codes)
%HUFFMAN_CODER  Codage de Huffman d'une suite de symboles.
%   bits = huffman_coder(idx, codes)
%     idx   : indices des symboles à coder (dans l'alphabet)
%     codes : mots de code (sortie de huffman_code)
%     bits  : suite binaire (vecteur ligne logique)
%   On concatène simplement les mots de code : le code étant préfixe,
%   aucun séparateur n'est nécessaire.

    c    = codes(idx);
    bits = [c{:}] == '1';
end