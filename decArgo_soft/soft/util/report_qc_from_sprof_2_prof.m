% ------------------------------------------------------------------------------
% Study the ability and restrictions while reporting QCs from S-PROF to PROF.
%
% SYNTAX :
%   report_qc_from_sprof_2_prof(6900189, 7900118)
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
%   09/11/2023 - RNU - creation
% ------------------------------------------------------------------------------
function report_qc_from_sprof_2_prof(varargin)

% list of floats to process (if empty, all encountered files of the DIR_INPUT_NC_FILES directory will be processed)
FLOAT_LIST_FILE_NAME = '';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_tmp.txt';

% top directory of input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\TEST_REPORT_QC_SPROF_PROF\';
DIR_INPUT_NC_FILES = 'G:\argo_snapshot_202309\coriolis\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';


% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the CSV file
DIR_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\csv\';

% default values initialization
init_default_values;

% measurement codes initialization
init_measurement_codes;

% statistics
global g_result;
global g_resultAll;
g_result = [];
g_result.PARAM_LIST = [];
g_resultAll = [];
g_resultAll.PARAM_LIST = [];


if (nargin == 0)

   if (isempty(FLOAT_LIST_FILE_NAME))

      % all the floats of the DIR_INPUT_NC_FILES directory should be processed
      floatList = [];
      dirNames = dir([DIR_INPUT_NC_FILES '/*']);
      for idDir = 1:length(dirNames)

         dirName = dirNames(idDir).name;
         dirPathName = [DIR_INPUT_NC_FILES '/' dirName];

         if (isdir(dirPathName))
            if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
               floatList = [floatList; str2num(dirName)];
            end
         end
      end
   else
      floatListFileName = FLOAT_LIST_FILE_NAME;

      % floats to process come from floatListFileName
      if ~(exist(floatListFileName, 'file') == 2)
         fprintf('ERROR: File not found: %s\n', floatListFileName);
         return
      end

      fprintf('Floats from list: %s\n', floatListFileName);
      floatList = load(floatListFileName);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

