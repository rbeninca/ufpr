%  function main()
%     %funcao = @(x) (x - 3).^2;
%     %funcao = @(x) (x - 3) .* (x - 5);   
%     %funcao = @(x) sin(x)+sin(2*x)
%     %funcao = @(x) sin(x) + x.^2;
%     %funcao = @(x) x .* sin(x);
%     funcao = @(x) x + sin(x);
%     %funcao = @(x) x.^3 - 3.*x      %sela
%     x0 = 3.0;   
%     delta_x = 0.1;
%     %[a, b] = regiao_busca1(funcao, x0, delta_x);
%     
%     x = 0:0.0013:10;
%     y = x + sin(x);
%     plot(x,y)
%     
%     a
%     b
%     
%     %% --- BLOCO DE PLOTAGEM CENTRALIZADO E SIMÉTRICO ---
%     figure('Name', 'Método do Cercamento', 'Position', [300, 200, 800, 500]);
%     
%     % 1. Encontra o centro do vale (aproximado pelo meio de a e b)
%     centro_aprox = (a + b) / 2;
%     
%     % 2. Calcula a distância do centro até o ponto de partida x0
%     distancia_x0 = abs(centro_aprox - x0);
%     
%     % 3. Define limites perfeitamente simétricos ao redor do centro
%     limite_esq = centro_aprox - distancia_x0 - 0.5;
%     limite_dir = centro_aprox + distancia_x0 + 0.5;
%     
%     % Gera 500 pontos para uma curva perfeitamente suave
%     X_total = linspace(limite_esq, limite_dir, 500);
%     Y_total = funcao(X_total);
%     
%     % Desenha a curva da função inteira
%     h1 = plot(X_total, Y_total, 'b-', 'LineWidth', 1.5);
%     hold on;
%     
%     % Desenha a região cercada
%     X_regiao = linspace(a, b, 100);
%     Y_regiao = funcao(X_regiao);
%     h2 = plot(X_regiao, Y_regiao, 'g-', 'LineWidth', 4);
%     
%     ya = funcao(a);
%     yb = funcao(b);
%     limites_y = ylim; 
%     
%     % Linhas verticais
%     h3 = plot([a, a], limites_y, 'r--', 'LineWidth', 1.5);
%     plot([b, b], limites_y, 'r--', 'LineWidth', 1.5);
%     
%     % Pontos A e B
%     h4 = plot(a, ya, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
%     plot(b, yb, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
%     
%     % ADIÇÃO: Marca o ponto de partida x0 para você ver de onde a busca começou
%     h5 = plot(x0, funcao(x0), 'ks', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
%     
%     grid on;
%     xlabel('x');
%     ylabel('f(x)');
%     title('Região de Busca do Mínimo [a, b] (Vista Centralizada)');
%     
%     % Legenda com o x0 incluído
%     legend([h1, h2, h3, h4, h5], 'Curva f(x)', 'Região Cercada [a, b]', 'Limites Verticais', 'Pontos a e b', 'Ponto Inicial x0', 'Location', 'best');
%     hold off;
% end

function [a, b] = regiao_busca(funcao, x0, delta_x)
    k = 1;    
    xk(k) = x0;
    xk(k+1) = x0 + delta_x;
    max_iter = 1000;
    
    if( funcao(xk(k+1)) > funcao(xk(k)) )
        delta_x = -delta_x;
        xk(k+1) = xk(k) + delta_x;
    end
    
    if funcao(xk(k+1)) > funcao(xk(k))
        a = xk(k) - abs(delta_x);   %precisa calcular com o abs(delta_x) pois se iniciar exatamente no min, ele inverte a e b
        b = xk(k) + abs(delta_x);
        return; 
    end
    
    while funcao(xk(k+1)) <= funcao(xk(k)) && k < max_iter
        k = k + 1;
        xk(k+1) = xk(k) + delta_x;     
        
        if abs(funcao(xk(k+1)) - funcao(xk(k))) < 1e-10 %garante que se nao mudar quase nada, para para não travar
            break; 
        end
    end
  
    if(xk(k-1) < xk(k+1))
        a = xk(k-1);
        b = xk(k+1);
    else
        a = xk(k+1);
        b = xk(k-1);
        
    end
    k;
end
