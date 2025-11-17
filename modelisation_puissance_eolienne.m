% modelisation_puissance_eolienne.m
% Script de modélisation et visualisation de la courbe de puissance
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Ce script utilise les données chargées pour créer différents modèles
% de la courbe de puissance et comparer leurs performances

clear all;
close all;
clc;

fprintf('=== Modélisation de la puissance éolienne ===\n\n');

%% 1. CHARGER LES DONNÉES NETTOYÉES
if ~exist('donnees_eolienne_clean.mat', 'file')
    error('Fichier de données non trouvé. Exécutez d''abord "load_eolienne_data.m"');
end

load('donnees_eolienne_clean.mat');
fprintf('Données chargées avec succès.\n');
fprintf('Nombre de points: %d\n\n', length(vitesse_vent_valid));

%% 2. DÉFINIR LES PARAMÈTRES DU MODÈLE
% Paramètres de base (identifiés à partir des données)
params_base.v_cut_in = v_cut_in;
params_base.v_rated = v_rated;
params_base.v_cut_out = 25;  % Vitesse d'arrêt typique (à ajuster si nécessaire)
params_base.P_rated = P_max;

fprintf('=== Paramètres du modèle ===\n');
fprintf('Vitesse de démarrage: %.2f m/s\n', params_base.v_cut_in);
fprintf('Vitesse nominale: %.2f m/s\n', params_base.v_rated);
fprintf('Vitesse d''arrêt: %.2f m/s\n', params_base.v_cut_out);
fprintf('Puissance nominale: %.2f MW\n\n', params_base.P_rated/1e6);

%% 3. CRÉER LES VECTEURS POUR LES COURBES THÉORIQUES
v_model = linspace(0, 30, 1000); % Vitesses de 0 à 30 m/s

% Calculer la puissance pour chaque modèle
params_cubic = params_base;
params_cubic.model = 'cubic';
P_cubic = puissance_eolienne(v_model, params_cubic);

params_linear = params_base;
params_linear.model = 'linear';
P_linear = puissance_eolienne(v_model, params_linear);

params_poly = params_base;
params_poly.model = 'polynomial';
P_poly = puissance_eolienne(v_model, params_poly);

%% 4. CALCULER LES ERREURS DE CHAQUE MODÈLE
% Interpoler les modèles aux points de mesure
P_cubic_interp = puissance_eolienne(vitesse_vent_valid, params_cubic);
P_linear_interp = puissance_eolienne(vitesse_vent_valid, params_linear);
P_poly_interp = puissance_eolienne(vitesse_vent_valid, params_poly);

% Calculer RMSE (Root Mean Square Error)
rmse_cubic = sqrt(mean((puissance_elec_valid - P_cubic_interp).^2));
rmse_linear = sqrt(mean((puissance_elec_valid - P_linear_interp).^2));
rmse_poly = sqrt(mean((puissance_elec_valid - P_poly_interp).^2));

% Calculer R² (coefficient de détermination)
SS_tot = sum((puissance_elec_valid - mean(puissance_elec_valid)).^2);
SS_res_cubic = sum((puissance_elec_valid - P_cubic_interp).^2);
SS_res_linear = sum((puissance_elec_valid - P_linear_interp).^2);
SS_res_poly = sum((puissance_elec_valid - P_poly_interp).^2);

R2_cubic = 1 - SS_res_cubic/SS_tot;
R2_linear = 1 - SS_res_linear/SS_tot;
R2_poly = 1 - SS_res_poly/SS_tot;

fprintf('=== Performances des modèles ===\n');
fprintf('Modèle Cubique:\n');
fprintf('  RMSE: %.2f kW\n', rmse_cubic/1000);
fprintf('  R²: %.4f\n\n', R2_cubic);

fprintf('Modèle Linéaire:\n');
fprintf('  RMSE: %.2f kW\n', rmse_linear/1000);
fprintf('  R²: %.4f\n\n', R2_linear);

fprintf('Modèle Polynomial:\n');
fprintf('  RMSE: %.2f kW\n', rmse_poly/1000);
fprintf('  R²: %.4f\n\n', R2_poly);

%% 5. VISUALISATION COMPARATIVE
figure('Name', 'Comparaison des modèles de puissance', 'Position', [100 100 1400 900]);

