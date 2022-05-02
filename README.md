# otm-tabu-search

### Anderson Rieger da Luz - 274725
### Guilherme Moreira Scariott - 271023

## Formulação do problema

Dentre os problemas disponibilizados, decidimos escolher o Problema 1 para ser implementado em nosso trabalho usando a linguagem Julia. 

> *Seja G = (V, E) um grafo com custos cv ∈ Z em cada vértice v ∈ V e valores va ∈ Z em cada aresta a ∈ E. Encontre um subconjunto de arestas A ⊆ E que maximiza a soma dos valores das arestas escolhidas menos os custos dos vértices cobertos por essas arestas (um vértice é coberto por uma aresta quando alguma aresta incidente a ele é escolhida em A).*
> 

Além das estruturas básicas do problema (conjunto de arestas `A` e de vértices `V`) criamos algumas estruturas para usar na formulação do problema de forma mais efetiva. Foram elas:

- u → vetor que guarda em cada índice `i` o valor do índice do vetor `u` coberto pela aresta `i`;
- v → vetor que guarda em cada índice `i` o valor do índice do vetor `v` coberto pela aresta `i`;
- X → vetor que guarda em cada índice `i` o valor booleano que indica se a aresta `i` pertence à solução proposta;
- Y → vetor que guarda em cada índice `i` o valor booleano que indica se o vetor `i`  é coberto por uma aresta pertencente à solução proposta.


A função objetivo tenta maximizar a diferença entre as somas dos valores das arestas e a soma dos vértices cobertos por essas arestas. Dessa maneira não precisamos nos preocupar com a soma duplicada de vértices cobertos.  A cobertura é garantida pelas restrições, pois toda aresta escolhida para a solução com certeza terá seus vértices escolhidos também.

Essa formulação foi implementada com sucesso em Julia da seguinte maneira:

```julia
@variable(model, Y[1:n], Bin)
@variable(model, X[1:m], Bin)
@objective(model, Max,
      sum(X[i] * A[i] for i in 1:m) - sum(Y[j] * V[j] for j in 1:n)
)

for i in 1:m
  @constraint(model, X[i] <= Y[u[i]])
  @constraint(model, X[i] <= Y[v[i]])
end
```

## Formulação e implementação do Tabu Search

### Vizinhança

A vizinhança da solução é formada a partir do movimento de troca 1-flip. Dessa a maneira a vizinhança ficou bem contínua, com exceção dos movimentos filtrados pela lista tabu. Esses movimentos só continuam na vizinhança caso passem pelo critério de aspiração por objetivo, ou seja, caso sejam maior do que o valor da melhor solução global até então.

Todas as implementações dos sistemas de vizinhança foram implementados no nosso método `bestNeighbor()`, apresentada abaixo. Ela devolve o melhor vizinho da vizinhança de uma solução.

```julia
function bestNeighbor(s, s_value, s_vertex, s_ast_value, tabu_list)
  best_value = -Inf
  best_move = 0
  best_s_vertex = []
  current_s_vertex = []
  s_copy = copy(s)

  for i in 1:a_qty
    current_s = flip(s_copy, i)
    current_value, current_s_vertex = neighborValue(current_s, i, s_value, s_vertex)
    if tabu_list[i] == 0 || s_ast_value < current_value
      if current_value > best_value
        best_value = current_value
        best_move = i
        best_s_vertex = current_s_vertex
      end
    end
    flip(s_copy, i)
  end
  best_s = flip(s_copy, best_move)

  return best_s, best_value, best_move, best_s_vertex
end
```

### Valor da solução

Para o cálculo do valor da solução, nós criamos dois métodos: o `solutionValue()`, que calcula o valor de uma solução partindo do zero e a `neighborValue()` (usada no `bestNeighbor()`), que faz uma avaliação diferencial, usando apenas a aresta que foi flipada para calcular o novo valor.

```julia
function solutionValue(s)
  a_values_sum = Int64(0)
  v_values_sum = Int64(0)
  s_vertex = fill(0, v_qty)

  for i in 1:a_qty
    a_values_sum = a_values_sum + s[i] * a_values[i]
    if s[i] == 1
      s_vertex[fst_v[i]] = s_vertex[fst_v[i]] + 1
      s_vertex[snd_v[i]] = s_vertex[snd_v[i]] + 1
    end
  end
  
  for i in 1:v_qty
    decider = s_vertex[i] >= 1 ? 1 : 0
    v_values_sum = v_values_sum + decider * v_values[i]
  end

  return a_values_sum - v_values_sum, s_vertex
end
```

