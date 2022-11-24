% ------------------------------------------------------------------------------
% Generate NetCDF mono_profile files (V3.1) from a DEP file.
%
% SYNTAX :
%   nc_create_apx_mono_profile_argos_from_dep or
%   nc_create_apx_mono_profile_argos_from_dep(6900189, 7900118)
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
function nc_create_apx_mono_profile_argos_from_dep(varargin)

% top directory of input DEP files
DIR_INPUT_DEP_FILES = 'C:\Users\jprannou\_DATA\juste_dep\DEP_final_apres_update_2017\';

% top directory of output NetCDF mono-profile files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\Conversion_en_3.1\OUT_from_DEP\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% default list of floats to process
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_all.txt';
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_pts_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_bgc_all.txt';
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\list\Apex_34.txt';

% json meta-data file directory
DIR_JSON_META_FILE = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\ConvertApexOldVersionsTo3.1\json_float_meta\';

% reference files
refNcFileName1 = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoProf_V3.1_cfile_part1.nc';
refNcFileName2 = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util\misc/ArgoProf_V3.1_cfile_part2.nc';

% program version
global g_cogd_ncGeneratedFromDepFile;
g_cogd_ncGeneratedFromDepFile = '1.0';

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

% check the reference files
if ~(exist(refNcFileName1, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', refNcFileName1);
   return
end
if ~(exist(refNcFileName2, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', refNcFileName2);
   return
end

% create and start log file recording
if (nargin == 0)
   [pathstr, name, ext] = fileparts(floatListFileName);
   name = ['_' name];
else
   name = sprintf('_%d', floatList);
end

logFile = [DIR_LOG_FILE '/' 'nc_create_apx_mono_profile_argos_from_dep' name '_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   Input files directory: %s\n', DIR_INPUT_DEP_FILES);
fprintf('   Output files directory: %s\n', DIR_OUTPUT_NC_FILES);
fprintf('   Log file directory: %s\n', DIR_LOG_FILE);
if (nargin == 0)
   fprintf('   List of floats to process: %s\n', FLOAT_LIST_FILE_NAME);
else
   fprintf('   Floats to process:');
   fprintf(' %d', floatList);
   fprintf('\n');
end
fprintf('   Json meta-data directory: %s\n', DIR_JSON_META_FILE);
fprintf('   Reference file for mono-profile NetCDF file (part #1): %s\n', refNcFileName1);
fprintf('   Reference file for mono-profile NetCDF file (part #2): %s\n', refNcFileName2);

% retrieve reference file schema
refFileSchema = ncinfo(refNcFileName1);
refFileSchema = [refFileSchema ncinfo(refNcFileName2)];

% process the floats
nbFloats = length(floatList);
for idFloat = 1:nbFloats
   
   floatNum = floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   [profileData] = get_dep_profile_data(DIR_INPUT_DEP_FILES, floatNum);
   if (~isempty(profileData))
      
      % retrieve needed meta-data from meta.nc file
      metaDataFilePathName = [DIR_OUTPUT_NC_FILES sprintf('/%d/%d_meta.nc', floatNum, floatNum)];
      jsonInputFileName = [DIR_JSON_META_FILE '/' sprintf('%d_meta.json', floatNum)];
      [profMetaData, configMetaData] = get_meta_data(metaDataFilePathName, jsonInputFileName);
      if (~isempty(profMetaData))
         
         % generate profile files
         for idProf = 1:length(profileData)
            [ok, comment, outputFilePathName] = create_profile_file( ...
               profileData(idProf), DIR_OUTPUT_NC_FILES, floatNum, ...
               refFileSchema, profMetaData, configMetaData);
            if (ok == 1)
               apply_rtqc(floatNum, outputFilePathName, metaDataFilePathName);
            else
               fprintf('%s\n', comment);
            end
         end
      else
         fprintf('ERROR: Meta-data not found for float #%d\n', floatNum);
      end
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve profile information and data from a DEP file.
%
% SYNTAX :
%  [o_profileData] = get_dep_profile_data(a_inputDirName, a_floatNum)
%
% INPUT PARAMETERS :
%   a_inputDirName : directory of DEP file
%   a_floatNum     : float WMO number
%
% OUTPUT PARAMETERS :
%   o_profileData : profile information and data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profileData] = get_dep_profile_data(a_inputDirName, a_floatNum)

% output parameters initialization
o_profileData = [];

% DEP file default values
global g_dateDef;
global g_latDef;
global g_lonDef;
global g_presDef;
global g_tempDef;
global g_salDef;

% measurement codes of DEP files
global g_typePresOffset;
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
   cycleNumTab = [];
   presOffsetTab = [];
   cycleNumAdjTab = [];
   presOffsetAdjTab = [];
   for idCy = 1:length(cycleList)
      cyNum = cycleList(idCy);
      idForCy = find(depCycle == cyNum);
      
      if (any(depType(idForCy) == g_typePresOffset))
         idF = find(depType(idForCy) == g_typePresOffset);
         if (depPres(idForCy(idF)) ~= g_presDef)
            cycleNumTab(end+1) = cyNum;
            presOffsetTab(end+1) = depPres(idForCy(idF));
         end
      end
      
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
         ordreMeas = depOrdre(idForCy(idF));
         ascPres = depPres(idForCy(idF));
         ascTemp = depTemp(idForCy(idF));
         ascPsal = depSal(idForCy(idF));
         ascOrdre = flipud(ordreMeas);
         ascPres = flipud(ascPres);
         ascTemp = flipud(ascTemp);
         ascPsal = flipud(ascPsal);
         
         if (any(find(diff(ordreMeas) ~= 1)))
            fprintf('ERROR: Check index of measurements in DEP file not found: %s\n', depFilePathName);
         end
      end
      
      if (~isempty(profJuld) && ~isempty(profJuldLoc))
         if (~isempty(ascPres))
            
            paramJuld = get_netcdf_param_attributes('JULD');
            paramLat = get_netcdf_param_attributes('LATITUDE');
            paramLon = get_netcdf_param_attributes('LONGITUDE');
            paramPres = get_netcdf_param_attributes('PRES');
            paramTemp = get_netcdf_param_attributes('TEMP');
            paramPsal = get_netcdf_param_attributes('PSAL');
            
            profJuld(find(profJuld == g_dateDef)) = paramJuld.fillValue;
            profJuldLoc(find(profJuldLoc == g_dateDef)) = paramJuld.fillValue;
            profLat(find(profLat == g_latDef)) = paramLat.fillValue;
            profLon(find(profLon == g_lonDef)) = paramLon.fillValue;
            ascPres(find(ascPres == g_presDef)) = paramPres.fillValue;
            ascTemp(find(ascTemp == g_tempDef)) = paramTemp.fillValue;
            ascPsal(find(ascPsal == g_salDef)) = paramPsal.fillValue;
            
            % select the pressure offset value to use
            prevPresOffset = [];
            idLastCycleStruct = find(cycleNumAdjTab < cyNum, 1, 'last');
            if (~isempty(idLastCycleStruct))
               prevPresOffset = presOffsetAdjTab(idLastCycleStruct);
            end
            
            presOffset = [];
            idCycleStruct = find(cycleNumTab == cyNum);
            if (~isempty(idCycleStruct))
               cyclePresOffset = presOffsetTab(idCycleStruct);
               if (abs(cyclePresOffset) <= 20)
                  if (~isempty(prevPresOffset))
                     if (abs(cyclePresOffset - prevPresOffset) <= 5)
                        presOffset = cyclePresOffset;
                     end
                  else
                     presOffset = cyclePresOffset;
                  end
               else
                  idF = find(ismember(cyNum:-1:cyNum-5, cycleNumTab));
                  if ((length(idF) == 6) && ~any(abs(presOffsetTab(idF)) <= 20))
                     fprintf('WARNING: Float #%d should be put on the grey list because of pressure error\n', ...
                        a_floatNum);
                  end
               end
            end
            if (isempty(presOffset))
               if (~isempty(prevPresOffset))
                  presOffset = prevPresOffset;
               end
            end
                        
            profileData = [];
            profileData.cyNum = cyNum;
            profileData.profJuld = profJuld;
            profileData.profJuldLoc = profJuldLoc;
            profileData.profLat = profLat;
            profileData.profLon = profLon;
            profileData.pres = ascPres;
            profileData.temp = ascTemp;
            profileData.psal = ascPsal;
            profileData.presAdj = [];
            profileData.tempAdj = [];
            profileData.psalAdj = [];
            profileData.presOffset = '';

            if (~isempty(presOffset))
               cycleNumAdjTab(end+1) = cyNum;
               presOffsetAdjTab(end+1) = presOffset;
            
               ascPresAdj = ascPres;
               idNoDef = find(ascPresAdj ~= paramPres.fillValue);
               ascPresAdj(idNoDef) = ascPresAdj(idNoDef) - presOffset;
               profileData.presAdj = ascPresAdj;
               profileData.tempAdj = ascTemp;
               profileData.psalAdj = ascPsal;
               profileData.presOffset = presOffset;
            end
            
            o_profileData = [o_profileData profileData];
         end
      end
   end
else
   fprintf('WARNING: DEP file not found: %s\n', depFilePathName);
end

return

% ------------------------------------------------------------------------------
% Retrieve information from V3.1 nc meta file and JSON meta-data file.
%
% SYNTAX :
%  [o_profMetaData, o_configMetaData] = get_meta_data( ...
%    a_metaDataFilePathName, a_jsonInputFileName)
%
% INPUT PARAMETERS :
%   a_metaDataFilePathName : V3.1 nc meta file path name
%   a_jsonFloatMetaDirName : JSON meta-data file path name
%
% OUTPUT PARAMETERS :
%   o_profMetaData   : retrieved information for profile 
%   o_configMetaData : retrieved information for configuration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profMetaData, o_configMetaData] = get_meta_data( ...
   a_metaDataFilePathName, a_jsonInputFileName)

% output parameters initialization
o_profMetaData = [];
o_configMetaData = [];


if ~(exist(a_metaDataFilePathName, 'file') == 2)
   return
end

% list of variables that will be retrieved from V3.1 meta.nc file to fill the
% V3.1 prof.nc ones
metaVarList = [ ...
   {'PROJECT_NAME'} ...
   {'PI_NAME'} ...
   {'DATA_CENTRE'} ...
   {'PLATFORM_TYPE'} ...
   {'FLOAT_SERIAL_NO'} ...
   {'FIRMWARE_VERSION'} ...
   {'WMO_INST_TYPE'} ...
   {'POSITIONING_SYSTEM'} ...
   ];
[o_profMetaData] = get_data_from_nc_file(a_metaDataFilePathName, metaVarList);

% list of variables that will be used to compute configuration mission
% number
metaVarList = [ ...
   {'DAC_FORMAT_ID'} ...
   {'CONFIG_MISSION_NUMBER'} ...
   ];
[o_configMetaData] = get_data_from_nc_file(a_metaDataFilePathName, metaVarList);

% retrieve CONFIG_REPETITION_RATE from json file
repRate = '';
if (exist(a_jsonInputFileName, 'file') == 2)
   % retrieve REPETITION_RATE from json meta-data file
   wantedMetaNames = [ ...
      {'CONFIG_REPETITION_RATE'} ...
      ];
   [repRateMetaData] = get_meta_data_from_json_file(a_jsonInputFileName, wantedMetaNames);
   repRate = repRateMetaData{2};
else
   fprintf('ERROR: Json meta-data file not found: %s - CONFIG_REPETITION_RATE not found\n', ...
      a_jsonInputFileName);
end
o_configMetaData{end+1} = 'CONFIG_REPETITION_RATE';
o_configMetaData{end+1} = repRate;

return

% ------------------------------------------------------------------------------
% Generate NetCDF mono_profile files (V3.1) from a DEP file.
%
% SYNTAX :
%  [o_ok, o_comment, o_outputFilePathName] = create_profile_file( ...
%    a_profileData, a_outputDirName, a_floatNum, a_refFileSchema, ...
%    a_profMetaData, a_configMetaData)
%
% INPUT PARAMETERS :
%   a_profileData    : profile data
%   a_outputDirName  : mono-profile NetCDF output file directory
%   a_floatNum       : float WMO number
%   a_refFileSchema  : NetCDF schema of the V3.1
%   a_profMetaData   : profile meta-data
%   a_configMetaData : configuration meta-data
%
% OUTPUT PARAMETERS :
%   o_ok                 : success flag (1 if Ok, 0 otherwise)
%   o_comment            : detailed comment (when o_ok = 0)
%   o_outputFilePathName : mono-profile NetCDF output file path name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_comment, o_outputFilePathName] = create_profile_file( ...
   a_profileData, a_outputDirName, a_floatNum, a_refFileSchema, ...
   a_profMetaData, a_configMetaData)

% output parameters initialization
o_ok = 0;
o_comment = [];
o_outputFilePathName = [];

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% program version
global g_cogd_ncGeneratedFromDepFile;


% output file name
outputFilePathName = [a_outputDirName sprintf('/%d/profiles/R%d_%03d.nc', a_floatNum, a_floatNum, a_profileData.cyNum)];

% create the Output file with the updated schema
if (exist(outputFilePathName, 'file') == 2)
   delete(outputFilePathName);
   if (exist(outputFilePathName, 'file') == 2)
      o_comment = sprintf('Cannot remove existing file %s', ...
         outputFilePathName);
      return
   end
else
   outputDirName = [a_outputDirName sprintf('/%d/profiles', a_floatNum)];
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
end

paramlist = [{'PRES'} {'TEMP'} {'PSAL'}];

% update the schema with the Input file dimensions
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_PROF', 1);
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_PARAM', length(paramlist));
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_CALIB', 1);
[a_refFileSchema(1)] = update_dim_in_nc_schema(a_refFileSchema(1), ...
   'N_LEVELS', length(a_profileData.pres));

% update the Output file with the schema
ncwriteschema(outputFilePathName, a_refFileSchema(1));

% open the Output file
fCdf = netcdf.open(outputFilePathName, 'NC_WRITE');
if (isempty(fCdf))
   o_comment = sprintf('ERROR: Unable to open NetCDF input file: %s\n', outputFilePathName);
   return
end

netcdf.reDef(fCdf);

% creation date
dateCreation = datestr(now_utc, 'yyyymmddHHMMSS');

% set the 'history' global attribute
globalVarId = netcdf.getConstant('NC_GLOBAL');
globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation (coriolis COGD software); '];
netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);

