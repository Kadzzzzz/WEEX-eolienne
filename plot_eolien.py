import numpy as np
import matplotlib.pyplot as plt

# Charger et regrouper les données par vitesse
data = np.loadtxt('Eolien_Type15.txt', skiprows=1)
vent_unique = np.arange(0, 26, 0.5)
puissance_moy = []

for v in vent_unique:
    mask = (data[:, 0] >= v - 0.25) & (data[:, 0] < v + 0.25)
    if mask.sum() > 0:
        puissance_moy.append(data[mask, 2].mean() / 1e6)
    else:
        puissance_moy.append(0)

puissance_moy = np.array(puissance_moy)

# Calculer la dérivée et détecter les zones
deriv = np.diff(puissance_moy) / np.diff(vent_unique)
deriv = np.append(deriv, deriv[-1])

# Trouver début et fin de zone utile
debut = np.where(puissance_moy > 0.1)[0][0]  # Début: P > 0.1 MW
fin = np.where(deriv < 0.05 * deriv.max())[0]
fin = fin[fin > debut][0] if len(fin[fin > debut]) > 0 else len(vent_unique)

vent_filtre = vent_unique[debut:fin]
puissance_filtre = puissance_moy[debut:fin]

# Tracer
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(14, 5))
ax1.scatter(data[:, 0], data[:, 2]/1e6, alpha=0.2, s=3, label='Données brutes')
ax1.plot(vent_unique, puissance_moy, 'b-', linewidth=2, label='Moyenne')
ax1.plot(vent_filtre, puissance_filtre, 'r-', linewidth=3, label='Zone utile')
ax1.set_xlabel('Vitesse du vent (m/s)')
ax1.set_ylabel('Puissance (MW)')
ax1.set_title('Détection automatique de la zone utile')
ax1.legend()
ax1.grid(True, alpha=0.3)

ax2.plot(vent_unique, deriv)
ax2.axvline(vent_filtre[0], color='r', linestyle='--', label='Limites zone')
ax2.axvline(vent_filtre[-1], color='r', linestyle='--')
ax2.set_xlabel('Vitesse du vent (m/s)')
ax2.set_ylabel('dP/dv (MW/(m/s))')
ax2.set_title('Dérivée de la puissance')
ax2.legend()
ax2.grid(True, alpha=0.3)

plt.tight_layout()
plt.show()

print(f"Zone utile: {vent_filtre[0]:.1f} - {vent_filtre[-1]:.1f} m/s")
print(f"Points dans zone utile: {len(vent_filtre)}")
