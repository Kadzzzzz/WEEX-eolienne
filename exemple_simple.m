% exemple_simple.m
% Exemple simple d'utilisation de la fonction puissance_eolienne
% Projet Centrale Lyon - Modélisation de puissance éolienne
%
% Ce script montre comment utiliser rapidement la fonction
% de modélisation sans passer par l'analyse complète des données

clear all;
close all;
clc;

fprintf('=== Exemple simple de modélisation éolienne ===\n\n');

%% 1. DÉFINIR LES PARAMÈTRES D'UNE ÉOLIENNE TYPIQUE
% Exemple: Éolienne de 2 MW

params.v_cut_in = 3;      % Vitesse de démarrage: 3 m/s
params.v_rated = 12;      % Vitesse nominale: 12 m/s
params.v_cut_out = 25;    % Vitesse d'arrêt: 25 m/s
params.P_rated = 2e6;     % Puissance nominale: 2 MW = 2,000,000 W
params.model = 'polynomial';  % Type de modèle

fprintf('Paramètres de l''éolienne:\n');
fprintf('  - Vitesse de démarrage: %.1f m/s\n', params.v_cut_in);
fprintf('  - Vitesse nominale: %.1f m/s\n', params.v_rated);
fprintf('  - Vitesse d''arrêt: %.1f m/s\n', params.v_cut_out);
fprintf('  - Puissance nominale: %.1f MW\n\n', params.P_rated/1e6);

%% 2. CRÉER UN VECTEUR DE VITESSES DE VENT
v = 0:0.5:30;  % Vitesses de 0 à 30 m/s, par pas de 0.5 m/s

%% 3. CALCULER LA PUISSANCE POUR CHAQUE VITESSE
P = puissance_eolienne(v, params);

% Convertir en MW pour l'affichage
P_MW = P / 1e6;

%% 4. AFFICHER QUELQUES VALEURS
fprintf('Exemples de puissance produite:\n');
fprintf('  v = 0 m/s    -> P = %.2f MW\n', puissance_eolienne(0, params)/1e6);
fprintf('  v = 5 m/s    -> P = %.2f MW\n', puissance_eolienne(5, params)/1e6);
fprintf('  v = 10 m/s   -> P = %.2f MW\n', puissance_eolienne(10, params)/1e6);
fprintf('  v = 15 m/s   -> P = %.2f MW\n', puissance_eolienne(15, params)/1e6);
fprintf('  v = 20 m/s   -> P = %.2f MW\n', puissance_eolienne(20, params)/1e6);
fprintf('  v = 30 m/s   -> P = %.2f MW (arrêt)\n\n', puissance_eolienne(30, params)/1e6);

%% 5. TRACER LA COURBE DE PUISSANCE
figure('Name', 'Courbe de puissance - Exemple simple', 'Position', [200 200 900 600]);

plot(v, P_MW, 'b-', 'LineWidth', 2.5);
hold on;

% Marquer les points clés
plot(params.v_cut_in, 0, 'go', 'MarkerSize', 10, 'LineWidth', 2, ...
     'DisplayName', sprintf('v_{cut-in} = %.1f m/s', params.v_cut_in));
plot(params.v_rated, params.P_rated/1e6, 'ro', 'MarkerSize', 10, 'LineWidth', 2, ...
     'DisplayName', sprintf('v_{rated} = %.1f m/s', params.v_rated));
plot(params.v_cut_out, 0, 'mo', 'MarkerSize', 10, 'LineWidth', 2, ...
     'DisplayName', sprintf('v_{cut-out} = %.1f m/s', params.v_cut_out));

% Ajouter des lignes verticales
xline(params.v_cut_in, 'g--', 'LineWidth', 1, 'Alpha', 0.5);
xline(params.v_rated, 'r--', 'LineWidth', 1, 'Alpha', 0.5);
xline(params.v_cut_out, 'm--', 'LineWidth', 1, 'Alpha', 0.5);

% Ajouter une ligne horizontale pour P_rated
yline(params.P_rated/1e6, 'r--', 'LineWidth', 1, 'Alpha', 0.5);

hold off;

