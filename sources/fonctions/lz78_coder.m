function [couples, nbits] = lz78_coder(seq, M)
%LZ78_CODER  Codage de Lempel-Ziv 78.
%   [couples, nbits] = lz78_coder(seq, M)
%     seq     : suite de symboles, entiers de 1 à M
%     M       : taille de l'alphabet
%     couples : matrice (nombre de phrases) x 2 ; chaque ligne est
%               (indice de la phrase connue, symbole ajouté), l'indice 0
%               désignant la phrase vide
%     nbits   : nombre total de bits : le i-ème couple coûte
%               ceil(log2(i)) bits pour l'indice + ceil(log2(M)) pour le symbole
%
%   Principe : on lit le message en prolongeant la phrase courante w tant
%   que (w, symbole) est déjà dans le dictionnaire. Dès que ce n'est plus
%   le cas, on émet (w, symbole), on ajoute cette nouvelle phrase au
%   dictionnaire et on repart de la phrase vide.

    seq = double(seq(:).');
    n   = numel(seq);

    % Dictionnaire : clé = w*(M+1) + symbole  ->  indice de la phrase
    dico = containers.Map('KeyType', 'double', 'ValueType', 'double');
    parent = zeros(1, n);              % phrase j = phrase parent(j) + symb(j)
    symb   = zeros(1, n);
    couples = zeros(n, 2);
    np = 0;                            % nombre de phrases émises
    w  = 0;                            % phrase courante (0 = vide)

    for i = 1:n
        s   = seq(i);
        cle = w*(M+1) + s;
        if isKey(dico, cle)
            w = dico(cle);             % on prolonge la phrase
        else
            np = np + 1;
            couples(np, :) = [w s];    % nouvelle phrase émise
            parent(np) = w;  symb(np) = s;
            dico(cle) = np;
            w = 0;
        end
    end

    % Fin du message au milieu d'une phrase déjà connue : on la réémet
    if w > 0
        np = np + 1;
        couples(np, :) = [parent(w) symb(w)];
    end
    couples = couples(1:np, :);

    % Coût en bits
    i = 1:np;
    nbits = sum(ceil(log2(i))) + np * ceil(log2(M));
end