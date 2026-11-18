function idx = huffman_decoder(bits, codes)
%HUFFMAN_DECODER  Décodage instantané d'une suite binaire codée par Huffman.
%   idx = huffman_decoder(bits, codes)
%     bits  : suite binaire (logique ou 0/1)
%     codes : mots de code (sortie de huffman_code)
%     idx   : indices des symboles décodés
%
%   1) On reconstruit l'arbre binaire du code : enfant(noeud, 1) pour le
%      bit 0, enfant(noeud, 2) pour le bit 1 ; feuille(noeud) = symbole.
%   2) On parcourt l'arbre depuis la racine bit par bit ; dès qu'on atteint
%      une feuille, on émet le symbole et on revient à la racine.
%      C'est possible car le code est préfixe (décodage instantané).

    % --- 1) Construction de l'arbre ---------------------------------------
    maxNoeuds = sum(cellfun(@numel, codes)) + 1;
    enfant  = zeros(maxNoeuds, 2);
    feuille = zeros(maxNoeuds, 1);
    nb = 1;                                    % nœud 1 = racine
    for s = 1:numel(codes)
        noeud = 1;
        for b = codes{s}
            k = (b == '1') + 1;
            if enfant(noeud, k) == 0
                nb = nb + 1;
                enfant(noeud, k) = nb;
            end
            noeud = enfant(noeud, k);
        end
        feuille(noeud) = s;
    end

    % --- 2) Parcours ------------------------------------------------------
    bits = double(bits(:).');
    idx  = zeros(1, numel(bits));
    m = 0;
    noeud = 1;
    for i = 1:numel(bits)
        noeud = enfant(noeud, bits(i) + 1);
        if feuille(noeud) > 0
            m = m + 1;
            idx(m) = feuille(noeud);
            noeud = 1;
        end
    end
    idx = idx(1:m);
end