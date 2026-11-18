%% partie4_3.m — Performances théoriques du code C(7,4) (questions 7 à 9)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));
[G, H] = hamming74();

EbN0dB = 0:9;
e  = 10.^(EbN0dB / 10);
pu = Q(sqrt(2 * e));                 % TEB sans codage
p  = Q(sqrt(2 * 4/7 * e));           % Q9 : TEB brut d'un bit codé (Ec = 4/7 Eb)

%% Q7 : probabilité qu'un bloc de 4 bits d'information soit juste
Pbloc_nc = (1 - pu).^4;                          % sans codage
Pbloc_c  = (1 - p).^7 + 7 * p .* (1 - p).^6;     % avec codage : 0 ou 1 erreur sur 7

%% Q8 : approximation du TEB après correction
Pb = zeros(size(p));
for j = 2:7
    Pb = Pb + (j/7) * nchoosek(7, j) * p.^j .* (1 - p).^(7 - j);
end

%% Vérification de l'approximation par Monte-Carlo (canal binaire de proba p)
rng(graine);
Pb_mc = zeros(size(p));  nErr = Pb_mc;  nBits = Pb_mc;
for i = 1:numel(p)
    N  = 4 * ceil(min(4e6, max(4e5, 300 / Pb(i))) / 4);
    m  = double(rand(1, N) < 0.5);
    c  = hamming_coder(m, G);
    r  = mod(c + (rand(size(c)) < p(i)), 2);
    mD = hamming_decoder(r, H);
    nErr(i)  = sum(mD ~= m);  nBits(i) = N;
    Pb_mc(i) = nErr(i) / N;
end

fprintf(' Eb/N0 | TEB sans code |  p (bit codé) | P(bloc ok) sans | P(bloc ok) avec | Pb approx  | Pb Monte-Carlo\n');
for i = 1:numel(p)
    fprintf('%4d dB |  %10.3e  |  %10.3e  |   %10.6f    |   %10.6f    | %9.3e  | %9.3e (%d err.)\n', ...
            EbN0dB(i), pu(i), p(i), Pbloc_nc(i), Pbloc_c(i), Pb(i), Pb_mc(i), nErr(i));
end
fprintf('\nRapport Monte-Carlo / approximation : %s\n', mat2str(Pb_mc ./ Pb, 3));

%% Q9 : comparaison trompeuse "à variance de bruit égale"
% Si l'on donnait aux bits codés la même énergie qu'aux bits non codés
% (p = Q(sqrt(2Eb/N0))), on oublierait que 7 bits sont émis pour 4 utiles.
Pb_faux = zeros(size(p));
for j = 2:7
    Pb_faux = Pb_faux + (j/7) * nchoosek(7, j) * pu.^j .* (1 - pu).^(7 - j);
end

xf = linspace(0, 9, 200);  ef = 10.^(xf / 10);
figure('Name', 'Performances théoriques C(7,4)');
semilogy(xf, Q(sqrt(2 * ef)), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0dB, p,  'k:', 'LineWidth', 1.2);
semilogy(EbN0dB, Pb, 'r-', 'LineWidth', 1.5);
semilogy(EbN0dB, Pb_mc, 'ro', 'LineWidth', 1.5);
semilogy(EbN0dB, Pb_faux, 'm--', 'LineWidth', 1.2);
grid on;  ylim([1e-7 1]);
xlabel('E_b/N_0 (dB)');  ylabel('Taux d''erreur binaire');
title('Code de Hamming C(7,4) : performances théoriques');
legend('Sans codage Q(\surd(2E_b/N_0))', 'p : bit codé avant correction', ...
       'Avec codage : approximation P_b', 'Avec codage : Monte-Carlo', ...
       'Comparaison trompeuse (même énergie par bit codé)', 'Location', 'southwest');

save('resultats_partie4_theorie.mat', 'EbN0dB', 'pu', 'p', 'Pb', 'Pb_mc');