% put a 'comment' global attribute
commentStr = '';
if (global_att_is_present_dec_argo(fCdf, 'comment'))
   commentStr = netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'comment');
   commentStr = [commentStr ' '];
end
commentStr = [commentStr 'This profile file has been generated from ANDRO data.'];
netcdf.putAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'comment', commentStr);

% set the resolution attribute to the JULD and JULD_LOCATION parameters
profJulDLocRes = double(1/86400); % 1 second
profJulDRes = double(1/86400); % 1 second
if (var_is_present_dec_argo(fCdf, 'JULD'))
   juldVarId = netcdf.inqVarID(fCdf, 'JULD');
   netcdf.putAtt(fCdf, juldVarId, 'resolution', profJulDRes);
end
if (var_is_present_dec_argo(fCdf, 'JULD_LOCATION'))
   juldLocationVarId = netcdf.inqVarID(fCdf, 'JULD_LOCATION');
   netcdf.putAtt(fCdf, juldLocationVarId, 'resolution', profJulDLocRes);
end

% retrieve the Ids of the dimensions associated with the parameter variables
nProfDimId = netcdf.inqDimID(fCdf, 'N_PROF');
nLevelsDimId = netcdf.inqDimID(fCdf, 'N_LEVELS');

% create the variables on global quality of parameter profile
for idParam = 1:length(paramlist)
   
   paramName = paramlist{idParam};
   
   % create the variables on global quality of parameter profile
   profParamQcName = ['PROFILE_' paramName '_QC'];
   if (~var_is_present_dec_argo(fCdf, profParamQcName))
      profileParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', nProfDimId);
      netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', paramName));
      netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
      netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
   end
