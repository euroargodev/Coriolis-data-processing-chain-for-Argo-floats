% ------------------------------------------------------------------------------
% Link 2 sets of data, a NetCDF files one and a DEP files one.
% The link is performed whit the comparison of profiles measurements
% (MATCH_PERCENT value is used to declare 2 profiles as identicals).
%
% SYNTAX :
%   create_link_from_nc_to_dep or create_link_from_nc_to_dep(6900189, 7900118)
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
function create_link_from_nc_to_dep(varargin)

% top directory of input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\IN\';

% top directory of input DEP files
DIR_INPUT_DEP_FILES = 'C:\Users\jprannou\_DATA\juste_dep\DEP_final_apres_update_2017\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_pts_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_bgc_all.txt';

% if one want to check profile that can be recovered from DEP files
DEP_2_NC_FLAG = 1;

% min percentage of identical measurements used to link profiles of both
% sets
MATCH_PERCENT = 40;

% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = load(floatListFileName);
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_CSV_FILE '/' 'create_link_from_nc_to_dep' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'create_link_from_nc_to_dep'  name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO;CYNUM NC;CYNUM DEP;% MATCH;N_LEVELS;CYNUM ERR;CYNUM DUPLICATED';
fprintf(fidOut, '%s\n', header);

if (DEP_2_NC_FLAG)
   % create the CSV output file
   outputFileName = [DIR_LOG_CSV_FILE '/' 'create_link_from_nc_to_dep_DEP_TO_NC'  name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
   fidOut2 = fopen(outputFileName, 'wt');
   if (fidOut2 == -1)
      return
   end
   header = 'WMO;CYNUM DEP;N_LEVELS;NB CYNUM NC;CY EXISTS;NC CYNUM LIST';
   fprintf(fidOut2, '%s\n', header);
end

% process the floats
cycleCorNumAll = [];
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   % retrieve profile measurements from both sets
   [ncProfCyNum, ncProfDir, ncProfLen, ncProfTimes, ncProfMeas] = ...
      get_nc_profile_data(DIR_INPUT_NC_FILES, floatNum);
   
   [depProfCyNum, depProfDir, depProfTimes, depProfMeas] = ...
      get_dep_profile_data(DIR_INPUT_DEP_FILES, floatNum);
   
   % link nc data set to DEP one
   if (~isempty(depProfCyNum))
      
      % try to associate a DEP cycle to each nc one
      nc2depCyNum = ones(length(ncProfCyNum), 1)*-1;
      depCyNumUsed = zeros(length(depProfCyNum), 1);
      nc2depMatch = zeros(length(ncProfCyNum), 1);
      for idProf = 1:length(ncProfCyNum)
         idF = find((depProfCyNum == ncProfCyNum(idProf)) & ...
            (depProfDir == ncProfDir(idProf)), 1);
         if (~isempty(idF))
            dataNc = (strsplit(ncProfMeas{idProf}, '@'))';
            dataDep = (strsplit(depProfMeas{idF}, '@'))';
            match = ismember(dataNc, dataDep);
            match = (sum(match)/length(match))*100;
            nc2depMatch(idProf) = match;
            
            if (match > MATCH_PERCENT)
               nc2depCyNum(idProf) = depProfCyNum(idF);
               depCyNumUsed(idF) = 1;
               %             else
               %                fprintf('Cycle #%d: %.2f\n', ncProfCyNum(idProf), match);
            end
         end
      end
      if (any(nc2depCyNum == -1) && any(depCyNumUsed == 0))
         idNcRemain = find(nc2depCyNum == -1);
         idDepUnused = find(depCyNumUsed == 0);
         for idProfNc = idNcRemain'
            dataNc = (strsplit(ncProfMeas{idProfNc}, '@'))';
            for idProfDep = idDepUnused'
               dataDep = (strsplit(depProfMeas{idProfDep}, '@'))';
               match = ismember(dataNc, dataDep);
               match = (sum(match)/length(match))*100;
               nc2depMatch(idProfNc) = max(nc2depMatch(idProfNc), match);
               
               if (match > MATCH_PERCENT)
                  nc2depCyNum(idProfNc) = depProfCyNum(idProfDep);
                  depCyNumUsed(idProfDep) = 1;
                  idDepUnused = find(depCyNumUsed == 0);
                  nc2depMatch(idProfNc) = match;
                  break
               end
            end
         end
      end
      
      cycleCorNum = [repmat(floatNum, length(ncProfCyNum), 1), ...
         ncProfCyNum nc2depCyNum floor(nc2depMatch) ncProfLen ones(length(ncProfCyNum), 2)*-1];
      idF = find((cycleCorNum(:, 3) ~= -1) & (cycleCorNum(:, 2)-cycleCorNum(:, 3) ~= 0));
      for idProf = idF'
         fprintf('Float #%d Cycle #%d: erroneous cycle number (should be #%d)\n', ...
            cycleCorNum(idProf, 1:3));
         cycleCorNum(idProf, 6) = 1;
      end
      idRemain = find(cycleCorNum(:, 3) == -1);
      for idProfNc = idRemain'
         dataNc = (strsplit(ncProfMeas{idProfNc}, '@'))';
         for idProfDep = 1:length(depProfCyNum)
            dataDep = (strsplit(depProfMeas{idProfDep}, '@'))';
            match = ismember(dataNc, dataDep);
            match = (sum(match)/length(match))*100;
            if (match > MATCH_PERCENT)
               idF = find(cycleCorNum(:, 3) == depProfCyNum(idProfDep));
               fprintf('Float #%d Cycle #%d: profile duplicated from cycle #%d\n', ...
                  cycleCorNum(idProfNc, 1:2), cycleCorNum(idF, 2));
               cycleCorNum(idProfNc, 7) = cycleCorNum(idF, 2);
            end
         end
      end
      
      cycleCorNumAll = [cycleCorNumAll; cycleCorNum];
   end
   
   if (DEP_2_NC_FLAG)
      
      % link DEP data set to nc one
      if (~isempty(depProfCyNum))
         
         % create 2 sets of measurements
         tabDataDep = cell(size(depProfCyNum));
         for idProf = 1:length(depProfCyNum)
            tabDataDep{idProf} = (strsplit(depProfMeas{idProf}, '@'))';
         end
         tabDataNc = cell(size(ncProfCyNum));
         for idProf = 1:length(ncProfCyNum)
            tabDataNc{idProf} = (strsplit(ncProfMeas{idProf}, '@'))';
         end
         
         % for each DEP cycle, look for associated nc cycle (using profile
         % measurements)
         tabNc2Dep = cell(size(depProfCyNum));
         for idDepProf = 1:length(depProfCyNum)
            dataDep = tabDataDep{idDepProf};
            ncCyList = [];
            for idNcProf = 1:length(ncProfCyNum)
               dataNc = tabDataNc{idNcProf};
               match = ismember(dataDep, dataNc);
               match = (sum(match)/length(match))*100;
               if (match > MATCH_PERCENT)
                  ncCyList = [ncCyList ncProfCyNum(idNcProf)];
               end
            end
            tabNc2Dep{idDepProf} = ncCyList;
         end
         
         % for each DEP cycle not associated with one nc cycle, check if on
         % nc file exists
         tabNcFile = ones(size(depProfCyNum))*-1;
         for idProf = 1:length(tabNc2Dep)
            if (isempty(tabNc2Dep{idProf}))
               file = dir([DIR_INPUT_NC_FILES sprintf('/%d/profiles/*%d_%03d.nc', floatNum, floatNum, depProfCyNum(idProf))]);
               if (isempty(file))
                  tabNcFile(idProf) = 0;
               else
                  tabNcFile(idProf) = 1;
               end
            else
               tabNcFile(idProf) = 1;
            end
         end         
         
         
         for idProf = 1:length(tabNc2Dep)
            cyListStr = '';
            cyList = tabNc2Dep{idProf};
            if (~isempty(cyList))
               cyListStr = sprintf('%d;', cyList);
            end
            fprintf(fidOut2, '%d;%d;%d;%d;%d;%s\n', ...
               floatNum, ...
               depProfCyNum(idProf), ...
               length(tabDataDep{idProf}), ...
               length(cyList), ...
               tabNcFile(idProf), ...
               cyListStr(1:end-1));
         end
      end
   end
end

fprintf(fidOut, '%d;%d;%d;%d;%d;%d;%d\n', cycleCorNumAll');

fclose(fidOut);

if (DEP_2_NC_FLAG)
   fclose(fidOut2);
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve information from NetCDF profile files of a float.
%
% SYNTAX :
%  [o_ncProfCyNum, o_ncProfDir, o_ncProfLen, o_ncProfTimes, o_ncProfMeas] = ...
%    get_nc_profile_data(a_inputDirName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_inputDirName : directory of mono-profile files
%   a_floatNum     : float WMO number
%
% OUTPUT PARAMETERS :
%   o_ncProfCyNum : profile cycle numbers
%   o_ncProfDir   : profile directions
%   o_ncProfLen   : profile length
%   o_ncProfTimes : profile times and locations
%   o_ncProfMeas  : profile measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncProfCyNum, o_ncProfDir, o_ncProfLen, o_ncProfTimes, o_ncProfMeas] = ...
   get_nc_profile_data(a_inputDirName, a_floatNum)

% output parameters initialization
o_ncProfCyNum = [];
o_ncProfDir = [];
o_ncProfLen = [];
o_ncProfTimes = [];
o_ncProfMeas = [];


% get data from mono-profile files
monoProfDirName = [a_inputDirName sprintf('/%d/profiles/', a_floatNum)];
monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', a_floatNum)];
monoProfFiles = dir(monoProfFileName);
for idFile = 1:length(monoProfFiles)
   
   fileName = monoProfFiles(idFile).name;
   % do not consider b file (if exists)
   if (fileName(1) == 'B')
      continue
   end
   profFileName = [monoProfDirName fileName];
   
   if (exist(profFileName, 'file') == 2)
      
      % retrieve information from Input file
      wantedInputVars = [ ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'JULD'} ...
         {'JULD_LOCATION'} ...
         {'LATITUDE'} ...
         {'LONGITUDE'} ...
         {'PRES'} ...
         {'TEMP'} ...
         {'PSAL'} ...
         ];
      [inputData] = get_data_from_nc_file(profFileName, wantedInputVars);
      
      idVal = find(strcmp('CYCLE_NUMBER', inputData(1:2:end)) == 1, 1);
      cycleNumber = inputData{2*idVal};
      idVal = find(strcmp('DIRECTION', inputData(1:2:end)) == 1, 1);
      direction = inputData{2*idVal};
      idVal = find(strcmp('JULD', inputData(1:2:end)) == 1, 1);
      juld = inputData{2*idVal};
      idVal = find(strcmp('JULD_LOCATION', inputData(1:2:end)) == 1, 1);
      juldLocation = inputData{2*idVal};
      idVal = find(strcmp('LATITUDE', inputData(1:2:end)) == 1, 1);
      latitude = inputData{2*idVal};
      idVal = find(strcmp('LONGITUDE', inputData(1:2:end)) == 1, 1);
      longitude = inputData{2*idVal};
      idVal = find(strcmp('PRES', inputData(1:2:end)) == 1, 1);
      pres = inputData{2*idVal};
      idVal = find(strcmp('TEMP', inputData(1:2:end)) == 1, 1);
      temp = inputData{2*idVal};
      idVal = find(strcmp('PSAL', inputData(1:2:end)) == 1, 1);
      psal = inputData{2*idVal};
      
      if (length(cycleNumber) > 1)
         cycleNumber = cycleNumber(1);
         direction = direction(1);
         juld = juld(1);
         juldLocation = juldLocation(1);
         latitude = latitude(1);
         longitude = longitude(1);
         pres = pres(:, 1);
         temp = temp(:, 1);
         psal = psal(:, 1);
      end
      
      o_ncProfCyNum = [o_ncProfCyNum; cycleNumber];
      o_ncProfDir = [o_ncProfDir; direction];
      o_ncProfLen = [o_ncProfLen; size(pres, 1)];
      o_ncProfTimes = [o_ncProfTimes; [juld juldLocation latitude longitude]];
      measData = sprintf('%.1f %.3f %.3f@', [pres, temp, psal]');
      o_ncProfMeas{end+1} = measData(1:end-1);
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve information from DEP profile file of a float.
%
% SYNTAX :
%  [o_depProfCyNum, o_depProfDir, o_depProfTimes, o_depProfMeas] = ...
%    get_dep_profile_data(a_inputDirName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_inputDirName : directory of DEP file
%   a_floatNum     : float WMO number
%
% OUTPUT PARAMETERS :
%   o_depProfCyNum : profile cycle numbers
%   o_depProfDir   : profile directions
%   o_depProfTimes : profile times and locations
%   o_depProfMeas  : profile measurements
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_depProfCyNum, o_depProfDir, o_depProfTimes, o_depProfMeas] = ...
   get_dep_profile_data(a_inputDirName, a_floatNum)

% output parameters initialization
o_depProfCyNum = [];
o_depProfDir = [];
o_depProfTimes = [];
o_depProfMeas = [];

% DEP file default values
global g_dateDef;

% measurement codes of DEP files
global g_typeProfAsc;

global g_typeAscentEndFloat;
global g_typeAscentEndProf;
global g_typeArgosStart;
global g_typeArgosStart2;

global g_typeArgosLoc;

% initialisation of DEP file default values
init_valdef;

% initialisation of DEP file measurement codes
init_valflag;


% read DEP file
depFilePathName = [a_inputDirName sprintf('/%d/%d_data_dep.txt', a_floatNum, a_floatNum)];
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
      
      ascPres = [];
      ascTemp = [];
      ascPsal = [];
      if (any(depType(idForCy) == g_typeProfAsc))
         idF = find(depType(idForCy) == g_typeProfAsc);
         ascPres = depPres(idForCy(idF));
         ascTemp = depTemp(idForCy(idF));
         ascPsal = depSal(idForCy(idF));
         ascPres = flipud(ascPres);
         ascTemp = flipud(ascTemp);
         ascPsal = flipud(ascPsal);
      end
      
      if (~isempty(profJuld) && ~isempty(profJuldLoc))
         if (~isempty(ascPres))
            o_depProfCyNum = [o_depProfCyNum; cyNum];
            o_depProfDir = [o_depProfDir; 'A'];
            o_depProfTimes = [o_depProfTimes; [profJuld profJuldLoc profLat profLon]];
            measData = sprintf('%.1f %.3f %.3f@', [ascPres, ascTemp, ascPsal]');
            o_depProfMeas{end+1} = measData(1:end-1);
         end
      end
   end
else
   fprintf('WARNING: DEP file not found: %s\n', depFilePathName);
end

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

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
