%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                             SCRIPT CODE                               %%
%%                           MAKING AVERAGE                              %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%-------------------------------------------------------------------------%
%   This script to allocate storage vectors / matrices                    %
%                                                                         %
%-------------------------------------------------------------------------%
%   Created by  : Darren Drewry                                           %
%   Modified by : Phong Le                                                %
%   Date        : December 26, 2009                                       %
%-------------------------------------------------------------------------%
%
% 
%% CANOPY VARIABLES
  %
  % Radiation Absorption
    PARabs_sun_prof         = NaN(nl_can,N);                    %#ok<AGROW>
    PARabs_shade_prof       = NaN(nl_can,N);                    %#ok<AGROW>
    PARabs_canopy_prof      = NaN(nl_can,N);                    %#ok<AGROW>
  %
    PARabs_sun_norm_prof    = NaN(nl_can,N);                    %#ok<AGROW>
    PARabs_shade_norm_prof  = NaN(nl_can,N);                    %#ok<AGROW>
    PARabs_canopy_norm_prof = NaN(nl_can,N);                    %#ok<AGROW>
  %
    NIRabs_sun_prof         = NaN(nl_can,N);                    %#ok<AGROW>
    NIRabs_shade_prof       = NaN(nl_can,N);                    %#ok<AGROW>
    NIRabs_canopy_prof      = NaN(nl_can,N);                    %#ok<AGROW>
  %
    NIRabs_sun_norm_prof    = NaN(nl_can,N);                    %#ok<AGROW>
    NIRabs_shade_norm_prof  = NaN(nl_can,N);                    %#ok<AGROW>
    NIRabs_canopy_norm_prof = NaN(nl_can,N);                    %#ok<AGROW>
  %
    LWabs_can_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    LWemit_can_prof         = NaN(nl_can,N);                    %#ok<AGROW> 
  %
    SWout_store             = NaN(N,1);                         %#ok<AGROW>
    LWout_store             = NaN(N,1);                         %#ok<AGROW>
    fdiff_store             = NaN(N,1);                         %#ok<AGROW>
%
  % Ecosystem Fluxes (Canopy + Soil)    
    Fc_eco_store            = NaN(N,1);                         %#ok<AGROW>
    LE_eco_store            = NaN(N,1);                         %#ok<AGROW> 
    H_eco_store             = NaN(N,1);                         %#ok<AGROW> 
    Rnrad_eco_store         = NaN(N,1);                         %#ok<AGROW>
%
  % Canopy Fluxes
    An_can_store            = NaN(N,1);                         %#ok<AGROW>
    LE_can_store            = NaN(N,1);                         %#ok<AGROW> 
    H_can_store             = NaN(N,1);                         %#ok<AGROW>
    Rnrad_can_store         = NaN(N,1);                         %#ok<AGROW>
    TR_can_store            = NaN(N,1);                         %#ok<AGROW>
%
  % Soil Fluxes
    Fc_soil_store           = NaN(N,1);                         %#ok<AGROW>
    H_soil_store            = NaN(N,1);                         %#ok<AGROW>
    LE_soil_store           = NaN(N,1);                         %#ok<AGROW>
    G_store                 = NaN(N,1);                         %#ok<AGROW>
    Rnrad_soil_store        = NaN(N,1);                         %#ok<AGROW>
    RH_soil_store           = NaN(N,1);                         %#ok<AGROW>
    E_soil_store            = NaN(N,1);                         %#ok<AGROW>
