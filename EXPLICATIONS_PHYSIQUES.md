# Modélisation Physique avec Rendement η
## Projet Centrale Lyon - WEEX

---

## 1. Formule utilisée

### Formule complète:
```
P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```

### Signification de chaque terme:

| Symbole | Nom | Unité | Description |
|---------|-----|-------|-------------|
| **P** | Puissance électrique | W | Puissance produite par l'éolienne |
| **η** | Rendement global | - | Rendement de l'éolienne (à déterminer) |
| **16/27** | Limite de Betz | - | ≈ 0.593, coefficient de puissance maximal théorique |
| **ρ** | Masse volumique | kg/m³ | Densité de l'air (calculée avec loi des gaz parfaits) |
| **V** | Vitesse du vent | m/s | Vitesse du vent incident |
| **D** | Diamètre du rotor | m | Diamètre balayé par les pales |
| **π×D²/4** | Surface balayée | m² | Surface du disque balayé = π×R² |

---

## 2. Calcul de la masse volumique ρ

### Loi des gaz parfaits:
```
ρ = P_atm / (R_specific × T)
```

**Avec:**
- **P_atm** = pression atmosphérique mesurée (Pa)
- **R_specific** = 287 J/(kg·K) = constante spécifique de l'air sec
- **T** = température absolue (K) = T(°C) + 273.15

**Pourquoi cette formule?**

L'équation d'état des gaz parfaits est:
```
P × V = n × R × T
```

Pour l'air, on peut l'écrire:
```
P = ρ × R_specific × T
```

D'où:
```
ρ = P / (R_specific × T)
```

**Valeur typique:**
- À 15°C et 101325 Pa (niveau de la mer): ρ ≈ 1.225 kg/m³
- Vos données donneront des valeurs variables selon P et T

---

## 3. Interprétation du rendement η

### Que représente η?

Le rendement **η** combine **tous les rendements** de la chaîne de conversion:

```
η = η_aérodynamique × η_mécanique × η_électrique
```

**Détails:**

1. **η_aérodynamique** ≈ 0.70-0.80
   - Efficacité de l'extraction de l'énergie du vent
   - Dépend du design des pales, du TSR (Tip Speed Ratio)
   - Inclut les pertes aérodynamiques

2. **η_mécanique** ≈ 0.95-0.98
   - Pertes dans la transmission (engrenages, roulements)
   - Pertes par friction

3. **η_électrique** ≈ 0.90-0.95
   - Rendement du générateur
   - Pertes dans l'onduleur/convertisseur

**Valeur typique globale:**
```
η ≈ 0.35 - 0.50
```

### Relation avec Cp

Le coefficient de puissance **Cp** utilisé traditionnellement est:
```
Cp = η × (16/27)
```

**Exemple:**
- Si η = 0.45, alors Cp = 0.45 × 0.593 = 0.267
- Ce qui est réaliste pour une éolienne moderne

---

## 4. Méthodologie de détermination de η et D

### Approche 1: Points à puissance nominale

On utilise les mesures où l'éolienne fonctionne à puissance maximale:

```
P_max = η × (16/27) × ρ × (1/2) × V_rated³ × (π×D²/4)
```

On peut calculer:
```
η × D² = P_max / [(16/27) × ρ × (1/2) × V_rated³ × (π/4)]
```

**Problème:** On a **une équation, deux inconnues** (η et D)

### Approche 2: Optimisation

On minimise l'erreur entre puissance mesurée et modélisée:

```
min RMSE = sqrt(mean((P_mesuré - P_modèle)²))
```

En variant **η** et **D** simultanément.

**Contraintes:**
- 0.20 ≤ η ≤ 0.60 (rendement physiquement réaliste)
- 50 m ≤ D ≤ 150 m (diamètre typique pour éoliennes MW)

---

## 5. Zones de fonctionnement

La courbe de puissance a toujours **4 zones**:

### Zone 1: v < v_cut_in (arrêt)
```
P = 0
```

### Zone 2: v_cut_in ≤ v < v_rated (montée)
```
P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```
**La puissance augmente avec V³**

### Zone 3: v_rated ≤ v < v_cut_out (nominale)
```
P = P_rated (constant)
```
**Contrôle de l'angle des pales (pitch control)**

### Zone 4: v ≥ v_cut_out (arrêt sécurité)
```
P = 0
```

---

## 6. Simplification de la formule

La formule peut s'écrire sous différentes formes:

### Forme 1 (originale):
```
P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```

