% Script de modélisation du vent pour trouver les meilleurs emplacements d'éoliennes
% Ce script analyse les données de vent de 2010 et identifie les 10 meilleurs points
% en tenant compte des contraintes de fonctionnement des éoliennes

clear all;
close all;
clc;

% Définir le répertoire des données
data_dir = '2010/';

% Lister tous les fichiers de données
files = dir([data_dir, '*_2010.txt']);
n_locations = length(files);

% Initialiser les variables
location_names = cell(n_locations, 1);
mean_v3_values = zeros(n_locations, 1);
all_velocity_data = cell(n_locations, 1);
all_direction_data = cell(n_locations, 1);

fprintf('Analyse de %d points de mesure...\n\n', n_locations);

% Analyser chaque fichier (chaque point de mesure)
for i = 1:n_locations
    % Obtenir le nom du fichier et extraire le nom du point
    filename = files(i).name;
    location_names{i} = filename(1:end-9); % Enlever '_2010.txt'

    % Lire les données
    filepath = [data_dir, filename];
    try
        % Lire le fichier en sautant les 2 premières lignes (en-tête)
        data = readmatrix(filepath, 'NumHeaderLines', 2);

        % Extraire la colonne de vitesse (4ème colonne) et direction (5ème colonne)
        velocity_raw = data(:, 4);
        direction_raw = data(:, 5);

        % Supprimer les valeurs NaN
        valid_idx = ~isnan(velocity_raw) & ~isnan(direction_raw);
        velocity_raw = velocity_raw(valid_idx);
        direction_raw = direction_raw(valid_idx);

        % Stocker les données brutes pour l'analyse ultérieure
        all_velocity_data{i} = velocity_raw;
        all_direction_data{i} = direction_raw;

        % Appliquer les contraintes de fonctionnement de l'éolienne:
        % - Vitesse < 3 m/s : pas de production (velocity = 0)
        % - Vitesse > 25 m/s : arrêt de sécurité (velocity = 0)
        % - 15 <= Vitesse <= 25 m/s : cappé à 15 m/s (puissance nominale)
        velocity = velocity_raw;
        velocity(velocity < 3) = 0;
        velocity(velocity > 25) = 0;
        velocity(velocity >= 15 & velocity <= 25) = 15;

        % Calculer la moyenne de V³ (car la puissance est proportionnelle à V³)
        v3 = velocity.^3;
        mean_v3 = mean(v3);

        % Stocker le résultat
        mean_v3_values(i) = mean_v3;

        fprintf('Point %s : moyenne(V³) = %.2f m³/s³\n', location_names{i}, mean_v3);

    catch ME
        warning('Erreur lors de la lecture du fichier %s : %s', filename, ME.message);
        mean_v3_values(i) = NaN;
    end
end

% Trier les points par ordre décroissant de moyenne(V³)
[sorted_v3, sorted_indices] = sort(mean_v3_values, 'descend');

% Afficher les 10 meilleurs points
fprintf('\n===================================================\n');
fprintf('LES 10 MEILLEURS POINTS POUR PLACER LES ÉOLIENNES\n');
fprintf('===================================================\n\n');

n_best = min(10, n_locations);
for i = 1:n_best
    idx = sorted_indices(i);
    fprintf('%2d. Point %s : moyenne(V³) = %.2f m³/s³\n', ...
        i, location_names{idx}, sorted_v3(i));
end

%% ========================================================================
%  FIGURE 1 : Classement général des points
%  ========================================================================
figure('Name', 'Analyse des emplacements d''éoliennes', 'Position', [100, 100, 1200, 600]);

% Graphique 1: Classement de tous les points
subplot(1, 2, 1);
bar(sorted_v3);
xlabel('Classement');
ylabel('Moyenne de V³ (m³/s³)');
title('Classement de tous les points de mesure');
grid on;

% Marquer les 10 meilleurs points en rouge
hold on;
bar(1:n_best, sorted_v3(1:n_best), 'r');
legend('Tous les points', 'Top 10', 'Location', 'northeast');

% Graphique 2: Top 10 avec noms
subplot(1, 2, 2);
top_names = location_names(sorted_indices(1:n_best));
bar(sorted_v3(1:n_best));
set(gca, 'XTickLabel', top_names);
xlabel('Point de mesure');
ylabel('Moyenne de V³ (m³/s³)');
title('Les 10 meilleurs emplacements');
grid on;
xtickangle(45);

% Sauvegarder les résultats dans un fichier
results_table = table(location_names(sorted_indices), sorted_v3, ...
    'VariableNames', {'Point', 'Moyenne_V3'});
writetable(results_table, 'resultats_classement_eoliennes.csv');
fprintf('\nRésultats sauvegardés dans : resultats_classement_eoliennes.csv\n');

% Sauvegarder la figure
saveas(gcf, 'classement_eoliennes.png');
fprintf('Graphique sauvegardé dans : classement_eoliennes.png\n');

%% ========================================================================
%  FIGURE 2 : Roses des vents pour les 10 meilleurs points
%  ========================================================================
fprintf('\nGénération des roses des vents...\n');

figure('Name', 'Roses des vents - Top 10', 'Position', [100, 100, 1600, 1000]);

