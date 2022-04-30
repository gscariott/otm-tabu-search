using JuMP, GLPK, Random

open("instancias-problema1/instance_50_75.dat") do f
  global q = readline(f)
  global n = parse(Int64, first(split(q, " ")))
  global m = parse(Int64, last(split(q, " ")))
  global vertices = Vector{Int64}(undef, n)
  global arestas = Vector{Int64}(undef, m)
  global u = Vector{Int64}(undef, m)
  global v = Vector{Int64}(undef, m)
  # global X = fill(0, m)
  # global Y = fill(0, n)

  for i in 1:n
    q = readline(f)
    vertices[i] = parse(Int64, last(split(q, " ")))
  end

  for i in 1:m
    q = readline(f)
    arestas[i] = parse(Int64, last(split(q, " ")))
    u[i] = parse(Int64, first(split(q, " ")))
    #Y[u[i]] += 1
    v[i] = parse(Int64, split(q, " ")[2])
    #Y[v[i]] += 1
    
  end
end
   
# model = Model(GLPK.Optimizer)
# @variable(model, Y[1:n], Bin)
# @variable(model, X[1:m], Bin)
# @objective(model, Max,
#             sum(X[i] * arestas[i] for i in 1:m) - sum(Y[j] * vertices[j] for j in 1:n)
#           )

# for i in 1:m
#   @constraint(model, X[i] <= Y[u[i]])
#   @constraint(model, X[i] <= Y[v[i]])
# end




# funcoes auxiliares
# flip(sol, bit)
  # flipa o bit da sol
  # flipa os vertices da aresta[bit] se nao tiver nenhuma aresta tiver usando aquele vertice
    # monta Y do zero toda vez?
    # Y não binário: se 2 arestas cobrem o vertice j, entao Y(j) == 2
    # devolve a sol flipada
  # atualizar X e Y
function flip(sol, bit)
  sol[bit] = sol[bit] == 1 ? 0 : 1

  return sol
end

# int64 calcSol(solucao[])
# calcula do zero o valor e devolve o valor da sol
#
function solutionValue(sol)
  # @show sol
  valores = Int64(0)
  custos = Int64(0)
  Y = fill(0, m)
  
  for i in 1:m
    if sol[i] > 0
      valores +=  arestas[i]
      Y[u[i]] += 1
      Y[v[i]] += 1
    end
  end
  
  for i in 1:m
    if Y[i] > 0
      custos +=  vertices[i]
    end
  end
  
  return valores - custos # devolver o Y tambem
end

# calcNeighborhoodSol(sol, bit)
  # calcula a partir da solucao total só com a diferença de um bit
# Random.seed!(0)
function neighborValue(bit, val)
  # sol ja flipada
  # solutionValue + valor da aresta que foi flipada - os vertices da aresta flipado
  # dec do u + dec do v
  # se maior que zero
  

  return solutionValue(sol)
end

function bestNeighbor(sol, value)
  # calcNeighborhoodSol em todas as sol da neighborhood e devolve a melhor sol e o move que gerou essa sol
  best_value = 0
  best_move = 1
  best_sol = sol
  curr_value = 0
  curr_sol = sol

  for i in 1:m
    curr_sol = flip(curr_sol, i)
    curr_value = solutionValue(sol) # neighborValue(i, value)
    if best_value < curr_value
      best_value = curr_value
      best_move = i
      # best_sol = curr_sol
    end
    flip(curr_sol, i)
  end
  best_sol = flip(curr_sol, best_move)
  
  return best_sol, best_value, best_move
end
# updateTabu(tabuList, move, moveStack)
# flip tabuList[move] + (push no top da pilha)
  # (o pop no bottom da pilha) + flip tabuList[popped]
function updateTabu(tabuList, move, moveStack)
  tabuList = flip(tabuList, move)
  pushfirst!(moveStack, move)
  oldest = pop!(moveStack)
  tabuList = flip(tabuList, oldest)
end
  # calcY
  
# calcX

#parametros: maximumIter = m/3, tabuSize = m/4, initialSol = [1, 0, 0, 1, 1]
function tabu()
  tabuList = fill(0, m)
  tabuSize = floor(Int64,m/4)
  moveStack = fill(1, tabuSize)
  # move = 13
  maximumIter = floor(Int64,m/3)
  # initialSol = [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1]
  initialSol = fill(0,m)
  # tabuList = fill(0, tabuSize)
  s = initialSol
  s_ast = s
  iterCount = 0
  bestIter = iterCount
  bestValue = 0
  s_value = solutionValue(s) # adicionar Y como retorno

  while iterCount - bestIter <= maximumIter
    # @show s
    iterCount += 1
    @show tabuList
    # @show moveStack
    s_line, s_line_value, s_line_move = bestNeighbor(s, s_value)

    if tabuList[s_line_move] == 0# || s_line_value > bestValue
      @show "NAO É TABU"
      s = s_line
      s_value = s_line_value
    end
    if s_value > bestValue
      s_ast = s
      bestIter = iterCount
      bestValue = s_value
    end
    updateTabu(tabuList, s_line_move, moveStack)
  end

  @show s_ast
  @show bestValue
end

tabu()

# optimize!(model)
# if termination_status(model) == MOI.OPTIMAL
#   println("Solução ótima encontrada")
#   @show objective_value(model)
#   # @show value.(Y)
#   # @show value.(X)
# else
#   println("Infactível ou ilimitado")
# end