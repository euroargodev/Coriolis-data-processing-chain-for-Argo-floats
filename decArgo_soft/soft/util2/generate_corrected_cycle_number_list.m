% ------------------------------------------------------------------------------
% For each cycle number of a DEP file, find the corresponding cycle number from
% nc mono-profile files.
%
% SYNTAX :
%   generate_corrected_cycle_number_list or 
%   generate_corrected_cycle_number_list(6900189, 7900118)
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
%   10/02/2015 - RNU - creation
% ------------------------------------------------------------------------------
function generate_corrected_cycle_number_list(varargin)

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all_argos.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertNkeOldVersionsTo3.1\list\nke_old_all_iridium.txt';

% top directory of input DEP files
DIR_INPUT_DEP_FILES = 'C:\Users\jprannou\_RNU\Andro\data\juste_dep_20140218\';

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\IN\NC_CONVERTION_TO_3.1\NC_files_nke_old_versions_to_convert_to_3.1_fromArchive201510\';

% directory to store the log and csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

global g_dateDef;
global g_latDef;
global g_lonDef;
global g_profNumDef;

g_dateDef = 99999.99999999;
g_latDef = -99.999;
g_lonDef = -999.999;
g_profNumDef = -1;

global g_typeArgosLoc;
global g_typeProfAsc;

g_typeProfAsc = 28;
g_typeArgosLoc = 36;

% shift between JulD and Matlab dates
SHIFT_DATE = 712224;

% time interval to look for profile dates
INTERVAL_HOUR = 10;
INTERVAL_DAY = INTERVAL_HOUR/24;


if (nargin == 0)
   floatListFileName = FLOAT_LIST_FILE_NAME;
   
   % floats to process come from floatListFileName
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return;
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

