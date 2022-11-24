% ------------------------------------------------------------------------------
% Create NetCDF TECH AUX file.
%
% SYNTAX :
%  create_nc_tech_aux_file(a_decoderId, ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, ...
%    a_tabNcTechLabelInfo, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_tabNcTechIndex     : index information on technical data
%   a_tabNcTechVal       : values of technical data
%   a_tabTechNMeas       : values of PARAM technical data
%   a_tabNcTechLabelInfo : additional information for technical labels
%   a_metaDataFromJson   : additional information retrieved from JSON meta-data
%                          file
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
function create_nc_tech_aux_file(a_decoderId, ...
   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, ...
   a_tabNcTechLabelInfo, a_metaDataFromJson)

% current float WMO number
global g_decArgo_floatNum;

% configuration values
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_applyRtqc;

% output NetCDF technical parameter Ids
global g_decArgo_outputNcParamId;

% output NetCDF technical parameter labels
global g_decArgo_outputNcParamLabel;
global g_decArgo_outputNcParamDescription;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;

% global default values
global g_decArgo_qcDef;


% verbose mode flag
VERBOSE_MODE = 1;

% consider only TECH_AUX labels
idToDel = zeros(size(a_tabNcTechIndex, 1), 1);
for idPar = 1:size(a_tabNcTechIndex, 1)
   idParamName = find(g_decArgo_outputNcParamId == a_tabNcTechIndex(idPar, 5));
   paramName = char(g_decArgo_outputNcParamLabel{idParamName});
   if (~strncmp(paramName, 'TECH_AUX', length('TECH_AUX')))
      idToDel(idPar) = 1;
   end   
end
a_tabNcTechIndex(find(idToDel == 1), :) = [];
a_tabNcTechVal(find(idToDel == 1)) = [];

% no data to save
if (isempty(a_tabNcTechIndex) && isempty(a_tabTechNMeas))
   return;
end
   
% retrieve auxiliary technical labels and descrptions for these float version
techAuxParamLabelList = [];
techAuxParamDescriptionList = [];
for idPar = 1:length(g_decArgo_outputNcParamLabel)
   if (strncmp(g_decArgo_outputNcParamLabel{idPar}, 'TECH_AUX', length('TECH_AUX')))
      paramLabel = g_decArgo_outputNcParamLabel{idPar};
      techAuxParamLabelList{end+1} = regexprep(paramLabel, 'TECH_AUX_', 'TECH_');
      techAuxParamDescriptionList{end+1} = g_decArgo_outputNcParamDescription{idPar};
   end
end

% collect information on technical parameters
measParamNameAll = [];
for idNM = 1:length(a_tabTechNMeas)
   nMeas = a_tabTechNMeas(idNM);
   if (~isempty(nMeas.tabMeas))
      measParamList = [nMeas.tabMeas.paramList];
      if (~isempty(measParamList))
         measParamNameList = {measParamList.name};
         measParamTypeList = [measParamList.paramType];
         idTech = find(measParamTypeList == 't');
         measParamNameAll = [measParamNameAll measParamNameList(idTech)];
      end
   end
end
measUniqueParamName = unique(measParamNameAll, 'stable');
nbMeasParam = length(measUniqueParamName);

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

ncFileName = [floatNumStr '_tech_aux.nc'];
ncPathFileName = [outputDirName  ncFileName];

% information to retrieve from a possible existing technical file
ncCreationDate = '';
if (exist(ncPathFileName, 'file') == 2)
   
   % retrieve information from existing file
   wantedTechVars = [ ...
      {'DATE_CREATION'} ...
      ];
   
   % retrieve information from TECH netCDF file
   [techData] = get_data_from_nc_file(ncPathFileName, wantedTechVars);
   
   idVal = find(strcmp('DATE_CREATION', techData) == 1);
   if (~isempty(idVal))
      ncCreationDate = techData{idVal+1}';
   end
   
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Updating NetCDF TECHNICAL AUX file (%s) ...\n', ncFileName);
   end
   
else
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Creating NetCDF TECHNICAL AUX file (%s) ...\n', ncFileName);
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
string1024DimId = netcdf.defDim(fCdf, 'STRING1024', 1024);
string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
if (nbMeasParam > 0)
   string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
   paramNameLength = 64;
end
string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

if (~isempty(techAuxParamLabelList))
   nTechAuxLabelDimId = netcdf.defDim(fCdf, 'N_TECH_AUX_LABEL', length(techAuxParamLabelList));
end

if (nbMeasParam > 0)
   nTechMeasParamDimId = netcdf.defDim(fCdf, 'N_TECH_MEAS_PARAM', nbMeasParam);
end

if (~isempty(a_tabTechNMeas))
   nTechMeasurementDimId = netcdf.defDim(fCdf, 'N_TECH_MEASUREMENT', sum(cellfun(@length, {a_tabTechNMeas.tabMeas})));
end

nTechParamDimId = netcdf.defDim(fCdf, 'N_TECH_PARAM', netcdf.getConstant('NC_UNLIMITED'));

% create global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float auxiliary technical data file');
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

% create general information variables
platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', string8DimId);
netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');

dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
netcdf.putAtt(fCdf, dataTypeVarId, 'conventions', 'Reference table AUX_1');
netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');

formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');

if (~isempty(a_tabTechNMeas))
   referenceDateTimeVarId = netcdf.defVar(fCdf, 'REFERENCE_DATE_TIME', 'NC_CHAR', dateTimeDimId);
   netcdf.putAtt(fCdf, referenceDateTimeVarId, 'long_name', 'Date of reference for Julian days');
   netcdf.putAtt(fCdf, referenceDateTimeVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, referenceDateTimeVarId, '_FillValue', ' ');
end

if (nbMeasParam > 0)
   technicalMeasParametersVarId = netcdf.defVar(fCdf, 'TECHNICAL_MEASUREMENT_PARAMETERS', 'NC_CHAR', fliplr([nTechMeasParamDimId string64DimId]));
   netcdf.putAtt(fCdf, technicalMeasParametersVarId, 'long_name', 'List of available technical parameters for the station');
   netcdf.putAtt(fCdf, technicalMeasParametersVarId, 'conventions', 'Reference table AUX_3b');
   netcdf.putAtt(fCdf, technicalMeasParametersVarId, '_FillValue', ' ');
end

dataCentreVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', string2DimId);
netcdf.putAtt(fCdf, dataCentreVarId, 'long_name', 'Data centre in charge of float data processing');
netcdf.putAtt(fCdf, dataCentreVarId, 'conventions', 'Argo reference table 4');
netcdf.putAtt(fCdf, dataCentreVarId, '_FillValue', ' ');

dateCreationVarId = netcdf.defVar(fCdf, 'DATE_CREATION', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateCreationVarId, 'long_name', 'Date of file creation');
netcdf.putAtt(fCdf, dateCreationVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateCreationVarId, '_FillValue', ' ');

dateUpdateVarId = netcdf.defVar(fCdf, 'DATE_UPDATE', 'NC_CHAR', dateTimeDimId);
netcdf.putAtt(fCdf, dateUpdateVarId, 'long_name', 'Date of update of this file');
netcdf.putAtt(fCdf, dateUpdateVarId, 'conventions', 'YYYYMMDDHHMISS');
netcdf.putAtt(fCdf, dateUpdateVarId, '_FillValue', ' ');

% create technical variables
technicalParameterNameVarId = netcdf.defVar(fCdf, 'TECHNICAL_PARAMETER_NAME', 'NC_CHAR', fliplr([nTechParamDimId string256DimId]));
netcdf.putAtt(fCdf, technicalParameterNameVarId, 'long_name', 'Name of technical parameter');
netcdf.putAtt(fCdf, technicalParameterNameVarId, '_FillValue', ' ');

technicalParameterValueVarId = netcdf.defVar(fCdf, 'TECHNICAL_PARAMETER_VALUE', 'NC_CHAR', fliplr([nTechParamDimId string256DimId]));
netcdf.putAtt(fCdf, technicalParameterValueVarId, 'long_name', 'Value of technical parameter');
netcdf.putAtt(fCdf, technicalParameterValueVarId, '_FillValue', ' ');

cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nTechParamDimId);
netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number');
netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle (if exists), 1 : first complete cycle');
netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));

