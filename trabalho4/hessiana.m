function h = hessiana(funcao, x, epsilon)
    h = zeros(length(x), length(x));
    for i=1: length(x)
        a = x(i);
        x(i) = a+epsilon;
        m = gradiente(funcao, x, epsilon);
        x(i) = a-epsilon;
        n = gradiente(funcao, x, epsilon);
        h(:,i) = (m-n).'/(2*epsilon);
        x(i) = a;
    end
end