### Forme 2 (avec surface A):
```
A = π × D² / 4
P = η × (16/27) × (1/2) × ρ × A × V³
```

### Forme 3 (simplifiée):
```
P = η × (2π/27) × ρ × D² × V³
```
Car: (16/27) × (1/2) × (π/4) = (2π/27)

### Forme 4 (avec rayon R):
```
P = η × (8π²/27) × ρ × R² × V³
```

---

## 7. Exemple de calcul numérique

### Données:
- η = 0.40
- D = 90 m → R = 45 m → A = π × 45² = 6362 m²
- ρ = 1.20 kg/m³ (calculé avec P et T)
- V = 10 m/s

### Calcul:
```
P = 0.40 × (16/27) × 1.20 × (1/2) × 10³ × 6362
P = 0.40 × 0.593 × 1.20 × 0.5 × 1000 × 6362
P = 0.40 × 0.593 × 0.6 × 1000 × 6362
P ≈ 903 000 W = 903 kW
```

### Vérification avec forme simplifiée:
```
P = η × (2π/27) × ρ × D² × V³
P = 0.40 × (2π/27) × 1.20 × 90² × 10³
P = 0.40 × 0.233 × 1.20 × 8100 × 1000
P ≈ 903 000 W ✓
```

---

## 8. Résultats attendus

### Avec vos données Eolien_Type15.txt:

D'après l'optimisation, vous devriez obtenir environ:

| Paramètre | Valeur attendue | Unité |
|-----------|-----------------|-------|
| **η** | 0.35 - 0.50 | - |
| **D** | 80 - 100 | m |
| **R** | 40 - 50 | m |
| **A** | 5000 - 8000 | m² |
| **Cp** | 0.21 - 0.30 | - |

### Interprétation:

- **η = 0.40** signifie 40% de rendement par rapport à la limite de Betz
- **Cp = 0.40 × 0.593 = 0.237** est le coefficient de puissance effectif
- **D ≈ 90 m** est cohérent avec une éolienne de 2-3 MW

---

## 9. Avantages de cette approche

### Par rapport au modèle classique avec Cp:

✅ **Séparation claire** entre:
   - Limite théorique (16/27)
   - Rendement réel (η)

✅ **Utilisation de ρ variable** calculée à chaque mesure

✅ **Interprétation physique** de η

✅ **Permet d'analyser** comment η varie avec V

---

## 10. Utilisation dans MATLAB

### Ordre d'exécution:

```matlab
% 1. Charger les données et calculer ρ
load_eolienne_data

% 2. Déterminer η et D
modelisation_physique_eolienne

% 3. Analyser les résultats
```

### Résultats affichés:

Le script affiche:
- **η optimal** et **D optimal**
- **RMSE** et **R²** du modèle
- **Cp équivalent**
- **Graphiques** comparatifs

---

## 11. Pour aller plus loin

### Analyse du rendement variable:

On peut analyser comment **η varie** avec:
- La vitesse du vent V
- La température T
- La pression P
- La direction du vent

### Formule générale:
```
η(V) = P_mesuré / [P_théorique_Betz(V)]
```

Où:
```
P_théorique_Betz(V) = (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```

---

## 12. Questions pour la présentation

### Q1: Pourquoi 16/27?
**R:** C'est la limite de Betz qui démontre qu'une éolienne ne peut extraire plus de 59.3% de l'énergie cinétique du vent.

### Q2: Pourquoi η < 1?
**R:** η représente le rendement réel de toute la chaîne de conversion (aérodynamique + mécanique + électrique).

### Q3: Que vaut η pour une bonne éolienne?
**R:** Typiquement η ≈ 0.40-0.45 pour une éolienne moderne bien conçue.

### Q4: Comment améliorer η?
**R:**
- Optimiser le design des pales
- Réduire les pertes mécaniques
- Améliorer le rendement du générateur
- Contrôle optimal de l'angle des pales

---

## 13. Tableau récapitulatif

| Grandeur | Formule | Ce qu'elle représente |
|----------|---------|----------------------|
| **Puissance du vent** | P_vent = (1/2) × ρ × A × V³ | Énergie cinétique disponible |
| **Puissance Betz** | P_Betz = (16/27) × (1/2) × ρ × A × V³ | Maximum théorique extractible |
| **Puissance réelle** | P = η × P_Betz | Puissance effectivement produite |
| **ρ** | P_atm / (R × T) | Masse volumique réelle de l'air |

---

## Auteurs
**Projet WEEX - Centrale Lyon**

Date: Novembre 2024

---

**Bonne chance pour votre présentation!** 🎓
