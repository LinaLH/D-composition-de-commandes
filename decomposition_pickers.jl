using JuMP, GLPK

# Assurez-vous que le fichier lecture.jl est dans le même répertoire
include("lecture.jl")

#Hypoyhèse : la fonction est définie dans lecture.jl et initialisée ... ?
Data.P = 5 #ou 2 ou autre valeur de notre choix
Data.Capa = []
for p in 1:Data.P
    push!(Data.Capa, 12) #encore ici, on peut remplacer 12 par la valeur de notre choix
end

for p in 1:Data.P
    println("Capacité du préparateur $p: ", Data.Capa[p])
end

Data.FO = []
Data.SO = []
if (Data.O % 2 == 0)
    for o in 1:(Data.O/2)
        push!(Data.FO, o)
    end
else 
    for o in 1:(Data.O/2)+1
        push!(Data.FO, o)
    end
end

for o in 1:Data.O
    if ! in(o,Data.FO)
        push!(Data.SO, o)
    end
end

function solve_picker_subproblem(p, alpha, beta)
    model = Model(GLPK.Optimizer)
    @variable(model, x[1:Data.O], Bin)  # Affectation des racks aux préparateurs
    @variable(model, y[1:Data.R], Bin)  # Affectation des commandes aux préparateurs
    @variable(model, 0<= v[Data.SO] <= 1)
    @variable(model, 0<= u[1:Data.R] <= 1)

    for i in 1:Data.N
        lhs = sum(Data.S[i][r] * y[r] for r in 1:Data.R)
        rhs = sum(Data.Q[i][o] * x[o] for o in 1:Data.O)
        @constraint(model, lhs >= rhs)
    end
    @constraint(model, sum(x[o] for o in 1:Data.O) <= Data.Capa[p])  # Contrainte de capacité pour le préparateur p

    # Fonction objectif
    @objective(model, Min, sum((length(Data.SO)  + 1 + beta[r]) * u[r] for r in 1:Data.R) - sum(y[r] * beta[r] for r in 1:Data.R) -
                          sum(v[o] * (1 - alpha[o]) for o in Data.SO) + sum(alpha[o] for o in Data.FO) - 
                          sum(x[o] * alpha[o] for o in 1:Data.O))

    cpu_time = @elapsed optimize!(model)
    println("CPU time pour le sous problème $p : $cpu_time")
    return value.(x), value.(y), objective_value(model)
end


# Exemple d'utilisation pour un préparateur p
alpha = [0.1 for o in 1:Data.O]  # Multiplicateurs pour les racks
beta = [0.1 for r in 1:Data.R]  # Multiplicateurs pour les commandes
x_solution, y_solution, obj_value = solve_picker_subproblem(1, alpha, beta)

println("Solution pour le préparateur 1: ", x_solution, y_solution, " avec un coût de ", obj_value)

function solve_master_problem(P, x_solutions, y_solutions, alphas, betas)
    master_model = Model(GLPK.Optimizer)
    @variable(master_model, lambda[1:P] >= 0)
    @constraint(master_model, sum(lambda[p] for p in 1:P) == 1)

    # Objectif du problème maître
    @objective(master_model, Min, sum(lambda[p] * (alphas[p] + betas[p]) for p in 1:P))

    cpu_time = @elapsed optimize!(master_model)

    println("Valeur optimale du problème maître: ", objective_value(master_model))
    for p in 1:P
        println("Poids du sous-problème pour le préparateur $p: ", value(lambda[p]))
    end
    println("================================")
    println(" CPU time = $cpu_time")
end

alphas = [0.1 for o in 1:Data.O]  # Multiplicateurs pour les racks
betas = [0.1 for r in 1:Data.R]

x_solutions = []
y_solutions = []

for p in 1:Data.P
    x_sol, y_sol, obj_value_ = solve_picker_subproblem(p, alphas, betas)
    push!(x_solutions, x_sol)
    push!(y_solutions, y_sol)
    println("Solution pour le préparateur $p: x=$x_sol, y=$y_sol, Coût=$obj_value_")
end

solve_master_problem(Data.P, x_solutions, y_solutions, alphas, betas)