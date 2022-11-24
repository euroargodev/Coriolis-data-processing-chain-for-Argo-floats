% ------------------------------------------------------------------------------
% Initialisation des valeurs par défaut des variables courantes.
%
% SYNTAX :
%   init_valdef
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   29/08/2007 - RNU - creation
% ------------------------------------------------------------------------------
function init_valdef(varargin)

global g_dateDef;
global g_latDef;
global g_lonDef;
global g_presDef;
global g_tempDef;
global g_salDef;
global g_condDef;
global g_oxyDef;
global g_molarDoxyDef;
global g_doxyDef;
global g_groundedDef;
global g_qcDef;
global g_durationDef;
global g_serialNumDef;
global g_vertSpeedDef;
global g_elevDef;
global g_ordreDef;
global g_cycleNumDef;
global g_cycleNumTrajDef;
global g_locClasDef;
global g_satNameDef;
global g_dateGregStr;
global g_profNumDef;
global g_clockDriftFlagDef;
global g_clockOffsetTrajDef;

global g_yoLonDef;
global g_yoLatDef;
global g_yoPresDef;
global g_yoTempDef;
global g_yoSalDef;
global g_yoJuldDef;
global g_yoUVDef;
global g_yoDeepUVErrDef;
global g_yoProfNumDef;

global g_argosLonDef g_argosLatDef;

g_dateDef = 99999.99999999;
g_latDef = -99.999;
g_lonDef = -999.999;
g_presDef = 9999.9;
g_tempDef = 99.999;
g_salDef = 99.999;
g_condDef = 99.999;
g_oxyDef = 99999;
g_molarDoxyDef = 999;
g_doxyDef = 999.999;
g_groundedDef = -1;
g_qcDef = -1;
g_durationDef = -1;
g_serialNumDef = -1;
g_vertSpeedDef = 999.9;
g_elevDef = 999999;
g_ordreDef = 99999;
g_cycleNumDef = -1;
g_locClasDef = '9';
g_satNameDef = '9';
g_dateGregStr = '9999/99/99 99:99:99';
g_profNumDef = -1;

% valeurs par défaut du format DEP2
g_clockDriftFlagDef = 9;

% valeurs par défaut du format TRAJ
g_cycleNumTrajDef = 99999;
g_clockOffsetTrajDef = 999999.0;

% valeurs par défaut du format YoMaHa
g_yoLonDef = -999.9999;
g_yoLatDef = -99.9999;
g_yoPresDef = -999.9;
g_yoTempDef = -99.999;
g_yoSalDef = -99.999;
g_yoJuldDef = -9999.999;
g_yoUVDef = -999.99;
g_yoDeepUVErrDef = -999.99;
g_yoProfNumDef = -99;

% valeurs par défaut des fichiers Argos bruts au format Aoml
g_argosLonDef = 999.999;
g_argosLatDef = 99.999;

return;
