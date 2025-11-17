% modelisation_physique_eolienne.m
% Modélisation physique avec détermination du rendement η
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Formule utilisée: P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
% Où η est le rendement global de l'éolienne

clear all;
close all;
clc;

fprintf('=== Modélisation physique de l''éolienne ===\n\n');

%% 1. CHARGER LES DONNÉES
if ~exist('donnees_eolienne_clean.mat', 'file')
    error('Fichier de données non trouvé. Exécutez d''abord "load_eolienne_data.m"');
end

load('donnees_eolienne_clean.mat');
fprintf('Données chargées: %d points\n\n', length(vitesse_vent_valid));

%% 2. FORMULE DE PUISSANCE AVEC LIMITE DE BETZ
% P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
%
% Simplifions:
% P = η × (16/27) × (1/2) × ρ × V³ × (π×D²/4)
% P = η × (16/27) × (π/8) × ρ × D² × V³
% P = η × (2π/27) × ρ × D² × V³

fprintf('=== Formule physique utilisée ===\n');
fprintf('P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)\n');
fprintf('  où:\n');
fprintf('    η = rendement global de l''éolienne\n');
fprintf('    16/27 ≈ 0.593 = limite de Betz (Cp_max)\n');
fprintf('    ρ = masse volumique (calculée avec P et T)\n');
fprintf('    V = vitesse du vent\n');
fprintf('    D = diamètre du rotor\n\n');

%% 3. ESTIMATION DU DIAMÈTRE ET DU RENDEMENT
% On utilise les points où l'éolienne fonctionne à puissance nominale
% pour estimer η et D

% Filtrer les points à puissance nominale (± 5%)
P_max = max(puissance_elec_valid);
tolerance = 0.05;
idx_nominal = puissance_elec_valid >= (1-tolerance) * P_max;

fprintf('=== Estimation des paramètres à partir des données ===\n');
fprintf('Nombre de points à puissance nominale: %d\n', sum(idx_nominal));

% Extraire les données à puissance nominale
v_nominal = vitesse_vent_valid(idx_nominal);
P_nominal = puissance_elec_valid(idx_nominal);
rho_nominal = rho_air_valid(idx_nominal);

% Calcul de η × D²
% P = η × (2π/27) × ρ × D² × V³
% Donc: η × D² = P / ((2π/27) × ρ × V³)

coeff = (2*pi/27);  % = (16/27) × (π/8)
eta_D2_values = P_nominal ./ (coeff * rho_nominal .* v_nominal.^3);

% Moyenne de η × D²
eta_D2_mean = mean(eta_D2_values);
eta_D2_std = std(eta_D2_values);

fprintf('η × D² moyen: %.2f m² (±%.2f)\n', eta_D2_mean, eta_D2_std);

% Pour déterminer η et D séparément, on peut :
% 1. Supposer un rendement typique (η ≈ 0.35-0.50) et calculer D
% 2. Supposer un diamètre typique et calculer η
% 3. Utiliser une optimisation

%% 4. MÉTHODE 1: SUPPOSER UN RENDEMENT ET CALCULER D
eta_suppose = [0.30, 0.35, 0.40, 0.45, 0.50];

fprintf('\n=== Estimation du diamètre pour différents rendements ===\n');
fprintf('Si η        alors D\n');
for eta = eta_suppose
    D_calcule = sqrt(eta_D2_mean / eta);
    fprintf('  %.2f      %.2f m (rayon = %.2f m)\n', eta, D_calcule, D_calcule/2);
end
fprintf('\n');

%% 5. MÉTHODE 2: OPTIMISATION POUR TROUVER η ET D OPTIMAUX
% On minimise l'erreur entre la puissance mesurée et modélisée

% Fonction objectif: minimiser RMSE
objectif = @(params) calculer_erreur_physique(params, vitesse_vent_valid, ...
    puissance_elec_valid, rho_air_valid, v_cut_in, v_rated, params_base.v_cut_out);

% Paramètres initiaux: [eta, D]
% Estimation initiale: η ≈ 0.40, D ≈ sqrt(eta_D2_mean/0.40)
eta_init = 0.40;
D_init = sqrt(eta_D2_mean / eta_init);
params_init = [eta_init; D_init];

