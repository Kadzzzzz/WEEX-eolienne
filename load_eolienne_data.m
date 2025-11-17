% load_eolienne_data.m
% Script principal pour charger et analyser les données d'éolienne
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Ce script charge les données de l'éolienne Type 15 et permet d'analyser
% la relation entre la vitesse du vent et la puissance produite

clear all;
close all;
clc;

fprintf('=== Chargement des données d''éolienne ===\n\n');

%% 1. CHARGEMENT DES DONNÉES
% Charger le fichier de données de l'éolienne
filename = 'Eolien_Type15.txt';

% Lire les données avec readmatrix (plus robuste)
% Le fichier a une ligne d'en-tête et 6 colonnes
data_matrix = readmatrix(filename, 'NumHeaderLines', 1);

% Extraire les colonnes par index (plus fiable que par nom)
vitesse_vent = data_matrix(:, 1);    % Colonne 1: Vitesse du vent en m/s
direction_vent = data_matrix(:, 2);  % Colonne 2: Direction du vent en degrés
puissance_elec = data_matrix(:, 3);  % Colonne 3: Puissance électrique en W
pression_atm = data_matrix(:, 4);    % Colonne 4: Pression atmosphérique en Pa
temperature = data_matrix(:, 5);     % Colonne 5: Température en °C
statut = data_matrix(:, 6);          % Colonne 6: Statut de l'éolienne (0 ou 1)

fprintf('Nombre de mesures chargées: %d\n', length(vitesse_vent));
fprintf('Période de mesure: Données Type 15\n\n');

%% 2. NETTOYAGE DES DONNÉES
% Ne garder que les données avec statut = 1 (éolienne en fonctionnement normal)
idx_valid = (statut == 1);
vitesse_vent_valid = vitesse_vent(idx_valid);
puissance_elec_valid = puissance_elec(idx_valid);
pression_atm_valid = pression_atm(idx_valid);
temperature_valid = temperature(idx_valid);

fprintf('Nombre de mesures valides (statut = 1): %d\n', sum(idx_valid));
fprintf('Pourcentage de données valides: %.1f%%\n\n', 100*sum(idx_valid)/length(statut));

%% 2b. CALCUL DE LA MASSE VOLUMIQUE DE L'AIR (LOI DES GAZ PARFAITS)
% ρ = P / (R_specific × T)
% où:
%   P = pression atmosphérique (Pa)
%   R_specific = constante spécifique de l'air = 287 J/(kg·K)
%   T = température absolue (K) = T(°C) + 273.15

R_specific = 287;  % Constante spécifique de l'air sec [J/(kg·K)]

% Convertir la température en Kelvin
temperature_K_valid = temperature_valid + 273.15;

% Calculer la masse volumique pour chaque mesure
rho_air_valid = pression_atm_valid ./ (R_specific * temperature_K_valid);

fprintf('=== Masse volumique de l''air (loi des gaz parfaits) ===\n');
fprintf('Température:\n');
fprintf('  - Minimum: %.1f °C (%.1f K)\n', min(temperature_valid), min(temperature_K_valid));
fprintf('  - Maximum: %.1f °C (%.1f K)\n', max(temperature_valid), max(temperature_K_valid));
fprintf('  - Moyenne: %.1f °C (%.1f K)\n\n', mean(temperature_valid), mean(temperature_K_valid));

fprintf('Pression atmosphérique:\n');
fprintf('  - Minimum: %.0f Pa (%.0f hPa)\n', min(pression_atm_valid), min(pression_atm_valid)/100);
fprintf('  - Maximum: %.0f Pa (%.0f hPa)\n', max(pression_atm_valid), max(pression_atm_valid)/100);
fprintf('  - Moyenne: %.0f Pa (%.0f hPa)\n\n', mean(pression_atm_valid), mean(pression_atm_valid)/100);

fprintf('Masse volumique de l''air (ρ):\n');
fprintf('  - Minimum: %.4f kg/m³\n', min(rho_air_valid));
fprintf('  - Maximum: %.4f kg/m³\n', max(rho_air_valid));
fprintf('  - Moyenne: %.4f kg/m³\n', mean(rho_air_valid));
fprintf('  - Écart-type: %.4f kg/m³\n', std(rho_air_valid));
fprintf('  - Référence (15°C, 101325 Pa): 1.225 kg/m³\n\n');

