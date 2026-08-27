function [x_otimo, xk_historico] = metodo_aproximacao_quadratica(funcao, x0, epsilon)
    xk = x0;
    x_ant = xk;
    xk_historico = xk;
    
    n = length(x0);
    max_iter = 10000;
    delta_x = 0.001;
    
    for k = 1:max_iter
        g = gradiente(funcao, xk, epsilon);
        H = hessiana(funcao, xk, epsilon);
        norm_g = norm(g);
        if norm_g <= epsilon
            break;
        end
        
        if mod(k, n) == 0 && k > 1
            S = (xk-x_ant)/norm(xk-x_ant);
            f_lambda = @(lambda) funcao(xk+lambda*S);
            [a, b] = regiao_busca(f_lambda, 0, delta_x);
            lambda_otimo = metodo_dsc(f_lambda, a, b, epsilon); 
            x_ant = xk;
            xk_historico = [xk_historico; xk];
            xk = xk+lambda_otimo*S;            
        else            
            Sk = -g/norm_g;
            numerador = -g*Sk';
            denominador = Sk*H*Sk';
            lambda_q = numerador/denominador;            
            xk = xk+lambda_q*Sk;
            xk_historico = [xk_historico; xk];
        end
    end    
    x_otimo = xk;
end