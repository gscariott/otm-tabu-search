using JuMP, GLPK, Random

open("instancias-problema1/instance_200_300.dat") do f
  global s = readline(f)
  global n = parse(Int64, first(split(s, " ")))
  global m = parse(Int64, last(split(s, " ")))
  global vertices = Vector{Int64}(undef, n)
  global arestas = Vector{Int64}(undef, m)
  global u = Vector{Int64}(undef, m)
  global v = Vector{Int64}(undef, m)
  # global X = fill(0, m)
  # global Y = fill(0, n)

  for i in 1:n
    s = readline(f)
    vertices[i] = parse(Int64, last(split(s, " ")))
  end

  for i in 1:m
    s = readline(f)
    arestas[i] = parse(Int64, last(split(s, " ")))
    u[i] = parse(Int64, first(split(s, " ")))
    #Y[u[i]] += 1
    v[i] = parse(Int64, split(s, " ")[2])
    #Y[v[i]] += 1
    
  end
end
   
model = Model(GLPK.Optimizer)
@variable(model, Y[1:n], Bin)
@variable(model, X[1:m], Bin)
@objective(model, Max,
            sum(X[i] * arestas[i] for i in 1:m) - sum(Y[j] * vertices[j] for j in 1:n)
          )

for i in 1:m
  @constraint(model, X[i] <= Y[u[i]])
  @constraint(model, X[i] <= Y[v[i]])
end

#parametros: maximumIter = 20, tabuSize = m/4, initialSol = [1, 0, 0, 1, 1]
# tabuList = [0, 0, 0, 0, 0]
# s = sol. inicial
# s* = s
# iterCount = 0
# bestIter = IterCount



# while iterCount - bestIter <= maximumIter
  # iterCount =+ 1
  # vizinhos com 1-flip: 
  # flip(1) [0, 0, 0, 1, 1]
  # flip(2) [1, 1, 0, 1, 1]
  # flip(3) [1, 0, 1, 1, 1]
  # flip(4) [1, 0, 0, 0, 1]
  # flip(5) [1, 0, 0, 1, 0]

  # s', move = bestInNeighborhood(neighborhood(s))
  # se move nao for tabu or s' é melhor que s*
    # s = s'
  # se s > s*
    # s* = s
    # bestIter = iterCount
  # updateTabu()
# retorna s*


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
end

# int64 calcSol(solucao[])
  # calcula do zero o valor e devolve o valor da sol
  #

# calcNeighborhoodSol(sol, bit)
  # calcula a partir da solucao total só com a diferença de um bit

function neighborhood(sol)

  # lista de soluçoes vizinhas e seus bits geradores
end

# bestInNeighborhood
  # calcNeighborhoodSol em todas as sol da neighborhood e devolve a melhor sol e o move que gerou essa sol

# updateTabu(tabuList, move, moveStack)
  # flip tabuList[move] + (push no top da pilha)
  # flip o move mais antigo + (o pop no bottom da pilha)

# calcY

# calcX



optimize!(model)
if termination_status(model) == MOI.OPTIMAL
  println("Solução ótima encontrada")
  @show objective_value(model)
  # @show value.(Y)
  # @show value.(X)
else
  println("Infactível ou ilimitado")
end