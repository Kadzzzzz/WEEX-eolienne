% calibration_modele.m
% Script d'optimisation des paramètres du modèle de puissance éolienne
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Ce script optimise les paramètres v_cut_in, v_rated, et P_rated
% pour minimiser l'erreur entre le modèle et les données mesurées

clear all;
close all;
clc;

fprintf('=== Calibration du modèle de puissance éolienne ===\n\n');

%% 1. CHARGER LES DONNÉES
if ~exist('donnees_eolienne_clean.mat', 'file')
    error('Fichier de données non trouvé. Exécutez d''abord "load_eolienne_data.m"');
end

load('donnees_eolienne_clean.mat');
fprintf('Données chargées: %d points\n\n', length(vitesse_vent_valid));

%% 2. DÉFINIR LA FONCTION OBJECTIF À MINIMISER
% Fonction qui calcule l'erreur quadratique moyenne (RMSE)
objectif = @(params_vec) calculer_erreur(params_vec, vitesse_vent_valid, puissance_elec_valid);

%% 3. PARAMÈTRES INITIAUX
% Utiliser les valeurs identifiées précédemment comme point de départ
params_init = [v_cut_in; v_rated; v_cut_out; P_max];

fprintf('=== Paramètres initiaux ===\n');
fprintf('v_cut_in: %.2f m/s\n', params_init(1));
fprintf('v_rated: %.2f m/s\n', params_init(2));
fprintf('v_cut_out: %.2f m/s\n', params_init(3));
fprintf('P_rated: %.2f MW\n\n', params_init(4)/1e6);

% Calculer l'erreur initiale
erreur_init = objectif(params_init);
fprintf('RMSE initial: %.2f kW\n\n', erreur_init/1000);

%% 4. DÉFINIR LES CONTRAINTES
% Bornes inférieures et supérieures pour chaque paramètre
lb = [2;    % v_cut_in min
      8;    % v_rated min
      20;   % v_cut_out min
      1e6]; % P_rated min (1 MW)

ub = [6;    % v_cut_in max
      16;   % v_rated max
      30;   % v_cut_out max
      5e6]; % P_rated max (5 MW)

% Contraintes linéaires: v_cut_in < v_rated < v_cut_out
% A * x <= b
% -v_cut_in + v_rated >= 1  =>  v_cut_in - v_rated <= -1
% -v_rated + v_cut_out >= 5  =>  v_rated - v_cut_out <= -5
A = [1, -1, 0, 0;   % v_cut_in - v_rated <= -1
     0, 1, -1, 0];  % v_rated - v_cut_out <= -5
b = [-1; -5];

%% 5. OPTIMISATION
fprintf('=== Démarrage de l''optimisation ===\n');
fprintf('Algorithme: fmincon (optimisation non-linéaire contrainte)\n');
fprintf('Cela peut prendre quelques secondes...\n\n');

% Options d'optimisation
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'Algorithm', 'interior-point', ...
    'MaxIterations', 1000, ...
    'MaxFunctionEvaluations', 5000, ...
    'OptimalityTolerance', 1e-6, ...
    'StepTolerance', 1e-6);

% Exécuter l'optimisation
[params_opt, erreur_opt, exitflag, output] = fmincon(objectif, params_init, ...
    A, b, [], [], lb, ub, [], options);

%% 6. AFFICHER LES RÉSULTATS
fprintf('\n=== Résultats de l''optimisation ===\n');
fprintf('Statut: ');
if exitflag > 0
    fprintf('SUCCÈS\n');
elseif exitflag == 0
    fprintf('LIMITE D''ITÉRATIONS ATTEINTE\n');
else
    fprintf('ÉCHEC (code %d)\n', exitflag);
end
fprintf('Nombre d''itérations: %d\n', output.iterations);
fprintf('Nombre d''évaluations: %d\n\n', output.funcCount);

