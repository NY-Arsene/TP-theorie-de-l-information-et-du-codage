%% partie3_3.m — Canal gaussien, 1 échantillon par bit (questions 7 à 9)
clear; close all; clc;
Parametres;
Nsim = 1e5;
Q = @(x) 0.5 * erfc(x / sqrt(2));

%% Q7 : seuil optimal et probabilité d'erreur théoriques
s_opt = sigma^2 / (2*A) * log(p0 / p1);
Pe_g  = @(s) p0 * Q((s + A) / sigma) + p1 * Q((A - s) / sigma);
fprintf('=== Q7 : bruit gaussien, sigma = %.2f, A = %.0f, p1 = %.2f ===\n', sigma, A, p1);
fprintf('Seuil optimal s* = sigma^2/(2A) ln(p0/p1) = %.4f\n', s_opt);
fprintf('Pe(s*) = %.5f   Pe(0) = %.5f\n', Pe_g(s_opt), Pe_g(0));
fprintf('Gain théorique : %.5f (%.1f %% d''erreurs en moins)\n', ...
        Pe_g(0) - Pe_g(s_opt), 100 * (1 - Pe_g(s_opt)/Pe_g(0)));

%% Q8 : TEB simulé en fonction du seuil
mdl = construire_modele_canal('gauss');
sv  = unique([linspace(-1.2*A, 1.2*A, 25), s_opt, 0]);
teb = zeros(size(sv));  ic = teb;
for i = 1:numel(sv)
    s   = sv(i);
    out = sim(mdl);
    e   = out.tx(:) ~= out.rx(:);
    teb(i) = mean(e);
    ic(i)  = 1.96 * sqrt(teb(i)*(1-teb(i)) / numel(e));
    if s == s_opt, rOpt = out.r(:); txOpt = out.tx(:); end
end
[tebMin, iMin] = min(teb);
fprintf('\n=== Q8 : simulation (%d bits par seuil, même bruit pour tous les seuils) ===\n', Nsim);
fprintf('TEB simulé : s = 0 -> %.5f ;  s = s* -> %.5f\n', teb(sv == 0), teb(sv == s_opt));
fprintf('Gain simulé : %.5f (%.1f %%)\n', teb(sv == 0) - teb(sv == s_opt), ...
        100 * (1 - teb(sv == s_opt) / teb(sv == 0)));
fprintf('Minimum simulé : TEB = %.5f pour s = %.4f\n', tebMin, sv(iMin));

% Figure 1 : densités pondérées et seuil optimal
rr = linspace(-A - 4*sigma, A + 4*sigma, 2000);
g0 = exp(-(rr + A).^2 / (2*sigma^2)) / (sigma*sqrt(2*pi));
g1 = exp(-(rr - A).^2 / (2*sigma^2)) / (sigma*sqrt(2*pi));
figure('Name', 'Densités - bruit gaussien');
plot(rr, p0*g0, 'b', rr, p1*g1, 'r', 'LineWidth', 1.5); hold on;
histogram(rOpt, 80, 'Normalization', 'pdf', 'FaceColor', [0.6 0.6 0.6], ...
          'FaceAlpha', 0.3, 'EdgeColor', 'none');
xline(s_opt, 'k--', sprintf('s* = %.3f', s_opt), 'LineWidth', 1.2);
xline(0, 'k:', 's = 0');
grid on; xlabel('r'); ylabel('Densité');
title('Densités pondérées p_i f(r|i) et histogramme de r');
legend('p_0 f(r|0)', 'p_1 f(r|1)', 'histogramme simulé', 'Location', 'northeast');

% Figure 2 : TEB en fonction du seuil
sFin = linspace(min(sv), max(sv), 1000);
figure('Name', 'TEB vs seuil - bruit gaussien');
plot(sFin, Pe_g(sFin), 'LineWidth', 1.5); hold on;
errorbar(sv, teb, ic, 'o', 'LineWidth', 1.2);
xline(s_opt, 'k--', 's*'); xline(0, 'k:', 's = 0');
grid on;
xlabel('Seuil de décision s'); ylabel('Taux d''erreur binaire');
title(sprintf('Bruit gaussien : \\sigma = %.2f, A = %.0f, p_1 = %.2f', sigma, A, p1));
legend('P_e(s) théorique', 'TEB simulé (IC 95 %)', 'Location', 'north');