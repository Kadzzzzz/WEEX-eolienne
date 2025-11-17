# Structure du Projet - Où trouver quoi?
## Projet WEEX - Centrale Lyon

---

## 📋 Vue d'ensemble

Ce document explique **où se trouvent** les paramètres, équations et rendements dans le projet.

---

## 1️⃣ Paramètres de base de l'éolienne

### Fichier source: `load_eolienne_data.m`

**Lignes 124-143** - Identification automatique des paramètres:

```matlab
% Vitesse de démarrage (cut-in)
v_cut_in = min(vitesse_vent_valid(puissance_elec_valid > 10000));

% Vitesse nominale (rated speed)
P_max = max(puissance_elec_valid);
v_rated = min(vitesse_vent_valid(puissance_elec_valid >= 0.95*P_max));

% Vitesse d'arrêt (cut-out)
v_cut_out = max(vitesse_vent_valid);
```

**Sauvegardés dans:** `donnees_eolienne_clean.mat`

**Variables disponibles:**
- `v_cut_in` - Vitesse de démarrage (m/s)
- `v_rated` - Vitesse nominale (m/s)
- `v_cut_out` - Vitesse d'arrêt (m/s)
- `P_max` - Puissance maximale (W)
- `rho_air_valid` - Masse volumique pour chaque mesure (kg/m³)
- `vitesse_vent_valid` - Vitesses du vent (m/s)
- `puissance_elec_valid` - Puissances mesurées (W)

---

## 2️⃣ Calcul de la masse volumique ρ

### Fichier source: `load_eolienne_data.m`

**Lignes 44-75** - Loi des gaz parfaits:

```matlab
R_specific = 287;  % J/(kg·K) - Constante de l'air
temperature_K = temperature_celsius + 273.15;
rho_air = pression_atm / (R_specific * temperature_K);
```

**Formule:**
```
ρ = P_atm / (R × T)
```

Où:
- P_atm = pression atmosphérique mesurée (Pa)
- R = 287 J/(kg·K)
- T = température absolue (K)

**Résultat:** Un vecteur `rho_air_valid` avec une valeur de ρ pour **chaque mesure**.

---

## 3️⃣ Équations de modélisation

### A. Modèle physique avec rendement η

**Fichier:** `modelisation_physique_eolienne.m`

**L'équation principale** (lignes 174, 273):

```matlab
P = eta * (16/27) * rho * 0.5 * v^3 * (pi*D^2/4)
```

**Correspondance:**
```
P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```

**Variables:**
- `eta` = Rendement global (déterminé par optimisation)
- `D` = Diamètre du rotor en mètres (déterminé par optimisation)
- `rho` = Masse volumique de l'air (kg/m³)
- `v` = Vitesse du vent (m/s)

### B. Optimisation pour trouver η et D

**Lignes 91-120** - Algorithme d'optimisation:

```matlab
% Fonction objectif: minimise RMSE
objectif = @(params) calculer_erreur_physique(params, ...);

% Paramètres à optimiser: [eta, D]
params_init = [0.40; 90];  % Valeurs initiales

% Contraintes
lb = [0.20; 50];   % η_min = 0.20, D_min = 50 m
ub = [0.60; 150];  % η_max = 0.60, D_max = 150 m

% Optimisation
[params_opt, ~, ~] = fmincon(objectif, params_init, [], [], [], [], lb, ub);

eta_opt = params_opt(1);  % Rendement optimal
D_opt = params_opt(2);    % Diamètre optimal
```

**Résultats sauvegardés dans:** `modele_physique.mat`

**Variables disponibles:**
- `eta_opt` - Rendement optimal
- `D_opt` - Diamètre optimal (m)
- `R_opt` - Rayon optimal (m)
- `A_opt` - Surface balayée (m²)
- `Cp_equivalent` - Coefficient de puissance = η × (16/27)

### C. Modèles mathématiques (alternative)

**Fichier:** `puissance_eolienne.m`

Fonction avec 3 modèles:
- `'cubic'` - Modèle cubique: P ∝ v³
- `'linear'` - Modèle linéaire
- `'polynomial'` - Modèle polynomial (Hermite)

**Utilisation:**
```matlab
params.model = 'polynomial';
params.v_cut_in = 3.5;
params.v_rated = 12;
params.P_rated = 2.5e6;
P = puissance_eolienne(v, params);
```

---

## 4️⃣ Rendements - Comment les obtenir

### Méthode 1: Rendement global optimal

**Exécuter:**
```matlab
load_eolienne_data           % 1. Charger données
modelisation_physique_eolienne  % 2. Calculer η
```

**Puis charger:**
```matlab
load('modele_physique.mat');
fprintf('Rendement global: η = %.4f (%.2f%%)\n', eta_opt, eta_opt*100);
fprintf('Diamètre: D = %.2f m\n', D_opt);
```

### Méthode 2: Analyse détaillée des rendements

**Exécuter:**
```matlab
analyse_rendements  % Script complet d'analyse
```

**Ce script calcule:**
- ✓ Rendement global optimal (η_opt)
- ✓ Rendement effectif pour chaque mesure
- ✓ Rendement moyen par tranche de vitesse
- ✓ Distribution des rendements
- ✓ Décomposition théorique (η_aéro, η_méca, η_élec)
- ✓ Graphiques de visualisation (6 subplots)
- ✓ Export dans `resultats_rendements.txt`

### Méthode 3: Calcul manuel du rendement

