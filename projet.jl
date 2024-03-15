using JuMP
using CBC

# Assurez-vous que le fichier lecture.jl est dans le même répertoire
include("lecture.jl")

# Assumer que le nom du fichier des données est spécifié ici
#nomFichierDonnees = "Data_test_N12_R12_O12_RS8.txt"
# Lire les données
#lines = readlines(nomFichierDonnees)
#donnees = lecture(lines)

# Initialiser le modèle JuMP avec le solveur CBC
model = Model(CBC.Optimizer)

# Supposons que les données soient maintenant dans la variable `donnees`
# Par exemple: donnees.N, donnees.R, donnees.O, etc.

# Variables de décision
@variable(model, x[1:donnees.R, 1:donnees.P], Bin)  # Affectation des racks aux préparateurs
@variable(model, y[1:donnees.O, 1:donnees.P], Bin)  # Affectation des commandes aux préparateurs
@variable(model, 0 <= v[1:donnees.O] <= 1)
@variable(model, 0 <= u[1:donnees.R] <= 1)


# Contraintes

#1
for o in donnees.FO
    @constraint(model, sum(x[o, p] for p in 1:donnees.P) == 1)
end

#2
for o in donnees.SO
    @constraint(model, sum(x[o, p] for p in 1:donnees.P) == v0)
end

#3
for r in donnees.RS
    @constraint(model, sum(y[r, p] for p in 1:donnees.P) == ur)
end

#4
for p in donnees.SO
    @constraint(model, sum(x[o, p] for o in 1:donnees.O) <= donnees.Capa[p])
end

#5
for r in donnees.RS for o in 1:donnees.O
    @constraint(model, sum(s[i, r]*y[r, p] for i in 1:donnees.N for p in 1:donnees.P) <= sum(q[i, o]*x[o, p] for i in 1:donnees.N for p in 1:donnees.P))
end

# Fonction objectif
@objective(model, Min, sum(abs(S)+1*ur for i in 1:donnees.R) - sum(v[o] for o in donnees.SO))

# Résoudre le modèle
optimize!(model)

# Afficher les résultats
# Vous pouvez afficher les résultats de l'optimisation ici, par exemple:
println("Solution optimale:")
for p in 1:donnees.P
    for r in 1:donnees.R
        if value(x[r,p]) > 0.5
            println("Rack $r assigné au préparateur $p")
        end
    end
end
