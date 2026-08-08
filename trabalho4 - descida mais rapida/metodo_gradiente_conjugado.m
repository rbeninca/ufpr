function [x_otimo, xk_historico] = metodo_gradiente_conjugado(funcao, x0, epsilon)
    xk = x0;
    xk_ant = xk;
    xk_historico = xk;
    
    n = length(x0);
    max_iter = 10000;
    delta_x = 0.001;
    
    g = gradiente(funcao, xk, epsilon);
    S = -g;
    
    for k = 1:max_iter
        dk=S/norm(S);
        f_lambda = @(lambda) funcao(xk+lambda*dk);
        [a, b] = regiao_busca(f_lambda, 0, delta_x);
        lambda_otimo = metodo_dsc(f_lambda, a, b, epsilon);        
        xk = xk+lambda_otimo*dk;
        xk_historico = [xk_historico; xk];        
        gk_1 = gradiente(funcao, xk, epsilon);
        if norm(gk_1) <= epsilon
            break;
        end

        if mod(k, n) == 0
            S = (xk-xk_ant)/norm(xk-xk_ant);
            xk_ant = xk;
        else
            beta = (norm(gk_1)^2)/(norm(g)^2);
            S = -gk_1+beta*S;
        end
        g = gk_1;
    end    
    x_otimo = xk;
end