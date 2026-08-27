# Relatório: Determinação e Estimativa de η em Métodos Quase-Newton

## 1. Introdução

Nos métodos de otimização numérica, o objetivo é encontrar um ponto $x^*$ que minimize uma função objetivo $f(x)$. Quando a função é diferenciável, podemos usar informações de primeira ordem — o gradiente $\nabla f(x)$ — para definir uma direção de descida. Quando também usamos informações de segunda ordem, entra em cena a matriz Hessiana $H(x)$, que descreve a curvatura local da função.

O **método de Newton** utiliza diretamente a Hessiana para calcular a direção de busca. Suas características principais são:

- Usa informação da 1ª e da 2ª derivadas;
- Necessita inverter $H$ a cada passo;
- Usa um modelo quadrático $f(x)$, obtido da série de Taylor;
- Para uma $f$ quadrática, converge em um só passo.

Em muitos problemas práticos, porém, calcular a Hessiana e, principalmente, invertê-la a cada iteração é caro ou inviável. É nesse contexto que surgem os **métodos quase-Newton**, cujo objetivo é construir, de forma iterativa e barata, uma aproximação da Hessiana ou de sua inversa. Essa aproximação inversa é representada pela matriz $\eta(x_k)$.

## 2. Algoritmo do método de Newton (referência)

1. Conhecer $f(x): \mathbb{R}^n \to \mathbb{R}$, $\nabla f(x) \in \mathbb{R}^n$, $H(x)_{n \times n}$; inicializar $k = 0$ e $x_0$; calcular $\nabla f(x_0)$.
2. Calcular $H(x_k)$.
3. Calcular $H^{-1}(x_k)$.
4. Atualizar o ponto:
$$
x_{k+1} = x_k - H^{-1}(x_k)\,\nabla f(x_k)
$$
5. Calcular $\nabla f(x_{k+1})$.
6. Critério de parada: se $\nabla f(x_{k+1}) = 0$, então $x^* = x_{k+1}$ e o algoritmo termina; senão, seguir para o passo 7.
7. $k = k+1$ e retornar ao passo 2.

### Variantes do método de Newton

- **Variante I** — inverte-se $H(x)$ uma única vez e usa-se como constante durante todo o processo.
- **Variante II** — mantém-se a inversa de $H(x)$ constante durante algumas iterações; após isso, atualiza-se $H(x)$.
- **Variante III** — usa-se a direção de busca de Newton normalizada:
$$
d_k = \frac{-H^{-1}(x_k)\nabla f(x_k)}{\left\lVert H(x_k)\nabla f(x_k) \right\rVert}
$$
No caso de algoritmos que não usam a Hessiana (método do gradiente), toma-se $H^{-1} = I$.

## 3. O que é η(x_k)

No método quase-Newton, a direção de busca é escrita de forma genérica como

$$
d_k = \eta(x_k)\,\nabla f(x_k)
$$

em que $\eta(x_k)$ é uma **estimativa** para o cálculo de $H^{-1}(x_k)$. Três casos definem o espectro de métodos:

**a)** Se $\eta(x_k) = I$, então $d_k = \nabla f(x_k)$ — recai-se no **método do gradiente**.

**b)** Se $I < \eta(x_k) \leq H^{-1}(x_k)$ — método **quase-Newton**.

**c)** Se $\eta(x_k) = H^{-1}(x_k)$ — coloca-se na frente o sinal $\Rightarrow$ **direção de Newton** exata.

Assim, $\eta$ não é um número escalar: é uma matriz $n \times n$, usada para transformar o gradiente em uma direção de busca mais adequada do que a direção do gradiente puro, sem exigir o cálculo explícito e a inversão da Hessiana verdadeira.

## 4. Modelo quadrático e origem de η

Em cada iteração $k$, os métodos quase-Newton constroem um modelo quadrático local da função objetivo:

$$
m_k(p) = f_k + \nabla f_k^T p + \frac{1}{2}p^T B_k p
$$

onde:

$$
f_k = f(x_k), \qquad \nabla f_k = \nabla f(x_k), \qquad B_k \approx H(x_k)
$$