end

% create the parameter variables
for idParam = 1:length(paramlist)
   
   paramName = paramlist{idParam};
   
   % retrieve the information on the parameter
   paramStruct = get_netcdf_param_attributes_3_1(paramName);
   if (isempty(paramStruct))
      o_comment = sprintf('ERROR: Parameter ''%s'' not managed yet by this program\n', paramName);
      return
   end
   
   % create the parameter variable and attributes
   if (~var_is_present_dec_argo(fCdf, paramName))
      paramVarId = netcdf.defVar(fCdf, paramName, 'NC_FLOAT', ...
         fliplr([nProfDimId nLevelsDimId]));
      if (~isempty(paramStruct.longName))
         netcdf.putAtt(fCdf, paramVarId, 'long_name', paramStruct.longName);
      end
      if (~isempty(paramStruct.standardName))
         netcdf.putAtt(fCdf, paramVarId, 'standard_name', paramStruct.standardName);
      end
      if (~isempty(paramStruct.fillValue))
         netcdf.putAtt(fCdf, paramVarId, '_FillValue', paramStruct.fillValue);
      end
      if (~isempty(paramStruct.units))
         netcdf.putAtt(fCdf, paramVarId, 'units', paramStruct.units);
      end
      if (~isempty(paramStruct.validMin))
         netcdf.putAtt(fCdf, paramVarId, 'valid_min', paramStruct.validMin);
      end
      if (~isempty(paramStruct.validMax))
         netcdf.putAtt(fCdf, paramVarId, 'valid_max', paramStruct.validMax);
      end
      if (~isempty(paramStruct.cFormat))
         netcdf.putAtt(fCdf, paramVarId, 'C_format', paramStruct.cFormat);
      end
      if (~isempty(paramStruct.fortranFormat))
         netcdf.putAtt(fCdf, paramVarId, 'FORTRAN_format', paramStruct.fortranFormat);
      end
      if (~isempty(paramStruct.resolution))
         netcdf.putAtt(fCdf, paramVarId, 'resolution', paramStruct.resolution);
      end
      if (~isempty(paramStruct.axis))
         netcdf.putAtt(fCdf, paramVarId, 'axis', paramStruct.axis);
      end
   end
   
   % create the parameter QC variable and attributes
   paramNameQc = [paramName '_QC'];
   if (~var_is_present_dec_argo(fCdf, paramNameQc))
      paramQcVarId = netcdf.defVar(fCdf, paramNameQc, 'NC_CHAR', ...
         fliplr([nProfDimId nLevelsDimId]));
      netcdf.putAtt(fCdf, paramQcVarId, 'long_name', 'quality flag');
      netcdf.putAtt(fCdf, paramQcVarId, 'conventions', 'Argo reference table 2');
      netcdf.putAtt(fCdf, paramQcVarId, '_FillValue', ' ');
   end
   
   if (paramStruct.adjAllowed == 1)
      % create the parameter adjusted variable and attributes
      paramNameAdj = [paramName '_ADJUSTED'];
      if (~var_is_present_dec_argo(fCdf, paramNameAdj))
         paramAdjVarId = netcdf.defVar(fCdf, paramNameAdj, 'NC_FLOAT', ...
            fliplr([nProfDimId nLevelsDimId]));
         if (~isempty(paramStruct.longName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'long_name', paramStruct.longName);
         end
         if (~isempty(paramStruct.standardName))
            netcdf.putAtt(fCdf, paramAdjVarId, 'standard_name', paramStruct.standardName);
         end
         if (~isempty(paramStruct.fillValue))
            netcdf.putAtt(fCdf, paramAdjVarId, '_FillValue', paramStruct.fillValue);
         end
         if (~isempty(paramStruct.units))
            netcdf.putAtt(fCdf, paramAdjVarId, 'units', paramStruct.units);
         end
         if (~isempty(paramStruct.validMin))
            netcdf.putAtt(fCdf, paramAdjVarId, 'valid_min', paramStruct.validMin);
         end
         if (~isempty(paramStruct.validMax))
            netcdf.putAtt(fCdf, paramAdjVarId, 'valid_max', paramStruct.validMax);
         end
         if (~isempty(paramStruct.cFormat))
            netcdf.putAtt(fCdf, paramAdjVarId, 'C_format', paramStruct.cFormat);
         end
         if (~isempty(paramStruct.fortranFormat))
            netcdf.putAtt(fCdf, paramAdjVarId, 'FORTRAN_format', paramStruct.fortranFormat);
         end
         if (~isempty(paramStruct.resolution))
            netcdf.putAtt(fCdf, paramAdjVarId, 'resolution', paramStruct.resolution);
         end
         if (~isempty(paramStruct.axis))
            netcdf.putAtt(fCdf, paramAdjVarId, 'axis', paramStruct.axis);
         end
      end
      
      % create the parameter adjusted QC variable and attributes
      paramNameAdjQc = [paramName '_ADJUSTED_QC'];
      if (~var_is_present_dec_argo(fCdf, paramNameAdjQc))
         paramAdjQcVarId = netcdf.defVar(fCdf, paramNameAdjQc, 'NC_CHAR', ...
            fliplr([nProfDimId nLevelsDimId]));
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'long_name', 'quality flag');
         netcdf.putAtt(fCdf, paramAdjQcVarId, 'conventions', 'Argo reference table 2');
         netcdf.putAtt(fCdf, paramAdjQcVarId, '_FillValue', ' ');
      end
      
      % create the parameter adjusted error variable and attributes
      paramNameAdjErr = [paramName '_ADJUSTED_ERROR'];
      if (~var_is_present_dec_argo(fCdf, paramNameAdjErr))
         paramAdjErrVarId = netcdf.defVar(fCdf, paramNameAdjErr, 'NC_FLOAT', ...
            fliplr([nProfDimId nLevelsDimId]));
         netcdf.putAtt(fCdf, paramAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
         if (~isempty(paramStruct.fillValue))
            netcdf.putAtt(fCdf, paramAdjErrVarId, '_FillValue', paramStruct.fillValue);
         end
         if (~isempty(paramStruct.units))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'units', paramStruct.units);
         end
         if (~isempty(paramStruct.cFormat))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'C_format', paramStruct.cFormat);
         end
         if (~isempty(paramStruct.fortranFormat))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'FORTRAN_format', paramStruct.fortranFormat);
         end
         if (~isempty(paramStruct.resolution))
            netcdf.putAtt(fCdf, paramAdjErrVarId, 'resolution', paramStruct.resolution);
         end
      end
   end
