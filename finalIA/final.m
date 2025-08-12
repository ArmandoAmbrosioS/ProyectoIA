function u = controlador_x1x2(x1, x2)
    % Controlador difuso manual para x1 y x2
    % Compatible con generación de código
    
    % Calcular error de posición
    error_pos = x1 - pi;
    
    % Saturar entradas
    error_pos = max(min(error_pos, 0.2), -0.2);
    vel_barra = max(min(x2, 0.5), -0.5);
    
    % Evaluar controlador difuso manualmente
    u = evaluar_difuso_manual(error_pos, vel_barra);
    
    % Saturar salida
    u = max(min(u, 24), -24);
end

function u = evaluar_difuso_manual(error_pos, vel_barra)
    % Implementación manual del sistema difuso
    
    % === FUZZIFICACIÓN ===
    % Funciones de membresía para error_pos [-0.2, 0.2]
    mu_error = calcular_membresia_error(error_pos);
    
    % Funciones de membresía para vel_barra [-0.5, 0.5]
    mu_vel = calcular_membresia_velocidad(vel_barra);
    
    % === INFERENCIA ===
    % Evaluar reglas difusas
    u = evaluar_reglas_difusas(mu_error, mu_vel);
end

function mu = calcular_membresia_error(error_pos)
    % Funciones de membresía triangulares para error de posición
    % [NL, NM, ZE, PM, PL]
    
    mu = zeros(1, 5);
    
    % NL: Negativo Large [-0.2, -0.2, -0.1]
    if error_pos <= -0.1
        mu(1) = 1;
    elseif error_pos > -0.1 && error_pos < -0.05
        mu(1) = (-0.05 - error_pos) / 0.05;
    end
    
    % NM: Negativo Medium [-0.2, -0.1, 0]
    if error_pos >= -0.2 && error_pos <= -0.1
        mu(2) = (error_pos + 0.2) / 0.1;
    elseif error_pos > -0.1 && error_pos < 0
        mu(2) = -error_pos / 0.1;
    end
    
    % ZE: Zero [-0.05, 0, 0.05]
    if error_pos >= -0.05 && error_pos <= 0
        mu(3) = (error_pos + 0.05) / 0.05;
    elseif error_pos > 0 && error_pos <= 0.05
        mu(3) = (0.05 - error_pos) / 0.05;
    end
    
    % PM: Positivo Medium [0, 0.1, 0.2]
    if error_pos >= 0 && error_pos < 0.1
        mu(4) = error_pos / 0.1;
    elseif error_pos >= 0.1 && error_pos <= 0.2
        mu(4) = (0.2 - error_pos) / 0.1;
    end
    
    % PL: Positivo Large [0.1, 0.2, 0.2]
    if error_pos >= 0.05
        if error_pos < 0.1
            mu(5) = (error_pos - 0.05) / 0.05;
        else
            mu(5) = 1;
        end
    end
end

function mu = calcular_membresia_velocidad(vel_barra)
    % Funciones de membresía triangulares para velocidad
    % [NL, NM, ZE, PM, PL]
    
    mu = zeros(1, 5);
    
    % NL: Negativo Large [-0.5, -0.5, -0.25]
    if vel_barra <= -0.25
        mu(1) = 1;
    elseif vel_barra > -0.25 && vel_barra < -0.125
        mu(1) = (-0.125 - vel_barra) / 0.125;
    end
    
    % NM: Negativo Medium [-0.5, -0.25, 0]
    if vel_barra >= -0.5 && vel_barra <= -0.25
        mu(2) = (vel_barra + 0.5) / 0.25;
    elseif vel_barra > -0.25 && vel_barra < 0
        mu(2) = -vel_barra / 0.25;
    end
    
    % ZE: Zero [-0.1, 0, 0.1]
    if vel_barra >= -0.1 && vel_barra <= 0
        mu(3) = (vel_barra + 0.1) / 0.1;
    elseif vel_barra > 0 && vel_barra <= 0.1
        mu(3) = (0.1 - vel_barra) / 0.1;
    end
    
    % PM: Positivo Medium [0, 0.25, 0.5]
    if vel_barra >= 0 && vel_barra < 0.25
        mu(4) = vel_barra / 0.25;
    elseif vel_barra >= 0.25 && vel_barra <= 0.5
        mu(4) = (0.5 - vel_barra) / 0.25;
    end
    
    % PL: Positivo Large [0.25, 0.5, 0.5]
    if vel_barra >= 0.125
        if vel_barra < 0.25
            mu(5) = (vel_barra - 0.125) / 0.125;
        else
            mu(5) = 1;
        end
    end
end

function u = evaluar_reglas_difusas(mu_error, mu_vel)
    % Evaluar las 25 reglas difusas y hacer defuzzificación
    
    % Centros de las funciones de salida
    centros = [-20, -12, 0, 12, 20];  % [NL, NM, ZE, PM, PL]
    
    % Matriz de reglas: salida para cada combinación [error, velocidad]
    % Filas: error (NL, NM, ZE, PM, PL)
    % Columnas: velocidad (NL, NM, ZE, PM, PL)
    reglas = [
        1, 1, 2, 2, 3;  % Error NL
        1, 2, 2, 3, 4;  % Error NM  
        2, 3, 3, 3, 4;  % Error ZE
        2, 3, 4, 4, 5;  % Error PM
        3, 4, 4, 5, 5;  % Error PL
    ];
    
    % Calcular activación de cada regla y acumular salidas
    numerador = 0;
    denominador = 0;
    
    for i = 1:5  % error
        for j = 1:5  % velocidad
            % Activación de la regla (mínimo)
            activacion = min(mu_error(i), mu_vel(j));
            
            if activacion > 0
                % Índice de salida según la regla
                salida_idx = reglas(i, j);
                centro_salida = centros(salida_idx);
                
                % Acumular para defuzzificación por centroide
                numerador = numerador + activacion * centro_salida;
                denominador = denominador + activacion;
            end
        end
    end
    
    % Defuzzificación por centroide
    if denominador > 0
        u = numerador / denominador;
    else
        u = 0;  % Salida por defecto
    end
end