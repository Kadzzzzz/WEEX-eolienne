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

fprintf('Nombre de mesures valides (statut = 1): %d\n', sum(idx_valid));
fprintf('Pourcentage de données valides: %.1f%%\n\n', 100*sum(idx_valid)/length(statut));

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
     'v_cut_in', 'v_rated', 'v_cut_out', 'P_max');

fprintf('Données nettoyées sauvegardées dans: donnees_eolienne_clean.mat\n');
fprintf('\nExécutez "modelisation_puissance_eolienne.m" pour la modélisation.\n');
