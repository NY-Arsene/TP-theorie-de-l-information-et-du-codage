function mdl = construire_modele_chaine_complete(avecCodage)
%CONSTRUIRE_MODELE_CHAINE_COMPLETE  Chaîne complète de la partie 7 :
%   bits lus dans le workspace (From Workspace) -> [codeur C(7,4)]
%   -> modem QPSK filtré (RRC) + canal à écho et bruit -> [décodeur C(7,4)]
%   -> bits reçus (To Workspace).
%   avecCodage = false : modele_chaine_complete
%   avecCodage = true  : modele_chaine_complete_codee
%   Variables : bits_ws = [t, bits], Tb, Tpas, Te, Tsym, L, hE, hc, N0, graine,
%   dPhase, Nsim, Nlog et, avec codage, Tc, phaseC, dAlign.
%   Sorties : out.rx, out.zsym, out.ye.

    try
        load_system('dspbuff3');
    catch
        error('Bibliothèque "dspbuff3" (Buffer / Unbuffer) introuvable.');
    end
    if avecCodage, mdl = 'modele_chaine_complete_codee'; else, mdl = 'modele_chaine_complete'; end
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Tpas', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');
    Ln = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');

    add_block('simulink/Sources/From Workspace', [mdl '/Bits emis'], ...
        'VariableName', 'bits_ws', 'SampleTime', 'Tb', 'Interpolate', 'off', ...
        'OutputAfterFinalValue', 'Setting to zero', 'Position', [20 95 110 125]);

    if ~avecCodage
        ajouter_modem_qpsk_filtre(mdl, 'Modem QPSK RRC et canal', [160 85 320 135]);
        ajouter_to_workspace(mdl, 'rx', [370 95 430 125]);
        Ln('Bits emis/1', 'Modem QPSK RRC et canal/1');
        Ln('Modem QPSK RRC et canal/1', 'rx/1');
    else
        add_block('dspbuff3/Buffer', [mdl '/Buffer 4'], 'N', '4', 'Position', [150 85 200 125]);
        add_block('simulink/Sources/Constant', [mdl '/Zeros redondance'], ...
            'Value', 'zeros(3,1)', 'SampleTime', '4*Tb', 'Position', [150 160 210 190]);
        add_block('simulink/Math Operations/Matrix Concatenate', [mdl '/Mot 7'], ...
            'NumInputs', '2', 'ConcatenateDimension', '1', 'Position', [250 90 270 180]);
        add_block('dspbuff3/Unbuffer', [mdl '/Unbuffer 7'], 'Position', [300 115 350 155]);
        ajouter_codeur_registre(mdl, 'Codeur C(7,4)', [390 105 500 165]);
        ajouter_modem_qpsk_filtre(mdl, 'Modem QPSK RRC et canal', [540 105 700 165]);
        add_block('simulink/Discrete/Delay', [mdl '/Alignement mots'], ...
            'DelayLength', 'dAlign', 'Position', [740 118 790 152]);
        ajouter_decodeur_hamming(mdl, 'Decodeur C(7,4)', [820 105 930 165]);
        add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Prelevement mot'], ...
            'OutPortSampleTime', '4*Tb', 'Position', [960 118 1010 152]);
        add_block('simulink/Math Operations/Reshape', [mdl '/Colonne'], ...
            'OutputDimensionality', 'Column vector (2-D)', 'Position', [1040 118 1090 152]);
        add_block('dspbuff3/Unbuffer', [mdl '/Unbuffer 4'], 'Position', [1120 118 1170 152]);
        ajouter_to_workspace(mdl, 'rx', [1200 120 1260 150]);
        Ln('Bits emis/1',               'Buffer 4/1');
        Ln('Buffer 4/1',                'Mot 7/1');
        Ln('Zeros redondance/1',        'Mot 7/2');
        Ln('Mot 7/1',                   'Unbuffer 7/1');
        Ln('Unbuffer 7/1',              'Codeur C(7,4)/1');
        Ln('Codeur C(7,4)/1',           'Modem QPSK RRC et canal/1');
        Ln('Modem QPSK RRC et canal/1', 'Alignement mots/1');
        Ln('Alignement mots/1',         'Decodeur C(7,4)/1');
        Ln('Decodeur C(7,4)/1',         'Prelevement mot/1');
        Ln('Prelevement mot/1',         'Colonne/1');
        Ln('Colonne/1',                 'Unbuffer 4/1');
        Ln('Unbuffer 4/1',              'rx/1');
    end

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end