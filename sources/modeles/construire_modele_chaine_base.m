function mdl = construire_modele_chaine_base()
%CONSTRUIRE_MODELE_CHAINE_BASE  Chaîne de base à L échantillons par bit
%   (partie 3, questions 10 à 12).
%
%   Source (Tb) -> x = ±A (Tb) -> suréchantillonnage (Te = Tb/L, bloqueur)
%     -> + bruit gaussien de variance sigma2e par échantillon (Te)
%     -> Détecteur optimal : intégrateur sur un bit -> échantillonneur (Tb)
%        -> comparateur à seuil nul
%     -> (branche de comparaison) un seul échantillon au milieu du bit
%
%   L'intégrateur à remise à zéro est réalisé par une somme glissante sur
%   L échantillons (filtre RIF de coefficients 1/L) : échantillonnée une fois
%   par bit au bon instant, elle vaut exactement
%       z_k = (1/L) * sum_{i=0}^{L-1} r_{kL+i}
%   c'est-à-dire la sortie de l'intégrateur remis à zéro à kTb et lue en
%   (k+1)Tb. Le bloc Delay "Phase" (dPhase échantillons) cale l'instant
%   d'échantillonnage sur la fin du bit ; il est étalonné par partie3_4.m.
%
%   Variables du workspace : Tb, Te, L, A, Nsim, sigma2e, graine, dPhase, dMid.
%   Sorties : out.tx, out.rxInt, out.rxMid, out.z (Tb) ; out.x, out.r
%   (20 derniers bits seulement, pour la visualisation).

    mdl = 'modele_chaine_base';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);
    open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Te', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');

    % --- Émetteur -------------------------------------------------------------
    ajouter_source_binaire(mdl, 'Source', [30 80 150 130], '0.5', 'graine');
    ajouter_to_workspace(mdl, 'tx', [220 10 280 40]);
    add_block('simulink/Math Operations/Gain', [mdl '/Mapping'], ...
        'Gain', '2*A', 'Position', [200 90 250 120]);
    add_block('simulink/Math Operations/Bias', [mdl '/Decalage'], ...
        'Bias', '-A', 'Position', [280 90 330 120]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Surechantillonnage'], ...
        'OutPortSampleTime', 'Te', 'Position', [370 88 420 122]);

    % --- Canal gaussien -------------------------------------------------------
    add_block('simulink/Sources/Random Number', [mdl '/Bruit'], ...
        'Mean', '0', 'Variance', 'sigma2e', 'Seed', 'graine+1', ...
        'SampleTime', 'Te', 'Position', [370 180 430 220]);
    add_block('simulink/Math Operations/Sum', [mdl '/Canal'], ...
        'Inputs', '++', 'Position', [480 95 510 125]);
    add_block('simulink/Sinks/To Workspace', [mdl '/x'], 'VariableName', 'x', ...
        'SaveFormat', 'Array', 'MaxDataPoints', '20*L', 'Position', [470 10 530 40]);
    add_block('simulink/Sinks/To Workspace', [mdl '/r'], 'VariableName', 'r', ...
        'SaveFormat', 'Array', 'MaxDataPoints', '20*L', 'Position', [560 10 620 40]);

    % --- Détecteur optimal (sous-système) -------------------------------------
    det = [mdl '/Detecteur optimal'];
    add_block('simulink/Ports & Subsystems/Subsystem', det, 'Position', [580 80 720 150]);
    delete_line(det, 'In1/1', 'Out1/1');
    set_param([det '/In1'],  'Name', 'r',    'Position', [20 98 50 112]);
    set_param([det '/Out1'], 'Name', 'bits', 'Position', [700 98 730 112]);
    add_block('simulink/Sinks/Out1', [det '/z'], 'Position', [700 180 730 194]);

    add_block('simulink/Discrete/Discrete FIR Filter', [det '/Integrateur'], ...
        'Coefficients', 'ones(1,L)/L', 'Position', [90 85 170 125]);
    add_block('simulink/Discrete/Delay', [det '/Phase'], ...
        'DelayLength', 'dPhase', 'Position', [210 88 260 122]);
    add_block('simulink/Signal Attributes/Rate Transition', [det '/Echantillonneur'], ...
        'OutPortSampleTime', 'Tb', 'Position', [300 88 350 122]);
    add_block('simulink/Sources/Constant', [det '/Seuil'], ...
        'Value', '0', 'SampleTime', 'Tb', 'Position', [390 150 430 175]);
    add_block('simulink/Logic and Bit Operations/Relational Operator', [det '/Decision'], ...
        'Operator', '>', 'Position', [470 90 510 130]);
    add_block('simulink/Signal Attributes/Data Type Conversion', [det '/VersDouble'], ...
        'OutDataTypeStr', 'double', 'Position', [560 95 630 125]);

    add_line(det, 'r/1',               'Integrateur/1',     'autorouting', 'on');
    add_line(det, 'Integrateur/1',     'Phase/1',           'autorouting', 'on');
    add_line(det, 'Phase/1',           'Echantillonneur/1', 'autorouting', 'on');
    add_line(det, 'Echantillonneur/1', 'Decision/1',        'autorouting', 'on');
    add_line(det, 'Seuil/1',           'Decision/2',        'autorouting', 'on');
    add_line(det, 'Decision/1',        'VersDouble/1',      'autorouting', 'on');
    add_line(det, 'VersDouble/1',      'bits/1',            'autorouting', 'on');
    add_line(det, 'Echantillonneur/1', 'z/1',               'autorouting', 'on');

    ajouter_to_workspace(mdl, 'rxInt', [790 85 850 115]);
    ajouter_to_workspace(mdl, 'z',     [790 130 850 160]);

    % --- Branche de comparaison : un échantillon au milieu du bit ------------
    add_block('simulink/Discrete/Delay', [mdl '/DelaiMilieu'], ...
        'DelayLength', 'dMid', 'Position', [580 240 630 275]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/EchMilieu'], ...
        'OutPortSampleTime', 'Tb', 'Position', [670 240 720 275]);
    add_block('simulink/Sources/Constant', [mdl '/SeuilMilieu'], ...
        'Value', '0', 'SampleTime', 'Tb', 'Position', [670 300 710 325]);
    add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl '/DecisionMilieu'], ...
        'Operator', '>', 'Position', [760 245 800 285]);
    add_block('simulink/Signal Attributes/Data Type Conversion', [mdl '/VersDoubleMilieu'], ...
        'OutDataTypeStr', 'double', 'Position', [840 250 910 280]);
    ajouter_to_workspace(mdl, 'rxMid', [950 250 1010 280]);

    % --- Connexions -----------------------------------------------------------
    add_line(mdl, 'Source/1',             'tx/1',                  'autorouting', 'on');
    add_line(mdl, 'Source/1',             'Mapping/1',             'autorouting', 'on');
    add_line(mdl, 'Mapping/1',            'Decalage/1',            'autorouting', 'on');
    add_line(mdl, 'Decalage/1',           'Surechantillonnage/1',  'autorouting', 'on');
    add_line(mdl, 'Surechantillonnage/1', 'Canal/1',               'autorouting', 'on');
    add_line(mdl, 'Surechantillonnage/1', 'x/1',                   'autorouting', 'on');
    add_line(mdl, 'Bruit/1',              'Canal/2',               'autorouting', 'on');
    add_line(mdl, 'Canal/1',              'r/1',                   'autorouting', 'on');
    add_line(mdl, 'Canal/1',              'Detecteur optimal/1',   'autorouting', 'on');
    add_line(mdl, 'Detecteur optimal/1',  'rxInt/1',               'autorouting', 'on');
    add_line(mdl, 'Detecteur optimal/2',  'z/1',                   'autorouting', 'on');
    add_line(mdl, 'Canal/1',              'DelaiMilieu/1',         'autorouting', 'on');
    add_line(mdl, 'DelaiMilieu/1',        'EchMilieu/1',           'autorouting', 'on');
    add_line(mdl, 'EchMilieu/1',          'DecisionMilieu/1',      'autorouting', 'on');
    add_line(mdl, 'SeuilMilieu/1',        'DecisionMilieu/2',      'autorouting', 'on');
    add_line(mdl, 'DecisionMilieu/1',     'VersDoubleMilieu/1',    'autorouting', 'on');
    add_line(mdl, 'VersDoubleMilieu/1',   'rxMid/1',               'autorouting', 'on');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end