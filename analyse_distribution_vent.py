import numpy as np
import matplotlib
matplotlib.use('Agg')  # Backend sans interface graphique
import matplotlib.pyplot as plt
from scipy import stats
from glob import glob

# Charger toutes les données de vitesse de vent
fichiers = glob('2010/*.txt')
vitesses = []

print(f"Nombre de fichiers trouvés: {len(fichiers)}")
if len(fichiers) == 0:
    print("ERREUR: Aucun fichier trouvé dans le dossier 2010/")
    exit()

print(f"Chargement des données...")
for f in fichiers:  # Charger tous les fichiers
    try:
        data = np.loadtxt(f, skiprows=2, encoding='latin-1')
        if len(data.shape) == 1:  # Une seule ligne
            vitesses.append(data[3])
        else:
            vitesses.extend(data[:, 3])  # Colonne vitesse
    except Exception as e:
        print(f"Erreur lecture {f}: {e}")

vitesses = np.array(vitesses)
print(f"Avant filtrage: {len(vitesses)} mesures")

vitesses = vitesses[~np.isnan(vitesses)]  # Enlever NaN
print(f"Après NaN: {len(vitesses)} mesures")

vitesses = vitesses[vitesses > 0]  # Enlever vitesses nulles
print(f"Après filtrage > 0: {len(vitesses)} mesures")

if len(vitesses) == 0:
    print("ERREUR: Aucune donnée valide trouvée!")
    exit()

print(f"\nVitesse moyenne: {vitesses.mean():.2f} m/s")
print(f"Écart-type: {vitesses.std():.2f} m/s")
print(f"Min: {vitesses.min():.2f}, Max: {vitesses.max():.2f} m/s\n")

# Ajuster la distribution de Weibull
print("Ajustement de la distribution de Weibull...\n")
k, loc, c = stats.weibull_min.fit(vitesses, floc=0)
ks_stat, p_value = stats.kstest(vitesses, lambda x: stats.weibull_min.cdf(x, k, loc, c))

print(f"{'='*50}")
print(f"PARAMÈTRES DE LA DISTRIBUTION DE WEIBULL")
print(f"{'='*50}")
print(f"Paramètre de forme (k): {k:.4f}")
print(f"Paramètre d'échelle (c): {c:.4f} m/s")
print(f"Localisation: {loc:.4f}")
print(f"\nQualité de l'ajustement:")
print(f"KS statistic: {ks_stat:.5f}")
print(f"p-value: {p_value:.4f}")
print(f"{'='*50}\n")

# Analyse du Q-Q plot pour détecter les déviations
print("ANALYSE DU Q-Q PLOT:")
print("-" * 50)

# Trier les données
vitesses_sorted = np.sort(vitesses)
n = len(vitesses_sorted)

# Calculer les quantiles théoriques et empiriques
quantiles_theoriques = np.zeros(n)
for i in range(n):
    p = (i + 0.5) / n  # Probabilité empirique
    quantiles_theoriques[i] = stats.weibull_min.ppf(p, k, loc, c)

# Calculer les déviations par rapport à la ligne idéale
deviations = np.abs(vitesses_sorted - quantiles_theoriques)
deviation_relative = deviations / (quantiles_theoriques + 1e-6)  # Éviter division par 0

# Détection du point de déviation (méthode: écart à la régression linéaire)
from scipy.stats import linregress
slope, intercept, r_value, p_value_reg, std_err = linregress(quantiles_theoriques, vitesses_sorted)

# Ligne de régression idéale
ligne_ideale = slope * quantiles_theoriques + intercept
residus = np.abs(vitesses_sorted - ligne_ideale)

# Détecter où les résidus dépassent un seuil (par ex. 2x l'écart-type des résidus)
seuil_deviation = 2 * np.std(residus[:int(0.7*n)])  # Calculer std sur les 70% premiers points
points_deviant = residus > seuil_deviation

# Trouver le premier point de déviation significative
idx_deviation = np.where(points_deviant)[0]
if len(idx_deviation) > 0:
    idx_debut_deviation = idx_deviation[0]
    quantile_deviation = (idx_debut_deviation / n) * 100
    valeur_deviation = vitesses_sorted[idx_debut_deviation]
    proportion_exclue = (n - idx_debut_deviation) / n * 100

    print(f"Point de déviation détecté:")
    print(f"  Quantile: {quantile_deviation:.1f}%")
    print(f"  Vitesse: {valeur_deviation:.2f} m/s")
    print(f"  Proportion à exclure: {proportion_exclue:.2f}% ({n - idx_debut_deviation} valeurs sur {n})")
    print(f"  Seuil de déviation utilisé: {seuil_deviation:.3f}")
else:
    print("Aucune déviation significative détectée")
    idx_debut_deviation = n
    proportion_exclue = 0

print(f"{'='*50}\n")

# Visualisation
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))

# Histogramme + distribution Weibull
ax1.hist(vitesses, bins=60, density=True, alpha=0.6, color='lightblue',
         edgecolor='black', label='Données observées')
x = np.linspace(0.1, vitesses.max(), 300)
pdf_weibull = stats.weibull_min.pdf(x, k, loc, c)
ax1.plot(x, pdf_weibull, 'r-', linewidth=3, label=f'Weibull(k={k:.2f}, c={c:.2f})')
ax1.set_xlabel('Vitesse du vent (m/s)', fontsize=11)
ax1.set_ylabel('Densité de probabilité', fontsize=11)
ax1.set_title('Ajustement Weibull des données de vent', fontsize=12, fontweight='bold')
ax1.legend(fontsize=10)
ax1.grid(True, alpha=0.3)

# Q-Q plot avec visualisation du point de déviation
stats.probplot(vitesses, dist=stats.weibull_min, sparams=(k, loc, c), plot=ax2)

# Marquer le point de déviation
if len(idx_deviation) > 0:
    # Points avant et après déviation
    ax2.plot(quantiles_theoriques[:idx_debut_deviation], vitesses_sorted[:idx_debut_deviation],
             'bo', markersize=3, label='Bon ajustement', alpha=0.6)
    ax2.plot(quantiles_theoriques[idx_debut_deviation:], vitesses_sorted[idx_debut_deviation:],
             'ro', markersize=3, label=f'Déviation ({proportion_exclue:.1f}%)', alpha=0.6)

    # Ligne verticale au point de déviation
    ax2.axvline(quantiles_theoriques[idx_debut_deviation], color='red',
                linestyle='--', linewidth=2, alpha=0.7, label=f'Seuil (Q{quantile_deviation:.0f}%)')
    ax2.legend(fontsize=9)

ax2.set_title('Q-Q plot (Weibull) - Détection de déviation', fontsize=12, fontweight='bold')
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('distribution_vent.png', dpi=150, bbox_inches='tight')
print("Graphique sauvegardé: distribution_vent.png\n")

# Exemple de simulation
print("SIMULATION:")
print("-" * 50)
n_simul = 365
vent_simule = stats.weibull_min.rvs(k, loc, c, size=n_simul)
print(f"Simulation de {n_simul} jours avec Weibull(k={k:.4f}, c={c:.4f}):")
print(f"  Vitesse moyenne simulée: {vent_simule.mean():.2f} m/s")
print(f"  Min: {vent_simule.min():.2f} m/s")
print(f"  Max: {vent_simule.max():.2f} m/s")
print(f"  Écart-type: {vent_simule.std():.2f} m/s")
