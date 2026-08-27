%define uma função seno, e plota o gráfico dela no intervalo de 0 a 2*pi
function teste()
    % Define a função seno
    funcao = @(x) sin(x);
    % Define o intervalo de 0 a 2*pi
    a = 0;
    b = 2*pi;
    % Define a precisão desejada
    epsilon = 0.001;
    % Chama o método de descida para encontrar o mínimo da função seno
    min = metodo_dsc(funcao, a, b, epsilon);
    % Exibe o resultado encontrado
    fprintf('Mínimo encontrado: %.4f\n', min);      
    plot(linspace(a, b, 100), funcao(linspace(a, b, 100)));
% Mantém a janela do gráfico aberta até você fechá-la manualmente.
% Sem isto, o Octave encerra o script e fecha o gráfico junto.
uiwait(gcf);
end