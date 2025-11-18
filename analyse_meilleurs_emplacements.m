% analyse_meilleurs_emplacements.m
% Analyse des meilleurs emplacements pour installer des éoliennes
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Ce script compare différents emplacements géographiques en calculant
% la moyenne de V³ effective (en tenant compte des contraintes de fonctionnement)

clear all;
close all;
clc;

fprintf('=== Analyse des meilleurs emplacements pour éoliennes ===\n\n');

%% 1. DÉFINIR LES CONTRAINTES DE FONCTIONNEMENT
v_cut_in = 3;    % Vitesse de démarrage (m/s)
v_cut_out = 25;  % Vitesse d'arrêt (m/s)
v_rated = 15;    % Vitesse nominale (m/s)

fprintf('Contraintes de fonctionnement:\n');
fprintf('  - v < %.0f m/s → Pas de puissance (v_eff = 0)\n', v_cut_in);
fprintf('  - %.0f ≤ v < %.0f m/s → Puissance proportionnelle à v³\n', v_cut_in, v_rated);
fprintf('  - %.0f ≤ v ≤ %.0f m/s → Puissance nominale (v_eff = %.0f)\n', v_rated, v_cut_out, v_rated);
fprintf('  - v > %.0f m/s → Arrêt sécurité (v_eff = 0)\n\n', v_cut_out);

%% 2. LISTER TOUS LES FICHIERS DE DONNÉES
data_dir = '2010/';
files = dir(fullfile(data_dir, '*.txt'));

% Extraire les codes d'emplacement uniques (A, B, C, ...)
emplacements = {};
for i = 1:length(files)
    filename = files(i).name;
    % Extraire la lettre (ex: "01A_2010.txt" → "A")
    if length(filename) >= 3
        code = filename(3);  % La lettre est à la position 3
        if ~ismember(code, emplacements)
            emplacements{end+1} = code;
        end
    end
end

emplacements = sort(emplacements);
n_emplacements = length(emplacements);

fprintf('Nombre d''emplacements trouvés: %d\n', n_emplacements);
fprintf('Emplacements: %s\n\n', strjoin(emplacements, ', '));

%% 3. FONCTION POUR APPLIQUER LES CONTRAINTES
function v_effective = appliquer_contraintes(velocity, v_cut_in, v_rated, v_cut_out)
    % Appliquer les contraintes de fonctionnement de l'éolienne
    v_effective = velocity;

    % v < 3 m/s → v_eff = 0
    v_effective(velocity < v_cut_in) = 0;

    % v > 25 m/s → v_eff = 0
    v_effective(velocity > v_cut_out) = 0;

    % 15 ≤ v ≤ 25 → v_eff = 15 (cappé à la vitesse nominale)
    v_effective(velocity >= v_rated & velocity <= v_cut_out) = v_rated;

    % Entre 3 et 15, on garde la vitesse telle quelle
end

%% 4. ANALYSER CHAQUE EMPLACEMENT
resultats = struct();

