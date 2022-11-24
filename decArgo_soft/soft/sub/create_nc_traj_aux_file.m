% ------------------------------------------------------------------------------
% Create NetCDF TRAJECTORY AUX file.
%
% SYNTAX :
%  create_nc_traj_aux_file( ...
%    a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabTrajNMeas     : N_MEASUREMENT trajectory data
%   a_tabTrajNCycle    : N_CYCLE trajectory data
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_traj_aux_file( ...
   a_decoderId, a_tabTrajNMeas, a_tabTrajNCycle, a_metaDataFromJson)

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;

% configuration values
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_applyRtqc;

% decoder version
global g_decArgo_decoderVersion;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;

% global default values
global g_decArgo_qcDef;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabTrajNMeas) && isempty(a_tabTrajNCycle))
   return;
end
   
% collect information on trajectory
measParamNameAll = [];
paramNameSubLevelsAll = [];
measSubLevelsAll = [];
for idNM = 1:length(a_tabTrajNMeas)
   nMeas = a_tabTrajNMeas(idNM);
   measParamList = [nMeas.tabMeas.paramList];
   if (~isempty(measParamList))
      measParamNameList = {measParamList.name};
      measParamNameAll = [measParamNameAll measParamNameList];
      
      measParamNumberWithSubLevelsList = [nMeas.tabMeas.paramNumberWithSubLevels];
      if (~isempty(measParamNumberWithSubLevelsList))
         for idM = 1:length(nMeas.tabMeas)
            measParamSubLevList = nMeas.tabMeas(idM).paramNumberWithSubLevels;
            if (~isempty(measParamSubLevList))
               measParamNameList = {nMeas.tabMeas(idM).paramList.name};
               paramNameSubLevelsAll = [paramNameSubLevelsAll measParamNameList(measParamSubLevList)];
               measSubLevelsAll = [measSubLevelsAll nMeas.tabMeas(idM).paramNumberOfSubLevels];
            end
         end
      end
   end   
end
measUniqueParamName = unique(measParamNameAll, 'stable');
nbMeasParam = length(measUniqueParamName);

% due to erroneous received data, the number of sublevels can vary for a same
% parameter
paramSubLevels = unique(paramNameSubLevelsAll, 'stable');
dimSubLevels = [];
for idParamSL = 1:length(paramSubLevels)
   dimSubLevels = [dimSubLevels ...
      max(measSubLevelsAll(find(strcmp(paramNameSubLevelsAll, paramSubLevels{idParamSL}))))];
end
measSubLevels = sort(unique(dimSubLevels), 'descend');

% not optimized version START
% measParamName = [];
% measSubLevels = [];
% paramNameSubLevels = [];
% for idNM = 1:length(a_tabTrajNMeas)
%    nMeas = a_tabTrajNMeas(idNM);
%    for idM = 1:length(nMeas.tabMeas)
%       if (~isempty(nMeas.tabMeas(idM).paramList))
%          measParamNameList = {nMeas.tabMeas(idM).paramList.name};
%          measParamName = [measParamName measParamNameList];
%          
%          measParamSubLevList = nMeas.tabMeas(idM).paramNumberWithSubLevels;
%          if (~isempty(measParamSubLevList))
%             paramNameSubLevels = [paramNameSubLevels ...
%                measParamNameList(measParamSubLevList)];
%             measSubLevels = [measSubLevels ...
%                nMeas.tabMeas(idM).paramNumberOfSubLevels];
%          end
%       end
%    end
% end
% measUniqueParamName = unique(measParamName, 'stable');
% nbMeasParam = length(measUniqueParamName);

% % due to erroneous received data, the number of sublevels can vary for a same
% % parameter
% paramSubLevels = unique(paramNameSubLevels, 'stable');
% dimSubLevels = [];
% for idParamSL = 1:length(paramSubLevels)
%    dimSubLevels = [dimSubLevels ...
%       max(measSubLevels(find(strcmp(paramNameSubLevels, paramSubLevels{idParamSL}))))];
% end
% measSubLevels = sort(unique(dimSubLevels), 'descend');
% not optimized version END

