function teste_descida_animado()
    epsilon = 0.001;
    [funcao, nome_funcao, x0] = obter_funcao(1);
    fprintf('\nFuncao: %s\n', nome_funcao);

    [x_otimo, historico_x] = metodo_descida_mais_rapida(funcao, x0, epsilon);
    fprintf('Descida mais rapida\n');
    fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
    fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
    plotar_resultado_animado(funcao, nome_funcao, x_otimo, historico_x, 'Descida mais rapida');
    
end

function plotar_resultado_2d(funcao, nome, x_otimo, x_historico, nome_metodo)
    % Malha para curvas de n�vel
    [X1, X2] = meshgrid(-2:0.1:2, -2:0.1:2);
    Z = arrayfun(@(i,j) funcao([i,j]), X1, X2);
    
    figure('Name', ['An�lise: ' nome, ' | M�todo: ', nome_metodo]);
    
    % Curvas de N�vel
    subplot(1, 2, 1);
    contour(X1, X2, Z, 20); hold on;
    plot(x_historico(:,1), x_historico(:,2), 'r-o', 'LineWidth', 1.5);
    plot(x_otimo(1), x_otimo(2), 'g*', 'MarkerSize', 10);
    title(['Curvas de N�vel: ' nome]); grid on;
    
    % Superf�cie 3D
    subplot(1, 2, 2);
    surf(X1, X2, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.7); hold on;
    plot3(x_historico(:,1), x_historico(:,2), arrayfun(@(i) funcao([x_historico(i,1), x_historico(i,2)]), 1:size(x_historico,1)), 'r-o');
    title('Vis�o 3D'); view(45, 30); grid on;
end

function plotar_resultado_animado(funcao, nome_funcao, x_otimo, hist, nome_metodo)
    velocidade = 0.05; % Ajuste da velocidade da animação (em segundos)

    % 1. Configura��o da malha din�mica
    min_x1 = min(hist(:,1)); max_x1 = max(hist(:,1));
    min_x2 = min(hist(:,2)); max_x2 = max(hist(:,2));
    
    range_x1 = max_x1 - min_x1;
    range_x2 = max_x2 - min_x2;
    if range_x1 == 0, range_x1 = 2; end
    if range_x2 == 0, range_x2 = 2; end
    
    x1_vec = linspace(min_x1 - range_x1, max_x1 + range_x1, 100);
    x2_vec = linspace(min_x2 - range_x2, max_x2 + range_x2, 100);
    
    [X1, X2] = meshgrid(x1_vec, x2_vec);
    Z = arrayfun(@(i,j) funcao([i,j]), X1, X2);
    
    figure('Name', ['Anima��o: ' nome_funcao, ' | M�todo: ', nome_metodo], 'Color', 'w');
    
    % --- Prepara��o Subplot 1: Contorno ---
    subplot(1, 2, 1);
    z_min = max(min(Z(:)), 0.01); 
    z_max = max(Z(:));
    niveis = logspace(log10(z_min), log10(z_max), 15);
    contour(X1, X2, Z, niveis); hold on; grid on;
    
    h_path_2d = plot(NaN, NaN, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 4);
    h_title1 = title('Curva de n�vel - Iniciando...');
    xlabel('x1'); ylabel('x2');
    
    % --- Prepara��o Subplot 2: Superf�cie 3D ---
    subplot(1, 2, 2);
    surf(X1, X2, Z, 'EdgeColor', 'none', 'FaceAlpha', 0.5); hold on; grid on;
    h_path_3d = plot3(NaN, NaN, NaN, 'r-o', 'LineWidth', 1.5, 'MarkerSize', 4);
    h_title2 = title('Vis�o 3D - Iniciando...');
    view(20, 30); xlabel('x1'); ylabel('x2'); zlabel('f(x)');

    % --- Loop de Anima��o ---
    num_passos = size(hist, 1); 

    for k = 1:num_passos
        set(h_path_2d, 'XData', hist(1:k, 1), 'YData', hist(1:k, 2));
        z_vals = arrayfun(@(i) funcao(hist(i,:)), 1:k);
        set(h_path_3d, 'XData', hist(1:k, 1), 'YData', hist(1:k, 2), 'ZData', z_vals);
        set(h_title1, 'String', sprintf('Curva de n�vel '));
        set(h_title2, 'String', sprintf('Vis�o 3D | Passo: %d/%d', k, num_passos));
        drawnow;
        pause(velocidade);
    end
    
    % --- FINALIZA��O: Destacar o �timo ---
    f_opt = funcao(x_otimo);
    
    % Subplot 1 (2D)
    subplot(1, 2, 1);
    plot(x_otimo(1), x_otimo(2), 'kp', 'MarkerSize', 15, 'MarkerFaceColor', 'y', 'LineWidth', 2);
    %text(x_otimo(1), x_otimo(2), sprintf(' x*=[%.3f, %.3f]', x_otimo(1), x_otimo(2)), 'FontSize', 10, 'FontWeight', 'bold');
    title(sprintf('x1: %.6f | x2: %.6f | f(x*): %.8f', x_otimo(1), x_otimo(2), f_opt));
    
    % Subplot 2 (3D)
    subplot(1, 2, 2);
    plot3(x_otimo(1), x_otimo(2), f_opt, 'kp', 'MarkerSize', 15, 'MarkerFaceColor', 'y', 'LineWidth', 2);
    title(sprintf('Passos: %d', num_passos));

    % Mantem a janela aberta ate o usuario fecha-la manualmente
    uiwait(gcf);
