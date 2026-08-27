function dicotomia(funcao, a, b, epsilon) {
     const iteracoes = [];
     const delta = epsilon / 10;
     let k = 0;
    while (Math.abs(b - a) > epsilon) {
        k++;
        centro = (a + b) / 2;
        x1 = centro - epsilon/10;
        x2 = centro + epsilon/10;
        
        f1 = funcao(x1);
        f2 = funcao(x2);
        
        if (f1 > f2)
            a = x1;
        else
            b = x2;
          iteracoes.push({ k, x1, x2, f1, f2, a, b, largura: b - a });
    }
    return { min: (a + b) / 2, iteracoes: iteracoes };
}