# Guide Rapide - Modélisation Puissance Éolienne
## Projet WEEX - Centrale Lyon

---

## Démarrage rapide (5 minutes)

### Étape 1: Ouvrir MATLAB
Lancez MATLAB et naviguez vers le dossier du projet:
```matlab
cd('/chemin/vers/WEEX-eolienne')
```

### Étape 2: Exécuter les scripts dans l'ordre

#### 2.1 Charger les données
```matlab
load_eolienne_data
```

**Ce script fait:**
- ✓ Charge le fichier `Eolien_Type15.txt`
- ✓ Nettoie les données (garde seulement statut=1)
- ✓ Affiche les statistiques
- ✓ Crée des visualisations initiales
- ✓ Identifie les paramètres clés (v_cut_in, v_rated, P_max)
- ✓ Sauvegarde dans `donnees_eolienne_clean.mat`

**Temps d'exécution:** ~10 secondes

---

#### 2.2A Modélisation physique avec rendement η (RECOMMANDÉ)
```matlab
modelisation_physique_eolienne
```

**Ce script fait:**
- ✓ Utilise la formule: **P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)**
- ✓ Calcule **ρ** avec la loi des gaz parfaits (P, T mesurés)
- ✓ Détermine le **rendement η** et le **diamètre D** par optimisation
- ✓ Compare modèle physique vs données
- ✓ Analyse le rendement en fonction de la vitesse
- ✓ Sauvegarde dans `modele_physique.mat`

**Temps d'exécution:** ~20-30 secondes

---

#### 2.2B Modélisation mathématique (alternative)
```matlab
modelisation_puissance_eolienne
```

**Ce script fait:**
- ✓ Applique 3 modèles différents (cubique, linéaire, polynomial)
- ✓ Compare leurs performances (RMSE, R²)
- ✓ Crée des visualisations comparatives
- ✓ Calcule les paramètres physiques (diamètre rotor, Cp)
- ✓ Sauvegarde dans `modeles_puissance.mat`

**Temps d'exécution:** ~15 secondes

---

#### 2.3 Optimiser les paramètres (optionnel)
```matlab
calibration_modele
```

**Ce script fait:**
- ✓ Optimise v_cut_in, v_rated, v_cut_out, P_rated
- ✓ Minimise l'erreur RMSE
- ✓ Compare avant/après optimisation
- ✓ Analyse les résidus
- ✓ Sauvegarde dans `modele_optimise.mat`

**Temps d'exécution:** ~30-60 secondes

---

## Fichiers créés

### Scripts MATLAB (.m)
| Fichier | Description | Exécution |
|---------|-------------|-----------|
| `load_eolienne_data.m` | Chargement et nettoyage des données | **1er** |
| `modelisation_puissance_eolienne.m` | Création des modèles | **2ème** |
| `calibration_modele.m` | Optimisation (optionnel) | **3ème** |
| `puissance_eolienne.m` | **Fonction** de modélisation | N/A (utilisée par les autres) |

### Fichiers de données générés (.mat)
| Fichier | Contenu | Créé par |
|---------|---------|----------|
| `donnees_eolienne_clean.mat` | Données nettoyées + paramètres initiaux | `load_eolienne_data.m` |
| `modeles_puissance.mat` | Résultats des 3 modèles | `modelisation_puissance_eolienne.m` |
| `modele_optimise.mat` | Paramètres optimisés | `calibration_modele.m` |

### Documentation (.md)
| Fichier | Description |
|---------|-------------|
| `EXPLICATIONS_MODELISATION.md` | Théorie complète, formules, explications |
| `GUIDE_RAPIDE.md` | Ce fichier - guide d'utilisation |

---

## Utiliser la fonction `puissance_eolienne()`

### Syntaxe de base
```matlab
P = puissance_eolienne(v, params)
```

### Exemple 1: Courbe simple
```matlab
% Définir les paramètres
params.v_cut_in = 3.5;     % Vitesse de démarrage (m/s)
params.v_rated = 12;       % Vitesse nominale (m/s)
params.v_cut_out = 25;     % Vitesse d'arrêt (m/s)
params.P_rated = 2.5e6;    % Puissance nominale (W)
params.model = 'polynomial';  % Type de modèle

% Créer vecteur de vitesses
v = 0:0.1:30;

% Calculer la puissance
P = puissance_eolienne(v, params);

% Tracer
figure;
plot(v, P/1e6, 'LineWidth', 2);
xlabel('Vitesse du vent (m/s)');
ylabel('Puissance (MW)');
title('Courbe de puissance - Modèle Polynomial');
grid on;
```

