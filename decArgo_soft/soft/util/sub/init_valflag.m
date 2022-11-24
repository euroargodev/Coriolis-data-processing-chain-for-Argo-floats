% ------------------------------------------------------------------------------
% Initialisation des valeurs des flags utilisés dans le format DEP.
%
% SYNTAX :
%   init_valflag
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
%   13/05/2007 - RNU - creation
% ------------------------------------------------------------------------------
function init_valflag(varargin)

global g_typeLacher;
global g_typeSurfMes;
global g_typePresOffset;
global g_typeDiveStart;
global g_typeSurfPres2;

global g_typeDescentStart;
global g_typeDescentFirstStab;
global g_typeProfDesc;
global g_typeMaxPresToParkPres;
global g_typeAdjPark;

global g_typeDescentEnd;
global g_typeDriftMes;
global g_typeMinPresAtParkPres;
global g_typeMaxPresAtParkPres;
global g_typeParkMes;
global g_typeMeanParkMes;
global g_typeRefParkPres;
global g_typeMedianParkMes;

global g_typeToProfStart;
global g_typeMaxPresToProfPres;
global g_typeToProfEnd;
global g_typeJustBeforeAscent;

global g_typeAscentStartFloat;
global g_typeAscentStartProf;
global g_typeProfAsc;
global g_typeAsc100dbar;
global g_typeDownTimeEnd;

global g_typeAscentEndFloat;
global g_typeAscentEndProf;
global g_typeArgosStart;
global g_typeArgosStart2;

global g_typeArgosFirstMsg;
global g_typeArgosLoc;
global g_typeSurfMes2;
global g_typeArgosLastMsg
global g_typeArgosStop;

global g_typeArgosFitLoc;

global g_typeSpyDescToPark;
global g_typeSpyDescToProf;
global g_typeSpyAscToSurf;

global g_dateFlagDef;
global g_dateFlagMesSat;
global g_dateFlagMesFloat;
global g_dateFlagEstProg;
global g_dateFlagCorManu;
global g_dateFlagOpe;
global g_dateFlagModifProg;
global g_dateFlagAddNeedClockDriftCor;
global g_dateFlagAddClockDriftLaunchCor;
global g_dateFlagAddClockDriftCor;
global g_dateFlagAddDoubtfulDate;

global g_posDef;
global g_posLacher;
global g_posSat;
global g_posExtrapolated;
global g_posFitted;

global g_ptsFlagDef;
global g_ptsInterpolated;
global g_ptsAddModifManu;
global g_ptsAddModifProg;
global g_ptsAddOffsetCorrected;
global g_ptsAddOffsetUncorrectable;

global g_etatDef;
global g_etatFromNcProfTraj;
global g_etatFromNcTech;
global g_etatFromArgos;
global g_etatFromDec;
global g_etatFromTxt;
global g_etatAddModifProg;
global g_etatFromNcMeta;
global g_etatFromDep;
global g_etatAddModifManu;
global g_etatAddModifCycleNum;

global g_grdDef;
global g_grdUuFu;
global g_grdUuFy;
global g_grdUuFn;

global g_posQcDef;
global g_posQcKobaOk;
global g_posQcKobaKo;
global g_posQcDoubtful;

global g_rppQcDef;
global g_rppQcAvg;
global g_rppQcMean;
global g_rppQcMedian;
global g_rppQcPark;
global g_rppQcMinMax;
global g_rppQcMetaNoCy;
global g_rppQcMetaNoMeas;

global g_dataSetEndDate;

global g_nbProfInBounceCycle;
global g_bounceProfMaxLength;

g_typeLacher = 0;
g_typeSurfMes = 1;
g_typePresOffset = 2;
g_typeDiveStart = 3;
g_typeSurfPres2 = 4;

g_typeDescentStart = 6;
g_typeDescentFirstStab = 7;
g_typeProfDesc = 8;
g_typeMaxPresToParkPres = 9;
g_typeAdjPark = 10;

