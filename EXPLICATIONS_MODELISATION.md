# Modélisation de la Puissance Éolienne
## Projet Centrale Lyon - WEEX

---

## Table des matières
1. [Introduction](#introduction)
2. [Théorie physique](#théorie-physique)
3. [Modèles implémentés](#modèles-implémentés)
4. [Structure du code](#structure-du-code)
5. [Utilisation](#utilisation)
6. [Résultats attendus](#résultats-attendus)
7. [Références](#références)

---

## 1. Introduction

Ce projet vise à modéliser la **puissance électrique produite par une éolienne** en fonction de la **vitesse du vent**.

### Objectifs:
- Analyser les données réelles de l'éolienne Type 15
- Comprendre la relation entre vitesse du vent et puissance produite
- Développer plusieurs modèles mathématiques
- Comparer les performances des différents modèles
- Estimer les paramètres physiques de l'éolienne

---

## 2. Théorie physique

### 2.1 Formule fondamentale de Betz

La puissance théorique maximale qu'une éolienne peut extraire du vent est donnée par:

```
P = (1/2) × ρ × A × Cp × v³
```

Où:
- **P** = Puissance mécanique (W)
- **ρ** = Densité de l'air (≈ 1.225 kg/m³ au niveau de la mer à 15°C)
- **A** = Surface balayée par les pales = π × R² (m²)
- **R** = Rayon des pales (m)
- **Cp** = Coefficient de puissance (sans dimension)
- **v** = Vitesse du vent (m/s)

### 2.2 Limite de Betz

La limite de Betz établit que **Cp ≤ 16/27 ≈ 0.593**

En pratique, les éoliennes modernes atteignent:
- Cp ≈ 0.45 - 0.50 pour les meilleures éoliennes
- Cp ≈ 0.35 - 0.45 pour les éoliennes moyennes

### 2.3 Courbe de puissance réelle

La courbe de puissance d'une éolienne se divise en **4 zones**:

```
    P_rated  |        ┌─────────────────────
             |       /
             |      /
             |     /
             |    /
             |   /
             |  /
           0 |──┘                         └──
             └──────────────────────────────────
                v_cut_in  v_rated   v_cut_out    v
```

#### **Zone 1: v < v_cut_in** (Vitesse de démarrage)
- L'éolienne ne tourne pas
- P = 0
- Typiquement: v_cut_in ≈ 3-4 m/s

#### **Zone 2: v_cut_in ≤ v < v_rated** (Montée en puissance)
- La puissance augmente rapidement
- Relation proche de v³
- C'est la zone la plus complexe à modéliser

#### **Zone 3: v_rated ≤ v < v_cut_out** (Puissance nominale)
- La puissance est maintenue constante à P_rated
- Le système de contrôle régule l'angle des pales (pitch control)
- Typiquement: v_rated ≈ 11-13 m/s

#### **Zone 4: v ≥ v_cut_out** (Arrêt de sécurité)
- L'éolienne s'arrête pour éviter les dommages
- P = 0
- Typiquement: v_cut_out ≈ 25 m/s

---

## 3. Modèles implémentés

Nous avons implémenté **3 modèles** pour la zone de montée en puissance:

### 3.1 Modèle Cubique

Basé sur la théorie physique (proportionnel à v³):

```matlab
P(v) = P_rated × [(v³ - v_cut_in³) / (v_rated³ - v_cut_in³)]
```

**Avantages:**
- Fondé physiquement
- Simple

**Inconvénients:**
- Peut ne pas capturer toutes les non-linéarités

### 3.2 Modèle Linéaire

Approximation linéaire simple:

```matlab
P(v) = P_rated × [(v - v_cut_in) / (v_rated - v_cut_in)]
```

**Avantages:**
- Très simple
- Facile à comprendre

**Inconvénients:**
- Pas réaliste physiquement
- Moins précis

### 3.3 Modèle Polynomial (Hermite)

Utilise un polynôme de Hermite d'ordre 3:

```matlab
v_norm = (v - v_cut_in) / (v_rated - v_cut_in)
P(v) = P_rated × (3×v_norm² - 2×v_norm³)
```

**Avantages:**
- Transition douce (dérivées nulles aux bornes)
- Bon compromis entre précision et simplicité
- Comportement régulier

**Inconvénients:**
- Moins intuitif physiquement

---

## 4. Structure du code

### 4.1 Fichiers MATLAB créés

```
WEEX-eolienne/
│
├── load_eolienne_data.m              # Script principal de chargement
├── puissance_eolienne.m              # Fonction de modélisation
├── modelisation_puissance_eolienne.m # Script de visualisation
├── calibration_modele.m              # Optimisation des paramètres
├── EXPLICATIONS_MODELISATION.md      # Ce fichier
│
└── Données/
    ├── Eolien_Type15.txt             # Données brutes
    ├── donnees_eolienne_clean.mat    # Données nettoyées (généré)
    └── modeles_puissance.mat         # Résultats modélisation (généré)
```

### 4.2 Workflow d'utilisation

```
1. load_eolienne_data.m
   ↓
   Charge et nettoie les données
   Identifie v_cut_in, v_rated, P_max
   Sauvegarde: donnees_eolienne_clean.mat
   ↓
2. modelisation_puissance_eolienne.m
   ↓
   Applique les 3 modèles
   Calcule RMSE et R²
   Génère visualisations
   Sauvegarde: modeles_puissance.mat
   ↓
3. calibration_modele.m (optionnel)
   ↓
   Optimise v_cut_in, v_rated pour minimiser RMSE
```

---

## 5. Utilisation

### 5.1 Première exécution

```matlab
% 1. Charger et analyser les données
run('load_eolienne_data.m')

% 2. Créer les modèles et visualisations
run('modelisation_puissance_eolienne.m')

% 3. (Optionnel) Optimiser les paramètres
run('calibration_modele.m')
```

### 5.2 Utiliser la fonction de modélisation

```matlab
% Définir les paramètres
params.v_cut_in = 3.5;    % m/s
params.v_rated = 12;      % m/s
params.v_cut_out = 25;    % m/s
params.P_rated = 2.5e6;   % W (2.5 MW)
params.model = 'polynomial';

% Calculer la puissance pour différentes vitesses
v = 0:0.5:30;  % Vitesses de 0 à 30 m/s
P = puissance_eolienne(v, params);

% Tracer la courbe
plot(v, P/1e6);
xlabel('Vitesse du vent (m/s)');
ylabel('Puissance (MW)');
title('Courbe de puissance');
grid on;
```

---

## 6. Résultats attendus

### 6.1 Visualisations générées

Le script `modelisation_puissance_eolienne.m` génère plusieurs figures:

1. **Figure 1 - Analyse des données:**
   - Nuage de points Puissance vs Vitesse
   - Distribution des vitesses de vent
   - Distribution de la puissance
   - Rose des vents

2. **Figure 2 - Comparaison des modèles:**
   - Courbes des 3 modèles superposées aux données
   - Zoom sur la zone de montée en puissance
   - Analyse des résidus
   - Distribution des erreurs

3. **Figure 3 - Modèle théorique:**
   - Comparaison modèle physique vs meilleur fit
   - Estimation du diamètre du rotor

### 6.2 Métriques de performance

Pour chaque modèle, nous calculons:

- **RMSE (Root Mean Square Error):**
  ```
  RMSE = sqrt(mean((P_mesure - P_modele)²))
  ```
  Plus faible est meilleur (en kW ou MW)

- **R² (Coefficient de détermination):**
  ```
  R² = 1 - (Somme_résidus² / Somme_totale²)
  ```
  Plus proche de 1 est meilleur (0 ≤ R² ≤ 1)

### 6.3 Paramètres estimés

À partir des données, nous estimons:
- Vitesse de démarrage (v_cut_in)
- Vitesse nominale (v_rated)
- Puissance nominale (P_rated)
- Diamètre du rotor (D)
- Coefficient de puissance (Cp)

---

## 7. Références

### 7.1 Documentation technique

- **Limite de Betz:** Betz, A. (1920). "Das Maximum der theoretisch möglichen Ausnutzung des Windes durch Windmotoren"

- **Norme IEC 61400:** Standards internationaux pour éoliennes

- **Courbes de puissance:** IEC 61400-12-1: Power performance measurements

### 7.2 Concepts clés

- **Cp (Coefficient de puissance):** Efficacité de conversion de l'énergie cinétique du vent
- **TSR (Tip Speed Ratio):** Rapport entre vitesse bout de pale et vitesse du vent
- **Pitch control:** Contrôle de l'angle des pales pour réguler la puissance
- **Cut-in/Cut-out:** Vitesses de démarrage et d'arrêt de sécurité

### 7.3 Formules utiles

**Énergie cinétique du vent:**
```
E_cin = (1/2) × m × v² = (1/2) × ρ × Volume × v²
```

**Puissance du vent disponible:**
```
P_vent = (1/2) × ρ × A × v³
```

**Puissance électrique:**
```
P_elec = P_vent × Cp × η_meca × η_elec
```

Où:
- η_meca ≈ 0.95 (rendement mécanique)
- η_elec ≈ 0.95 (rendement électrique)

---

## Auteurs
**Projet WEEX - Centrale Lyon**

Date: Novembre 2024

---

## Notes pour la présentation

### Points clés à présenter:

1. **Pourquoi v³?** L'énergie cinétique est proportionnelle à v², mais la puissance est énergie par temps, donc on a un facteur v supplémentaire.

2. **Pourquoi la puissance plafonne?** Pour protéger le générateur et la structure mécanique.

3. **Quel modèle choisir?** Le modèle polynomial offre généralement le meilleur compromis.

4. **Applications pratiques:**
   - Prévision de production
   - Dimensionnement de parcs éoliens
   - Maintenance prédictive
   - Optimisation du rendement

### Questions possibles:

**Q: Pourquoi y a-t-il autant de dispersion dans les données?**
R: Turbulence, direction du vent, température, pression, inertie du système, erreurs de mesure.

**Q: Comment améliorer le modèle?**
R: Inclure température, pression, direction du vent, utiliser machine learning.

**Q: Quelle est la différence entre puissance mécanique et électrique?**
R: Pertes dans le générateur et la transmission (rendement ≈ 90-95%).

