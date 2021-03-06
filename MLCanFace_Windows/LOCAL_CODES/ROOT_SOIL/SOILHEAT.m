function [Ts_new, cpv] = SOILHEAT (nl_soil, dt, znode, zlayer, dz, Ts, Hg, ...
                        alph, Tf, theta_liq, TK_dry, TK_sol, TK_liq, TK_ice, ...
                        poros, HC_sol, HC_liq, HC_ice, rho_liq, rho_ice)         
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%%                              FUNCTION CODE                            %%
%%                       SOIL HEAT FLOW CALCULATION                      %%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%------------------------------------------------------------------------%%
%  This function implements the numerical solution for soil heat          %
%   transport described in Oleson et al (2004) for the Community Land     %
%   Model (CLM)                                                           %
%  Top BC: Hg is heat flux into top of soil column                        %
%  Bottom BC: zero heat flux at bottom of soil column                     %
%-------------------------------------------------------------------------%
%  The following equation is solved:                                      %
%                                                                         %
%   dT    d        dT                                                     %
% C -- = -- ( TK * -- )                                                   %
%   dt   dz        dz                                                     %
%-------------------------------------------------------------------------%
%                                                                         %
%   INPUT VARIABLES:::::::::::::::::::::::::::::::::::::::::::            %
%       nl_soil     = number of soil layers                               %
%       dt          = time step                                 [s]       %
%       znode       = soil node depths                          [m]       %
%       zlayer      = soil layer interface depths             	[m]       %         
%       dz          = layer thickness                        	[m]       %
%       alph        = Crank-Nicholson parameter                 [-]       %
%       Ts          = soil temperature                         	[K]       %         
%       Tf          = freezing temperature of fresh water      	[K]       %
%       theta_liq   = soil liquid water content              	[m^3/m^3] %
%       theta_ice   = soil ice content                        	[m^3/m^3] %
%       TK_dry      = thermal conductivity of dry soil        	[W/m/ K]  %
%       TK_sol      = thermal conductivity of soil solids      	[W/m/ K]  %
%       TK_liq      = thermal conductivity of liquid water    	[W/m/ K]  %
%       TK_ice      = thermal conductivity of ice             	[W/m/ K]  %
%       poros       = soil porosity, saturated water content 	[-]       %
%       HC_sol      = heat capacity of soil solids           	[J/m^3/K] %
%       HC_liq      = heat capacity of liquid water             [J/kg/ K] %
%       HC_ice      = heat capacity of ice                    	[J/kg/ K] %
%       Hg          = soil heat flux at top of soil column   	[W/m^2]   %     
%       rho_liq     = density of water                       	[kg/m^3]  %
%       rho_ice     = density of ice                        	[kg/m^3]  %
%                                                                         %
%   OUTPUR VARIABLES:::::::::::::::::::::::::::::::::::::::::::           %
%       dTs         = change in soil temperature                [K]       %
%       Tsurf       = soil surface temp                         [K]       %
%                                                                         %
%   LOCAL VARIABLES::::::::::::::::::::::::::::::::::::::::::::           %
%       amx         = "a" left off diagonal of tridiagonal matrix         %
%       bmx         = "b" diagonal column for tridiagonal matrix          %
%       cmx         = "c" right off diagonal tridiagonal matrix           %
%       rmx         = "r" forcing term of tridiagonal matrix              %
%                                                                         %
%-------------------------------------------------------------------------%
%   Created by  : Darren Drewry                                           %
%   Editted by  : Phong Le                                                %
%   Date        : January 10, 2010                                        %
%% --------------------------------------------------------------------- %%
%%
    theta_ice = zeros(nl_soil,1);
%
%
% SOIL SURFACE ENERGY EXCHANGE
%*******
% FIX THIS WHEN CANOPY MODEL COUPLED TO SOIL !!!!
% HEAT FLUX FROM ATMOSPHERE 
%   (Hg and dH_dT)
    dHg_dT=0;
%
%
% VOLUMETRIC HEAT CAPACITY [J / m^3 / K]  (6.67)
	cpv = HC_sol.*(1-poros) ...
            + ((theta_liq * rho_liq)).*HC_liq + ((theta_ice * rho_ice))...
            .* HC_ice - 0*10^6;
