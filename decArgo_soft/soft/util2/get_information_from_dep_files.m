% ------------------------------------------------------------------------------
% Retrieve profile time and location information from DEP files.
%
% SYNTAX :
%   get_information_from_dep_files or get_information_from_dep_files(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function get_information_from_dep_files(varargin)

% top directory of input DEP files
DIR_INPUT_DEP_FILES = 'C:\Users\jprannou\_DATA\juste_dep\DEP_final_apres_update_2017\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = ''; % to process all floats of the DIR_INPUT_DEP_FILES directory
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_pts_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_bgc_all.txt';

% DEP file default values
global g_dateDef;

% measurement codes of DEP files
global g_typeAscentEndFloat;
global g_typeAscentEndProf;
global g_typeArgosStart;
global g_typeArgosStart2;

global g_typeArgosLoc;

% default values initialization
init_default_values;

% initialisation of DEP file default values
init_valdef;

% initialisation of DEP file measurement codes
init_valflag;


floatList = '';
if (nargin == 0)
   if (~isempty(FLOAT_LIST_FILE_NAME))
      % floats to process come from floatListFileName
      if ~(exist(FLOAT_LIST_FILE_NAME, 'file') == 2)
         fprintf('File not found: %s\n', FLOAT_LIST_FILE_NAME);
         return
      end
      
      fprintf('Floats from list: %s\n', FLOAT_LIST_FILE_NAME);
      floatList = load(FLOAT_LIST_FILE_NAME);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/' 'get_information_from_dep_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'get_information_from_dep_files_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO;CYCLE;DIR;JULD (NUM);JULD_LOCATION (NUM);LATITUDE;LONGITUDE;JULD (GREG);JULD_LOCATION (GREG)';
fprintf(fidOut, '%s\n', header);

% process all floats of the DIR_INPUT_DEP_FILES directory
if (isempty(floatList))
   floatDirs = dir(DIR_INPUT_DEP_FILES);
   floatList = {floatDirs.name};
   floatList = setdiff(floatList, [{'.'}, {'..'}]);
   floatList = str2double(floatList)';
end

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);

   % read DEP file
   depFilePathName = [DIR_INPUT_DEP_FILES '/' floatNumStr '/' floatNumStr '_data_dep.txt'];
   if (~exist(depFilePathName, 'dir') && exist(depFilePathName, 'file'))
      [depNumWmo, depCycle, depType, ...
         depDate, depDateFlag, depDateGregDay, depDateGregHour, depOrdre, ...
         depLon, depLat, depPosFlag, depPosQc, depSatName, ...
         depPres, depPresFlag, ...
         depTemp, depTempFlag, ...
         depSal, depSalFlag, ...
         depGrd, depEtat, depUpdate, depProfNum] = read_file_dep(depFilePathName);
      
      cycleList = unique(depCycle);
      for idCy = 1:length(cycleList)
         cyNum = cycleList(idCy);
         idForCy = find(depCycle == cyNum);
         
         profJuld = '';
         if (any(depType(idForCy) == g_typeAscentEndFloat))
            idF = find(depType(idForCy) == g_typeAscentEndFloat);
            if (depDate(idForCy(idF)) ~= g_dateDef)
               profJuld = depDate(idForCy(idF));
            end
         end
         if (isempty(profJuld))
            if (any(depType(idForCy) == g_typeAscentEndProf))
               idF = find(depType(idForCy) == g_typeAscentEndProf);
               if (depDate(idForCy(idF)) ~= g_dateDef)
                  profJuld = depDate(idForCy(idF));
               end
            end
         end
         if (isempty(profJuld))
            if (any(depType(idForCy) == g_typeArgosStart))
               idF = find(depType(idForCy) == g_typeArgosStart);
               if (depDate(idForCy(idF)) ~= g_dateDef)
                  profJuld = depDate(idForCy(idF));
               end
            end
         end
         if (isempty(profJuld))
            if (any(depType(idForCy) == g_typeArgosStart2))
               idF = find(depType(idForCy) == g_typeArgosStart2);
               if (depDate(idForCy(idF)) ~= g_dateDef)
                  profJuld = depDate(idForCy(idF));
               end
            end
         end
         if (isempty(profJuld))
            if (any(depType(idForCy) == g_typeArgosLoc))
               idF = find(depType(idForCy) == g_typeArgosLoc);
               profJuld = min(depDate(idForCy(idF)));
            end
         end
         
         profJuldLoc = '';
         profLat = '';
         profLon = '';
         if (any(depType(idForCy) == g_typeArgosLoc))
            idF = find(depType(idForCy) == g_typeArgosLoc);
            [~, idMin] = min(depDate(idForCy(idF)));
            profJuldLoc = depDate(idForCy(idF(idMin)));
            profLat = depLat(idForCy(idF(idMin)));
            profLon = depLon(idForCy(idF(idMin)));
         end
         
         if (~isempty(profJuld) && ~isempty(profJuldLoc))
            fprintf(fidOut, '%d;%d;%d;%.8f;%.8f;%.3f;%.3f;%s;%s\n', ...
               floatNum, cyNum, 1, ...
               profJuld, profJuldLoc, profLat, profLon, ...
               julian_2_gregorian_dec_argo(profJuld), ...
               julian_2_gregorian_dec_argo(profJuldLoc));
         end
      end
   else
      fprintf('WARNING: DEP file not found: %s\n', depFilePathName);
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

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