end

netcdf.close(fCdf);

% update the schema with the Input file dimensions
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_PROF', 1);
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_PARAM', length(paramlist));
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_CALIB', 1);
[a_refFileSchema(2)] = update_dim_in_nc_schema(a_refFileSchema(2), ...
   'N_LEVELS', length(a_profileData.pres));

% update the Output file with the schema
ncwriteschema(outputFilePathName, a_refFileSchema(2));

% open the Output file
fCdf = netcdf.open(outputFilePathName, 'NC_WRITE');
if (isempty(fCdf))
   o_comment = sprintf('ERROR: Unable to open NetCDF input file: %s\n', outputFilePathName);
   return
end

% ready to add the data
valueStr = 'Argo profile';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_TYPE'), 0, length(valueStr), valueStr);
valueStr = '3.1';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'FORMAT_VERSION'), 0, length(valueStr), valueStr);
valueStr = '1.2';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HANDBOOK_VERSION'), 0, length(valueStr), valueStr);
valueStr = '19500101000000';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'REFERENCE_DATE_TIME'), 0, length(valueStr), valueStr);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'), dateCreation);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateCreation);
valueStr = num2str(a_floatNum);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PLATFORM_NUMBER'), [0 0], [length(valueStr) 1], valueStr');
for idParam = 1:length(paramlist)
   paramName = paramlist{idParam};
   valueStr = paramName;
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'), ...
      fliplr([0 idParam-1 0]), fliplr([1 1 length(valueStr)]), valueStr');
