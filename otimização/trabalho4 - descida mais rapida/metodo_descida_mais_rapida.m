function [x_otimo, xk_historico] = metodo_descida_mais_rapida(funcao, x0, epsilon)
    xk = x0;
    x_ant = x0;
    
    n = length(x0);    
    max_iter = 10000;
    
    delta_x = 0.001;
    
    xk_historico = [xk];
    
    for k = 1:max_iter
        g = gradiente(funcao, xk, epsilon);
        norm_g = norm(g);  %modulo gradiente 
        if (norm_g <= epsilon)
            break;
        end
        
        if (mod(k, n) == 0)  %quebra de condicionamento k multplo de n
            S = (xk-x_ant)/norm(xk-x_ant);%
            f_lambda = @(lambda) funcao(xk+lambda*S);
            [a, b] = regiao_busca(f_lambda, xk(1), delta_x);
            lambda_otimo = metodo_dsc(f_lambda, a, b, epsilon);
            x_ant = xk;
            xk_historico = [xk_historico; xk];
            xk = xk+lambda_otimo*S;            
        else
            du = -g/norm_g; 
            f_lambda = @(lambda) funcao(xk+lambda*du); 
            [a, b] = regiao_busca(f_lambda, xk(1), delta_x); 
            lambda_otimo = metodo_dsc(f_lambda, a, b, epsilon); %dicotomia, dsc , seção aurea
            xk = xk+lambda_otimo*du; 
            xk_historico = [xk_historico; xk];
        end
    end
    
    x_otimo = xk;
end