logFile = [DIR_LOG_CSV_FILE '/' 'generate_corrected_cycle_number_list' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'generate_corrected_cycle_number_list' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return;
end
header = 'WMO; DEP cycle; NC cycle; Diff';
fprintf(fidOut, '%s\n', header);

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
     
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
   
   % recherche d'un fichier DEP pour ce flotteur
   % find a DEP file for this float
   depFileName = [DIR_INPUT_DEP_FILES '/' floatNumStr '/' floatNumStr '_data_dep.txt'];
   if ~(exist(depFileName, 'file') == 2)
      fprintf('WARNING: no DEP file for this float!\n');
      continue;
   end
      
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve DEP file data
   
   % read DEP file
   [depNumWmo, depCycle, depType, ...
      depDate, depDateFlag, depDateGregDay, depDateGregHour, depOrdre, ...
      depLon, depLat, depPosFlag, depPosQc, depSatName, ...
      depPres, depPresFlag, ...
      depTemp, depTempFlag, ...
      depSal, depSalFlag, ...
      depGrd, depEtat, depUpdate, depProfNum] = read_file_dep(depFileName);
   
   % retrieve DEP file profiles
   
   % DEP file cycles
   cycles = sort(unique(depCycle));
   cycles = cycles(find(cycles >= 0));
   maxDepNumCy = max(cycles);
   
   % arrays to store the data
   tabLocDate = ones(maxDepNumCy+1, 1)*g_dateDef;
   tabLocLon = ones(maxDepNumCy+1, 1)*g_lonDef;
   tabLocLat = ones(maxDepNumCy+1, 1)*g_latDef;
   tabProfNum = ones(maxDepNumCy+1, 1)*-2;
   
   % process DEP data
   for idCy = 1:length(cycles)
      numCycle = cycles(idCy);
      
      idCycle = find(depCycle == numCycle);
      
      % Argos locations
      idCycleArgosLoc = find(depType(idCycle) == g_typeArgosLoc);
      if (~isempty(idCycleArgosLoc))
         tabLocDate(numCycle+1) = depDate(idCycle(idCycleArgosLoc(1)));
         tabLocLon(numCycle+1) = depLon(idCycle(idCycleArgosLoc(1)));
         tabLocLat(numCycle+1) = depLat(idCycle(idCycleArgosLoc(1)));
      end
      
      % ascending profile
      idCycleProfAsc = find(depType(idCycle) == g_typeProfAsc);
      if (~isempty(idCycleProfAsc))
         tabProfNum(numCycle+1) = unique(depProfNum(idCycle(idCycleProfAsc)));
      end
   end
      
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve data from NC mono profile files
   
   [monoDescProfNum, monoDescProfDate, monoDescProfLocDate, ...
      monoAscProfNum, monoAscProfDate, monoAscProfLocDate, ...
      multiDescProfNum, multiDescProfDate, multiDescProfLocDate, ...
      multiAscProfNum, multiAscProfDate, multiAscProfLocDate] = get_profil_info(DIR_INPUT_NC_FILES, floatNum);
   maxProfNumCy = max([monoAscProfNum; multiAscProfNum]);
      
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % profile identification
   
   idDated = find(tabLocDate ~= g_dateDef);
   if (~isempty(idDated))
      tabLocDate(idDated) = datenum(datestr(tabLocDate(idDated)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   idDated = find(monoAscProfDate ~= g_dateDef);
   if (~isempty(idDated))
      monoAscProfDate(idDated) = datenum(datestr(monoAscProfDate(idDated)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   idDated = find(monoAscProfLocDate ~= g_dateDef);
   if (~isempty(idDated))
      monoAscProfLocDate(idDated) = datenum(datestr(monoAscProfLocDate(idDated)+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   
   % cycle mapping
   maxNumCy = max([maxDepNumCy maxProfNumCy]);
   dep2NcId = ones(maxNumCy+1, 1)*999;
   % if J   => prof in NC at cycle J+1
   % if 999 => no prof in DEP no prof NC
   % if 0   => prof in DEP not found in NC
   depProfNum(:) = g_profNumDef;
   for idCy = 1:maxDepNumCy+1
      if (tabLocDate(idCy) ~= g_dateDef)
         idNcMonoProfDate = find(abs(monoAscProfDate - tabLocDate(idCy)) <= INTERVAL_DAY);
         
         if (~isempty(idNcMonoProfDate))
            if (length(idNcMonoProfDate) == 1)
               dep2NcId(idCy) = monoAscProfNum(idNcMonoProfDate)+1;
            else
               [~, idMin] = min(abs(monoAscProfDate(idNcMonoProfDate) - tabLocDate(idCy)));
               dep2NcId(idCy) = monoAscProfNum(idNcMonoProfDate(idMin(1)))+1;
               
               fprintf('WARNING: float %d: %d profiles found in NC around loc date %s (the #%d is selected)\n', ...
                  floatNum, length(idNcMonoProfDate), julian_2_gregorian_dec_argo(tabLocDate(idCy)), idMin(1));
               
               for id = 1:length(idNcMonoProfDate)
                  fprintf('INFO: float %d: mono-profile #%d : nc cycle number #%d date %s\n', ...
                     floatNum, id, monoAscProfNum(idNcMonoProfDate(id)), ...
                     julian_2_gregorian_dec_argo(monoAscProfDate(idNcMonoProfDate(id))));
               end
            end
         else
            idNcMonoProfLocDate = find(abs(monoAscProfLocDate - tabLocDate(idCy)) <= INTERVAL_DAY);
            
            if (~isempty(idNcMonoProfLocDate))
               if (length(idNcMonoProfLocDate) == 1)
                  dep2NcId(idCy) = monoAscProfNum(idNcMonoProfLocDate)+1;
               else
                  [~, idMin] = min(abs(monoAscProfLocDate(idNcMonoProfLocDate) - tabLocDate(idCy)));
                  dep2NcId(idCy) = monoAscProfNum(idNcMonoProfLocDate(idMin(1)))+1;
                  
                  fprintf('WARNING: float %d: %d profiles found in NC around loc date %s (the #%d is selected)\n', ...
                     floatNum, length(idNcMonoProfLocDate), julian_2_gregorian_dec_argo(tabLocDate(idCy)), idMin(1));
                  
                  for id = 1:length(idNcMonoProfLocDate)
                     fprintf('INFO: float %d: mono-profile #%d : nc cycle number #%d date %s\n', ...
                        floatNum, id, monoAscProfNum(idNcMonoProfLocDate(id)), ...
                        julian_2_gregorian_dec_argo(monoAscProfLocDate(idNcMonoProfLocDate(id))));
                  end
               end
            else
               idNcMultiProfDate = find(abs(multiAscProfDate - tabLocDate(idCy)) <= INTERVAL_DAY);
               
               if (~isempty(idNcMultiProfDate))
                  if (length(idNcMultiProfDate) == 1)
                     dep2NcId(idCy) = multiAscProfNum(idNcMultiProfDate)+1;
                  else
                     [~, idMin] = min(abs(multiAscProfDate(idNcMultiProfDate) - tabLocDate(idCy)));
                     dep2NcId(idCy) = multiAscProfNum(idNcMultiProfDate(idMin(1)))+1;
                     
                     fprintf('WARNING: float %d: %d profiles found in NC around loc date %s (the #%d is selected)\n', ...
                        floatNum, length(idNcMultiProfDate), julian_2_gregorian_dec_argo(tabLocDate(idCy)), idMin(1));
                     
                     for id = 1:length(idNcMultiProfDate)
                        fprintf('INFO: float %d: multi-profile #%d : nc cycle number #%d date %s\n', ...
                           floatNum, id, multiAscProfNum(idNcMultiProfDate(id)), ...
                           julian_2_gregorian_dec_argo(multiAscProfDate(idNcMultiProfDate(id))));
                     end
                  end
               else
                  idNcMultiProfLocDate = find(abs(multiAscProfLocDate - tabLocDate(idCy)) <= INTERVAL_DAY);
                  
                  if (~isempty(idNcMultiProfLocDate))
                     if (length(idNcMultiProfLocDate) == 1)
                        dep2NcId(idCy) = multiAscProfNum(idNcMultiProfLocDate)+1;
                     else
                        [~, idMin] = min(abs(multiAscProfLocDate(idNcMultiProfLocDate) - tabLocDate(idCy)));
                        dep2NcId(idCy) = multiAscProfNum(idNcMultiProfLocDate(idMin(1)))+1;
                        
                        fprintf('WARNING: float %d: %d profiles found in NC around loc date %s (the #%d is selected)\n', ...
                           floatNum, length(idNcMultiProfLocDate), julian_2_gregorian_dec_argo(tabLocDate(idCy)), idMin(1));
                        
                        for id = 1:length(idNcMultiProfLocDate)
                           fprintf('INFO: float %d: multi-profile #%d : nc cycle number #%d date %s\n', ...
                              floatNum, id, multiAscProfNum(idNcMultiProfLocDate(id)), ...
                              julian_2_gregorian_dec_argo(multiAscProfLocDate(idNcMultiProfLocDate(id))));
                        end
                     end
                  else
                     dep2NcId(idCy) = 0;
                     
                     fprintf('INFO: float %d cycle #%d: no profile found (DEP (date lon lat) => (%s %8.3f %7.3f))\n', ...
                        floatNum, idCy-1, ...
                        julian_2_gregorian_dec_argo(tabLocDate(idCy)), tabLocLon(idCy), tabLocLat(idCy));
                  end
               end
            end
         end
         
         % contrôle de la valeur mise jusqu'à présent (utilisé pour
         % production DEP2 post AOML 2009)
         % contenu de dep2NcId
         % si J   => prof dans NC au cycle J+1
         % si 999 => pas de prof dans DEP et pas dans NC
         % si 0   => prof dans DEP pas trouvé dans NC
         %             if (dep2NcId(idCy) ~= 999)
         %                if (dep2NcId(idCy) == 0)
         %                   if (tabProfNum(idCy) ~= -2)
         %                      if (tabProfNum(idCy) ~= -1)
         %                         fprintf('ATTENTION: cycle #%d: tabProfNum=%d et dep2NcId=%d\n', ...
         %                            idCy-1, tabProfNum(idCy), dep2NcId(idCy));
         %                      end
         %                   end
         %                else
         %                   if (tabProfNum(idCy) ~= -2)
         %                      if (tabProfNum(idCy) ~= dep2NcId(idCy)-1)
         %                         fprintf('ATTENTION: cycle #%d: ttabProfNum=%d et dep2NcId=%d\n', ...
         %                            idCy-1, tabProfNum(idCy), dep2NcId(idCy));
         %                      end
         %                   end
         %                end
         %             end
         
         %          if (dep2NcId(idCy) ~= 0)
         %             idCycle = find(depCycle == idCy-1);
         %             depProfNum(idCycle) = dep2NcId(idCy)-1;
         %          end
         if (dep2NcId(idCy) ~= 999)
            depCy = idCy-1;
            ncCy = dep2NcId(idCy)-1;
            fprintf(fidOut, '%d;%d;%d;%d\n', floatNum, depCy, ncCy, depCy-ncCy);
         end
      end
   end
end

fclose(fidOut);

diary off;

return;

% ------------------------------------------------------------------------------
% Collecte des informations de profils (numéro de cycle et date) dans les
% fichiers NetCDF mono et multi-profils.
%
% SYNTAX :
%  [o_monoDescProfNum, o_monoDescProfDate, o_monoDescProfLocDate, ...
%    o_monoAscProfNum, o_monoAscProfDate, o_monoAscProfLocDate, ...
%    o_multiDescProfNum, o_multiDescProfDate, o_multiDescProfLocDate, ...
%    o_multiAscProfNum, o_multiAscProfDate, o_multiAscProfLocDate ...
%    ] = get_profil_info(a_ncDirName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_ncDirName : répertoire des fichiers profils
%   a_floatNum  : numéro du flotteur
%
% OUTPUT PARAMETERS :
%   o_monoDescProfNum      : numéros des profls descendants dans les fichiers
%                            mono-profil
%   o_monoDescProfDate     : date des profls descendants dans les fichiers
%                            mono-profil
%   o_monoDescProfLocDate  : dates des localisations des profls descendants dans
%                            les fichiers mono-profil
%   o_monoAscProfNum       : numéros des profls ascendants dans les fichiers
%                            mono-profil
%   o_monoAscProfDate      : date des profls ascendants dans les fichiers
%                            mono-profil
%   o_monoAscProfLocDate   : dates des localisations des profls ascendants dans
%                            les fichiers mono-profil
%   o_multiDescProfNum     : numéros des profls descendants dans le fichier
%                            multi-profil
%   o_multiDescProfDate    : date des profls descendants dans le fichier
%                            multi-profil
%   o_multiDescProfLocDate : dates des localisations des profls descendants dans
%                            le fichier multi-profil
%   o_multiAscProfNum      : numéros des profls ascendants dans le fichier
%                            multi-profil
%   o_multiAscProfDate     : date des profls ascendants dans le fichier
%                            multi-profil
%   o_multiAscProfLocDate  : dates des localisations des profls ascendants dans
%                            le fichier multi-profil
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   18/03/2012 - RNU - creation
% ------------------------------------------------------------------------------
function [o_monoDescProfNum, o_monoDescProfDate, o_monoDescProfLocDate, ...
   o_monoAscProfNum, o_monoAscProfDate, o_monoAscProfLocDate, ...
   o_multiDescProfNum, o_multiDescProfDate, o_multiDescProfLocDate, ...
   o_multiAscProfNum, o_multiAscProfDate, o_multiAscProfLocDate ...
   ] = get_profil_info(a_ncDirName, a_floatNum)

global g_dateDef;

% initialisation des valeurs par défaut
init_valdef;

o_monoDescProfNum = [];
o_monoDescProfDate = [];
o_monoDescProfLocDate = [];

o_monoAscProfNum = [];
o_monoAscProfDate = [];
o_monoAscProfLocDate = [];

o_multiDescProfNum = [];
o_multiDescProfDate = [];
o_multiDescProfLocDate = [];

o_multiAscProfNum = [];
o_multiAscProfDate = [];
o_multiAscProfLocDate = [];

% exploitation du fichier multi-profils
multiProfNum = [];
multiProfDir = [];
multiProfDate = [];
multiProfLocDate = [];
profFileName = [a_ncDirName '/' sprintf('%d/%d_prof.nc', a_floatNum, a_floatNum)];
if (~exist(profFileName, 'dir') && exist(profFileName, 'file'))
   if (verLessThan('matlab', '7.7'))
      
      fCdf = netcdf(profFileName, 'read');
      
      cycleNumber = fCdf{'CYCLE_NUMBER'}(:);
      direction = fCdf{'DIRECTION'}(:);
      juld = fCdf{'JULD'}(:);
      idFillValue = find(juld == fCdf{'JULD'}.FillValue_(:));
      if (~isempty(idFillValue))
         juld(idFillValue) = ones(length(idFillValue), 1)*g_dateDef;
      end
      juldLocation = fCdf{'JULD_LOCATION'}(:);
      idFillValue = find(juldLocation == fCdf{'JULD_LOCATION'}.FillValue_(:));
      if (~isempty(idFillValue))
         juldLocation(idFillValue) = ones(length(idFillValue), 1)*g_dateDef;
      end
      
      close(fCdf);
      
      multiProfNum = cycleNumber;
      multiProfDir = direction;
      multiProfDate = juld;
      multiProfLocDate = juldLocation;
      
   else
      
      % retrieve needed information from NetCDF file
      wantedVars = [ ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'JULD'} ...
         {'JULD_LOCATION'} ...
         ];
      [ncData] = get_data_from_nc_file(profFileName, wantedVars);
      
      idVal = find(strcmp('CYCLE_NUMBER', ncData) == 1, 1);
      cycleNumber = ncData{idVal+1};
      
      idVal = find(strcmp('DIRECTION', ncData) == 1, 1);
      direction = ncData{idVal+1};
      
      idVal = find(strcmp('JULD', ncData) == 1, 1);
      juld = ncData{idVal+1};
      juld(find(juld == 999999)) = g_dateDef;
      
      idVal = find(strcmp('JULD_LOCATION', ncData) == 1, 1);
      juldLocation = ncData{idVal+1};
      juldLocation(find(juldLocation == 999999)) = g_dateDef;
      
      multiProfNum = cycleNumber;
      multiProfDir = direction;
      multiProfDate = juld;
      multiProfLocDate = juldLocation;
      
   end
else
   fprintf('ATTENTION: pas de fichier multi PROF.nc pour le flotteur %d\n', ...
      a_floatNum);
end

% exploitation des fichiers mono-profil
monoProfNum = [];
monoProfDir = [];
monoProfDate = [];
monoProfLocDate = [];
monoProfFileName = [a_ncDirName sprintf('/%d/profiles/*%d_*.nc', a_floatNum, a_floatNum)];
monoProfFiles = dir(monoProfFileName);
for idFile = 1:length(monoProfFiles)
   fileName = monoProfFiles(idFile).name;
   profFileName = [a_ncDirName sprintf('/%d/profiles/', a_floatNum) fileName];
   
   if (~exist(profFileName, 'dir') && exist(profFileName, 'file'))
      if (verLessThan('matlab', '7.7'))
         
         fCdf = netcdf(profFileName, 'read');
         
         cycleNumber = fCdf{'CYCLE_NUMBER'}(:);
         direction = fCdf{'DIRECTION'}(:);
         juld = fCdf{'JULD'}(:);
         if (juld == fCdf{'JULD'}.FillValue_(:))
            juld = g_dateDef;
         end
         juldLocation = fCdf{'JULD_LOCATION'}(:);
         if (juldLocation == fCdf{'JULD_LOCATION'}.FillValue_(:))
            juldLocation = g_dateDef;
         end
         
         close(fCdf);
         
         monoProfNum = [monoProfNum; cycleNumber(1)];
         monoProfDir = [monoProfDir direction(1)];
         monoProfDate = [monoProfDate; juld(1)];
         monoProfLocDate = [monoProfLocDate; juldLocation(1)];
         
      else
         
         % retrieve needed information from NetCDF file
         wantedVars = [ ...
            {'CYCLE_NUMBER'} ...
            {'DIRECTION'} ...
            {'JULD'} ...
            {'JULD_LOCATION'} ...
            ];
         [ncData] = get_data_from_nc_file(profFileName, wantedVars);
         
         idVal = find(strcmp('CYCLE_NUMBER', ncData) == 1, 1);
         cycleNumber = ncData{idVal+1};
         
         idVal = find(strcmp('DIRECTION', ncData) == 1, 1);
         direction = ncData{idVal+1};
         
         idVal = find(strcmp('JULD', ncData) == 1, 1);
         juld = ncData{idVal+1};
         juld(find(juld == 999999)) = g_dateDef;
         
         idVal = find(strcmp('JULD_LOCATION', ncData) == 1, 1);
         juldLocation = ncData{idVal+1};
         juldLocation(find(juldLocation == 999999)) = g_dateDef;
         
         monoProfNum = [monoProfNum; cycleNumber(1)];
         monoProfDir = [monoProfDir direction(1)];
         monoProfDate = [monoProfDate; juld(1)];
         monoProfLocDate = [monoProfLocDate; juldLocation(1)];
         
      end
   end
end
if (isempty(monoProfFiles))
   fprintf('ATTENTION: pas de fichier mono profil pour le flotteur %d\n', ...
      a_floatNum);
end

% on épure la liste des multi en supprimant les profils déjà dans les mono

% profils descendants
idDesc = find(multiProfDir == 'D');
o_multiDescProfNum = multiProfNum(idDesc);
o_multiDescProfDate = multiProfDate(idDesc);
o_multiDescProfLocDate = multiProfLocDate(idDesc);

idDesc = find(monoProfDir == 'D');
o_monoDescProfNum = monoProfNum(idDesc);
o_monoDescProfDate = monoProfDate(idDesc);
o_monoDescProfLocDate = monoProfLocDate(idDesc);

% for idProf = 1:length(o_monoDescProfNum)
%    idDel = find((o_multiDescProfNum == o_monoDescProfNum(idProf)) & ...
%       (o_multiDescProfDate == o_monoDescProfDate(idProf)) & ...
%       (o_multiDescProfLocDate == o_monoDescProfLocDate(idProf)));
%    if (~isempty(idDel))
%       o_multiDescProfNum(idDel) = [];
%       o_multiDescProfDate(idDel) = [];
%       o_multiDescProfLocDate(idDel) = [];
%    end
% end
%
% if (~isempty(o_multiDescProfNum))
%    fprintf('ATTENTION: %d profils descendants du multi ne sont pas dans les mono pour le flotteur %d\n', ...
%       length(o_multiDescProfNum), a_floatNum);
% end

% profils ascendants
idAsc = find(multiProfDir == 'A');
o_multiAscProfNum = multiProfNum(idAsc);
o_multiAscProfDate = multiProfDate(idAsc);
o_multiAscProfLocDate = multiProfLocDate(idAsc);

idAsc = find(monoProfDir == 'A');
o_monoAscProfNum = monoProfNum(idAsc);
o_monoAscProfDate = monoProfDate(idAsc);
o_monoAscProfLocDate = monoProfLocDate(idAsc);

% for idProf = 1:length(o_monoAscProfNum)
%    idDel = find((o_multiAscProfNum == o_monoAscProfNum(idProf)) & ...
%       (o_multiAscProfDate == o_monoAscProfDate(idProf)) & ...
%       (o_multiAscProfLocDate == o_monoAscProfLocDate(idProf)));
%    if (~isempty(idDel))
%       o_multiAscProfNum(idDel) = [];
%       o_multiAscProfDate(idDel) = [];
%       o_multiAscProfLocDate(idDel) = [];
%    end
% end
%
% if (~isempty(o_multiAscProfNum))
%    fprintf('ATTENTION: %d profils ascendants du multi ne sont pas dans les mono pour le flotteur %d\n', ...
%       length(o_multiAscProfNum), a_floatNum);
% end

return;

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


if (~exist(a_ncPathFileName, 'dir') && exist(a_ncPathFileName, 'file'))
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
   end
   
   % retreive variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {' '}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return;
