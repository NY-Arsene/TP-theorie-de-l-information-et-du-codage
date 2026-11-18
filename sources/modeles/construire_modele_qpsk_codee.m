function mdl = construire_modele_qpsk_codee()
%CONSTRUIRE_MODELE_QPSK_CODEE  Chaîne QPSK avec code C(7,4) (partie 5, Q6).
%   Identique à la chaîne de la partie 4, mais le détecteur binaire est
%   remplacé par le modem QPSK : les bits codés (cadence Tc) sont regroupés
%   par deux au fil de l'eau (Buffer 2), sans bit de bourrage ; deux mots-codes
%   de 7 bits donnent exactement 7 symboles.
%   Variables : Tb, Tc, Tpas, Tsym, Nsim, N0, graine, mappingGray, phaseC, dAlign.
%   Sorties : out.tx, out.rx, out.cTx, out.cRx, out.ssym, out.rsym.

    try
        load_system('dspbuff3');
    catch
        error('Bibliothèque "dspbuff3" (Buffer / Unbuffer) introuvable.');
    end
    mdl = 'modele_qpsk_codee';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tpas', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');
    Ln = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');

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
    ajouter_modem_qpsk(mdl, 'Modem QPSK et canal', [600 105 760 165]);
    ajouter_to_workspace(mdl, 'cRx', [800 20 860 50]);
    add_block('simulink/Discrete/Delay', [mdl '/Alignement mots'], ...
        'DelayLength', 'dAlign', 'Position', [800 118 850 152]);
    ajouter_decodeur_hamming(mdl, 'Decodeur C(7,4)', [880 105 990 165]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Prelevement mot'], ...
        'OutPortSampleTime', '4*Tb', 'Position', [1020 118 1070 152]);
    add_block('simulink/Math Operations/Reshape', [mdl '/Colonne'], ...
        'OutputDimensionality', 'Column vector (2-D)', 'Position', [1100 118 1150 152]);
    add_block('dspbuff3/Unbuffer', [mdl '/Unbuffer 4'], 'Position', [1180 118 1230 152]);
    ajouter_to_workspace(mdl, 'rx', [1260 120 1320 150]);

    Ln('Source/1',              'tx/1');
    Ln('Source/1',              'Buffer 4/1');
    Ln('Buffer 4/1',            'Mot 7/1');
    Ln('Zeros redondance/1',    'Mot 7/2');
    Ln('Mot 7/1',               'Unbuffer 7/1');
    Ln('Unbuffer 7/1',          'Codeur C(7,4)/1');
    Ln('Codeur C(7,4)/1',       'cTx/1');
    Ln('Codeur C(7,4)/1',       'Modem QPSK et canal/1');
    Ln('Modem QPSK et canal/1', 'cRx/1');
    Ln('Modem QPSK et canal/1', 'Alignement mots/1');
    Ln('Alignement mots/1',     'Decodeur C(7,4)/1');
    Ln('Decodeur C(7,4)/1',     'Prelevement mot/1');
    Ln('Prelevement mot/1',     'Colonne/1');
    Ln('Colonne/1',             'Unbuffer 4/1');
    Ln('Unbuffer 4/1',          'rx/1');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end