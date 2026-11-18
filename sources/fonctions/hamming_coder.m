function c = hamming_coder(m, G)
%HAMMING_CODER  Codage C(7,4) par produit matriciel modulo 2.
%   c = hamming_coder(m, G)
%     m : bits d'information (longueur multiple de 4)
%     G : matrice génératrice 4 x 7 (sortie de hamming74)
%     c : bits codés (vecteur ligne), 7 bits par bloc de 4

    m = double(m(:).');
    if mod(numel(m), 4) ~= 0
        error('hamming_coder : le nombre de bits doit être un multiple de 4.');
    end
    M = reshape(m, 4, []).';           % un mot-message par ligne
    C = mod(M * G, 2);                 % un mot-code par ligne
    c = reshape(C.', 1, []);
end