function [gbv, gbh, gbv_forced, gbv_free, cnt] = BLC_Nikolov(VARIABLES, PARAMS, sunlit)
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                             FUNCTION CODE                             %%
%%                 BOUNDARY LAYER CONDUCTANCE CALCULATION                %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%   This function computes Leaf Boundary Layer Conductance                %
%   Free and forced convective regimes are both computed, with free       %           
%   convection becoming relevant under low wind conditions.               %
%   These equations are taken from (Nikolov, Massman, Schoettle),         %
%   Ecological Modelling, 80 (1995), 205-235                              %                   %
%-------------------------------------------------------------------------%
%   Created by  : Darren Drewry                                           %
%   Editted by  : Phong Le                                                %
%   Date        : January 13, 2010                                        %
%-------------------------------------------------------------------------%
%                                                                         %
%   INPUTS:                                                               %
%       ld      = characteristic leaf dimension parameter      [m]        %         
%               = leaf width for broadleaved vegetation                   %
%               = needle diameter for conifers                            %
%                                                                         %
%       lw      = shoot diameter for conifers                  [m]        %
%               = leaf width for broadleaved vegetation                   %
%                                                                         %
%       ls      = shoot diameter for conifers                  [m]        %         
%               = 0 for broadleaved vegetation                            %
%                                                                         %
%       U       = horizontal wind speed                        [m/s]      %
%       gsv     = stomatal conductance for vapor               [mol/m^2/s]%
%       Ta_in   = ambient air temperature                      [C]        %         
%       Pa_in   = ambient air pressure                         [kPa]      %
%       Tl_in   = leaf temperature                             [C]        %
%       ea_in   = ambient vapor pressure                       [kPa]      %
%                                                                         %
%       leaftype = 1 for broad leaved vegetation                          %
%                = 2 for needle leaved vegetation                         %
%                                                                         %
%   OUTPUTS:                                                              %                                                                
%       gbv = boundary layer conductance to vapor              [mol/m^2/s]%
%       gbh = boundary layer conductance to heat               [mol/m^2/s]%
%                                                                         %
%       Conversion from [m/s] to [mol/m^2/s]:  41.4 [mol/m^3]             %
%% --------------------------------------------------------------------- %%  
%
%
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<< DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%
    if (sunlit)  
        Tl_in  =  VARIABLES.CANOPY.Tl_sun;
        gsv_in =  VARIABLES.CANOPY.gsv_sun;
    else
        Tl_in  =  VARIABLES.CANOPY.Tl_shade;
        gsv_in =  VARIABLES.CANOPY.gsv_shade;
    end
%    
    ld       = PARAMS.CanStruc.ld;
    lw       = PARAMS.CanStruc.lw; 
    leaftype = PARAMS.CanStruc.leaftype;
%
    Ta_in    = VARIABLES.CANOPY.TAz;
    Pa_in    = VARIABLES.CANOPY.PAz;
    ea_in    = VARIABLES.CANOPY.EAz;
    U        = VARIABLES.CANOPY.Uz;
%    
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<< END OF DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%% 
% UNIT CONVERSIONS
    gsv = gsv_in / 41.4;            % [m/s]
    Tak = Ta_in + 273.15;           % [K]
    Tlk = Tl_in + 273.15;           % [K]
    Pa  = Pa_in * 1000;             % [Pa]
    ea  = ea_in * 1000;             % [Pa]
%    
% SATURATION VAPOR PRESSURE at Tl    
    esTl = 1000 * 0.611*exp( (17.502*Tl_in) ./ (Tl_in+240.97) );            % [Pa] - Tetens formula (Buck,1981) 
                                                                            % Also see eqn 3.8, (C&N 1998, pp 41)
%
% FORCED CONVECTION
    if (leaftype == 1)              % broadleaf, cf = 4.322 * 10^-3;
        cf = 1.6361 * 10^-3;        
    elseif (leaftype == 2)          % evergreen needles, cf = 1.2035 * 10^-3; used in Eqn 29
        cf = 0.8669 * 10^-3;        
    end    
%            
    gbv_forced = cf * Tak.^(0.56) .* ((Tak+120).*(U./ld./Pa)).^(0.5);       % Eqn 29 ; unit [m/s]
%    
%
% FREE CONVECTION
    if (leaftype == 1)              % broadleaf
        ce = 1.6361 * 10^-3;
    elseif (leaftype == 2)          % evergreen needles                     % used in Eqn 33
        ce = 0.8669 * 10^-3;
    end
%    
%    
% FORCED CONVECTION     
    gbv_free = gbv_forced;
    eb = (gsv.*esTl + gbv_free.*ea)./(gsv + gbv_free);                      % Eqn 35
%
    Tvdiff = (Tlk ./ (1-0.378*eb./Pa)) - (Tak ./ (1-0.378*ea./Pa));         % Eqn 34
%
    gbv_free = ce * Tlk.^(0.56) .* ((Tlk+120)./Pa).^(0.5)...
                 .* (abs(Tvdiff)/lw).^(0.25);                               % Eqn 33
%        
%    
    gbv_forced  = gbv_forced * 41.4;                                        % convert unit to [mol/m^2/s]
    gbv_free    = gbv_free   * 41.4;                                        % convert unit to [mol/m^2/s]
%
    gbv = max(gbv_forced, gbv_free);
    gbh = 0.924 * gbv;                                                      % Eqn 36
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%