$B_k$ representa uma aproximação da Hessiana. A direção de busca que minimiza esse modelo é

$$
p_k = -B_k^{-1}\nabla f_k
$$

Como $B_k^{-1}$ é justamente a inversa aproximada da Hessiana, define-se

$$
\eta(x_k) = B_k^{-1}
$$

de modo que a direção pode ser escrita como

$$
p_k = -\eta(x_k)\,\nabla f_k
$$

Essa é a função central de $\eta$: permitir que o método use uma direção semelhante à de Newton sem precisar calcular explicitamente a Hessiana exata a cada passo.

## 5. Atualização do ponto e variações entre iterações

Calculada a direção $p_k$, o novo ponto é obtido por

$$
x_{k+1} = x_k + \alpha_k p_k
$$

onde $\alpha_k$ é o tamanho do passo, obtido por algum método de busca unidimensional que minimiza $f(x_k + \lambda\,d_k)$.

Define-se o deslocamento entre duas iterações consecutivas:

$$
\Delta x_k = x_{k+1} - x_k = \lambda_k^{*}\,d_k
$$

e a variação do gradiente:

$$
\Delta g(x_k) = \nabla f(x_{k+1}) - \nabla f(x_k)
$$

Esses dois vetores — $\Delta x_k$ e $\Delta g(x_k)$ — são as únicas informações novas disponíveis após uma iteração: quanto o ponto mudou e quanto o gradiente mudou. É a partir deles que $\eta$ é corrigida.

## 6. A equação secante

Para que o modelo quadrático represente melhor a curvatura real da função, impõe-se a **equação secante**:

$$
B_{k+1}\,\Delta x_k = \Delta g(x_k)
$$

Essa equação diz que a nova aproximação da Hessiana, $B_{k+1}$, deve transformar o deslocamento $\Delta x_k$ na variação observada do gradiente $\Delta g(x_k)$.

Como o interesse está na inversa da Hessiana, $H_{k+1} = B_{k+1}^{-1}$, a equação secante equivalente para a inversa fica:

$$
H_{k+1}\,\Delta g(x_k) = \Delta x_k
$$

ou, usando a notação com $\eta$:

$$
\eta(x_{k+1})\,\Delta g(x_k) = \Delta x_k
$$

Essa relação é a definição-chave: a nova matriz $\eta(x_{k+1})$ deve transformar a variação do gradiente na variação observada da posição.

## 7. Condição de curvatura

Para garantir que a matriz atualizada preserve propriedades desejáveis, como positividade definida, exige-se a **condição de curvatura**:

$$
\Delta x_k^T\,\Delta g(x_k) > 0
$$

Essa condição significa que a variação do gradiente deve estar coerente com o deslocamento realizado — geometricamente, indica curvatura positiva na direção percorrida. Ela é importante porque, se $\eta(x_k)$ for positiva definida, a direção

$$
p_k = -\eta(x_k)\,\nabla f(x_k)
$$

tende a ser uma direção de descida.

## 8. Fórmula geral de atualização de η

A matriz $\eta$ é atualizada iterativamente:

$$
\eta(x_{k+1}) = \eta(x_k) + \Delta \eta(x_k)
$$

O objetivo é corrigir a matriz anterior $\eta(x_k)$ usando as novas informações $\Delta x_k$ e $\Delta g(x_k)$. A forma geral parametrizada da correção é

$$
\Delta \eta(x_k) = \frac{1}{\omega}\,\frac{\Delta x_k\,\bar y^T}{\bar y^T\,\Delta g(x_k)} \;-\; \frac{\eta(x_k)\,\Delta g(x_k)\,\bar z^T}{\bar z^T\,\Delta g(x_k)}
$$

onde $\omega$ é um escalar e $\bar y$, $\bar z$ são vetores cuja escolha depende do método (do autor da fórmula). Diferentes escolhas de $\omega$, $\bar y$ e $\bar z$ geram famílias distintas de métodos quase-Newton:

| Método | $\omega$ | $\bar y$ | $\bar z$ |
|---|---|---|---|
| Broyden | $1$ | $\bar y = \bar z = \Delta x_k$ | $\Delta x_k$ |
| Fletcher–Powell (DFP) | $1$ | $\Delta x_k$ | $\eta(x_k)\,\Delta g(x_k)$ |
| Davidon | $1$ | $\bar y = \bar z = \Delta x_k$ | — |
| Rophisan | $\omega \to \infty$ | $\eta(x_k)\,\Delta g(x_k)$ | $\Delta g(x_k)$ |

## 9. Estimativa de η pelo método DFP (Davidon–Fletcher–Powell)

Fazendo, na fórmula geral, $\omega = 1$, $\bar y = \Delta x_k$ e $\bar z = \eta(x_k)\,\Delta g(x_k)$, obtém-se a atualização DFP:

$$
\Delta \eta(x_k) = \frac{\Delta x_k\,\Delta x_k^T}{\Delta g(x_k)^T\,\Delta x_k} \;-\; \frac{\eta(x_k)\,\Delta g(x_k)\,\Delta g(x_k)^T\,\eta(x_k)}{\Delta g(x_k)^T\,\eta(x_k)\,\Delta g(x_k)}
$$

e, portanto,

$$
\eta(x_{k+1}) = \eta(x_k) + \frac{\Delta x_k\,\Delta x_k^T}{\Delta g(x_k)^T\,\Delta x_k} \;-\; \frac{\eta(x_k)\,\Delta g(x_k)\,\Delta g(x_k)^T\,\eta(x_k)}{\Delta g(x_k)^T\,\eta(x_k)\,\Delta g(x_k)}
$$

Essa é a forma principal da estimativa de $\eta$ no método DFP.

### Interpretação dos termos

A atualização possui dois termos principais:

**Primeiro termo** (adição):
$$
\frac{\Delta x_k\,\Delta x_k^T}{\Delta g(x_k)^T\,\Delta x_k}
$$
Adiciona à matriz $\eta$ uma informação nova baseada no deslocamento efetivamente realizado pelo algoritmo, forçando a nova matriz a reproduzir melhor a relação entre variação de gradiente e variação de posição.

**Segundo termo** (subtração):
$$
\frac{\eta(x_k)\,\Delta g(x_k)\,\Delta g(x_k)^T\,\eta(x_k)}{\Delta g(x_k)^T\,\eta(x_k)\,\Delta g(x_k)}
$$
Remove da matriz anterior a parte da informação que se tornou incompatível com a nova observação de curvatura.

Assim, a atualização de $\eta$ pode ser interpretada como um ajuste: remove-se uma estimativa antiga inadequada e adiciona-se uma nova estimativa compatível com os dados mais recentes.

## 10. Outras variantes: Broyden e Rophisan

Além do DFP, a mesma fórmula parametrizada gera outras estimativas de $\eta$, variando apenas $\omega$, $\bar y$ e $\bar z$:

**Método de Broyden** ($\omega = 1$, $\bar y = \bar z = \Delta x_k$):
$$
\Delta \eta(x_k) = \frac{(\Delta x_k - \eta(x_k)\Delta g(x_k))\,\Delta x_k^T}{\Delta x_k^T\,\Delta g(x_k)}
$$

**Método de Rophisan** ($\omega \to \infty$, $\bar z = \eta(x_k)\Delta g(x_k)$):
$$
\eta(x_{k+1}) \to \frac{\eta(x_k)\,\Delta g(x_k)\,\Delta g(x_k)^T\,\eta(x_k)}{\Delta g(x_k)^T\,\eta(x_k)\,\Delta g(x_k)}
$$

Isso mostra que a fórmula parametrizada apresentada na Seção 8 é, de fato, um esqueleto geral do qual DFP, Broyden e demais métodos quase-Newton são casos particulares.

## 11. Algoritmo completo usando η (Método de Fletcher–Powell)