fprintf('=== Paramètres optimisés ===\n');
fprintf('v_cut_in: %.2f m/s (initial: %.2f m/s, delta: %+.2f m/s)\n', ...
    params_opt(1), params_init(1), params_opt(1)-params_init(1));
fprintf('v_rated: %.2f m/s (initial: %.2f m/s, delta: %+.2f m/s)\n', ...
    params_opt(2), params_init(2), params_opt(2)-params_init(2));
fprintf('v_cut_out: %.2f m/s (initial: %.2f m/s, delta: %+.2f m/s)\n', ...
    params_opt(3), params_init(3), params_opt(3)-params_init(3));
fprintf('P_rated: %.2f MW (initial: %.2f MW, delta: %+.2f MW)\n\n', ...
    params_opt(4)/1e6, params_init(4)/1e6, (params_opt(4)-params_init(4))/1e6);

fprintf('=== Amélioration de l''erreur ===\n');
fprintf('RMSE initial: %.2f kW\n', erreur_init/1000);
fprintf('RMSE optimisé: %.2f kW\n', erreur_opt/1000);
fprintf('Amélioration: %.2f kW (%.1f%%)\n\n', ...
    (erreur_init-erreur_opt)/1000, 100*(erreur_init-erreur_opt)/erreur_init);

%% 7. COMPARER VISUELLEMENT
% Créer les paramètres pour les modèles
params_init_struct.v_cut_in = params_init(1);
params_init_struct.v_rated = params_init(2);
params_init_struct.v_cut_out = params_init(3);
params_init_struct.P_rated = params_init(4);
params_init_struct.model = 'polynomial';

params_opt_struct.v_cut_in = params_opt(1);
params_opt_struct.v_rated = params_opt(2);
params_opt_struct.v_cut_out = params_opt(3);
params_opt_struct.P_rated = params_opt(4);
params_opt_struct.model = 'polynomial';

% Générer les courbes
v_model = linspace(0, 30, 1000);
P_init = puissance_eolienne(v_model, params_init_struct);
P_opt = puissance_eolienne(v_model, params_opt_struct);

% Calculer les prédictions aux points de mesure
P_init_pred = puissance_eolienne(vitesse_vent_valid, params_init_struct);
P_opt_pred = puissance_eolienne(vitesse_vent_valid, params_opt_struct);

% Calculer R²
SS_tot = sum((puissance_elec_valid - mean(puissance_elec_valid)).^2);
SS_res_init = sum((puissance_elec_valid - P_init_pred).^2);
SS_res_opt = sum((puissance_elec_valid - P_opt_pred).^2);
R2_init = 1 - SS_res_init/SS_tot;
R2_opt = 1 - SS_res_opt/SS_tot;

fprintf('R² initial: %.4f\n', R2_init);
fprintf('R² optimisé: %.4f\n\n', R2_opt);

%% 8. VISUALISATIONS
figure('Name', 'Comparaison: Paramètres initiaux vs optimisés', 'Position', [100 100 1400 900]);

% Subplot 1: Courbes de puissance
subplot(2,2,1);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.2, 'DisplayName', 'Données mesurées');
plot(v_model, P_init/1e6, 'b--', 'LineWidth', 2, 'DisplayName', ...
     sprintf('Modèle initial (RMSE=%.0f kW)', erreur_init/1000));
plot(v_model, P_opt/1e6, 'r-', 'LineWidth', 2.5, 'DisplayName', ...
     sprintf('Modèle optimisé (RMSE=%.0f kW)', erreur_opt/1000));
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Puissance électrique (MW)', 'FontSize', 12);
title('Comparaison des courbes de puissance', 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 10);
grid on;
xlim([0 25]);

