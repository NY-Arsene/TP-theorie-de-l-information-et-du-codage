%% partie2_3.m — Extension de la source binaire (question 7)
% On code des blocs de k bits (k-ième extension de la source) avec un code
% de Huffman, pour une source très déséquilibrée P(1) = p1_ext.
clear; close all; clc;
Parametres;

kmax = 10;
N    = 1e5;                       % bits de source pour la vérification
H    = entropie_binaire(p1_ext);  % entropie de la source (bit/bit de source)

rng(graine);
b = source(N, p1_ext);            % 1e5 bits de source

Lk_th  = zeros(1, kmax);          % longueur moyenne théorique par bit de source
Lk_sim = zeros(1, kmax);          % longueur mesurée en codant les 1e5 bits
tTab   = zeros(1, kmax);          % temps de construction du code

fprintf('Source : p1_ext = %.2f   H = %.4f bit/bit de source\n\n', p1_ext, H);
fprintf('  k   taille table   Lk/k (théo)   Lk/k (simu)   H + 1/k    efficacité\n');

for k = 1:kmax
    % --- probabilités des 2^k blocs : p^w (1-p)^(k-w), w = nombre de 1 ---
    v  = 0:2^k-1;                                 % valeur entière du bloc
    w  = sum(dec2bin(v, k) == '1', 2).';          % poids de Hamming de chaque bloc
    pk = p1_ext.^w .* (1-p1_ext).^(k-w);

    tic;
    codes = huffman_code(pk);
    tTab(k) = toc;
    len = cellfun(@numel, codes);
    Lk_th(k) = sum(pk .* len) / k;

    % --- vérification : codage de N bits (tronqué à un multiple de k) ---
    Nk  = floor(N/k) * k;
    B   = reshape(b(1:Nk), k, []);                % un bloc par colonne, MSB en tête
    idx = (2.^(k-1:-1:0)) * B + 1;                % indice du bloc dans 1..2^k
    bits = huffman_coder(idx, codes);
    Lk_sim(k) = numel(bits) / Nk;

    % décodage vérifié pour le plus grand k
    if k == kmax
        idxDec = huffman_decoder(bits, codes);
        okDec  = isequal(idxDec, idx);
    end

    fprintf('%3d   %10d   %11.4f   %11.4f   %8.4f   %8.2f %%\n', ...
            k, 2^k, Lk_th(k), Lk_sim(k), H + 1/k, 100*H/Lk_th(k));
end
fprintf('\nDécodage sans erreur pour k = %d : %d\n', kmax, okDec);
fprintf('Vérification H <= Lk/k < H + 1/k pour tout k : %d\n', ...
        all(Lk_th >= H - 1e-12 & Lk_th < H + 1./(1:kmax)));

%% Tracé
k = 1:kmax;
figure('Name', 'Extension de la source');
plot(k, Lk_th, 'o-', 'LineWidth', 1.5); hold on;
plot(k, Lk_sim, 'x', 'MarkerSize', 9, 'LineWidth', 1.5);
plot(k, H + 1./k, '--', 'LineWidth', 1.2);
yline(H, 'k-', 'LineWidth', 1.2);
grid on;
xlabel('Taille k des blocs (bits)');
ylabel('Longueur moyenne par bit de source (bit)');
title(sprintf('Huffman sur blocs de k bits, p_1 = %.2f', p1_ext));
legend('L_k/k théorique', 'L_k/k mesurée (10^5 bits)', 'Borne H + 1/k', ...
       sprintf('Entropie H = %.3f', H), 'Location', 'northeast');
ylim([0 1.1]);

%% Prix à payer : taille de la table et temps de construction
figure('Name', 'Coût de l''extension');
yyaxis left;  semilogy(k, 2.^k, 'o-', 'LineWidth', 1.5);
ylabel('Nombre de mots de code 2^k');
yyaxis right; plot(k, 1000*tTab, 's-', 'LineWidth', 1.5);
ylabel('Temps de construction du code (ms)');
grid on; xlabel('Taille k des blocs (bits)');
title('Coût de l''extension de la source');