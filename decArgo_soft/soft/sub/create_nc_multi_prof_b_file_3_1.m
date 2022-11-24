% ------------------------------------------------------------------------------
% Create NetCDF MULTI-PROFILE b files.
%
% SYNTAX :
%  create_nc_multi_prof_b_file_3_1( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
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
%   06/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_multi_prof_b_file_3_1( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson)

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrMissing;

% configuration values
global g_decArgo_dirOutputNetcdfFile;
global g_decArgo_applyRtqc;

% global default values
global g_decArgo_dateDef;
global g_decArgo_qcDef;

% decoder version
global g_decArgo_decoderVersion;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% report information structure
global g_decArgo_reportStruct;

% arrays to store RT offset information
global g_decArgo_rtOffsetInfo;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabProfiles))
   return;
end

% assign time resolution for each float transmission type
profJulDLocRes = double(1/5184000); % 1 second
[profJulDRes, profJulDComment] = get_prof_juld_resolution(g_decArgo_floatTransType, a_decoderId);

% collect information on core primary sampling profiles
profInfo = [];
profToDelIdList = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   
   if (profile.primarySamplingProfileFlag ~= 1)
      profToDelIdList = [profToDelIdList; idProf];
   else
      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end
      profInfo = [profInfo; ...
         [profile.outputCycleNumber direction]];
   end
end

% delete excluded profiles
if (~isempty(profToDelIdList))
   a_tabProfiles(profToDelIdList) = [];
end

% no data to save
if (isempty(a_tabProfiles))
   return;
end

% create the order to process profiles, the profile parameters list and compute
% the number of levels and sublevels
outputCycleNumberMin = min(profInfo(:, 1));
outputCycleNumberMax = max(profInfo(:, 1));

profIdList = [];
profParamName = [];
nbProfParam = 0;
nbProfLevels = 0;
profSubLevels = [];
paramNameSubLevels = [];
for outputCycleNumber = outputCycleNumberMin:outputCycleNumberMax
   for profileDir = 1:2
      
      % list of concerned profiles
      idProf = find((profInfo(:, 1) == outputCycleNumber) & ...
         (profInfo(:, 2) == profileDir));
      nbProf = length(idProf);
      
      for idP = 1:nbProf
         paramNameOfProf = [];
         prof = a_tabProfiles(idProf(idP));
         profIdList = [profIdList idProf(idP)];
         
         if (~is_core_profile(prof))
            
            parameterList = prof.paramList;
            profileData = prof.data;
            
            for idParam = 1:length(parameterList)
               if (((parameterList(idParam).paramType ~= 'c') || ...
                     strcmp(parameterList(idParam).name, 'PRES') || ...
                     strcmp(parameterList(idParam).name, 'PRES2')) && ...
                     ~strcmp(parameterList(idParam).name(end-3:end), '_STD') && ...
                     ~strcmp(parameterList(idParam).name(end-3:end), '_MED'))
                  
                  profParamName = [profParamName; {parameterList(idParam).name}];
                  paramNameOfProf = [paramNameOfProf; {parameterList(idParam).name}];
                  nbProfLevels = max(nbProfLevels, size(profileData, 1));
                  
                  if (~isempty(prof.paramNumberWithSubLevels))
                     idF = find(prof.paramNumberWithSubLevels == idParam);
                     if (~isempty(idF))
                        profSubLevels = [profSubLevels prof.paramNumberOfSubLevels(idF)];
                        paramNameSubLevels = [paramNameSubLevels {parameterList(idParam).name}];
                     end
                  end
               end
            end
            nbProfParam = max(nbProfParam, length(unique(paramNameOfProf)));
         end
      end
   end
end
profUniqueParamName = unique(profParamName, 'stable');

% due to erroneous received data, the number of sublevels can vary for a
% same parameter
paramSubLevels = unique(paramNameSubLevels, 'stable');
dimSubLevels = [];
for idParamSL = 1:length(paramSubLevels)
   dimSubLevels = [dimSubLevels ...
      max(profSubLevels(find(strcmp(paramNameSubLevels, paramSubLevels{idParamSL}))))];
end
profSubLevels = sort(unique(dimSubLevels), 'descend');
nbProfInFile = length(a_tabProfiles);

