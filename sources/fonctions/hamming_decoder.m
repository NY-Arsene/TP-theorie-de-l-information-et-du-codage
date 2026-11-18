function [m, nCorr] = hamming_decoder(r, H)
%HAMMING_DECODER  Décodage C(7,4) par calcul du syndrome.
%   [m, nCorr] = hamming_decoder(r, H)
%     r     : bits reçus (longueur multiple de 7)
%     H     : matrice de contrôle 3 x 7 (sortie de hamming74)
%     m     : bits d'information décodés (4 par mot)
%     nCorr : nombre de mots dans lesquels un bit a été corrigé
%
%   Pour chaque mot reçu, s = r H' (mod 2).
%   - s = 0 : mot accepté tel quel ;
%   - s ~= 0 : s est égal à une colonne j de H -> on inverse le bit j
%     (hypothèse d'une erreur simple).

    r = double(r(:).');
    if mod(numel(r), 7) ~= 0
        error('hamming_decoder : le nombre de bits doit être un multiple de 7.');
    end
    R = reshape(r, 7, []).';           % un mot reçu par ligne
    S = mod(R * H.', 2);               % syndromes (une ligne par mot)

    % Table syndrome -> position : on code chaque syndrome par un entier
    poids = [4; 2; 1];
    pos   = zeros(8, 1);
    pos(H.' * poids + 1) = 1:7;        % colonne j de H  ->  position j
    p = pos(S * poids + 1);            % position à corriger (0 si s = 0)

    k = find(p > 0);
    lin = sub2ind(size(R), k, p(k));
    R(lin) = 1 - R(lin);               % correction

    m = reshape(R(:, 1:4).', 1, []);
    nCorr = numel(k);
end