using JuMP, GLPK, Random

open("instancias-problema1/instance_50_250.dat") do f
  global s = readline(f)
  global n = parse(Int64, first(split(s, " ")))
  global m = parse(Int64, last(split(s, " ")))
  global vertices = Vector{Int64}(undef, n)
  global arestas = Vector{Int64}(undef, m)
  global u = Vector{Int64}(undef, m)
  global v = Vector{Int64}(undef, m)

  for i in 1:n
    s = readline(f)
    vertices[i] = parse(Int64, last(split(s, " ")))
  end

  for i in 1:m
    s = readline(f)
    arestas[i] = parse(Int64, last(split(s, " ")))
    u[i] = parse(Int64, first(split(s, " ")))
    v[i] = parse(Int64, split(s, " ")[2])  
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

optimize!(model)
if termination_status(model) == MOI.OPTIMAL
  @show value.(Y)
  @show value.(X)
  println("Solução ótima encontrada")
  @show objective_value(model)
else
  println("Infactível ou ilimitado")
end