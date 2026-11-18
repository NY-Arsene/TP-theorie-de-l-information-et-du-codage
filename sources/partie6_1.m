%% partie6_1.m — Filtre en racine de cosinus surélevé : réponse, IES, spectre (Q2 à Q4)
clear; close all; clc;
Parametres;
span = 10;                                 % troncature : 10 symboles, N = 10L + 1
fprintf('alpha = %.2f, L = %d, span = %d -> N = %d coefficients\n', alpha, L, span, span*L + 1);

%% Q2 : valeurs limites et comparaison avec la Toolbox
h0   = 1 - alpha + 4*alpha/pi;
hlim = alpha/sqrt(2) * ((1 + 2/pi)*sin(pi/(4*alpha)) + (1 - 2/pi)*cos(pi/(4*alpha)));
f    = @(x) (4*alpha/pi*cos(pi*(1+alpha)*x) + (1-alpha)*sin(pi*(1-alpha)*x)./(pi*(1-alpha)*x)) ./ (1 - (4*alpha*x).^2);
x0   = 1/(4*alpha);
fprintf('\n=== Q2 : valeurs limites (sqrt(T) h(t), T = 1) ===\n');
fprintf('t = 0        : h(0) = 1 - a + 4a/pi = %.6f   (formule en t = 1e-6 : %.6f)\n', h0, f(1e-6));
fprintf('t = T/(4a)   : %.6f   (formule en T/(4a) +- 1e-6 : %.6f / %.6f)\n', ...
        hlim, f(x0 - 1e-6), f(x0 + 1e-6));

[h, t] = rrc_coeffs(alpha, L, span);
if exist('rcosdesign', 'file')
    hTb = rcosdesign(alpha, span, L, 'sqrt');
    fprintf('Écart maximal avec rcosdesign (Toolbox) : %.2e\n', max(abs(h - hTb)));
end

%% Q3 : h et h*h, interférence entre symboles
g  = conv(h, h);                           % mise en forme + filtre adapté
tg = (-(numel(g)-1)/2 : (numel(g)-1)/2) / L;
c  = (numel(g) + 1) / 2;                   % indice de t = 0
k  = [-span:-1, 1:span];
ies  = abs(g(c + k*L)) / g(c);
hk   = abs(h((numel(h)+1)/2 + (1:3)*L)) / h((numel(h)+1)/2);
fprintf('\n=== Q3 ===\n');
fprintf('(h*h)(0) = %.6f (énergie unité)\n', g(c));
fprintf('max |(h*h)(kT)| / (h*h)(0), k ~= 0 : %.2e   -> IES quasi nulle\n', max(ies));
fprintf('|h(kT)| / h(0) pour k = 1, 2, 3 : %s   -> h seul ne s''annule pas\n', mat2str(hk, 3));
for sp = [4 6 10 20]
    hs = rrc_coeffs(alpha, L, sp);  gs = conv(hs, hs);  cs = (numel(gs) + 1)/2;
    ks = [-sp:-1, 1:sp];
    fprintf('  troncature à %2d symboles : IES résiduelle max = %.2e\n', sp, ...
            max(abs(gs(cs + ks*L))) / gs(cs));
end

figure('Name', 'Réponses impulsionnelles');
subplot(2, 1, 1);
plot(t, h, 'b.-'); hold on;
stem(-5:5, h((numel(h)+1)/2 + (-5:5)*L), 'r', 'filled');
grid on; xlabel('t / T'); ylabel('h(t)');
title(sprintf('Racine de cosinus surélevé, \\alpha = %.2f (points rouges : t = kT)', alpha));
subplot(2, 1, 2);
plot(tg, g, 'b.-'); hold on;
stem(-span:span, g(c + (-span:span)*L), 'r', 'filled');
grid on; xlabel('t / T'); ylabel('(h * h)(t)');
title('Cosinus surélevé h*h : nul aux instants kT, k \neq 0');

%% Q4 : densités spectrales de puissance, filtre porte et RRC
rng(graine);
Ns   = 2e4;
sym  = ((2*randi([0 1], Ns, 1) - 1) + 1j*(2*randi([0 1], Ns, 1) - 1)) / sqrt(2);
up   = zeros(Ns*L, 1);  up(1:L:end) = sym;          % un symbole tous les L échantillons
xP   = filter(ones(L, 1)/sqrt(L), 1, up);           % filtre porte
xR   = filter(h, 1, up);                            % racine de cosinus surélevé
nfft = 1024;
[SP, fr] = pwelch(xP, hann(nfft), nfft/2, nfft, L, 'centered');   % fréquence en 1/T
SR       = pwelch(xR, hann(nfft), nfft/2, nfft, L, 'centered');

% Bandes occupées (unilatérales) : 99 % de la puissance, et niveau -40 dB
B99 = @(S) bande99(fr, S);
B40 = @(S) max(abs(fr(10*log10(S/max(S)) > -40)));
fprintf('\n=== Q4 : bande occupée (f en 1/T) ===\n');
fprintf('Porte   : B(99 %%) = %.3f /T,  B(-40 dB) = %.3f /T (spectre en sinc^2, limité ici par fe/2 = %g /T)\n', ...
        B99(SP), B40(SP), L/2);
fprintf('RRC     : B(99 %%) = %.3f /T,  B(-40 dB) = %.3f /T,  théorie (1+a)/(2T) = %.3f /T\n', ...
        B99(SR), B40(SR), (1 + alpha)/2);

ff  = linspace(-L/2, L/2, 2000);
Cth = zeros(size(ff));                      % cosinus surélevé théorique (T = 1)
a1  = (1 - alpha)/2;  a2 = (1 + alpha)/2;
Cth(abs(ff) <= a1) = 1;
m   = abs(ff) > a1 & abs(ff) <= a2;
Cth(m) = 0.5 * (1 - sin(pi/alpha * (abs(ff(m)) - 0.5)));
sincf = sin(pi*ff)./(pi*ff);  sincf(ff == 0) = 1;
figure('Name', 'Densités spectrales');
plot(fr, 10*log10(SP/max(SP)), 'b', 'LineWidth', 1.2); hold on;
plot(fr, 10*log10(SR/max(SR)), 'r', 'LineWidth', 1.2);
plot(ff, 10*log10(sincf.^2 + 1e-12), 'b:');
plot(ff, 10*log10(Cth + 1e-12), 'r:');
xline([-1 1]*(1 + alpha)/2, 'k--');
grid on; ylim([-80 5]);
xlabel('f T'); ylabel('DSP normalisée (dB)');
title('Densité spectrale du signal émis');
legend('Porte (simulation)', sprintf('RRC \\alpha = %.2f (simulation)', alpha), ...
       'Porte : sinc^2(fT)', 'RRC : C_\alpha(f)', '\pm(1+\alpha)/(2T)', 'Location', 'southwest');

%% ------------------------------------------------------------------------
function B = bande99(fr, S)
% Plus petite bande [-B, B] contenant 99 % de la puissance
    fa = unique(abs(fr));
    P  = arrayfun(@(b) sum(S(abs(fr) <= b)), fa);
    B  = fa(find(P >= 0.99*sum(S), 1));
end