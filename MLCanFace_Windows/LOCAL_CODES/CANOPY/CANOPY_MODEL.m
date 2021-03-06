function [An_can,   LE_can,     TR_can,     H_can,      Rnrad_can,...
                    Fc_soil,    LE_soil,    H_soil,     Rnrad_soil,...
                    G,          Rnrad_sun,  Rnrad_shade,Rnrad_eco,...
                    An_sun,     An_shade,   LE_sun,     LE_shade,...
                    H_sun,      H_shade,    Tl_sun,     Tl_shade,...
                    psil_sun,   psil_shade, gsv_sun,    gsv_shade,...
                    fsv_sun,    fsv_shade,  Ci_sun,     Ci_shade,...
                    CAz,        TAz,        EAz,        Uz,...
                    gbv_sun,    gbh_sun,    gbv_shade,  gbh_shade,...
                    LAIsun,     LAIshade,   fsun,       fshade,...
                    PARabs_sun, PARabs_shade,NIRabs_sun,NIRabs_shade,...
                    SWout,      LWabs_can,  LWemit_can, LWout,...
                    RH_soil,    fdiff,      Sh2o_prof,  Sh2o_can,...
                    ppt_ground, Ch2o_prof,  Ch2o_can,   Evap_prof,...  
                    Evap_can,   dryfrac,    wetfrac,    Vz,...
                    VARIABLES   An_sun_2    An_shaded   LAI_sunlit...
                    LAI_shaded  gs_sun_2    An_can_top  ] = ...         
            CANOPY_MODEL(...
                    SWITCHES,   VERTSTRUC,  FORCING,    PARAMS,...
                    VARIABLES,  CONSTANTS);
%         
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                             FUNCTION CODE                             %%
%%                       IMPLEMENTING CANOPY MODEL                       %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%-------------------------------------------------------------------------%
%   Created by  : Darren Drewry                                           %
%   Editted by  : Phong Le                                                %
%   Date        : December 26, 2009                                       %
%% --------------------------------------------------------------------- %%  
%
%
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<< DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%
    turb_on     = SWITCHES.turb_on;
%    
    Sh2o_prof   = VARIABLES.CANOPY.Sh2o_prof;
%    
    Tsoil       = VARIABLES.SOIL.Ts(1);
%    
    znc         = VERTSTRUC.znc;
    vinds       = VERTSTRUC.vinds; 
    nvinds      = VERTSTRUC.nvinds; 
%    
    clump       = PARAMS.Rad.clump;
    Ro          = PARAMS.Resp.Ro;
    Q10         = PARAMS.Resp.Q10;
    nl_can      = PARAMS.CanStruc.nl_can;
    Ffact       = PARAMS.CanStruc.Ffact;    
%    
    dtime       = CONSTANTS.dtime;
%    
%*************************************************************************%
%% <<<<<<<<<<<<<<<<<<<<<<<<END OF DE-REFERENCE BLOCK >>>>>>>>>>>>>>>>>>> %%
%*************************************************************************%
%%          
% Vertical distribution of photosynthetic capacity
    [Vz]                = PH_Dist(VERTSTRUC, PARAMS);
    VARIABLES.CANOPY.Vz = Vz;
%
% WIND PROFILE    
    [Uz, Km]            = ORDER_1_CLOSURE_U(FORCING, VERTSTRUC, PARAMS);  
    VARIABLES.CANOPY.Uz = Uz;
    VARIABLES.CANOPY.Km = Km;
%    
% CANOPY PRECIPITATION INTERCEPTION
%   Smax [mm / LAI]
%   Sh2o_prof
%   ppt [mm]
    [Sh2o_prof, Smaxz, ppt_ground, wetfrac, dryfrac] = ...
        PRECIP_INTERCEPTION(FORCING, VARIABLES, VERTSTRUC, PARAMS);   
    %ASSIGN
    VARIABLES.CANOPY.Sh2o_prof  = Sh2o_prof;
    VARIABLES.CANOPY.Smaxz      = Smaxz;
    VARIABLES.CANOPY.wetfrac    = wetfrac;
    VARIABLES.CANOPY.dryfrac    = dryfrac;
    VARIABLES.SOIL.ppt_ground   = ppt_ground;
%
%======================================================================
% SHORTWAVE RADIATION PROFILES
%======================================================================
    [fsun,  fshade,     LAIsun,     LAIshade,   SWabs_sun,  SWabs_shade,...
            PARabs_sun, PARabs_shade,           NIRabs_sun, NIRabs_shade, ...
            PARabs_sun_lai,                     PARabs_shade_lai, ...
            SWabs_soil, PARabs_soil,            NIRabs_soil, ...
            SWout,      PARout,     NIRout,     PARtop,     NIRtop,...
            fdiff,      Kbm,        taud        ] = ...
    SWRAD...
            (FORCING, VERTSTRUC, PARAMS, CONSTANTS); 
    
    % STORE VARIABLES
    VARIABLES.CANOPY.PARabs_sun     = PARabs_sun_lai;
    VARIABLES.CANOPY.PARabs_shade   = PARabs_shade_lai;
    VARIABLES.CANOPY.fsun           = fsun;
    VARIABLES.CANOPY.fshade         = fshade;
    VARIABLES.CANOPY.LAIsun         = LAIsun;
    VARIABLES.CANOPY.LAIshade       = LAIshade;
    VARIABLES.CANOPY.taud           = taud;
