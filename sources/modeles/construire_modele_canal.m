function mdl = construire_modele_canal(type)
%CONSTRUIRE_MODELE_CANAL  Construit la chaîne de base à 1 échantillon par bit
%   (partie 3, questions 1 à 9).
%   mdl = construire_modele_canal(type), type :
%     'cbs'   : canal binaire symétrique   tx XOR e,  P(e = 1) = pe
%     'unif'  : r = x + n, x = ±A, n uniforme sur [-a, a], décision r > s
%     'gauss' : r = x + n, x = ±A, n gaussien N(0, sigma^2), décision r > s
%   Sorties enregistrées : out.tx (bits émis), out.rx (bits décidés) et,
%   pour 'unif' et 'gauss', out.r (échantillons reçus).
%   Variables du workspace utilisées : Tb, Nsim, p1, pe, A, a, sigma, s, graine.

    mdl = ['modele_canal_' type];
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);
    open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tb', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');

    % --- Émetteur : source binaire -----------------------------------------
    ajouter_source_binaire(mdl, 'Source', [40 80 160 130], 'p1', 'graine');
    ajouter_to_workspace(mdl, 'tx', [260 10 320 40]);
    add_line(mdl, 'Source/1', 'tx/1', 'autorouting', 'on');

    switch type
        case 'cbs'
            % --- Canal binaire symétrique : inversion du bit avec proba pe
            ajouter_source_binaire(mdl, 'Erreurs', [40 200 160 250], 'pe', 'graine+1');
            add_block('simulink/Logic and Bit Operations/Logical Operator', ...
                [mdl '/CBS'], 'Operator', 'XOR', 'Position', [260 120 300 170]);
            add_block('simulink/Signal Attributes/Data Type Conversion', ...
                [mdl '/VersDouble'], 'OutDataTypeStr', 'double', 'Position', [360 130 430 160]);
            ajouter_to_workspace(mdl, 'rx', [480 130 540 160]);
            add_line(mdl, 'Source/1',     'CBS/1',        'autorouting', 'on');
            add_line(mdl, 'Erreurs/1',    'CBS/2',        'autorouting', 'on');
            add_line(mdl, 'CBS/1',        'VersDouble/1', 'autorouting', 'on');
            add_line(mdl, 'VersDouble/1', 'rx/1',         'autorouting', 'on');

        case {'unif', 'gauss'}
            % --- Mise en niveaux antipodaux : x = 2A*b - A ----------------
            add_block('simulink/Math Operations/Gain', [mdl '/Mapping'], ...
                'Gain', '2*A', 'Position', [220 90 270 120]);
            add_block('simulink/Math Operations/Bias', [mdl '/Decalage'], ...
                'Bias', '-A', 'Position', [300 90 350 120]);

            % --- Bruit additif -------------------------------------------
            if strcmp(type, 'unif')
                add_block('simulink/Sources/Uniform Random Number', [mdl '/Bruit'], ...
                    'Minimum', '-a', 'Maximum', 'a', 'Seed', 'graine+1', ...
                    'SampleTime', 'Tb', 'Position', [220 180 280 220]);
            else
                add_block('simulink/Sources/Random Number', [mdl '/Bruit'], ...
                    'Mean', '0', 'Variance', 'sigma^2', 'Seed', 'graine+1', ...
                    'SampleTime', 'Tb', 'Position', [220 180 280 220]);
            end
            add_block('simulink/Math Operations/Sum', [mdl '/Canal'], ...
                'Inputs', '++', 'Position', [400 95 430 125]);

            % --- Récepteur : comparateur à seuil s ------------------------
            add_block('simulink/Sources/Constant', [mdl '/Seuil'], ...
                'Value', 's', 'SampleTime', 'Tb', 'Position', [400 180 450 210]);
            add_block('simulink/Logic and Bit Operations/Relational Operator', ...
                [mdl '/Decision'], 'Operator', '>', 'Position', [500 100 540 140]);
            add_block('simulink/Signal Attributes/Data Type Conversion', ...
                [mdl '/VersDouble'], 'OutDataTypeStr', 'double', 'Position', [580 105 650 135]);
            ajouter_to_workspace(mdl, 'r',  [480 20 540 50]);
            ajouter_to_workspace(mdl, 'rx', [700 105 760 135]);

            add_line(mdl, 'Source/1',     'Mapping/1',    'autorouting', 'on');
            add_line(mdl, 'Mapping/1',    'Decalage/1',   'autorouting', 'on');
            add_line(mdl, 'Decalage/1',   'Canal/1',      'autorouting', 'on');
            add_line(mdl, 'Bruit/1',      'Canal/2',      'autorouting', 'on');
            add_line(mdl, 'Canal/1',      'Decision/1',   'autorouting', 'on');
            add_line(mdl, 'Seuil/1',      'Decision/2',   'autorouting', 'on');
            add_line(mdl, 'Canal/1',      'r/1',          'autorouting', 'on');
            add_line(mdl, 'Decision/1',   'VersDouble/1', 'autorouting', 'on');
            add_line(mdl, 'VersDouble/1', 'rx/1',         'autorouting', 'on');

        otherwise
            error('Type de canal inconnu : %s (cbs, unif ou gauss)', type);
    end

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end