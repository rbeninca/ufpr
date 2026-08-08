// Conversao de metodo_descida_mais_rapida.m para JavaScript.
// Os vetores x sao arrays comuns: [x1, x2, ...]

function norma(v) {
    let s = 0;
    for (let i = 0; i < v.length; i++) s += v[i] * v[i];
    return Math.sqrt(s);
}

// gradiente.m - derivada por diferencas centrais
function gradiente(funcao, x, epsilon) {
    const g = new Array(x.length);
    const xc = x.slice();
    for (let i = 0; i < xc.length; i++) {
        const a = xc[i];
        xc[i] = a + epsilon;
        const b = funcao(xc);
        xc[i] = a - epsilon;
        const c = funcao(xc);
        g[i] = (b - c) / (2 * epsilon);
        xc[i] = a;
    }
    return g;
}

// regiao_busca.m - cercamento do minimo, devolve [a, b]
function regiao_busca(funcao, x0, delta_x) {
    let k = 0;
    const xk = [x0, x0 + delta_x];

    if (funcao(xk[k + 1]) > funcao(xk[k])) {
        delta_x = -delta_x;
        xk[k + 1] = xk[k] + delta_x;
    }

    // x0 ja esta praticamente no minimo: usa abs para nao inverter a e b
    if (funcao(xk[k + 1]) > funcao(xk[k])) {
        return [x0 - Math.abs(delta_x), x0 + Math.abs(delta_x)];
    }

    while (funcao(xk[k + 1]) <= funcao(xk[k])) {
        k++;
        xk[k + 1] = xk[k] + delta_x;
    }

    return [Math.min(xk[k - 1], xk[k + 1]), Math.max(xk[k - 1], xk[k + 1])];
}

// metodo_dsc.m - aproximacao quadratica (Davies-Swann-Campey)
function metodo_dsc(funcao, a, b, epsilon) {
    const max_iter = 1000;
    let k = 1;
    let xa = a;
    let xc = b;
    let xb = (xa + xc) / 2;
    let xq = 0;

    while (k < max_iter) {
        const fa = funcao(xa);
        const fb = funcao(xb);
        const fc = funcao(xc);

        const num = (xb ** 2 - xc ** 2) * fa + (xc ** 2 - xa ** 2) * fb + (xa ** 2 - xb ** 2) * fc;
        const den = (xb - xc) * fa + (xc - xa) * fb + (xa - xb) * fc;

        xq = 0.5 * (num / den);
        const fq = funcao(xq);

        if (Math.abs(xq - xb) < epsilon) break;

        // abandona o maior
        if (xq > xb) {
            if (fq < fb) {
                xa = xb;
                xb = xq;
            } else {
                xc = xq;
            }
        } else {
            if (fq < fb) {
                xc = xb;
                xb = xq;
            } else {
                xa = xq;
            }
        }
        k++;
    }
    return xq;
}

// metodo_descida_mais_rapida.m
function metodo_descida_mais_rapida(funcao, x0, epsilon) {
    let xk = x0.slice();
    let x_ant = x0.slice();

    const n = x0.length;
    const max_iter = 10000;
    const delta_x = 0.001;

    const xk_historico = [xk.slice()];

    for (let k = 1; k <= max_iter; k++) {
        const g = gradiente(funcao, xk, epsilon);
        const norm_g = norma(g);
        if (norm_g <= epsilon) break;

        // a cada n iteracoes usa a direcao acumulada (xk - x_ant)
        let S;
        if (k % n === 0) {//reinicia a direcao de busca a cada n iteracoes
            const d = xk.map((v, i) => v - x_ant[i]); //calcula o vetor de deslocamento
            const norm_d = norma(d); //calcula a norma do vetor de deslocamento
            S = d.map(v => v / norm_d);
            x_ant = xk.slice();
            xk_historico.push(xk.slice());
        } else {
            S = g.map(v => -v / norm_g);
        }

        const f_lambda = lambda => funcao(xk.map((v, i) => v + lambda * S[i]));
        const [a, b] = regiao_busca(f_lambda, xk[0], delta_x);
        const lambda_otimo = metodo_dsc(f_lambda, a, b, epsilon);

        xk = xk.map((v, i) => v + lambda_otimo * S[i]);
        xk_historico.push(xk.slice());
    }

    return { x_otimo: xk, xk_historico: xk_historico };
}
