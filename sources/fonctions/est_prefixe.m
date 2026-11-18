function ok = est_prefixe(codes)
%EST_PREFIXE  Vérifie qu'aucun mot de code n'est le préfixe d'un autre.
%   ok = est_prefixe(codes), codes : tableau de cellules de chaînes '0'/'1'.

    ok = true;
    n  = numel(codes);
    for i = 1:n
        for j = 1:n
            if i ~= j && numel(codes{i}) <= numel(codes{j}) && ...
               strncmp(codes{j}, codes{i}, numel(codes{i}))
                ok = false;
                fprintf('  "%s" (symbole %d) est préfixe de "%s" (symbole %d)\n', ...
                        codes{i}, i, codes{j}, j);
                return;
            end
        end
    end
end