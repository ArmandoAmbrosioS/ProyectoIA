function u = ctrl_x1x2(x1, x2)
% Control difuso con estado (x1, x2)
% x1 ~ pi ± 0.2 rad; x2 ~ [-0.5, 0.5] rad/s

persistent fis
if isempty(fis)
    fis = mamfis('Name','FIS_x1x2');

    % Entradas: error de ángulo y velocidad de barra
    fis = addInput(fis, [-0.25 0.25], 'Name','e');
    fis = addMF(fis,'e','trimf',[-0.25 -0.20 -0.10],'Name','NB');
    fis = addMF(fis,'e','trimf',[-0.20 -0.10  0.00],'Name','NS');
    fis = addMF(fis,'e','trimf',[-0.05  0.00  0.05],'Name','ZO');
    fis = addMF(fis,'e','trimf',[ 0.00  0.10  0.20],'Name','PS');
    fis = addMF(fis,'e','trimf',[ 0.10  0.20  0.25],'Name','PB');

    fis = addInput(fis, [-0.6 0.6], 'Name','edot');  % margen leve sobre ±0.5
    fis = addMF(fis,'edot','trimf',[-0.6 -0.4 -0.2],'Name','NB');
    fis = addMF(fis,'edot','trimf',[-0.4 -0.2  0.0],'Name','NS');
    fis = addMF(fis,'edot','trimf',[-0.1  0.0  0.1],'Name','ZO');
    fis = addMF(fis,'edot','trimf',[ 0.0  0.2  0.4],'Name','PS');
    fis = addMF(fis,'edot','trimf',[ 0.2  0.4  0.6],'Name','PB');

    % Salida
    fis = addOutput(fis, [-24 24], 'Name','u');
    fis = addMF(fis,'u','trimf',[-24 -24 -12],'Name','NB');
    fis = addMF(fis,'u','trimf',[-18 -12  -6],'Name','NS');
    fis = addMF(fis,'u','trimf',[ -3   0   3],'Name','ZO');
    fis = addMF(fis,'u','trimf',[  6  12  18],'Name','PS');
    fis = addMF(fis,'u','trimf',[ 12  24  24],'Name','PB');

    % Reglas "PD difuso": la velocidad amortigua (si la barra se mueve hacia la derecha (+), quito algo de u)
    rules = [];
    labels = ["NB","NS","ZO","PS","PB"];
    for i = 1:5  % e
        for j = 1:5  % edot
            % mapa base: u = -e - k*edot (cualitativo)
            idxU = 6 - i;             % invierte por e
            % ajuste por velocidad:
            idxU = idxU - (j-3);      % ZO no altera; PB resta; NB suma
            idxU = max(1, min(5, idxU));
            rules(end+1,:) = [i, j, idxU, 1, 1]; %#ok<AGROW>
        end
    end
    fis = addRule(fis, rules);

    fis.DefuzzificationMethod = "centroid";
end

e    = wrapToPi(x1 - pi);
e    = max(min(e,  0.25), -0.25);
edot = max(min(x2, 0.6), -0.6);

u = evalfis(fis, [e, edot]);
end