end

function [funcao, nome, x0] = obter_funcao(opcao)
    n_total = 4;        
    if opcao == 0 || opcao > n_total
        opcao = randi(n_total);
    end  
    
    switch opcao
        case 1,  funcao = @(x) 100*(x(2) - x(1)^2)^2 + (1 - x(1))^2;
                 nome = 'Rosenbrock (2D)'; 
                 x0 = [-1.5, 1.0];
                               
        case 2,  funcao = @(x) 2*x(1)^2 + x(2)^2 - 2*x(1); 
                 nome = 'Quadr�tica (2x1^2 + x2^2 - 2x1)'; 
                 x0 = [0, 0];
                 
        case 3,  funcao = @(x) x(1)^2 + 2*x(2)^2;
                 nome = 'Elipse (x1^2 + 2x2^2)'; 
                 x0 = [2, 2];
                 
        case 4,  funcao = @(x) (x(1) - 1)^2 + 2*(x(2) - 1)^2;
                 nome = 'Deslocada ((x1-1)^2 + 2(x2-1)^2)'; 
                 x0 = [0, 0];
                 
        otherwise, funcao = @(x) 100*(x(2) - x(1)^2)^2 + (1 - x(1))^2;
                 nome = 'Rosenbrock (2D)'; 
                 x0 = [-1.2, 1.0];
    end
end




function teste_descida()
    epsilon = 0.001;

    plotar_um_ou_varios = 0;
    
    if plotar_um_ou_varios == 1
        
        for i = 1:5
            [funcao, nome_funcao, x0] = obter_funcao(i);
            fprintf('\nFuncao: %s\n', nome_funcao);
            
            [x_otimo, historico_x] = metodo_descida_mais_rapida(funcao, x0, epsilon);
            fprintf('Descida mais rapida\n');
            fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
            fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
            plotar_resultado_2d(funcao, nome_funcao, x_otimo, historico_x);
            
            
            [x_otimo, historico_x] = metodo_aproximacao_quadratica(funcao, x0, epsilon);
            fprintf('Aproximacao quadratica\n');
            fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
            fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
            plotar_resultado_2d(funcao, nome_funcao, x_otimo, historico_x);
            
            
            [x_otimo, historico_x] = metodo_gradiente_conjugado(funcao, x0, epsilon);
            fprintf('Gradiente conjugado\n');
            fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
            fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
            plotar_resultado_2d(funcao, nome_funcao, x_otimo, historico_x);
            
        end
        
    else
        [funcao, nome_funcao, x0] = obter_funcao(1);
        fprintf('\nFuncao: %s\n', nome_funcao);
        
        [x_otimo, historico_x] = metodo_descida_mais_rapida(funcao, x0, epsilon);
        fprintf('Descida mais rapida\n');
        fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
        fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
        plotar_resultado_2d(funcao, nome_funcao, x_otimo, historico_x);
        

        [x_otimo, historico_x] = metodo_aproximacao_quadratica(funcao, x0, epsilon);
        fprintf('Aproximacao quadratica\n');
        fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
        fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
        plotar_resultado_2d(funcao, nome_funcao, x_otimo, historico_x);
        
        
        [x_otimo, historico_x] = metodo_gradiente_conjugado(funcao, x0, epsilon);
        fprintf('Gradiente conjugado\n');
        fprintf('�timo encontrado: [%s]\n', num2str(x_otimo));
        fprintf('Valor f(x*): %.8f\n', funcao(x_otimo));
        plotar_resultado_2d(funcao, nome_funcao, x_otimo, historico_x);
    
        
    end
    
end