if (nbMeasParam > 0)
   
   % create output file pathname
   floatNumStr = num2str(g_decArgo_floatNum);
   outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
   outputDirName = [outputDirName '/auxiliary/'];
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
   
   ncFileName = [floatNumStr '_Rtraj_aux.nc'];
   ncPathFileName = [outputDirName  ncFileName];
   
   % information to retrieve from a possible existing trajectory file
   ncCreationDate = '';
   histoInstitution = '';
   histoStep = '';
   histoSoftware = '';
   histoSoftwareRelease = '';
   histoDate = '';
   if (exist(ncPathFileName, 'file') == 2)
      
      % retrieve information from existing file
      wantedTrajVars = [ ...
         {'DATE_CREATION'} ...
         {'DATA_MODE'} ...
         {'HISTORY_INSTITUTION'} ...
         {'HISTORY_STEP'} ...
         {'HISTORY_SOFTWARE'} ...
         {'HISTORY_SOFTWARE_RELEASE'} ...
         {'HISTORY_DATE'} ...
         ];
      
      % retrieve information from TRAJ netCDF file
      [trajData] = get_data_from_nc_file(ncPathFileName, wantedTrajVars);
      
      idVal = find(strcmp('DATE_CREATION', trajData) == 1);
      if (~isempty(idVal))
         ncCreationDate = trajData{idVal+1}';
      end
      idVal = find(strcmp('DATA_MODE', trajData) == 1);
      if (~isempty(idVal))
         ncDataMode = trajData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_INSTITUTION', trajData) == 1);
      if (~isempty(idVal))
         histoInstitution = trajData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_STEP', trajData) == 1);
      if (~isempty(idVal))
         histoStep = trajData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_SOFTWARE', trajData) == 1);
      if (~isempty(idVal))
         histoSoftware = trajData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_SOFTWARE_RELEASE', trajData) == 1);
      if (~isempty(idVal))
         histoSoftwareRelease = trajData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_DATE', trajData) == 1);
      if (~isempty(idVal))
         histoDate = trajData{idVal+1};
      end
      
      if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
         fprintf('Updating NetCDF TRAJECTORY AUX file (%s) ...\n', ncFileName);
      end
      
   else
      if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
         fprintf('Creating NetCDF TRAJECTORY AUX file (%s) ...\n', ncFileName);
      end
   end
   
   currentDate = datestr(now_utc, 'yyyymmddHHMMSS');
   
   % create and open NetCDF file
   fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
      return;
   end
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % DEFINE MODE BEGIN
   if (VERBOSE_MODE == 2)
      fprintf('START DEFINE MODE\n');
   end
   
   % create dimensions
   dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
   string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
   paramNameLength = 64;
   string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
   string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
   string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
   string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
   string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);
   
   if (nbMeasParam == 0)
      nbMeasParam = 1;
   end
   nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbMeasParam);
   
   for idSL = 1:length(measSubLevels)
      netcdf.defDim(fCdf, sprintf('N_VALUES%d', measSubLevels(idSL)), measSubLevels(idSL));
   end
   
   nMeasurementDimId = netcdf.defDim(fCdf, 'N_MEASUREMENT', netcdf.getConstant('NC_UNLIMITED'));
   
   cycles = [];
   if (~isempty(a_tabTrajNCycle))
      cycles =  sort(unique([a_tabTrajNCycle.outputCycleNumber]));
      nCycle = length(cycles);
   end
   if (nCycle == 0)
      nCycle = 1;
   end
   nCycleDimId = netcdf.defDim(fCdf, 'N_CYCLE', nCycle);
   
   nHistoryDim = 1;
   if (~isempty(histoInstitution))
      if (length(ncDataMode) <= length(cycles))
         nHistoryDim = size(histoInstitution, 2) + 1;
      end
   end
   nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', nHistoryDim);
   
   if (VERBOSE_MODE == 2)
      fprintf('N_PARAM = %d\n', nbMeasParam);
      fprintf('N_CYCLE = %d\n', length(cycles));
      for idSL = 1:length(measSubLevels)
         fprintf('N_SUBLEVELS%d = %d\n', measSubLevels(idSL), measSubLevels(idSL));
      end
   end
   
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float trajectory auxiliary data file');
   institution = 'CORIOLIS';
   idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
   if (~isempty(idVal))
      dataCentre = char(a_metaDataFromJson{idVal+1});
      [institution] = get_institution_from_data_centre(dataCentre);
   end
   netcdf.putAtt(fCdf, globalVarId, 'institution', institution);
   netcdf.putAtt(fCdf, globalVarId, 'source', 'Argo float');
   if (isempty(ncCreationDate))
      globalHistoryText = [datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   else
      globalHistoryText = [datestr(datenum(ncCreationDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   end
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(currentDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis float real time data processing)'];
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   netcdf.putAtt(fCdf, globalVarId, 'references', ' ');
   netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '1.0');
   netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'CF-1.6 Coriolis-Argo-Aux-1.0');
   netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryCoriolisAux');
   
   resGlobalComment = get_global_comment_on_resolution(a_decoderId);
   if (~isempty(resGlobalComment))
      netcdf.putAtt(fCdf, globalVarId, 'comment_on_resolution', resGlobalComment);
   end
   
   measGlobalComment = get_global_comment_on_measurement_code(a_decoderId);
   if (~isempty(measGlobalComment))
      netcdf.putAtt(fCdf, globalVarId, 'comment_on_measurement_code', measGlobalComment);
   end
   
   % general information on the trajectory file
   dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string32DimId);
   netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
   netcdf.putAtt(fCdf, dataTypeVarId, 'conventions', 'Reference table AUX_1');
   netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');
   
   formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
   netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
   netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');
   
   referenceDateTimeVarId = netcdf.defVar(fCdf, 'REFERENCE_DATE_TIME', 'NC_CHAR', dateTimeDimId);
   netcdf.putAtt(fCdf, referenceDateTimeVarId, 'long_name', 'Date of reference for Julian days');
   netcdf.putAtt(fCdf, referenceDateTimeVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, referenceDateTimeVarId, '_FillValue', ' ');
   
   dateCreationVarId = netcdf.defVar(fCdf, 'DATE_CREATION', 'NC_CHAR', dateTimeDimId);
   netcdf.putAtt(fCdf, dateCreationVarId, 'long_name', 'Date of file creation');
   netcdf.putAtt(fCdf, dateCreationVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, dateCreationVarId, '_FillValue', ' ');
   
   dateUpdateVarId = netcdf.defVar(fCdf, 'DATE_UPDATE', 'NC_CHAR', dateTimeDimId);
   netcdf.putAtt(fCdf, dateUpdateVarId, 'long_name', 'Date of update of this file');
   netcdf.putAtt(fCdf, dateUpdateVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, dateUpdateVarId, '_FillValue', ' ');
   
   % general information on the float
   platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', string8DimId);
   netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
   netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
   netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');
   
   projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', string64DimId);
   netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Name of the project');
   netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');
   
   piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', string64DimId);
   netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
   netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');
   
   trajectoryParametersVarId = netcdf.defVar(fCdf, 'TRAJECTORY_PARAMETERS', 'NC_CHAR', fliplr([nParamDimId string64DimId]));
   netcdf.putAtt(fCdf, trajectoryParametersVarId, 'long_name', 'List of available parameters for the station');
   netcdf.putAtt(fCdf, trajectoryParametersVarId, 'conventions', 'Reference table AUX_3a');
   netcdf.putAtt(fCdf, trajectoryParametersVarId, '_FillValue', ' ');
   
   dataCentreVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', string2DimId);
   netcdf.putAtt(fCdf, dataCentreVarId, 'long_name', 'Data centre in charge of float data processing');
   netcdf.putAtt(fCdf, dataCentreVarId, 'conventions', 'Argo reference table 4');
   netcdf.putAtt(fCdf, dataCentreVarId, '_FillValue', ' ');
   
   dataStateIndicatorVarId = netcdf.defVar(fCdf, 'DATA_STATE_INDICATOR', 'NC_CHAR', string4DimId);
   netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'long_name', 'Degree of processing the data have passed through');
   netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'conventions', 'Argo reference table 6');
   netcdf.putAtt(fCdf, dataStateIndicatorVarId, '_FillValue', ' ');
   
   platformTypeVarId = netcdf.defVar(fCdf, 'PLATFORM_TYPE', 'NC_CHAR', string32DimId);
   netcdf.putAtt(fCdf, platformTypeVarId, 'long_name', 'Type of float');
   netcdf.putAtt(fCdf, platformTypeVarId, 'conventions', 'Argo reference table 23');
   netcdf.putAtt(fCdf, platformTypeVarId, '_FillValue', ' ');
   
   floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', string32DimId);
   netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
   netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');
   
   firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', string32DimId);
   netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Instrument firmware version');
   netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');
   
   wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', string4DimId);
   netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
   netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
   netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');
   
   % locations and measurements from the float
   % N_MEASUREMENT variables
   
   juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nMeasurementDimId);
   netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
   netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
   netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   [resNominal, resComment] = get_param_comment_on_resolution('JULD', a_decoderId);
   netcdf.putAtt(fCdf, juldVarId, 'resolution', resNominal);
   netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
   netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');
   if (~isempty(resComment))
      netcdf.putAtt(fCdf, juldVarId, 'comment_on_resolution', resComment);
   end
   
   juldStatusVarId = netcdf.defVar(fCdf, 'JULD_STATUS', 'NC_CHAR', nMeasurementDimId);
   netcdf.putAtt(fCdf, juldStatusVarId, 'long_name', 'Status of the date and time');
   netcdf.putAtt(fCdf, juldStatusVarId, 'conventions', 'Argo reference table 19');
   netcdf.putAtt(fCdf, juldStatusVarId, '_FillValue', ' ');
   
   juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nMeasurementDimId);
   netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
   netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');
   
   juldAdjustedVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED', 'NC_DOUBLE', nMeasurementDimId);
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'long_name', 'Adjusted julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'standard_name', 'time');
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   [resNominal, resComment] = get_param_comment_on_resolution('JULD_ADJUSTED', a_decoderId);
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'resolution', resNominal);
   netcdf.putAtt(fCdf, juldAdjustedVarId, '_FillValue', double(999999));
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'axis', 'T');
   if (~isempty(resComment))
      netcdf.putAtt(fCdf, juldAdjustedVarId, 'comment_on_resolution', resComment);
   end
   
   juldAdjustedStatusVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED_STATUS', 'NC_CHAR', nMeasurementDimId);
   netcdf.putAtt(fCdf, juldAdjustedStatusVarId, 'long_name', 'Status of the JULD_ADJUSTED date');
   netcdf.putAtt(fCdf, juldAdjustedStatusVarId, 'conventions', 'Argo reference table 19');
   netcdf.putAtt(fCdf, juldAdjustedStatusVarId, '_FillValue', ' ');
   
   juldAdjustedQcVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED_QC', 'NC_CHAR', nMeasurementDimId);
   netcdf.putAtt(fCdf, juldAdjustedQcVarId, 'long_name', 'Quality on adjusted date and time');
   netcdf.putAtt(fCdf, juldAdjustedQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, juldAdjustedQcVarId, '_FillValue', ' ');
   
   cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nMeasurementDimId);
   netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number of the measurement');
   netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
   netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));
   
   cycleNumberAdjustedVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_ADJUSTED', 'NC_INT', nMeasurementDimId);
   netcdf.putAtt(fCdf, cycleNumberAdjustedVarId, 'long_name', 'Adjusted float cycle number of the measurement');
   netcdf.putAtt(fCdf, cycleNumberAdjustedVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
   netcdf.putAtt(fCdf, cycleNumberAdjustedVarId, '_FillValue', int32(99999));
   
   measurementCodeVarId = netcdf.defVar(fCdf, 'MEASUREMENT_CODE', 'NC_INT', nMeasurementDimId);
   netcdf.putAtt(fCdf, measurementCodeVarId, 'long_name', 'Flag referring to a measurement event in the cycle');
   netcdf.putAtt(fCdf, measurementCodeVarId, 'conventions', 'Argo reference table 15');
   netcdf.putAtt(fCdf, measurementCodeVarId, '_FillValue', int32(99999));
   
   % parameter variables
   paramNameDone = [];
   doubleTypeInFile = 0;
   for idNM = 1:length(a_tabTrajNMeas)
      nMeas = a_tabTrajNMeas(idNM);
      for idM = 1:length(nMeas.tabMeas)
         meas = nMeas.tabMeas(idM);
         
         measParamList = meas.paramList;
         for idParam = 1:length(measParamList)
            
            measParam = measParamList(idParam);
            measParamName = measParam.name;
            
            if (isempty(find(strcmp(measParamName, paramNameDone) == 1, 1)))
               
               paramNameDone = [paramNameDone; {measParamName}];
               
               % find if this parameter has sublevels
               paramWithSubLevels = 0;
               if (~isempty(meas.paramNumberWithSubLevels))
                  idF = find(meas.paramNumberWithSubLevels == idParam);
                  if (~isempty(idF))
                     paramWithSubLevels = 1;
                     paramSubLevelsDim = dimSubLevels(find(strcmp(measParamName, paramSubLevels), 1));
                     %                            nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', meas.paramNumberOfSubLevels(idF)));
                     nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', paramSubLevelsDim));
                  end
               end
               
               % create parameter variable and attributes
               if (~var_is_present_dec_argo(fCdf, measParamName))
                  
                  varType = 'NC_FLOAT';
                  if ((strncmp(measParamName, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
                        (strncmp(measParamName, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
                     varType = 'NC_DOUBLE';
                     doubleTypeInFile = 1;
                  end
                  if (paramWithSubLevels == 0)
                     measParamVarId = netcdf.defVar(fCdf, measParamName, varType, nMeasurementDimId);
                  else
                     measParamVarId = netcdf.defVar(fCdf, measParamName, varType, fliplr([nMeasurementDimId nValuesDimId]));
                  end
                  
                  if (~isempty(measParam.longName))
                     netcdf.putAtt(fCdf, measParamVarId, 'long_name', measParam.longName);
                  end
                  if (~isempty(measParam.standardName))
                     netcdf.putAtt(fCdf, measParamVarId, 'standard_name', measParam.standardName);
                  end
                  if (~isempty(measParam.fillValue))
                     netcdf.putAtt(fCdf, measParamVarId, '_FillValue', measParam.fillValue);
                  end
                  if (~isempty(measParam.units))
                     netcdf.putAtt(fCdf, measParamVarId, 'units', measParam.units);
                  end
                  if (~isempty(measParam.validMin))
                     netcdf.putAtt(fCdf, measParamVarId, 'valid_min', measParam.validMin);
                  end
                  if (~isempty(measParam.validMax))
                     netcdf.putAtt(fCdf, measParamVarId, 'valid_max', measParam.validMax);
                  end
                  
                  [cFormat, fortranFormat] = get_param_output_format(measParamName, a_decoderId);
                  if (isempty(cFormat))
                     if (~isempty(measParam.cFormat))
                        netcdf.putAtt(fCdf, measParamVarId, 'C_format', measParam.cFormat);
                     end
                  else
                     netcdf.putAtt(fCdf, measParamVarId, 'C_format', cFormat);
                  end
                  if (isempty(fortranFormat))
                     if (~isempty(measParam.fortranFormat))
                        netcdf.putAtt(fCdf, measParamVarId, 'FORTRAN_format', measParam.fortranFormat);
                     end
                  else
                     netcdf.putAtt(fCdf, measParamVarId, 'FORTRAN_format', fortranFormat);
                  end
                  
                  [resNominal, resComment] = get_param_comment_on_resolution(measParamName, a_decoderId);
                  if (isempty(resNominal))
                     if (~isempty(measParam.resolution))
                        netcdf.putAtt(fCdf, measParamVarId, 'resolution', measParam.resolution);
                     end
                  else
                     netcdf.putAtt(fCdf, measParamVarId, 'resolution', resNominal);
                  end
                  if (~isempty(resComment))
                     netcdf.putAtt(fCdf, measParamVarId, 'comment_on_resolution', resComment);
                  end
                  
                  if (~isempty(measParam.axis))
                     netcdf.putAtt(fCdf, measParamVarId, 'axis', measParam.axis);
                  end
               end
               
               % parameter QC variable and attributes
               if ~(strcmp(measParamName(end-3:end), '_STD') || ...
                     strcmp(measParamName(end-3:end), '_MED'))
                  
                  measParamQcName = sprintf('%s_QC', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamQcName))
                     
                     measParamQcVarId = netcdf.defVar(fCdf, measParamQcName, 'NC_CHAR', nMeasurementDimId);
                     
                     netcdf.putAtt(fCdf, measParamQcVarId, 'long_name', 'quality flag');
                     netcdf.putAtt(fCdf, measParamQcVarId, 'conventions', 'Argo reference table 2');
                     netcdf.putAtt(fCdf, measParamQcVarId, '_FillValue', ' ');
                  end
               end
               
               % parameter adjusted variable and attributes
               if (measParam.adjAllowed == 1)
                  
                  measParamAdjName = sprintf('%s_ADJUSTED', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamAdjName))
                     
                     if (paramWithSubLevels == 0)
                        measParamAdjVarId = netcdf.defVar(fCdf, measParamAdjName, varType, nMeasurementDimId);
                     else
                        measParamAdjVarId = netcdf.defVar(fCdf, measParamAdjName, varType, fliplr([nMeasurementDimId nValuesDimId]));
                     end
                     
                     if (~isempty(measParam.longName))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'long_name', measParam.longName);
                     end
                     if (~isempty(measParam.standardName))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'standard_name', measParam.standardName);
                     end
                     if (~isempty(measParam.fillValue))
                        netcdf.putAtt(fCdf, measParamAdjVarId, '_FillValue', measParam.fillValue);
                     end
                     if (~isempty(measParam.units))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'units', measParam.units);
                     end
                     if (~isempty(measParam.validMin))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'valid_min', measParam.validMin);
                     end
                     if (~isempty(measParam.validMax))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'valid_max', measParam.validMax);
                     end
                     
                     [cFormat, fortranFormat] = get_param_output_format(measParamAdjName, a_decoderId);
                     if (isempty(cFormat))
                        if (~isempty(measParam.cFormat))
                           netcdf.putAtt(fCdf, measParamAdjVarId, 'C_format', measParam.cFormat);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'C_format', cFormat);
                     end
                     if (isempty(fortranFormat))
                        if (~isempty(measParam.fortranFormat))
                           netcdf.putAtt(fCdf, measParamAdjVarId, 'FORTRAN_format', measParam.fortranFormat);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'FORTRAN_format', fortranFormat);
                     end
                     
                     [resNominal, resComment] = get_param_comment_on_resolution(measParamAdjName, a_decoderId);
                     if (isempty(resNominal))
                        if (~isempty(measParam.resolution))
                           netcdf.putAtt(fCdf, measParamAdjVarId, 'resolution', measParam.resolution);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'resolution', resNominal);
                     end
                     if (~isempty(resComment))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'comment_on_resolution', resComment);
                     end
                     
                     if (~isempty(measParam.axis))
                        netcdf.putAtt(fCdf, measParamAdjVarId, 'axis', measParam.axis);
                     end
                  end
                  
                  % parameter adjusted QC variable and attributes
                  measParamAdjQcName = sprintf('%s_ADJUSTED_QC', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamAdjQcName))
                     
                     measParamAdjQcVarId = netcdf.defVar(fCdf, measParamAdjQcName, 'NC_CHAR', nMeasurementDimId);
                     
                     netcdf.putAtt(fCdf, measParamAdjQcVarId, 'long_name', 'quality flag');
                     netcdf.putAtt(fCdf, measParamAdjQcVarId, 'conventions', 'Argo reference table 2');
                     netcdf.putAtt(fCdf, measParamAdjQcVarId, '_FillValue', ' ');
                  end
                  
                  % parameter adjusted error variable and attributes
                  measParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', measParamName);
                  if (~var_is_present_dec_argo(fCdf, measParamAdjErrName))
                     
                     if (paramWithSubLevels == 0)
                        measParamAdjErrVarId = netcdf.defVar(fCdf, measParamAdjErrName, varType, nMeasurementDimId);
                     else
                        measParamAdjErrVarId = netcdf.defVar(fCdf, measParamAdjErrName, varType, fliplr([nMeasurementDimId nValuesDimId]));
                     end
                     
                     netcdf.putAtt(fCdf, measParamAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
                     if (~isempty(measParam.fillValue))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, '_FillValue', measParam.fillValue);
                     end
                     if (~isempty(measParam.units))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'units', measParam.units);
                     end
                     
                     [cFormat, fortranFormat] = get_param_output_format(measParamAdjErrName, a_decoderId);
                     if (isempty(cFormat))
                        if (~isempty(measParam.cFormat))
                           netcdf.putAtt(fCdf, measParamAdjErrVarId, 'C_format', measParam.cFormat);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'C_format', cFormat);
                     end
                     if (isempty(fortranFormat))
                        if (~isempty(measParam.fortranFormat))
                           netcdf.putAtt(fCdf, measParamAdjErrVarId, 'FORTRAN_format', measParam.fortranFormat);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'FORTRAN_format', fortranFormat);
                     end
                     
                     [resNominal, resComment] = get_param_comment_on_resolution(measParamAdjErrName, a_decoderId);
                     if (isempty(resNominal))
                        if (~isempty(measParam.resolution))
                           netcdf.putAtt(fCdf, measParamAdjErrVarId, 'resolution', measParam.resolution);
                        end
                     else
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'resolution', resNominal);
                     end
                     if (~isempty(resComment))
                        netcdf.putAtt(fCdf, measParamAdjErrVarId, 'comment_on_resolution', resComment);
                     end
                  end
               end
            end
         end
      end
   end
   
   % cycle information from the float
   % N_CYCLE variables
   configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nCycleDimId);
   netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
   netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
   netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));
   
   cycleNumberIndexVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_INDEX', 'NC_INT', nCycleDimId);
   netcdf.putAtt(fCdf, cycleNumberIndexVarId, 'long_name', 'Cycle number that corresponds to the current index');
   netcdf.putAtt(fCdf, cycleNumberIndexVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
   netcdf.putAtt(fCdf, cycleNumberIndexVarId, '_FillValue', int32(99999));
   
   cycleNumberIndexAdjustedVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_INDEX_ADJUSTED', 'NC_INT', nCycleDimId);
   netcdf.putAtt(fCdf, cycleNumberIndexAdjustedVarId, 'long_name', 'Adjusted cycle number that corresponds to the current index');
   netcdf.putAtt(fCdf, cycleNumberIndexAdjustedVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
   netcdf.putAtt(fCdf, cycleNumberIndexAdjustedVarId, '_FillValue', int32(99999));
   
   dataModeVarId = netcdf.defVar(fCdf, 'DATA_MODE', 'NC_CHAR', nCycleDimId);
   netcdf.putAtt(fCdf, dataModeVarId, 'long_name', 'Delayed mode or real time data');
   netcdf.putAtt(fCdf, dataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
   netcdf.putAtt(fCdf, dataModeVarId, '_FillValue', ' ');
   
   % history information
   historyInstitutionVarId = netcdf.defVar(fCdf, 'HISTORY_INSTITUTION', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
   netcdf.putAtt(fCdf, historyInstitutionVarId, 'long_name', 'Institution which performed action');
   netcdf.putAtt(fCdf, historyInstitutionVarId, 'conventions', 'Argo reference table 4');
   netcdf.putAtt(fCdf, historyInstitutionVarId, '_FillValue', ' ');
   
   historyStepVarId = netcdf.defVar(fCdf, 'HISTORY_STEP', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
   netcdf.putAtt(fCdf, historyStepVarId, 'long_name', 'Step in data processing');
   netcdf.putAtt(fCdf, historyStepVarId, 'conventions', 'Argo reference table 12');
   netcdf.putAtt(fCdf, historyStepVarId, '_FillValue', ' ');
   
   historySoftwareVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
   netcdf.putAtt(fCdf, historySoftwareVarId, 'long_name', 'Name of software which performed action');
   netcdf.putAtt(fCdf, historySoftwareVarId, 'conventions', 'Institution dependent');
   netcdf.putAtt(fCdf, historySoftwareVarId, '_FillValue', ' ');
   
   historySoftwareReleaseVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE_RELEASE', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
   netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'long_name', 'Version/release of software which performed action');
   netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'conventions', 'Institution dependent');
   netcdf.putAtt(fCdf, historySoftwareReleaseVarId, '_FillValue', ' ');
   
   historyReferenceVarId = netcdf.defVar(fCdf, 'HISTORY_REFERENCE', 'NC_CHAR', fliplr([nHistoryDimId string64DimId]));
   netcdf.putAtt(fCdf, historyReferenceVarId, 'long_name', 'Reference of database');
   netcdf.putAtt(fCdf, historyReferenceVarId, 'conventions', 'Institution dependent');
   netcdf.putAtt(fCdf, historyReferenceVarId, '_FillValue', ' ');
   
   historyDateVarId = netcdf.defVar(fCdf, 'HISTORY_DATE', 'NC_CHAR', fliplr([nHistoryDimId dateTimeDimId]));
   netcdf.putAtt(fCdf, historyDateVarId, 'long_name', 'Date the history record was created');
   netcdf.putAtt(fCdf, historyDateVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, historyDateVarId, '_FillValue', ' ');
   
   historyActionVarId = netcdf.defVar(fCdf, 'HISTORY_ACTION', 'NC_CHAR', fliplr([nHistoryDimId string4DimId]));
   netcdf.putAtt(fCdf, historyActionVarId, 'long_name', 'Action performed on data');
   netcdf.putAtt(fCdf, historyActionVarId, 'conventions', 'Argo reference table 7');
   netcdf.putAtt(fCdf, historyActionVarId, '_FillValue', ' ');
   
   historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId string64DimId]));
   netcdf.putAtt(fCdf, historyParameterVarId, 'long_name', 'Station parameter action is performed on');
   netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Reference table AUX_3a');
   netcdf.putAtt(fCdf, historyParameterVarId, '_FillValue', ' ');
   
   if (doubleTypeInFile == 0)
      historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', nHistoryDimId);
      netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
      netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));
   else
      historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_DOUBLE', nHistoryDimId);
      netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
      netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', double(99999));
   end
   
   historyIndexDimensionVarId = netcdf.defVar(fCdf, 'HISTORY_INDEX_DIMENSION', 'NC_CHAR', nHistoryDimId);
   netcdf.putAtt(fCdf, historyIndexDimensionVarId, 'long_name', 'Name of dimension to which HISTORY_START_INDEX and HISTORY_STOP_INDEX correspond');
   netcdf.putAtt(fCdf, historyIndexDimensionVarId, 'conventions', 'C: N_CYCLE, M: N_MEASUREMENT');
   netcdf.putAtt(fCdf, historyIndexDimensionVarId, '_FillValue', ' ');
   
   historyStartIndexVarId = netcdf.defVar(fCdf, 'HISTORY_START_INDEX', 'NC_INT', nHistoryDimId);
   netcdf.putAtt(fCdf, historyStartIndexVarId, 'long_name', 'Start index action applied on');
   netcdf.putAtt(fCdf, historyStartIndexVarId, '_FillValue', int32(99999));
   
   historyStopIndexVarId = netcdf.defVar(fCdf, 'HISTORY_STOP_INDEX', 'NC_INT', nHistoryDimId);
   netcdf.putAtt(fCdf, historyStopIndexVarId, 'long_name', 'Stop index action applied on');
   netcdf.putAtt(fCdf, historyStopIndexVarId, '_FillValue', int32(99999));
   
   historyQcTestVarId = netcdf.defVar(fCdf, 'HISTORY_QCTEST', 'NC_CHAR', fliplr([nHistoryDimId string16DimId]));
   netcdf.putAtt(fCdf, historyQcTestVarId, 'long_name', 'Documentation of tests performed, tests failed (in hex form)');
   netcdf.putAtt(fCdf, historyQcTestVarId, 'conventions', 'Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
   netcdf.putAtt(fCdf, historyQcTestVarId, '_FillValue', ' ');
   
   % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % % DEFINE MODE END
   if (VERBOSE_MODE == 2)
      fprintf('STOP DEFINE MODE\n');
   end
   
   netcdf.endDef(fCdf);
   
   % general information on the trajectory file
   valueStr = 'Aux-Argo trajectory';
   netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);
   
   valueStr = '1.0';
   netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);
   
   netcdf.putVar(fCdf, referenceDateTimeVarId, '19500101000000');
   
   if (isempty(ncCreationDate))
      netcdf.putVar(fCdf, dateCreationVarId, currentDate);
   else
      netcdf.putVar(fCdf, dateCreationVarId, ncCreationDate);
   end
   
   netcdf.putVar(fCdf, dateUpdateVarId, currentDate);
   
   % general information on the float
   valueStr = sprintf('%d', g_decArgo_floatNum);
   netcdf.putVar(fCdf, platformNumberVarId, 0, length(valueStr), valueStr);
   
   valueStr = ' ';
   idVal = find(strcmp('PROJECT_NAME', a_metaDataFromJson) == 1);
   if (~isempty(idVal))
      valueStr = char(a_metaDataFromJson{idVal+1});
   end
   netcdf.putVar(fCdf, projectNameVarId, 0, length(valueStr), valueStr);
   
   valueStr = ' ';
   idVal = find(strcmp('PI_NAME', a_metaDataFromJson) == 1);
   if (~isempty(idVal))
      valueStr = char(a_metaDataFromJson{idVal+1});
   end
   netcdf.putVar(fCdf, piNameVarId, 0, length(valueStr), valueStr);
   
   for idParam = 1:length(measUniqueParamName)
      valueStr = char(measUniqueParamName(idParam));
      
      if (length(valueStr) > paramNameLength)
         fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) => name truncated\n', ...
            g_decArgo_floatNum, valueStr, paramNameLength);
         valueStr = valueStr(1:paramNameLength);
      end
      
      netcdf.putVar(fCdf, trajectoryParametersVarId, ...
         fliplr([idParam-1  0]), fliplr([1 length(valueStr)]), valueStr');
   end
   
   valueStr = ' ';
   idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
   if (~isempty(idVal))
      valueStr = char(a_metaDataFromJson{idVal+1});
   end
   netcdf.putVar(fCdf, dataCentreVarId, 0, length(valueStr), valueStr);
   
   valueStr = '1A';
   netcdf.putVar(fCdf, dataStateIndicatorVarId, 0, length(valueStr), valueStr);
   
   valueStr = get_platform_type(a_decoderId);
   valueStr = [valueStr blanks(32-length(valueStr))];
   netcdf.putVar(fCdf, platformTypeVarId, 0, length(valueStr), valueStr);
   
   valueStr = ' ';
   idVal = find(strcmp('FLOAT_SERIAL_NO', a_metaDataFromJson) == 1);
   if (~isempty(idVal))
      valueStr = char(a_metaDataFromJson{idVal+1});
   end
   netcdf.putVar(fCdf, floatSerialNoVarId, 0, length(valueStr), valueStr);
   
   valueStr = ' ';
   idVal = find(strcmp('FIRMWARE_VERSION', a_metaDataFromJson) == 1);
   if (~isempty(idVal))
      valueStr = char(a_metaDataFromJson{idVal+1});
   end
   netcdf.putVar(fCdf, firmwareVersionVarId, 0, length(valueStr), valueStr);
   
   valueStr = get_wmo_instrument_type(a_decoderId);
   netcdf.putVar(fCdf, wmoInstTypeVarId, 0, length(valueStr), valueStr);
   
   % copy existing history information
   if (~isempty(histoInstitution))
      if (length(ncDataMode) <= length(cycles))
         netcdf.putVar(fCdf, historyInstitutionVarId, ...
            fliplr([0 0]), fliplr([size(histoInstitution, 2) size(histoInstitution, 1)]), histoInstitution);
         netcdf.putVar(fCdf, historyStepVarId, ...
            fliplr([0 0]), fliplr([size(histoStep, 2) size(histoStep, 1)]), histoStep);
         netcdf.putVar(fCdf, historySoftwareVarId, ...
            fliplr([0 0]), fliplr([size(histoSoftware, 2) size(histoSoftware, 1)]), histoSoftware);
         netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
            fliplr([0 0]), fliplr([size(histoSoftwareRelease, 2) size(histoSoftwareRelease, 1)]), histoSoftwareRelease);
         netcdf.putVar(fCdf, historyDateVarId, ...
            fliplr([0 0]), fliplr([size(histoDate, 2) size(histoDate, 1)]), histoDate);
      else
         fprintf('WARNING: Float #%d : N_CYCLE=%d in existing file, N_CYCLE=%d in updated file => history information not copied when updating file %s\n', ...
            g_decArgo_floatNum, length(ncDataMode), length(cycles), ncPathFileName);
      end
   end
   
   % N_MEASUREMENT data
   
   cycleNumberVarFillValue = netcdf.getAtt(fCdf, cycleNumberVarId, '_FillValue');
   measurementCodeVarFillValue = netcdf.getAtt(fCdf, measurementCodeVarId, '_FillValue');
   juldVarFillValue = netcdf.getAtt(fCdf, juldVarId, '_FillValue');
   juldStatusVarFillValue = netcdf.getAtt(fCdf, juldStatusVarId, '_FillValue');
   juldQcVarFillValue = netcdf.getAtt(fCdf, juldQcVarId, '_FillValue');
   juldAdjustedVarFillValue = netcdf.getAtt(fCdf, juldAdjustedVarId, '_FillValue');
   juldAdjustedStatusVarFillValue = netcdf.getAtt(fCdf, juldAdjustedStatusVarId, '_FillValue');
   juldAdjustedQcVarFillValue = netcdf.getAtt(fCdf, juldAdjustedQcVarId, '_FillValue');
   
   measPos = 0;
   measPos2 = 0;
   for idNM = 1:length(a_tabTrajNMeas)
      nMeas = a_tabTrajNMeas(idNM);
      
      cycleNumberVarTab = int32(ones(length(nMeas.tabMeas), 1))*cycleNumberVarFillValue;
      measurementCodeVarTab = int32(ones(length(nMeas.tabMeas), 1))*measurementCodeVarFillValue;
      juldVarTab = ones(length(nMeas.tabMeas), 1)*juldVarFillValue;
      juldStatusVarTab = repmat(juldStatusVarFillValue, length(nMeas.tabMeas), 1);
      juldQcVarTab = repmat(juldQcVarFillValue, length(nMeas.tabMeas), 1);
      juldAdjustedVarTab = ones(length(nMeas.tabMeas), 1)*juldAdjustedVarFillValue;
      juldAdjustedStatusVarTab = repmat(juldAdjustedStatusVarFillValue, length(nMeas.tabMeas), 1);
      juldAdjustedQcVarTab = repmat(juldAdjustedQcVarFillValue, length(nMeas.tabMeas), 1);
      
      for idM = 1:length(nMeas.tabMeas)
         meas = nMeas.tabMeas(idM);
         
         if (~isempty(meas.paramList))
            
            cycleNumberVarTab(idM) = nMeas.outputCycleNumber;
            measurementCodeVarTab(idM) = meas.measCode;
            
            if (~isempty(meas.juld))
               juldVarTab(idM) = meas.juld;
            end
            if (~isempty(meas.juldStatus))
               juldStatusVarTab(idM) = meas.juldStatus;
            end
            if (~isempty(meas.juldQc))
               juldQcVarTab(idM) = meas.juldQc;
            end
            if (~isempty(meas.juldAdj))
               juldAdjustedVarTab(idM) = meas.juldAdj;
            end
            if (~isempty(meas.juldAdjStatus))
               juldAdjustedStatusVarTab(idM) = meas.juldAdjStatus;
            end
            if (~isempty(meas.juldAdjQc))
               juldAdjustedQcVarTab(idM) = meas.juldAdjQc;
            end
            
            % parameters
            measParamList = meas.paramList;
            for idParam = 1:length(measParamList)
               
               measParam = measParamList(idParam);
               
               measParamName = measParam.name;
               measParamVarId = netcdf.inqVarID(fCdf, measParamName);
               
               measParamQcVarId = '';
               if ~(strcmp(measParamName(end-3:end), '_STD') || ...
                     strcmp(measParamName(end-3:end), '_MED'))
                  measParamQcName = sprintf('%s_QC', measParamName);
                  measParamQcVarId = netcdf.inqVarID(fCdf, measParamQcName);
               end
               
               % parameter data
               if (isempty(meas.paramNumberWithSubLevels))
                  
                  % none of the profile parameters has sublevels
                  
                  % parameter data
                  paramData = meas.paramData(:, idParam);
                  if (isempty(meas.paramDataQc))
                     paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                     paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
                  else
                     paramDataQc = meas.paramDataQc(:, idParam);
                     if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                        paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                        paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
                     else
                        paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                        idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                        paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
                     end
                  end
                  
                  % store the data
                  netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
                  
                  if (~isempty(measParamQcVarId))
                     netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
                  end
               else
                  
                  % some profile parameters have sublevels
                  
                  % retrieve the column(s) associated with the parameter data
                  idF = find(meas.paramNumberWithSubLevels < idParam);
                  if (isempty(idF))
                     firstCol = idParam;
                  else
                     firstCol = idParam + sum(meas.paramNumberOfSubLevels(idF)) - length(idF);
                  end
                  
                  idF = find(meas.paramNumberWithSubLevels == idParam);
                  if (isempty(idF))
                     lastCol = firstCol;
                  else
                     lastCol = firstCol + meas.paramNumberOfSubLevels(idF) - 1;
                  end
                  
                  % parameter data
                  paramData = meas.paramData(:, firstCol:lastCol);
                  
                  if (size(paramData, 2) == 1)
                     
                     netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
                     
                     if (~isempty(measParamQcVarId))
                        if (isempty(meas.paramDataQc))
                           paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                           paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
                        else
                           paramDataQc = meas.paramDataQc(:, idParam);
                           if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                              paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
                           else
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                              idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                              paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
                           end
                        end
                        netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
                     end
                  else
                     
                     netcdf.putVar(fCdf, measParamVarId, fliplr([measPos 0]), fliplr([size(paramData)]), paramData');
                     
                     if (~isempty(measParamQcVarId))
                        if (isempty(meas.paramDataQc))
                           paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                           for idL = 1: size(paramData, 1)
                              if (~isempty(find(paramData(idL, :) ~= measParam.fillValue, 1)))
                                 paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
                              end
                           end
                        else
                           paramDataQc = meas.paramDataQc(:, idParam);
                           if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                              for idL = 1: size(paramData, 1)
                                 if (~isempty(find(paramData(idL, :) ~= measParam.fillValue, 1)))
                                    paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                 end
                              end
                           else
                              paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                              idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                              paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
                           end
                        end
                        netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
                     end
                  end
               end
            end
         end
         measPos = measPos + 1;
      end
      
      netcdf.putVar(fCdf, cycleNumberVarId, measPos2, length(nMeas.tabMeas), cycleNumberVarTab);
      netcdf.putVar(fCdf, measurementCodeVarId, measPos2, length(nMeas.tabMeas), measurementCodeVarTab);
      netcdf.putVar(fCdf, juldVarId, measPos2, length(nMeas.tabMeas), juldVarTab);
      netcdf.putVar(fCdf, juldStatusVarId, measPos2, length(nMeas.tabMeas), juldStatusVarTab);
      netcdf.putVar(fCdf, juldQcVarId, measPos2, length(nMeas.tabMeas), juldQcVarTab);
      netcdf.putVar(fCdf, juldAdjustedVarId, measPos2, length(nMeas.tabMeas), juldAdjustedVarTab);
      netcdf.putVar(fCdf, juldAdjustedStatusVarId, measPos2, length(nMeas.tabMeas), juldAdjustedStatusVarTab);
      netcdf.putVar(fCdf, juldAdjustedQcVarId, measPos2, length(nMeas.tabMeas), juldAdjustedQcVarTab);
      
      measPos2 = measPos2 + length(nMeas.tabMeas);
   end
   
   % not optimized version START
   %    measPos = 0;
   %    for idNM = 1:length(a_tabTrajNMeas)
   %       nMeas = a_tabTrajNMeas(idNM);
   %       for idM = 1:length(nMeas.tabMeas)
   %          meas = nMeas.tabMeas(idM);
   %
   %          if (~isempty(meas.paramList))
   %
   %             netcdf.putVar(fCdf, cycleNumberVarId, measPos, 1, nMeas.outputCycleNumber);
   %             netcdf.putVar(fCdf, measurementCodeVarId, measPos, 1, meas.measCode);
   %
   %             if (~isempty(meas.juld))
   %                netcdf.putVar(fCdf, juldVarId, measPos, 1, meas.juld);
   %             end
   %             if (~isempty(meas.juldStatus))
   %                netcdf.putVar(fCdf, juldStatusVarId, measPos, 1, meas.juldStatus);
   %             end
   %             if (~isempty(meas.juldQc))
   %                netcdf.putVar(fCdf, juldQcVarId, measPos, 1, meas.juldQc);
   %             end
   %             if (~isempty(meas.juldAdj))
   %                netcdf.putVar(fCdf, juldAdjustedVarId, measPos, 1, meas.juldAdj);
   %             end
   %             if (~isempty(meas.juldAdjStatus))
   %                netcdf.putVar(fCdf, juldAdjustedStatusVarId, measPos, 1, meas.juldAdjStatus);
   %             end
   %             if (~isempty(meas.juldAdjQc))
   %                netcdf.putVar(fCdf, juldAdjustedQcVarId, measPos, 1, meas.juldAdjQc);
   %             end
   %
   %             % parameters
   %             measParamList = meas.paramList;
   %             for idParam = 1:length(measParamList)
   %
   %                measParam = measParamList(idParam);
   %
   %                measParamName = measParam.name;
   %                measParamVarId = netcdf.inqVarID(fCdf, measParamName);
   %
   %                measParamQcVarId = '';
   %                if ~(strcmp(measParamName(end-3:end), '_STD') || ...
   %                      strcmp(measParamName(end-3:end), '_MED'))
   %                   measParamQcName = sprintf('%s_QC', measParamName);
   %                   measParamQcVarId = netcdf.inqVarID(fCdf, measParamQcName);
   %                end
   %
   %                % parameter data
   %                if (isempty(meas.paramNumberWithSubLevels))
   %
   %                   % none of the profile parameters has sublevels
   %
   %                   % parameter data
   %                   paramData = meas.paramData(:, idParam);
   %                   if (isempty(meas.paramDataQc))
   %                      paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
   %                      paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
   %                   else
   %                      paramDataQc = meas.paramDataQc(:, idParam);
   %                      if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
   %                         paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
   %                         paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
   %                      else
   %                         paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
   %                         idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
   %                         paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
   %                      end
   %                   end
   %
   %                   % store the data
   %                   netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
   %
   %                   if (~isempty(measParamQcVarId))
   %                      netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
   %                   end
   %                else
   %
   %                   % some profile parameters have sublevels
   %
   %                   % retrieve the column(s) associated with the parameter data
   %                   idF = find(meas.paramNumberWithSubLevels < idParam);
   %                   if (isempty(idF))
   %                      firstCol = idParam;
   %                   else
   %                      firstCol = idParam + sum(meas.paramNumberOfSubLevels(idF)) - length(idF);
   %                   end
   %
   %                   idF = find(meas.paramNumberWithSubLevels == idParam);
   %                   if (isempty(idF))
   %                      lastCol = firstCol;
   %                   else
   %                      lastCol = firstCol + meas.paramNumberOfSubLevels(idF) - 1;
   %                   end
   %
   %                   % parameter data
   %                   paramData = meas.paramData(:, firstCol:lastCol);
   %
   %                   if (size(paramData, 2) == 1)
   %
   %                      netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
   %
   %                      if (~isempty(measParamQcVarId))
   %                         if (isempty(meas.paramDataQc))
   %                            paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
   %                            paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
   %                         else
   %                            paramDataQc = meas.paramDataQc(:, idParam);
   %                            if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
   %                               paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
   %                               paramDataQcStr(find(paramData ~= measParam.fillValue)) = g_decArgo_qcStrNoQc;
   %                            else
   %                               paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
   %                               idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
   %                               paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
   %                            end
   %                         end
   %                         netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
   %                      end
   %                   else
   %
   %                      netcdf.putVar(fCdf, measParamVarId, fliplr([measPos 0]), fliplr([size(paramData)]), paramData');
   %
   %                      if (~isempty(measParamQcVarId))
   %                         if (isempty(meas.paramDataQc))
   %                            paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
   %                            for idL = 1: size(paramData, 1)
   %                               if (~isempty(find(paramData(idL, :) ~= measParam.fillValue, 1)))
   %                                  paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
   %                               end
   %                            end
   %                         else
   %                            paramDataQc = meas.paramDataQc(:, idParam);
   %                            if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
   %                               paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
   %                               for idL = 1: size(paramData, 1)
   %                                  if (~isempty(find(paramData(idL, :) ~= measParam.fillValue, 1)))
   %                                     paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
   %                                  end
   %                               end
   %                            else
   %                               paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
   %                               idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
   %                               paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
   %                            end
   %                         end
   %                         netcdf.putVar(fCdf, measParamQcVarId, measPos, size(paramData, 1), paramDataQcStr);
   %                      end
   %                   end
   %                end
   %             end
   %          end
   %          measPos = measPos + 1;
   %       end
   %    end
   % not optimized version END

   % N_CYCLE data
   if (~isempty(cycles))
      for idNC = 1:length(a_tabTrajNCycle)
         nCycle = a_tabTrajNCycle(idNC);
         
         idC = find(cycles == nCycle.outputCycleNumber);
         
         if (~isempty(nCycle.outputCycleNumber))
            netcdf.putVar(fCdf, cycleNumberIndexVarId, idC-1, 1, nCycle.outputCycleNumber);
         end
         if (~isempty(nCycle.configMissionNumber))
            netcdf.putVar(fCdf, configMissionNumberVarId, idC-1, 1, nCycle.configMissionNumber);
         end
         if (~isempty(nCycle.dataMode))
            netcdf.putVar(fCdf, dataModeVarId, idC-1, 1, nCycle.dataMode);
         end
      end
   else
      netcdf.putVar(fCdf, dataModeVarId, 0, 1, 'R');
   end
   
   % history information
   currentHistoId = 0;
   if (~isempty(histoInstitution))
      if (length(ncDataMode) <= length(cycles))
         currentHistoId = size(histoInstitution, 2);
      end
   end
   value = 'IF';
   netcdf.putVar(fCdf, historyInstitutionVarId, ...
      fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
   value = 'ARFM';
   netcdf.putVar(fCdf, historyStepVarId, ...
      fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
   value = 'CODA';
   netcdf.putVar(fCdf, historySoftwareVarId, ...
      fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
   value = g_decArgo_decoderVersion;
   netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
      fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
   value = currentDate;
   netcdf.putVar(fCdf, historyDateVarId, ...
      fliplr([currentHistoId 0]), fliplr([1 length(value)]), value');
   
   netcdf.close(fCdf);
   
   if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
      % store information for the XML report
      g_decArgo_reportStruct.outputTrajAuxFiles = [g_decArgo_reportStruct.outputTrajAuxFiles ...
         {ncPathFileName}];
   end
   
   fprintf('... NetCDF TRAJECTORY AUX file created\n');
   
end

return;