for i = 1:n_best
    idx = sorted_indices(i);
    velocity = all_velocity_data{idx};
    direction = all_direction_data{idx};

    % Créer un subplot pour chaque point
    subplot(2, 5, i);

    % Définir les secteurs de direction (16 secteurs de 22.5°)
    n_sectors = 16;
    sector_width = 360 / n_sectors;
    sector_edges = 0:sector_width:360;
    sector_centers = sector_edges(1:end-1) + sector_width/2;

    % Calculer la fréquence du vent dans chaque secteur
    sector_frequency = zeros(n_sectors, 1);
    for s = 1:n_sectors
        angle_min = sector_edges(s);
        angle_max = sector_edges(s+1);

        if s == 1
            % Premier secteur : inclure à la fois [0, 22.5] et [337.5, 360]
            in_sector = (direction >= 0 & direction < angle_max) | ...
                       (direction >= sector_edges(end-1) & direction <= 360);
        else
            in_sector = direction >= angle_min & direction < angle_max;
        end

        sector_frequency(s) = sum(in_sector);
    end

    % Normaliser en pourcentage
    sector_frequency = sector_frequency / length(direction) * 100;

    % Créer la rose des vents (diagramme polaire)
    theta = deg2rad(sector_centers);
    theta = [theta, theta(1)]; % Fermer le cercle
    r = [sector_frequency; sector_frequency(1)];

    polarplot(theta, r, 'b-', 'LineWidth', 2);
    hold on;
    polarscatter(theta, r, 50, 'b', 'filled');

    title(sprintf('%s\nmoyenne(V³)=%.1f m³/s³', top_names{i}, sorted_v3(i)), ...
        'FontSize', 10);

    % Personnaliser l'affichage
    ax = gca;
    ax.ThetaZeroLocation = 'top';
    ax.ThetaDir = 'clockwise';
end

sgtitle('Roses des vents - 10 meilleurs emplacements', 'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'roses_des_vents_top10.png');
fprintf('Roses des vents sauvegardées dans : roses_des_vents_top10.png\n');

%% ========================================================================
%  FIGURE 3 : Distributions de vitesse et loi de Weibull
%  ========================================================================
fprintf('Génération des distributions de vitesse et loi de Weibull...\n');

figure('Name', 'Distributions de Weibull - Top 10', 'Position', [100, 100, 1600, 1000]);

for i = 1:n_best
    idx = sorted_indices(i);
    velocity = all_velocity_data{idx};

    % Retirer les vitesses négatives et nulles pour l'analyse de Weibull
    velocity_positive = velocity(velocity > 0);

    subplot(2, 5, i);

    % Créer l'histogramme des vitesses
    [counts, edges] = histcounts(velocity_positive, 20);
    bin_centers = (edges(1:end-1) + edges(2:end)) / 2;
    bin_width = edges(2) - edges(1);

    % Normaliser pour obtenir une densité de probabilité
    pdf_empirique = counts / (sum(counts) * bin_width);

    % Tracer l'histogramme
    bar(bin_centers, pdf_empirique, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'k');
    hold on;

    % Estimer les paramètres de Weibull (k: shape, lambda: scale)
    if length(velocity_positive) > 5
        try
            % Méthode des moments pour estimer les paramètres de Weibull
            mean_v = mean(velocity_positive);
            std_v = std(velocity_positive);

            % Estimation initiale
            k_init = (std_v / mean_v)^(-1.086);
            lambda_init = mean_v / gamma(1 + 1/k_init);

            % Ajustement par maximum de vraisemblance
            params = wblfit(velocity_positive);
            lambda = params(1); % paramètre d'échelle
            k = params(2);      % paramètre de forme

            % Générer la courbe de Weibull ajustée
            v_range = linspace(0, max(velocity_positive), 100);
            weibull_pdf = wblpdf(v_range, lambda, k);

            % Tracer la courbe de Weibull
            plot(v_range, weibull_pdf, 'r-', 'LineWidth', 2);

            % Afficher les paramètres
            legend('Données mesurées', ...
                   sprintf('Weibull: k=%.2f, λ=%.2f', k, lambda), ...
                   'Location', 'northeast', 'FontSize', 8);

            title(sprintf('%s\nk=%.2f, λ=%.2f m/s', top_names{i}, k, lambda), ...
                'FontSize', 10);
        catch
            title(sprintf('%s\n(Ajustement impossible)', top_names{i}), ...
                'FontSize', 10);
        end
    else
        title(sprintf('%s\n(Données insuffisantes)', top_names{i}), ...
            'FontSize', 10);
    end

    xlabel('Vitesse (m/s)', 'FontSize', 9);
    ylabel('Densité de probabilité', 'FontSize', 9);
    grid on;
end

sgtitle('Distributions de vitesse et loi de Weibull - 10 meilleurs emplacements', ...
    'FontSize', 14, 'FontWeight', 'bold');
saveas(gcf, 'distributions_weibull_top10.png');
fprintf('Distributions Weibull sauvegardées dans : distributions_weibull_top10.png\n');

fprintf('\n=== Analyse terminée avec succès ===\n');