for idx = 1:n_emplacements
    emplacement = emplacements{idx};

    fprintf('Traitement emplacement %s...\n', emplacement);

    % Charger toutes les données pour cet emplacement (tous les mois)
    all_velocities = [];

    for mois = 1:12
        filename = sprintf('%02d%s_2010.txt', mois, emplacement);
        filepath = fullfile(data_dir, filename);

        if exist(filepath, 'file')
            % Lire le fichier
            data = readmatrix(filepath, 'NumHeaderLines', 2);

            % Colonne 4 = Velocity [m/s]
            velocities = data(:, 4);

            % Retirer les NaN
            velocities = velocities(~isnan(velocities));

            all_velocities = [all_velocities; velocities];
        end
    end

    % Appliquer les contraintes de fonctionnement
    v_effective = appliquer_contraintes(all_velocities, v_cut_in, v_rated, v_cut_out);

    % Calculer les statistiques
    resultats(idx).emplacement = emplacement;
    resultats(idx).n_mesures = length(all_velocities);
    resultats(idx).v_moyenne = mean(all_velocities);
    resultats(idx).v_effective_moyenne = mean(v_effective);
    resultats(idx).v3_moyenne = mean(v_effective.^3);  % IMPORTANT: moyenne de V³!
    resultats(idx).v_max = max(all_velocities);
    resultats(idx).v_min = min(all_velocities);

    % Calculer le pourcentage de temps dans chaque zone
    resultats(idx).pct_arret_cut_in = sum(all_velocities < v_cut_in) / length(all_velocities) * 100;
    resultats(idx).pct_montee = sum(all_velocities >= v_cut_in & all_velocities < v_rated) / length(all_velocities) * 100;
    resultats(idx).pct_nominal = sum(all_velocities >= v_rated & all_velocities <= v_cut_out) / length(all_velocities) * 100;
    resultats(idx).pct_arret_cut_out = sum(all_velocities > v_cut_out) / length(all_velocities) * 100;

    % Puissance relative (proportionnelle à moyenne de V³)
    resultats(idx).puissance_relative = resultats(idx).v3_moyenne;
end

%% 5. TRIER PAR MOYENNE DE V³ (= PUISSANCE POTENTIELLE)
[~, ordre_decroissant] = sort([resultats.v3_moyenne], 'descend');
resultats_tries = resultats(ordre_decroissant);

%% 6. AFFICHER LES RÉSULTATS
fprintf('\n');
fprintf('╔════════════════════════════════════════════════════════════════════╗\n');
fprintf('║  CLASSEMENT DES EMPLACEMENTS PAR PUISSANCE POTENTIELLE           ║\n');
fprintf('╚════════════════════════════════════════════════════════════════════╝\n\n');

fprintf('Critère de classement: Moyenne de V³ effective (car P ∝ V³)\n\n');

fprintf('Rang  Emplacement  |  <V³> [m³/s³]  |  <V_eff> [m/s]  |  <V> [m/s]  | Puissance relative\n');
fprintf('--------------------------------------------------------------------------------------------\n');

for i = 1:n_emplacements
    fprintf('%2d       %s        |   %8.1f     |     %5.2f       |   %5.2f    |    %6.1f%%\n', ...
        i, ...
        resultats_tries(i).emplacement, ...
        resultats_tries(i).v3_moyenne, ...
        resultats_tries(i).v_effective_moyenne, ...
        resultats_tries(i).v_moyenne, ...
        resultats_tries(i).v3_moyenne / resultats_tries(1).v3_moyenne * 100);
end

fprintf('\n');

% Afficher les détails du meilleur emplacement
meilleur = resultats_tries(1);
fprintf('╔════════════════════════════════════════════════════════════════════╗\n');
fprintf('║  MEILLEUR EMPLACEMENT: %s                                         ║\n', meilleur.emplacement);
fprintf('╚════════════════════════════════════════════════════════════════════╝\n\n');

fprintf('Statistiques détaillées:\n');
fprintf('  - Nombre de mesures: %d\n', meilleur.n_mesures);
fprintf('  - Vitesse moyenne brute: %.2f m/s\n', meilleur.v_moyenne);
fprintf('  - Vitesse effective moyenne: %.2f m/s\n', meilleur.v_effective_moyenne);
fprintf('  - Moyenne de V³: %.1f m³/s³\n', meilleur.v3_moyenne);
fprintf('  - Vitesse min: %.2f m/s\n', meilleur.v_min);
fprintf('  - Vitesse max: %.2f m/s\n\n', meilleur.v_max);

fprintf('Répartition du temps de fonctionnement:\n');
fprintf('  - Arrêt (v < %.0f m/s): %.1f%%\n', v_cut_in, meilleur.pct_arret_cut_in);
fprintf('  - Montée (%.0f ≤ v < %.0f m/s): %.1f%%\n', v_cut_in, v_rated, meilleur.pct_montee);
fprintf('  - Nominal (%.0f ≤ v ≤ %.0f m/s): %.1f%%\n', v_rated, v_cut_out, meilleur.pct_nominal);
fprintf('  - Arrêt sécurité (v > %.0f m/s): %.1f%%\n\n', v_cut_out, meilleur.pct_arret_cut_out);