%
% LONGWAVE CONVERGENCE LOOP  
    converged_LW    = 0; 
    cnt_LW          = 0; 
    maxiters        = 20; 
    percdiff        = 0.01;
    while (~converged_LW)     
        %
        % LONGWAVE RADIATION ABSORPTION    
        [LWabs_can,     LWabs_sun,  LWabs_shade,    LWabs_soil,...
                        LWin,       LWout,          LWemit_can,...
                        LWemit_sun, LWemit_shade,   LWemit_soil] = ...
        LWRAD...
            (FORCING,   VARIABLES,  VERTSTRUC,      PARAMS,     CONSTANTS);          
        %
        % TOTAL ABSORBED RADIATION [W/m^2 ground]
        Totabs_sun      = LWabs_sun + SWabs_sun;         
        Totabs_shade    = LWabs_shade + SWabs_shade;   
        %
        % TOTAL ABSORBED RADIATION PER UNIT LEAF AREA [W/m^2 leaf area]
        Rabs_sun_lai    = Totabs_sun./LAIsun;
        Rabs_shade_lai  = Totabs_shade./LAIshade;
        %
        % SOIL ABSORBED ENERGY
        Totabs_soil     = SWabs_soil + LWabs_soil;
        Rnrad_soil      = Totabs_soil - LWemit_soil;
        %
        % ASSIGN
        VARIABLES.CANOPY.Rabs_sun   = Rabs_sun_lai;
        VARIABLES.CANOPY.Rabs_shade = Rabs_shade_lai;
        VARIABLES.SOIL.Totabs_soil  = Totabs_soil;
        %
        %==================================================================
        %                   SHADED CANOPY SOLUTION
        %   Calculations performed per [m^2 ground area], and canopy fluxes
        %   are calculated by integrating over the shaded leaf area
        %==================================================================     
        sunlit = 0;
        [Ph_shade,  An_shade,   Ci_shade,   gsv_shade,  Tl_shade,...
                    LE_shade,   TR_shade,   Evap_shade, H_shade, ...
                    psil_shade, fsv_shade,  Ch2o_shade, gbv_shade,...
                    gbh_shade,  VARIABLES] = ...
        LEAF_SOLUTION ...
            (FORCING,   VARIABLES,  PARAMS, CONSTANTS,  VERTSTRUC, sunlit);
        %                              
        %==================================================================
        %                       SUNLIT CANOPY SOLUTION
        %   Calculations performed per [m^2 leaf area], and canopy fluxes
        %       are calculated by integrating vertically over the sunlit 
        %       leaf area
        %==================================================================
        if (sum(fsun)==0)   % under nocturnal conditions all leaf area is 
                            % considered to be shaded
            An_sun      = zeros(nl_can,1);
            LE_sun      = zeros(nl_can,1);
            H_sun       = zeros(nl_can,1);
            Phtype_sun  = NaN(nl_can,1);
            gsv_sun     = gsv_shade;
            gbv_sun     = gbv_shade;
            gbh_sun     = gbh_shade;
            Ci_sun      = Ci_shade;            
            Tl_sun      = Tl_shade;   
            psil_sun    = psil_shade;
            fsv_sun     = fsv_shade;
            Evap_sun    = zeros(nl_can,1);
            TR_sun      = zeros(nl_can,1);
            Ch2o_sun    = zeros(nl_can,1);
        else
            sunlit      = 1;
            [Ph_sun,    An_sun,     Ci_sun,     gsv_sun,    Tl_sun,...
                        LE_sun,     TR_sun,     Evap_sun,   H_sun, ...
                        psil_sun,   fsv_sun,    Ch2o_sun,   gbv_sun,...
                        gbh_sun,    VARIABLES] = ...
            LEAF_SOLUTION...
                (FORCING,   VARIABLES,  PARAMS, CONSTANTS,  VERTSTRUC, sunlit);                                
        end            
        %
        % ASSIGN
        VARIABLES.CANOPY.An_sun     = An_sun;
        VARIABLES.CANOPY.An_shade   = An_shade;
        VARIABLES.CANOPY.LE_sun     = LE_sun;
        VARIABLES.CANOPY.LE_shade   = LE_shade;
        VARIABLES.CANOPY.H_sun      = H_sun;
        VARIABLES.CANOPY.H_shade    = H_shade;     
        %    
        % SOIL RESPIRATION [umol CO2/ m^2 ground / s] 
        Fc_soil = Ro .* Q10.^((Tsoil - 10)/10);                             % See (Lloyd and Taylor, 1994) & (Van't Hoff, 1898)
                                                                            % Eqn 38, Drewry et al, 2009 - Part B: Online Supplement
        %    
        % SOIL ENERGY FLUXES
        [H_soil, LE_soil, G, RH_soil] = SOIL_SURFACE_FLUXES(VARIABLES,...
                                        VERTSTRUC, PARAMS, CONSTANTS);
        %
        % ASSIGN
        VARIABLES.SOIL.Fc_soil      = Fc_soil;
        VARIABLES.SOIL.LE_soil      = LE_soil;
        VARIABLES.SOIL.H_soil       = H_soil;    
        %
        if (turb_on)
            [CAz, EAz, TAz] = MICROENVIRONMENT(VARIABLES, VERTSTRUC,...
                              PARAMS, CONSTANTS);  
            % ASSIGN
            VARIABLES.CANOPY.CAz    = CAz;
            VARIABLES.CANOPY.TAz    = TAz;
            VARIABLES.CANOPY.EAz    = EAz;
        end        
        %                              
        % TEST LONGWAVE CONVERGENCE
        cnt_LW = cnt_LW + 1; 
        if (cnt_LW>1)
            diffprof        = LWabs_can - LWabs_prev;
            percdiffprof    = diffprof ./ LWabs_prev;
            %
            if (max(percdiffprof) < percdiff)
                converged_LW = 1;
            end
        end
        LWabs_prev = LWabs_can;
        %
        %
        if (cnt_LW>maxiters && converged_LW==0)
            %disp(['*** TOO MANY ITERATIONS IN CANOPY MODEL!!! --> Timestep:', num2str(VARIABLES.niters_driver)]);
            break;
        end      
    %    
    end %LONGWAVE ITERATION
    %    
    %
% NET RADIATION
	Rnrad_eco   = (FORCING.Rg - SWout) + (FORCING.LWdn - LWout);
    Rnrad_sun   = SWabs_sun + LWabs_sun - LWemit_sun;
    Rnrad_shade = SWabs_shade + LWabs_shade - LWemit_shade;
%        
% H2O storage on foliage --> Precipitation and Condensation
    Evap_prof   = (Evap_sun.*LAIsun + Evap_shade.*LAIshade) * dtime;        % [mm] Evaporation at each layer
    Evap_can    = sum(Evap_prof);                                           % [mm] Total canopy evaporation
    %
    Ch2o_prof   = -(Ch2o_sun.*LAIsun + Ch2o_shade.*LAIshade) * dtime;       % [mm] Condensation at each layer
    Ch2o_can    = sum(Ch2o_prof);                                           % [mm] Total canopy condensation
    %
    %ASSIGN
    VARIABLES.CANOPY.Ch2o_prof = Ch2o_prof;
    VARIABLES.CANOPY.Evap_prof = Evap_prof;
%       
% Adjust Canopy Water Storage
    [Sh2o_prof, Sh2o_can] = EVAP_CONDENSATION_ADJUST(VARIABLES, VERTSTRUC, PARAMS);
%                        
% COMPUTE CANOPY FLUXES
    An_can      =   sum(An_sun(vinds)   .*LAIsun(vinds)) + ...
                    sum(An_shade(vinds) .*LAIshade(vinds)); 
    %
    An_can_top  =   (An_sun(end) .* LAIsun(end) + An_shade(end) .* LAIshade(end));
    LAI_sunlit  =   sum(LAIsun(vinds));
    LAI_shaded  =   sum(LAIshade(vinds));
    %
    An_sun_2    =   mean(An_sun(vinds(end-1:end)));                         % Phong added
    An_shaded   =   sum(An_shade(vinds));                                   % Phong added
    gs_sun_2    =   mean(gsv_sun(vinds(end-1:end)));
    %
    LE_can      =   sum(LE_sun(vinds)   .*LAIsun(vinds)) + ... 
                    sum(LE_shade(vinds) .*LAIshade(vinds));
    %
    H_can       =   sum(H_sun(vinds)    .*LAIsun(vinds)) + ... 
                    sum(H_shade(vinds)  .*LAIshade(vinds)); 
    %
    TR_can      =   sum(TR_sun(vinds)   .*LAIsun(vinds)) + ... 
                    sum(TR_shade(vinds) .*LAIshade(vinds)); % [g/m^2] = [mm]
    %            
    Rnrad_can   =   sum(Rnrad_sun(vinds)) + sum(Rnrad_shade(vinds));
    %    
    %ASSIGN
    VARIABLES.CANOPY.TR_total   = TR_can;
    VARIABLES.CANOPY.Sh2o_prof  = Sh2o_prof;
    VARIABLES.SOIL.ppt_ground   = ppt_ground;
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%                 
                