return

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
global g_clockOffsetDef;
global g_interpClockOffsetDef;
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
g_clockOffsetDef = -9999999999;
g_interpClockOffsetDef = -1;

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

return

% ------------------------------------------------------------------------------
% Lecture du contenu d'un fichier DEP.
%
% SYNTAX :
%  [o_depCycle, o_depType, o_depDate, o_depDateFlag, o_depOrdre, ...
%    o_depLon, o_depLat, o_depPosFlag, o_depPosQc, o_depSatName, ...
%    o_depPres, o_depPresFlag, ...
%    o_depTemp, o_depTempFlag, ...
%    o_depSal, o_depSalFlag, ...
%    o_depGrd, o_depEtat, o_depUpdate, o_depProfNum] = read_file_dep(a_depFileName)
%
% INPUT PARAMETERS :
%   a_depFileName : nom du fichier DEP
%
% OUTPUT PARAMETERS :
%   données de chaque colonne
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2012 - RNU - creation
% ------------------------------------------------------------------------------
function [o_depNumWmo, o_depCycle, o_depType, ...
   o_depDate, o_depDateFlag, o_depDateGregDay, o_depDateGregHour, o_depOrdre, ...
   o_depLon, o_depLat, o_depPosFlag, o_depPosQc, o_depSatName, ...
   o_depPres, o_depPresFlag, ...
   o_depTemp, o_depTempFlag, ...
   o_depSal, o_depSalFlag, ...
   o_depGrd, o_depEtat, o_depUpdate, o_depProfNum] = read_file_dep(a_depFileName)

o_depNumWmo = [];
o_depCycle = [];
o_depType = [];
o_depDate = [];
o_depDateFlag = [];
o_depDateGregDay = [];
o_depDateGregHour = [];
o_depOrdre = [];
o_depLon = [];
o_depLat = [];
o_depPosFlag = [];
o_depPosQc = [];
o_depSatName = [];
o_depPres = [];
o_depPresFlag = [];
o_depTemp = [];
o_depTempFlag = [];
o_depSal = [];
o_depSalFlag = [];
o_depGrd = [];
o_depEtat = [];
o_depUpdate = [];
o_depProfNum = [];

% ouverture du fichier DEP
fId = fopen(a_depFileName, 'r');
if (fId == -1)
   fprintf('Erreur ouverture fichier : %s\n', a_depFileName);
   return;
end

% lecture et stockage des données du fichier DEP
dataDep = textscan(fId, '%u %d %u %f %u %s %s %u %f %f %u %c %c %f %u %f %u %f %u %u %u %s %d');

o_depNumWmo = dataDep{1}(:);
o_depCycle = dataDep{2}(:);
o_depType = dataDep{3}(:);
o_depDate = dataDep{4}(:);
o_depDateFlag = dataDep{5}(:);
o_depDateGregDay = dataDep{6}(:);
o_depDateGregHour = dataDep{7}(:);
o_depOrdre = dataDep{8}(:);
o_depLon = dataDep{9}(:);
o_depLat = dataDep{10}(:);
o_depPosFlag = dataDep{11}(:);
o_depPosQc = dataDep{12}(:);
o_depSatName = dataDep{13}(:);
o_depPres = dataDep{14}(:);
o_depPresFlag = dataDep{15}(:);
o_depTemp = dataDep{16}(:);
o_depTempFlag = dataDep{17}(:);
o_depSal = dataDep{18}(:);
o_depSalFlag = dataDep{19}(:);
o_depGrd = dataDep{20}(:);
o_depEtat = dataDep{21}(:);
o_depUpdate = dataDep{22}(:);
o_depProfNum = dataDep{23}(:);
   
fclose(fId);

return
