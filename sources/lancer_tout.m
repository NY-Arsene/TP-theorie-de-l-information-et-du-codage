function lancer_tout(scripts)
%LANCER_TOUT  Exécute les scripts du TP dans l'ordre et enregistre toutes
%   les figures dans le dossier ../figures (PNG, 200 dpi).
%   lancer_tout                      : tout le TP (environ 30 à 40 minutes)
%   lancer_tout({'partie3_4'})       : un ou plusieurs scripts choisis
%
%   Les scripts sont exécutés dans le workspace de base (evalin), car les
%   modèles Simulink y lisent leurs variables.

    if nargin < 1
        scripts = {'partie2_1', 'partie2_2', 'partie2_3', 'partie2_4', 'partie2_5', ...
                   'partie3_1', 'partie3_2', 'partie3_3', 'partie3_4', ...
                   'partie4_1', 'partie4_2', 'partie4_3', 'partie4_4', ...
                   'partie5_1', 'partie5_2', 'partie6_1', 'partie6_2', ...
                   'partie7_1', 'partie7_2'};
    end
    dossierFig = fullfile(fileparts(which('lancer_tout')), '..', 'figures');
    if ~isfolder(dossierFig), mkdir(dossierFig); end

    for k = 1:numel(scripts)
        fprintf('\n==================== %s ====================\n', scripts{k});
        t = tic;
        evalin('base', scripts{k});
        figs = findobj('Type', 'figure');
        for f = figs.'
            nom = sprintf('%s_fig%d.png', scripts{k}, f.Number);
            exportgraphics(f, fullfile(dossierFig, nom), 'Resolution', 200);
        end
        fprintf('---- %s terminé en %.0f s, %d figure(s) enregistrée(s)\n', ...
                scripts{k}, toc(t), numel(figs));
    end
end
