function construire_modele_source(nomModele)
%CONSTRUIRE_MODELE_SOURCE  Construit par script le modèle Simulink de la
%   source binaire (partie 2.1) :
%     [Source binaire (sous-système masqué)] --> [To Workspace 'bits']
%
%   Contenu du sous-système :
%     Uniform Random Number [0,1] (cadencé à Tb) --\
%                                                   >-- Relational (u < p1) --> double --> sortie
%     Constant p1 (cadencé à Tb) ------------------/
%
%   Paramètres du masque : p1, Tb, graine (valeurs par défaut = variables
%   du workspace créées par Parametres.m).
%   Le modèle utilise la variable Nsim (nombre de bits à simuler).

    if nargin < 1
        nomModele = 'modele_source';
    end

    % --- Repartir d'un modèle vierge ---------------------------------------
    if bdIsLoaded(nomModele), close_system(nomModele, 0); end
    if exist([nomModele '.slx'], 'file'), delete([nomModele '.slx']); end
    new_system(nomModele);
    open_system(nomModele);

    % --- Solveur : temps discret, pas fixe = Tb -----------------------------
    set_param(nomModele, ...
        'SolverType', 'Fixed-step', ...
        'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tb', ...
        'StopTime', '(Nsim-1)*Tb', ...      % Nsim échantillons : t = 0 ... (Nsim-1)Tb
        'ReturnWorkspaceOutputs', 'on');    % sim() renvoie un objet 'out'

    % --- Sous-système "Source binaire" -------------------------------------
    sub = [nomModele '/Source binaire'];
    add_block('simulink/Ports & Subsystems/Subsystem', sub, ...
              'Position', [100 100 220 160]);
    % on vide le sous-système par défaut (In1 -> Out1)
    delete_line(sub, 'In1/1', 'Out1/1');
    delete_block([sub '/In1']);
    set_param([sub '/Out1'], 'Name', 'bits', 'Position', [520 98 550 112]);

    add_block('simulink/Sources/Uniform Random Number', [sub '/Uniforme'], ...
        'Minimum', '0', 'Maximum', '1', ...
        'Seed', 'graine_m', 'SampleTime', 'Tb_m', ...
        'Position', [60 60 120 100]);

    add_block('simulink/Sources/Constant', [sub '/Seuil'], ...
        'Value', 'p1_m', 'SampleTime', 'Tb_m', ...
        'Position', [60 130 120 160]);

    add_block('simulink/Logic and Bit Operations/Relational Operator', ...
        [sub '/Comparateur'], 'Operator', '<', ...
        'Position', [200 85 240 125]);

    add_block('simulink/Signal Attributes/Data Type Conversion', ...
        [sub '/VersDouble'], 'OutDataTypeStr', 'double', ...
        'Position', [320 90 400 120]);

    add_line(sub, 'Uniforme/1',    'Comparateur/1', 'autorouting', 'on');
    add_line(sub, 'Seuil/1',       'Comparateur/2', 'autorouting', 'on');
    add_line(sub, 'Comparateur/1', 'VersDouble/1',  'autorouting', 'on');
    add_line(sub, 'VersDouble/1',  'bits/1',        'autorouting', 'on');

    % --- Masque du sous-système (paramètres réglables) ---------------------
    m = Simulink.Mask.create(sub);
    m.Type        = 'Source binaire';
    m.Description = 'Source binaire sans mémoire : P(1) = p1, un bit toutes les Tb secondes.';
    m.addParameter('Type', 'edit', 'Name', 'p1_m', ...
        'Prompt', 'Probabilité d''émettre un 1 (p1)', 'Value', 'p1');
    m.addParameter('Type', 'edit', 'Name', 'Tb_m', ...
        'Prompt', 'Durée d''un bit Tb (s)', 'Value', 'Tb');
    m.addParameter('Type', 'edit', 'Name', 'graine_m', ...
        'Prompt', 'Graine (Seed)', 'Value', 'graine');

    % --- Récupération des bits ---------------------------------------------
    add_block('simulink/Sinks/To Workspace', [nomModele '/VersWorkspace'], ...
        'VariableName', 'bits', 'SaveFormat', 'Array', ...
        'Position', [320 115 400 145]);
    add_line(nomModele, 'Source binaire/1', 'VersWorkspace/1', 'autorouting', 'on');

    save_system(nomModele);
    fprintf('Modèle "%s.slx" construit et enregistré.\n', nomModele);
end