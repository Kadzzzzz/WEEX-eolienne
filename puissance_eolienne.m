function P = puissance_eolienne(v, params)
% PUISSANCE_EOLIENNE Modélise la puissance d'une éolienne en fonction du vent
%
% Syntaxe:
%   P = puissance_eolienne(v, params)
%
% Entrées:
%   v      - Vitesse du vent (m/s) - peut être un scalaire ou un vecteur
%   params - Structure contenant les paramètres du modèle:
%            .v_cut_in  : Vitesse de démarrage (m/s)
%            .v_rated   : Vitesse nominale (m/s)
%            .v_cut_out : Vitesse d'arrêt (m/s)
%            .P_rated   : Puissance nominale (W)
%            .model     : Type de modèle ('cubic', 'linear', 'polynomial')
%
% Sortie:
%   P - Puissance électrique produite (W)
%
% Modèles disponibles:
%   'cubic'      - Modèle théorique P = 0.5 * rho * A * Cp * v^3
%   'linear'     - Interpolation linéaire entre v_cut_in et v_rated
%   'polynomial' - Modèle polynomial d'ordre 3
%
% Exemple:
%   params.v_cut_in = 3;
%   params.v_rated = 12;
%   params.v_cut_out = 25;
%   params.P_rated = 2.5e6;
%   params.model = 'cubic';
%   v = 0:0.1:30;
%   P = puissance_eolienne(v, params);
%   plot(v, P/1e6);
%
% Auteur: Projet WEEX - Centrale Lyon
% Date: 2024

% Vérification des paramètres
if ~isfield(params, 'model')
    params.model = 'cubic'; % Modèle par défaut
end

% Initialiser la puissance à zéro
P = zeros(size(v));

% Indices pour les différentes zones de fonctionnement
idx_below_cut_in = v < params.v_cut_in;
idx_between = (v >= params.v_cut_in) & (v < params.v_rated);
idx_rated = (v >= params.v_rated) & (v < params.v_cut_out);
idx_above_cut_out = v >= params.v_cut_out;

% Zone 1: v < v_cut_in -> P = 0
P(idx_below_cut_in) = 0;

% Zone 2: v_cut_in <= v < v_rated -> Montée en puissance
switch lower(params.model)
    case 'cubic'
        % Modèle cubique: P proportionnel à v^3
        % P(v) = P_rated * ((v^3 - v_cut_in^3) / (v_rated^3 - v_cut_in^3))
        v_zone2 = v(idx_between);
        P(idx_between) = params.P_rated * ...
            ((v_zone2.^3 - params.v_cut_in^3) / ...
             (params.v_rated^3 - params.v_cut_in^3));

    case 'linear'
        % Modèle linéaire simple
        v_zone2 = v(idx_between);
        P(idx_between) = params.P_rated * ...
            ((v_zone2 - params.v_cut_in) / ...
             (params.v_rated - params.v_cut_in));

    case 'polynomial'
        % Modèle polynomial d'ordre 3
        % P(v) = a*v^3 + b*v^2 + c*v + d
        % Avec conditions aux limites:
        % P(v_cut_in) = 0 et P(v_rated) = P_rated
        % dP/dv(v_cut_in) = 0 et dP/dv(v_rated) = 0

        v_zone2 = v(idx_between);
        % Normalisation
        v_norm = (v_zone2 - params.v_cut_in) / (params.v_rated - params.v_cut_in);
        % Polynôme de Hermite: P(t) = P_rated * (3*t^2 - 2*t^3)
        P(idx_between) = params.P_rated * (3*v_norm.^2 - 2*v_norm.^3);

    otherwise
        error('Modèle non reconnu. Utilisez ''cubic'', ''linear'', ou ''polynomial''');
end

% Zone 3: v_rated <= v < v_cut_out -> P = P_rated
P(idx_rated) = params.P_rated;

% Zone 4: v >= v_cut_out -> P = 0 (arrêt pour sécurité)
P(idx_above_cut_out) = 0;

end
