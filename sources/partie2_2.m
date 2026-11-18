%% partie2_2.m — Entropie d'un texte et codage de Huffman (questions 3 à 6)
clear; close all; clc;
Parametres;

%% Choix du texte
fichierTexte = 'The_Project_Gutenberg_eBook_of_The.txt';      % <-- remplacer par ton texte long (>= 100 000 caractères)
titreTexte   = 'The Prince';
auteurTexte  = 'Niccolò Machiavelli';

texte = lire_texte(fichierTexte);
N = numel(texte);

%% Q3 : entropie, alphabet, code de longueur fixe, redondance
[H0, p, alphabet, idx] = entropie_empirique(texte);
M     = numel(alphabet);
nFixe = ceil(log2(M));                 % bits d'un code de longueur fixe

fprintf('=== Q3 : texte "%s" (%s) ===\n', titreTexte, auteurTexte);
fprintf('Nombre de caractères       : %d\n', N);
if N < 1e5
    fprintf('  /!\\ moins de 100 000 caractères : fichier de test uniquement\n');
end
fprintf('Taille de l''alphabet M     : %d symboles\n', M);
fprintf('Entropie (ordre 0) H0      : %.4f bit/caractère\n', H0);
fprintf('Code de longueur fixe      : %d bits/caractère\n', nFixe);
fprintf('Redondance / 8 bits        : 1 - H0/8     = %.1f %%\n', 100*(1 - H0/8));
fprintf('Redondance / code fixe     : 1 - H0/%d     = %.1f %%\n', nFixe, 100*(1 - H0/nFixe));

% Fréquences des caractères les plus fréquents
[ps, ord] = sort(p, 'descend');
nAff   = min(30, M);
labels = arrayfun(@etiquette, alphabet(ord(1:nAff)), 'UniformOutput', false);
figure('Name', 'Fréquences des caractères');
bar(ps(1:nAff));
set(gca, 'XTick', 1:nAff, 'XTickLabel', labels, 'TickLabelInterpreter', 'none');
grid on;
xlabel('Caractère (␣ = espace, \n = retour à la ligne)', 'Interpreter', 'none');
ylabel('Fréquence relative');
title(sprintf('%d caractères les plus fréquents', nAff), 'Interpreter', 'none');

%% Q4 : validation de huffman_code sur un exemple
pTest  = [0.4 0.2 0.2 0.1 0.1];
codesT = huffman_code(pTest);
lenT   = cellfun(@numel, codesT);

fprintf('\n=== Q4 : validation sur p = (0,4 ; 0,2 ; 0,2 ; 0,1 ; 0,1) ===\n');
for i = 1:numel(pTest)
    fprintf('  s%d  p = %.1f  code = %-5s (longueur %d)\n', i, pTest(i), codesT{i}, lenT(i));
end
fprintf('Code préfixe        : %d\n', est_prefixe(codesT));
fprintf('Somme de Kraft      : %.4f (attendu : 1)\n', sum(2.^(-lenT)));
fprintf('Longueur moyenne    : %.4f bits (attendu : 2,2)\n', sum(pTest .* lenT));
if exist('huffmandict', 'file')
    [~, LmoyTbx] = huffmandict(1:numel(pTest), pTest);
    fprintf('huffmandict (Toolbox) : longueur moyenne = %.4f bits\n', LmoyTbx);
end

%% Q5 : code de Huffman du texte, codage, décodage, compression
codes = huffman_code(p);
len   = cellfun(@numel, codes);
Lmoy  = sum(p .* len);

fprintf('\n=== Q5 : code de Huffman du texte ===\n');
fprintf('Code préfixe      : %d   |   Somme de Kraft = %.4f\n', est_prefixe(codes), sum(2.^(-len)));
fprintf('Longueur moyenne  : %.4f bits/caractère\n', Lmoy);
fprintf('Efficacité H0/L   : %.2f %%\n', 100*H0/Lmoy);
fprintf('H0 <= L < H0+1    : %.4f <= %.4f < %.4f  ->  %d\n', ...
        H0, Lmoy, H0+1, (H0 <= Lmoy) && (Lmoy < H0+1));

tic; bits = huffman_coder(idx, codes);     tCod = toc;
tic; idxDec = huffman_decoder(bits, codes); tDec = toc;
texteDec = alphabet(idxDec);
fprintf('Codage : %.2f s, décodage : %.2f s\n', tCod, tDec);
fprintf('Texte restitué sans erreur : %d\n', isequal(texteDec, texte));

Nbits = numel(bits);
fprintf('Taille codée      : %d bits (%.4f bits/caractère)\n', Nbits, Nbits/N);
fprintf('Taux de compression / 8 bits     : %.2f %%  (gain %.1f %%)\n', ...
        100*Nbits/(8*N), 100*(1 - Nbits/(8*N)));
fprintf('Taux de compression / code fixe  : %.2f %%  (gain %.1f %%)\n', ...
        100*Nbits/(nFixe*N), 100*(1 - Nbits/(nFixe*N)));
infoFichier = dir(fichierTexte);
fprintf('Fichier UTF-8 d''origine : %d octets -> taux réel = %.2f %%\n', ...
        infoFichier.bytes, 100*(Nbits/8)/infoFichier.bytes);

%% Q6 : coût de transmission de la table de codage
% Pour chaque symbole on transmet : le caractère (point de code Unicode sur
% 16 bits), la longueur de son mot (sur nbL bits), puis le mot lui-même.
% Avec un code de Huffman CANONIQUE, les longueurs suffisent : le décodeur
% reconstruit les mots à partir des longueurs.
bitsSymb = 16;
nbL      = ceil(log2(max(len) + 1));
T_expl   = sum(bitsSymb + nbL + len);
T_can    = M * (bitsSymb + nbL);

fprintf('\n=== Q6 : coût de la table ===\n');
fprintf('Table explicite  : %d bits  (%.2f %% du message codé)\n', T_expl, 100*T_expl/Nbits);
fprintf('Table canonique  : %d bits  (%.2f %% du message codé)\n', T_can,  100*T_can/Nbits);
Nseuil = ceil(100 * T_expl / Lmoy);        % table < 1 % du message
fprintf('Table < 1 %% du message dès N >= %d caractères environ\n', Nseuil);

%% Sauvegarde pour les parties suivantes
save('resultats_partie2_2.mat', 'texte', 'alphabet', 'p', 'H0', 'codes', 'Lmoy', 'bits', 'nFixe');

%% ------------------------------------------------------------------------
function s = etiquette(c)
% Libellé lisible d'un caractère pour les axes
    switch c
        case ' ',      s = '␣';
        case newline,  s = '\n';
        case char(9),  s = '\t';
        otherwise,     s = c;
    end
end