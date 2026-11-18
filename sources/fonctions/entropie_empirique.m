function [H, p, alphabet, idx] = entropie_empirique(seq)
%ENTROPIE_EMPIRIQUE  Entropie empirique (ordre 0) d'une séquence de symboles.
%   [H, p, alphabet, idx] = entropie_empirique(seq)
%     seq      : vecteur de symboles (caractères ou nombres)
%     H        : entropie en bits/symbole, H = -sum p_i log2 p_i
%     p        : fréquences relatives des symboles (vecteur ligne)
%     alphabet : symboles distincts, dans le même ordre que p
%     idx      : indice de chaque symbole de seq dans l'alphabet
%   Les probabilités sont estimées par les fréquences d'apparition
%   (modèle de source sans mémoire).

    [alphabet, ~, idx] = unique(seq);
    idx    = idx(:).';
    counts = accumarray(idx(:), 1).';
    p      = counts / numel(seq);
    H      = -sum(p .* log2(p));          % aucun p nul par construction
end