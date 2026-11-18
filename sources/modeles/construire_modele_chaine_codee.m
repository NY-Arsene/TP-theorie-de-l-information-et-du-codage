function mdl = construire_modele_chaine_codee()
%CONSTRUIRE_MODELE_CHAINE_CODEE  Chaîne de transmission avec code C(7,4)
%   (partie 4, questions 10 à 12).
%
%   Émission :
%     Source (Tb) -> Buffer 4 (un mot-message toutes les 4Tb)
%       -> ajout de 3 zéros (place de la redondance) -> Unbuffer (cadence Tc = 4Tb/7)
%       -> codeur à registre -> niveaux ±Ac, Ac = A*sqrt(4/7)
%       -> suréchantillonnage (L échantillons par bit codé, Tec = Tc/L)
%   Canal : bruit gaussien de variance sigma2e par échantillon
%   Réception :
%     intégrateur (somme glissante 1/L) -> échantillonneur (Tc) -> décision
%       -> alignement sur les mots (retard dAlign) -> décodeur C(7,4)
%       -> prélèvement du mot décodé toutes les 4Tb -> Unbuffer (Tb)
%
%   Variables du workspace : Tb, Tc, Tec, L, A, Ac, sigma2e, graine, Nsim,
%   dPhase, dAlign, phaseC.
%   Sorties : out.tx, out.rx (bits d'information, Tb), out.cTx, out.cRx
%   (bits codés avant/après le canal, Tc), out.z (sortie échantillonnée de
%   l'intégrateur, Tc).

    try
        load_system('dspbuff3');                 % bibliothèque Buffer / Unbuffer
    catch
        error(['Bibliothèque "dspbuff3" introuvable : les blocs Buffer et Unbuffer ' ...
               'de la DSP System Toolbox sont nécessaires.']);
    end

    mdl = 'modele_chaine_codee';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tec', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');
    Ln = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');

    % --- Émetteur : source et mise en mots -------------------------------------
    ajouter_source_binaire(mdl, 'Source', [20 80 140 130], '0.5', 'graine');
    ajouter_to_workspace(mdl, 'tx', [200 10 260 40]);
    add_block('dspbuff3/Buffer', [mdl '/Buffer 4'], 'N', '4', 'Position', [200 85 250 125]);
    add_block('simulink/Sources/Constant', [mdl '/Zeros redondance'], ...
        'Value', 'zeros(3,1)', 'SampleTime', '4*Tb', 'Position', [200 160 260 190]);
    add_block('simulink/Math Operations/Matrix Concatenate', [mdl '/Mot 7'], ...
        'NumInputs', '2', 'ConcatenateDimension', '1', 'Position', [300 90 320 180]);
    add_block('dspbuff3/Unbuffer', [mdl '/Unbuffer 7'], 'Position', [360 115 410 155]);
    ajouter_codeur_registre(mdl, 'Codeur C(7,4)', [450 105 560 165]);
    ajouter_to_workspace(mdl, 'cTx', [600 20 660 50]);

    % --- Modulation : niveaux ±Ac et suréchantillonnage ------------------------
    add_block('simulink/Math Operations/Gain', [mdl '/Mapping'], ...
        'Gain', '2*Ac', 'Position', [600 120 650 150]);
    add_block('simulink/Math Operations/Bias', [mdl '/Decalage'], ...
        'Bias', '-Ac', 'Position', [680 120 730 150]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Surechantillonnage'], ...
        'OutPortSampleTime', 'Tec', 'Position', [760 118 810 152]);

    % --- Canal gaussien --------------------------------------------------------
    add_block('simulink/Sources/Random Number', [mdl '/Bruit'], ...
        'Mean', '0', 'Variance', 'sigma2e', 'Seed', 'graine+1', ...
        'SampleTime', 'Tec', 'Position', [760 200 820 240]);
    add_block('simulink/Math Operations/Sum', [mdl '/Canal'], ...
        'Inputs', '++', 'Position', [860 125 890 155]);

    % --- Détecteur optimal (identique à la partie 3) ----------------------------
    add_block('simulink/Discrete/Discrete FIR Filter', [mdl '/Integrateur'], ...
        'Coefficients', 'ones(1,L)/L', 'Position', [930 120 1010 160]);
    add_block('simulink/Discrete/Delay', [mdl '/Phase'], ...
        'DelayLength', 'dPhase', 'Position', [1040 123 1090 157]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Echantillonneur'], ...
        'OutPortSampleTime', 'Tc', 'Position', [1120 123 1170 157]);
    ajouter_to_workspace(mdl, 'z', [1200 30 1260 60]);
    add_block('simulink/Sources/Constant', [mdl '/Seuil'], ...
        'Value', '0', 'SampleTime', 'Tc', 'Position', [1200 190 1240 215]);
    add_block('simulink/Logic and Bit Operations/Relational Operator', [mdl '/Decision'], ...
        'Operator', '>', 'Position', [1270 125 1310 165]);
    add_block('simulink/Signal Attributes/Data Type Conversion', [mdl '/VersDouble'], ...
        'OutDataTypeStr', 'double', 'Position', [1340 130 1410 160]);
    ajouter_to_workspace(mdl, 'cRx', [1440 60 1500 90]);

    % --- Décodage et remise en série --------------------------------------------
    add_block('simulink/Discrete/Delay', [mdl '/Alignement mots'], ...
        'DelayLength', 'dAlign', 'Position', [1440 130 1490 165]);
    ajouter_decodeur_hamming(mdl, 'Decodeur C(7,4)', [1520 120 1630 175]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Prelevement mot'], ...
        'OutPortSampleTime', '4*Tb', 'Position', [1660 130 1710 165]);
    add_block('simulink/Math Operations/Reshape', [mdl '/Colonne'], ...
        'OutputDimensionality', 'Column vector (2-D)', 'Position', [1740 130 1790 165]);
    add_block('dspbuff3/Unbuffer', [mdl '/Unbuffer 4'], 'Position', [1820 130 1870 165]);
    ajouter_to_workspace(mdl, 'rx', [1900 133 1960 163]);

    % --- Connexions ---------------------------------------------------------------
    Ln('Source/1',               'tx/1');
    Ln('Source/1',               'Buffer 4/1');
    Ln('Buffer 4/1',             'Mot 7/1');
    Ln('Zeros redondance/1',     'Mot 7/2');
    Ln('Mot 7/1',                'Unbuffer 7/1');
    Ln('Unbuffer 7/1',           'Codeur C(7,4)/1');
    Ln('Codeur C(7,4)/1',        'cTx/1');
    Ln('Codeur C(7,4)/1',        'Mapping/1');
    Ln('Mapping/1',              'Decalage/1');
    Ln('Decalage/1',             'Surechantillonnage/1');
    Ln('Surechantillonnage/1',   'Canal/1');
    Ln('Bruit/1',                'Canal/2');
    Ln('Canal/1',                'Integrateur/1');
    Ln('Integrateur/1',          'Phase/1');
    Ln('Phase/1',                'Echantillonneur/1');
    Ln('Echantillonneur/1',      'z/1');
    Ln('Echantillonneur/1',      'Decision/1');
    Ln('Seuil/1',                'Decision/2');
    Ln('Decision/1',             'VersDouble/1');
    Ln('VersDouble/1',           'cRx/1');
    Ln('VersDouble/1',           'Alignement mots/1');
    Ln('Alignement mots/1',      'Decodeur C(7,4)/1');
    Ln('Decodeur C(7,4)/1',      'Prelevement mot/1');
    Ln('Prelevement mot/1',      'Colonne/1');
    Ln('Colonne/1',              'Unbuffer 4/1');
    Ln('Unbuffer 4/1',           'rx/1');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end