% create and start log file recording
if (nargin == 0)
   if (isempty(FLOAT_LIST_FILE_NAME))
      name = '';
   else

      [pathstr, name, ext] = fileparts(floatListFileName);
      name = ['_' name];
   end
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'report_qc_from_sprof_2_prof' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
     
   floatNum = floatList(idFloat);
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);

   floatDir = [DIR_INPUT_NC_FILES '/' floatNumStr '/'];

   if (exist(floatDir, 'dir') == 7)
      
      % META data file
      metaFileName = [floatDir '/' floatNumStr '_meta.nc'];

      if ~(exist(metaFileName, 'file') == 2)
         fprintf('ERROR: Float %d: META file not found: %s\n', floatNum, metaFileName);
         return
      end

      % create the list of available cycle numbers (from PROF files)
      profileDir = [floatDir '/profiles'];
      files = dir([profileDir '/' '*' floatNumStr '_' '*.nc']);
      cyNumList = [];
      bgcFloatFlag = 0;
      for idFile = 1:length(files)
         fileName = files(idFile).name;
         if (fileName(1) == 'B')
            bgcFloatFlag = 1;
         end
         if (ismember(fileName(1), 'DRB'))
            idF = strfind(fileName, floatNumStr);
            cyNumStr = fileName(idF+length(floatNumStr)+1:end-3);
            if (cyNumStr(end) == 'D')
               cyNumStr(end) = [];
            end
            cyNumList = [cyNumList str2num(cyNumStr)];
         end
      end
      cyNumList = unique(cyNumList);

      % process PROF files
      for idCy = 1:length(cyNumList)

         cycleNum = cyNumList(idCy);
         cycleNumStr = num2str(cycleNum);

         % process descending and ascending profiles
         for idDir = 1:2

            if (idDir == 1)
               cycleDir = 'D';
            else
               cycleDir = '';
            end

            cProfFileName = '';
            bProfFileName = '';
            sProfFileName = '';
            if (exist([profileDir '/' sprintf('D%d_%03d%c.nc', floatNum, cycleNum, cycleDir)], 'file') == 2)
               cProfFileName = [profileDir '/' sprintf('D%d_%03d%c.nc', floatNum, cycleNum, cycleDir)];
            elseif (exist([profileDir '/' sprintf('R%d_%03d%c.nc', floatNum, cycleNum, cycleDir)], 'file') == 2)
               cProfFileName = [profileDir '/' sprintf('R%d_%03d%c.nc', floatNum, cycleNum, cycleDir)];
            end
            if (exist([profileDir '/' sprintf('BD%d_%03d%c.nc', floatNum, cycleNum, cycleDir)], 'file') == 2)
               bProfFileName = [profileDir '/' sprintf('BD%d_%03d%c.nc', floatNum, cycleNum, cycleDir)];
            elseif (exist([profileDir '/' sprintf('BR%d_%03d%c.nc', floatNum, cycleNum, cycleDir)], 'file') == 2)
               bProfFileName = [profileDir '/' sprintf('BR%d_%03d%c.nc', floatNum, cycleNum, cycleDir)];
            end
            if (exist([profileDir '/' sprintf('SD%d_%03d%c.nc', floatNum, cycleNum, cycleDir)], 'file') == 2)
               sProfFileName = [profileDir '/' sprintf('SD%d_%03d%c.nc', floatNum, cycleNum, cycleDir)];
            elseif (exist([profileDir '/' sprintf('SR%d_%03d%c.nc', floatNum, cycleNum, cycleDir)], 'file') == 2)
               sProfFileName = [profileDir '/' sprintf('SR%d_%03d%c.nc', floatNum, cycleNum, cycleDir)];
            end

            if (~isempty(cProfFileName) && ~isempty(sProfFileName))

               fprintf('   %02d/%02d: Float #%d Cycle #%d%c\n', ...
                  idCy, length(cyNumList), floatNum, cycleNum, cycleDir);

               % check QC report for one profile cycle and direction
               check_qc_report( ...
                  cProfFileName, bProfFileName, sProfFileName, metaFileName, ...
                  floatNum, cycleNum, DIR_CSV_FILE);
            end
         end
      end

      % fprintf('\n');

      for idP = 1:length(g_result.PARAM_LIST)
         paramName = g_result.PARAM_LIST{idP};
         nbMeasLink = g_result.([paramName '_link']);
         nbMeasLink0 = g_result.([paramName '_link0']);
         nbProfMeas = g_result.([paramName '_tot']);

         fprintf('INFO: %s : %d/%d/%d - %.1f%%/%.1f%%\n', ...
            paramName, nbMeasLink, nbMeasLink0, nbProfMeas, (nbMeasLink*100)/nbProfMeas, (nbMeasLink0*100)/nbProfMeas);

         if (~ismember(paramName, g_resultAll.PARAM_LIST))
            g_resultAll.PARAM_LIST{end+1} = paramName;
            g_resultAll.([paramName '_link']) = nbMeasLink;
            g_resultAll.([paramName '_link0']) = nbMeasLink0;
            g_resultAll.([paramName '_tot']) = nbProfMeas;
         else
            g_resultAll.([paramName '_link']) = g_resultAll.([paramName '_link']) + nbMeasLink;
            g_resultAll.([paramName '_link0']) = g_resultAll.([paramName '_link0']) + nbMeasLink0;
            g_resultAll.([paramName '_tot']) = g_resultAll.([paramName '_tot']) + nbProfMeas;
         end
      end

      g_result = [];
      g_result.PARAM_LIST = [];
   end
end

fprintf('\n');
for idP = 1:length(g_resultAll.PARAM_LIST)
   paramName = g_resultAll.PARAM_LIST{idP};
   nbMeasLink = g_resultAll.([paramName '_link']);
   nbMeasLink0 = g_resultAll.([paramName '_link0']);
   nbProfMeas = g_resultAll.([paramName '_tot']);

   fprintf('INFO: %s : %d/%d/%d - %.1f%%/%.1f%%\n', ...
      paramName, nbMeasLink, nbMeasLink0, nbProfMeas, (nbMeasLink*100)/nbProfMeas, (nbMeasLink0*100)/nbProfMeas);
end
   
ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Generate one synthetic profile from one C and one B mono-profile files.
%
% SYNTAX :
%  nc_create_synthetic_profile_( ...
%    a_createOnlyMultiProfFlag, ...
%    a_cProfFileName, a_bProfFileName, a_metaFileName, ...
%    a_createMultiProfFlag, ...
%    a_outputDir, ...
%    a_monoProfRefFile, a_multiProfRefFile, ...
%    a_tmpDir)
%
% INPUT PARAMETERS :
%   a_createOnlyMultiProfFlag : generate only S multi-profile file flag
%   a_cProfFileName           : input C prof file path name
%   a_bProfFileName           : input B prof file path name
%   a_metaFileName            : input meta file path name
%   a_createMultiProfFlag     : generate S multi-prof flag
%   a_outputDir               : output S prof file directory
%   a_monoProfRefFile         : netCDF synthetic mono-profile file schema
%   a_multiProfRefFile        : netCDF synthetic multi-profile file schema
%   a_tmpDir                  : base name of the temporary directory
%   a_bgcFloatFlag            : 1 if it is a BGC float, 0 otherwise
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/11/2023 - RNU - creation
% ------------------------------------------------------------------------------
function check_qc_report( ...
   a_cProfFileName, a_bProfFileName, a_sProfFileName, a_metaFileName, ...
   a_floatNum, a_cycleNum, a_csvOutputDir)

