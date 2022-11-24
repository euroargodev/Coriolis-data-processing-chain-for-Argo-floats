% ------------------------------------------------------------------------------
% Retrieve min and max values of float profile files.
%
% SYNTAX :
%   nc_get_profile_max_pressure ou nc_get_profile_max_pressure(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : éventuellement la liste des numéros de flotteurs à traiter
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/24/2019 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_profile_max_pressure(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT\';
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT_from_DEP\';

% directory to store the log and CSV file
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_all.txt';

% default values initialization
init_default_values;


% input parameters management
if (nargin == 0)
   % floats to process come from FLOAT_LIST_FILE_NAME
   floatListFileName = FLOAT_LIST_FILE_NAME;
   if ~(exist(floatListFileName, 'file') == 2)
      fprintf('ERROR: File not found: %s\n', floatListFileName);
      return
   end
   
   fprintf('Floats from list: %s\n', floatListFileName);
   floatList = textread(floatListFileName, '%d');
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

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_profile_max_pressure' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_profile_max_pressure'  name '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   return
end
header = 'WMO;FILE;N_PROF;CY_NUM;DIR;MODE;MIN_PRES;MIN_PRES_QC;MAX_PRES;MAX_PRES_QC';
fprintf(fidOut, '%s\n', header);

paramPres = get_netcdf_param_attributes_3_1('PRES');

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
      
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % retrieve information from NetCDF V3.1 mono-profile file
   monoProfDirName = [DIR_INPUT_NC_FILES sprintf('/%d/profiles/', floatNum)];
   monoProfFileName = [monoProfDirName sprintf('*%d_*.nc', floatNum)];
   monoProfFiles = dir(monoProfFileName);
   for idFile = 1:length(monoProfFiles)
      
      fileName = monoProfFiles(idFile).name;
      if (fileName(1) == 'B')
         continue
      end
      profFileName = [monoProfDirName fileName];
            
      % retrieve information from PROF file
      wantedVars = [ ...
         {'FORMAT_VERSION'} ...
         {'DATA_MODE'} ...
         {'CYCLE_NUMBER'} ...
         {'DIRECTION'} ...
         {'PRES'} ...
         {'PRES_QC'} ...
         {'PRES_ADJUSTED'} ...
         {'PRES_ADJUSTED_QC'} ...
         ];
      [profData] = get_data_from_nc_file(profFileName, wantedVars);
      
      idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
      formatVersion = strtrim(profData{2*idVal}');
      if (~strcmp(formatVersion, '3.1'))
         fprintf('\n');
         fprintf('ERROR: Float #%d: Bad mono-profile file format version (%s)\n', ...
            floatNum, formatVersion);
         continue
      end
      
      idVal = find(strcmp('DATA_MODE', profData(1:2:end)) == 1, 1);
      dataMode = profData{2*idVal};
      idVal = find(strcmp('CYCLE_NUMBER', profData(1:2:end)) == 1, 1);
      cycleNumber = profData{2*idVal};
      idVal = find(strcmp('DIRECTION', profData(1:2:end)) == 1, 1);
      direction = profData{2*idVal};
      idVal = find(strcmp('PRES', profData(1:2:end)) == 1, 1);
      pres = profData{2*idVal};
      idVal = find(strcmp('PRES_QC', profData(1:2:end)) == 1, 1);
      presQc = profData{2*idVal};
      idVal = find(strcmp('PRES_ADJUSTED', profData(1:2:end)) == 1, 1);
      presAdj = profData{2*idVal};
      idVal = find(strcmp('PRES_ADJUSTED_QC', profData(1:2:end)) == 1, 1);
      presAdjQc = profData{2*idVal};

      for idProf = 1:length(dataMode)
         
         if (dataMode(idProf) == 'R')
            profPres = pres(:, idProf);
            profPresQc = presQc(:, idProf);
            idPresOk = find((profPres ~= paramPres.fillValue) & (profPresQc ~= '4'));
            [profPresMin, idMin] = min(profPres(idPresOk));
            profPresMinQc = profPresQc(idPresOk(idMin));
            [profPresMax, idMax] = max(profPres(idPresOk));
            profPresMaxQc = profPresQc(idPresOk(idMax));
         else
            profPres = presAdj(:, idProf);
            profPresQc = presAdjQc(:, idProf);
            idPresOk = find((profPres ~= paramPres.fillValue) & (profPresQc ~= '4'));
            [profPresMin, idMin] = min(profPres(idPresOk));
            profPresMinQc = profPresQc(idPresOk(idMin));
            [profPresMax, idMax] = max(profPres(idPresOk));
            profPresMaxQc = profPresQc(idPresOk(idMax));
         end
         
         fprintf(fidOut, '%d;%s;%d;%d;%c;%c;%.1f;%c;%.1f;%c\n', ...
            floatNum, fileName, idProf, cycleNumber(idProf), direction(idProf), dataMode(idProf), ...
            profPresMin, profPresMinQc, profPresMax, profPresMaxQc);
         
      end
   end
end

fclose(fidOut);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return
