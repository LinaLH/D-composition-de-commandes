using JuMP
using Cbc
#Pkg.add("Cbc")

# Assurez-vous que le fichier lecture.jl est dans le même répertoire
include("lecture.jl")

# Assumer que le nom du fichier des données est spécifié ici
#nomFichierDonnees = "Data_test_N12_R12_O12_RS8.txt"
# Lire les données
#lines = readlines(nomFichierDonnees)
#donnees = lecture(lines)

# Initialiser le modèle JuMP avec le solveur CBC
model = Model(Cbc.Optimizer)

# Supposons que les données soient maintenant dans la variable `donnees`
# Par exemple: donnees.N, donnees.R, donnees.O, etc.

# Variables de décision
@variable(model, x[1:Data.R, 1:Data.P], Bin)  # Affectation des racks aux préparateurs
@variable(model, y[1:Data.O, 1:Data.P], Bin)  # Affectation des commandes aux préparateurs
@variable(model, 0 <= v[1:Data.O] <= 1)
@variable(model, 0 <= u[1:Data.R] <= 1)


# Contraintes

#1
for o in Data.FO
    @constraint(model, sum(x[o, p] for p in 1:Data.P) == 1)
end

#2
for o in Data.SO
    @constraint(model, sum(x[o, p] for p in 1:Data.P) == v[o])
end

#3
for r in 1:Data.RS
    @constraint(model, sum(y[r, p] for p in 1:Data.P) == u[r])
end

#4
for p in Data.SO
    @constraint(model, sum(x[o, p] for o in 1:Data.O) <= Data.Capa[p])
end

#5
for r in 1:Data.RS for o in 1:Data.O
    @constraint(model, sum(s[i, r]*y[r, p] for i in 1:Data.N for p in 1:Data.P) >= sum(q[i, o]*x[o, p] for i in 1:Data.N for p in 1:Data.P))
end

# Fonction objectif
@objective(model, Min, sum(length(Data.SO)+1*u[r] for r in 1:Data.RS ) - sum(v[o] for o in Data.SO))

# Résoudre le modèle
optimize!(model)
println(model)
# Afficher les résultats
println("Solution optimale:")
for p in 1:Data.P
    for r in 1:Data.R
        if value(x[r,p]) > 0.5
            println("Rack $r assigné au préparateur $p")
        end
    end
end
end