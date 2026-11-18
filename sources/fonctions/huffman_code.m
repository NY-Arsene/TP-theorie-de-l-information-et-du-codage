function codes = huffman_code(p)
%HUFFMAN_CODE  Construit un code de Huffman binaire.
%   codes = huffman_code(p)
%     p     : probabilités des symboles (vecteur)
%     codes : tableau de cellules ; codes{i} est le mot de code (chaîne de
%             '0' et '1') du symbole i.
%
%   Principe : on fusionne de proche en proche les deux "nœuds" les moins
%   probables. Chaque nœud est représenté par la liste des symboles qu'il
%   contient (tableau de cellules) ; lors d'une fusion, on ajoute '0' en
%   tête des mots des symboles du premier nœud et '1' en tête de ceux du
%   second. On remonte ainsi l'arbre des feuilles vers la racine.

    p = p(:).';
    n = numel(p);
    codes = repmat({''}, 1, n);

    if n == 1                       % cas dégénéré : un seul symbole
        codes{1} = '0';
        return;
    end

    probs   = p;                    % probabilités des nœuds courants
    groupes = num2cell(1:n);        % symboles contenus dans chaque nœud

    while numel(probs) > 1
        [probs, ordre] = sort(probs);          % les 2 plus petits en tête
        groupes = groupes(ordre);

        for s = groupes{1}, codes{s} = ['0' codes{s}]; end
        for s = groupes{2}, codes{s} = ['1' codes{s}]; end

        % fusion des deux nœuds
        probs   = [probs(1) + probs(2), probs(3:end)];
        groupes = [{[groupes{1} groupes{2}]}, groupes(3:end)];
    end
end