end
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CYCLE_NUMBER'), a_profileData.cyNum);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DIRECTION'), 'A');
valueStr = '1A';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_STATE_INDICATOR'), [0 0], [length(valueStr) 1], valueStr');
if (isempty(a_profileData.presOffset))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'), 'R');
else
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'), 'A');
end
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD'), a_profileData.profJuld);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_LOCATION'), a_profileData.profJuldLoc);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LATITUDE'), a_profileData.profLat);
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'LONGITUDE'), a_profileData.profLon);

% copy of the V3.1 meta.nc file variables into the Output file
for idVar = 1:2:length(a_profMetaData)
   
   varName = a_profMetaData{idVar};
   
   if (var_is_present_dec_argo(fCdf, varName))
      idVal = find(strcmp(varName, a_profMetaData(1:2:end)) == 1, 1);
      varValue = a_profMetaData{2*idVal};
      if (isempty(varValue))
         continue
      end
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), varValue);
   else
      fprintf('INFO: Variable %s not present in output format - not copied in output file\n', ...
         varName);
   end
end

% copy of the Input file measurements into the Output file
for idVar = 1:length(paramlist)
   
   varName = paramlist{idVar};
   
   if (var_is_present_dec_argo(fCdf, varName))
      
      varValue = a_profileData.(lower(varName));
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), varValue);
   else
      fprintf('INFO: Variable %s not present in output format - not copied in output file\n', ...
         varName);
   end
   
   if (~isempty(a_profileData.presOffset))
      varNameAdj = [varName '_ADJUSTED'];
      if (var_is_present_dec_argo(fCdf, varNameAdj))
         varValueAdj = a_profileData.([lower(varName) 'Adj']);
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varNameAdj), varValueAdj);
      else
         fprintf('INFO: Variable %s not present in output format - not copied in output file\n', ...
            varNameAdj);
      end
            
      parameterStr = varName;
      if (strcmp(varName, 'PRES'))
         equationStr = 'PRES_ADJUSTED = PRES - Surface Pressure';
         coefficientStr = ['Surface Pressure = ' num2str(a_profileData.presOffset) ' dbar'];
         commentStr = 'Pressure adjusted in real time by using pressure offset at the sea surface';
      else
         equationStr = [varName '_ADJUSTED = ' varName];
         coefficientStr = 'Not applicable';
         commentStr = 'No adjustment performed (values duplicated)';
      end
      dateStr = dateCreation;
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER'), ...
         fliplr([0 0 idVar-1 0]), fliplr([1 1 1 length(parameterStr)]), parameterStr');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_EQUATION'), ...
         fliplr([0 0 idVar-1 0]), fliplr([1 1 1 length(equationStr)]), equationStr');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT'), ...
         fliplr([0 0 idVar-1 0]), fliplr([1 1 1 length(coefficientStr)]), coefficientStr');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_COMMENT'), ...
         fliplr([0 0 idVar-1 0]), fliplr([1 1 1 length(commentStr)]), commentStr');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'SCIENTIFIC_CALIB_DATE'), ...
         fliplr([0 0 idVar-1 0]), fliplr([1 1 1 length(dateStr)]), dateStr');
   end
