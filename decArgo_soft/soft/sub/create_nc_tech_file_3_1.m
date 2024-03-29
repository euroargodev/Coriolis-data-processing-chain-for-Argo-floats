% ------------------------------------------------------------------------------
% Create NetCDF TECH file .
%
% SYNTAX :
%  create_nc_tech_file_3_1(a_decoderId, ...
%    a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, a_tabTechAuxNMeas, ...
%    a_tabNcTechLabelInfo, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId          : float decoder Id
%   a_tabNcTechIndex     : index information on technical data
%   a_tabNcTechVal       : values of technical data
%   a_tabTechNMeas       : values of technical parameter data
%   a_tabTechAuxNMeas    : values of technical parameter AUX data
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
%   06/22/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_tech_file_3_1(a_decoderId, ...
   a_tabNcTechIndex, a_tabNcTechVal, a_tabTechNMeas, a_tabTechAuxNMeas, ...
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

% decoder version
global g_decArgo_decoderVersion;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;


% verbose mode flag
VERBOSE_MODE = 1;

% consider only Argo TECH labels
idToDel = zeros(size(a_tabNcTechIndex, 1), 1);
techAuxData = 0;
for idPar = 1:size(a_tabNcTechIndex, 1)
   idParamName = find(g_decArgo_outputNcParamId == a_tabNcTechIndex(idPar, 5));
   paramName = char(g_decArgo_outputNcParamLabel{idParamName});
   if (strncmp(paramName, 'TECH_AUX', length('TECH_AUX')))
      idToDel(idPar) = 1;
      techAuxData = 1;
   end   
   if (strncmp(paramName, 'META_', length('META_')))
      idToDel(idPar) = 1;
   end
end
tabNcTechIndex = a_tabNcTechIndex;
tabNcTechVal = a_tabNcTechVal;
tabNcTechIndex(find(idToDel == 1), :) = [];
tabNcTechVal(find(idToDel == 1)) = [];

% create/update update NetCDF TECH_AUX file
if ((techAuxData == 1) || (~isempty(a_tabTechAuxNMeas)))
   create_nc_tech_aux_file(a_decoderId, ...
      a_tabNcTechIndex, a_tabNcTechVal, a_tabTechAuxNMeas, ...
      a_tabNcTechLabelInfo, a_metaDataFromJson);
end

% no data to save
if (isempty(tabNcTechIndex) && isempty(a_tabTechNMeas))
   return
end

% create output file pathname
floatNumStr = num2str(g_decArgo_floatNum);
outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

ncFileName = [floatNumStr '_tech.nc'];
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
      fprintf('Updating NetCDF TECHNICAL file (%s) ...\n', ncFileName);
   end
   
else
   if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
      fprintf('Creating NetCDF TECHNICAL file (%s) ...\n', ncFileName);
   end
end

currentDate = datestr(now_utc, 'yyyymmddHHMMSS');

% create and open NetCDF file
fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
if (isempty(fCdf))
   fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE MODE BEGIN
if (VERBOSE_MODE == 2)
   fprintf('START DEFINE MODE\n');
end

% create dimensions
dateTimeDimId = netcdf.defDim(fCdf, 'DATE_TIME', 14);
string128DimId = netcdf.defDim(fCdf, 'STRING128', 128);
string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

timeseriesFlag = 0;
if (~isempty(a_tabTechNMeas) && (sum(cellfun(@length, {a_tabTechNMeas.tabMeas})) ~= 0))
   nTechMeasurementDimId = netcdf.defDim(fCdf, 'N_TECH_MEASUREMENT', sum(cellfun(@length, {a_tabTechNMeas.tabMeas})));
   timeseriesFlag = 1;
end

nTechParamDimId = netcdf.defDim(fCdf, 'N_TECH_PARAM', netcdf.getConstant('NC_UNLIMITED'));

% create global attributes
globalVarId = netcdf.getConstant('NC_GLOBAL');
netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float technical data file');
institution = 'CORIOLIS';
idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
if (~isempty(idVal))
   dataCentre = char(a_metaDataFromJson{idVal+1});
   [institution] = get_institution_from_data_centre(dataCentre, 1);
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
netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.1');
netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));
netcdf.putAtt(fCdf, globalVarId, 'id', 'https://doi.org/10.17882/42182');

% create general information variables
platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', string8DimId);
netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');

dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string32DimId);
netcdf.putAtt(fCdf, dataTypeVarId, 'long_name', 'Data type');
netcdf.putAtt(fCdf, dataTypeVarId, 'conventions', 'Argo reference table 1');
netcdf.putAtt(fCdf, dataTypeVarId, '_FillValue', ' ');

