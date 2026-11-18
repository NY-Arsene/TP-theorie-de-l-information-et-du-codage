%% partie2_5.m — Complément : codage de Lempel-Ziv 78 (questions 10 et 11)
clear; close all; clc;
Parametres;

fichierTexte = 'The_Project_Gutenberg_eBook_of_The.txt';     % <-- mettre le même fichier que dans partie2_2.m

%% Q10 : validation sur l'exemple de l'énoncé
ex = 'ABAABABAABAB';
[alphEx, ~, seqEx] = unique(ex);           % A -> 1, B -> 2
[cEx, nbEx] = lz78_coder(seqEx, numel(alphEx));
fprintf('=== Q10 : exemple %s ===\n', ex);
txt = '';
for j = 1:size(cEx, 1)
    txt = [txt sprintf('(%d,%c) ', cEx(j,1), alphEx(cEx(j,2)))]; %#ok<AGROW>
end
fprintf('Couples obtenus : %s\n', txt);
fprintf('Couples attendus : (0,A) (0,B) (1,A) (2,A) (4,A) (4,B)\n');
decEx = alphEx(lz78_decoder(cEx));
fprintf('Décodage : %s  ->  correct : %d   (%d bits)\n', decEx, isequal(decEx, ex), nbEx);

%% Q11 (a) : texte complet et 5 000 premiers caractères
texte = lire_texte(fichierTexte);
fprintf('\n=== Q11 : texte ===\n');
for Nt = [numel(texte) 5000]
    t = texte(1:Nt);
    [H0, ~, alph, seq] = entropie_empirique(t);
    tic; [c, nb] = lz78_coder(seq, numel(alph)); tc = toc;
    ok = isequal(alph(lz78_decoder(c)), t);
    fprintf('N = %6d : %6d phrases, %.4f bits/car. (H0 = %.4f), décodage ok : %d  [%.1f s]\n', ...
            Nt, size(c, 1), nb/Nt, H0, ok, tc);
end

%% Q11 (b) : source binaire p1_ext, messages de 1e3 à 1e6 bits
Hb  = entropie_binaire(p1_ext);
Ns  = round(10.^(3:0.5:6));
bpb = zeros(size(Ns));
rng(graine);
bAll = source(max(Ns), p1_ext);
fprintf('\n=== Q11 : source binaire p1_ext = %.2f, H = %.4f ===\n', p1_ext, Hb);
for i = 1:numel(Ns)
    [c, nb] = lz78_coder(bAll(1:Ns(i)) + 1, 2);     % symboles 1 et 2
    bpb(i) = nb / Ns(i);
    fprintf('N = %8d : %7d phrases, %.4f bit/bit de source\n', Ns(i), size(c, 1), bpb(i));
end

figure('Name', 'LZ78 source binaire');
semilogx(Ns, bpb, 'o-', 'LineWidth', 1.5); hold on;
yline(Hb, 'k-', 'LineWidth', 1.2);
yline(1, 'k:', 'LineWidth', 1);
grid on;
xlabel('Longueur du message (bits)');
ylabel('Bits codés par bit de source');
title(sprintf('LZ78 sur une source binaire, p_1 = %.2f', p1_ext));
legend('LZ78', sprintf('Entropie H = %.3f', Hb), 'Sans codage (1 bit/bit)', ...
       'Location', 'northeast');