% Subplot 1: Données réelles + tous les modèles
subplot(2,2,1);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.2, 'DisplayName', 'Données mesurées');
plot(v_model, P_cubic/1e6, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Modèle Cubique');
plot(v_model, P_linear/1e6, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Modèle Linéaire');
plot(v_model, P_poly/1e6, 'g-', 'LineWidth', 2.5, 'DisplayName', 'Modèle Polynomial');
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Puissance électrique (MW)', 'FontSize', 12);
title('Comparaison des modèles de courbe de puissance', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 10);
grid on;
xlim([0 25]);

% Subplot 2: Zoom sur la zone de montée en puissance
subplot(2,2,2);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.2);
plot(v_model, P_cubic/1e6, 'r-', 'LineWidth', 2.5);
plot(v_model, P_linear/1e6, 'b-', 'LineWidth', 2.5);
plot(v_model, P_poly/1e6, 'g-', 'LineWidth', 2.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Puissance électrique (MW)', 'FontSize', 12);
title('Zoom: Zone de montée en puissance', 'FontSize', 14);
grid on;
xlim([params_base.v_cut_in-1, params_base.v_rated+2]);

% Subplot 3: Résidus pour le meilleur modèle (polynomial)
subplot(2,2,3);
residus = puissance_elec_valid - P_poly_interp;
scatter(vitesse_vent_valid, residus/1e6, 10, 'r', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
yline(0, 'k--', 'LineWidth', 1.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Résidus (MW)', 'FontSize', 12);
title(sprintf('Résidus - Modèle Polynomial (RMSE = %.0f kW)', rmse_poly/1000), 'FontSize', 14);
grid on;

% Subplot 4: Histogramme des résidus
subplot(2,2,4);
histogram(residus/1e6, 50, 'FaceColor', 'b', 'EdgeColor', 'k');
xlabel('Résidus (MW)', 'FontSize', 12);
ylabel('Fréquence', 'FontSize', 12);
title('Distribution des résidus', 'FontSize', 14);
grid on;

%% 6. CRÉER LA COURBE DE PUISSANCE THÉORIQUE SELON LA FORMULE PHYSIQUE
% P = 0.5 * rho * A * Cp * v^3
% où:
%   rho = densité de l'air (kg/m³)
%   A = surface balayée par les pales (m²)
%   Cp = coefficient de puissance (sans dimension, max théorique = 0.593)
%   v = vitesse du vent (m/s)

% Estimation des paramètres physiques
rho = 1.225; % Densité de l'air au niveau de la mer à 15°C (kg/m³)

% Calculer le rayon des pales à partir de P_rated et v_rated
% En supposant Cp optimal (0.45 typique pour une éolienne moderne)
Cp = 0.45;
% P_rated = 0.5 * rho * A * Cp * v_rated^3
% A = P_rated / (0.5 * rho * Cp * v_rated^3)
A = P_max / (0.5 * rho * Cp * v_rated^3);
R = sqrt(A / pi); % Rayon des pales
D = 2 * R;        % Diamètre du rotor

fprintf('=== Paramètres physiques estimés ===\n');
fprintf('Surface balayée (A): %.2f m²\n', A);
fprintf('Rayon des pales (R): %.2f m\n', R);
fprintf('Diamètre du rotor (D): %.2f m\n', D);
fprintf('Coefficient de puissance (Cp): %.2f\n\n', Cp);

% Calculer la puissance théorique
P_theorique = 0.5 * rho * A * Cp * v_model.^3;
% Limiter à P_rated pour v >= v_rated
P_theorique(v_model >= v_rated) = P_max;
% Mettre à 0 pour v < v_cut_in et v >= v_cut_out
P_theorique(v_model < v_cut_in) = 0;
P_theorique(v_model >= params_base.v_cut_out) = 0;

% Visualisation avec le modèle théorique
figure('Name', 'Modèle théorique vs données', 'Position', [150 150 1000 600]);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.2, 'DisplayName', 'Données mesurées');
plot(v_model, P_theorique/1e6, 'm-', 'LineWidth', 2.5, ...
     'DisplayName', sprintf('Modèle théorique (D=%.1fm, Cp=%.2f)', D, Cp));
plot(v_model, P_poly/1e6, 'g-', 'LineWidth', 2.5, ...
     'DisplayName', 'Modèle polynomial (meilleur fit)');
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Puissance électrique (MW)', 'FontSize', 12);
title('Comparaison: Modèle théorique vs Modèle polynomial', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 11);
grid on;
xlim([0 25]);

%% 7. SAUVEGARDER LES RÉSULTATS
save('modeles_puissance.mat', 'params_base', 'params_poly', ...
     'v_model', 'P_cubic', 'P_linear', 'P_poly', 'P_theorique', ...
     'rmse_cubic', 'rmse_linear', 'rmse_poly', ...
     'R2_cubic', 'R2_linear', 'R2_poly', ...
     'rho', 'A', 'R', 'D', 'Cp');

fprintf('Résultats sauvegardés dans: modeles_puissance.mat\n');
fprintf('\nModélisation terminée avec succès!\n');