g_typeDescentEnd = 11;
g_typeDriftMes = 12;
g_typeMinPresAtParkPres = 13;
g_typeMaxPresAtParkPres = 14;
g_typeParkMes = 15;
g_typeMeanParkMes = 16;
g_typeMedianParkMes = 17;
g_typeRefParkPres = 20;

g_typeToProfStart = 21;
g_typeMaxPresToProfPres = 22;
g_typeToProfEnd = 23;
g_typeJustBeforeAscent = 24;

g_typeAscentStartFloat = 26;
g_typeAscentStartProf = 27;
g_typeProfAsc = 28;
g_typeAsc100dbar = 29;
g_typeDownTimeEnd = 30;

g_typeAscentEndFloat = 31;
g_typeAscentEndProf = 32;
g_typeArgosStart = 33;
g_typeArgosStart2 = 34;

g_typeArgosFirstMsg = 35;
g_typeArgosLoc = 36;
g_typeSurfMes2 = 37;
g_typeArgosLastMsg = 38;
g_typeArgosStop = 40;

g_typeArgosFitLoc = 46;

g_typeSpyDescToPark = 51;
g_typeSpyDescToProf = 52;
g_typeSpyAscToSurf = 53;

g_dateFlagDef = 99;
g_dateFlagMesSat = 1;
g_dateFlagMesFloat = 2;
g_dateFlagEstProg = 3;
g_dateFlagCorManu = 4;
g_dateFlagOpe = 5;
g_dateFlagModifProg = 6;
g_dateFlagAddNeedClockDriftCor = 10;
g_dateFlagAddClockDriftLaunchCor = 20;
g_dateFlagAddClockDriftCor = 40;
g_dateFlagAddDoubtfulDate = 80; %uniquement utilisée dans les DEP2

g_posDef = 99;
g_posLacher = 0;
g_posSat = 1;
g_posExtrapolated = 2;
g_posFitted = 3;

g_ptsFlagDef = 999;
g_ptsInterpolated = 8;
g_ptsAddModifManu = 10;
g_ptsAddModifProg = 20;
g_ptsAddOffsetCorrected = 40;
g_ptsAddOffsetUncorrectable = 80; % Truncated Negative Pressure Drift

g_etatDef = 99;
g_etatFromNcProfTraj = 1;
g_etatFromNcTech = 2;
g_etatFromArgos = 3;
g_etatFromDec = 4;
g_etatFromTxt = 5;
g_etatFromNcMeta = 6;
g_etatFromDep = 7;
g_etatAddModifManu = 10;
g_etatAddModifProg = 20;
g_etatAddModifCycleNum = 40;

g_grdDef = 99;
g_grdUuFu = 0;
g_grdUuFn = 1;
g_grdUuFy = 2;

% pour format DEP2
g_posQcDef = 9;
g_posQcKobaOk = 1;
g_posQcKobaKo = 0;
g_posQcDoubtful = 2;
g_rppQcDef = 9;
g_rppQcAvg = 1;
g_rppQcMean = 2;
g_rppQcMedian = 3;
g_rppQcPark = 4;
g_rppQcMinMax = 5;
g_rppQcMetaNoCy = 6;
g_rppQcMetaNoMeas = 7;

% date utilisée pour effectuer la limitation temporelle du jeu de données
g_dataSetEndDate = '2013/04/15 00:00:00'; % pour ANDRO 2013
% g_dataSetEndDate = '2013/11/15 00:00:00'; % pour misc andro 2013 (APEX IR)
% g_dataSetEndDate = '2009/01/01 00:00:00';
% g_dataSetEndDate = '2008/04/15 00:00:00';

% nombre de profils d'un cycle bounce
g_nbProfInBounceCycle = 7;
% taille maximale d'un profil bounce
g_bounceProfMaxLength = 100;

return;