% create technical auxiliary reference lists
if (~isempty(techAuxParamLabelList))
   refTechAuxParamLabelVarId = netcdf.defVar(fCdf, 'TECH_AUX_PARAM_LABEL', 'NC_CHAR', fliplr([nTechAuxLabelDimId string256DimId]));
   netcdf.putAtt(fCdf, refTechAuxParamLabelVarId, 'long_name', 'Name of auxiliary technical parameter label used by this float type and version');
   netcdf.putAtt(fCdf, refTechAuxParamLabelVarId, '_FillValue', ' ');
   
   refTechAuxParamDescriptionVarId = netcdf.defVar(fCdf, 'TECH_AUX_PARAM_DESCRIPTION', 'NC_CHAR', fliplr([nTechAuxLabelDimId string1024DimId]));
   netcdf.putAtt(fCdf, refTechAuxParamDescriptionVarId, 'long_name', 'Description of auxiliary technical parameter label used by this float type and version');
   netcdf.putAtt(fCdf, refTechAuxParamDescriptionVarId, '_FillValue', ' ');
end

% N_TECH_MEASUREMENT variables
if (~isempty(a_tabTechNMeas))
   
   juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
   netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
   netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   [resNominal, resComment] = get_param_comment_on_resolution('JULD', a_decoderId);
   netcdf.putAtt(fCdf, juldVarId, 'resolution', resNominal);
   netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
   netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');
   
   juldStatusVarId = netcdf.defVar(fCdf, 'JULD_STATUS', 'NC_CHAR', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldStatusVarId, 'long_name', 'Status of the date and time');
   netcdf.putAtt(fCdf, juldStatusVarId, 'conventions', 'Argo reference table 19');
   netcdf.putAtt(fCdf, juldStatusVarId, '_FillValue', ' ');
   
   juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
   netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');
   
   juldAdjustedVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED', 'NC_DOUBLE', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'long_name', 'Adjusted julian day (UTC) of each measurement relative to REFERENCE_DATE_TIME');
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'standard_name', 'time');
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   [resNominal, resComment] = get_param_comment_on_resolution('JULD_ADJUSTED', a_decoderId);
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'resolution', resNominal);
   netcdf.putAtt(fCdf, juldAdjustedVarId, '_FillValue', double(999999));
   netcdf.putAtt(fCdf, juldAdjustedVarId, 'axis', 'T');
   
   juldAdjustedStatusVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED_STATUS', 'NC_CHAR', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldAdjustedStatusVarId, 'long_name', 'Status of the JULD_ADJUSTED date');
   netcdf.putAtt(fCdf, juldAdjustedStatusVarId, 'conventions', 'Argo reference table 19');
   netcdf.putAtt(fCdf, juldAdjustedStatusVarId, '_FillValue', ' ');
   
   juldAdjustedQcVarId = netcdf.defVar(fCdf, 'JULD_ADJUSTED_QC', 'NC_CHAR', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldAdjustedQcVarId, 'long_name', 'Quality on adjusted date and time');
   netcdf.putAtt(fCdf, juldAdjustedQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, juldAdjustedQcVarId, '_FillValue', ' ');
   
   cycleNumberMeasVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_MEAS', 'NC_INT', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, cycleNumberMeasVarId, 'long_name', 'Float cycle number of the measurement');
   netcdf.putAtt(fCdf, cycleNumberMeasVarId, 'conventions', '0...N, 0 : launch cycle, 1 : first complete cycle');
   netcdf.putAtt(fCdf, cycleNumberMeasVarId, '_FillValue', int32(99999));
      
   measurementCodeVarId = netcdf.defVar(fCdf, 'MEASUREMENT_CODE', 'NC_INT', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, measurementCodeVarId, 'long_name', 'Flag referring to a measurement event in the cycle');
   netcdf.putAtt(fCdf, measurementCodeVarId, 'conventions', 'Argo reference table 15');
   netcdf.putAtt(fCdf, measurementCodeVarId, '_FillValue', int32(99999));
   
   % parameter variables
   paramNameDone = [];
   for idNM = 1:length(a_tabTechNMeas)
      nMeas = a_tabTechNMeas(idNM);
      for idM = 1:length(nMeas.tabMeas)
         meas = nMeas.tabMeas(idM);
         measParamList = meas.paramList;
         for idParam = 1:length(measParamList)
            measParam = measParamList(idParam);
            measParamName = measParam.name;
            measParamNcType = measParam.paramNcType;
            
            if (isempty(find(strcmp(measParamName, paramNameDone) == 1, 1)))
               
               paramNameDone = [paramNameDone; {measParamName}];
               
               % create parameter variable and attributes
               if (~var_is_present_dec_argo(fCdf, measParamName))
                  
                  measParamVarId = netcdf.defVar(fCdf, measParamName, measParamNcType, nTechMeasurementDimId);
                  
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
                  
                  if (~isempty(measParam.cFormat))
                     netcdf.putAtt(fCdf, measParamVarId, 'C_format', measParam.cFormat);
                  end
                  
                  if (~isempty(measParam.fortranFormat))
                     netcdf.putAtt(fCdf, measParamVarId, 'FORTRAN_format', measParam.fortranFormat);
                  end
                  
                  if (~isempty(measParam.resolution))
                     netcdf.putAtt(fCdf, measParamVarId, 'resolution', measParam.resolution);
                  end
                  
                  if (~isempty(measParam.axis))
                     netcdf.putAtt(fCdf, measParamVarId, 'axis', measParam.axis);
                  end
               end
               
               % parameter QC variable and attributes
               measParamQcName = sprintf('%s_QC', measParamName);
               if (~var_is_present_dec_argo(fCdf, measParamQcName))
                  
                  measParamQcVarId = netcdf.defVar(fCdf, measParamQcName, 'NC_CHAR', nTechMeasurementDimId);
                  
                  netcdf.putAtt(fCdf, measParamQcVarId, 'long_name', 'quality flag');
                  netcdf.putAtt(fCdf, measParamQcVarId, 'conventions', 'Argo reference table 2');
                  netcdf.putAtt(fCdf, measParamQcVarId, '_FillValue', ' ');
               end
            end
         end
      end
   end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % DEFINE MODE END
