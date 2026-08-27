function dicotomia_passo_a_passo()

% Função de exemplo
funcao = @(x) (x - 3).^2 + 0.2;

% Intervalo inicial
a = 2.0;
b = 4.5;

% Parâmetro de precisão
epsilon = 0.1;

delta = epsilon / 10;  

k = 0;

while abs(b - a) > epsilon
    k = k + 1;
    % Cálculo dos pontos da iteração
    meio = (a + b) / 2;
    x1 = meio - delta;
    x2 = meio + delta;
    f1 = funcao(x1);
    f2 = funcao(x2);


    if f1 > f2
        decisao = 'Descarta a esquerda';
        novo_a = x1;
        novo_b = b;
    else
        decisao = 'Descarta a direita';
        novo_a = a;
        novo_b = x2;
    end

    % Imprime os valores da iteração no console
    fprintf('Iteração %2d | a=%.6f b=%.6f | x1=%.6f x2=%.6f | f(x1)=%.6f f(x2)=%.6f | %s\n', ...
        k, a, b, x1, x2, f1, f2, decisao);

    % Gera curva da função
    X = linspace(1.7, 4.8, 500);
    Y = funcao(X);

    % Cria uma nova figura para esta iteração
    figure(k);
    plot(X, Y, 'LineWidth', 1.5);
    hold on;
    grid on;

    % Linhas verticais do intervalo atual
    yl = ylim;
    plot([a a], yl, '--', 'LineWidth', 1.2);
    plot([b b], yl, '--', 'LineWidth', 1.2);

    % Pontos x1, x2 e mínimo real
    plot(x1, funcao(x1), 'o', 'MarkerSize', 8, 'LineWidth', 1.5);
    plot(x2, funcao(x2), 'o', 'MarkerSize', 8, 'LineWidth', 1.5);
    plot(3, funcao(3), '*', 'MarkerSize', 10, 'LineWidth', 1.5);

    % Rótulos
    text(a, funcao(a)+0.05, 'a');
    text(b, funcao(b)+0.05, 'b');
    text(x1, funcao(x1)+0.05, 'x1');
    text(x2, funcao(x2)+0.05, 'x2');
    text(3, funcao(3)+0.05, 'mínimo');

    title(sprintf('Iteração %d - %s - Novo intervalo [%.6f, %.6f] (largura = %.6f)', ...
        k, decisao, novo_a, novo_b, novo_b - novo_a));
    xlabel('x');
    ylabel('f(x)');
    hold off;
    drawnow;

    % Atualiza o intervalo para a próxima iteração
    a = novo_a;
    b = novo_b;
end

min_aprox = (a + b) / 2;
fprintf('Convergiu em %d iterações.\n', k);
fprintf('Intervalo final: [%.6f, %.6f] (largura = %.6f)\n', a, b, b - a);
fprintf('Mínimo aproximado: x = %.6f (real: x = 3)\n', min_aprox);

end