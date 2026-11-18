%% partie3_2.m — Canal à bruit uniforme, 1 échantillon par bit (questions 4 à 6)
clear; close all; clc;
Parametres;
Nsim = 1e5;
Q0   = @(v) min(max(v, 0), 1);                     % écrêtage dans [0, 1]

%% Q4 : densités conditionnelles et seuil optimal
rr = linspace(-A-a-0.5, A+a+0.5, 2000);
f0 = (abs(rr + A) <= a) / (2*a);                   % f(r | 0) : uniforme sur [-A-a, -A+a]
f1 = (abs(rr - A) <= a) / (2*a);                   % f(r | 1) : uniforme sur [ A-a,  A+a]

if a <= A
    s_opt = 0;  txtSeuil = 'a <= A : aucun recouvrement, tout seuil de [a-A, A-a] est optimal';
elseif p1 > p0
    s_opt = A - a;  txtSeuil = 'p1 > p0 : on décide 1 sur toute la zone de recouvrement';
elseif p0 > p1
    s_opt = a - A;  txtSeuil = 'p0 > p1 : on décide 0 sur toute la zone de recouvrement';
else
    s_opt = 0;  txtSeuil = 'p0 = p1 : tout seuil de la zone de recouvrement est optimal';
end
fprintf('=== Q4 : bruit uniforme sur [-a, a], a = %.2f, A = %.2f ===\n', a, A);
if a > A
    fprintf('Zone de recouvrement : [A-a, a-A] = [%.2f ; %.2f]\n', A-a, a-A);
end
fprintf('%s\nSeuil optimal s* = %.4f\n', txtSeuil, s_opt);

%% Q5 : probabilité d'erreur théorique en fonction du seuil
% Erreur sur un 0 : r > s avec r uniforme sur [-A-a, -A+a]
% Erreur sur un 1 : r < s avec r uniforme sur [ A-a,  A+a]
Pe_unif = @(s) p0 * Q0((a - A - s) / (2*a)) + p1 * Q0((s - A + a) / (2*a));
fprintf('\n=== Q5 ===\nPe(s*) = %.4f   (formule p_min * (1 - A/a) = %.4f)\n', ...
        Pe_unif(s_opt), min(p0, p1) * max(0, 1 - A/a));
fprintf('Pe(0)  = %.4f\n', Pe_unif(0));

%% Q6 : TEB simulé pour une série de seuils
mdl = construire_modele_canal('unif');
sv  = unique([linspace(-(A+a), A+a, 21), s_opt, 0]);
teb = zeros(size(sv));  ic = teb;
for i = 1:numel(sv)
    s   = sv(i);                                   % variable lue par le bloc Seuil
    out = sim(mdl);
    e   = out.tx(:) ~= out.rx(:);
    teb(i) = mean(e);
    ic(i)  = 1.96 * sqrt(teb(i)*(1-teb(i)) / numel(e));
    if s == s_opt, rOpt = out.r(:); txOpt = out.tx(:); end
end
[tebMin, iMin] = min(teb);
fprintf('\n=== Q6 : simulation (%d bits par seuil) ===\n', Nsim);
fprintf('TEB simulé en s* = %.4f  (théorie %.4f)\n', teb(sv == s_opt), Pe_unif(s_opt));
fprintf('Minimum simulé : TEB = %.4f pour s = %.4f\n', tebMin, sv(iMin));

% Figure 1 : densités théoriques + histogrammes simulés
figure('Name', 'Densités - bruit uniforme');
subplot(2,1,1);
plot(rr, f0, 'b', rr, f1, 'r', 'LineWidth', 1.5); hold on;
histogram(rOpt(txOpt == 0), 60, 'Normalization', 'pdf', 'FaceColor', 'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
histogram(rOpt(txOpt == 1), 60, 'Normalization', 'pdf', 'FaceColor', 'r', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
grid on; ylabel('Densité');
title('Densités conditionnelles f(r|0) et f(r|1)');
legend('f(r|0)', 'f(r|1)', 'histogramme bit 0', 'histogramme bit 1', 'Location', 'northeastoutside');
subplot(2,1,2);
plot(rr, p0*f0, 'b', rr, p1*f1, 'r', 'LineWidth', 1.5); hold on;
xline(s_opt, 'k--', sprintf('s* = %.2f', s_opt), 'LineWidth', 1.2);
grid on; xlabel('r'); ylabel('p_i f(r|i)');
title('Densités pondérées par les probabilités a priori (critère MAP)');
legend('p_0 f(r|0)', 'p_1 f(r|1)', 'Location', 'northeastoutside');

% Figure 2 : TEB en fonction du seuil
sFin = linspace(min(sv), max(sv), 1000);
figure('Name', 'TEB vs seuil - bruit uniforme');
plot(sFin, Pe_unif(sFin), 'LineWidth', 1.5); hold on;
errorbar(sv, teb, ic, 'o', 'LineWidth', 1.2);
xline(s_opt, 'k--', 's*');
grid on;
xlabel('Seuil de décision s'); ylabel('Taux d''erreur binaire');
title(sprintf('Bruit uniforme : a = %.2f, A = %.0f, p_1 = %.2f', a, A, p1));
legend('P_e(s) théorique', 'TEB simulé (IC 95 %)', 'Location', 'north');