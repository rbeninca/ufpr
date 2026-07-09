//funcao = @(x) (x - 3).^2 + 0.2;
funcao = (x) => { return (x - 3)**2 + 0.2; };

//Intervalo inicial
a = 2.0;
b = 4.5;

epsilon = 0.1; // precisão

delta = epsilon / 10;  

k = 0;




 busca_min_dicotomia = (funcao, a, b, epsilon)=> {
    k=0;
    while (Math.abs(b - a) > epsilon) {
        k=k+1;
        centro = (a + b) / 2;
        x1 = centro - epsilon/10;
        x2 = centro + epsilon/10;

        f1 = funcao(x1);
        f2 = funcao(x2);
        
        if (f1 > f2)
            a = x1;
        else
            b = x2;
        
        //fprintf('Intervalo final: [%.6f, %.6f] (largura = %.6f)\n', a, b, b - a);
        console.log(`Intervalo : [${a}, ${b}] (largura = ${b - a})`);
        
}
    
    
    return min = (a + b) / 2;
 }

 busca_min_dicotomia(funcao, a, b, epsilon);