end

% fill the VERTICAL_SAMPLING_SCHEME variable
value = 'Primary sampling: discrete []';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'VERTICAL_SAMPLING_SCHEME'), ...
   fliplr([0 0]), ...
   fliplr([1 length(value)]), value');

% fill the CONFIG_MISSION_NUMBER variable
[confMissionNumber] = compute_config_mission_number(a_profileData.cyNum, a_configMetaData);
if (~isempty(confMissionNumber))
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'CONFIG_MISSION_NUMBER'), ...
      0, 1, confMissionNumber);
end

% add history information that concerns the current program
currentHistoId = 0;
idProf = 1;
value = 'IF';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
   fliplr([currentHistoId idProf-1 0]), ...
   fliplr([1 1 length(value)]), value');
value = 'COGD';
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
   fliplr([currentHistoId idProf-1 0]), ...
   fliplr([1 1 length(value)]), value');
value = g_cogd_ncGeneratedFromDepFile;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
   fliplr([currentHistoId idProf-1 0]), ...
   fliplr([1 1 length(value)]), value');
value = dateCreation;
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
   fliplr([currentHistoId idProf-1 0]), ...
   fliplr([1 1 length(value)]), value');

netcdf.close(fCdf);

o_ok = 1;
o_outputFilePathName = outputFilePathName;

