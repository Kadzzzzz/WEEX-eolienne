% analyse_rendements.m
% Script pour analyser les rendements de l'éolienne
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Ce script calcule et affiche les rendements de différentes manières

clear all;
close all;
clc;

fprintf('=== Analyse des rendements de l''éolienne ===\n\n');

%% 1. CHARGER LES DONNÉES
if ~exist('donnees_eolienne_clean.mat', 'file')
    error('Exécutez d''abord "load_eolienne_data.m"');
end
load('donnees_eolienne_clean.mat');

if ~exist('modele_physique.mat', 'file')
    error('Exécutez d''abord "modelisation_physique_eolienne.m"');
end
load('modele_physique.mat');

fprintf('Données chargées avec succès.\n\n');

%% 2. RENDEMENT GLOBAL OPTIMAL (déterminé par optimisation)
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  RENDEMENT GLOBAL DE L''ÉOLIENNE (η optimal)          ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

fprintf('Rendement optimal (η): %.4f = %.2f%%\n', eta_opt, eta_opt*100);
fprintf('Diamètre optimal (D): %.2f m\n', D_opt);
fprintf('Rayon optimal (R): %.2f m\n', R_opt);
fprintf('Surface balayée (A): %.2f m²\n\n', A_opt);

fprintf('Ce rendement η représente l''efficacité GLOBALE:\n');
fprintf('  η = η_aérodynamique × η_mécanique × η_électrique\n\n');

% Calcul du Cp équivalent
fprintf('Coefficient de puissance équivalent:\n');
fprintf('  Cp = η × (16/27) = %.4f\n', Cp_equivalent);
fprintf('  Limite de Betz = 16/27 = %.4f\n', 16/27);
fprintf('  Rendement par rapport à Betz = %.1f%%\n\n', eta_opt*100);

%% 3. RENDEMENT EN FONCTION DE LA VITESSE DU VENT
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  RENDEMENT EFFECTIF EN FONCTION DE LA VITESSE         ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

% Filtrer les points dans la zone de montée en puissance
idx_montee = (vitesse_vent_valid > v_cut_in) & (vitesse_vent_valid < v_rated);

% Calculer la puissance théorique maximale (limite de Betz) pour chaque point
P_theorique_Betz = (16/27) * rho_air_valid(idx_montee) .* 0.5 .* ...
                   vitesse_vent_valid(idx_montee).^3 .* (pi*D_opt^2/4);

% Calculer le rendement effectif pour chaque mesure
eta_effectif = puissance_elec_valid(idx_montee) ./ P_theorique_Betz;

% Statistiques des rendements effectifs
fprintf('Zone de montée en puissance (%.1f < v < %.1f m/s):\n\n', v_cut_in, v_rated);
fprintf('Rendement effectif (η):\n');
fprintf('  - Minimum: %.4f (%.2f%%)\n', min(eta_effectif), min(eta_effectif)*100);
fprintf('  - Maximum: %.4f (%.2f%%)\n', max(eta_effectif), max(eta_effectif)*100);
fprintf('  - Moyenne: %.4f (%.2f%%)\n', mean(eta_effectif), mean(eta_effectif)*100);
fprintf('  - Médiane: %.4f (%.2f%%)\n', median(eta_effectif), median(eta_effectif)*100);
fprintf('  - Écart-type: %.4f\n\n', std(eta_effectif));

%% 4. RENDEMENT PAR TRANCHE DE VITESSE
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  RENDEMENT MOYEN PAR TRANCHE DE VITESSE               ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

% Définir les tranches de vitesse
v_bins = v_cut_in:1:v_rated;
n_bins = length(v_bins) - 1;

fprintf('Tranche vitesse   |  η moyen  |  Nombre mesures\n');
fprintf('------------------------------------------------\n');

for i = 1:n_bins
    idx_bin = (vitesse_vent_valid >= v_bins(i)) & (vitesse_vent_valid < v_bins(i+1));

    if sum(idx_bin) > 0
        % Calculer P_Betz pour cette tranche
        P_Betz_bin = (16/27) * rho_air_valid(idx_bin) .* 0.5 .* ...
                     vitesse_vent_valid(idx_bin).^3 .* (pi*D_opt^2/4);

        % Rendement moyen pour cette tranche
        eta_bin = mean(puissance_elec_valid(idx_bin) ./ P_Betz_bin);

        fprintf('[%.1f - %.1f[ m/s  |  %.4f  |  %d\n', ...
                v_bins(i), v_bins(i+1), eta_bin, sum(idx_bin));
    end
end
fprintf('\n');

%% 5. COMPARAISON: PUISSANCE MESURÉE VS THÉORIQUE
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  COMPARAISON PUISSANCE: MESURÉE VS THÉORIQUE         ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

% Calculer pour quelques vitesses typiques
v_test = [6, 8, 10, 12];
rho_test = mean(rho_air_valid); % Utiliser ρ moyen