% statistics
global g_result;


% retrieve PROF and S-PROF data
cProfData = get_prof_data(a_cProfFileName, 1);
bProfData = get_prof_data(a_bProfFileName, 2);
sProfData = get_prof_data(a_sProfFileName, 3);

% retrieve vertical offsets
bProfData = get_vertical_offset(a_metaFileName, bProfData);

% try to link S-PROF measurements with PROF ones
profId = [];
paramList = sProfData.PARAM_LIST{:};
for idParam = 1:length(paramList)
   paramName = paramList{idParam};
   if (strcmp(paramName, 'PRES'))
      continue
   end

   % if (~strcmp(paramName, 'TEMP'))
   %    continue
   % end

   paramInfo = get_netcdf_param_attributes(paramName);
   
   sData = sProfData.(paramName);
   sPres = sProfData.PRES;
   sDPres = sProfData.([paramName '_dPRES']);
   link = [(1:length(sData))' sDPres nan(length(sData), 3)];

   if (ismember(paramInfo.paramType, 'ib'))
      profData = bProfData.(paramName);
      profPres = bProfData.PRES;
      profPresOffset = bProfData.PRES_OFFSET;
      profPresOffset(isnan(profPresOffset)) = 0;
      % when DOXY2 is measured by a PTSO float, it is provided in the same
      % N_PROF as the DOXY measurements, however, the OPTODE_DOXY vertical
      % offset should not be used, use a vertical offset of 0
      % this should not happen in a BGC float where DOXY2 is provided on its own
      % N_PROF
      if (strcmp(paramName, 'DOXY2') && (size(profData, 2) == 2))
         profPresOffset = zeros(size(profPresOffset));
      end
   else
      profData = cProfData.(paramName);
      profPres = cProfData.PRES;
      profPresOffset = zeros(1, size(cProfData.PRES, 2));
   end

   idNoDefS = find(sData ~= paramInfo.fillValue);
   for idL1 = idNoDefS'

      % if (idL1 == 1372)
      %    a=1
      % end

      sDataVal = sData(idL1);
      sPresVal = round(double(sPres(idL1))*1000)/1000;
      sDPresVal = round(double(sDPres(idL1))*1000)/1000;
      % if (sDPresVal ~= 0)
      %    continue
      % end

      profId = [];
      for idProf = 1:size(profData, 2)
         if (any(profData(:, idProf) ~= paramInfo.fillValue))
            profId = [profId idProf];
         end
      end
      profId = unique(profId);
      % if (~ismember(paramInfo.paramType, 'ib'))
      %    profId(find(profId > 2)) = []; % PTS profile associated to SUNA data
      % end

      found = 0;
      for idProf = profId
         profIdData = profData(:, idProf);
         profIdPres = round(double(profPres(:, idProf))*1000)/1000;
         presOffset = round(profPresOffset(idProf)*1000)/1000;
         sPresValComp = round((double(sPresVal) - presOffset)*1000)/1000;

         profIdPres2 = round((profIdPres + presOffset)*1000)/1000;
         sPresValComp2 = round((sPresVal + sDPresVal)*1000)/1000;

         idNoDef = find(profIdData ~= paramInfo.fillValue);
         for idL2 = idNoDef'
            % if (idL2 == 226)
            %    a=1
            % end
            if (sDPresVal == 0)
               if ((profIdData(idL2) == sDataVal) && (profIdPres(idL2) == sPresValComp))
                  link(idL1, 3) = idProf;
                  link(idL1, 4) = idL2;
                  idF = find((profIdData == sDataVal) & (profIdPres == sPresValComp));
                  link(idL1, 5) = length(idF);
                  % if (length(idF) > 1)
                  %    fprintf('WARNING: %d levels match\n', length(idF));
                  % end
                  found = 1;
                  break
               end
            else
               if (profIdPres2(idL2) == sPresValComp2)
                  link(idL1, 3) = idProf;
                  link(idL1, 4) = idL2;
                  idF = find(profIdPres2 == sPresValComp2);
                  link(idL1, 5) = length(idF);
                  % if (length(idF) > 1)
                  %    fprintf('WARNING: %d levels match\n', length(idF));
                  % end
                  found = 1;
                  break
               end
            end
         end
         if (found)
            break
         end
      end

      if (~found)
         fprintf('ERROR: Float %d Cycle %d: S-PROF measurement #%d of ''%s'' not linked (N_LEVEL = %d)\n', ...
            a_floatNum, a_cycleNum, idL1, paramName, size(profData, 1));
      end
   end

   % number of profile measurements
   if (~isempty(profId))
      nbProfMeas = 0;
      for idProf = profId
         profIdData = profData(:, idProf);
         nbProfMeas = nbProfMeas + length(find(profIdData ~= paramInfo.fillValue));
      end

      % number of measurements linked
      idNoNan = find(~isnan(link(:, 5)));
      nbMeasLink = sum(link(idNoNan, 5));

      % number of measurements linked with <PARAM>_dPRES = 0
      idNull = find(link(idNoNan, 2) == 0);
      nbMeasLink0 = sum(link(idNoNan(idNull), 5));
      % fprintf('INFO: %s : %d/%d/%d - %.1f%%/%.1f%%\n', ...
      %    paramName, nbMeasLink, nbMeasLink0, nbProfMeas, (nbMeasLink*100)/nbProfMeas, (nbMeasLink0*100)/nbProfMeas);

      if (~ismember(paramName, g_result.PARAM_LIST))
         g_result.PARAM_LIST{end+1} = paramName;
         g_result.([paramName '_link']) = nbMeasLink;
         g_result.([paramName '_link0']) = nbMeasLink0;
         g_result.([paramName '_tot']) = nbProfMeas;
      else
         g_result.([paramName '_link']) = g_result.([paramName '_link']) + nbMeasLink;
         g_result.([paramName '_link0']) = g_result.([paramName '_link0']) + nbMeasLink0;
         g_result.([paramName '_tot']) = g_result.([paramName '_tot']) + nbProfMeas;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve vertical offsets of each sensor from meta-data file and assign it to
% the concerned profile number.
%
% SYNTAX :
 % [o_bProfData] = get_vertical_offset(a_metaFileName, a_bProfData)
%
% INPUT PARAMETERS :
%   a_metaFileName : meta-data file path name
%   a_bProfData    : input BGC profile data
%
% OUTPUT PARAMETERS :
%   o_bProfData : updated BGC profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/11/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bProfData] = get_vertical_offset(a_metaFileName, a_bProfData)

