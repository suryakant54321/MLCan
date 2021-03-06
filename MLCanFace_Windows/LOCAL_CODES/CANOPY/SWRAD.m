function [fsun,         fshade,         LAIsun,         LAIshade, ...
          SWabs_sun,    SWabs_shade,    PARabs_sun,     PARabs_shade,...
          NIRabs_sun,   NIRabs_shade,   PARabs_sun_lai, PARabs_shade_lai, ...
          SWabs_soil,   PARabs_soil,    NIRabs_soil, ...
          SWout,        PARout,         NIRout,...
          PARtop,       NIRtop,         fdiff,          Kbm,    taud] = ...
    SWRad (FORCING,     VERTSTRUC,      PARAMS,         CONSTANTS)
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                             FUNCTION CODE                             %%
%%                  CALCULATE THE SHORTWAVE RADIATION                    %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%   This function is used to calculate the vertical solution of the       %
%   shortwave radiative regime through the canopy considers PAR and NIR   %
%   separately (Beer's Law relationship). See Campbell and Norman, 1998   % 
%       - Diffuse fraction of downwelling shortwave is determined from    %
%         algorithms described in Spitters (1986)                         %
%       - Solar Zenith angle is determined from time of day and site      %
%         location as described in Campbell and Norman, 1998              %                
%-------------------------------------------------------------------------%
%   Created by  : Darren Drewry                                           %
%   Editted by  : Phong Le                                                %
%   Date        : January 09, 2010                                        %
%-------------------------------------------------------------------------%
%                                                                         %
%   INPUTS:                                                               %
%       SWin        = measured incident short-wave radiation              % [W / m^2 ground]
%       PARin       = measured incident above-canopy PAR                  % [umol / m^2 ground / s]
%       PARtop      = incident above-canopy PAR                           % [umol / m^2 ground / s]
%       NIRtop      = incident above-canopy NIR                           % [W / m^2 ground]
%       LAI         = leaf area index of each canopy layer                % [m^2 leaf / m^2 ground]
%       zendeg      = zenith angle of sun                                 % [degree]
%       Pa          = air pressure                                        % [kPa]
%       transmiss   = transmissivity of the atmosphere                    % [-]                      
%       xx          = leaf distribution parameter                         % [-]
%       clump       = foliage clumping parameter                          % [-]
%       trans_PAR   = foliage transmissivity to PAR                       % [-]                        
%       refl_PAR    = foliage reflectivity to PAR                         % [-]
%       trans_NIR   = foliage transmissivity to NIR                       % [-]
%       refl_NIR    = foliage reflectivity to NIR                         % [-]
%       refl_soil   = soil reflectivity for SW radiation                  % [-]       
%       Kdf         = diffuse extinction coefficient                      % [-]
%       Wm2toumol   = unit conversion factor                              % [W/m^2] to [umol/m^2]
%                                                                         %
%   OUTPUTS:                                                              %
%       fsun        = fraction of canopy foliage that is sunlit           % [-]
%       fshade      = fraction of canopy foliage that is shaded           % [-]
%       PARabs_sun  = absorbed PAR by sunlit fraction in each layer       % [umol / m^2 ground / s]
%       PARabs_shade= absorbed PAR by shaded fraction in each layer       % [umol / m^2 ground / s]
%       NIRabs_sun  = absorbed NIR by sunlit fraction in each layer       % [W / m^2 ground]
%       NIRabs_shade= absorbed NIR by shaded fraction in each layer       % [W / m^2 ground]
%                                                                         %
%% --------------------------------------------------------------------- %%
%
%
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<< DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%
    SWin        = FORCING.Rg;
    zendeg      = FORCING.zen;
    doy         = FORCING.doy;
    Pa          = FORCING.Pa;
%    
    LAIz        = VERTSTRUC.LAIz;
    vinds       = VERTSTRUC.vinds; 
%
    transmiss   = PARAMS.Rad.transmiss;
    xx          = PARAMS.Rad.xx;
    clump       = PARAMS.Rad.clump;
    trans_PAR   = PARAMS.Rad.trans_PAR;
    refl_PAR    = PARAMS.Rad.refl_PAR;
    trans_NIR   = PARAMS.Rad.trans_NIR;
    refl_NIR    = PARAMS.Rad.refl_NIR;
    refl_soil   = PARAMS.Rad.refl_soil;
    Kdf         = PARAMS.Rad.Kdf;
%    
    Wm2toumol   = CONSTANTS.Wm2toumol;
    umoltoWm2   = CONSTANTS.umoltoWm2;
%    
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<END OF DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%%
% CONVERT ZENITH IN DEGREE TO RADIAN
    zenrad      = zendeg * pi/180;
    if (zendeg > 89)
        SWin  = 0;
        PARin = 0;
    end
%    
    PARtop      = SWin * 0.45 * Wm2toumol;                                  % Reference??
    NIRtop      = SWin * 0.55;                                              % Reference??    
%
% DIFFUSE FRACTION
    [fdiff] = DIFFUSE_FRACTION (zendeg, doy, SWin); 
    if (zendeg > 80)
        fdiff = 1;
    end
%    
    PARtop_beam = PARtop * (1-fdiff);
    PARtop_diff = PARtop - PARtop_beam;
    NIRtop_beam = NIRtop * (1-fdiff);
    NIRtop_diff = NIRtop - NIRtop_beam;
%   
% BEAM EXTINCTION COEFF FOR ELLIPSOIDAL LEAF DISTRIBUTION (EQN. 15.4 C&N)
%   or Equation (24) in Drewry et al, 2009 - Part B: Online Supplement.
    Kbm = sqrt(xx^2 + tan(zenrad)^2) / (xx + 1.774*(xx+1.182)^(-0.733));
%
% INITIALIZE ARRAYS
    len         = length(LAIz);
    PARabs_sun  = zeros(len,1);
    PARabs_shade= zeros(len,1);
    NIRabs_sun  = zeros(len,1);
    NIRabs_shade= zeros(len,1);
    fsun        = zeros(len,1);
    fshade      = zeros(len,1);
    LAIsun      = zeros(len,1);
    LAIshade    = zeros(len,1);
    diffdn      = zeros(len,1);
    diffup      = zeros(len,1);
    PARabs_soil = 0;
    NIRabs_soil = 0;
    radlost     = 0;
    PARout      = 0;
    NIRout      = 0;
%    
    if (PARtop<1)
        LAIshade = LAIz;
        fshade   = fshade + 1;
    else    
    % Iterate to Solve PAR Absorption Profile
        count = 0;
        percdiff = 1;
        radin    = PARtop; 
        beam_top = PARtop_beam; 
        diff_top = PARtop_diff;
        while (percdiff > 0.01)
            [PARabs_sun,    PARabs_shade,   PARabs_soil,    fsun,   fshade,...
                diffdn,     diffup,         radabs_tot,     radlost ] = ...
            SW_ATTENUATION (beam_top,       diff_top,       LAIz,   trans_PAR,...
                            refl_PAR,       refl_soil,      clump,  Kbm,...
                            Kdf,            count,          PARabs_sun,...
                            PARabs_shade,   diffdn,         diffup, PARabs_soil,...
                            fsun,           fshade,         radlost);
        %
             beam_top = 0;  
             diff_top = 0;
        %
             radtot   = radabs_tot + radlost;
             percdiff = (radin - radtot) / radin;
        %
             count = count + 1;
             if (count>5)
                 disp('COUNT > 5 in PAR loop!!!');
                 break;
             end
        end
    %
        LAIsun   = fsun .* LAIz;
        LAIshade = fshade .* LAIz;
    %
        PARout   = radlost;

    % Iterate to Solve NIR Absorption Profile
        diffdn   = zeros(len,1);
        diffup   = zeros(len,1);
        radlost  = 0;
    %
        count    = 0;
        percdiff = 1;
        radin    = NIRtop; 
        beam_top = NIRtop_beam; diff_top = NIRtop_diff;
        while (percdiff > 0.01)
            [NIRabs_sun,    NIRabs_shade,   NIRabs_soil,    fsun,   fshade,...
                    diffdn, diffup,         radabs_tot,     radlost] = ...
             SW_ATTENUATION (beam_top,      diff_top,       LAIz,   trans_NIR,...
                            refl_NIR,       refl_soil,      clump,  ...
                            Kbm,            Kdf,            count,...
                            NIRabs_sun,     NIRabs_shade,   diffdn, diffup,...
                            NIRabs_soil,    fsun,           fshade, radlost);
        %
             beam_top   = 0;  
             diff_top   = 0;
        %
             radtot     = radabs_tot + radlost;
             percdiff   = (radin - radtot) / radin;
        %
             count      = count + 1;
             if (count>5)
                 disp('COUNT > 5 in NIR loop!!!');
                 break;
             end
        end
        NIRout = radlost;
    end
%
    taud        = exp(-Kdf*clump*LAIz);
%
% Total SW outgoing [W/m^2]
    SWout       = PARout*umoltoWm2 + NIRout;
%    
% Shortwave Absorption Profiles    
    SWabs_sun   = PARabs_sun*umoltoWm2 + NIRabs_sun;
    SWabs_shade = PARabs_shade*umoltoWm2 + NIRabs_shade;
%    
% Shortwave Absorbed by Soil    
    SWabs_soil  = NIRabs_soil + PARabs_soil*umoltoWm2;  % [W/m^2]
%    
% Absorbed PAR per unit LAI [umol/m^2 LEAF AREA/s]
    PARabs_sun_lai          = PARabs_sun;
    PARabs_sun_lai(vinds)   = PARabs_sun_lai(vinds)./LAIsun(vinds);
%
    PARabs_shade_lai        = PARabs_shade;
    PARabs_shade_lai(vinds) = PARabs_shade_lai(vinds)./LAIshade(vinds);
%
%
% MAKE OUTPUR PROFILES COLUMN VECTORS
    fsun        = fsun(:);
    fshade      = fshade(:);
    LAIsun      = LAIsun(:);
    LAIshade    = LAIshade(:);
    SWabs_sun   = SWabs_sun(:);
    SWabs_shade = SWabs_shade(:);
    PARabs_sun  = PARabs_sun(:);
    PARabs_shade= PARabs_shade(:);
    NIRabs_sun  = NIRabs_sun(:);
    NIRabs_shade= NIRabs_shade(:);
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%     