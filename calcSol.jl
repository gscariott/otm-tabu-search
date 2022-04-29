#sol = [0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 1, 1]
#[1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
function calcSol(sol)
  valores = Int64(0)
  custos = Int64(0)
  Z = fill(0, m)

  for each in 1:m
      if sol[each] > 0
          valores +=  arestas[each]
          Z[u[each]] += 1
          Z[v[each]] += 1
      end
  end
  for each in 1:m
    if Z[each] > 0
          custos +=  vertices[each]
    end
  end

  return valores - custos
end