return

% ------------------------------------------------------------------------------
% Apply RTQC to newly generated NetCDF mono_profile files (V3.1) from a DEP file.
%
% SYNTAX :
%  apply_rtqc(a_floatNum, a_filePathName, a_metaDataFilePathName)
%
% INPUT PARAMETERS :
%   a_floatNum             : float WMO number
%   a_filePathName         : mono-profile NetCDF input file path name
%   a_metaDataFilePathName : meta-adat NetCDF output file path name
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
function apply_rtqc(a_floatNum, a_filePathName, a_metaDataFilePathName)

% create the list of tests to perform
testToPerformList = [ ...
   {'TEST001_PLATFORM_IDENTIFICATION'} {1} ...
   {'TEST002_IMPOSSIBLE_DATE'} {1} ...
   {'TEST003_IMPOSSIBLE_LOCATION'} {1} ...
   {'TEST004_POSITION_ON_LAND'} {1} ...
   {'TEST005_IMPOSSIBLE_SPEED'} {0} ...
   {'TEST006_GLOBAL_RANGE'} {1} ...
   {'TEST007_REGIONAL_RANGE'} {1} ...
   {'TEST008_PRESSURE_INCREASING'} {1} ...
   {'TEST009_SPIKE'} {1} ...
   {'TEST011_GRADIENT'} {1} ...
   {'TEST012_DIGIT_ROLLOVER'} {1} ...
   {'TEST013_STUCK_VALUE'} {1} ...
   {'TEST014_DENSITY_INVERSION'} {1} ...
   {'TEST015_GREY_LIST'} {1} ...
   {'TEST016_GROSS_SALINITY_OR_TEMPERATURE_SENSOR_DRIFT'} {0} ...
   {'TEST018_FROZEN_PRESSURE'} {0} ...
   {'TEST019_DEEPEST_PRESSURE'} {1} ...
   {'TEST020_QUESTIONABLE_ARGOS_POSITION'} {1} ...
   {'TEST021_NS_UNPUMPED_SALINITY'} {0} ...
   {'TEST022_NS_MIXED_AIR_WATER'} {0} ...
   {'TEST023_DEEP_FLOAT'} {0} ...
   {'TEST024_RBR_FLOAT'} {0} ...
   {'TEST025_MEDD'} {0} ...
   {'TEST057_DOXY'} {0} ...
   {'TEST059_NITRATE'} {0} ...
   {'TEST062_BBP'} {0} ...
   {'TEST063_CHLA'} {0} ...
   ];

% meta-data associated to each test
testMetaData = [ ...
   {'TEST000_FLOAT_DECODER_ID'} {''} ...
   {'TEST004_GEBCO_FILE'} {'C:\Users\jprannou\_RNU\_ressources\GEBCO_2021\GEBCO_2021.nc'} ...
   {'TEST013_METADA_DATA_FILE'} {a_metaDataFilePathName} ...
   {'TEST015_GREY_LIST_FILE'} {'C:\Users\jprannou\_RNU\DecArgo_soft\work\ar_greylist.txt'} ...
   {'TEST019_METADA_DATA_FILE'} {a_metaDataFilePathName} ...
   ];

% apply RTQC
add_rtqc_to_profile_file(a_floatNum, ...
   a_filePathName, a_filePathName, ...
   '', '', ...
   testToPerformList, testMetaData, 1, 0);

return

% ------------------------------------------------------------------------------
% Compute the configuration number associated to a given cycle number.
%
% SYNTAX :
%  [o_confMissionNumber] = compute_config_mission_number(a_cycleNumber, a_metaData)
%
% INPUT PARAMETERS :
%   a_cycleNumber  : cycle number from nc input file
%   a_metaData     : meta-data from V3.1 nc meta file
%
% OUTPUT PARAMETERS :
%   o_confMissionNumber : configuration number of the cycle
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/26/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_confMissionNumber] = compute_config_mission_number(a_cycleNumber, a_metaData)

% output parameters initialization
o_confMissionNumber = [];


