%% partie4_1.m — Code de Hamming C(7,4) : calcul théorique et fonctions de référence
% Questions 1 à 3 de la partie 4.
clear; close all; clc;

%% Q1 : restes x^3 m(x) mod g(x) et matrices G, H
g = [1 1 0 1];                                   % g(x) = 1 + x + x^3
fprintf('=== Q1 : g(x) = 1 + x + x^3 ===\n');
for k = 0:3
    a = zeros(1, 7);  a(k + 4) = 1;
    r = reste_poly(a, g);
    fprintf('m(x) = x^%d : x^%d mod g(x) = (r0 r1 r2) = (%d %d %d)\n', k, k + 3, r);
end
[G, H, P] = hamming74();
fprintf('\nG = [I4 | P] =\n');  disp(G);
fprintf('H = [P'' | I3] =\n');  disp(H);
fprintf('G H'' mod 2 =\n');     disp(mod(G * H.', 2));
fprintf('G H'' = 0 : %d\n', all(all(mod(G * H.', 2) == 0)));

% Comparaison avec la Communications Toolbox (forme [P | I4], parité en tête)
if exist('cyclgen', 'file')
    [~, Gtb] = cyclgen(7, g, 'system');
    fprintf('cyclgen (Toolbox), colonnes remises dans l''ordre [message | parité] : identique = %d\n', ...
            isequal(Gtb(:, [4:7 1:3]), G));
end

%% Q2 : colonnes de H, distance minimale
fprintf('\n=== Q2 ===\n');
cols  = H.' * [4; 2; 1];                         % chaque colonne vue comme un entier
fprintf('Colonnes de H (en entiers) : %s\n', mat2str(cols.'));
fprintf('Colonnes non nulles : %d   |   distinctes : %d\n', ...
        all(cols > 0), numel(unique(cols)) == 7);

msgs   = dec2bin(0:15, 4) - '0';                 % les 16 messages
codes  = mod(msgs * G, 2);
poids  = sum(codes, 2);
dmin   = min(poids(poids > 0));
fprintf('Distribution des poids des 16 mots-codes :\n');
for w = unique(poids).'
    fprintf('   poids %d : %d mot(s)\n', w, sum(poids == w));
end
fprintf('Distance minimale dmin = %d\n', dmin);
fprintf('Capacité de détection  : %d erreurs\n', dmin - 1);
fprintf('Capacité de correction : %d erreur\n', floor((dmin - 1) / 2));
fprintf('Code parfait : 2^(n-k) = %d = 1 + n = %d  ->  %d\n', 2^3, 1 + 7, 2^3 == 1 + 7);

%% Q3 : validation du codeur et du décodeur
fprintf('\n=== Q3 : validation ===\n');
m  = reshape(msgs.', 1, []);                     % les 16 messages bout à bout
c  = hamming_coder(m, G);
[mDec, nC] = hamming_decoder(c, H);
fprintf('Sans erreur        : 16 messages restitués = %d, corrections = %d\n', isequal(mDec, m), nC);

okSimple = true;
for j = 1:7
    E = zeros(16, 7);  E(:, j) = 1;              % une erreur en position j dans chaque mot
    rj = mod(c + reshape(E.', 1, []), 2);
    [mDec, nC] = hamming_decoder(rj, H);
    fprintf('Erreur en position %d : restitués = %d, corrections = %d/16\n', j, isequal(mDec, m), nC);
    okSimple = okSimple && isequal(mDec, m);
end
fprintf('=> Toutes les erreurs simples sont corrigées : %d\n', okSimple);

% Erreurs doubles : le décodeur se trompe toujours (il "corrige" un 3e bit)
paires = nchoosek(1:7, 2);
nMotsFaux = 0;
for q = 1:size(paires, 1)
    E = zeros(16, 7);  E(:, paires(q, :)) = 1;
    rq = mod(c + reshape(E.', 1, []), 2);
    mDec = hamming_decoder(rq, H);
    nMotsFaux = nMotsFaux + sum(any(reshape(mDec ~= m, 4, []), 1));
end
fprintf('Erreurs doubles : %d mots faux sur %d cas testés\n', nMotsFaux, 16 * size(paires, 1));