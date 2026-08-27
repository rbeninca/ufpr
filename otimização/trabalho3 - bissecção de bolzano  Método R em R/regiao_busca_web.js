function regiao_busca(funcao, x0, delta_x) {
    const passos = [];
    let k = 0;
    const xk = [x0, x0 + delta_x];

    if (funcao(xk[k + 1]) > funcao(xk[k])) {
        delta_x = -delta_x;
        xk[k + 1] = xk[k] + delta_x;
    }

    // se a funcao sobe nos dois sentidos, x0 ja esta praticamente no minimo.
    // usa abs(delta_x) pois senao a e b saem invertidos
    if (funcao(xk[k + 1]) > funcao(xk[k])) {
        passos.push({ k: 0, x: xk[0], f: funcao(xk[0]) });
        return { a: x0 - Math.abs(delta_x), b: x0 + Math.abs(delta_x), passos: passos };
    }

    while (funcao(xk[k + 1]) <= funcao(xk[k])) {
        passos.push({ k: k, x: xk[k], f: funcao(xk[k]) });
        k++;
        xk[k + 1] = xk[k] + delta_x;
    }
    passos.push({ k: k, x: xk[k], f: funcao(xk[k]) });
    passos.push({ k: k + 1, x: xk[k + 1], f: funcao(xk[k + 1]) });

    const a = Math.min(xk[k - 1], xk[k + 1]);
    const b = Math.max(xk[k - 1], xk[k + 1]);
    return { a: a, b: b, passos: passos };
}
