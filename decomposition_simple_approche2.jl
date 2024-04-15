using JuMP
using GLPK
#Pkg.add("Cbc")

# Assurez-vous que le fichier lecture.jl est dans le même répertoire
include("lecture.jl")
# Initialiser nos 2 modèles JuMP avec le solveur CBC pour résoudres les 2 sous problemes

#Hypoyhèse : la fonction est définie dans lecture.jl et initialisée ... ?
Data.P = 2 #ou 2 ou autre valeur de notre choix
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
# Fonction pour initialiser les multiplicateurs de Lagrange
function initialiser_multiplicateurs(P, N, valeur_initiale)
    alpha = fill(valeur_initiale, P, N)
    return alpha
end
function f(x,y)
    return sum((length(Data.SO) + 1) * sum(y[r,p] for p in 1:Data.P) for r in 1:Data.R) - sum(sum(x[o,p] for p in 1:Data.P) for o in Data.SO)
end

function f1(alpha)
    model_1 = Model(GLPK.Optimizer)
    @variable(model_1, x[1:Data.O, 1:Data.P], Bin)  # Affectation des racks aux préparateurs
    @variable(model_1, 0 <= v[Data.SO] <= 1)
    #1
    for o in Data.FO
        @constraint(model_1, sum(x[o, p] for p in 1:Data.P) == 1)
    end

    #2
    for o in Data.SO
        @constraint(model_1, sum(x[o, p] for p in 1:Data.P) == v[o])
    end
    #4
    for p in 1:Data.P
        @constraint(model_1, sum(x[o, p] for o in 1:Data.O) <= Data.Capa[p])
    end
        # Fonction objectif sous probleme 1
    @objective(model_1, Min, sum(sum(x[o,p]*sum(alpha[p,i]*Data.Q[i][o] for i in 1:Data.N) for p in 1:Data.P) for o in 1:Data.O) - sum(v[o] for o in Data.SO))

    # Résoudre le modèle 1
    optimize!(model_1)
    x_value = [ value(x[o,p]) for o in 1:Data.O, p in 1:Data.P ]
    return x_value,  objective_value(model_1)
end
function f2(alpha)
    model_2 = Model(GLPK.Optimizer)
    @variable(model_2, y[1:Data.R, 1:Data.P], Bin)  # Affectation des commandes aux préparateurs
    @variable(model_2, 0 <= u[1:Data.R] <= 1)
        #3
    for r in 1:Data.R
        @constraint(model_2, sum(y[r, p] for p in 1:Data.P) == u[r])
    end
        # Fonction objectif
    @objective(model_2, Min, sum((length(Data.SO) + 1) * u[r] for r in 1:Data.R) + sum(sum(y[r,p] * sum(-alpha[p,i]*Data.S[i][r] for i in 1:Data.N) for p in 1:Data.P) for r in 1:Data.R))

    # Résoudre le modèle
    optimize!(model_2)
    y_value = [value(y[r,p]) for r in 1:Data.R , p in 1:Data.P]
    return y_value ,objective_value(model_2)
end
valeur_initiale = 0.11
alpha1 = initialiser_multiplicateurs(Data.P, Data.N, valeur_initiale)
alpha2 = initialiser_multiplicateurs(Data.P, Data.N, valeur_initiale) 
model_maitre = Model(GLPK.Optimizer)
@variable(model_maitre, 0<=alpha[1:Data.P, 1:Data.N])
x_sol, obj_value_x= f1(alpha1)
y_sol , obj_value_y= f2(alpha1)
@objective(model_maitre,Min,obj_value_x + obj_value_y + sum(sum(alpha[p,i]*(sum(Data.Q[i][o] * x_sol[o, p] for o in 1:Data.O)-sum(Data.S[i][r] * y_sol[r, p] for r in 1:Data.R)) for i in 1:Data.N) for p in 1:Data.P))
optimize!(model_maitre)
object = objective_value(model_maitre)
println("================================================================================================================================")
println("prbm maitre final = ", object)

for  p in 1:Data.P, o in 1:Data.O
    println("x[$o,$p] = ", x_sol[o,p])
end
for r in 1:Data.R, p in 1:Data.P
    println("y[$r,$p] = ", y_sol[r,p])
end
println("Valeur optimale = ", f(x_sol, y_sol))