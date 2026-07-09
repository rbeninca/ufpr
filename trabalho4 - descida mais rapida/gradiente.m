function g = gradiente(funcao, x, epsilon)
    g = zeros(1, length(x));
    for i=1: length(x)
        a = x(i);
        x(i) = a+epsilon;
        b = funcao(x);
        x(i) = a-epsilon;
        c = funcao(x);
        g(i) = (b-c)/(2*epsilon);
        x(i) = a;
    end      
end