fprintf('Vitesse  |  P_Betz (max)  |  P_modèle (η×P_Betz)  |  η\n');
fprintf('------------------------------------------------------------\n');

for v = v_test
    if v < v_rated
        P_Betz_max = (16/27) * rho_test * 0.5 * v^3 * (pi*D_opt^2/4);
        P_modele = eta_opt * P_Betz_max;

        fprintf('%2d m/s   |  %.2f MW       |  %.2f MW              |  %.3f\n', ...
                v, P_Betz_max/1e6, P_modele/1e6, eta_opt);
    end
end
fprintf('\n');

%% 6. DÉCOMPOSITION DU RENDEMENT (estimation théorique)
fprintf('╔════════════════════════════════════════════════════════╗\n');
fprintf('║  DÉCOMPOSITION THÉORIQUE DU RENDEMENT                 ║\n');
fprintf('╚════════════════════════════════════════════════════════╝\n\n');

fprintf('Le rendement global η = %.3f peut être décomposé en:\n\n', eta_opt);
fprintf('  η_total = η_aéro × η_méca × η_élec\n\n');

% Estimation des composantes (valeurs typiques)
eta_elec_typical = 0.95;  % Générateur: 95%
eta_meca_typical = 0.97;  % Transmission: 97%
eta_aero_implied = eta_opt / (eta_elec_typical * eta_meca_typical);

fprintf('Estimation des composantes (valeurs typiques):\n');
fprintf('  - η_électrique ≈ %.2f (générateur + onduleur)\n', eta_elec_typical);
fprintf('  - η_mécanique ≈ %.2f (transmission + roulements)\n', eta_meca_typical);
fprintf('  - η_aérodynamique ≈ %.2f (extraction énergie du vent)\n\n', eta_aero_implied);

fprintf('Vérification: %.3f × %.2f × %.2f = %.3f ✓\n\n', ...
        eta_aero_implied, eta_meca_typical, eta_elec_typical, ...
        eta_aero_implied * eta_meca_typical * eta_elec_typical);

%% 7. VISUALISATION DES RENDEMENTS
figure('Name', 'Analyse des rendements', 'Position', [100 100 1400 900]);

