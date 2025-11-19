import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from scipy import stats

# ===== PARAMÈTRES À AJUSTER =====
# Case du maillage à simuler
case_maillage = "01A"  # À modifier selon votre choix

# Paramètres Weibull (trouvés précédemment pour toutes les cases)
# Si vous voulez des paramètres spécifiques à la case, chargez les données de cette case
k_weibull = 1.810  # Paramètre de forme
c_weibull = 10.961  # Paramètre d'échelle (m/s)

# Paramètres de l'éolienne
diametre_rotor = 90  # mètres (à ajuster selon votre éolienne)
rayon = diametre_rotor / 2
aire_balayee = np.pi * rayon**2  # m²
rendement_eta = 0.40  # À ajuster selon votre valeur trouvée (ex: 0.35-0.45)
rho_air = 1.225  # kg/m³ (densité de l'air au niveau de la mer, 15°C)

# Simulation
n_heures = 8760  # 1 an = 365 jours × 24 heures
print(f"{'='*60}")
print(f"SIMULATION DE PRODUCTION ÉOLIENNE")
print(f"{'='*60}")
print(f"Case: {case_maillage}")
print(f"Durée: {n_heures} heures (1 an)")
print(f"\nParamètres Weibull:")
print(f"  k = {k_weibull:.3f}")
print(f"  c = {c_weibull:.3f} m/s")
print(f"\nParamètres éolienne:")
print(f"  Diamètre rotor: {diametre_rotor} m")
print(f"  Aire balayée: {aire_balayee:.1f} m²")
print(f"  Rendement η: {rendement_eta:.2f}")
print(f"  Densité air ρ: {rho_air} kg/m³")
print(f"{'='*60}\n")

# Générer les vitesses de vent aléatoires selon Weibull
np.random.seed(42)  # Pour reproductibilité
vitesses_vent = stats.weibull_min.rvs(k_weibull, 0, c_weibull, size=n_heures)

# Calculer la puissance instantanée pour chaque heure
# Formule: P = 0.5 × η × ρ × A × v³
puissance_instantanee = 0.5 * rendement_eta * rho_air * aire_balayee * vitesses_vent**3

# Convertir en MW
puissance_MW = puissance_instantanee / 1e6

# Statistiques
energie_totale_MWh = puissance_MW.sum()  # Somme sur toutes les heures
puissance_moyenne_MW = puissance_MW.mean()
facteur_charge = (energie_totale_MWh / n_heures) / puissance_MW.max() * 100

print("RÉSULTATS:")
print("-" * 60)
print(f"Vitesse moyenne du vent: {vitesses_vent.mean():.2f} m/s")
print(f"Vitesse max du vent: {vitesses_vent.max():.2f} m/s")
print(f"\nPuissance moyenne: {puissance_moyenne_MW:.3f} MW")
print(f"Puissance maximale: {puissance_MW.max():.3f} MW")
print(f"\nÉnergie totale produite: {energie_totale_MWh:.1f} MWh/an")
print(f"Facteur de charge: {facteur_charge:.1f}%")
print(f"\nÉnergie par jour (moyenne): {energie_totale_MWh/365:.2f} MWh/jour")
print(f"{'='*60}\n")

# Visualisation
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))

# 1. Distribution des vitesses de vent simulées
ax1.hist(vitesses_vent, bins=50, density=True, alpha=0.6, color='lightblue', edgecolor='black')
x = np.linspace(0, vitesses_vent.max(), 200)
ax1.plot(x, stats.weibull_min.pdf(x, k_weibull, 0, c_weibull), 'r-', lw=2, label='Weibull théorique')
ax1.set_xlabel('Vitesse du vent (m/s)')
ax1.set_ylabel('Densité')
ax1.set_title('Distribution des vitesses de vent simulées')
ax1.legend()
ax1.grid(True, alpha=0.3)

# 2. Courbe de puissance P(v)
v_range = np.linspace(0, 30, 100)
p_range = 0.5 * rendement_eta * rho_air * aire_balayee * v_range**3 / 1e6
ax2.plot(v_range, p_range, 'b-', lw=2)
ax2.scatter(vitesses_vent[::100], puissance_MW[::100], alpha=0.3, s=10, c='red', label='Points simulés')
ax2.set_xlabel('Vitesse du vent (m/s)')
ax2.set_ylabel('Puissance (MW)')
ax2.set_title('Courbe de puissance P = 0.5·η·ρ·A·v³')
ax2.grid(True, alpha=0.3)
ax2.legend()

# 3. Série temporelle (30 premiers jours)
heures_affichage = 30 * 24
ax3.plot(range(heures_affichage), puissance_MW[:heures_affichage], linewidth=0.8)
ax3.set_xlabel('Heures')
ax3.set_ylabel('Puissance (MW)')
ax3.set_title('Production sur les 30 premiers jours')
ax3.grid(True, alpha=0.3)

# 4. Distribution de la puissance
ax4.hist(puissance_MW, bins=60, alpha=0.6, color='green', edgecolor='black')
ax4.axvline(puissance_moyenne_MW, color='red', linestyle='--', linewidth=2, label=f'Moyenne: {puissance_moyenne_MW:.2f} MW')
ax4.set_xlabel('Puissance (MW)')
ax4.set_ylabel('Fréquence')
ax4.set_title('Distribution de la puissance produite')
ax4.legend()
ax4.grid(True, alpha=0.3)

plt.tight_layout()
plt.savefig('simulation_eolienne.png', dpi=150, bbox_inches='tight')
print("Graphique sauvegardé: simulation_eolienne.png")

# Sauvegarder les résultats dans un fichier
with open(f'resultats_simulation_{case_maillage}.txt', 'w') as f:
    f.write(f"SIMULATION PRODUCTION ÉOLIENNE - Case {case_maillage}\n")
    f.write(f"{'='*60}\n\n")
    f.write(f"Paramètres Weibull: k={k_weibull:.3f}, c={c_weibull:.3f} m/s\n")
    f.write(f"Éolienne: D={diametre_rotor}m, η={rendement_eta:.2f}\n\n")
    f.write(f"Énergie totale: {energie_totale_MWh:.1f} MWh/an\n")
    f.write(f"Puissance moyenne: {puissance_moyenne_MW:.3f} MW\n")
    f.write(f"Facteur de charge: {facteur_charge:.1f}%\n")

print(f"\nRésultats sauvegardés: resultats_simulation_{case_maillage}.txt")
