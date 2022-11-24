% ------------------------------------------------------------------------------
% Compare two sets (called Base and New) of NetCDF mono-profile files.
% Similar to nc_compare_mono_profile_files_prv_DM.m but for 'real' BGC
% floats.
%
% SYNTAX :
%   nc_compare_mono_profile_files_prv_bgc_in_DM or nc_compare_mono_profile_files_prv_bgc_in_DM(6900189, 7900118)
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
%   10/22/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_compare_mono_profile_files_prv_bgc_in_DM(varargin)

% top directory of base NetCDF mono-profile files
DIR_INPUT_BASE_NC_FILES = 'E:\HDD\201407-ArgoData\coriolis_csio_incois_kordi_nmdis\';
DIR_INPUT_BASE_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_updated\';
DIR_INPUT_BASE_NC_FILES = 'E:\DM_3.1\coriolis_csio_incois_kordi_nmdis\';
DIR_INPUT_BASE_NC_FILES = 'E:\archive_201505\coriolis\selected\';
DIR_INPUT_BASE_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TMP\OLD\';

% top directory of new NetCDF mono-profile files
DIR_INPUT_NEW_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_decPrv_argos_sans_EOL\';
DIR_INPUT_NEW_NC_FILES = 'C:\users\RNU\Argo\work\nc_output_decPrv_argos\';
DIR_INPUT_NEW_NC_FILES = 'E:\nc_output_decPrv_argos_20150129\';
DIR_INPUT_NEW_NC_FILES = 'E:\archive_201510\201510-ArgoData\DATA\coriolis\selected\\';
DIR_INPUT_NEW_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TMP\NEW\';


% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to compare
FLOAT_LIST_FILE_NAME = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/nke_all_with_DM_b_file.txt';
FLOAT_LIST_FILE_NAME = 'C:/users/RNU/Argo/Aco/12833_update_decPrv_pour_RT_TRAJ3/lists/nke_all_with_DM.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\nke_all_with_DM_bis_20151003.txt';

% flag to print data measurements (when different) in the log file
PRINT_DIFF_DATA_FLAG = 1;

% default values
global g_dateDef;
global g_janFirst1950InMatlab;
g_dateDef = 99999.99999999;
g_janFirst1950InMatlab = datenum('1950-01-01 00:00:00', 'yyyy-mm-dd HH:MM:SS');

% Matlab date to julian day shift
SHIFT_DATE = 712224;

% half interval for profile fit
INTERVAL_HOUR = 10;
INTERVAL_DAY = INTERVAL_HOUR/24;

% first profile date to stop the comparison (leave it empty if you don't want
% to use it)
FIRST_PROF_DATE_TO_STOP_COMPARISON = ''; % if you don't want to use it
% FIRST_PROF_DATE_TO_STOP_COMPARISON = '2014-06-01 00:00:00';
firstJuldToStopComparison = g_dateDef;
if (~isempty(FIRST_PROF_DATE_TO_STOP_COMPARISON))
   firstJuldToStopComparison = datenum(FIRST_PROF_DATE_TO_STOP_COMPARISON, 'yyyy-mm-dd HH:MM:SS')-SHIFT_DATE;
end


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

logFile = [DIR_LOG_CSV_FILE '/' 'nc_compare_mono_profile_files_prv_bgc_in_DM' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   Base input directory: %s\n', DIR_INPUT_BASE_NC_FILES);
fprintf('   New input directory: %s\n', DIR_INPUT_NEW_NC_FILES);
fprintf('   Log/csv output directory: %s\n', DIR_LOG_CSV_FILE);
if (nargin == 0)
   fprintf('   List of floats to process: %s\n', FLOAT_LIST_FILE_NAME);
else
   fprintf('   Floats to process:');
   fprintf(' %d', floatList);
   fprintf('\n');
end
fprintf('   Time interval to link profile sets: [-%d ; + %d] hours\n', ...
   INTERVAL_HOUR, INTERVAL_HOUR);
if (firstJuldToStopComparison ~= g_dateDef)
   fprintf('   Only profiles dated before %s are considered\n', ...
      julian_2_gregorian(firstJuldToStopComparison));
end
fprintf('\n');

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_compare_mono_profile_files_prv_bgc_in_DM' name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = ['; ; ; DIFF; DIFF; DIFF; DIFF; DIFF; DIFF; DIFF; DIFF;' ...
   'BASE; BASE; BASE; BASE; BASE; BASE; BASE; BASE; BASE; ' ...
   'NEW; NEW; NEW; NEW; NEW; NEW; NEW; NEW; NEW'];
fprintf(fidOut, '%s\n', header);
header = ['Line; WMO; Dir; CyNum; Date; Pos; Mode; Cut; Lev; Data; Vers;' ...
   'CyNum; Date; DateLoc; Lon; Lat; Mode; Cut; Lev; Vers; ' ...
   'CyNum; Date; DateLoc; Lon; Lat; Mode; Cut; Lev; Vers'];
fprintf(fidOut, '%s\n', header);

