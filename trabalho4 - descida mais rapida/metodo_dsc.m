% function main()
%     funcao = @(x) (x - 3).^2;     
%     a = 2.7;
%     b = 3.7;     
%     epsilon = 0.001; 
%     
%     min = metodo_dsc1(funcao, a, b, epsilon)
% end

function min = metodo_dsc(funcao, a, b, epsilon)
    k = 1;
    xa = a;
    xc = b;
    xb = (xa+xc)/2;
    
    xq = 0;
    
    max_iter = 1000;
    
    while k < max_iter
        fa = funcao(xa);
        fb = funcao(xb);
        fc = funcao(xc);
            
        num = (xb^2 - xc^2)*fa + (xc^2 - xa^2)*fb + (xa^2 - xb^2)*fc;
        den = (xb - xc)*fa + (xc - xa)*fb + (xa - xb)*fc;
        
        xq = 0.5 * (num/den);
        fq = funcao(xq);
        
        if abs(xq-xb) < epsilon
            min = xq;
            k;
            break;
        end

        %abandona o maior
        if xq > xb
            if fq < fb
                xa = xb;
                xb = xq;
            else
                xc = xq;          
            end
        else
            if fq < fb
                xc = xb;
                xb = xq; 
            else
                xa = xq;          
            end
        end
        k = k+1;
    end  
    min = xq;
    k;
end