1. **Conhecer:** $f(x): \mathbb{R}^n \to \mathbb{R}$, $\nabla f(x) \in \mathbb{R}^n$; escolher $x_0$ e tolerância $\varepsilon > 0$; inicializar $k = 0$ e $\eta(x_0) = I$.
2. **Calcular a direção de busca:**
$$
d_k = \frac{-\eta(x_k)\,\nabla f(x_k)}{\left\lVert \eta(x_k)\,\nabla f(x_k) \right\rVert}
$$
3. **Minimizar** $f(x_k + \lambda\,d_k)$ usando algum método unidimensional, obtendo $\lambda_k^{*}$.
4. **Atualizar o ponto:**
$$
x_{k+1} = x_k + \lambda_k^{*}\,d_k
$$
5. **Calcular** $\Delta f(x_{k+1}) = f(x_{k+1}) - f(x_k)$.
6. **Calcular:**
$$
\Delta g(x_k) = \nabla f(x_{k+1}) - \nabla f(x_k), \qquad \Delta x_k = x_{k+1} - x_k = \lambda_k^{*}\,d_k
$$
7. **Critério de parada:** se $\Delta x_k$ (ou $\nabla f(x_{k+1})$) $\to 0$, parar; senão, seguir ao passo 8.
8. **Atualizar a matriz:**
$$
\eta(x_{k+1}) = \eta(x_k) + \Delta \eta(x_k)
$$
usando a fórmula da Seção 8 ou 9, conforme o método escolhido.
9. **Teste de singularidade:** se $\left|\det\big[\eta(x_{k+1})\big]\right| \leq \varepsilon$ (matriz próxima de singular), reinicializar $\eta(x_{k+1}) = I$; senão, manter.
10. $k = k+1$ e retornar ao passo 2.

## 12. Interpretação geométrica

O gradiente $\nabla f(x_k)$ aponta para a direção de maior crescimento da função; portanto, $-\nabla f(x_k)$ aponta para uma direção de descida. Entretanto, essa direção pode não ser a melhor quando as curvas de nível da função são alongadas, inclinadas ou mal condicionadas.

A matriz $\eta(x_k)$ modifica essa direção. Em vez de seguir simplesmente o sentido oposto ao gradiente, o método usa

$$
-\eta(x_k)\,\nabla f(x_k)
$$

Isso significa que a matriz $\eta$ "corrige" o gradiente levando em conta a curvatura aproximada da função. Por isso, métodos quase-Newton normalmente convergem mais rapidamente que o método do gradiente puro, mas evitam o custo computacional completo do método de Newton (montagem e inversão da Hessiana verdadeira a cada passo).

## 13. Conclusão

A matriz $\eta(x_k)$ é a estimativa da inversa da Hessiana usada nos métodos quase-Newton. Ela serve para calcular uma direção de busca que incorpora informação de curvatura sem exigir o cálculo direto da Hessiana exata, sendo:

- $\eta(x_k) = I \Rightarrow$ método do gradiente;
- $\eta(x_k) = H^{-1}(x_k) \Rightarrow$ método de Newton;
- $I < \eta(x_k) \leq H^{-1}(x_k) \Rightarrow$ método quase-Newton.

Partindo do modelo quadrático local da função objetivo, em que $B_k$ aproxima a Hessiana, define-se $H_k = B_k^{-1} \equiv \eta(x_k)$. A atualização de $\eta$ é construída a partir da **equação secante** ($\eta(x_{k+1})\Delta g(x_k) = \Delta x_k$) e da **condição de curvatura** ($\Delta x_k^T \Delta g(x_k) > 0$), usando apenas as variações observadas entre iterações:

$$
\Delta x_k = x_{k+1} - x_k, \qquad \Delta g(x_k) = \nabla f(x_{k+1}) - \nabla f(x_k)
$$

A fórmula final do método DFP/Fletcher–Powell é

$$
\eta(x_{k+1}) = \eta(x_k) + \frac{\Delta x_k\,\Delta x_k^T}{\Delta g(x_k)^T\,\Delta x_k} - \frac{\eta(x_k)\,\Delta g(x_k)\,\Delta g(x_k)^T\,\eta(x_k)}{\Delta g(x_k)^T\,\eta(x_k)\,\Delta g(x_k)}
$$

Portanto, $\eta$ é a memória de curvatura do método quase-Newton: registra, a cada iteração, como o gradiente mudou em relação ao deslocamento realizado, permitindo construir de forma barata e incremental uma aproximação cada vez melhor da direção de Newton.