formatVersionVarId = netcdf.defVar(fCdf, 'FORMAT_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, formatVersionVarId, 'long_name', 'File format version');
netcdf.putAtt(fCdf, formatVersionVarId, '_FillValue', ' ');

handbookVersionVarId = netcdf.defVar(fCdf, 'HANDBOOK_VERSION', 'NC_CHAR', string4DimId);
netcdf.putAtt(fCdf, handbookVersionVarId, 'long_name', 'Data handbook version');
netcdf.putAtt(fCdf, handbookVersionVarId, '_FillValue', ' ');

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
technicalParameterNameVarId = netcdf.defVar(fCdf, 'TECHNICAL_PARAMETER_NAME', 'NC_CHAR', fliplr([nTechParamDimId string128DimId]));
netcdf.putAtt(fCdf, technicalParameterNameVarId, 'long_name', 'Name of technical parameter');
netcdf.putAtt(fCdf, technicalParameterNameVarId, '_FillValue', ' ');

technicalParameterValueVarId = netcdf.defVar(fCdf, 'TECHNICAL_PARAMETER_VALUE', 'NC_CHAR', fliplr([nTechParamDimId string128DimId]));
netcdf.putAtt(fCdf, technicalParameterValueVarId, 'long_name', 'Value of technical parameter');
netcdf.putAtt(fCdf, technicalParameterValueVarId, '_FillValue', ' ');

cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nTechParamDimId);
netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number');
netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle (if exists), 1 : first complete cycle');
netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));

% create timeseries technical variables
if (timeseriesFlag)
   
   juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nTechMeasurementDimId);
   netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of each measurement');
   netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
   netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   [resNominal, resComment] = get_param_comment_on_resolution('JULD', a_decoderId);
   netcdf.putAtt(fCdf, juldVarId, 'resolution', resNominal);
   netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
   netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');

   cycleNumberMeasVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER_MEAS', 'NC_INT', nTechMeasurementDimId);
   
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
            
            if (isempty(find(strcmp(measParamName, paramNameDone), 1)))
               
               paramNameDone = [paramNameDone; {measParamName}];
               
               % create parameter variable and attributes
               if (~var_is_present_dec_argo(fCdf, measParamName))
                  
                  measParamVarId = netcdf.defVar(fCdf, measParamName, measParamNcType, nTechMeasurementDimId);
                  
                  if (~isempty(measParam.longName))
                     netcdf.putAtt(fCdf, measParamVarId, 'long_name', measParam.longName);
                  end
                  if (~isempty(measParam.fillValue))
                     netcdf.putAtt(fCdf, measParamVarId, '_FillValue', measParam.fillValue);
                  end
                  if (~isempty(measParam.units))
                     netcdf.putAtt(fCdf, measParamVarId, 'units', measParam.units);
                  end
                  
                  if (~isempty(measParam.cFormat))
                     netcdf.putAtt(fCdf, measParamVarId, 'C_format', measParam.cFormat);
                  end
                  
                  if (~isempty(measParam.fortranFormat))
                     netcdf.putAtt(fCdf, measParamVarId, 'FORTRAN_format', measParam.fortranFormat);
                  end
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

valueStr = 'Argo technical data';
netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);

valueStr = '3.1';
netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);

valueStr = '1.2';
netcdf.putVar(fCdf, handbookVersionVarId, 0, length(valueStr), valueStr);

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
if (~isempty(a_tabNcTechIndex))
   paramPos = 0;
   for outputCycleNumber = min(tabNcTechIndex(:, 6)):max(tabNcTechIndex(:, 6))

      % list of concerned parameters
      idParam = find(tabNcTechIndex(:, 6) == outputCycleNumber);

      if (~isempty(idParam))
         for idP = 1:length(idParam)
            idPar = idParam(idP);

            idParamName = find(g_decArgo_outputNcParamId == tabNcTechIndex(idPar, 5));
            paramName = char(g_decArgo_outputNcParamLabel{idParamName});

            if (tabNcTechIndex(idPar, 4) < -1)
               [paramName] = create_param_name_ir_rudics_sbd2(paramName, a_tabNcTechLabelInfo{tabNcTechIndex(idPar, 4)*-1});
            end
            netcdf.putVar(fCdf, technicalParameterNameVarId, fliplr([paramPos 0]), fliplr([1 length(paramName)]), paramName');

            paramValue = tabNcTechVal{idPar};
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
end

% N_TECH_MEASUREMENT data
if (timeseriesFlag)
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
         
         % parameters
         measParamList = meas.paramList;
         for idParam = 1:length(measParamList)
            
            if (measParamList(idParam).paramType == 't')
               
               measParam = measParamList(idParam);
               
               measParamName = measParam.name;
               measParamVarId = netcdf.inqVarID(fCdf, measParamName);
                              
               % parameter data
               paramData = meas.paramData(:, idParam);
               
               % store the data
               netcdf.putVar(fCdf, measParamVarId, measPos, size(paramData, 1), paramData);
            end
         end
         measPos = measPos + 1;
      end
   end
end

netcdf.close(fCdf);

if ((g_decArgo_realtimeFlag == 1)  || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
   % store information for the XML report
   g_decArgo_reportStruct.outputTechFiles = [g_decArgo_reportStruct.outputTechFiles ...
      {ncPathFileName}];
end

fprintf('... NetCDF TECHNICAL file created\n');

return