% output parameter initialization
o_bProfData = a_bProfData;


if (isempty(a_bProfData))
   return
end

% retrieve information from NetCDF meta file
wantedVars = [ ...
   {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
   {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   ];

% retrieve information from NetCDF meta file
[ncMetaData] = get_data_from_nc_file(a_metaFileName, wantedVars);

launchConfigParameterName = [];
idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', ncMetaData) == 1);
if (~isempty(idVal))
   launchConfigParameterNameTmp = ncMetaData{idVal+1}';

   for id = 1:size(launchConfigParameterNameTmp, 1)
      launchConfigParameterName{end+1} = deblank(launchConfigParameterNameTmp(id, :));
   end
end

launchConfigParameterValue = [];
idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', ncMetaData) == 1);
if (~isempty(idVal))
   launchConfigParameterValue = ncMetaData{idVal+1}';
end

parameterMeta = [];
idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
if (~isempty(idVal))
   parameterMetaTmp = ncMetaData{idVal+1}';

   for id = 1:size(parameterMetaTmp, 1)
      parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
   end
end

parameterSensorMeta = [];
idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
if (~isempty(idVal))
   parameterSensorMetaTmp = ncMetaData{idVal+1}';

   for id = 1:size(parameterSensorMetaTmp, 1)
      parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
   end
end

% assign vertical pressure offset to associated N_PROF
o_bProfData.PRES_OFFSET = nan(1, size(o_bProfData.PRES, 2));
idF = cellfun(@(x) strfind(launchConfigParameterName, x), {'VerticalPressureOffset_dbar'}, 'UniformOutput', 0);
idF = find(~cellfun(@isempty, idF{:}) == 1);
for idC = idF
   configName = launchConfigParameterName{idC};
   configValue = launchConfigParameterValue(idC);
   idF1 = strfind(configName, 'VerticalPressureOffset_dbar');
   shortSensorName = lower(configName(8:idF1-1));

   % retrieve sensor name
   switch (shortSensorName)
      case 'crover'
         sensorNameList = [{'TRANSMISSOMETER_CP'}];
      case 'eco'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'FLUOROMETER_CDOM'} {'BACKSCATTERINGMETER_BBP'}];
      case 'flbb'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP'}];
      case 'flntu'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_TURBIDITY'}];
      case 'isus'
         sensorNameList = [{'SPECTROPHOTOMETER_NITRATE'}];
      case 'mcoms'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'FLUOROMETER_CDOM'} {'BACKSCATTERINGMETER_BBP'}];
      case 'ocr'
         sensorNameList = [{'RADIOMETER_DOWN_IRR'} {'RADIOMETER_PAR'}];
      case 'optode'
         sensorNameList = [{'OPTODE_DOXY'}];
      case 'sfet'
         sensorNameList = [{'TRANSISTOR_PH'}];
      case 'suna'
         sensorNameList = [{'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_BISULFIDE'}];
      otherwise
         fprintf('ERROR: Don''t know how to manage short sensor name ''%s'' to assign VerticalPressureOffset_dbar to the concerned profile data - not considered\n', ...
            configName(8:idF1-1));
         continue
   end

   % retrieve associated list of parameters
   paramList = [];
   for idS = 1:length(sensorNameList)
      idF2 = cellfun(@(x) strfind(parameterSensorMeta, x), sensorNameList(idS), 'UniformOutput', 0);
      idF2 = find(~cellfun(@isempty, idF2{:}) == 1);
      for id = idF2
         paramList{end+1} = parameterMeta{id};
      end
   end

   profId = [];
   for idParam = 1:length(paramList)
      if (isfield(a_bProfData, paramList{idParam}))
         paramName = paramList{idParam};
         paramInfo = get_netcdf_param_attributes(paramName);
         data = a_bProfData.(paramName);
         for idProf = 1:size(data, 2)
            if (any(data(:, idProf) ~= paramInfo.fillValue))
               profId = [profId idProf];
            end
         end
      end
   end
   profId = unique(profId);

   if (~isempty(profId))
      o_bProfData.PRES_OFFSET(profId) = configValue;
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve data from profile file.
%
% SYNTAX :
%  [o_profData] = get_prof_data(a_profFileName, a_profFileType)
%
% INPUT PARAMETERS :
%   a_profFileName : profile file path name
%   a_profFileType : profile file type
%
% OUTPUT PARAMETERS :
%   o_profData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/11/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = get_prof_data(a_profFileName, a_profFileType)

