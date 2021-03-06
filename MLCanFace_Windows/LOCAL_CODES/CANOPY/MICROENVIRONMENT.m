function [CAz, EAz, TAz] = MICROENVIRONMENT(VARIABLES, VERTSTRUC, PARAMS, CONSTANTS)
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                              FUNCTION CODE                            %%
%%                            MICROENVIRONMENT                           %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%-------------------------------------------------------------------------%
% Calculate the canopy microenvironment (Ca, Ta, ea) using a first-order  %
% canopy closure model                                                    %
% Turbulent transport of these scalar quantities is similarly computed    %
% using the temporally averaged conservation of mass equation assuming    %
% negligible scalar storage within the canopy.                            %
% See Poggi et al., 2004; Drewry and Albertson, 2006                      %
% or Eqn 31 in Drewry et al., 2009 - part B: Online Supplement            %
%-------------------------------------------------------------------------%
%   Created by  : Darren Drewry                                           %
%   Editted by  : Phong Le                                                %
%   Date        : January 10, 2010                                        %
%% --------------------------------------------------------------------- %%  
%
%
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<< DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%
    CAz     = VARIABLES.CANOPY.CAz;
    TAz     = VARIABLES.CANOPY.TAz;
    EAz     = VARIABLES.CANOPY.EAz;
    PAz     = VARIABLES.CANOPY.PAz; 
    Km      = VARIABLES.CANOPY.Km;
%   
    An_sun  = VARIABLES.CANOPY.An_sun;
    An_shade= VARIABLES.CANOPY.An_shade;
    LE_sun  = VARIABLES.CANOPY.LE_sun;
    LE_shade= VARIABLES.CANOPY.LE_shade;
    H_sun   = VARIABLES.CANOPY.H_sun;
    H_shade = VARIABLES.CANOPY.H_shade;
    LAIsun  = VARIABLES.CANOPY.LAIsun;
    LAIshade= VARIABLES.CANOPY.LAIshade;
%
    Fc_soil = VARIABLES.SOIL.Fc_soil;
    LE_soil = VARIABLES.SOIL.LE_soil;
    H_soil  = VARIABLES.SOIL.H_soil;
%    
    znc     = VERTSTRUC.znc;
    dzc     = VERTSTRUC.dzc;
%    
    hcan    = PARAMS.CanStruc.hcan;
%    
    Lv      = CONSTANTS.Lv;
    cp_mol  = CONSTANTS.cp_mol;
%    
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<< END OF DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%% 
    molar_density   = 44.6 * PAz * 273.15 ./ (101.3 * (TAz + 273.15));      % Eqn 3.3 Campbell and Norman, 1998 (pp. 38)
    psy             = 6.66 * 10^-4;                                         % Symbol gamma, Thermaldynamic psychrometer constant [1/C]
                                                                            % See Campbell and Norman, 1998 (pp. 44)
     % CO2
        Sc      = (An_sun .* LAIsun + An_shade .* LAIshade)./dzc;
        Sc      = -Sc ./ molar_density;                                     % [umol/mol / s]
        [CAz]   = ORDER_1_CLOSURE_ALL(CAz, znc, dzc, Km, Sc, Fc_soil, hcan);  

     % VAPOR
        q       = (EAz./PAz) .* molar_density;                 
        Sv      = (LE_sun .* LAIsun + LE_shade .* LAIshade) ./ dzc;         % [W / m^3]
        Sv      = (Sv ./ Lv);
        Sv_soil = LE_soil / Lv;
        [q]     = ORDER_1_CLOSURE_ALL(q, znc, dzc, Km, Sv, Sv_soil, hcan);
        EAz     = (q ./ molar_density) .* PAz;

     % HEAT
        heat    = TAz .* molar_density .* psy;
        Sh      = (H_sun .* LAIsun + H_shade .* LAIshade) ./ dzc;           % [W / m^3]
        Sh      = Sh ./ cp_mol ./ molar_density;
        Sh_soil = H_soil ./ cp_mol ./ molar_density(1);
        [TAz]   = ORDER_1_CLOSURE_ALL(TAz, znc, dzc, Km, Sh, Sh_soil, hcan);   
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%        
        