```julia
function neighborValue(s, index, s_value, s_vertex)
  s_vertex_cpy = copy(s_vertex)
  new_s_value = copy(s_value)

  if s[index] == 1
    s_vertex_cpy[fst_v[index]] = s_vertex_cpy[fst_v[index]] + 1
    s_vertex_cpy[snd_v[index]] = s_vertex_cpy[snd_v[index]] + 1
    fst_decider = s_vertex_cpy[fst_v[index]] == 1 ? 1 : 0
    snd_decider = s_vertex_cpy[snd_v[index]] == 1 ? 1 : 0
    new_s_value = new_s_value + (a_values[index] - (fst_decider * v_values[fst_v[index]] + snd_decider * v_values[snd_v[index]]))
  end
  if s[index] == 0
    s_vertex_cpy[fst_v[index]] = s_vertex_cpy[fst_v[index]] - 1
    s_vertex_cpy[snd_v[index]] = s_vertex_cpy[snd_v[index]] - 1
    fst_decider = s_vertex_cpy[fst_v[index]] == 0 ? 1 : 0
    snd_decider = s_vertex_cpy[snd_v[index]] == 0 ? 1 : 0
    new_s_value = new_s_value - (a_values[index] - (fst_decider * v_values[fst_v[index]] + snd_decider * v_values[snd_v[index]]))
  end

  return new_s_value, s_vertex_cpy
end
```

### Lista Tabu

Nossa lista tabu é uma lista de movimentos que foram usados recentemente. Esses movimentos são simplesmente representados pelo índice da aresta flipada.

Para manter a lista atualizada de maneira correta e eficiente, usamos 2 estruturas:

- `tabu_list` → Um vetor binário do tamanho do vetor de arestas que indica se a aresta daquele índice é tabu ou não;
- `tabu_stack` → Uma pilha de tamanho máximo indicado por parâmetro que salva os índices das arestas que entraram para a lista tabu, em ordem.

Assim, quando queremos adicionar um movimento na lista tabu, flipamos o bit do movimento na `tabu_list` e fazemos o push do índice da aresta na `tabu_list`. Para retirar da lista Tabu, fazemos o pop na `tabu_stack` do índice da aresta e utilizamos o valor “popado” para flipar na `tabu_list`. Podemos ver como isso foi implementado na função `updateTabu()` abaixo.

```julia
function updateTabu(tabu_list, tabu_stack, tabu_size, move)
  if tabu_list[move] == 0
    pushfirst!(tabu_stack, move)
    tabu_list = flip(tabu_list, move)
    if length(tabu_stack) >= tabu_size
      oldest_move = pop!(tabu_stack)
      tabu_list = flip(tabu_list, oldest_move)
    end
  end
end
```

### Fluxo principal

Depois de apresentar as estruturas auxiliares, podemos começar a entender o funcionamento da meta-heurística da Tabu Search. Abaixo temos a implementação do fluxo principal do programa. Nela podemos notar algumas coisas importantes, como a inicialização de variáveis (e a passagem delas como parâmetros) e o critério de parada.

Começamos com a solução inicial `s`, passada como parâmetro pelo usuário. A solução que escolhemos foi a solução toda zerada pois achamos que em um cálculo de diferenças uma solução zerada seria uma boa solução média. A solução, seu valor e seus vértices cobertos (sempre indicados pelo sufixo `_vertex`) são naturalmente passados como parâmetro para a maioria de nossos métodos e entre iterações.

Para o critério de parada escolhemos um sistema de iterações máxima sem melhora na melhor solução global `s_ast`. Para isso, usamos o parâmetro passado pelo usuário `maximum_iter` e mantemos salvo em qual iteração essa solução foi encontrada.

Abaixo temos o código do nosso fluxo principal; 

```julia
function tabuSearch(maximum_iter, s, tabu_size)
  iter_count = 0
  best_iter = 0

  s_ast = []
  s_ast_value = -Inf
  s_ast_vertex = []

  s_line = []
  s_line_vertex = []
  s_line_value = 0
  s_line_move = 0

  s_value, s_vertex = solutionValue(s)

  tabu_list = fill(0, a_qty)
  tabu_stack = []

  while iter_count - best_iter <= maximum_iter
    iter_count += 1

    s_line, s_line_value, s_line_move, s_line_vertex = bestNeighbor(s, s_value, s_vertex, s_ast_value, tabu_list)

    if s_line_value > s_ast_value
      s_ast = s_line
      s_ast_value = s_line_value
      s_ast_vertex = s_line_vertex
      best_iter = iter_count
    end
    
    s = s_line
    s_value = s_line_value
    s_vertex = s_line_vertex
    
    updateTabu(tabu_list, tabu_stack, tabu_size, s_line_move)
  end
  
  return s_ast, s_ast_value
end
```

## Resultados

O que pudemos notar foi que nossa implementação teve em média ~ *76.67%* de aproximação da solução ideal. O tempo de execução foi substancialmente menor que o tempo de execução do solver, mais expressivo com problemas maiores.
