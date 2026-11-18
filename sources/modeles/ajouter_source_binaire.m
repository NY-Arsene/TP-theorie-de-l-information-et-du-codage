function blk = ajouter_source_binaire(sys, nom, pos, exprP, exprGraine)
%AJOUTER_SOURCE_BINAIRE  Ajoute dans le système Simulink 'sys' un
%   sous-système masqué "source binaire" (P(1) = exprP), cadencé à Tb.
%   blk = ajouter_source_binaire(sys, nom, pos, exprP, exprGraine)
%     sys        : modèle ou sous-système parent
%     nom        : nom du bloc créé
%     pos        : position [gauche haut droite bas]
%     exprP      : expression de P(1), ex. 'p1', 'pe', '0.5'
%     exprGraine : expression de la graine, ex. 'graine', 'graine+1'
%   Contenu : Uniform Random Number [0,1] < p  ->  double.

    blk = [sys '/' nom];
    add_block('simulink/Ports & Subsystems/Subsystem', blk, 'Position', pos);
    delete_line(blk, 'In1/1', 'Out1/1');
    delete_block([blk '/In1']);
    set_param([blk '/Out1'], 'Name', 'bits', 'Position', [520 98 550 112]);

    add_block('simulink/Sources/Uniform Random Number', [blk '/Uniforme'], ...
        'Minimum', '0', 'Maximum', '1', ...
        'Seed', 'graine_m', 'SampleTime', 'Tb_m', 'Position', [60 60 120 100]);
    add_block('simulink/Sources/Constant', [blk '/Seuil'], ...
        'Value', 'p_m', 'SampleTime', 'Tb_m', 'Position', [60 130 120 160]);
    add_block('simulink/Logic and Bit Operations/Relational Operator', ...
        [blk '/Comparateur'], 'Operator', '<', 'Position', [200 85 240 125]);
    add_block('simulink/Signal Attributes/Data Type Conversion', ...
        [blk '/VersDouble'], 'OutDataTypeStr', 'double', 'Position', [320 90 400 120]);

    add_line(blk, 'Uniforme/1',    'Comparateur/1', 'autorouting', 'on');
    add_line(blk, 'Seuil/1',       'Comparateur/2', 'autorouting', 'on');
    add_line(blk, 'Comparateur/1', 'VersDouble/1',  'autorouting', 'on');
    add_line(blk, 'VersDouble/1',  'bits/1',        'autorouting', 'on');

    m = Simulink.Mask.create(blk);
    m.Type        = 'Source binaire';
    m.Description = 'Source binaire sans mémoire : P(1) = p, un bit toutes les Tb secondes.';
    m.addParameter('Type', 'edit', 'Name', 'p_m', ...
        'Prompt', 'Probabilité d''émettre un 1', 'Value', exprP);
    m.addParameter('Type', 'edit', 'Name', 'Tb_m', ...
        'Prompt', 'Durée d''un bit Tb (s)', 'Value', 'Tb');
    m.addParameter('Type', 'edit', 'Name', 'graine_m', ...
        'Prompt', 'Graine (Seed)', 'Value', exprGraine);
end