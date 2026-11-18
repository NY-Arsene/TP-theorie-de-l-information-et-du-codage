function seq = lz78_decoder(couples)
%LZ78_DECODER  Décodage de Lempel-Ziv 78.
%   seq = lz78_decoder(couples)
%     couples : sortie de lz78_coder ((indice, symbole) par ligne)
%     seq     : suite de symboles reconstituée
%
%   Le décodeur reconstruit le même dictionnaire que le codeur : la phrase
%   j est la phrase couples(j,1) prolongée du symbole couples(j,2). Aucune
%   table n'a besoin d'être transmise.

    np     = size(couples, 1);
    parent = couples(:, 1).';
    symb   = couples(:, 2).';

    % Longueur de chaque phrase : len(j) = len(parent(j)) + 1
    len = zeros(1, np);
    for j = 1:np
        if parent(j) == 0
            len(j) = 1;
        else
            len(j) = len(parent(j)) + 1;
        end
    end

    % Reconstruction : chaque phrase est écrite en remontant ses parents
    seq = zeros(1, sum(len));
    pos = 0;
    for j = 1:np
        k = j;
        for q = len(j):-1:1
            seq(pos + q) = symb(k);
            k = parent(k);
        end
        pos = pos + len(j);
    end
end