% Subplot 1: Rendement en fonction de la vitesse (nuage de points)
subplot(2,3,1);
scatter(vitesse_vent_valid(idx_montee), eta_effectif, 20, 'b', 'filled', 'MarkerFaceAlpha', 0.4);
hold on;
yline(eta_opt, 'r--', 'LineWidth', 2.5, 'Label', sprintf('η_{opt} = %.3f', eta_opt));
yline(mean(eta_effectif), 'g--', 'LineWidth', 2, 'Label', sprintf('η_{moy} = %.3f', mean(eta_effectif)));
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 11);
ylabel('Rendement effectif η', 'FontSize', 11);
title('Rendement en fonction de la vitesse', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('Location', 'best', 'FontSize', 9);
ylim([0 max(eta_effectif)*1.1]);

% Subplot 2: Distribution des rendements
subplot(2,3,2);
histogram(eta_effectif, 30, 'FaceColor', 'b', 'EdgeColor', 'k', 'FaceAlpha', 0.7);
xline(eta_opt, 'r--', 'LineWidth', 2.5, 'Label', 'η_{opt}');
xline(mean(eta_effectif), 'g--', 'LineWidth', 2, 'Label', 'Moyenne');
xlabel('Rendement η', 'FontSize', 11);
ylabel('Fréquence', 'FontSize', 11);
title('Distribution des rendements effectifs', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
legend('Location', 'best', 'FontSize', 9);

% Subplot 3: Rendement moyen par tranche de vitesse
subplot(2,3,3);
eta_bins = zeros(n_bins, 1);
v_centers = zeros(n_bins, 1);
for i = 1:n_bins
    idx_bin = (vitesse_vent_valid >= v_bins(i)) & (vitesse_vent_valid < v_bins(i+1));
    if sum(idx_bin) > 0
        P_Betz_bin = (16/27) * rho_air_valid(idx_bin) .* 0.5 .* ...
                     vitesse_vent_valid(idx_bin).^3 .* (pi*D_opt^2/4);
        eta_bins(i) = mean(puissance_elec_valid(idx_bin) ./ P_Betz_bin);
        v_centers(i) = (v_bins(i) + v_bins(i+1)) / 2;
    else
        eta_bins(i) = NaN;
        v_centers(i) = (v_bins(i) + v_bins(i+1)) / 2;
    end
end

bar(v_centers, eta_bins, 'FaceColor', 'c', 'EdgeColor', 'k', 'FaceAlpha', 0.7);
hold on;
yline(eta_opt, 'r--', 'LineWidth', 2.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 11);
ylabel('Rendement moyen η', 'FontSize', 11);
title('Rendement moyen par tranche de vitesse', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
ylim([0 max(eta_bins(~isnan(eta_bins)))*1.1]);

% Subplot 4: Puissance mesurée vs modèle (avec η)
subplot(2,3,4);
hold on;
scatter(vitesse_vent_valid, puissance_elec_valid/1e6, 10, 'k', 'filled', 'MarkerFaceAlpha', 0.2);
plot(v_model, P_model/1e6, 'r-', 'LineWidth', 2.5);
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 11);
ylabel('Puissance (MW)', 'FontSize', 11);
title(sprintf('Modèle avec η = %.3f', eta_opt), 'FontSize', 12, 'FontWeight', 'bold');
legend('Mesures', sprintf('Modèle (D=%.1fm)', D_opt), 'Location', 'northwest', 'FontSize', 9);
grid on;
xlim([0 25]);

% Subplot 5: Rapport P_mesurée / P_Betz
subplot(2,3,5);
ratio_power = puissance_elec_valid(idx_montee) ./ P_theorique_Betz;
scatter(vitesse_vent_valid(idx_montee), ratio_power, 20, 'r', 'filled', 'MarkerFaceAlpha', 0.4);
hold on;
yline(eta_opt, 'b--', 'LineWidth', 2.5, 'Label', sprintf('η = %.3f', eta_opt));
yline(16/27, 'k-', 'LineWidth', 2, 'Label', 'Limite Betz = 0.593');
hold off;
xlabel('Vitesse du vent (m/s)', 'FontSize', 11);
ylabel('P_{mesurée} / P_{Betz}', 'FontSize', 11);
title('Rapport puissance mesurée / puissance Betz', 'FontSize', 12, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 9);
grid on;
ylim([0 0.7]);

% Subplot 6: Décomposition du rendement (graphique en camembert)
subplot(2,3,6);
labels = {sprintf('Pertes aéro (%.0f%%)', (1-eta_aero_implied)*100), ...
          sprintf('Pertes méca (%.0f%%)', (1-eta_meca_typical)*100), ...
          sprintf('Pertes élec (%.0f%%)', (1-eta_elec_typical)*100), ...
          sprintf('Rendement (%.0f%%)', eta_opt*100)};
values = [(1-eta_aero_implied)*100, (1-eta_meca_typical)*100, (1-eta_elec_typical)*100, eta_opt*100];
pie(values, labels);
title('Décomposition des pertes et rendement', 'FontSize', 12, 'FontWeight', 'bold');
colormap([1 0.7 0.7; 1 0.9 0.7; 1 1 0.7; 0.7 1 0.7]);

%% 8. EXPORTER LES RÉSULTATS DANS UN FICHIER TEXTE
fid = fopen('resultats_rendements.txt', 'w');
fprintf(fid, '===============================================\n');
fprintf(fid, 'ANALYSE DES RENDEMENTS DE L''EOLIENNE\n');
fprintf(fid, 'Projet WEEX - Centrale Lyon\n');
fprintf(fid, '===============================================\n\n');

fprintf(fid, 'RENDEMENT GLOBAL OPTIMAL:\n');
fprintf(fid, '  η = %.4f (%.2f%%)\n', eta_opt, eta_opt*100);
fprintf(fid, '  D = %.2f m\n', D_opt);
fprintf(fid, '  R = %.2f m\n', R_opt);
fprintf(fid, '  A = %.2f m²\n\n', A_opt);

fprintf(fid, 'COEFFICIENT DE PUISSANCE:\n');
fprintf(fid, '  Cp = η × (16/27) = %.4f\n', Cp_equivalent);
fprintf(fid, '  Limite de Betz = %.4f\n', 16/27);
fprintf(fid, '  Efficacité = %.1f%%\n\n', eta_opt/0.593*100);

fprintf(fid, 'STATISTIQUES RENDEMENT EFFECTIF:\n');
fprintf(fid, '  Minimum: %.4f\n', min(eta_effectif));
fprintf(fid, '  Maximum: %.4f\n', max(eta_effectif));
fprintf(fid, '  Moyenne: %.4f\n', mean(eta_effectif));
fprintf(fid, '  Médiane: %.4f\n', median(eta_effectif));
fprintf(fid, '  Écart-type: %.4f\n\n', std(eta_effectif));

fprintf(fid, 'DÉCOMPOSITION THÉORIQUE:\n');
fprintf(fid, '  η_aérodynamique ≈ %.3f\n', eta_aero_implied);
fprintf(fid, '  η_mécanique ≈ %.3f\n', eta_meca_typical);
fprintf(fid, '  η_électrique ≈ %.3f\n', eta_elec_typical);
fprintf(fid, '  η_total = %.3f\n\n', eta_opt);

fclose(fid);

fprintf('Résultats exportés dans: resultats_rendements.txt\n');
fprintf('\nAnalyse des rendements terminée avec succès!\n');
