function mdl = construire_modele_qpsk_filtre()
%CONSTRUIRE_MODELE_QPSK_FILTRE  Chaîne QPSK suréchantillonnée avec filtre de
%   mise en forme et filtre adapté (partie 6).
%
%   Source (Tb) -> Buffer 2 -> mapping de Gray (Ts = 2Tb)
%     -> un symbole tous les L échantillons, zéros ailleurs (Te = Ts/L)
%     -> filtre de mise en forme hE -> + bruit complexe (N0/2 par voie et par échantillon)
%     -> filtre adapté hE(-t) -> retard dPhase -> échantillonnage (Ts)
%     -> décision sur le signe de I et Q -> Unbuffer (Tb)
%
%   hE étant d'énergie unité, l'échantillon prélevé vaut le symbole émis en
%   l'absence de bruit et d'IES, et le bruit y garde la variance N0/2 par voie.
%   Variables : Tb, Ts, Te, L, hE, N0, graine, dPhase, Nsim, Nlog.
%   Sorties : out.tx, out.rx, out.zsym (échantillons de décision, Ts),
%   out.ye (sortie du filtre adapté, Te, Nlog derniers points).

    try
        load_system('dspbuff3');
    catch
        error('Bibliothèque "dspbuff3" (Buffer / Unbuffer) introuvable.');
    end
    mdl = 'modele_qpsk_filtre';
    if bdIsLoaded(mdl), close_system(mdl, 0); end
    if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
    new_system(mdl);  open_system(mdl);
    set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
        'FixedStep', 'Te', 'StopTime', '(Nsim-1)*Tb', 'ReturnWorkspaceOutputs', 'on');
    Ln = @(a, b) add_line(mdl, a, b, 'autorouting', 'on');
    LO = 'simulink/Logic and Bit Operations/Relational Operator';
    DT = 'simulink/Signal Attributes/Data Type Conversion';

    % --- Source et mapping de Gray ----------------------------------------------
    ajouter_source_binaire(mdl, 'Source', [20 80 140 130], '0.5', 'graine');
    ajouter_to_workspace(mdl, 'tx', [180 10 240 40]);
    add_block('dspbuff3/Buffer', [mdl '/Buffer 2'], 'N', '2', 'Position', [180 85 230 125]);
    add_block('simulink/Math Operations/Reshape', [mdl '/Vecteur'], ...
        'OutputDimensionality', '1-D array', 'Position', [260 85 300 125]);
    add_block('simulink/Signal Routing/Demux', [mdl '/b1 b2'], 'Outputs', '2', 'Position', [330 75 335 135]);
    add_block('simulink/Math Operations/Gain', [mdl '/Gain I'], 'Gain', '2/sqrt(2)', 'Position', [370 65 410 95]);
    add_block('simulink/Math Operations/Bias', [mdl '/Biais I'], 'Bias', '-1/sqrt(2)', 'Position', [430 65 470 95]);
    add_block('simulink/Math Operations/Gain', [mdl '/Gain Q'], 'Gain', '2/sqrt(2)', 'Position', [370 115 410 145]);
    add_block('simulink/Math Operations/Bias', [mdl '/Biais Q'], 'Bias', '-1/sqrt(2)', 'Position', [430 115 470 145]);
    add_block('simulink/Math Operations/Real-Imag to Complex', [mdl '/Symbole'], 'Position', [500 85 540 125]);
    Ln('Source/1', 'tx/1');  Ln('Source/1', 'Buffer 2/1');
    Ln('Buffer 2/1', 'Vecteur/1');  Ln('Vecteur/1', 'b1 b2/1');
    Ln('b1 b2/1', 'Gain I/1');  Ln('Gain I/1', 'Biais I/1');  Ln('Biais I/1', 'Symbole/1');
    Ln('b1 b2/2', 'Gain Q/1');  Ln('Gain Q/1', 'Biais Q/1');  Ln('Biais Q/1', 'Symbole/2');

    % --- Suréchantillonnage par insertion de zéros et mise en forme -----------------
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Vers Te'], ...
        'OutPortSampleTime', 'Te', 'Position', [570 88 620 122]);
    add_block('simulink/Sources/Pulse Generator', [mdl '/Peigne'], ...
        'PulseType', 'Sample based', 'Amplitude', '1', 'Period', 'L', ...
        'PulseWidth', '1', 'PhaseDelay', '0', 'SampleTime', 'Te', 'Position', [570 150 620 180]);
    add_block('simulink/Math Operations/Product', [mdl '/Insertion zeros'], ...
        'Inputs', '**', 'Position', [650 95 680 145]);
    add_block('simulink/Discrete/Discrete FIR Filter', [mdl '/Mise en forme'], ...
        'Coefficients', 'hE', 'Position', [710 100 790 140]);
    Ln('Symbole/1', 'Vers Te/1');  Ln('Vers Te/1', 'Insertion zeros/1');
    Ln('Peigne/1', 'Insertion zeros/2');  Ln('Insertion zeros/1', 'Mise en forme/1');

    % --- Canal : bruit complexe ------------------------------------------------------
    add_block('simulink/Sources/Random Number', [mdl '/Bruit I'], 'Mean', '0', 'Variance', 'N0/2', ...
        'Seed', 'graine+1', 'SampleTime', 'Te', 'Position', [710 180 760 210]);
    add_block('simulink/Sources/Random Number', [mdl '/Bruit Q'], 'Mean', '0', 'Variance', 'N0/2', ...
        'Seed', 'graine+2', 'SampleTime', 'Te', 'Position', [710 230 760 260]);
    add_block('simulink/Math Operations/Real-Imag to Complex', [mdl '/Bruit complexe'], 'Position', [790 195 830 245]);
    add_block('simulink/Math Operations/Sum', [mdl '/Canal'], 'Inputs', '++', 'Position', [860 105 890 135]);
    Ln('Bruit I/1', 'Bruit complexe/1');  Ln('Bruit Q/1', 'Bruit complexe/2');
    Ln('Mise en forme/1', 'Canal/1');  Ln('Bruit complexe/1', 'Canal/2');

    % --- Réception : filtre adapté et échantillonnage --------------------------------
    add_block('simulink/Discrete/Discrete FIR Filter', [mdl '/Filtre adapte'], ...
        'Coefficients', 'fliplr(hE)', 'Position', [920 100 1000 140]);
    add_block('simulink/Sinks/To Workspace', [mdl '/ye'], 'VariableName', 'ye', ...
        'SaveFormat', 'Array', 'MaxDataPoints', 'Nlog', 'Position', [1030 20 1090 50]);
    add_block('simulink/Discrete/Delay', [mdl '/Phase'], 'DelayLength', 'dPhase', ...
        'Position', [1030 103 1080 137]);
    add_block('simulink/Signal Attributes/Rate Transition', [mdl '/Echantillonneur'], ...
        'OutPortSampleTime', 'Ts', 'Position', [1110 103 1160 137]);
    ajouter_to_workspace(mdl, 'zsym', [1190 20 1250 50]);
    Ln('Canal/1', 'Filtre adapte/1');  Ln('Filtre adapte/1', 'ye/1');
    Ln('Filtre adapte/1', 'Phase/1');  Ln('Phase/1', 'Echantillonneur/1');
    Ln('Echantillonneur/1', 'zsym/1');

    % --- Décision et remise en série --------------------------------------------------
    add_block('simulink/Math Operations/Complex to Real-Imag', [mdl '/Voies'], 'Position', [1190 95 1230 145]);
    add_block('simulink/Sources/Constant', [mdl '/Zero'], 'Value', '0', 'SampleTime', 'inf', ...
        'Position', [1190 180 1220 200]);
    add_block(LO, [mdl '/Decision I'], 'Operator', '>', 'Position', [1260 80 1290 110]);
    add_block(LO, [mdl '/Decision Q'], 'Operator', '>', 'Position', [1260 140 1290 170]);
    add_block(DT, [mdl '/d1'], 'OutDataTypeStr', 'double', 'Position', [1310 80 1350 110]);
    add_block(DT, [mdl '/d2'], 'OutDataTypeStr', 'double', 'Position', [1310 140 1350 170]);
    add_block('simulink/Signal Routing/Mux', [mdl '/Paire'], 'Inputs', '2', 'Position', [1380 80 1385 170]);
    add_block('simulink/Math Operations/Reshape', [mdl '/Colonne'], ...
        'OutputDimensionality', 'Column vector (2-D)', 'Position', [1410 105 1450 145]);
    add_block('dspbuff3/Unbuffer', [mdl '/Unbuffer 2'], 'Position', [1480 105 1530 145]);
    ajouter_to_workspace(mdl, 'rx', [1560 110 1620 140]);
    Ln('Echantillonneur/1', 'Voies/1');
    Ln('Voies/1', 'Decision I/1');  Ln('Zero/1', 'Decision I/2');
    Ln('Voies/2', 'Decision Q/1');  Ln('Zero/1', 'Decision Q/2');
    Ln('Decision I/1', 'd1/1');  Ln('Decision Q/1', 'd2/1');
    Ln('d1/1', 'Paire/1');  Ln('d2/1', 'Paire/2');
    Ln('Paire/1', 'Colonne/1');  Ln('Colonne/1', 'Unbuffer 2/1');  Ln('Unbuffer 2/1', 'rx/1');

    save_system(mdl);
    fprintf('Modèle "%s.slx" construit.\n', mdl);
end