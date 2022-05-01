using JuMP, GLPK, Random

open("instancias-problema1/instance_1000_10000.dat") do file
  global line = readline(file)
  global v_qty = parse(Int64, first(split(line, " ")))
  global a_qty = parse(Int64, last(split(line, " ")))
  global v_values = Vector{Int64}(undef, v_qty)
  global a_values = Vector{Int64}(undef, a_qty)
  global fst_v = Vector{Int64}(undef, a_qty)
  global snd_v = Vector{Int64}(undef, a_qty)

  for i in 1:v_qty
    line = readline(file)
    v_values[i] = parse(Int64, last(split(line, " ")))
  end

  for i in 1:a_qty
    line = readline(file)
    a_values[i] = parse(Int64, last(split(line, " ")))
    fst_v[i] = parse(Int64, first(split(line, " ")))
    snd_v[i] = parse(Int64, split(line, " ")[2]) 
  end
end

function setOnes(s_vertex)
  for i in 1:length(s_vertex)
    if s_vertex[i] > 0
      s_vertex[i] = 1
    end
  end
end

function flip(s, index)
  s[index] = s[index] == 1 ? 0 : 1

  return s
end

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
  
  @show s_ast_vertex
  return s_ast, s_ast_value
end

s = fill(0, a_qty)
@show tabuSearch(40, s, 1.1 * floor(sqrt(a_qty)))