%% 3. STATISTIQUES DESCRIPTIVES
fprintf('=== Statistiques des données ===\n');
fprintf('Vitesse du vent:\n');
fprintf('  - Minimum: %.2f m/s\n', min(vitesse_vent_valid));
fprintf('  - Maximum: %.2f m/s\n', max(vitesse_vent_valid));
fprintf('  - Moyenne: %.2f m/s\n', mean(vitesse_vent_valid));
fprintf('  - Écart-type: %.2f m/s\n\n', std(vitesse_vent_valid));

fprintf('Puissance électrique:\n');
fprintf('  - Minimum: %.0f W (%.2f kW)\n', min(puissance_elec_valid), min(puissance_elec_valid)/1000);
fprintf('  - Maximum: %.0f W (%.2f MW)\n', max(puissance_elec_valid), max(puissance_elec_valid)/1e6);
fprintf('  - Moyenne: %.0f W (%.2f kW)\n', mean(puissance_elec_valid), mean(puissance_elec_valid)/1000);
fprintf('  - Puissance nominale estimée: %.2f MW\n\n', max(puissance_elec_valid)/1e6);

%% 4. VISUALISATION INITIALE
figure('Name', 'Analyse des données éoliennes', 'Position', [100 100 1200 800]);

% Subplot 1: Nuage de points Puissance vs Vitesse
subplot(2,2,1);
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.3);
xlabel('Vitesse du vent (m/s)');
ylabel('Puissance électrique (MW)');
title('Relation Puissance-Vitesse du vent');
grid on;

% Subplot 2: Histogramme des vitesses de vent
subplot(2,2,2);
histogram(vitesse_vent_valid, 30, 'FaceColor', 'c', 'EdgeColor', 'k');
xlabel('Vitesse du vent (m/s)');
ylabel('Fréquence');
title('Distribution des vitesses de vent');
grid on;

% Subplot 3: Histogramme de la puissance
subplot(2,2,3);
histogram(puissance_elec_valid/1e6, 30, 'FaceColor', 'm', 'EdgeColor', 'k');
xlabel('Puissance électrique (MW)');
ylabel('Fréquence');
title('Distribution de la puissance produite');
grid on;

% Subplot 4: Rose des vents (direction)
subplot(2,2,4);
direction_valid = direction_vent(idx_valid);
polarhistogram(deg2rad(direction_valid), 36, 'FaceColor', 'g', 'EdgeColor', 'k');
title('Rose des vents - Distribution des directions');

%% 5. IDENTIFIER LES PARAMÈTRES CLÉS DE L'ÉOLIENNE
% Vitesse de démarrage (cut-in speed)
P_min = 10000; % 10 kW minimum pour considérer que l'éolienne produit
idx_producing = puissance_elec_valid > P_min;
v_cut_in = min(vitesse_vent_valid(idx_producing));

% Vitesse nominale (rated speed) - vitesse à laquelle la puissance max est atteinte
P_max = max(puissance_elec_valid);
P_rated = 0.95 * P_max; % 95% de la puissance max
idx_rated = puissance_elec_valid >= P_rated;
v_rated = min(vitesse_vent_valid(idx_rated));

% Vitesse d'arrêt (cut-out speed)
v_cut_out = max(vitesse_vent_valid);

fprintf('=== Paramètres identifiés de l''éolienne ===\n');
fprintf('Vitesse de démarrage (v_cut_in): %.2f m/s\n', v_cut_in);
fprintf('Vitesse nominale (v_rated): %.2f m/s\n', v_rated);
fprintf('Vitesse d''arrêt estimée (v_cut_out): %.2f m/s\n', v_cut_out);
fprintf('Puissance nominale (P_rated): %.2f MW\n\n', P_max/1e6);

%% 6. SAUVEGARDER LES DONNÉES NETTOYÉES
save('donnees_eolienne_clean.mat', 'vitesse_vent_valid', 'puissance_elec_valid', ...
     'rho_air_valid', 'pression_atm_valid', 'temperature_valid', ...
     'v_cut_in', 'v_rated', 'v_cut_out', 'P_max', 'R_specific');

fprintf('Données nettoyées sauvegardées dans: donnees_eolienne_clean.mat\n');
fprintf('\nExécutez "modelisation_puissance_eolienne.m" pour la modélisation.\n');