if (nbProfParam > 0)
   
   % create output file pathname
   floatNumStr = num2str(g_decArgo_floatNum);
   outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
   if ~(exist(outputDirName, 'dir') == 7)
      mkdir(outputDirName);
   end
   
   ncFileName = [floatNumStr '_Bprof.nc'];
   ncPathFileName = [outputDirName  ncFileName];
   
   % information to retrieve from a possible existing multi-profile file
   ncCreationDate = '';
   histoInstitution = '';
   histoStep = '';
   histoSoftware = '';
   histoSoftwareRelease = '';
   histoDate = '';
   if (exist(ncPathFileName, 'file') == 2)
      
      % retrieve information from existing file
      wantedProfVars = [ ...
         {'DATE_CREATION'} ...
         {'HISTORY_INSTITUTION'} ...
         {'HISTORY_STEP'} ...
         {'HISTORY_SOFTWARE'} ...
         {'HISTORY_SOFTWARE_RELEASE'} ...
         {'HISTORY_DATE'} ...
         ];
      
      % retrieve information from PROF netCDF file
      [profData] = get_data_from_nc_file(ncPathFileName, wantedProfVars);
      
      idVal = find(strcmp('DATE_CREATION', profData) == 1);
      if (~isempty(idVal))
         ncCreationDate = profData{idVal+1}';
      end
      idVal = find(strcmp('HISTORY_INSTITUTION', profData) == 1);
      if (~isempty(idVal))
         histoInstitution = profData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_STEP', profData) == 1);
      if (~isempty(idVal))
         histoStep = profData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_SOFTWARE', profData) == 1);
      if (~isempty(idVal))
         histoSoftware = profData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_SOFTWARE_RELEASE', profData) == 1);
      if (~isempty(idVal))
         histoSoftwareRelease = profData{idVal+1};
      end
      idVal = find(strcmp('HISTORY_DATE', profData) == 1);
      if (~isempty(idVal))
         histoDate = profData{idVal+1};
      end
      
      if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
         fprintf('Updating NetCDF MULTI-PROFILE b file (%s) ...\n', ncFileName);
      end
      
   else
      if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
         fprintf('Creating NetCDF MULTI-PROFILE b file (%s) ...\n', ncFileName);
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
   string256DimId = netcdf.defDim(fCdf, 'STRING256', 256);
   verticalSamplingSchemeLength = 256;
   string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
   paramNameLength = 64;
   string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
   string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
   string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
   string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
   string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);
   
   nProfDimId = netcdf.defDim(fCdf, 'N_PROF', nbProfInFile);
   nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbProfParam);
   nLevelsDimId = netcdf.defDim(fCdf, 'N_LEVELS', nbProfLevels);
   for idSL = 1:length(profSubLevels)
      netcdf.defDim(fCdf, sprintf('N_VALUES%d', profSubLevels(idSL)), profSubLevels(idSL));
   end
   % N_CALIB dimension is processed and created later
   nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', netcdf.getConstant('NC_UNLIMITED'));
   
   if (VERBOSE_MODE == 2)
      fprintf('N_PROF = %d\n', nbProfInFile);
      fprintf('N_PARAM = %d\n', nbProfParam);
      fprintf('N_LEVELS = %d\n', nbProfLevels);
      for idSL = 1:length(profSubLevels)
         fprintf('N_SUBLEVELS%d = %d\n', profSubLevels(idSL), profSubLevels(idSL));
      end
   end
   
   % create global attributes
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
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
   netcdf.putAtt(fCdf, globalVarId, 'references', 'http://www.argodatamgt.org/Documentation');
   netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '3.1');
   netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'Argo-3.1 CF-1.6');
   netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');
   
   % create misc variables
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
   
   % create profile variables
   platformNumberVarId = netcdf.defVar(fCdf, 'PLATFORM_NUMBER', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
   netcdf.putAtt(fCdf, platformNumberVarId, 'long_name', 'Float unique identifier');
   netcdf.putAtt(fCdf, platformNumberVarId, 'conventions', 'WMO float identifier : A9IIIII');
   netcdf.putAtt(fCdf, platformNumberVarId, '_FillValue', ' ');
   
   projectNameVarId = netcdf.defVar(fCdf, 'PROJECT_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
   netcdf.putAtt(fCdf, projectNameVarId, 'long_name', 'Name of the project');
   netcdf.putAtt(fCdf, projectNameVarId, '_FillValue', ' ');
   
   piNameVarId = netcdf.defVar(fCdf, 'PI_NAME', 'NC_CHAR', fliplr([nProfDimId string64DimId]));
   netcdf.putAtt(fCdf, piNameVarId, 'long_name', 'Name of the principal investigator');
   netcdf.putAtt(fCdf, piNameVarId, '_FillValue', ' ');
   
   stationParametersVarId = netcdf.defVar(fCdf, 'STATION_PARAMETERS', 'NC_CHAR', fliplr([nProfDimId nParamDimId string64DimId]));
   netcdf.putAtt(fCdf, stationParametersVarId, 'long_name', 'List of available parameters for the station');
   netcdf.putAtt(fCdf, stationParametersVarId, 'conventions', 'Argo reference table 3');
   netcdf.putAtt(fCdf, stationParametersVarId, '_FillValue', ' ');
   
   cycleNumberVarId = netcdf.defVar(fCdf, 'CYCLE_NUMBER', 'NC_INT', nProfDimId);
   netcdf.putAtt(fCdf, cycleNumberVarId, 'long_name', 'Float cycle number');
   netcdf.putAtt(fCdf, cycleNumberVarId, 'conventions', '0...N, 0 : launch cycle (if exists), 1 : first complete cycle');
   netcdf.putAtt(fCdf, cycleNumberVarId, '_FillValue', int32(99999));
   
   directionVarId = netcdf.defVar(fCdf, 'DIRECTION', 'NC_CHAR', nProfDimId);
   netcdf.putAtt(fCdf, directionVarId, 'long_name', 'Direction of the station profiles');
   netcdf.putAtt(fCdf, directionVarId, 'conventions', 'A: ascending profiles, D: descending profiles');
   netcdf.putAtt(fCdf, directionVarId, '_FillValue', ' ');
   
   dataCenterVarId = netcdf.defVar(fCdf, 'DATA_CENTRE', 'NC_CHAR', fliplr([nProfDimId string2DimId]));
   netcdf.putAtt(fCdf, dataCenterVarId, 'long_name', 'Data centre in charge of float data processing');
   netcdf.putAtt(fCdf, dataCenterVarId, 'conventions', 'Argo reference table 4');
   netcdf.putAtt(fCdf, dataCenterVarId, '_FillValue', ' ');
   
   dcReferenceVarId = netcdf.defVar(fCdf, 'DC_REFERENCE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
   netcdf.putAtt(fCdf, dcReferenceVarId, 'long_name', 'Station unique identifier in data centre');
   netcdf.putAtt(fCdf, dcReferenceVarId, 'conventions', 'Data centre convention');
   netcdf.putAtt(fCdf, dcReferenceVarId, '_FillValue', ' ');
   
   dataStateIndicatorVarId = netcdf.defVar(fCdf, 'DATA_STATE_INDICATOR', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'long_name', 'Degree of processing the data have passed through');
   netcdf.putAtt(fCdf, dataStateIndicatorVarId, 'conventions', 'Argo reference table 6');
   netcdf.putAtt(fCdf, dataStateIndicatorVarId, '_FillValue', ' ');
   
   dataModeVarId = netcdf.defVar(fCdf, 'DATA_MODE', 'NC_CHAR', nProfDimId);
   netcdf.putAtt(fCdf, dataModeVarId, 'long_name', 'Delayed mode or real time data');
   netcdf.putAtt(fCdf, dataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
   netcdf.putAtt(fCdf, dataModeVarId, '_FillValue', ' ');
   
   parameterDataModeVarId = netcdf.defVar(fCdf, 'PARAMETER_DATA_MODE', 'NC_CHAR', fliplr([nProfDimId nParamDimId]));
   netcdf.putAtt(fCdf, parameterDataModeVarId, 'long_name', 'Delayed mode or real time data');
   netcdf.putAtt(fCdf, parameterDataModeVarId, 'conventions', 'R : real time; D : delayed mode; A : real time with adjustment');
   netcdf.putAtt(fCdf, parameterDataModeVarId, '_FillValue', ' ');
   
   platformTypeVarId = netcdf.defVar(fCdf, 'PLATFORM_TYPE', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
   netcdf.putAtt(fCdf, platformTypeVarId, 'long_name', 'Type of float');
   netcdf.putAtt(fCdf, platformTypeVarId, 'conventions', 'Argo reference table 23');
   netcdf.putAtt(fCdf, platformTypeVarId, '_FillValue', ' ');
   
   floatSerialNoVarId = netcdf.defVar(fCdf, 'FLOAT_SERIAL_NO', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
   netcdf.putAtt(fCdf, floatSerialNoVarId, 'long_name', 'Serial number of the float');
   netcdf.putAtt(fCdf, floatSerialNoVarId, '_FillValue', ' ');
   
   firmwareVersionVarId = netcdf.defVar(fCdf, 'FIRMWARE_VERSION', 'NC_CHAR', fliplr([nProfDimId string32DimId]));
   netcdf.putAtt(fCdf, firmwareVersionVarId, 'long_name', 'Instrument firmware version');
   netcdf.putAtt(fCdf, firmwareVersionVarId, '_FillValue', ' ');
   
   wmoInstTypeVarId = netcdf.defVar(fCdf, 'WMO_INST_TYPE', 'NC_CHAR', fliplr([nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, wmoInstTypeVarId, 'long_name', 'Coded instrument type');
   netcdf.putAtt(fCdf, wmoInstTypeVarId, 'conventions', 'Argo reference table 8');
   netcdf.putAtt(fCdf, wmoInstTypeVarId, '_FillValue', ' ');
   
   juldVarId = netcdf.defVar(fCdf, 'JULD', 'NC_DOUBLE', nProfDimId);
   netcdf.putAtt(fCdf, juldVarId, 'long_name', 'Julian day (UTC) of the station relative to REFERENCE_DATE_TIME');
   netcdf.putAtt(fCdf, juldVarId, 'standard_name', 'time');
   netcdf.putAtt(fCdf, juldVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   netcdf.putAtt(fCdf, juldVarId, 'resolution', profJulDRes);
   netcdf.putAtt(fCdf, juldVarId, '_FillValue', double(999999));
   netcdf.putAtt(fCdf, juldVarId, 'axis', 'T');
   if (~isempty(profJulDComment))
      netcdf.putAtt(fCdf, juldVarId, 'comment_on_resolution', profJulDComment);
   end
   
   juldQcVarId = netcdf.defVar(fCdf, 'JULD_QC', 'NC_CHAR', nProfDimId);
   netcdf.putAtt(fCdf, juldQcVarId, 'long_name', 'Quality on date and time');
   netcdf.putAtt(fCdf, juldQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, juldQcVarId, '_FillValue', ' ');
   
   juldLocationVarId = netcdf.defVar(fCdf, 'JULD_LOCATION', 'NC_DOUBLE', nProfDimId);
   netcdf.putAtt(fCdf, juldLocationVarId, 'long_name', 'Julian day (UTC) of the location relative to REFERENCE_DATE_TIME');
   netcdf.putAtt(fCdf, juldLocationVarId, 'units', 'days since 1950-01-01 00:00:00 UTC');
   netcdf.putAtt(fCdf, juldLocationVarId, 'conventions', 'Relative julian days with decimal part (as parts of day)');
   netcdf.putAtt(fCdf, juldLocationVarId, 'resolution', profJulDLocRes);
   netcdf.putAtt(fCdf, juldLocationVarId, '_FillValue', double(999999));
   
   latitudeVarId = netcdf.defVar(fCdf, 'LATITUDE', 'NC_DOUBLE', nProfDimId);
   netcdf.putAtt(fCdf, latitudeVarId, 'long_name', 'Latitude of the station, best estimate');
   netcdf.putAtt(fCdf, latitudeVarId, 'standard_name', 'latitude');
   netcdf.putAtt(fCdf, latitudeVarId, 'units', 'degree_north');
   netcdf.putAtt(fCdf, latitudeVarId, '_FillValue', double(99999));
   netcdf.putAtt(fCdf, latitudeVarId, 'valid_min', double(-90));
   netcdf.putAtt(fCdf, latitudeVarId, 'valid_max', double(90));
   netcdf.putAtt(fCdf, latitudeVarId, 'axis', 'Y');
   
   longitudeVarId = netcdf.defVar(fCdf, 'LONGITUDE', 'NC_DOUBLE', nProfDimId);
   netcdf.putAtt(fCdf, longitudeVarId, 'long_name', 'Longitude of the station, best estimate');
   netcdf.putAtt(fCdf, longitudeVarId, 'standard_name', 'longitude');
   netcdf.putAtt(fCdf, longitudeVarId, 'units', 'degree_east');
   netcdf.putAtt(fCdf, longitudeVarId, '_FillValue', double(99999));
   netcdf.putAtt(fCdf, longitudeVarId, 'valid_min', double(-180));
   netcdf.putAtt(fCdf, longitudeVarId, 'valid_max', double(180));
   netcdf.putAtt(fCdf, longitudeVarId, 'axis', 'X');
   
   positionQcVarId = netcdf.defVar(fCdf, 'POSITION_QC', 'NC_CHAR', nProfDimId);
   netcdf.putAtt(fCdf, positionQcVarId, 'long_name', 'Quality on position (latitude and longitude)');
   netcdf.putAtt(fCdf, positionQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, positionQcVarId, '_FillValue', ' ');
   
   positioningSystemVarId = netcdf.defVar(fCdf, 'POSITIONING_SYSTEM', 'NC_CHAR', fliplr([nProfDimId string8DimId]));
   netcdf.putAtt(fCdf, positioningSystemVarId, 'long_name', 'Positioning system');
   netcdf.putAtt(fCdf, positioningSystemVarId, '_FillValue', ' ');
   
   % global quality of PARAM profile
   for idParam = 1:length(profUniqueParamName)
      profParamName = profUniqueParamName{idParam};
      if (~strcmp(profParamName, 'PRES') && ~strcmp(profParamName, 'PRES2'))
         ncParamName = sprintf('PROFILE_%s_QC', profParamName);
         
         profileParamQcVarId = netcdf.defVar(fCdf, ncParamName, 'NC_CHAR', nProfDimId);
         netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', profParamName));
         netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
         netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
      end
   end
   
   verticalSamplingSchemeVarId = netcdf.defVar(fCdf, 'VERTICAL_SAMPLING_SCHEME', 'NC_CHAR', fliplr([nProfDimId string256DimId]));
   netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'long_name', 'Vertical sampling scheme');
   netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, 'conventions', 'Argo reference table 16');
   netcdf.putAtt(fCdf, verticalSamplingSchemeVarId, '_FillValue', ' ');
   
   configMissionNumberVarId = netcdf.defVar(fCdf, 'CONFIG_MISSION_NUMBER', 'NC_INT', nProfDimId);
   netcdf.putAtt(fCdf, configMissionNumberVarId, 'long_name', 'Unique number denoting the missions performed by the float');
   netcdf.putAtt(fCdf, configMissionNumberVarId, 'conventions', '1...N, 1 : first complete mission');
   netcdf.putAtt(fCdf, configMissionNumberVarId, '_FillValue', int32(99999));
   
   % add profile data
   doubleTypeInFile = 0;
   for idP = 1:length(a_tabProfiles)
      prof = a_tabProfiles(profIdList(idP));
      
      if (~is_core_profile(prof))
         
         % profile parameter data
         parameterList = prof.paramList;
         for idParam = 1:length(parameterList)
            
            if ((parameterList(idParam).paramType ~= 'c') || ...
                  strcmp(parameterList(idParam).name, 'PRES') || ...
                  strcmp(parameterList(idParam).name, 'PRES2'))
               
               profParam = parameterList(idParam);
               profParamName = profParam.name;

               % find if this parameter has sublevels
               paramWithSubLevels = 0;
               if (~isempty(prof.paramNumberWithSubLevels))
                  idF = find(prof.paramNumberWithSubLevels == idParam);
                  if (~isempty(idF))
                     paramWithSubLevels = 1;
                     paramSubLevelsDim = dimSubLevels(find(strcmp(profParamName, paramSubLevels), 1));
                     %                      nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', prof.paramNumberOfSubLevels(idF)));
                     nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', paramSubLevelsDim));
                  end
               end
                             
               % parameter variable and attributes
               if (~var_is_present_dec_argo(fCdf, profParamName))
                  
                  varType = 'NC_FLOAT';
                  if ((strncmp(profParamName, 'RAW_DOWNWELLING_IRRADIANCE', length('RAW_DOWNWELLING_IRRADIANCE')) == 1) || ...
                        (strncmp(profParamName, 'RAW_DOWNWELLING_PAR', length('RAW_DOWNWELLING_PAR')) == 1))
                     varType = 'NC_DOUBLE';
                     doubleTypeInFile = 1;
                  end
                  if (paramWithSubLevels == 0)
                     profParamVarId = netcdf.defVar(fCdf, profParamName, varType, fliplr([nProfDimId nLevelsDimId]));
                  else
                     profParamVarId = netcdf.defVar(fCdf, profParamName, varType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
                  end
                  
                  if (~isempty(profParam.longName))
                     netcdf.putAtt(fCdf, profParamVarId, 'long_name', profParam.longName);
                  end
                  if (~isempty(profParam.standardName))
                     netcdf.putAtt(fCdf, profParamVarId, 'standard_name', profParam.standardName);
                  end
                  if (~isempty(profParam.fillValue))
                     netcdf.putAtt(fCdf, profParamVarId, '_FillValue', profParam.fillValue);
                  end
                  if (~isempty(profParam.units))
                     netcdf.putAtt(fCdf, profParamVarId, 'units', profParam.units);
                  end
                  if (~isempty(profParam.validMin))
                     netcdf.putAtt(fCdf, profParamVarId, 'valid_min', profParam.validMin);
                  end
                  if (~isempty(profParam.validMax))
                     netcdf.putAtt(fCdf, profParamVarId, 'valid_max', profParam.validMax);
                  end
                  if (~isempty(profParam.cFormat))
                     netcdf.putAtt(fCdf, profParamVarId, 'C_format', profParam.cFormat);
                  end
                  if (~isempty(profParam.fortranFormat))
                     netcdf.putAtt(fCdf, profParamVarId, 'FORTRAN_format', profParam.fortranFormat);
                  end
                  if (~isempty(profParam.resolution))
                     netcdf.putAtt(fCdf, profParamVarId, 'resolution', profParam.resolution);
                  end
                  if (~isempty(profParam.axis))
                     netcdf.putAtt(fCdf, profParamVarId, 'axis', profParam.axis);
                  end
               end
               
               % parameter QC variable and attributes
               if (profParam.paramType ~= 'c')
                  if ~(strcmp(profParam.name(end-3:end), '_STD') || ...
                        strcmp(profParam.name(end-3:end), '_MED'))
                     
                     profParamQcName = sprintf('%s_QC', profParam.name);
                     if (~var_is_present_dec_argo(fCdf, profParamQcName))
                        
                        profParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
                        
                        netcdf.putAtt(fCdf, profParamQcVarId, 'long_name', 'quality flag');
                        netcdf.putAtt(fCdf, profParamQcVarId, 'conventions', 'Argo reference table 2');
                        netcdf.putAtt(fCdf, profParamQcVarId, '_FillValue', ' ');
                     end
                  end
               end
               
               % parameter adjusted variable and attributes
               if ((profParam.adjAllowed == 1) && (profParam.paramType ~= 'c'))
                  
                  profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                  if (~var_is_present_dec_argo(fCdf, profParamAdjName))
                     
                     if (paramWithSubLevels == 0)
                        profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, varType, fliplr([nProfDimId nLevelsDimId]));
                     else
                        profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, varType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
                     end
                     
                     if (~isempty(profParam.longName))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'long_name', profParam.longName);
                     end
                     if (~isempty(profParam.standardName))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'standard_name', profParam.standardName);
                     end
                     if (~isempty(profParam.fillValue))
                        netcdf.putAtt(fCdf, profParamAdjVarId, '_FillValue', profParam.fillValue);
                     end
                     if (~isempty(profParam.units))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'units', profParam.units);
                     end
                     if (~isempty(profParam.validMin))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_min', profParam.validMin);
                     end
                     if (~isempty(profParam.validMax))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'valid_max', profParam.validMax);
                     end
                     if (~isempty(profParam.cFormat))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'C_format', profParam.cFormat);
                     end
                     if (~isempty(profParam.fortranFormat))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'FORTRAN_format', profParam.fortranFormat);
                     end
                     if (~isempty(profParam.resolution))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'resolution', profParam.resolution);
                     end
                     if (~isempty(profParam.axis))
                        netcdf.putAtt(fCdf, profParamAdjVarId, 'axis', profParam.axis);
                     end
                  end
                  
                  % parameter adjusted QC variable and attributes
                  profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
                  if (~var_is_present_dec_argo(fCdf, profParamAdjQcName))
                     
                     profParamAdjQcVarId = netcdf.defVar(fCdf, profParamAdjQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
                     
                     netcdf.putAtt(fCdf, profParamAdjQcVarId, 'long_name', 'quality flag');
                     netcdf.putAtt(fCdf, profParamAdjQcVarId, 'conventions', 'Argo reference table 2');
                     netcdf.putAtt(fCdf, profParamAdjQcVarId, '_FillValue', ' ');
                  end
                  
                  % parameter adjusted error variable and attributes
                  profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
                  if (~var_is_present_dec_argo(fCdf, profParamAdjErrName))
                     
                     if (paramWithSubLevels == 0)
                        profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, varType, fliplr([nProfDimId nLevelsDimId]));
                     else
                        profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, varType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
                     end
                     
                     netcdf.putAtt(fCdf, profParamAdjErrVarId, 'long_name', g_decArgo_longNameOfParamAdjErr);
                     if (~isempty(profParam.fillValue))
                        netcdf.putAtt(fCdf, profParamAdjErrVarId, '_FillValue', profParam.fillValue);
                     end
                     if (~isempty(profParam.units))
                        netcdf.putAtt(fCdf, profParamAdjErrVarId, 'units', profParam.units);
                     end
                     if (~isempty(profParam.cFormat))
                        netcdf.putAtt(fCdf, profParamAdjErrVarId, 'C_format', profParam.cFormat);
                     end
                     if (~isempty(profParam.fortranFormat))
                        netcdf.putAtt(fCdf, profParamAdjErrVarId, 'FORTRAN_format', profParam.fortranFormat);
                     end
                     if (~isempty(profParam.resolution))
                        netcdf.putAtt(fCdf, profParamAdjErrVarId, 'resolution', profParam.resolution);
                     end
                  end
               end
            end
         end
      end
   end
   
   % history information
   historyInstitutionVarId = netcdf.defVar(fCdf, 'HISTORY_INSTITUTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, historyInstitutionVarId, 'long_name', 'Institution which performed action');
   netcdf.putAtt(fCdf, historyInstitutionVarId, 'conventions', 'Argo reference table 4');
   netcdf.putAtt(fCdf, historyInstitutionVarId, '_FillValue', ' ');
   
   historyStepVarId = netcdf.defVar(fCdf, 'HISTORY_STEP', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, historyStepVarId, 'long_name', 'Step in data processing');
   netcdf.putAtt(fCdf, historyStepVarId, 'conventions', 'Argo reference table 12');
   netcdf.putAtt(fCdf, historyStepVarId, '_FillValue', ' ');
   
   historySoftwareVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, historySoftwareVarId, 'long_name', 'Name of software which performed action');
   netcdf.putAtt(fCdf, historySoftwareVarId, 'conventions', 'Institution dependent');
   netcdf.putAtt(fCdf, historySoftwareVarId, '_FillValue', ' ');
   
   historySoftwareReleaseVarId = netcdf.defVar(fCdf, 'HISTORY_SOFTWARE_RELEASE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'long_name', 'Version/release of software which performed action');
   netcdf.putAtt(fCdf, historySoftwareReleaseVarId, 'conventions', 'Institution dependent');
   netcdf.putAtt(fCdf, historySoftwareReleaseVarId, '_FillValue', ' ');
   
   historyReferenceVarId = netcdf.defVar(fCdf, 'HISTORY_REFERENCE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string64DimId]));
   netcdf.putAtt(fCdf, historyReferenceVarId, 'long_name', 'Reference of database');
   netcdf.putAtt(fCdf, historyReferenceVarId, 'conventions', 'Institution dependent');
   netcdf.putAtt(fCdf, historyReferenceVarId, '_FillValue', ' ');
   
   historyDateVarId = netcdf.defVar(fCdf, 'HISTORY_DATE', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId dateTimeDimId]));
   netcdf.putAtt(fCdf, historyDateVarId, 'long_name', 'Date the history record was created');
   netcdf.putAtt(fCdf, historyDateVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, historyDateVarId, '_FillValue', ' ');
   
   historyActionVarId = netcdf.defVar(fCdf, 'HISTORY_ACTION', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string4DimId]));
   netcdf.putAtt(fCdf, historyActionVarId, 'long_name', 'Action performed on data');
   netcdf.putAtt(fCdf, historyActionVarId, 'conventions', 'Argo reference table 7');
   netcdf.putAtt(fCdf, historyActionVarId, '_FillValue', ' ');
   
   historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string64DimId]));
   netcdf.putAtt(fCdf, historyParameterVarId, 'long_name', 'Station parameter action is performed on');
   netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Argo reference table 3');
   netcdf.putAtt(fCdf, historyParameterVarId, '_FillValue', ' ');
   
   historyStartPresVarId = netcdf.defVar(fCdf, 'HISTORY_START_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
   netcdf.putAtt(fCdf, historyStartPresVarId, 'long_name', 'Start pressure action applied on');
   netcdf.putAtt(fCdf, historyStartPresVarId, '_FillValue', single(99999));
   netcdf.putAtt(fCdf, historyStartPresVarId, 'units', 'decibar');
   
   historyStopPresVarId = netcdf.defVar(fCdf, 'HISTORY_STOP_PRES', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
   netcdf.putAtt(fCdf, historyStopPresVarId, 'long_name', 'Stop pressure action applied on');
   netcdf.putAtt(fCdf, historyStopPresVarId, '_FillValue', single(99999));
   netcdf.putAtt(fCdf, historyStopPresVarId, 'units', 'decibar');
   
   if (doubleTypeInFile == 0)
      historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
      netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
      netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));
   else
      historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_DOUBLE', fliplr([nHistoryDimId nProfDimId]));
      netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
      netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', double(99999));
   end
   
   historyQcTestVarId = netcdf.defVar(fCdf, 'HISTORY_QCTEST', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
   netcdf.putAtt(fCdf, historyQcTestVarId, 'long_name', 'Documentation of tests performed, tests failed (in hex form)');
   netcdf.putAtt(fCdf, historyQcTestVarId, 'conventions', 'Write tests performed when ACTION=QCP$; tests failed when ACTION=QCF$');
   netcdf.putAtt(fCdf, historyQcTestVarId, '_FillValue', ' ');
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % DEFINE MODE END
   if (VERBOSE_MODE == 2)
      fprintf('STOP DEFINE MODE\n');
   end
   
   netcdf.endDef(fCdf);
   
   valueStr = 'B-Argo profile';
   netcdf.putVar(fCdf, dataTypeVarId, 0, length(valueStr), valueStr);
   
   valueStr = '3.1';
   netcdf.putVar(fCdf, formatVersionVarId, 0, length(valueStr), valueStr);
   
   valueStr = '1.2';
   netcdf.putVar(fCdf, handbookVersionVarId, 0, length(valueStr), valueStr);
   
   netcdf.putVar(fCdf, referenceDateTimeVarId, '19500101000000');
   
   if (isempty(ncCreationDate))
      netcdf.putVar(fCdf, dateCreationVarId, currentDate);
   else
      netcdf.putVar(fCdf, dateCreationVarId, ncCreationDate);
   end
   
   netcdf.putVar(fCdf, dateUpdateVarId, currentDate);
   
   % create profile variables
   for idP = 1:length(a_tabProfiles)
      prof = a_tabProfiles(profIdList(idP));
      if (~is_core_profile(prof))
         
         profPos = idP-1;
         
         valueStr = sprintf('%d', g_decArgo_floatNum);
         netcdf.putVar(fCdf, platformNumberVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         valueStr = ' ';
         idVal = find(strcmp('PROJECT_NAME', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         netcdf.putVar(fCdf, projectNameVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         valueStr = ' ';
         idVal = find(strcmp('PI_NAME', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         netcdf.putVar(fCdf, piNameVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         parameterList = prof.paramList;
         paramPos = 0;
         for idParam = 1:length(parameterList)
            
            if (((parameterList(idParam).paramType ~= 'c') || ...
                  strcmp(parameterList(idParam).name, 'PRES') || ...
                  strcmp(parameterList(idParam).name, 'PRES2')) && ...
                  ~strcmp(parameterList(idParam).name(end-3:end), '_STD') && ...
                  ~strcmp(parameterList(idParam).name(end-3:end), '_MED'))
               
               valueStr = parameterList(idParam).name;
               
               if (length(valueStr) > paramNameLength)
                  fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) => name truncated\n', ...
                     g_decArgo_floatNum, valueStr, paramNameLength);
                  valueStr = valueStr(1:paramNameLength);
               end
               
               netcdf.putVar(fCdf, stationParametersVarId, ...
                  fliplr([profPos paramPos 0]), fliplr([1 1 length(valueStr)]), valueStr');
               
               netcdf.putVar(fCdf, parameterDataModeVarId, fliplr([profPos paramPos]), fliplr([1 1]), 'R');
               paramPos = paramPos + 1;
            end
         end
         
         valueStr = ' ';
         idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         netcdf.putVar(fCdf, dataCenterVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         valueStr = '1A';
         netcdf.putVar(fCdf, dataStateIndicatorVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         netcdf.putVar(fCdf, dataModeVarId, profPos, 1, 'R');
         
         valueStr = get_platform_type(a_decoderId);
         netcdf.putVar(fCdf, platformTypeVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         valueStr = ' ';
         idVal = find(strcmp('FLOAT_SERIAL_NO', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         netcdf.putVar(fCdf, floatSerialNoVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         valueStr = ' ';
         idVal = find(strcmp('FIRMWARE_VERSION', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         netcdf.putVar(fCdf, firmwareVersionVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
         
         valueStr = get_wmo_instrument_type(a_decoderId);
         netcdf.putVar(fCdf, wmoInstTypeVarId, ...
            fliplr([profPos 0]), ...
            fliplr([1 length(valueStr)]), valueStr');
      end
   end
   
   % copy existing history information
   if (~isempty(histoInstitution))
      if (size(histoInstitution, 2) <= nbProfInFile)
         netcdf.putVar(fCdf, historyInstitutionVarId, ...
            fliplr([0 0 0]), fliplr([size(histoInstitution, 3) size(histoInstitution, 2) size(histoInstitution, 1)]), histoInstitution);
         netcdf.putVar(fCdf, historyStepVarId, ...
            fliplr([0 0 0]), fliplr([size(histoStep, 3) size(histoStep, 2) size(histoStep, 1)]), histoStep);
         netcdf.putVar(fCdf, historySoftwareVarId, ...
            fliplr([0 0 0]), fliplr([size(histoSoftware, 3) size(histoSoftware, 2) size(histoSoftware, 1)]), histoSoftware);
         netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
            fliplr([0 0 0]), fliplr([size(histoSoftwareRelease, 3) size(histoSoftwareRelease, 2) size(histoSoftwareRelease, 1)]), histoSoftwareRelease);
         netcdf.putVar(fCdf, historyDateVarId, ...
            fliplr([0 0 0]), fliplr([size(histoDate, 3) size(histoDate, 2) size(histoDate, 1)]), histoDate);
      else
         fprintf('WARNING: Float #%d : N_PROF=%d in existing file, N_PROF=%d in updated file => history information not copied when updating file %s\n', ...
            g_decArgo_floatNum, size(histoInstitution, 2), nbProfInFile, ncPathFileName);
      end
   end
     
   % create the list of RT adjusted profiles
   adjustedProfilesList = zeros(length(a_tabProfiles), 1);
   for idP = 1:length(a_tabProfiles)
      prof = a_tabProfiles(profIdList(idP));
      [adjustedProfilesList(idP)] = rt_adjusment_exist(prof, 0);
   end
   
   % add profile data
   calibInfo = [];
   for idP = 1:length(a_tabProfiles)
      
      prof = a_tabProfiles(profIdList(idP));
      
      if (~is_core_profile(prof))
         
         profPos = idP-1;
         
         if (VERBOSE_MODE == 2)
            fprintf('Add profile #%d/%d data\n', profPos, length(a_tabProfiles));
         end
         
         % cycle number
         netcdf.putVar(fCdf, cycleNumberVarId, profPos, 1, prof.outputCycleNumber);
         
         % profile direction
         netcdf.putVar(fCdf, directionVarId, profPos, 1, prof.direction);
         
         % profile date
         profDate = prof.date;
         if (profDate ~= g_decArgo_dateDef)
            netcdf.putVar(fCdf, juldVarId, profPos, 1, profDate);
            if (isempty(prof.dateQc))
               netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
            else
               netcdf.putVar(fCdf, juldQcVarId, profPos, 1, prof.dateQc);
            end
         else
            netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrMissing);
         end
         
         % profile location
         profLocationDate = prof.locationDate;
         profLocationLon = prof.locationLon;
         profLocationLat = prof.locationLat;
         profLocationQc = prof.locationQc;
         profPosSystem = prof.posSystem;
         if (profLocationDate ~= g_decArgo_dateDef)
            netcdf.putVar(fCdf, juldLocationVarId, profPos, 1, profLocationDate);
            netcdf.putVar(fCdf, latitudeVarId, profPos, 1, profLocationLat);
            netcdf.putVar(fCdf, longitudeVarId, profPos, 1, profLocationLon);
            netcdf.putVar(fCdf, positionQcVarId, profPos, 1, profLocationQc);
         else
            netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrMissing);
         end
         netcdf.putVar(fCdf, positioningSystemVarId, fliplr([profPos 0]), fliplr([1 length(profPosSystem)]), profPosSystem');
         
         % vertical sampling scheme
         vertSampScheme = prof.vertSamplingScheme;
         if (length(vertSampScheme) > verticalSamplingSchemeLength)
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: vertical sampling scheme too long (length = %d > %d) => vertical sampling scheme ''%s'' truncated to ''%s''\n', ...
               g_decArgo_floatNum, prof.cycleNumber, prof.profileNumber, prof.outputCycleNumber, ...
               length(vertSampScheme), verticalSamplingSchemeLength, ...
               vertSampScheme, ...
               vertSampScheme(1:verticalSamplingSchemeLength));
            vertSampScheme = vertSampScheme(1:verticalSamplingSchemeLength);
         end
         netcdf.putVar(fCdf, verticalSamplingSchemeVarId, fliplr([profPos 0]), fliplr([1 length(vertSampScheme)]), vertSampScheme');
         
         % configuration mission number
         if (~isempty(prof.configMissionNumber))
            netcdf.putVar(fCdf, configMissionNumberVarId, profPos, 1, prof.configMissionNumber);
         end
         
         % profile parameter data
         parameterList = prof.paramList;
         adjustedParamIdList = [];
         paramPos = 0;
         for idParam = 1:length(parameterList)
            
            if ((parameterList(idParam).paramType ~= 'c') || ...
                  strcmp(parameterList(idParam).name, 'PRES') || ...
                  strcmp(parameterList(idParam).name, 'PRES2'))
               
               profParam = parameterList(idParam);
               
               % parameter variable and attributes
               
               profParamName = profParam.name;
               profParamVarId = netcdf.inqVarID(fCdf, profParamName);
               
               % parameter QC variable and attributes
               profParamQcVarId = '';
               if ~(strcmp(profParam.name, 'PRES') || strcmp(profParam.name, 'PRES2') || ...
                     strcmp(profParam.name(end-3:end), '_STD') || ...
                     strcmp(profParam.name(end-3:end), '_MED'))
                  profParamQcName = sprintf('%s_QC', profParam.name);
                  profParamQcVarId = netcdf.inqVarID(fCdf, profParamQcName);
               end
               
               if ((profParam.adjAllowed == 1) && (profParam.paramType ~= 'c'))
                  % parameter adjusted variable and attributes
                  profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                  profParamAdjVarId = netcdf.inqVarID(fCdf, profParamAdjName);
                  
                  % parameter adjusted QC variable and attributes
                  profParamAdjQcName = sprintf('%s_ADJUSTED_QC', profParam.name);
                  profParamAdjQcVarId = netcdf.inqVarID(fCdf, profParamAdjQcName);
                  
                  % parameter adjusted error variable and attributes
                  profParamAdjErrName = sprintf('%s_ADJUSTED_ERROR', profParam.name);
                  profParamAdjErrVarId = netcdf.inqVarID(fCdf, profParamAdjErrName);
               end
               
               % parameter data
               if (isempty(prof.paramNumberWithSubLevels))
                  
                  % none of the profile parameters has sublevels
                  paramData = prof.data(:, idParam);
                  if (isempty(prof.dataQc))
                     paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                     paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                  else
                     paramDataQc = prof.dataQc(:, idParam);
                     if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                        paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                        paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                     else
                        paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                        idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                        paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
                        
                        if ~(strcmp(profParam.name, 'PRES') || strcmp(profParam.name, 'PRES2') || ...
                              strcmp(profParam.name(end-3:end), '_STD') || ...
                              strcmp(profParam.name(end-3:end), '_MED'))
                           profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                           profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                        end
                     end
                  end
                  
                  if (prof.direction == 'A')
                     measIds = fliplr([1:length(paramData)]);
                  else
                     measIds = [1:length(paramData)];
                  end
                  netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                  
                  if (~isempty(profParamQcVarId))
                     netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramDataQcStr(measIds));
                  end
                  
                  if (adjustedProfilesList(idP) == 1)
                     if ((profParam.adjAllowed == 1) && (profParam.paramType ~= 'c'))
                        
                        % process RT adjustment of this parameter
                        [paramAdjData] = compute_adjusted_data(paramData, profParam, prof);
                        if (~isempty(paramAdjData))
                           
                           adjustedParamIdList = [adjustedParamIdList paramPos];
                           
                           % store parameter adjusted data in ADJUSTED variable
                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjData(measIds));
                           
                           paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                           paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));
                        else
                           % copy parameter data in ADJUSTED variable
                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                           
                           paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                           paramAdjDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramAdjDataQcStr(measIds));
                        end
                     end
                  end
               else
                  
                  % some profile parameters have sublevels
                  
                  % retrieve the column(s) associated with the parameter data
                  idF = find(prof.paramNumberWithSubLevels < idParam);
                  if (isempty(idF))
                     firstCol = idParam;
                  else
                     firstCol = idParam + sum(prof.paramNumberOfSubLevels(idF)) - length(idF);
                  end
                  
                  idF = find(prof.paramNumberWithSubLevels == idParam);
                  if (isempty(idF))
                     lastCol = firstCol;
                  else
                     lastCol = firstCol + prof.paramNumberOfSubLevels(idF) - 1;
                  end
                  
                  paramData = prof.data(:, firstCol:lastCol);
                  if (isempty(prof.dataQc))
                     paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                     if (size(paramData, 2) == 1)
                        paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                     else
                        for idL = 1: size(paramData, 1)
                           if (~isempty(find(paramData(idL, :) ~= profParam.fillValue, 1)))
                              paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
                           end
                        end
                     end
                  else
                     paramDataQc = prof.dataQc(:, firstCol);
                     if ((length(unique(paramDataQc)) == 1) && (unique(paramDataQc) == g_decArgo_qcDef))
                        paramDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                        if (size(paramData, 2) == 1)
                           paramDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                        else
                           for idL = 1: size(paramData, 1)
                              if (~isempty(find(paramData(idL, :) ~= profParam.fillValue, 1)))
                                 paramDataQcStr(idL) = g_decArgo_qcStrNoQc;
                              end
                           end
                        end
                     else
                        paramDataQcStr = repmat(g_decArgo_qcStrDef, length(paramDataQc), 1);
                        idNoDef = find(paramDataQc ~= g_decArgo_qcDef);
                        paramDataQcStr(idNoDef) = num2str(paramDataQc(idNoDef));
                        
                        if ~(strcmp(profParam.name, 'PRES') || strcmp(profParam.name, 'PRES2') || ...
                              strcmp(profParam.name(end-3:end), '_STD') || ...
                              strcmp(profParam.name(end-3:end), '_MED'))
                           profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                           profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                        end
                     end
                  end
                                   
                  if (prof.direction == 'A')
                     measIds = fliplr([1:length(paramData)]);
                  else
                     measIds = [1:length(paramData)];
                  end
                  
                  netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0 0]), fliplr([1 size(paramData)]), paramData(measIds, :)');
                  
                  if (~isempty(profParamQcVarId))
                     netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQcStr)]), paramDataQcStr(measIds));
                  end
                  
                  if (adjustedProfilesList(idP) == 1)
                     if ((profParam.adjAllowed == 1) && (profParam.paramType ~= 'c'))
                        
                        % process RT adjustment of this parameter
                        [paramAdjData] = compute_adjusted_data(paramData, profParam, prof);
                        
                        if (~isempty(paramAdjData))
                           
                           adjustedParamIdList = [adjustedParamIdList paramPos];
                           
                           % store parameter adjusted data in ADJUSTED variable
                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 size(paramAdjData)]), paramAdjData(measIds, :)');
                           
                           paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                           if (size(paramAdjData, 2) == 1)
                              paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           else
                              for idL = 1: size(paramAdjData, 1)
                                 if (~isempty(find(paramAdjData(idL, :) ~= profParam.fillValue, 1)))
                                    paramAdjDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                 end
                              end
                           end
                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 size(paramAdjData, 1)]), paramAdjDataQcStr(measIds));
                        else
                           % copy parameter data in ADJUSTED variable
                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 size(paramData)]), paramData(measIds, :)');
                           
                           paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                           if (size(paramData, 2) == 1)
                              paramAdjDataQcStr(find(paramData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           else
                              for idL = 1: size(paramData, 1)
                                 if (~isempty(find(paramData(idL, :) ~= profParam.fillValue, 1)))
                                    paramAdjDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                 end
                              end
                           end
                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 size(paramData, 1)]), paramAdjDataQcStr(measIds));
                        end
                     end
                  end
               end
               paramPos = paramPos + 1;
            end
         end
         
         if (adjustedProfilesList(idP) == 1)
            netcdf.putVar(fCdf, dataModeVarId, profPos, 1, 'A');
            for id = 1:length(adjustedParamIdList)
               netcdf.putVar(fCdf, parameterDataModeVarId, fliplr([profPos adjustedParamIdList(id)]), fliplr([1 1]), 'A');
            end
            
            % process calibration information
            idVal = find(strcmp('CALIB_RT_PARAMETER', a_metaDataFromJson) == 1);
            if (~isempty(idVal))
               metaData = a_metaDataFromJson{idVal+1};
               if (~isempty(metaData))
                  tabParam = unique(struct2cell(metaData));
                  idDel = [];
                  for idParam = 1:length(tabParam)
                     param = tabParam{idParam};
                     idPosParam = find(strcmp({parameterList.name}, param) == 1);
                     paramTypeList = [parameterList.paramType];
                     if (isempty(idPosParam) || ...
                           ~((paramTypeList(idPosParam) ~= 'c') || ...
                           strcmp(param, 'PRES')))
                        idDel = [idDel idParam];
                     end
                  end                  
                  tabParam(idDel) = [];
                  tabId = [];
                  tabEquation = [];
                  tabCoefficient = [];
                  tabComment = [];
                  tabDate = [];
                  for idParam = 1:length(tabParam)
                     param = tabParam{idParam};
                     fieldNames = fields(metaData);
                     tab = [];
                     for idF = 1:length(fieldNames)
                        fieldName = fieldNames{idF};
                        if (strcmp(metaData.(fieldName), param) == 1)
                           idPos = strfind(fieldName, '_');
                           posNum = str2num(fieldName(idPos(end)+1:end));
                           tab = [tab posNum];
                        end
                     end
                     tabId{idParam} = tab;
                  end
                  
                  idVal = find(strcmp('CALIB_RT_EQUATION', a_metaDataFromJson) == 1);
                  if (~isempty(idVal))
                     metaData = a_metaDataFromJson{idVal+1};
                     if (~isempty(metaData))
                        for idParam = 1:length(tabParam)
                           equation = [];
                           tab = tabId{idParam};
                           for id = 1:length(tab)
                              eq = '';
                              if (isfield(metaData, ['CALIB_RT_EQUATION_' num2str(tab(id))]))
                                 eq = metaData.(['CALIB_RT_EQUATION_' num2str(tab(id))]);
                              end
                              equation{id} = eq;
                           end
                           tabEquation{idParam} = equation;
                        end
                     end
                  end
                  
                  idVal = find(strcmp('CALIB_RT_COEFFICIENT', a_metaDataFromJson) == 1);
                  if (~isempty(idVal))
                     metaData = a_metaDataFromJson{idVal+1};
                     if (~isempty(metaData))
                        for idParam = 1:length(tabParam)
                           coefficient = [];
                           tab = tabId{idParam};
                           for id = 1:length(tab)
                              coef = '';
                              if (isfield(metaData, ['CALIB_RT_COEFFICIENT_' num2str(tab(id))]))
                                 coef = metaData.(['CALIB_RT_COEFFICIENT_' num2str(tab(id))]);
                              end
                              coefficient{id} = coef;
                           end
                           tabCoefficient{idParam} = coefficient;
                        end
                     end
                  end
                  
                  idVal = find(strcmp('CALIB_RT_COMMENT', a_metaDataFromJson) == 1);
                  if (~isempty(idVal))
                     metaData = a_metaDataFromJson{idVal+1};
                     if (~isempty(metaData))
                        for idParam = 1:length(tabParam)
                           comment = [];
                           tab = tabId{idParam};
                           for id = 1:length(tab)
                              com = '';
                              if (isfield(metaData, ['CALIB_RT_COMMENT_' num2str(tab(id))]))
                                 com = metaData.(['CALIB_RT_COMMENT_' num2str(tab(id))]);
                              end
                              comment{id} = com;
                           end
                           tabComment{idParam} = comment;
                        end
                     end
                  end
                  
                  idVal = find(strcmp('CALIB_RT_DATE', a_metaDataFromJson) == 1);
                  if (~isempty(idVal))
                     metaData = a_metaDataFromJson{idVal+1};
                     if (~isempty(metaData))
                        for idParam = 1:length(tabParam)
                           dates = [];
                           tab = tabId{idParam};
                           for id = 1:length(tab)
                              dat = '';
                              if (isfield(metaData, ['CALIB_RT_DATE_' num2str(tab(id))]))
                                 dat = metaData.(['CALIB_RT_DATE_' num2str(tab(id))]);
                              end
                              dates{id} = dat;
                           end
                           tabDate{idParam} = dates;
                        end
                     end
                  end
                  
                  % store calibration information for this profile
                  profCalibInfo = [];
                  profCalibInfo.profId = idP;
                  profCalibInfo.param = tabParam;
                  profCalibInfo.equation = tabEquation;
                  profCalibInfo.coefficient = tabCoefficient;
                  profCalibInfo.comment = tabComment;
                  profCalibInfo.date = tabDate;
                  calibInfo{end+1} = profCalibInfo;
               end
            end
         end
         
         % add specific comment for PRES parameter
         if (~isempty(find(strcmp({prof.paramList.name}, 'PRES') == 1, 1)))
            
            comment = '';
            date = '';
            if (adjustedProfilesList(idP) == 1)
               comment = 'Not applicable';
               if (isempty(ncCreationDate))
                  date = currentDate;
               else
                  date = ncCreationDate;
               end
            end
            tabParam = {'PRES'};
            tabEquation = {{comment}};
            tabCoefficient = {{comment}};
            tabComment = {{'Adjusted values are provided in the core profile file'}};
            tabDate = {{date}};
            
            % store calibration information for this profile
            profCalibInfo = [];
            profCalibInfo.profId = idP;
            profCalibInfo.param = tabParam;
            profCalibInfo.equation = tabEquation;
            profCalibInfo.coefficient = tabCoefficient;
            profCalibInfo.comment = tabComment;
            profCalibInfo.date = tabDate;
            calibInfo{end+1} = profCalibInfo;
         end
         
         % add specific comment for PRES2 parameter
         if (~isempty(find(strcmp({prof.paramList.name}, 'PRES2') == 1, 1)))
            
            comment = '';
            date = '';
            if (adjustedProfilesList(idP) == 1)
               comment = 'Not applicable';
               if (isempty(ncCreationDate))
                  date = currentDate;
               else
                  date = ncCreationDate;
               end
            end
            tabParam = {'PRES2'};
            tabEquation = {{comment}};
            tabCoefficient = {{comment}};
            tabComment = {{'Adjusted values are provided in the core profile file'}};
            tabDate = {{date}};
            
            % store calibration information for this profile
            profCalibInfo = [];
            profCalibInfo.profId = idP;
            profCalibInfo.param = tabParam;
            profCalibInfo.equation = tabEquation;
            profCalibInfo.coefficient = tabCoefficient;
            profCalibInfo.comment = tabComment;
            profCalibInfo.date = tabDate;
            calibInfo{end+1} = profCalibInfo;
         end
         
         % NO SINCE THE OTHER PARAMETERS ARE in 'R' MODE (NOT DUPLICATED)
         %          % add a SCIENTIFIC_CALIB_COMMENT for duplicated data
         %          calibList = [calibInfo{:}];
         %          idF = find([calibList.profId] == idP);
         %          calibListForProf = [calibInfo{idF}];
         %          if ~((length(idF) == 1) && (strcmp(calibListForProf.param, 'PRES')))
         %             newList = setdiff({prof.paramList.name}, [calibListForProf.param]);
         %             for idParam = 1:length(newList)
         %                paramName = newList{idParam};
         %                paramInfo = get_netcdf_param_attributes(paramName);
         %                if (paramInfo.paramType ~= 'c')
         %
         %                   tabParam = {paramName};
         %                   tabEquation = {{[paramName '_ADJUSTED = ' paramName]}};
         %                   tabCoefficient = {{'Not applicable'}};
         %                   tabComment = {{'No adjustment performed (values duplicated)'}};
         %                   tabDate = {{format_date_yyyymmddhhmiss_dec_argo(prof.date)}};
         %
         %                   % store calibration information for this profile
         %                   profCalibInfo = [];
         %                   profCalibInfo.profId = idP;
         %                   profCalibInfo.param = tabParam;
         %                   profCalibInfo.equation = tabEquation;
         %                   profCalibInfo.coefficient = tabCoefficient;
         %                   profCalibInfo.comment = tabComment;
         %                   profCalibInfo.date = tabDate;
         %                   calibInfo{end+1} = profCalibInfo;
         %                end
         %             end
         %          end
         
         % history information
         currentHistoId = 0;
         if (~isempty(histoInstitution))
            if (size(histoInstitution, 2) <= nbProfInFile)
               currentHistoId = size(histoInstitution, 3);
            end
         end
         value = 'IF';
         netcdf.putVar(fCdf, historyInstitutionVarId, ...
            fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
         value = 'ARFM';
         netcdf.putVar(fCdf, historyStepVarId, ...
            fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
         value = 'CODA';
         netcdf.putVar(fCdf, historySoftwareVarId, ...
            fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
         value = g_decArgo_decoderVersion;
         netcdf.putVar(fCdf, historySoftwareReleaseVarId, ...
            fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
         value = currentDate;
         netcdf.putVar(fCdf, historyDateVarId, ...
            fliplr([currentHistoId profPos 0]), fliplr([1 1 length(value)]), value');
      end
   end
   
   % process calibration information
   
   % compute the N_CALIB dimension
   nbCalib = 1;
   for idC = 1:length(calibInfo)
      if (~isempty(calibInfo{idC}))
         tabParam = calibInfo{idC}.param;
         tabEquation = calibInfo{idC}.equation;
         tabCoefficient = calibInfo{idC}.coefficient;
         tabComment = calibInfo{idC}.comment;
         tabDate = calibInfo{idC}.date;
         for idParam = 1:length(tabParam)
            nbCalib = max(nbCalib, max([ ...
               length(tabEquation{idParam}) ...
               length(tabCoefficient{idParam}) ...
               length(tabComment{idParam}) ...
               length(tabDate{idParam}) ...
               ]));
         end
      end
   end
   
   netcdf.reDef(fCdf);
   
   nCalibDimId = netcdf.defDim(fCdf, 'N_CALIB', nbCalib);
   
   % calibration information
   parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string64DimId]));
   netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'List of parameters with calibration information');
   netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Argo reference table 3');
   netcdf.putAtt(fCdf, parameterVarId, '_FillValue', ' ');
   
   scientificCalibEquationVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_EQUATION', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
   netcdf.putAtt(fCdf, scientificCalibEquationVarId, 'long_name', 'Calibration equation for this parameter');
   netcdf.putAtt(fCdf, scientificCalibEquationVarId, '_FillValue', ' ');
   
   scientificCalibCoefficientVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COEFFICIENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
   netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, 'long_name', 'Calibration coefficients for this equation');
   netcdf.putAtt(fCdf, scientificCalibCoefficientVarId, '_FillValue', ' ');
   
   scientificCalibCommentVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_COMMENT', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string256DimId]));
   netcdf.putAtt(fCdf, scientificCalibCommentVarId, 'long_name', 'Comment applying to this parameter calibration');
   netcdf.putAtt(fCdf, scientificCalibCommentVarId, '_FillValue', ' ');
   
   scientificCalibDateVarId = netcdf.defVar(fCdf, 'SCIENTIFIC_CALIB_DATE', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId dateTimeDimId]));
   netcdf.putAtt(fCdf, scientificCalibDateVarId, 'long_name', 'Date of calibration');
   netcdf.putAtt(fCdf, scientificCalibDateVarId, 'conventions', 'YYYYMMDDHHMISS');
   netcdf.putAtt(fCdf, scientificCalibDateVarId, '_FillValue', ' ');
   
   netcdf.endDef(fCdf);
   
   % fill PARAMETER variable (event if there is no RT adjustments)
   ncParamlist = repmat({''}, length(a_tabProfiles), nbProfParam);
   for idP = 1:length(a_tabProfiles)
      prof = a_tabProfiles(profIdList(idP));
      if (~is_core_profile(prof))
         parameterList = prof.paramList;
         profPos = idP-1;
         paramPos = 0;
         for idParam = 1:length(parameterList)
            
            if (((parameterList(idParam).paramType ~= 'c') || ...
                  strcmp(parameterList(idParam).name, 'PRES') || ...
                  strcmp(parameterList(idParam).name, 'PRES2')) && ...
                  ~strcmp(parameterList(idParam).name(end-3:end), '_STD') && ...
                  ~strcmp(parameterList(idParam).name(end-3:end), '_MED'))
               
               valueStr = parameterList(idParam).name;
               
               for idCalib = 1:nbCalib
                  netcdf.putVar(fCdf, parameterVarId, ...
                     fliplr([profPos idCalib-1 paramPos 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
               end
               paramPos = paramPos + 1;
               ncParamlist(idP, paramPos) = {valueStr};
            end
         end
      end
   end
   
   for idC = 1:length(calibInfo)
      profId = calibInfo{idC}.profId;
      profPos = profId-1;
      tabParams = calibInfo{idC}.param;
      tabEquations = calibInfo{idC}.equation;
      tabCoefficients = calibInfo{idC}.coefficient;
      tabComments = calibInfo{idC}.comment;
      tabDates = calibInfo{idC}.date;
      
      for idParam = 1:length(tabParams)
         param = tabParams{idParam};
         idPosParam = find(strcmp(ncParamlist(profId, :), param) == 1);
         if (isempty(idPosParam))
            continue;
         end
         tabEquation = tabEquations{idParam};
         tabCoefficient = tabCoefficients{idParam};
         tabComment = tabComments{idParam};
         tabDate = tabDates{idParam};
         
         for idCalib = 1:max([length(tabEquation) length(tabCoefficient) length(tabComment) length(tabDate) ])
            value = param;
            netcdf.putVar(fCdf, parameterVarId, ...
               fliplr([profPos idCalib-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
         end
         for idCalib = 1:length(tabEquation)
            value = tabEquation{idCalib};
            if (~isempty(value))
               netcdf.putVar(fCdf, scientificCalibEquationVarId, ...
                  fliplr([profPos idCalib-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
            end
         end
         for idCalib = 1:length(tabCoefficient)
            value = tabCoefficient{idCalib};
            if (~isempty(value))
               netcdf.putVar(fCdf, scientificCalibCoefficientVarId, ...
                  fliplr([profPos idCalib-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
            end
         end
         for idCalib = 1:length(tabComment)
            value = tabComment{idCalib};
            if (~isempty(value))
               netcdf.putVar(fCdf, scientificCalibCommentVarId, ...
                  fliplr([profPos idCalib-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
            end
         end
         for idCalib = 1:length(tabDate)
            value = tabDate{idCalib};
            if (~isempty(value))
               netcdf.putVar(fCdf, scientificCalibDateVarId, ...
                  fliplr([profPos idCalib-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
            end
         end
      end
   end
   
   netcdf.close(fCdf);
   
   if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1) || (g_decArgo_applyRtqc == 1))
      % store information for the XML report
      g_decArgo_reportStruct.outputMultiProfFiles = [g_decArgo_reportStruct.outputMultiProfFiles ...
         {ncPathFileName}];
   end
   
   fprintf('... NetCDF MULTI-PROFILE b file created\n');
end

return;