%% 7. VISUALISATIONS
figure('Name', 'Analyse des emplacements', 'Position', [100 100 1400 900]);

% Subplot 1: Classement par moyenne de V³
subplot(2,3,1);
emplacements_array = {resultats_tries.emplacement};
v3_moyennes = [resultats_tries.v3_moyenne];
bar(v3_moyennes, 'FaceColor', 'b', 'EdgeColor', 'k');
set(gca, 'XTick', 1:n_emplacements, 'XTickLabel', emplacements_array);
xlabel('Emplacement', 'FontSize', 11);
ylabel('Moyenne de V³ [m³/s³]', 'FontSize', 11);
title('Classement par puissance potentielle (<V³>)', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
% Marquer le meilleur en vert
hold on;
bar(1, v3_moyennes(1), 'FaceColor', 'g', 'EdgeColor', 'k');
hold off;

% Subplot 2: Vitesse moyenne vs vitesse effective moyenne
subplot(2,3,2);
v_moyennes = [resultats_tries.v_moyenne];
v_eff_moyennes = [resultats_tries.v_effective_moyenne];
hold on;
bar(1:n_emplacements, [v_moyennes; v_eff_moyennes]', 'grouped');
hold off;
set(gca, 'XTick', 1:n_emplacements, 'XTickLabel', emplacements_array);
xlabel('Emplacement', 'FontSize', 11);
ylabel('Vitesse [m/s]', 'FontSize', 11);
title('Vitesse moyenne brute vs effective', 'FontSize', 12, 'FontWeight', 'bold');
legend('V brute', 'V effective', 'Location', 'best', 'FontSize', 9);
grid on;

% Subplot 3: Répartition du temps pour le meilleur emplacement
subplot(2,3,3);
categories = {'Arrêt\n(v<3)', sprintf('Montée\n(%.0f≤v<%.0f)', v_cut_in, v_rated), ...
              sprintf('Nominal\n(%.0f≤v≤%.0f)', v_rated, v_cut_out), 'Arrêt\n(v>25)'};
percentages = [meilleur.pct_arret_cut_in, meilleur.pct_montee, ...
               meilleur.pct_nominal, meilleur.pct_arret_cut_out];
pie(percentages, categories);
title(sprintf('Répartition temps - Emplacement %s', meilleur.emplacement), ...
      'FontSize', 12, 'FontWeight', 'bold');
colormap([1 0.7 0.7; 0.7 1 0.7; 0.7 0.7 1; 1 1 0.7]);

% Subplot 4: Puissance relative de chaque emplacement
subplot(2,3,4);
puissances_relatives = v3_moyennes / v3_moyennes(1) * 100;
bar(puissances_relatives, 'FaceColor', 'c', 'EdgeColor', 'k');
set(gca, 'XTick', 1:n_emplacements, 'XTickLabel', emplacements_array);
xlabel('Emplacement', 'FontSize', 11);
ylabel('Puissance relative [%]', 'FontSize', 11);
title('Puissance relative par rapport au meilleur', 'FontSize', 12, 'FontWeight', 'bold');
yline(100, 'r--', 'LineWidth', 2);
grid on;
ylim([0 105]);

% Subplot 5: Top 5 emplacements
subplot(2,3,5);
top5 = min(5, n_emplacements);
bar(v3_moyennes(1:top5), 'FaceColor', [0.2 0.6 0.8], 'EdgeColor', 'k');
set(gca, 'XTick', 1:top5, 'XTickLabel', emplacements_array(1:top5));
xlabel('Emplacement', 'FontSize', 11);
ylabel('Moyenne de V³ [m³/s³]', 'FontSize', 11);
title('Top 5 des meilleurs emplacements', 'FontSize', 12, 'FontWeight', 'bold');
grid on;
% Marquer le meilleur
hold on;
bar(1, v3_moyennes(1), 'FaceColor', 'g', 'EdgeColor', 'k');
hold off;

% Subplot 6: Comparaison erreur si on utilisait <V> au lieu de <V³>
subplot(2,3,6);
% Classement par <V> (FAUX)
[~, ordre_v] = sort(v_moyennes, 'descend');
% Classement par <V³> (CORRECT)
[~, ordre_v3] = sort(v3_moyennes, 'descend');

% Afficher la différence
rang_v = zeros(1, n_emplacements);
rang_v3 = zeros(1, n_emplacements);
for i = 1:n_emplacements
    rang_v(ordre_v(i)) = i;
    rang_v3(ordre_v3(i)) = i;
end

difference_rang = abs(rang_v - rang_v3);
bar(difference_rang, 'FaceColor', 'r', 'EdgeColor', 'k');
set(gca, 'XTick', 1:n_emplacements, 'XTickLabel', emplacements_array);
xlabel('Emplacement', 'FontSize', 11);
ylabel('Différence de rang', 'FontSize', 11);
title('Erreur si classement par <V> au lieu de <V³>', 'FontSize', 12, 'FontWeight', 'bold');
grid on;

%% 8. EXPORTER LES RÉSULTATS
% Créer un tableau récapitulatif
fid = fopen('classement_emplacements.txt', 'w');
fprintf(fid, '===============================================\n');
fprintf(fid, 'CLASSEMENT DES EMPLACEMENTS POUR EOLIENNES\n');
fprintf(fid, 'Projet WEEX - Centrale Lyon\n');
fprintf(fid, '===============================================\n\n');

fprintf(fid, 'Critère: Moyenne de V³ effective\n');
fprintf(fid, 'Contraintes appliquées:\n');
fprintf(fid, '  - v < %.0f m/s → v_eff = 0\n', v_cut_in);
fprintf(fid, '  - %.0f ≤ v < %.0f m/s → v_eff = v\n', v_cut_in, v_rated);
fprintf(fid, '  - %.0f ≤ v ≤ %.0f m/s → v_eff = %.0f\n', v_rated, v_cut_out, v_rated);
fprintf(fid, '  - v > %.0f m/s → v_eff = 0\n\n', v_cut_out);

fprintf(fid, 'CLASSEMENT:\n');
fprintf(fid, 'Rang  Emplacement  <V³> [m³/s³]  <V_eff> [m/s]  <V> [m/s]  P_relative\n');
fprintf(fid, '-----------------------------------------------------------------------\n');

for i = 1:n_emplacements
    fprintf(fid, '%2d       %s        %8.1f      %5.2f          %5.2f      %6.1f%%\n', ...
        i, resultats_tries(i).emplacement, resultats_tries(i).v3_moyenne, ...
        resultats_tries(i).v_effective_moyenne, resultats_tries(i).v_moyenne, ...
        resultats_tries(i).v3_moyenne / resultats_tries(1).v3_moyenne * 100);
end

fprintf(fid, '\n\nMEILLEUR EMPLACEMENT: %s\n', meilleur.emplacement);
fprintf(fid, '  <V³> = %.1f m³/s³\n', meilleur.v3_moyenne);
fprintf(fid, '  <V_eff> = %.2f m/s\n', meilleur.v_effective_moyenne);
fprintf(fid, '  Temps productif: %.1f%%\n', 100 - meilleur.pct_arret_cut_in - meilleur.pct_arret_cut_out);

fclose(fid);

% Sauvegarder les résultats dans un fichier .mat
save('resultats_emplacements.mat', 'resultats_tries', 'meilleur', ...
     'v_cut_in', 'v_rated', 'v_cut_out');

fprintf('Résultats exportés dans:\n');
fprintf('  - classement_emplacements.txt\n');
fprintf('  - resultats_emplacements.mat\n\n');

fprintf('Analyse terminée avec succès!\n');