% output parameter initialization
o_profData = [];


% retrieve information from PROF file
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'STATION_PARAMETERS'} ...
   ];
[profData1] = get_data_from_nc_file(a_profFileName, wantedVars);

formatVersion = deblank(get_data_from_name('FORMAT_VERSION', profData1)');

% check the PROF file format version
if (a_profFileType == 3) % S-PROF
   if (~strcmp(formatVersion, '1.0'))
      fprintf('ERROR: Input PROF file (%s) format version is %s - not used\n', ...
         a_profFileName, formatVersion);
      return
   end
else
   if (~strcmp(formatVersion, '3.1'))
      fprintf('ERROR: Input PROF file (%s) format version is %s - not used\n', ...
         a_profFileName, formatVersion);
      return
   end
end

% create the list of parameters to be retrieved from PROF file
wantedVars = [];

% add parameter measurements
stationParameters = get_data_from_name('STATION_PARAMETERS', profData1);
parameterList = [];
parameterList2 = [];
[~, nParam, nProf] = size(stationParameters);
for idProf = 1:nProf
   profParamList = [];
   for idParam = 1:nParam
      paramName = deblank(stationParameters(:, idParam, idProf)');
      if (~isempty(paramName))
         paramInfo = get_netcdf_param_attributes(paramName);
         if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'b'))
            profParamList{end+1} = paramName;
            parameterList2{end+1} = paramName;
            wantedVars = [wantedVars ...
               {paramName} ...
               {[paramName '_QC']} ...
               {[paramName '_ADJUSTED']} ...
               {[paramName '_ADJUSTED_QC']} ...
               {[paramName '_ADJUSTED_ERROR']} ...
               ];
            if (a_profFileType == 3) % S-PROF
               wantedVars = [wantedVars ...
                  {[paramName '_dPRES']} ...
                  ];
            end
         end
      end
   end
   parameterList = [parameterList; {profParamList}];
end

% retrieve information from PROF file
[profData2] = get_data_from_nc_file(a_profFileName, wantedVars);

% store data into output structure
o_profData.PARAM_LIST = unique(parameterList2, 'stable');
o_profData.PARAM_LIST = parameterList;
for idP = 1:2:length(profData2)
   o_profData.(profData2{idP}) = profData2{idP+1};
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
%   06/15/2018 - RNU - creation
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
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {' '}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return
