function [psil_MPa] = LEAF_WATER_POTENTIAL (VARIABLES, PARAMS, VERTSTRUC, CONSTANTS)
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                             FUNCTION CODE                             %%
%%                   LEAF WATER POTENTIAL CALCULATION                    %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%   This function is used to calculates Leaf Water Potential at each      %  
%   layer using Ohm's law.                                                %
%   See Drewry et al, 2009, Part B Online Supplement, Eqns (13,14)        %
%-------------------------------------------------------------------------%
%   Date        : January 13, 2010                                        %
%-------------------------------------------------------------------------%  
%                                                                         %
%   INPUTS:                                                               %
%       rpp_wgt      = root pressure potential weighted by root           %
%                       distribution                    [mm]              %
%       znc          = height of canopy levels          [m]               %
%       Rp           = plant resistance to water flow   [MPa / m / s]     %         
%       TR           = transpiration PER UNIT LEAF AREA [mm/s/unit LAI]   %    
%                                                                         %
%   OUTPUTS:                                                              %                                                                 
%       psil_MPa     = leaf water potential             [MPa]             %
%                                                                         %
%% --------------------------------------------------------------------- %%  
%
%
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<< DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%
    TR_sun      = VARIABLES.CANOPY.TR_sun;
    TR_shade    = VARIABLES.CANOPY.TR_shade;
%    
    rpp_wgt     = VARIABLES.ROOT.rpp_wgt;
%    
    znc         = VERTSTRUC.znc;
%    
    Rp          = PARAMS.StomCond.Rp;
%    
    grav        = CONSTANTS.grav;
    dtime       = CONSTANTS.dtime;
    mmH2OtoMPa  = CONSTANTS.mmH2OtoMPa;
%    
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<< END OF DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%% 
    rho_kg      = 1;                                                        % [kg / m^3]
%
    znc         = znc(:);                                                   % [m]
%
    TR          = (TR_sun + TR_shade);                                      % [W/LAI/s]
%
    TR_m        = TR / 1000;                                                % [m/s/unit LAI]
%
    rpp_wgt_MPa = rpp_wgt * mmH2OtoMPa;                                     % [MPa]
%
    psil_MPa    = rpp_wgt_MPa - TR*Rp - (rho_kg*grav*znc)./10^6;            % [MPa]
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%    