% process the floats
lineNum = 1;
nbFloats = length(floatList);
for idFloat = 1:nbFloats

   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);

   % retrieve profile dates and numbers of both sets
   [descProfNumBase, descProfDateBase, descProfLocDateBase, ...
      ascProfNumBase, ascProfDateBase, ascProfLocDateBase] = ...
      get_nc_profile_dates(DIR_INPUT_BASE_NC_FILES, floatNum, 'Base');

   [descProfNumNew, descProfDateNew, descProfLocDateNew, ...
      ascProfNumNew, ascProfDateNew, ascProfLocDateNew] = ...
      get_nc_profile_dates(DIR_INPUT_NEW_NC_FILES, floatNum, 'New');
   
   % only dated profiles are used
   idNotDated = find(descProfDateBase == g_dateDef);
   descProfDateBase(idNotDated) = descProfLocDateBase(idNotDated);
   idNotDated = find(descProfDateBase == g_dateDef);
   if (~isempty(idNotDated))
      fprintf('WARNING: Not dated Base descent profile (ignored):');
      fprintf(' %d', descProfNumBase(idNotDated));
      fprintf('\n');
      descProfNumBase(idNotDated) = [];
      descProfDateBase(idNotDated) = [];
   end
   
   idNotDated = find(ascProfDateBase == g_dateDef);
   ascProfDateBase(idNotDated) = ascProfLocDateBase(idNotDated);
   idNotDated = find(ascProfDateBase == g_dateDef);
   if (~isempty(idNotDated))
      fprintf('WARNING: Not dated Base ascent profile (ignored):');
      fprintf(' %d', ascProfNumBase(idNotDated));
      fprintf('\n');
      ascProfNumBase(idNotDated) = [];
      ascProfDateBase(idNotDated) = [];
   end
   
   idNotDated = find(descProfDateNew == g_dateDef);
   descProfDateNew(idNotDated) = descProfLocDateNew(idNotDated);
   idNotDated = find(descProfDateNew == g_dateDef);
   if (~isempty(idNotDated))
      fprintf('WARNING: Not dated new descent profile (ignored):');
      fprintf(' %d', descProfNumNew(idNotDated));
      fprintf('\n');
      descProfNumNew(idNotDated) = [];
      descProfDateNew(idNotDated) = [];
   end
   
   idNotDated = find(ascProfDateNew == g_dateDef);
   ascProfDateNew(idNotDated) = ascProfLocDateNew(idNotDated);
   idNotDated = find(ascProfDateNew == g_dateDef);
   if (~isempty(idNotDated))
      fprintf('WARNING: Not dated new ascent profile (ignored):');
      fprintf(' %d', ascProfNumNew(idNotDated));
      fprintf('\n');
      ascProfNumNew(idNotDated) = [];
      ascProfDateNew(idNotDated) = [];
   end
   
   % compute anew the dates for comparisons
   if (~isempty(descProfDateBase))
      descProfDateBase = datenum(datestr(descProfDateBase+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   if (~isempty(descProfDateNew))
      descProfDateNew = datenum(datestr(descProfDateNew+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   if (~isempty(ascProfDateBase))
      ascProfDateBase = datenum(datestr(ascProfDateBase+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   if (~isempty(ascProfDateNew))
      ascProfDateNew = datenum(datestr(ascProfDateNew+SHIFT_DATE, 0), 'dd-mmm-yyyy HH:MM:SS')-SHIFT_DATE;
   end
   
   % date restriction for comparison
   if (firstJuldToStopComparison ~= g_dateDef)
      if (~isempty(find(descProfDateBase >= firstJuldToStopComparison, 1)))
         idDel = find(descProfDateBase >= firstJuldToStopComparison);
         descProfNumBase(idDel) = [];
         descProfDateBase(idDel) = [];
      end
      if (~isempty(find(descProfDateNew >= firstJuldToStopComparison, 1)))
         idDel = find(descProfDateNew >= firstJuldToStopComparison);
         descProfNumNew(idDel) = [];
         descProfDateNew(idDel) = [];
      end
      if (~isempty(find(ascProfDateBase >= firstJuldToStopComparison, 1)))
         idDel = find(ascProfDateBase >= firstJuldToStopComparison);
         ascProfNumBase(idDel) = [];
         ascProfDateBase(idDel) = [];
      end
      if (~isempty(find(ascProfDateNew >= firstJuldToStopComparison, 1)))
         idDel = find(ascProfDateNew >= firstJuldToStopComparison);
         ascProfNumNew(idDel) = [];
         ascProfDateNew(idDel) = [];
      end
   end
      
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % descent profiles processing
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     
   % try to link the 2 sets according to profile dates
   descProfNumBase2New = ones(length(descProfNumBase), 1)*-1;
   for idProf = 1:length(descProfNumBase)
      profDateBase = descProfDateBase(idProf);
      
      % look for the corresponding New profile
      idF = find(abs(descProfDateNew - profDateBase) <= INTERVAL_DAY);
      if (length(idF) == 1)
         descProfNumBase2New(idProf) = descProfNumNew(idF);
         
         descProfNumNew(idF) = [];
         descProfDateNew(idF) = [];
      elseif (length(idF) > 1)
         [~, idMin] = min(abs(descProfDateNew - profDateBase));
         descProfNumBase2New(idProf) = descProfNumNew(idMin);
         
         numbers = sprintf(' #%d', descProfNumNew(idF));
         fprintf('WARNING: %d descent new profiles found around date %s (corresponding to profiles%s) => (the #%d is selected)\n', ...
            length(idF), julian_2_gregorian(profDateBase), numbers, idMin);
         
         descProfNumNew(idMin) = [];
         descProfDateNew(idMin) = [];
      end
   end
   
   % process the remaining New profiles
   for idProf = 1:length(descProfNumNew)
      profNumNew = descProfNumNew(idProf);
      profDateNew = descProfDateNew(idProf);
      
      % find the right place (chronological order) to store the remaining
      % profile
      idF = find(descProfDateBase < profDateNew);
      if (~isempty(idF))
         if (idF(end) < length(descProfDateBase))
            descProfNumBase(idF(end)+2:end+1) = descProfNumBase(idF(end)+1:end);
            descProfDateBase(idF(end)+2:end+1) = descProfDateBase(idF(end)+1:end);
            descProfNumBase2New(idF(end)+2:end+1) = descProfNumBase2New(idF(end)+1:end);
         end
         descProfNumBase(idF(end)+1) = -1;
         descProfDateBase(idF(end)+1) = profDateNew;
         descProfNumBase2New(idF(end)+1) = profNumNew;
      else
         descProfNumBase = [-1; descProfNumBase];
         descProfDateBase = [profDateNew; descProfDateBase];
         descProfNumBase2New = [profNumNew; descProfNumBase2New];
      end         
   end
   
   % compare the mono-profile files
   for idProf = 1:length(descProfNumBase)
      
      if (descProfNumBase(idProf) == -1)
         
         profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03dD.nc', floatNum, floatNum, descProfNumBase2New(idProf))];
         if ~(exist(profFileNameNew, 'file') == 2)
            profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03dD.nc', floatNum, floatNum, descProfNumBase2New(idProf))];
            if ~(exist(profFileNameNew, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameNew);
               continue
            end
         end
         [profDate, profLocDate, profLon, profLat, ...
            profMode, profCut, profNbLevels, fileVersion, dataStr, paramStr] = ...
            get_nc_profile_info(profFileNameNew, PRINT_DIFF_DATA_FLAG);
         
         for idProf2 = 1:length(profLocDate)
            
            fprintf(fidOut, '%d; %d; D; -1; -1; -1; -1; -1; -1; -1; -1; ; ; ; ; ; ; ; ; ; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s\n', ...
               lineNum, floatNum, ...
               descProfNumBase2New(idProf), ...
               julian_2_gregorian(profDate(idProf2)), ...
               julian_2_gregorian(profLocDate(idProf2)), profLon(idProf2), profLat(idProf2), ...
               profMode(idProf2), profCut(idProf2), profNbLevels(idProf2), fileVersion);
            lineNum = lineNum + 1;
            
            if (PRINT_DIFF_DATA_FLAG == 1)
               fprintf('Float %d cycle #%d prof #%d: descent profile only in NEW set (N_LEVELS = %d)\n', ...
                  floatNum, descProfNumBase2New(idProf), idProf2, profNbLevels(idProf2));
               nbCol = size(dataStr{idProf2}, 2);
               pattern = repmat(' ', 1, nbCol);
               fprintf('FLAG: %s | NEW (%s)\n', pattern, paramStr{idProf2});
               for idLev = 1:size(dataStr{idProf2}, 1)
                  diffFlag = 1;
                  fprintf('  %d : %s | %s\n', ...
                     diffFlag, pattern, dataStr{idProf2}(idLev, :));
               end
            end
         end
                  
      elseif (descProfNumBase2New(idProf) == -1)
         
         profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03dD.nc', floatNum, floatNum, descProfNumBase(idProf))];
         if ~(exist(profFileNameBase, 'file') == 2)
            profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03dD.nc', floatNum, floatNum, descProfNumBase(idProf))];
            if ~(exist(profFileNameBase, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameBase);
               continue
            end
         end
         [profDate, profLocDate, profLon, profLat, ...
            profMode, profCut, profNbLevels, fileVersion, dataStr, paramStr] = ...
            get_nc_profile_info(profFileNameBase, PRINT_DIFF_DATA_FLAG);
         
         for idProf2 = 1:length(profLocDate)
            
            fprintf(fidOut, '%d; %d; D; -1; -1; -1; -1; -1; -1; -1; -1; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s\n', ...
               lineNum, floatNum, ...
               descProfNumBase(idProf), ...
               julian_2_gregorian(profDate(idProf2)), ...
               julian_2_gregorian(profLocDate(idProf2)), profLon(idProf2), profLat(idProf2), ...
               profMode(idProf2), profCut(idProf2), profNbLevels(idProf2), fileVersion);
            lineNum = lineNum + 1;
            
            if (PRINT_DIFF_DATA_FLAG == 1)
               fprintf('Float %d cycle #%d prof #%d: descent profile only in BASE set (N_LEVELS = %d)\n', ...
                  floatNum, descProfNumBase(idProf), idProf2, profNbLevels(idProf2));
               nbCol = size(dataStr{idProf2}, 2);
               fprintf('FLAG: BASE (%s) %s |\n', ...
                  paramStr{idProf2}, ...
                  repmat(' ', 1, nbCol-length('BASE')-1-length(paramStr{idProf2})-3));
               for idLev = 1:size(dataStr{idProf2}, 1)
                  diffFlag = 1;
                  fprintf('  %d : %s |\n', ...
                     diffFlag, dataStr{idProf2}(idLev, :));
               end
            end
         end
         
      else
         
         profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03dD.nc', floatNum, floatNum, descProfNumBase(idProf))];
         if ~(exist(profFileNameBase, 'file') == 2)
            profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03dD.nc', floatNum, floatNum, descProfNumBase(idProf))];
            if ~(exist(profFileNameBase, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameBase);
               continue
            end
         end
         [profDateBase, profLocDateBase, profLonBase, profLatBase, ...
            profModeBase, profCutBase, profNbLevelsBase, fileVersionBase, dataStrBase, paramStrBase] = ...
            get_nc_profile_info(profFileNameBase, 1);

         profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03dD.nc', floatNum, floatNum, descProfNumBase2New(idProf))];
         if ~(exist(profFileNameNew, 'file') == 2)
            profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03dD.nc', floatNum, floatNum, descProfNumBase2New(idProf))];
            if ~(exist(profFileNameNew, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameNew);
               continue
            end
         end
         [profDateNew, profLocDateNew, profLonNew, profLatNew, ...
            profModeNew, profCutNew, profNbLevelsNew, fileVersionNew, dataStrNew, paramStrNew] = ...
            get_nc_profile_info(profFileNameNew, 1);
         
         % create the comparison flags
         for idProf2 = 1:length(profDateBase)
            
            cycleNumFlag = 0;
            if (descProfNumBase(idProf) ~= descProfNumBase2New(idProf))
               cycleNumFlag = 1;
            end
            profDateFlag = 0;
            if (strcmp(julian_2_gregorian(profDateBase(idProf2)), julian_2_gregorian(profDateNew(idProf2))) == 0)
               profDateFlag = 1;
            end
            profPosFlag = 0;
            if ((strcmp(julian_2_gregorian(profLocDateBase(idProf2)), julian_2_gregorian(profLocDateNew(idProf2))) == 0) || ...
                  (strcmp(sprintf('%.3f', profLonBase(idProf2)), sprintf('%.3f', profLonNew(idProf2))) == 0) || ...
                  (strcmp(sprintf('%.3f', profLatBase(idProf2)), sprintf('%.3f', profLatNew(idProf2))) == 0))
               profPosFlag = 1;
            end
            profModeFlag = 0;
            if (profModeBase(idProf2) ~= profModeNew(idProf2))
               profModeFlag = 1;
            end
            profCutFlag = 0;
            if (profCutBase(idProf2) ~= profCutNew(idProf2))
               profCutFlag = 1;
            end
            profNbLevFlag = 0;
            if (profNbLevelsBase(idProf2) ~= profNbLevelsNew(idProf2))
               profNbLevFlag = 1;
            end
            profDataFlag = profNbLevFlag;
            if (profDataFlag == 0)
               for idLev = 1:size(dataStrBase{idProf2}, 1)
                  if (~strcmp(dataStrBase{idProf2}(idLev, :), dataStrNew{idProf2}(idLev, :)))
                     profDataFlag = 1;
                     break
                  end
               end
            end
            if ((profDataFlag == 1) && (PRINT_DIFF_DATA_FLAG == 1))
               fprintf('Float %d cycle #%d prof #%d: descent profiles differ (BASE: N_LEVELS = %d; NEW: N_LEVELS = %d)\n', ...
                  floatNum, descProfNumBase(idProf), idProf2, ...
                  profNbLevelsBase(idProf2), profNbLevelsNew(idProf2));
               nbCol = size(dataStrBase{idProf2}, 2);
               fprintf('FLAG: BASE (%s) %s | NEW (%s)\n', ...
                  paramStrBase{idProf2}, ...
                  repmat(' ', 1, nbCol-length('BASE')-1-length(paramStrBase{idProf2})-3), ...
                  paramStrNew{idProf2});
               nbLevBoth = min(size(dataStrBase{idProf2}, 1), size(dataStrNew{idProf2}, 1));
               for idLev = 1:nbLevBoth
                  diffFlag = 0;
                  if (~strcmp(dataStrBase{idProf2}(idLev, :), dataStrNew{idProf2}(idLev, :)))
                     diffFlag = 1;
                  end
                  fprintf('  %d : %s | %s\n', ...
                     diffFlag, dataStrBase{idProf2}(idLev, :), dataStrNew{idProf2}(idLev, :));
               end
               if (size(dataStrBase{idProf2}, 1) > nbLevBoth)
                  for idLev = nbLevBoth+1:size(dataStrBase{idProf2}, 1)
                     diffFlag = 1;
                     fprintf('  %d : %s |\n', ...
                        diffFlag, dataStrBase{idProf2}(idLev, :));
                  end
               else
                  pattern = repmat(' ', 1, nbCol);
                  for idLev = nbLevBoth+1:size(dataStrNew{idProf2}, 1)
                     diffFlag = 1;
                     fprintf('  %d : %s | %s\n', ...
                        diffFlag, pattern, dataStrNew{idProf2}(idLev, :));
                  end
               end
            end
            fileVersionFlag = 0;
            if (strcmp(fileVersionBase, fileVersionNew) == 0)
               fileVersionFlag = 1;
            end
            
            fprintf(fidOut, '%d; %d; D; %d; %d; %d; %d; %d; %d; %d; %d; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s\n', ...
               lineNum, floatNum, ...
               cycleNumFlag, profDateFlag, profPosFlag, profModeFlag, ...
               profCutFlag, profNbLevFlag, profDataFlag, fileVersionFlag, ...
               descProfNumBase(idProf), ...
               julian_2_gregorian(profDateBase(idProf2)), ...
               julian_2_gregorian(profLocDateBase(idProf2)), profLonBase(idProf2), profLatBase(idProf2), ...
               profModeBase(idProf2), profCutBase(idProf2), profNbLevelsBase(idProf2), fileVersionBase, ...
               descProfNumBase2New(idProf), ...
               julian_2_gregorian(profDateNew(idProf2)), ...
               julian_2_gregorian(profLocDateNew(idProf2)), profLonNew(idProf2), profLatNew(idProf2), ...
               profModeNew(idProf2), profCutNew(idProf2), profNbLevelsNew(idProf2), fileVersionNew);
            lineNum = lineNum + 1;
            
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % ascent profiles processing
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % try to link the 2 sets according to profile dates
   ascProfNumBase2New = ones(length(ascProfNumBase), 1)*-1;
   for idProf = 1:length(ascProfNumBase)
      profNumBase = ascProfNumBase(idProf);
      profDateBase = ascProfDateBase(idProf);
      
      % look for the corresponding New profile
      idF = find(abs(ascProfDateNew - profDateBase) <= INTERVAL_DAY);
      if (length(idF) == 1)
         ascProfNumBase2New(idProf) = ascProfNumNew(idF);
         
         ascProfNumNew(idF) = [];
         ascProfDateNew(idF) = [];
      elseif (length(idF) > 1)
         [~, idMin] = min(abs(ascProfDateNew - profDateBase));
         ascProfNumBase2New(idProf) = ascProfNumNew(idMin);
         
         numbers = sprintf(' #%d', ascProfNumNew(idF));
         fprintf('WARNING: %d ascent new profiles found around date %s (corresponding to profiles%s) => (the #%d is selected)\n', ...
            length(idF), julian_2_gregorian(profDateBase), numbers, idMin);
         
         ascProfNumNew(idMin) = [];
         ascProfDateNew(idMin) = [];
      end
   end

   % process the remaining New profiles
   for idProf = 1:length(ascProfNumNew)
      profNumNew = ascProfNumNew(idProf);
      profDateNew = ascProfDateNew(idProf);
      
      % find the right place (chronological order) to store the remaining
      % profile
      idF = find(ascProfDateBase < profDateNew);
      if (~isempty(idF))
         if (idF(end) < length(ascProfDateBase))
            ascProfNumBase(idF(end)+2:end+1) = ascProfNumBase(idF(end)+1:end);
            ascProfDateBase(idF(end)+2:end+1) = ascProfDateBase(idF(end)+1:end);
            ascProfNumBase2New(idF(end)+2:end+1) = ascProfNumBase2New(idF(end)+1:end);
         end
         ascProfNumBase(idF(end)+1) = -1;
         ascProfDateBase(idF(end)+1) = profDateNew;
         ascProfNumBase2New(idF(end)+1) = profNumNew;
      else
         ascProfNumBase = [-1; ascProfNumBase];
         ascProfDateBase = [profDateNew; ascProfDateBase];
         ascProfNumBase2New = [profNumNew; ascProfNumBase2New];
      end         
   end
   
   % compare the mono-profile files
   for idProf = 1:length(ascProfNumBase)
      
      if (ascProfNumBase(idProf) == -1)
         
         profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03d.nc', floatNum, floatNum, ascProfNumBase2New(idProf))];
         if ~(exist(profFileNameNew, 'file') == 2)
            profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03d.nc', floatNum, floatNum, ascProfNumBase2New(idProf))];
            if ~(exist(profFileNameNew, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameNew);
               continue
            end
         end
         [profDate, profLocDate, profLon, profLat, ...
            profMode, profCut, profNbLevels, fileVersion, dataStr, paramStr] = ...
            get_nc_profile_info(profFileNameNew, PRINT_DIFF_DATA_FLAG);
         
         for idProf2 = 1:length(profDateBase)
            
            fprintf(fidOut, '%d; %d; A; -1; -1; -1; -1; -1; -1; -1; -1; ; ; ; ; ; ; ; ; ; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s\n', ...
               lineNum, floatNum, ...
               ascProfNumBase2New(idProf), ...
               julian_2_gregorian(profDate(idProf2)), ...
               julian_2_gregorian(profLocDate(idProf2)), profLon(idProf2), profLat(idProf2), ...
               profMode(idProf2), profCut(idProf2), profNbLevels(idProf2), fileVersion);
            lineNum = lineNum + 1;
            
            if (PRINT_DIFF_DATA_FLAG == 1)
               fprintf('Float %d cycle #%d prof #%d: ascent profile only in NEW set (N_LEVELS = %d)\n', ...
                  floatNum, ascProfNumBase2New(idProf), idProf2, profNbLevels(idProf2));
               nbCol = size(dataStr{idProf2}, 2);
               pattern = repmat(' ', 1, nbCol);
               fprintf('FLAG: %s | NEW (%s)\n', pattern, paramStr{idProf2});
               for idLev = 1:size(dataStr{idProf2}, 1)
                  diffFlag = 1;
                  fprintf('  %d : %s | %s\n', ...
                     diffFlag, pattern, dataStr{idProf2}(idLev, :));
               end
            end
         end
         
      elseif (ascProfNumBase2New(idProf) == -1)
         
         profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03d.nc', floatNum, floatNum, ascProfNumBase(idProf))];
         if ~(exist(profFileNameBase, 'file') == 2)
            profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03d.nc', floatNum, floatNum, ascProfNumBase(idProf))];
            if ~(exist(profFileNameBase, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameBase);
               continue
            end
         end
         [profDate, profLocDate, profLon, profLat, ...
            profMode, profCut, profNbLevels, fileVersion, dataStr, paramStr] = ...
            get_nc_profile_info(profFileNameBase, PRINT_DIFF_DATA_FLAG);
         
         for idProf2 = 1:length(profDateBase)
            
            fprintf(fidOut, '%d; %d; A; -1; -1; -1; -1; -1; -1; -1; -1; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s\n', ...
               lineNum, floatNum, ...
               ascProfNumBase(idProf), ...
               julian_2_gregorian(profDate(idProf2)), ...
               julian_2_gregorian(profLocDate(idProf2)), profLon(idProf2), profLat(idProf2), ...
               profMode(idProf2), profCut(idProf2), profNbLevels(idProf2), fileVersion);
            lineNum = lineNum + 1;
            
            if (PRINT_DIFF_DATA_FLAG == 1)
               fprintf('Float %d cycle #%d prof #%d: ascent profile only in BASE set (N_LEVELS = %d)\n', ...
                  floatNum, ascProfNumBase(idProf), idProf2, profNbLevels(idProf2));
               nbCol = size(dataStr{idProf2}, 2);
               fprintf('FLAG: BASE (%s) %s |\n', ...
                  paramStr{idProf2}, ...
                  repmat(' ', 1, nbCol-length('BASE')-1-length(paramStr{idProf2})-3));
               for idLev = 1:size(dataStr{idProf2}, 1)
                  diffFlag = 1;
                  fprintf('  %d : %s |\n', ...
                     diffFlag, dataStr{idProf2}(idLev, :));
               end
            end
         end
         
      else
         
         profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03d.nc', floatNum, floatNum, ascProfNumBase(idProf))];
         if ~(exist(profFileNameBase, 'file') == 2)
            profFileNameBase = [DIR_INPUT_BASE_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03d.nc', floatNum, floatNum, ascProfNumBase(idProf))];
            if ~(exist(profFileNameBase, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameBase);
               continue
            end
         end
         [profDateBase, profLocDateBase, profLonBase, profLatBase, ...
            profModeBase, profCutBase, profNbLevelsBase, fileVersionBase, ...
            dataStrBase, paramStrBase] = ...
            get_nc_profile_info(profFileNameBase, 1);

         profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
            sprintf('/%d/profiles/R%d_%03d.nc', floatNum, floatNum, ascProfNumBase2New(idProf))];
         if ~(exist(profFileNameNew, 'file') == 2)
            profFileNameNew = [DIR_INPUT_NEW_NC_FILES ...
               sprintf('/%d/profiles/D%d_%03d.nc', floatNum, floatNum, ascProfNumBase2New(idProf))];
            if ~(exist(profFileNameNew, 'file') == 2)
               fprintf('WARNING: expected file name is missing (%s)\n', profFileNameNew);
               continue
            end
         end
         [profDateNew, profLocDateNew, profLonNew, profLatNew, ...
            profModeNew, profCutNew, profNbLevelsNew, fileVersionNew, ...
            dataStrNew, paramStrNew] = ...
            get_nc_profile_info(profFileNameNew, 1);
         
         % create the comparison flags
         for idProf2 = 1:length(profDateBase)
            
            cycleNumFlag = 0;
            if (ascProfNumBase(idProf) ~= ascProfNumBase2New(idProf))
               cycleNumFlag = 1;
            end
            profDateFlag = 0;
            if (strcmp(julian_2_gregorian(profDateBase(idProf2)), julian_2_gregorian(profDateNew(idProf2))) == 0)
               profDateFlag = 1;
            end
            profPosFlag = 0;
            if ((strcmp(julian_2_gregorian(profLocDateBase(idProf2)), julian_2_gregorian(profLocDateNew(idProf2))) == 0) || ...
                  (strcmp(sprintf('%.3f', profLonBase(idProf2)), sprintf('%.3f', profLonNew(idProf2))) == 0) || ...
                  (strcmp(sprintf('%.3f', profLatBase(idProf2)), sprintf('%.3f', profLatNew(idProf2))) == 0))
               profPosFlag = 1;
            end
            profModeFlag = 0;
            if (profModeBase(idProf2) ~= profModeNew(idProf2))
               profModeFlag = 1;
            end
            profCutFlag = 0;
            if (profCutBase(idProf2) ~= profCutNew(idProf2))
               profCutFlag = 1;
            end
            profNbLevFlag = 0;
            if (profNbLevelsBase(idProf2) ~= profNbLevelsNew(idProf2))
               profNbLevFlag = 1;
            end
            profDataFlag = profNbLevFlag;
            if (profDataFlag == 0)
               for idLev = 1:size(dataStrBase{idProf2}, 1)
                  if (~strcmp(dataStrBase{idProf2}(idLev, :), dataStrNew{idProf2}(idLev, :)))
                     profDataFlag = 1;
                     break
                  end
               end
            end
            if ((profDataFlag == 1) && (PRINT_DIFF_DATA_FLAG == 1))
               fprintf('Float %d cycle #%d prof #%d: ascent profiles differ (BASE: N_LEVELS = %d; NEW: N_LEVELS = %d)\n', ...
                  floatNum, ascProfNumBase(idProf), idProf2, ...
                  profNbLevelsBase(idProf2), profNbLevelsNew(idProf2));
               nbCol = size(dataStrBase{idProf2}, 2);
               fprintf('FLAG: BASE (%s) %s | NEW (%s)\n', ...
                  paramStrBase{idProf2}, ...
                  repmat(' ', 1, nbCol-length('BASE')-1-length(paramStrBase{idProf2})-3), ...
                  paramStrNew{idProf2});
               nbLevBoth = min(size(dataStrBase{idProf2}, 1), size(dataStrNew{idProf2}, 1));
               for idLev = 1:nbLevBoth
                  diffFlag = 0;
                  if (~strcmp(dataStrBase{idProf2}(idLev, :), dataStrNew{idProf2}(idLev, :)))
                     diffFlag = 1;
                  end
                  fprintf('  %d : %s | %s\n', ...
                     diffFlag, dataStrBase{idProf2}(idLev, :), dataStrNew{idProf2}(idLev, :));
               end
               if (size(dataStrBase{idProf2}, 1) > nbLevBoth)
                  for idLev = nbLevBoth+1:size(dataStrBase{idProf2}, 1)
                     diffFlag = 1;
                     fprintf('  %d : %s |\n', ...
                        diffFlag, dataStrBase{idProf2}(idLev, :));
                  end
               else
                  pattern = repmat(' ', 1, nbCol);
                  for idLev = nbLevBoth+1:size(dataStrNew{idProf2}, 1)
                     diffFlag = 1;
                     fprintf('  %d : %s | %s\n', ...
                        diffFlag, pattern, dataStrNew{idProf2}(idLev, :));
                  end
               end
            end
            fileVersionFlag = 0;
            if (strcmp(fileVersionBase, fileVersionNew) == 0)
               fileVersionFlag = 1;
            end
            
            fprintf(fidOut, '%d; %d; A; %d; %d; %d; %d; %d; %d; %d; %d; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s; %d; %s; %s; %.3f; %.3f; %c; %d; %d; V%s\n', ...
               lineNum, floatNum, ...
               cycleNumFlag, profDateFlag, profPosFlag, profModeFlag, ...
               profCutFlag, profNbLevFlag, profDataFlag, fileVersionFlag, ...
               ascProfNumBase(idProf), ...
               julian_2_gregorian(profDateBase(idProf2)), ...
               julian_2_gregorian(profLocDateBase(idProf2)), profLonBase(idProf2), profLatBase(idProf2), ...
               profModeBase(idProf2), profCutBase(idProf2), profNbLevelsBase(idProf2), fileVersionBase, ...
               ascProfNumBase2New(idProf), ...
               julian_2_gregorian(profDateNew(idProf2)), ...
               julian_2_gregorian(profLocDateNew(idProf2)), profLonNew(idProf2), profLatNew(idProf2), ...
               profModeNew(idProf2), profCutNew(idProf2), profNbLevelsNew(idProf2), fileVersionNew);
            lineNum = lineNum + 1;
            
         end
      end
   end   
   
   fprintf(fidOut, '%d; %d\n', ...
      lineNum, floatNum);
   lineNum = lineNum + 1;

end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve information on profile dates of a mono-profile NetCDF file.
%
% SYNTAX :
%  [o_descProfNum, o_descProfDate, o_descProfLocDate, ...
%    o_ascProfNum, o_ascProfDate, o_ascProfLocDate] = ...
%    get_nc_profile_dates(a_ncDirName, a_floatNum, a_commentStr)
%
% INPUT PARAMETERS :
%   a_ncDirName  : NetCDF top directory
%   a_floatNum   : float WMO number
%   a_commentStr : additional information (for comment only)
%
% OUTPUT PARAMETERS :
%   o_descProfNum     : descent profile numbers
%   o_descProfDate    : descent profile dates
%   o_descProfLocDate : descent profile location dates
%   o_ascProfNum      : ascent profile numbers
%   o_ascProfDate     : ascent profile dates
%   o_ascProfLocDate  : ascent profile location dates
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/26/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_descProfNum, o_descProfDate, o_descProfLocDate, ...
   o_ascProfNum, o_ascProfDate, o_ascProfLocDate] = ...
   get_nc_profile_dates(a_ncDirName, a_floatNum, a_commentStr)

% output parameters initialization
o_descProfNum = [];
o_descProfDate = [];
o_descProfLocDate = [];
o_ascProfNum = [];
o_ascProfDate = [];
o_ascProfLocDate = [];

% default values
global g_dateDef;


% extract profile dates in mono-profile NetCDF files
profNum = [];
profDir = [];
profDate = [];
profLocDate = [];
monoProfDirName = [a_ncDirName sprintf('/%d/profiles/', a_floatNum)];
if (strcmp(a_commentStr, 'Base'))
   lastCycle = -1;
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', a_floatNum)];
   monoProfFiles = dir(monoProfFileName);
   for idFile = 1:length(monoProfFiles)
      fileName = monoProfFiles(idFile).name;
      idF = strfind(fileName, '_');
      cyNum = str2num(fileName(idF+1:end-3));
      lastCycle = max([lastCycle cyNum]);
   end
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', a_floatNum)];
else
   lastCycle = -1;
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', a_floatNum)];
   monoProfFiles = dir(monoProfFileName);
   for idFile = 1:length(monoProfFiles)
      fileName = monoProfFiles(idFile).name;
      idF = strfind(fileName, '_');
      cyNum = str2num(fileName(idF+1:end-3));
      lastCycle = max([lastCycle cyNum]);
   end
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', a_floatNum)];
end
monoProfFiles = dir(monoProfFileName);
for idFile = 1:length(monoProfFiles)
    
   fileName = monoProfFiles(idFile).name;
   
   % do not consider b file (if exists)
   if (fileName(1) == 'B')
      continue
   end
   
   idF = strfind(fileName, '_');
   cyNum = str2num(fileName(idF+1:idF+3));
   if (cyNum > lastCycle)
      continue
   end
   
   profFileName = [monoProfDirName fileName];

   if (exist(profFileName, 'file') == 2)

      % open NetCDF file
      fCdf = netcdf.open(profFileName, 'NC_NOWRITE');
      if (isempty(fCdf))
         fprintf('ERROR: Unable to open NetCDF input file: %s\n', profFileName);
         return
      end

      % retrieve information
      if (var_is_present(fCdf, 'CYCLE_NUMBER') && ...
            var_is_present(fCdf, 'DIRECTION') && ...
            var_is_present(fCdf, 'JULD') && ...
            var_is_present(fCdf, 'JULD_LOCATION') && ...
            var_is_present(fCdf, 'DATA_MODE'))
         
         cycleNumber = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'));
         direction = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'));
         
         julD = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'));
         julDFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD'), '_FillValue');
         julD(find(julD == julDFillVal)) = g_dateDef;
         
         julDLocation = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'));
         julDLocationFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), '_FillValue');
         julDLocation(find(julDLocation == julDLocationFillVal)) = g_dateDef;
         
         dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'));
         
         netcdf.close(fCdf);
         
         idDel = find(dataMode == ' ');
         cycleNumber(idDel) = [];
         direction(idDel) = [];
         julD(idDel) = [];
         julDLocation(idDel) = [];
         
         [uJulD, idA, idC] = unique(julD);
         if (length(uJulD) > 1)
            fprintf('ERROR: %d profiles in the %s NetCDF input file: %s => file ignored\n', ...
               length(uJulD), a_commentStr, profFileName);
            continue
         end
           
         if (length(uJulD) ~= length(julD))
            % delete duplicated information
            for id1 = 1:length(uJulD)
               idF = find(idC == id1);
               if (length(idF) > 1)
                  for id2 = length(idF):-1:2
                     cycleNumber(idF(id2)) = [];
                     direction(idF(id2)) = [];
                     julD(idF(id2)) = [];
                     julDLocation(idF(id2)) = [];
                  end
               end
            end
         end
         
         profNum = [profNum; cycleNumber];
         profDir = [profDir direction];
         profDate = [profDate; julD];
         profLocDate = [profLocDate; julDLocation];
         
      else
         if (~var_is_present(fCdf, 'CYCLE_NUMBER'))
            fprintf('WARNING: Variable CYCLE_NUMBER not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         if (~var_is_present(fCdf, 'DIRECTION'))
            fprintf('WARNING: Variable DIRECTION not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         if (~var_is_present(fCdf, 'JULD'))
            fprintf('WARNING: Variable JULD not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         if (~var_is_present(fCdf, 'JULD_LOCATION'))
            fprintf('WARNING: Variable JULD_LOCATION not present in %s file : %s\n', ...
               a_commentStr, profFileName);
         end
         netcdf.close(fCdf);
         continue
      end
   end
end

if (isempty(monoProfFiles))
   fprintf('WARNING: no mono-profile %s file for float #%d\n', ...
      a_commentStr, a_floatNum);
end

% output parameters
idDesc = find(profDir == 'D');
o_descProfNum = profNum(idDesc);
o_descProfDate = profDate(idDesc);
o_descProfLocDate = profLocDate(idDesc);
idAsc = find(profDir == 'A');
o_ascProfNum = profNum(idAsc);
o_ascProfDate = profDate(idAsc);
o_ascProfLocDate = profLocDate(idAsc);

return

% ------------------------------------------------------------------------------
% Retrieve information on profile of a mono-profile NetCDF file.
%
% SYNTAX :
%  [o_profDate, o_profLocDate, o_profLon, o_profLat, ...
%    o_profMode, o_profCut, o_profNbLevels, o_fileVersion, o_dataStr, o_paramStr] = ...
%    get_nc_profile_info(a_profFilePathName, a_dataFlag)
%
% INPUT PARAMETERS :
%   a_profFilePathName : NetCDF file path name
%   a_dataFlag         : flag to retrieve also data measurements
%
% OUTPUT PARAMETERS :
%   o_profDate     : profile date
%   o_profLocDate  : profile location date
%   o_profLon      : profile longitude
%   o_profLat      : profile latitude
%   o_profMode     : profile mode
%   o_profCut      : cut profile flag
%   o_profNbLevels : number of levels of the profile
%   o_fileVersion  : NetCDF file format version
%   o_dataStr      : profile data measurements
%   o_paramStr     : param names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/26/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profDate, o_profLocDate, o_profLon, o_profLat, ...
   o_profMode, o_profCut, o_profNbLevels, o_fileVersion, o_dataStr, o_paramStr] = ...
   get_nc_profile_info(a_profFilePathName, a_dataFlag)
         
% output parameters initialization
o_profDate = [];
o_profLocDate = [];
o_profLon = [];
o_profLat = [];
o_profMode = [];
o_profCut = [];
o_profNbLevels = [];
o_fileVersion = [];
o_dataStr = [];
o_paramStr = [];

% default values
global g_dateDef;


% read the file and retrieve wanted information
if (exist(a_profFilePathName, 'file') == 2)
   
   % file Id for possible b file
   fCdfB = '';

   % open NetCDF file
   fCdf = netcdf.open(a_profFilePathName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_profFilePathName);
      return
   end
   
   % retrieve information
   if (var_is_present(fCdf, 'JULD') && ...
         var_is_present(fCdf, 'JULD_LOCATION') && ...
         var_is_present(fCdf, 'LONGITUDE') && ...
         var_is_present(fCdf, 'LATITUDE') && ...
         var_is_present(fCdf, 'DATA_MODE') && ...
         var_is_present(fCdf, 'FORMAT_VERSION') && ...
         var_is_present(fCdf, 'VERTICAL_SAMPLING_SCHEME'))
      
      julD = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'));
      julDFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD'), '_FillValue');
      julD(find(julD == julDFillVal)) = g_dateDef;
      
      julDLocation = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'));
      julDLocationFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), '_FillValue');
      julDLocation(find(julDLocation == julDLocationFillVal)) = g_dateDef;
      
      longitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'));
      
      latitude = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'));
      
      dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'));
      
      version = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'))');
      
      verticalSamplingScheme = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'VERTICAL_SAMPLING_SCHEME'))';
      vssList = [];
      for idProf = 1:size(verticalSamplingScheme, 1)
         vssList{end+1} = deblank(verticalSamplingScheme(idProf, :));
      end
      
      % collect the station parameter list
      primaryId = -1;
      nearSurfaceId = -1;
      stationParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));
      [~, nParam, nProf] = size(stationParameters);
      paramForProf = [];
      for idProf = 1:nProf
         o_profCut(idProf) = 0;
         if (strncmp(vssList{idProf}, 'Primary sampling:', length('Primary sampling:')))
            primaryId = idProf;
         end
         if (strncmp(vssList{idProf}, 'Near-surface sampling:', length('Near-surface sampling:')))
            nearSurfaceId = idProf;
            o_profCut(idProf) = 1;
         end
         for idParam = 1:nParam
            paramForProf{idProf, idParam} = deblank(stationParameters(:, idParam, idProf)');
         end
      end
      
      if (length(unique(julD)) ~= 1)
         fprintf('ERROR: multiple profiles in file: %s\n', a_profFilePathName);
         return
      end
         
      % output parameters
      o_profDate = julD;
      o_profLocDate = julDLocation;
      o_profLon = longitude;
      o_profLat = latitude;
      o_profMode = dataMode;
      o_fileVersion = version;

      if (a_dataFlag == 1)
         
         % consider also b file if exists
         [pathstr, name, ext] = fileparts(a_profFilePathName);
         bProfFilePathNames = dir([pathstr '/B*' name(2:end) ext]);
         if (~isempty(bProfFilePathNames))
            
            bProfFilePathName = [pathstr '/' bProfFilePathNames(1).name];
            
            % open NetCDF file
            fCdfB = netcdf.open(bProfFilePathName, 'NC_NOWRITE');
            if (isempty(fCdfB))
               fprintf('ERROR: Unable to open NetCDF input file: %s\n', bProfFilePathName);
               return
            end
         
            % collect the station parameter list
            stationParameters = netcdf.getVar(fCdfB, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));
            [~, nParam, nProfBfile] = size(stationParameters);
            if (nProfBfile ~= nProf)
               fprintf('ERROR: N_PROF in C file (%d) differ from N_PROF in B file (%d)\n', nProf, nProfBfile);
               return
            end
            for idProf = 1:nProf
               for idParam = 1:nParam
                  paramName = deblank(stationParameters(:, idParam, idProf)');
                  if (~isempty(paramName))
                     if (~strcmp(paramName, 'PRES'))
                        paramForProf{idProf, end+1} = paramName;
                     end
                  end
               end
            end
         end
         
         % clean empty parameter names
         paramForProf2 = [];
         for idProf = 1:nProf
            paramNames = paramForProf(idProf, :);
            paramNames(find(cellfun(@(x) isempty(x), paramNames))) = [];
            paramForProf2{idProf} = paramNames;
            paramStr = sprintf('%s, ', paramNames{:});
            paramStr(end-1:end) = [];
            o_paramStr{idProf} = paramStr;
         end

         % collect parameter data
         dataFormat = [];
         dataFillValue = [];
         data = [];
         for idProf = 1:length(paramForProf2)
            paramList = paramForProf2{idProf};
            formatList = [];
            fillValueList = [];
            dataParam = [];
            for idParam = 1:length(paramList)
               paramStr = paramList{idParam};
               
               if (ismember(paramStr, [{'PRES'} {'TEMP'} {'PSAL'}]))
                  paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramStr));
                  paramFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramStr), 'C_format');
                  paramFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramStr), '_FillValue');
               else
                  paramData = netcdf.getVar(fCdfB, netcdf.inqVarID(fCdfB, paramStr));
                  paramFormat = netcdf.getAtt(fCdfB, netcdf.inqVarID(fCdfB, paramStr), 'C_format');
                  paramFillVal = netcdf.getAtt(fCdfB, netcdf.inqVarID(fCdfB, paramStr), '_FillValue');
               end
               
               if (~strcmp(paramStr, 'UV_INTENSITY_NITRATE'))
                  formatList = [formatList ' ' paramFormat];
                  fillValueList = [fillValueList paramFillVal];
                  dataParam = [dataParam paramData(:, idProf)];
               else
                  [nValues, ~, ~] = size(paramData);
                  formatList = [formatList repmat([' ' paramFormat], 1, nValues)];
                  fillValueList = [fillValueList repmat(paramFillVal, 1, nValues)];
                  dataParam = [dataParam paramData(:, :, idProf)'];
               end
            end
            
            dataFormat{idProf} = formatList;
            dataFillValue{idProf} = fillValueList;
            data{idProf} = dataParam;
         end
         for idProf = 1:length(data)
            profFillValue = dataFillValue{idProf};
            profData = data{idProf};
            idToDel = [];
            for idLev = 1:size(profData, 1)
               profDataLev = profData(idLev, :);
               if (~any(profDataLev ~= profFillValue))
                  idToDel = [idToDel; idLev];
               end
            end
            profData(idToDel, :) = [];
            data{idProf} = profData;
            o_profNbLevels(idProf) = size(profData, 1);
         end
         
         % report parameter data as string
         dataStr = [];
         for idProf = 1:length(data)
            profFormat = dataFormat{idProf};
            profData = data{idProf};
            profDataStr = [];
            for idLev = 1:size(profData, 1)
               profDataLev = profData(idLev, :);
               profDataLevStr = sprintf(profFormat, profDataLev);
               if (~isempty(profDataStr) && (length(profDataLevStr) ~= size(profDataStr, 2)))
                  nbCol = size(profDataStr, 2) - length(profDataLevStr);
                  if (length(profDataLevStr) < size(profDataStr, 2))
                     profDataLevStr = [repmat(' ', 1, nbCol) profDataLevStr];
                  else
                     profDataStr = [repmat(' ', size(profDataStr, 1), -nbCol) profDataStr];
                  end
               end
               profDataStr = [profDataStr; profDataLevStr];
            end
            dataStr{idProf} = profDataStr;
         end

         o_dataStr = dataStr;
      
      end
      
   else
      
      if (~var_is_present(fCdf, 'JULD'))
         fprintf('WARNING: Variable JULD not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'JULD_LOCATION'))
         fprintf('WARNING: Variable JULD_LOCATION not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'LONGITUDE'))
         fprintf('WARNING: Variable LONGITUDE not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'LATITUDE'))
         fprintf('WARNING: Variable LATITUDE not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'DATA_MODE'))
         fprintf('WARNING: Variable DATA_MODE not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'FORMAT_VERSION'))
         fprintf('WARNING: Variable FORMAT_VERSION not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'VERTICAL_SAMPLING_SCHEME'))
         fprintf('WARNING: Variable VERTICAL_SAMPLING_SCHEME not present in file : %s\n', ...
            a_profFilePathName);
      end
   end
   
   if (~isempty(fCdfB))
      netcdf.close(fCdfB);
   end
   netcdf.close(fCdf);
   
else
   fprintf('ERROR: file not found: %s\n', a_profFilePathName);
end

return

% ------------------------------------------------------------------------------
% Check if a variable (defined by its name) is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : exist flag (1 if exists, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/26/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar= 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break
   end
end

return

% ------------------------------------------------------------------------------
% Convert a julian 1950 date to a gregorian date.
%
% SYNTAX :
%   [o_gregorianDate] = julian_2_gregorian(a_julDay)
%
% INPUT PARAMETERS :
%   a_julDay : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_gregorianDate : gregorain date (in 'yyyy/mm/dd HH:MM' or 
%                     'yyyy/mm/dd HH:MM:SS' format)
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_gregorianDate] = julian_2_gregorian(a_julDay)

% default values
global g_dateDef;

% output parameters initialization
o_gregorianDate = [];

[dayNum, dd, mm, yyyy, HH, MI, SS] = format_juld(a_julDay);

for idDate = 1:length(dayNum)
   if (a_julDay(idDate) ~= g_dateDef)
      o_gregorianDate = [o_gregorianDate; sprintf('%04d/%02d/%02d %02d:%02d:%02d', ...
         yyyy(idDate), mm(idDate), dd(idDate), HH(idDate), MI(idDate), SS(idDate))];
   else
      o_gregorianDate = [o_gregorianDate; '9999/99/99 99:99:99'];
   end
end

return

% ------------------------------------------------------------------------------
% Split of a julian 1950 date in gregorian date parts.
%
% SYNTAX :
%   [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld(a_juld)
%
% INPUT PARAMETERS :
%   a_juld : julian 1950 date
%
% OUTPUT PARAMETERS :
%   o_dayNum : julian 1950 day number
%   o_day    : gregorian day
%   o_month  : gregorian month
%   o_year   : gregorian year
%   o_hour   : gregorian hour
%   o_min    : gregorian minute
%   o_sec    : gregorian second
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/02/2010 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dayNum, o_day, o_month, o_year, o_hour, o_min, o_sec] = format_juld(a_juld)
 
% output parameters initialization
o_dayNum = []; 
o_day = []; 
o_month = []; 
o_year = [];   
o_hour = [];   
o_min = [];
o_sec = [];

% default values
global g_dateDef;
global g_janFirst1950InMatlab;


for id = 1:length(a_juld)
   juldStr = num2str(a_juld(id), 11);
   res = sscanf(juldStr, '%5d.%6d');
   o_day(id) = res(1);
   
   if (o_day(id) ~= fix(g_dateDef))
      o_dayNum(id) = fix(a_juld(id));
      
      dateNum = o_day(id) + g_janFirst1950InMatlab;
      ymd = datestr(dateNum, 'yyyy/mm/dd');
      res = sscanf(ymd, '%4d/%2d/%d');
      o_year(id) = res(1);
      o_month(id) = res(2);
      o_day(id) = res(3);

      hms = datestr(a_juld(id), 'HH:MM:SS');
      res = sscanf(hms, '%d:%d:%d');
      o_hour(id) = res(1);
      o_min(id) = res(2);
      o_sec(id) = res(3);
   else
      o_dayNum(id) = 99999;
      o_day(id) = 99;
      o_month(id) = 99;
      o_year(id) = 9999;
      o_hour(id) = 99;
      o_min(id) = 99;
      o_sec(id) = 99;
   end
   
end

return
