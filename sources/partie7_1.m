%% partie7_1.m — Canal à écho h_c(t) = delta(t) + beta delta(t - tau) (questions 1 et 2)
clear; close all; clc;
Parametres;
Q = @(x) 0.5 * erfc(x / sqrt(2));

Te = 1;  Tsym = L;  Tb = L/2;  Tpas = 1;     % un échantillon = 1
Es = 1;  Eb = Es/2;
span = 10;
hE   = rrc_coeffs(alpha, L, span);
Nlog = 400*L;
Nmax = 1e6;
hEcho = [1 zeros(1, tau*L - 1) beta];        % écho retardé de tau symboles
fprintf('Canal : beta = %.2f, retard tau = %d symbole(s), roll-off alpha = %.2f\n', beta, tau, alpha);

mdl = construire_modele_chaine_complete(false);

%% Étalonnage sans bruit et sans écho
rng(P.graine);
Nsim = 2000;  bits = double(rand(Nsim, 1) < 0.5);
bits_ws = [(0:Nsim-1).' * Tb, bits];
N0 = 0;  hc = 1;  graine = P.graine;
meilleur = -inf;
for d = 1:L
    dPhase = d;
    out = sim(mdl);
    z = out.zsym(:);  z = z(30:end);
    o = min(abs([real(z); imag(z)]));
    if o > meilleur, meilleur = o; dOpt = d; end
end
dPhase = dOpt;
out0 = sim(mdl);
D = trouver_retard(bits, out0.rx, 80);
% Alignement des échantillons de décision sur les symboles émis
s  = ((2*bits(1:2:end) - 1) + 1j*(2*bits(2:2:end) - 1)) / sqrt(2);
z0 = out0.zsym(:);
acc = zeros(1, 41);
for l = 0:40
    n = min(numel(z0) - l, numel(s));
    acc(l+1) = mean(sign(real(z0(l+1:l+n))) == sign(real(s(1:n))));
end
[~, i] = max(acc);  lag = i - 1;
ye0 = real(out0.ye(:));
m = arrayfun(@(p) mean(abs(ye0(p:L:end))), 1:L);
[~, pOpt] = max(m);
fprintf('Étalonnage : dPhase = %d, retard = %d bits, décalage des symboles = %d\n', dPhase, D, lag);

%% Q1 : diagramme de l'œil et constellation avec écho
hc = hEcho;
outE = sim(mdl);
yeE  = real(outE.ye(:));
zE   = outE.zsym(:);  zE = zE(30:end);
ouvE = min(abs([real(zE); imag(zE)]));
fprintf('\n=== Q1 ===\n');
fprintf('Ouverture de l''œil : %.3f sans écho, %.3f avec écho (théorie (1-beta)/sqrt(2) = %.3f)\n', ...
        meilleur, ouvE, (1 - beta)/sqrt(2));
fprintf('Niveaux reçus sur chaque voie : +-(1+beta)/sqrt(2) = +-%.3f et +-(1-beta)/sqrt(2) = +-%.3f\n', ...
        (1 + beta)/sqrt(2), (1 - beta)/sqrt(2));

figure('Name', 'Œil et constellations avec écho');
centres = (pOpt + 2*L) : L : (numel(ye0) - L);
tracer = {ye0, yeE};  titres = {'Sans écho', sprintf('Avec écho (\\beta = %.2f, \\tau = %dT)', beta, tau)};
for f = 1:2
    subplot(2, 2, f);
    y = tracer{f};
    for ci = centres(1:min(200, end))
        plot((-L:L)/L, y(ci-L:ci+L), 'b-');  hold on;
    end
    xline(0, 'r-', 'LineWidth', 1.5);  grid on;
    xlabel('t / T');  ylabel('voie I');  title(titres{f});
end
N0 = Eb / 10;  Nsim = 4000;  bits = double(rand(Nsim, 1) < 0.5);
bits_ws = [(0:Nsim-1).' * Tb, bits];
for f = 1:2
    if f == 1, hc = 1; else, hc = hEcho; end
    out = sim(mdl);  z = out.zsym(:);  z = z(30:end);
    subplot(2, 2, 2 + f);
    plot(real(z), imag(z), '.', 'MarkerSize', 4);  hold on;
    xline(0, 'k-');  yline(0, 'k-');  axis equal;  axis([-1.8 1.8 -1.8 1.8]);  grid on;
    xlabel('I');  ylabel('Q');  title([titres{f} ', 10 dB']);
end

%% Q1-Q2 : TEB sans égalisation, avec égaliseur ZF et avec égaliseur à retour de décision
EbN0dB_v = 0:9;
e  = 10.^(EbN0dB_v/10);
x  = sqrt(2*e);
q  = Q(x);
thEcho = 0.5*(Q((1 + beta)*x) + Q((1 - beta)*x));
thZF   = Q(sqrt(1 - beta^2)*x);
hc = hEcho;
tebE = zeros(size(e));  tebZF = tebE;  tebDFE = tebE;
fprintf('\n Eb/N0 | sans écho | écho simulé | écho théorie | ZF simulé | ZF théorie | DFE simulé\n');
for i = 1:numel(e)
    N0 = Eb / e(i);
    graine = P.graine + 100*i;
    rng(graine);
    Nsim = 2 * ceil(min(Nmax, max(1e5, 300/thZF(i))) / 2);
    bits = double(rand(Nsim, 1) < 0.5);
    bits_ws = [(0:Nsim-1).' * Tb, bits];
    out = sim(mdl);
    rx = out.rx(:);
    tebE(i) = mean(bits(10:end-D) ~= rx(10+D:end));

    % Égalisation au rythme symbole, à partir des échantillons de décision
    s  = ((2*bits(1:2:end) - 1) + 1j*(2*bits(2:2:end) - 1)) / sqrt(2);
    z  = out.zsym(:);
    Ns = min(numel(s), numel(z) - lag);
    zk = z(lag+1 : lag+Ns);  sk = s(1:Ns);
    % ZF : inverse du canal, y_k = z_k - beta y_{k-tau}
    yZF = filter(1, [1 zeros(1, tau-1) beta], zk);
    % DFE : on retranche l'écho reconstruit à partir des décisions passées
    dec = zeros(Ns, 1);
    for k = 1:Ns
        yk = zk(k);
        if k > tau, yk = yk - beta*dec(k - tau); end
        dec(k) = (sign(real(yk)) + 1j*sign(imag(yk))) / sqrt(2);
    end
    ok = 20:Ns-20;
    errB = @(y) (sum(sign(real(y(ok))) ~= sign(real(sk(ok)))) + ...
                 sum(sign(imag(y(ok))) ~= sign(imag(sk(ok))))) / (2*numel(ok));
    tebZF(i)  = errB(yZF);
    tebDFE(i) = errB(dec);
    fprintf('%4d dB | %9.3e | %10.3e  | %10.3e   | %9.3e | %9.3e  | %9.3e\n', EbN0dB_v(i), ...
            q(i), tebE(i), thEcho(i), tebZF(i), thZF(i), tebDFE(i));
end

xf = linspace(0, 9, 200);  xx = sqrt(2*10.^(xf/10));
figure('Name', 'TEB avec écho');
semilogy(xf, Q(xx), 'k-', 'LineWidth', 1.5);  hold on;
semilogy(xf, 0.5*(Q((1+beta)*xx) + Q((1-beta)*xx)), 'r-', 'LineWidth', 1.2);
semilogy(EbN0dB_v, tebE, 'ro', 'LineWidth', 1.5);
semilogy(xf, Q(sqrt(1-beta^2)*xx), 'b-', 'LineWidth', 1.2);
semilogy(EbN0dB_v, tebZF, 'bs', 'LineWidth', 1.5);
semilogy(EbN0dB_v, tebDFE, 'g^-', 'LineWidth', 1.5);
grid on;  ylim([1e-6 1]);
xlabel('E_b/N_0 (dB)');  ylabel('Taux d''erreur binaire');
title(sprintf('Canal à écho : \\beta = %.2f, \\tau = %d T', beta, tau));
legend('Sans écho : Q(\surd(2E_b/N_0))', 'Écho : théorie', 'Écho : simulation', ...
       'Égaliseur ZF : théorie', 'Égaliseur ZF : simulation', ...
       'Égaliseur à retour de décision : simulation', 'Location', 'southwest');

save('resultats_partie7.mat', 'EbN0dB_v', 'tebE', 'tebZF', 'tebDFE', 'beta', 'tau');