fprintf('=== Optimisation pour déterminer η et D ===\n');
fprintf('Paramètres initiaux:\n');
fprintf('  η initial: %.3f\n', eta_init);
fprintf('  D initial: %.2f m\n\n', D_init);

% Contraintes
lb = [0.20; 50];   % η min = 0.20, D min = 50 m
ub = [0.60; 150];  % η max = 0.60, D max = 150 m

% Options d'optimisation
options = optimoptions('fmincon', ...
    'Display', 'iter', ...
    'Algorithm', 'interior-point', ...
    'MaxIterations', 500, ...
    'OptimalityTolerance', 1e-6);

% Exécuter l'optimisation
[params_opt, erreur_opt, exitflag] = fmincon(objectif, params_init, ...
    [], [], [], [], lb, ub, [], options);

eta_opt = params_opt(1);
D_opt = params_opt(2);
R_opt = D_opt / 2;
A_opt = pi * R_opt^2;

fprintf('\n=== Résultats de l''optimisation ===\n');
fprintf('Rendement optimal (η): %.4f (%.2f%%)\n', eta_opt, eta_opt*100);
fprintf('Diamètre optimal (D): %.2f m\n', D_opt);
fprintf('Rayon optimal (R): %.2f m\n', R_opt);
fprintf('Surface balayée (A): %.2f m²\n', A_opt);
fprintf('RMSE: %.2f kW\n\n', erreur_opt/1000);

% Comparaison avec Cp
% η représente le rendement par rapport à la limite de Betz
% Cp = η × (16/27)
Cp_equivalent = eta_opt * (16/27);
fprintf('Coefficient de puissance équivalent:\n');
fprintf('  Cp = η × (16/27) = %.4f\n', Cp_equivalent);
fprintf('  Limite de Betz = 16/27 = %.4f\n', 16/27);
fprintf('  Rendement par rapport à Betz = %.1f%%\n\n', eta_opt*100);

%% 6. CRÉER LE MODÈLE AVEC LES PARAMÈTRES OPTIMISÉS
v_model = linspace(0, 30, 1000);

% Calculer ρ moyen pour le modèle (on pourrait aussi le faire varier)
rho_mean = mean(rho_air_valid);

% Calculer la puissance théorique pour chaque vitesse
P_model = zeros(size(v_model));
for i = 1:length(v_model)
    if v_model(i) < v_cut_in
        P_model(i) = 0;
    elseif v_model(i) >= v_cut_in && v_model(i) < v_rated
        % Zone de montée: P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
        P_model(i) = eta_opt * (16/27) * rho_mean * 0.5 * v_model(i)^3 * (pi*D_opt^2/4);
    elseif v_model(i) >= v_rated && v_model(i) < params_base.v_cut_out
        % Zone nominale: P = P_max
        P_model(i) = P_max;
    else
        % Cut-out: P = 0
        P_model(i) = 0;
    end
end

% Limiter à P_max si dépassement
P_model = min(P_model, P_max);

%% 7. CALCULER LA PUISSANCE PRÉDITE AUX POINTS DE MESURE
P_pred = zeros(size(vitesse_vent_valid));
for i = 1:length(vitesse_vent_valid)
    v = vitesse_vent_valid(i);
    rho = rho_air_valid(i);

    if v < v_cut_in
        P_pred(i) = 0;
    elseif v >= v_cut_in && v < v_rated
        P_pred(i) = eta_opt * (16/27) * rho * 0.5 * v^3 * (pi*D_opt^2/4);
    elseif v >= v_rated && v < params_base.v_cut_out
        P_pred(i) = P_max;
    else
        P_pred(i) = 0;
    end
end
P_pred = min(P_pred, P_max);

% Calculer R²
SS_tot = sum((puissance_elec_valid - mean(puissance_elec_valid)).^2);
SS_res = sum((puissance_elec_valid - P_pred).^2);
R2 = 1 - SS_res/SS_tot;

fprintf('Performance du modèle physique:\n');
fprintf('  R²: %.4f\n', R2);
fprintf('  RMSE: %.2f kW\n\n', sqrt(mean((puissance_elec_valid - P_pred).^2))/1000);