% Labels et titre
xlabel('Vitesse du vent (m/s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Puissance électrique (MW)', 'FontSize', 14, 'FontWeight', 'bold');
title(sprintf('Courbe de puissance - Éolienne %.1f MW (Modèle: %s)', ...
      params.P_rated/1e6, params.model), 'FontSize', 16, 'FontWeight', 'bold');

% Grille et légende
grid on;
legend('Location', 'northwest', 'FontSize', 12);
xlim([0 30]);
ylim([0 params.P_rated/1e6 * 1.1]);

% Améliorer l'apparence
set(gca, 'FontSize', 12);
box on;

%% 6. COMPARER LES 3 MODÈLES
fprintf('Comparaison des 3 modèles à v = 8 m/s:\n');

params.model = 'cubic';
P_cubic = puissance_eolienne(8, params);
fprintf('  Modèle Cubique:     %.3f MW\n', P_cubic/1e6);

params.model = 'linear';
P_linear = puissance_eolienne(8, params);
fprintf('  Modèle Linéaire:    %.3f MW\n', P_linear/1e6);

params.model = 'polynomial';
P_poly = puissance_eolienne(8, params);
fprintf('  Modèle Polynomial:  %.3f MW\n\n', P_poly/1e6);

%% 7. CRÉER UNE COMPARAISON VISUELLE DES 3 MODÈLES
figure('Name', 'Comparaison des modèles', 'Position', [250 250 1000 600]);

% Recalculer pour les 3 modèles
params.model = 'cubic';
P_cubic_all = puissance_eolienne(v, params);

params.model = 'linear';
P_linear_all = puissance_eolienne(v, params);

params.model = 'polynomial';
P_poly_all = puissance_eolienne(v, params);

% Tracer
hold on;
plot(v, P_cubic_all/1e6, 'r-', 'LineWidth', 2, 'DisplayName', 'Cubique (v³)');
plot(v, P_linear_all/1e6, 'b-', 'LineWidth', 2, 'DisplayName', 'Linéaire');
plot(v, P_poly_all/1e6, 'g-', 'LineWidth', 2, 'DisplayName', 'Polynomial (Hermite)');
hold off;

xlabel('Vitesse du vent (m/s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Puissance électrique (MW)', 'FontSize', 14, 'FontWeight', 'bold');
title('Comparaison des 3 modèles de courbe de puissance', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
xlim([0 25]);
ylim([0 params.P_rated/1e6 * 1.1]);
set(gca, 'FontSize', 12);
box on;

%% 8. ZOOM SUR LA ZONE DE MONTÉE EN PUISSANCE
figure('Name', 'Zoom: Zone de montée', 'Position', [300 300 1000 600]);

hold on;
plot(v, P_cubic_all/1e6, 'r-', 'LineWidth', 2.5, 'DisplayName', 'Cubique');
plot(v, P_linear_all/1e6, 'b-', 'LineWidth', 2.5, 'DisplayName', 'Linéaire');
plot(v, P_poly_all/1e6, 'g-', 'LineWidth', 2.5, 'DisplayName', 'Polynomial');
hold off;

xlabel('Vitesse du vent (m/s)', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Puissance électrique (MW)', 'FontSize', 14, 'FontWeight', 'bold');
title('Zoom sur la zone de montée en puissance', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 12);
grid on;
xlim([params.v_cut_in - 0.5, params.v_rated + 1]);
ylim([0 params.P_rated/1e6 * 1.05]);
set(gca, 'FontSize', 12);
box on;

%% 9. CALCULER L'ÉNERGIE PRODUITE SUR UNE JOURNÉE
% Supposons un vent constant à différentes vitesses

vitesses_test = [5, 8, 10, 12, 15];  % m/s
duree = 24;  % heures

fprintf('Énergie produite sur 24 heures avec vent constant:\n');
for v_test = vitesses_test
    P_test = puissance_eolienne(v_test, params);  % W
    E_test = P_test * duree / 1e6;  % MWh (W * h / 1e6)
    fprintf('  v = %2d m/s  ->  P = %.2f MW  ->  E = %.1f MWh/jour\n', ...
            v_test, P_test/1e6, E_test);
end

fprintf('\n=== Exemple terminé ===\n');
fprintf('Pour une analyse complète avec vos données:\n');
fprintf('  1. Exécutez: load_eolienne_data.m\n');
fprintf('  2. Puis: modelisation_puissance_eolienne.m\n');