**À partir des données:**
```matlab
load('donnees_eolienne_clean.mat');
load('modele_physique.mat');

% Pour une mesure donnée (exemple: mesure #100)
i = 100;
v = vitesse_vent_valid(i);
P_mesure = puissance_elec_valid(i);
rho = rho_air_valid(i);

% Puissance théorique maximale (Betz)
P_Betz = (16/27) * rho * 0.5 * v^3 * (pi*D_opt^2/4);

% Rendement effectif
eta_effectif = P_mesure / P_Betz;

fprintf('Rendement à %.1f m/s: η = %.4f\n', v, eta_effectif);
```

---

## 5️⃣ Workflow complet

### Ordre d'exécution recommandé:

```matlab
% Étape 1: Charger et préparer les données
load_eolienne_data
% → Crée: donnees_eolienne_clean.mat
% → Calcule: ρ avec loi des gaz parfaits
% → Identifie: v_cut_in, v_rated, P_max

% Étape 2: Modélisation physique avec rendement
modelisation_physique_eolienne
% → Détermine: η_opt et D_opt par optimisation
% → Crée: modele_physique.mat
% → Génère: 4 graphiques de visualisation

% Étape 3: Analyse détaillée des rendements
analyse_rendements
% → Calcule: rendements effectifs, statistiques
% → Génère: 6 graphiques d'analyse
% → Exporte: resultats_rendements.txt
```

---

## 6️⃣ Fichiers de résultats

### Après exécution, vous aurez:

| Fichier | Contenu |
|---------|---------|
| `donnees_eolienne_clean.mat` | Données nettoyées + ρ calculé + paramètres de base |
| `modele_physique.mat` | η_opt, D_opt, Cp_equivalent, courbes modèle |
| `resultats_rendements.txt` | Rapport textuel avec tous les rendements |

---

## 7️⃣ Équations clés - Récapitulatif

### Masse volumique (loi des gaz parfaits):
```
ρ = P_atm / (R_specific × T)
R_specific = 287 J/(kg·K)
T = T_celsius + 273.15
```

### Puissance de l'éolienne:
```
P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```

### Puissance maximale théorique (Betz):
```
P_Betz = (16/27) × ρ × (1/2) × V³ × (π×D²/4)
```

### Rendement effectif:
```
η = P_mesurée / P_Betz
```

### Coefficient de puissance:
```
Cp = η × (16/27)
Limite: Cp_max = 16/27 ≈ 0.593
```

### Rendement global décomposé:
```
η_total = η_aérodynamique × η_mécanique × η_électrique
```

Typiquement:
- η_aéro ≈ 0.70-0.80
- η_méca ≈ 0.95-0.98
- η_élec ≈ 0.90-0.95
- **η_total ≈ 0.35-0.50**

---

## 8️⃣ Variables importantes - Référence rapide

### Dans `donnees_eolienne_clean.mat`:
```matlab
vitesse_vent_valid      % Vitesses du vent [m/s]
puissance_elec_valid    % Puissances mesurées [W]
rho_air_valid           % Masse volumique [kg/m³]
pression_atm_valid      % Pression [Pa]
temperature_valid       % Température [°C]
v_cut_in                % Vitesse démarrage [m/s]
v_rated                 % Vitesse nominale [m/s]
v_cut_out               % Vitesse arrêt [m/s]
P_max                   % Puissance maximale [W]
R_specific              % Constante air = 287 [J/(kg·K)]
```

### Dans `modele_physique.mat`:
```matlab
eta_opt                 % Rendement optimal [-]
D_opt                   % Diamètre optimal [m]
R_opt                   % Rayon optimal [m]
A_opt                   % Surface balayée [m²]
Cp_equivalent           % Coeff. puissance [-]
v_model                 % Vecteur vitesses pour courbe
P_model                 % Puissances modélisées [W]
P_pred                  % Prédictions aux points mesure [W]
R2                      % Coefficient détermination
erreur_opt              % RMSE [W]
rho_mean                % ρ moyen [kg/m³]
```

---

## 9️⃣ Pour votre présentation

### Les chiffres importants à présenter:

1. **Rendement global**: η ≈ 0.40-0.45 (40-45%)
2. **Diamètre**: D ≈ 80-100 m
3. **Cp équivalent**: ≈ 0.24-0.27 (vs Betz max = 0.593)
4. **Efficacité vs Betz**: ≈ 40-45%

### Les équations à montrer:

1. **Masse volumique**: ρ = P/(R×T)
2. **Puissance**: P = η × (16/27) × ρ × ½ × V³ × πD²/4
3. **Rendement**: η = P_mesurée / P_Betz

### Les graphiques à inclure:

- Rendement en fonction de la vitesse (scatter plot)
- Distribution des rendements (histogramme)
- Puissance mesurée vs modèle
- Décomposition du rendement (pie chart)

---

## 🔍 Aide rapide - Commandes utiles

```matlab
% Voir toutes les variables d'un fichier .mat
load('modele_physique.mat');
whos

% Afficher le rendement
fprintf('η = %.4f\n', eta_opt);

% Afficher tous les paramètres
load('modele_physique.mat');
fprintf('Rendement: %.3f\n', eta_opt);
fprintf('Diamètre: %.1f m\n', D_opt);
fprintf('Cp: %.3f\n', Cp_equivalent);

% Recharger et réanalyser
clear all;
load_eolienne_data;
modelisation_physique_eolienne;
analyse_rendements;
```

---

**Auteurs:** Projet WEEX - Centrale Lyon
**Date:** Novembre 2024

---

Pour toute question, consultez:
- `EXPLICATIONS_PHYSIQUES.md` - Théorie détaillée
- `GUIDE_RAPIDE.md` - Guide d'utilisation