if (VERBOSE_MODE == 2)
   fprintf('STOP DEFINE MODE\n');
end

netcdf.endDef(fCdf);

% create general information variables
valueStr = sprintf('%d', g_decArgo_floatNum);
netcdf.putVar(fCdf, platformNumberVarId, 0, length(valueStr), valueStr);

valueStr = 'Argo auxiliary technical data';
netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);

valueStr = '1.0';
netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);

if (~isempty(a_tabTechNMeas))
   netcdf.putVar(fCdf, referenceDateTimeVarId, '19500101000000');
end

% add technical parameters
for idParam = 1:length(measUniqueParamName)
   valueStr = measUniqueParamName{idParam};
   
   if (length(valueStr) > paramNameLength)
      fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) => name truncated\n', ...
         g_decArgo_floatNum, valueStr, paramNameLength);
      valueStr = valueStr(1:paramNameLength);
   end
   
   netcdf.putVar(fCdf, technicalMeasParametersVarId, ...
      fliplr([idParam-1  0]), fliplr([1 length(valueStr)]), valueStr');
end

valueStr = ' ';
idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   valueStr = char(a_metaDataFromJson{idVal+1});
end
netcdf.putVar(fCdf, dataCentreVarId, 0, length(valueStr), valueStr);

if (isempty(ncCreationDate))
   netcdf.putVar(fCdf, dateCreationVarId, currentDate);
else
   netcdf.putVar(fCdf, dateCreationVarId, ncCreationDate);
end

netcdf.putVar(fCdf, dateUpdateVarId, currentDate);

% fill technical parameter variables
paramPos = 0;
for outputCycleNumber = min(a_tabNcTechIndex(:, 6)):max(a_tabNcTechIndex(:, 6))
   
   % list of concerned parameters
   idParam = find(a_tabNcTechIndex(:, 6) == outputCycleNumber);
   
   if (~isempty(idParam))
      for idP = 1:length(idParam)
         idPar = idParam(idP);
         
         idParamName = find(g_decArgo_outputNcParamId == a_tabNcTechIndex(idPar, 5));
         paramName = char(g_decArgo_outputNcParamLabel{idParamName});
         paramName = regexprep(paramName, 'TECH_AUX_', 'TECH_');
      
         if (a_tabNcTechIndex(idPar, 4) < -1)
            [paramName] = create_param_name_ir_rudics_sbd2(paramName, a_tabNcTechLabelInfo{a_tabNcTechIndex(idPar, 4)*-1});
         end
         netcdf.putVar(fCdf, technicalParameterNameVarId, fliplr([paramPos 0]), fliplr([1 length(paramName)]), paramName');
         
         paramValue = a_tabNcTechVal{idPar};
         if (isnumeric(paramValue))
            paramValueStr = num2str(paramValue);
         else
            paramValueStr = paramValue;
         end
         netcdf.putVar(fCdf, technicalParameterValueVarId, fliplr([paramPos 0]), fliplr([1 length(paramValueStr)]), paramValueStr');
         
         netcdf.putVar(fCdf, cycleNumberVarId, paramPos, 1, outputCycleNumber);
         
         paramPos = paramPos + 1;
      end
   end
end

% N_TECH_MEASUREMENT data
measPos = 0;
for idNM = 1:length(a_tabTechNMeas)
   nMeas = a_tabTechNMeas(idNM);
      
   for idM = 1:length(nMeas.tabMeas)
      meas = nMeas.tabMeas(idM);
      
      netcdf.putVar(fCdf, cycleNumberMeasVarId, measPos, 1, nMeas.outputCycleNumber);
      netcdf.putVar(fCdf, measurementCodeVarId, measPos, 1, meas.measCode);
      
      if (~isempty(meas.juld))
         netcdf.putVar(fCdf, juldVarId, measPos, 1, meas.juld);
      end
      if (~isempty(meas.juldStatus))
         netcdf.putVar(fCdf, juldStatusVarId, measPos, 1, meas.juldStatus);
      end
      if (~isempty(meas.juldQc))
         netcdf.putVar(fCdf, juldQcVarId, measPos, 1, meas.juldQc);
      end
      if (~isempty(meas.juldAdj))
         netcdf.putVar(fCdf, juldAdjustedVarId, measPos, 1, meas.juldAdj);
      end
      if (~isempty(meas.juldAdjStatus))
         netcdf.putVar(fCdf, juldAdjustedStatusVarId, measPos, 1, meas.juldAdjStatus);
      end
      if (~isempty(meas.juldAdjQc))
         netcdf.putVar(fCdf, juldAdjustedQcVarId, measPos, 1, meas.juldAdjQc);
      end
      
      % parameters
      measParamList = meas.paramList;
      for idParam = 1:length(measParamList)
         
         if (measParamList(idParam).paramType == 't')
            
            measParam = measParamList(idParam);
            
            measParamName = measParam.name;
            measParamVarId = netcdf.inqVarID(fCdf, measParamName);
            
            measParamQcName = sprintf('%s_QC', measParamName);
            measParamQcVarId = netcdf.inqVarID(fCdf, measParamQcName);
                        
            % parameter data
            paramData = meas.paramData(:, idParam);
            
            % store the data
            netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
            
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
      end
      measPos = measPos + 1;
   end
end

% fill auxiliary technical parameter labels and associated descriptions
paramPos = 0;
for idP = 1:length(techAuxParamLabelList)
   paramLabel = techAuxParamLabelList{idP};
   paramDescription = techAuxParamDescriptionList{idP};
   
   netcdf.putVar(fCdf, refTechAuxParamLabelVarId, fliplr([paramPos 0]), fliplr([1 length(paramLabel)]), paramLabel');
   netcdf.putVar(fCdf, refTechAuxParamDescriptionVarId, fliplr([paramPos 0]), fliplr([1 length(paramDescription)]), paramDescription');
   
   paramPos = paramPos + 1;
end

netcdf.close(fCdf);

if ((g_decArgo_realtimeFlag == 1)  || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
   % store information for the XML report
   g_decArgo_reportStruct.outputTechAuxFiles = [g_decArgo_reportStruct.outputTechAuxFiles ...
      {ncPathFileName}];
end

fprintf('... NetCDF TECHNICAL AUX file created\n');

return;