### Exemple 2: Comparer plusieurs modèles
```matlab
% Paramètres communs
params.v_cut_in = 3.5;
params.v_rated = 12;
params.v_cut_out = 25;
params.P_rated = 2.5e6;

% Vitesses
v = 0:0.1:30;

% Calculer pour chaque modèle
params.model = 'cubic';
P_cubic = puissance_eolienne(v, params);

params.model = 'linear';
P_linear = puissance_eolienne(v, params);

params.model = 'polynomial';
P_poly = puissance_eolienne(v, params);

% Tracer
figure;
hold on;
plot(v, P_cubic/1e6, 'r-', 'LineWidth', 2, 'DisplayName', 'Cubique');
plot(v, P_linear/1e6, 'b-', 'LineWidth', 2, 'DisplayName', 'Linéaire');
plot(v, P_poly/1e6, 'g-', 'LineWidth', 2, 'DisplayName', 'Polynomial');
hold off;
xlabel('Vitesse du vent (m/s)');
ylabel('Puissance (MW)');
title('Comparaison des modèles');
legend('Location', 'northwest');
grid on;
```

### Exemple 3: Utiliser les paramètres optimisés
```matlab
% Charger les paramètres optimisés
load('modele_optimise.mat', 'params_opt_struct');

% Calculer la puissance
v = 0:0.1:30;
P = puissance_eolienne(v, params_opt_struct);

% Tracer
plot(v, P/1e6, 'LineWidth', 2);
xlabel('Vitesse du vent (m/s)');
ylabel('Puissance (MW)');
title('Courbe de puissance - Modèle optimisé');
grid on;
```

---

## Figures générées

### Par `load_eolienne_data.m`
**Figure 1: "Analyse des données éoliennes"** (2×2 subplots)
1. Nuage de points: Puissance vs Vitesse du vent
2. Histogramme: Distribution des vitesses de vent
3. Histogramme: Distribution de la puissance
4. Rose des vents: Distribution des directions

### Par `modelisation_puissance_eolienne.m`
**Figure 2: "Comparaison des modèles de puissance"** (2×2 subplots)
1. Données + 3 modèles superposés
2. Zoom sur la zone de montée en puissance
3. Résidus du modèle polynomial
4. Histogramme des résidus

**Figure 3: "Modèle théorique vs données"**
- Comparaison entre le modèle physique (v³) et le meilleur fit

### Par `calibration_modele.m`
**Figure 4: "Comparaison: Paramètres initiaux vs optimisés"** (2×2 subplots)
1. Courbes avant/après optimisation
2. Zoom avec marqueurs des paramètres
3. Résidus avant optimisation
4. Résidus après optimisation

**Figure 5: "Analyse des résidus"** (1×2 subplots)
1. Histogrammes comparatifs des résidus
2. Q-Q plot (test de normalité)

---

## Résultats typiques attendus

### Paramètres identifiés
D'après les données Type 15, vous devriez obtenir environ:
- **v_cut_in:** 3-4 m/s
- **v_rated:** 10-13 m/s
- **v_cut_out:** 20-25 m/s
- **P_rated:** 2-3 MW

### Performance des modèles
Classement typique (du meilleur au moins bon):
1. **Polynomial:** R² ≈ 0.80-0.85, RMSE ≈ 200-300 kW
2. **Cubique:** R² ≈ 0.75-0.80, RMSE ≈ 250-350 kW
3. **Linéaire:** R² ≈ 0.70-0.75, RMSE ≈ 300-400 kW

### Paramètres physiques estimés
- **Diamètre du rotor (D):** 80-100 m (typique pour 2-3 MW)
- **Coefficient de puissance (Cp):** 0.40-0.50

---

## Dépannage

### Erreur: "Fichier de données non trouvé"
**Solution:** Exécutez d'abord `load_eolienne_data.m`

### Erreur: "Undefined function 'puissance_eolienne'"
**Solution:** Assurez-vous que `puissance_eolienne.m` est dans le répertoire courant
```matlab
pwd  % Afficher le répertoire actuel
dir  % Lister les fichiers
```