%   
%    
% THERMAL CONDUCTIVITIES AT NODES 
    nfrinds = find(Ts>=Tf);     % Indices of non-frozen layers
    frinds  = find(Ts<Tf);      % Indices of frozen layers
    %
    % Saturated Thermal Conductivity [W / m / K]
        TK_sat(nfrinds) = (TK_sol(nfrinds).^(1-poros(nfrinds))) .* ...
                            (TK_liq.^(poros(nfrinds)));
        TK_sat(frinds)  = (TK_sol(frinds).^(1-poros(frinds))) .* ...
                            (TK_liq.^(poros(frinds))) .* ...
                            (TK_ice.^(poros(frinds)-theta_liq(frinds)));
        TK_sat = TK_sat(:);
    %    
    % (6.64)
        Sr = (theta_liq + theta_ice) ./ poros;
        if (max(Sr) > 1)
            disp('ERROR in SoilHeatTransport: Sr > 1');
            keyboard;
        end
    %    
    % Kersten Number (6.63)
        Ke(nfrinds) = log10(Sr(nfrinds))+1;
        Ke(frinds) = Sr(frinds);
        Ke(find(Ke<0)) = 0; 
        Ke = Ke(:);
    %
    % Soil Thermal Conductivity [W / m / K] (6.58)
        TKsoil = Ke .* TK_sat + (1-Ke).*TK_dry;
        inds = find(Sr <= 10^-7);
        TKsoil(inds) = TK_dry(inds);
%    
%    
% THERMAL CONDUCTIVITIES AT LAYER INTERFACES (6.11)
	num     = TKsoil(1:nl_soil-1) .* TKsoil(2:nl_soil) .* (znode(2:nl_soil)...
                - znode(1:nl_soil-1));
    denom   = TKsoil(1:nl_soil-1) .* (znode(2:nl_soil) - zlayer(1:nl_soil-1))...
                + TKsoil(2:nl_soil) .* (zlayer(1:nl_soil-1) - znode(1:nl_soil-1));
%
	TKsoil_h(1:nl_soil-1) = num ./ denom;
    TKsoil_h(nl_soil)     = 0;
    TKsoil_h              = TKsoil_h(:);
%    
%
% SET UP TRI-DIAGONAL SOLUTION
    fact = dt ./ cpv ./ dz;
    zdiff = diff(znode);
    %
    % TOP NODE:
        aa(1) = 0;
        bb(1) = 1 + fact(1) * ((1-alph)*TKsoil_h(1)/(znode(2)-znode(1)) - dHg_dT);
        cc(1) = -(1-alph) * fact(1) * TKsoil_h(1) / (znode(2)-znode(1));
        rr(1) = Ts(1) + fact(1) * (Hg - dHg_dT*Ts(1) - alph * TKsoil_h(1) * (Ts(1)-Ts(2))/(znode(2)-znode(1)));
    %
    % INTERNAL NODES:
        inds = [2:nl_soil-1];
        t1 = TKsoil_h(inds-1) ./ (znode(inds) - znode(inds-1));
        t2 = TKsoil_h(inds) ./ (znode(inds+1) - znode(inds));
        aa(inds) = -(1-alph) * fact(inds) .* t1;
        bb(inds) = 1 + (1-alph) * fact(inds) .* (t1 + t2);
        cc(inds) = - (1-alph) * fact(inds) .* t2;
    %    
        Fi = -t2 .* (Ts(inds) - Ts(inds+1));
        Fim1 = -t1 .* (Ts(inds-1) - Ts(inds));
        rr(inds) = Ts(inds) + alph * fact(inds) .* (Fi - Fim1);
    %
    % BOTTOM NODE:
        aa(nl_soil) = -(1-alph) * fact(nl_soil) * TKsoil_h(nl_soil-1) / (znode(nl_soil) - znode(nl_soil-1));
        bb(nl_soil) = 1 + (1-alph) * fact(nl_soil) * TKsoil_h(nl_soil-1) / (znode(nl_soil) - znode(nl_soil-1));
        cc(nl_soil) = 0;
        rr(nl_soil) = Ts(nl_soil) + alph * fact(nl_soil) * TKsoil_h(nl_soil-1) / ...
                    (znode(nl_soil) - znode(nl_soil-1)) * (Ts(nl_soil-1) - Ts(nl_soil));
%
%                
% CALL TRI-DIAGONAL SOLVER
    Ts_new = TRIDIAG(nl_soil, aa, bb, cc, rr);
    Ts_new = Ts_new(:);
%
%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%
%% <<<<<<<<<<<<<<<<<<<<<<<<< END OF FUNCTION >>>>>>>>>>>>>>>>>>>>>>>>>>>>%%
%:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::%    
