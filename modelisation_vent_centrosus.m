% Script de modélisation du vent pour trouver les meilleurs emplacements d'éoliennes
% Ce script analyse les données de vent de 2010 et identifie les 5 meilleurs points
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

        % Extraire la colonne de vitesse (4ème colonne)
        velocity = data(:, 4);

        % Supprimer les valeurs NaN
        velocity = velocity(~isnan(velocity));

        % Appliquer les contraintes de fonctionnement de l'éolienne:
        % - Vitesse < 3 m/s : pas de production (velocity = 0)
        % - Vitesse > 25 m/s : arrêt de sécurité (velocity = 0)
        % - 15 <= Vitesse <= 25 m/s : cappé à 15 m/s (puissance nominale)
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

% Afficher les 5 meilleurs points
fprintf('\n=================================================\n');
fprintf('LES 5 MEILLEURS POINTS POUR PLACER LES ÉOLIENNES\n');
fprintf('=================================================\n\n');

for i = 1:min(5, n_locations)
    idx = sorted_indices(i);
    fprintf('%d. Point %s : moyenne(V³) = %.2f m³/s³\n', ...
        i, location_names{idx}, sorted_v3(i));
end

% Créer une visualisation des résultats
figure('Name', 'Analyse des emplacements d''éoliennes', 'Position', [100, 100, 1200, 600]);

% Graphique 1: Classement de tous les points
subplot(1, 2, 1);
bar(sorted_v3);
xlabel('Classement');
ylabel('Moyenne de V³ (m³/s³)');
title('Classement de tous les points de mesure');
grid on;

% Marquer les 5 meilleurs points en rouge
hold on;
bar(1:5, sorted_v3(1:5), 'r');
legend('Tous les points', 'Top 5', 'Location', 'northeast');

% Graphique 2: Top 5 avec noms
subplot(1, 2, 2);
top5_names = location_names(sorted_indices(1:5));
bar(sorted_v3(1:5));
set(gca, 'XTickLabel', top5_names);
xlabel('Point de mesure');
ylabel('Moyenne de V³ (m³/s³)');
title('Les 5 meilleurs emplacements');
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