%% 8. VISUALISATIONS
figure('Name', 'Modélisation physique avec rendement η', 'Position', [100 100 1400 900]);

% Subplot 1: Modèle vs données
subplot(2,2,1);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', ...
        'MarkerFaceAlpha', 0.2, 'DisplayName', 'Données mesurées');
plot(v_model, P_model/1e6, 'r-', 'LineWidth', 2.5, ...
     'DisplayName', sprintf('Modèle physique (η=%.3f, D=%.1fm)', eta_opt, D_opt));
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Puissance électrique (MW)', 'FontSize', 12);
title(sprintf('Modèle physique - R²=%.4f', R2), 'FontSize', 14);
legend('Location', 'northwest', 'FontSize', 10);
grid on;
xlim([0 25]);

% Subplot 2: Résidus
subplot(2,2,2);
residus = puissance_elec_valid - P_pred;
scatter(vitesse_vent_valid, residus/1e6, 10, 'r', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
yline(0, 'k--', 'LineWidth', 1.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Résidus (MW)', 'FontSize', 12);
title(sprintf('Résidus - RMSE = %.0f kW', erreur_opt/1000), 'FontSize', 14);
grid on;

% Subplot 3: Distribution des résidus
subplot(2,2,3);
histogram(residus/1e6, 50, 'FaceColor', 'b', 'EdgeColor', 'k');
xlabel('Résidus (MW)', 'FontSize', 12);
ylabel('Fréquence', 'FontSize', 12);
title('Distribution des résidus', 'FontSize', 14);
grid on;

% Subplot 4: Rendement en fonction de la vitesse (analyse)
subplot(2,2,4);
% Calculer le rendement effectif à chaque point
idx_prod = vitesse_vent_valid > v_cut_in & vitesse_vent_valid < v_rated;
eta_effectif = puissance_elec_valid(idx_prod) ./ ...
    ((16/27) * rho_air_valid(idx_prod) .* 0.5 .* vitesse_vent_valid(idx_prod).^3 .* (pi*D_opt^2/4));

scatter(vitesse_vent_valid(idx_prod), eta_effectif, 10, 'b', 'filled', 'MarkerFaceAlpha', 0.3);
hold on;
yline(eta_opt, 'r--', 'LineWidth', 2, 'DisplayName', sprintf('η_{opt} = %.3f', eta_opt));
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 12);
ylabel('Rendement effectif η', 'FontSize', 12);
title('Rendement effectif en fonction de la vitesse', 'FontSize', 14);
legend('Location', 'best', 'FontSize', 10);
grid on;
ylim([0 0.8]);

%% 9. SAUVEGARDER LES RÉSULTATS
save('modele_physique.mat', 'eta_opt', 'D_opt', 'R_opt', 'A_opt', 'Cp_equivalent', ...
     'v_model', 'P_model', 'P_pred', 'R2', 'erreur_opt', 'rho_mean');

fprintf('Résultats sauvegardés dans: modele_physique.mat\n');
fprintf('\nModélisation physique terminée avec succès!\n');

%% FONCTION AUXILIAIRE
function erreur = calculer_erreur_physique(params, v_data, P_data, rho_data, v_cut_in, v_rated, v_cut_out)
    % Calculer l'erreur RMSE pour des paramètres donnés

    eta = params(1);
    D = params(2);

    P_max = max(P_data);
    P_pred = zeros(size(v_data));

    for i = 1:length(v_data)
        v = v_data(i);
        rho = rho_data(i);

        if v < v_cut_in
            P_pred(i) = 0;
        elseif v >= v_cut_in && v < v_rated
            % P = η × (16/27) × ρ × (1/2) × V³ × (π×D²/4)
            P_pred(i) = eta * (16/27) * rho * 0.5 * v^3 * (pi*D^2/4);
        elseif v >= v_rated && v < v_cut_out
            P_pred(i) = P_max;
        else
            P_pred(i) = 0;
        end
    end

    % Limiter à P_max
    P_pred = min(P_pred, P_max);

    % Calculer RMSE
    erreur = sqrt(mean((P_data - P_pred).^2));
end