### Erreur lors de la lecture de `Eolien_Type15.txt`
**Solution:** Vérifiez le nom des colonnes dans le fichier
```matlab
% Lire manuellement pour vérifier
data = readtable('Eolien_Type15.txt');
data.Properties.VariableNames  % Afficher les noms de colonnes
```

### Les figures ne s'affichent pas
**Solution:**
```matlab
close all  % Fermer toutes les figures
figure     % Créer une nouvelle figure
```

### L'optimisation ne converge pas
**Solutions possibles:**
1. Ajuster les bornes dans `calibration_modele.m` (variables `lb` et `ub`)
2. Changer l'algorithme d'optimisation
3. Fournir de meilleurs paramètres initiaux

---

## Personnalisation

### Changer le type de modèle par défaut
Dans `puissance_eolienne.m`, ligne ~40:
```matlab
if ~isfield(params, 'model')
    params.model = 'polynomial';  % Changer ici
end
```

### Modifier les couleurs des graphiques
Exemple dans `modelisation_puissance_eolienne.m`:
```matlab
plot(v_model, P_cubic/1e6, 'r-', ...)   % Rouge
plot(v_model, P_linear/1e6, 'b-', ...)  % Bleu
plot(v_model, P_poly/1e6, 'g-', ...)    % Vert
```

### Ajouter un nouveau modèle
Dans `puissance_eolienne.m`, ajoutez un nouveau `case` dans le `switch`:
```matlab
case 'mon_modele'
    % Votre formule ici
    v_zone2 = v(idx_between);
    P(idx_between) = ... ;
```

---

## Pour la présentation

### Figures à inclure (recommandé)
1. Figure 1 (Subplot 1): Montre les données brutes
2. Figure 2 (Subplot 1): Comparaison des modèles
3. Figure 3: Modèle théorique vs fit
4. Figure 4 (Subplot 1): Si vous faites l'optimisation

### Points clés à mentionner
- ✓ Pourquoi la puissance est proportionnelle à v³
- ✓ Les 4 zones de fonctionnement
- ✓ La limite de Betz (Cp_max = 0.593)
- ✓ Quel modèle fonctionne le mieux et pourquoi
- ✓ Applications pratiques (prévision production, etc.)

### Démonstration live (si possible)
Montrer l'exécution de `load_eolienne_data.m` pour impressionner l'audience!

---

## Aller plus loin

### Améliorations possibles
1. **Inclure la température et la pression** pour corriger la densité de l'air
   ```matlab
   rho = P_atm / (R_air * T_kelvin)
   ```

2. **Filtrer par direction du vent** (analyser seulement certaines directions)

3. **Analyser la production annuelle** en utilisant les fichiers dans `2010/`

4. **Machine Learning** (réseaux de neurones, arbres de décision)

5. **Analyse de Weibull** pour la distribution des vitesses de vent

### Données supplémentaires
Les fichiers dans `2010/` contiennent des données journalières:
```matlab
% Exemple de lecture
data_2010 = readtable('2010/01A_2010.txt', 'HeaderLines', 1);
```

---

## Aide et support

### Ressources
- **Documentation MATLAB:** `doc nom_fonction`
- **Explications théoriques:** Lire `EXPLICATIONS_MODELISATION.md`
- **Code source commenté:** Tous les fichiers `.m` sont bien commentés

### Commandes utiles MATLAB
```matlab
help puissance_eolienne   % Aide sur la fonction
doc plot                  % Documentation complète
whos                      % Variables en mémoire
clear all                 % Effacer toutes les variables
close all                 % Fermer toutes les figures
clc                       % Effacer la console
```

---

## Checklist avant la présentation

- [ ] Tous les scripts s'exécutent sans erreur
- [ ] Les figures sont claires et lisibles
- [ ] Vous comprenez la théorie (limite de Betz, v³, etc.)
- [ ] Vous pouvez expliquer les 4 zones de fonctionnement
- [ ] Vous savez quel modèle fonctionne le mieux
- [ ] Vous avez vérifié les résultats (ordres de grandeur corrects)
- [ ] Les unités sont correctes (MW, m/s, etc.)
- [ ] Vous pouvez répondre aux questions sur Cp et le diamètre

---

**Bonne chance pour votre présentation!** 🎓

*Projet WEEX - Centrale Lyon - Novembre 2024*
