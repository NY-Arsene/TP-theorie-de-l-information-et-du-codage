function D = trouver_retard(tx, rx, Dmax)
%TROUVER_RETARD  Retard (en bits) entre les bits émis et les bits reçus,
%   déterminé sur une simulation SANS bruit : plus petit D tel que
%   rx(k + D) = tx(k) pour tout k (les premiers bits, transitoires, sont ignorés).
    if nargin < 3, Dmax = 10; end
    tx = tx(:);  rx = rx(:);
    for D = 0:Dmax
        if isequal(tx(5:end-D), rx(5+D:end))
            return;
        end
    end
    error('trouver_retard : aucun retard entre 0 et %d bits ne convient.', Dmax);
end