% function main()
%     funcao = @(x) (x - 3).^2;     
%     a = 2.7;
%     b = 3.7;     
%     epsilon = 0.001; 
%     
%     min = metodo_dicotomia(funcao, a, b, epsilon)
% end

function min = metodo_dicotomia(funcao, a, b, epsilon)
    k = 0;
    while abs(b - a) > epsilon
        x1 = (a + b) / 2 - epsilon/20;  %tem que dividir o epsilon por um numero grande para poder andar e nao cair em loop infinito
        x2 = (a + b) / 2 + epsilon/20;
        f1 = funcao(x1);
        f2 = funcao(x2);        
        if f1 > f2
            a = x1;
        else
            b = x2;
        end
        k = k + 1;
    end    
    min = (a + b) / 2;
    k;
end