idVal = find(strcmp('DAC_FORMAT_ID', a_metaData(1:2:end)) == 1, 1);
dacFormatId = strtrim(a_metaData{2*idVal}');
idVal = find(strcmp('CONFIG_MISSION_NUMBER', a_metaData(1:2:end)) == 1, 1);
metaConfMisNum = a_metaData{2*idVal};

if (~isempty(dacFormatId) && ~isempty(metaConfMisNum))
      
   firstProfCycleNum = [];
   switch (dacFormatId)
      case {'11', '4', '1.2', '24', '19', '25', '1.02', '1.01', '6', '1.4', ...
            '1.1', '28', '1.3', '1.03', '13', '23', '1.04', '1.5', ...
            '17', '36', '29', '27', '41', '9'}
         firstProfCycleNum = 1;
         DPF_FLAG = 0;
      case {'46', '11.1', '013108',  '111509', '042408', '34'}
         firstProfCycleNum = 1;
         DPF_FLAG = 1;
      otherwise
         fprintf('WARNING: Nothing done yet to first deep cycle number for dacFormatId %s\n', dacFormatId);
   end
   
   if (length(metaConfMisNum) < 4)
      if (~DPF_FLAG)
         if (length(metaConfMisNum) == 1)
            % only one mission
            o_confMissionNumber = metaConfMisNum;
         else
            % multi-mission with their associated repetition rates
            idVal = find(strcmp('CONFIG_REPETITION_RATE', a_metaData(1:2:end)) == 1, 1);
            repRateMetaData = a_metaData{2*idVal};
            sumRepRate = 0;
            for idRep = 1:length(repRateMetaData)
               sumRepRate = sumRepRate + ...
                  str2num(repRateMetaData{idRep}.(char(fieldnames(repRateMetaData{idRep}))));
            end
            if (rem(a_cycleNumber-1, sumRepRate) == 0)
               o_confMissionNumber = metaConfMisNum(1);
            else
               o_confMissionNumber = metaConfMisNum(2);
            end
         end
      else
         if (a_cycleNumber == firstProfCycleNum)
            % DPF cycle
            o_confMissionNumber = metaConfMisNum(1);
         elseif (length(metaConfMisNum) == 2)
            % only one mission
            o_confMissionNumber = metaConfMisNum(2);
         else
            fprintf('ERROR: TBD FOR DPF\n');
         end
      end
   else
      % seasonal floats
      % multi-mission with their associated repetition rates
      idVal = find(strcmp('CONFIG_REPETITION_RATE', a_metaData(1:2:end)) == 1, 1);
      repRateMetaData = a_metaData{2*idVal};
      repRateTab = [];
      for idRep = 1:length(repRateMetaData)
         repRateTab = [repRateTab ...
            str2double(repRateMetaData{idRep}.(char(fieldnames(repRateMetaData{idRep}))))];
      end
      for idRep = 1:length(repRateTab)
         if (a_cycleNumber <= sum(repRateTab(1:idRep)))
            break
         end
      end
      o_confMissionNumber = metaConfMisNum(idRep);
   end   
end

return

% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}) == 1, 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;
   
   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      idDims = find(strcmp(a_dimName, {var.Dimensions.Name}) == 1);
      a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
      for idDim = 1:length(idDims)
         a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
      end
   end
end

o_outputSchema = a_inputSchema;

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
% Retrieve information from json meta-data file.
%
% SYNTAX :
%  [o_metaData] = get_meta_data_from_json_file(a_floatNum, a_wantedMetaNames)
%
% INPUT PARAMETERS :
%   a_floatNum        : float WMO number
%   a_wantedMetaNames : meta-data to retrieve from json file
%
% OUTPUT PARAMETERS :
%   o_metaData : retrieved meta-data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/09/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_metaData] = get_meta_data_from_json_file(a_jsonInputFileName, a_wantedMetaNames)

% output parameters initialization
o_metaData = [];

% read meta-data file
metaData = loadjson(a_jsonInputFileName);

% retrieve variables from json structure
for idField = 1:length(a_wantedMetaNames)
   fieldName = char(a_wantedMetaNames(idField));
   
   if (isfield(metaData, fieldName))
      fieldValue = metaData.(fieldName);
      if (~isempty(fieldValue))
         o_metaData = [o_metaData {fieldName} {fieldValue}];
      else
         %          fprintf('WARNING: Field %s value is empty in file : %s\n', ...
         %             fieldName, jsonInputFileName);
         o_metaData = [o_metaData {fieldName} {' '}];
      end
   else
      %       fprintf('WARNING: Field %s not present in file : %s\n', ...
      %          fieldName, jsonInputFileName);
      o_metaData = [o_metaData {fieldName} {' '}];
   end
end

return