% Subplot 2: Zoom sur la zone de transition
subplot(2,2,2);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.3);
plot(v_model, P_init/1e6, 'b--', 'LineWidth', 2);
plot(v_model, P_opt/1e6, 'r-', 'LineWidth', 2.5);
% Marquer les points clés
xline(params_init(1), 'b:', 'LineWidth', 1.5, 'Label', 'v_{cut-in}^{init}');
xline(params_init(2), 'b:', 'LineWidth', 1.5, 'Label', 'v_{rated}^{init}');
xline(params_opt(1), 'r:', 'LineWidth', 1.5, 'Label', 'v_{cut-in}^{opt}');
xline(params_opt(2), 'r:', 'LineWidth', 1.5, 'Label', 'v_{rated}^{opt}');
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Puissance électrique (MW)', 'FontSize', 12);
title('Zoom: Zone de montée en puissance', 'FontSize', 14);
grid on;
xlim([min(params_init(1), params_opt(1))-1, max(params_init(2), params_opt(2))+2]);

% Subplot 3: Résidus avant optimisation
subplot(2,2,3);
residus_init = puissance_elec_valid - P_init_pred;
scatter(vitesse_vent_valid, residus_init/1e6, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
yline(0, 'k--', 'LineWidth', 1.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Résidus (MW)', 'FontSize', 12);
title(sprintf('Résidus - Modèle initial (R²=%.4f)', R2_init), 'FontSize', 14);
grid on;
ylim_max = max(abs(residus_init/1e6));
ylim([-ylim_max, ylim_max]);

% Subplot 4: Résidus après optimisation
subplot(2,2,4);
residus_opt = puissance_elec_valid - P_opt_pred;
scatter(vitesse_vent_valid, residus_opt/1e6, 10, 'r', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
yline(0, 'k--', 'LineWidth', 1.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Résidus (MW)', 'FontSize', 12);
title(sprintf('Résidus - Modèle optimisé (R²=%.4f)', R2_opt), 'FontSize', 14);
grid on;
ylim([-ylim_max, ylim_max]);

%% 9. ANALYSE DES RÉSIDUS
figure('Name', 'Analyse des résidus', 'Position', [150 150 1200 500]);

% Histogrammes comparatifs
subplot(1,2,1);
hold on;
histogram(residus_init/1e6, 50, 'FaceColor', 'b', 'FaceAlpha', 0.5, ...
          'EdgeColor', 'k', 'DisplayName', 'Initial');
histogram(residus_opt/1e6, 50, 'FaceColor', 'r', 'FaceAlpha', 0.5, ...
          'EdgeColor', 'k', 'DisplayName', 'Optimisé');
hold off;
xlabel('Résidus (MW)', 'FontSize', 12);
ylabel('Fréquence', 'FontSize', 12);
title('Distribution des résidus', 'FontSize', 14);
legend('FontSize', 10);
grid on;

% Q-Q plot pour vérifier la normalité
subplot(1,2,2);
qqplot(residus_opt/1e6);
title('Q-Q Plot des résidus (modèle optimisé)', 'FontSize', 14);
xlabel('Quantiles théoriques', 'FontSize', 12);
ylabel('Quantiles des résidus (MW)', 'FontSize', 12);
grid on;

%% 10. SAUVEGARDER LES RÉSULTATS
save('modele_optimise.mat', 'params_opt', 'params_opt_struct', ...
     'erreur_opt', 'R2_opt', 'v_model', 'P_opt', 'residus_opt');

fprintf('Résultats de l''optimisation sauvegardés dans: modele_optimise.mat\n');
fprintf('\nCalibration terminée avec succès!\n');

%% FONCTION AUXILIAIRE
function erreur = calculer_erreur(params_vec, v_data, P_data)
    % Fonction qui calcule le RMSE pour un ensemble de paramètres

    % Créer la structure de paramètres
    params.v_cut_in = params_vec(1);
    params.v_rated = params_vec(2);
    params.v_cut_out = params_vec(3);
    params.P_rated = params_vec(4);
    params.model = 'polynomial';

    % Calculer la puissance prédite
    P_pred = puissance_eolienne(v_data, params);

    % Calculer le RMSE
    erreur = sqrt(mean((P_data - P_pred).^2));
end