%
%
%% FLUXES:        
  % Flux Profiles
    An_sun_prof             = NaN(nl_can,N);                    %#ok<AGROW>
    LE_sun_prof             = NaN(nl_can,N);                    %#ok<AGROW>
    H_sun_prof              = NaN(nl_can,N);                    %#ok<AGROW>
    Rnrad_sun_prof          = NaN(nl_can,N);                    %#ok<AGROW>
  %
    An_shade_prof           = NaN(nl_can,N);                    %#ok<AGROW>
    LE_shade_prof           = NaN(nl_can,N);                    %#ok<AGROW>
    H_shade_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    Rnrad_shade_prof        = NaN(nl_can,N);                    %#ok<AGROW>
  %
  % Mean Flux Profiles
    An_canopy_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    LE_canopy_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    H_canopy_prof           = NaN(nl_can,N);                    %#ok<AGROW>
    Rnrad_canopy_prof       = NaN(nl_can,N);                    %#ok<AGROW>    
  %
  % Normalized Flux Profiles (ie. per unit LAI)    
    % Sunlit
        An_sun_norm_prof    = NaN(nl_can,N);                    %#ok<AGROW>
        LE_sun_norm_prof    = NaN(nl_can,N);                    %#ok<AGROW>
        H_sun_norm_prof     = NaN(nl_can,N);                    %#ok<AGROW>
        Rnrad_sun_norm_prof = NaN(nl_can,N);                    %#ok<AGROW>
    %
    % Shaded
        An_shade_norm_prof  = NaN(nl_can,N);                    %#ok<AGROW>
        LE_shade_norm_prof  = NaN(nl_can,N);                    %#ok<AGROW> 
        H_shade_norm_prof   = NaN(nl_can,N);                    %#ok<AGROW>
        Rnrad_shade_norm_prof = NaN(nl_can,N);                  %#ok<AGROW>
    %
    % Canopy
        An_canopy_norm_prof = NaN(nl_can,N);                    %#ok<AGROW>
        LE_canopy_norm_prof = NaN(nl_can,N);                    %#ok<AGROW>
        H_canopy_norm_prof  = NaN(nl_can,N);                    %#ok<AGROW>
        Rnrad_canopy_norm_prof = NaN(nl_can,N);                 %#ok<AGROW>
  %
  % Leaf States
    Tl_sun_prof             = NaN(nl_can,N);                    %#ok<AGROW>
    Tl_shade_prof           = NaN(nl_can,N);                    %#ok<AGROW>
    Tl_sun_Ta_Diff          = NaN(nl_can,N);                    %#ok<AGROW>
    Tl_shade_Ta_Diff        = NaN(nl_can,N);                    %#ok<AGROW>
  %
    psil_sun_prof           = NaN(nl_can,N);                    %#ok<AGROW>
    psil_shade_prof         = NaN(nl_can,N);                    %#ok<AGROW>
  %
    fsv_sun_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    fsv_shade_prof          = NaN(nl_can,N);                    %#ok<AGROW>
  %
    gsv_sun_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    gsv_shade_prof          = NaN(nl_can,N);                    %#ok<AGROW>
  %
    Ci_sun_prof             = NaN(nl_can,N);                    %#ok<AGROW>
    Ci_shade_prof           = NaN(nl_can,N);                    %#ok<AGROW>
  %
    gbv_sun_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    gbh_sun_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    gbv_shade_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    gbh_shade_prof          = NaN(nl_can,N);                    %#ok<AGROW>
  %
    LAI_sun_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    LAI_shade_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    fsun_prof               = NaN(nl_can,N);                    %#ok<AGROW>
    fshade_prof             = NaN(nl_can,N);                    %#ok<AGROW>
    dryfrac_prof            = NaN(nl_can,N);                    %#ok<AGROW>
    wetfrac_prof            = NaN(nl_can,N);                    %#ok<AGROW>
  %
    % canopy h2o storage
        % Sh2o_norm_prof    = NaN(nl_can,N);                    %#ok<AGROW>
        Sh2o_canopy_prof    = NaN(nl_can,N);                    %#ok<AGROW>
        Sh2o_canopy         = NaN(N,1);                         %#ok<AGROW>
        % Sh2o_canopy_max   = NaN(N,1);                         %#ok<AGROW>
    %
    % Condensation
        Ch2o_canopy_prof    = NaN(nl_can,N);                    %#ok<AGROW>                                
        Ch2o_canopy         = NaN(N,1);                         %#ok<AGROW>
    %
    % evaporation
        Evap_canopy_prof    = NaN(nl_can,N);                    %#ok<AGROW> 
        Evap_canopy         = NaN(N,1);                         %#ok<AGROW>
    %
        ppt_ground_store    = NaN(N,1);                         %#ok<AGROW>
        qinfl_store         = NaN(N,1);                         %#ok<AGROW>
  %
  % Mean Canopy Profiles
	Ci_canopy_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    Tl_canopy_prof          = NaN(nl_can,N);                    %#ok<AGROW>
    gsv_canopy_prof         = NaN(nl_can,N);                    %#ok<AGROW>
    psil_canopy_prof        = NaN(nl_can,N);                    %#ok<AGROW>   
    fsv_canopy_prof         = NaN(nl_can,N);                    %#ok<AGROW>
  %
  % Mean Canopy States
    Ci_mean                 = NaN(N,1);                         %#ok<AGROW>
    Tl_mean                 = NaN(N,1);                         %#ok<AGROW>
    gsv_mean                = NaN(N,1);                         %#ok<AGROW>
    psil_mean               = NaN(N,1);                         %#ok<AGROW>
    fsv_mean                = NaN(N,1);                         %#ok<AGROW>
  %
  % Canopy Microenvironment
    CAz_prof                = NaN(nl_can,N);                    %#ok<AGROW>
    TAz_prof                = NaN(nl_can,N);                    %#ok<AGROW>
    EAz_prof                = NaN(nl_can,N);                    %#ok<AGROW>
    Uz_prof                 = NaN(nl_can,N);                    %#ok<AGROW>
%
%    
%% SOIL VARIABLES
	volliq_store            = NaN(nl_soil,N);    
    krad_store              = NaN(nl_soil,N);
    hk_store                = NaN(nl_soil,N);
    Ts_store                = NaN(nl_soil,N);
    smp_store               = NaN(nl_soil,N);
    rpp_store               = NaN(nl_soil,N);
    smpMPA_store            = NaN(nl_soil,N);
    rppMPA_store            = NaN(nl_soil,N);
    smp_weight_store        = NaN(N,1); 
    rpp_weight_store        = NaN(N,1); 
  %
    if (SWITCHES.soilheat_on)
        Ts_store = NaN(nl_soil,N);
    end
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<<<< END OF SCRIPT >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%          
   
    
    