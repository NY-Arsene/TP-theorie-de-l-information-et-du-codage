%% partie2_4.m — Sources avec mémoire et compresseurs réels (questions 8 et 9)
clear; close all; clc;
Parametres;

%% Texte (mêmes réglages que partie2_2.m)
fichierTexte = 'The_Project_Gutenberg_eBook_of_The.txt';     % <-- mettre le même fichier que dans partie2_2.m
texte = lire_texte(fichierTexte);

% Chemin de 7-Zip (bzip2 et 7z). Si 7-Zip n'est pas installé, ces colonnes
% restent vides : on peut alors compresser à la main avec l'interface de
% 7-Zip et reporter les tailles dans le compte rendu.
exe7z = 'C:\Program Files\7-Zip\7z.exe';

dossier = 'compression';
if ~isfolder(dossier), mkdir(dossier); end

%% Q8 : comparaison sur le texte complet puis sur les 5 000 premiers caractères
if numel(texte) < 1e5
    error(['Le texte ne fait que %d caractères : mets ton roman à la ligne 7 ' ...
           '(le même fichier que dans partie2_2.m).'], numel(texte));
end
S(1) = analyse(texte,          'complet', dossier, exe7z);
S(2) = analyse(texte(1:5000),  'debut5000', dossier, exe7z);

noms = {'Code fixe', 'H0 (ordre 0)', 'Huffman', 'Huffman + table', ...
        'H(X1X2)/2', 'gzip', 'bzip2', '7z (LZMA)'};
champs = {'nFixe', 'H0', 'Lhuff', 'LhuffTable', 'H2', 'gz', 'bz2', 'sz7'};

fprintf('\n=== Q8 : bits par caractère ===\n');
fprintf('%-18s %14s %14s\n', 'Méthode', sprintf('N = %d', S(1).N), sprintf('N = %d', S(2).N));
for i = 1:numel(noms)
    fprintf('%-18s %14.4f %14.4f\n', noms{i}, S(1).(champs{i}), S(2).(champs{i}));
end
fprintf('\nEntropie conditionnelle H(X2|X1) = H(X1X2) - H(X1) : %.4f (complet), %.4f (5 000 car.)\n', ...
        2*S(1).H2 - S(1).H0, 2*S(2).H2 - S(2).H0);
fprintf('Nombre de paires distinctes observées : %d (complet), %d (5 000 car.)\n', ...
        S(1).nPaires, S(2).nPaires);

% Graphique comparatif
Y = zeros(numel(champs), 2);
for i = 1:numel(champs)
    Y(i, :) = [S(1).(champs{i}), S(2).(champs{i})];
end
figure('Name', 'Comparaison des codages');
bar(Y);
set(gca, 'XTick', 1:numel(noms), 'XTickLabel', noms, 'XTickLabelRotation', 30);
ylabel('Bits par caractère');
grid on;
legend(sprintf('Texte complet (%d car.)', S(1).N), sprintf('%d premiers car.', S(2).N), ...
       'Location', 'northeast');
title('Codes, entropies et compresseurs réels');

%% Q9 : propriétés des bits en sortie du codeur de Huffman
[~, p, ~, idx] = entropie_empirique(texte);
codes = huffman_code(p);
bH = double(huffman_coder(idx, codes));

% Bits du texte "brut" : octets UTF-8 réels du texte (8 bits par octet)
octets = unicode2native(texte, 'UTF-8');
bB = double(reshape((dec2bin(octets, 8) == '1').', 1, []));
nbBrut = 8;

fprintf('\n=== Q9 : bits produits ===\n');
fprintf('%-34s %15s %18s %18s\n', '', 'Proportion de 1', 'H(paires)/2 (bit)', 'H(octets)/8 (bit)');
fprintf('%-34s %15.4f %18.4f %18.4f\n', 'Sortie du codeur de Huffman', ...
        mean(bH), entropie_paires_bits(bH), entropie_blocs_bits(bH, 8));
fprintf('%-34s %15.4f %18.4f %18.4f\n', sprintf('Texte brut (UTF-8, %d bits/octet)', nbBrut), ...
        mean(bB), entropie_paires_bits(bB), entropie_blocs_bits(bB, 8));

% Fréquence des 4 paires de bits en sortie de Huffman
v  = 2*bH(1:2:end-1) + bH(2:2:end);
fp = accumarray(v(:) + 1, 1, [4 1]).' / numel(v);
vB = 2*bB(1:2:end-1) + bB(2:2:end);
fB = accumarray(vB(:) + 1, 1, [4 1]).' / numel(vB);
figure('Name', 'Paires de bits');
bar([fp; fB].');
set(gca, 'XTickLabel', {'00', '01', '10', '11'});
yline(0.25, 'k--', 'équiprobable');
grid on; xlabel('Paire de bits'); ylabel('Fréquence');
legend('Sortie Huffman', 'Texte brut', 'Location', 'northeast');
title('Répartition des paires de bits');

%% ------------------------------------------------------------------------
function S = analyse(texte, nom, dossier, exe7z)
% Calcule les différentes mesures (en bits par caractère) pour un texte.
    S.N = numel(texte);
    [S.H0, p, alphabet, idx] = entropie_empirique(texte);
    M = numel(alphabet);
    S.nFixe = ceil(log2(M));

    % Huffman (seul, puis en comptant la table canonique)
    codes = huffman_code(p);
    len   = cellfun(@numel, codes);
    S.Lhuff = sum(p .* len);
    T_can = M * (16 + ceil(log2(max(len) + 1)));
    S.LhuffTable = S.Lhuff + T_can / S.N;

    % Entropie des paires de caractères consécutifs (paires chevauchantes)
    paires = (idx(1:end-1) - 1) * M + idx(2:end);
    [Hp, pp] = entropie_empirique(paires);
    S.H2 = Hp / 2;
    S.nPaires = numel(pp);

    % Compresseurs : on écrit le texte nettoyé en UTF-8 puis on compresse
    f = fullfile(dossier, ['texte_' nom '.txt']);
    fid = fopen(f, 'w', 'n', 'UTF-8');
    fwrite(fid, texte, 'char');
    fclose(fid);

    gzip(f);
    d = dir([f '.gz']);
    S.gz = 8 * d.bytes / S.N;

    S.bz2 = NaN;  S.sz7 = NaN;
    if isfile(exe7z)
        S.bz2 = compresse7z(exe7z, f, 'bzip2', 'bz2', S.N);
        S.sz7 = compresse7z(exe7z, f, '7z',    '7z',  S.N);
    end
end

function bpc = compresse7z(exe7z, f, type, ext, N)
% Compresse f avec 7-Zip (niveau maximal) et renvoie les bits par caractère.
    sortie = [f '.' ext];
    if isfile(sortie), delete(sortie); end
    cmd = sprintf('"%s" a -t%s -mx=9 %s %s', exe7z, type, sortie, f);
    [st, ~] = system(cmd);
    if st == 0 && isfile(sortie)
        d = dir(sortie);
        bpc = 8 * d.bytes / N;
    else
        bpc = NaN;
    end
end

function H = entropie_blocs_bits(b, k)
% Entropie par bit estimée sur des blocs disjoints et alignés de k bits.
    nb = floor(numel(b)/k);
    B  = reshape(b(1:nb*k), k, nb);
    v  = (2.^(k-1:-1:0)) * B;              % valeur entière de chaque bloc
    H  = entropie_empirique(v) / k;
end

function H = entropie_paires_bits(b)
% Entropie par bit estimée sur des paires de bits disjointes.
    v = 2*b(1:2:end-1) + b(2:2:end);
    H = entropie_empirique(v) / 2;
end