% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE AUX files.
%
% SYNTAX :
%  create_nc_mono_prof_aux_files( ...
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
%   02/20/2017 - RNU - creation
% ------------------------------------------------------------------------------
function create_nc_mono_prof_aux_files( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson)

% Argos (1), Iridium RUDICS (2) or Iridium SBD (3) float
global g_decArgo_floatTransType;

% configuration values
global g_decArgo_generateNcMonoProf;
global g_decArgo_applyRtqc;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% global input parameter information
global g_decArgo_processModeAll;

% current float WMO number
global g_decArgo_floatNum;

% QC flag values (char)
global g_decArgo_qcStrDef;
global g_decArgo_qcStrNoQc;
global g_decArgo_qcStrMissing;

% configuration values
global g_decArgo_dirOutputNetcdfFile;

% global default values
global g_decArgo_dateDef;
global g_decArgo_qcDef;

% decoder version
global g_decArgo_decoderVersion;

% report information structure
global g_decArgo_reportStruct;

% common long_name for nc files
global g_decArgo_longNameOfParamAdjErr;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabProfiles))
   return
end

% assign time resolution for each float transmission type
if (a_decoderId == 2003)
   profJulDLocRes = double(6/1440); % 6 minutes
else
   profJulDLocRes = double(1/86400); % 1 second
end
[profJulDRes, profJulDComment] = get_prof_juld_resolution(g_decArgo_floatTransType, a_decoderId);

% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag 0]];
end

for idProf = 1:length(a_tabProfiles)
   if (profInfo(idProf, 4) == 0)
      profile = a_tabProfiles(idProf);
      cycleNumber = profile.cycleNumber;
      profileNumber = profile.profileNumber;
      outputCycleNumber = profile.outputCycleNumber;
      direction = 2;
      if (profile.direction == 'D')
         direction = 1;
      end
      
      % list of profiles to store in the current profile file
      idProfInFile = find( ...
         (profInfo(:, 1) == outputCycleNumber) & ...
         (profInfo(:, 2) == direction) & ...
         (profInfo(:, 4) == 0));
      nbProfToStore = length(idProfInFile);
      
      profShiftIfNoPrimary = 0;
      nbProfInFile = nbProfToStore + profShiftIfNoPrimary;
      
      % create the profile parameters list and compute the number of levels
      % and sublevels
      profParamName = [];
      nbProfParam = 0;
      nbProfLevels = 0;
      profSubLevels = [];
      paramNameSubLevels = [];
      for idP = 1:nbProfToStore
         paramNameOfProf = [];
         prof = a_tabProfiles(idProfInFile(idP));
         
         parameterList = prof.paramList;
         profileData = prof.data;
         for idParam = 1:length(parameterList)
            if (~strcmp(parameterList(idParam).name(end-3:end), '_STD') && ...
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
      
      if (nbProfParam > 0)
         
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
         outputDirName = [outputDirName '/profiles/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end
         
         if (direction == 1)
            ncFileName = sprintf('R%d_%03dD_aux.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         else
            ncFileName = sprintf('R%d_%03d_aux.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         end
         ncPathFileName = [outputDirName  ncFileName];
         
         % check if the file need to be created
         generate = 1;
         if (g_decArgo_floatTransType == 1)
            
            % Argos floats
            
            if (g_decArgo_generateNcMonoProf == 2)
               
               if ((g_decArgo_realtimeFlag == 1) && (g_decArgo_processModeAll == 0))
                  
                  % in this configuration, only new profile files are created
                  % (never updated)
                  if (exist(ncPathFileName, 'file') == 2)
                     generate = 0;
                  end
               end
            end
            
         elseif ((g_decArgo_floatTransType == 2) || ...
               (g_decArgo_floatTransType == 4))
            
            % Iridium RUDICS floats
            % Iridium SBD ProvBioII floats

            if (g_decArgo_generateNcMonoProf == 2)
               
               if (g_decArgo_realtimeFlag == 1)
                  
                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  % - it exists but the profile structure has been updated
                  if ((exist(ncPathFileName, 'file') == 2) && ...
                        (isempty(find([a_tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               elseif (g_decArgo_delayedModeFlag == 1)
                  
                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  if (exist(ncPathFileName, 'file') == 2)
                     generate = 0;
                  end
               end
            end
            
         elseif (g_decArgo_floatTransType == 3)
            
            % Iridium SBD floats

            if (g_decArgo_generateNcMonoProf == 2)
               
               if (g_decArgo_realtimeFlag == 1)
                  
                  % in this configuration, the file is created/updated if:
                  % - it doesn't exist
                  % - it exists but the profile structure has been updated
                  if ((exist(ncPathFileName, 'file') == 2) && ...
                        (isempty(find([a_tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               end
            end
            
         else
            
            if (g_decArgo_generateNcMonoProf == 2)
               
               if (g_decArgo_realtimeFlag == 1)
                  
                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no strategy to generate or not profile NetCDF files => generating all profile fles\n', ...
                     g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
               end
            end
         end
         
         % the data of one cycle can be in consecutive rsync log files
         % to check if the file need to be created we should then compare profile
         % levels
         if (generate == 0)
            if ((g_decArgo_floatTransType == 2) || (g_decArgo_floatTransType == 3) || (g_decArgo_floatTransType == 4))
               if ((g_decArgo_generateNcMonoProf == 2) && (g_decArgo_realtimeFlag == 1))
                  if (exist(ncPathFileName, 'file') == 2)
                     
                     % retrieve profile levels of the nc file
                     ncProfLev = get_nc_profile_level(ncPathFileName);
                     
                     % compare profile levels
                     differ = 0;
                     
                     for idP = 1:nbProfToStore
                        prof = a_tabProfiles(idProfInFile(idP));
                        nLevelsParam = 0;
                        idNoDefAll = [];
                        
                        profPos = idP-1+profShiftIfNoPrimary;
                        
                        % profile parameter data
                        parameterList = prof.paramList;
                        for idParam = 1:length(parameterList)
                           profParam = parameterList(idParam);
                           profParamName = profParam.name;
                           paramInfo = get_netcdf_param_attributes(profParamName);
                           
                           % parameter data
                           if (isempty(prof.paramNumberWithSubLevels))
                              % none of the profile parameters has sublevels
                              paramData = prof.data(:, idParam);
                              idNoDef = find(paramData ~= paramInfo.fillValue);
                              idNoDefAll = [idNoDefAll idNoDef'];
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
                              if (size(paramData, 2) == 1)
                                 idNoDef = find(paramData ~= paramInfo.fillValue);
                                 idNoDefAll = [idNoDefAll idNoDef'];
                              else
                                 idNoDef = [];
                                 for id = 1:size(paramData, 1)
                                    if ~((length(unique(paramData(id, :))) == 1) && (unique(paramData(id, :)) == paramInfo.fillValue))
                                       idNoDef = [idNoDef id];
                                    end
                                 end
                                 idNoDefAll = [idNoDefAll idNoDef];
                              end
                           end
                        end
                        
                        if (~isempty(idNoDefAll))
                           nLevelsParam = max(idNoDefAll) - min(idNoDefAll) + 1;
                        end
                        if (nLevelsParam ~= ncProfLev(profPos+1))
                           differ = 1;
                           break
                        end
                     end
                     if (differ == 1)
                        generate = 1;
                     end
                  end
               end
            end
         end
         if (generate == 0)
            continue
         end
         
         % information to retrieve from a possible existing mono-profile file
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
               fprintf('Updating NetCDF MONO-PROFILE AUX file (%s) ...\n', ncFileName);
            end
            
         else
            if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
               fprintf('Creating NetCDF MONO-PROFILE AUX file (%s) ...\n', ncFileName);
            end
         end
         
         if (g_decArgo_floatTransType == 1)
            
            % Argos floats
            
            if (g_decArgo_generateNcMonoProf == 2)
               if (~isempty(profile.profileCompleted) && (profile.profileCompleted > 0))
                  fprintf('INFO: Float #%d cycle #%d: missing levels in transmitted profile (%d levels are missing)\n', ...
                     g_decArgo_floatNum, outputCycleNumber, profile.profileCompleted);
               end
            end
         end
         
         currentDate = datestr(now_utc, 'yyyymmddHHMMSS');
         
         % create and open NetCDF file
         fCdf = netcdf.create(ncPathFileName, 'NC_CLOBBER');
         if (isempty(fCdf))
            fprintf('ERROR: Unable to create NetCDF output file: %s\n', ncPathFileName);
            return
         end
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % DEFINE MODE BEGIN
         if (VERBOSE_MODE == 2)
            fprintf('START DEFINE MODE\n');
            fprintf('float cycle # = %d\n', cycleNumber);
            fprintf('float profile # = %d\n', profileNumber);
            fprintf('output cycle # = %d\n', outputCycleNumber);
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
         netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile auxiliary data');
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
         netcdf.putAtt(fCdf, globalVarId, 'references', ' ');
         netcdf.putAtt(fCdf, globalVarId, 'user_manual_version', '1.0');
         netcdf.putAtt(fCdf, globalVarId, 'Conventions', 'CF-1.6 Coriolis-Argo-Aux-1.0');
         netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfileCoriolisAux');
         netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));
         
         % create misc variables
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
         netcdf.putAtt(fCdf, stationParametersVarId, 'conventions', 'Reference table AUX_3a');
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
            ncParamName = sprintf('PROFILE_%s_QC', profParamName);
            
            profileParamQcVarId = netcdf.defVar(fCdf, ncParamName, 'NC_CHAR', nProfDimId);
            netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of %s profile', profParamName));
            netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
            netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');
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
         calibInfo = [];
         doubleTypeInFile = 0;
         for idP = 1:nbProfToStore
            
            prof = a_tabProfiles(idProfInFile(idP));
            
            % profile parameter data
            parameterList = prof.paramList;
            for idParam = 1:length(parameterList)
               
               profParam = parameterList(idParam);
               profParamName = profParam.name;
               profParamNcType = profParam.paramNcType;
               
               % find if this parameter has sublevels
               paramWithSubLevels = 0;
               if (~isempty(prof.paramNumberWithSubLevels))
                  idF = find(prof.paramNumberWithSubLevels == idParam);
                  if (~isempty(idF))
                     paramWithSubLevels = 1;
                     paramSubLevelsDim = dimSubLevels(find(strcmp(profParamName, paramSubLevels), 1));
                     %                            nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', prof.paramNumberOfSubLevels(idF)));
                     nValuesDimId = netcdf.inqDimID(fCdf, sprintf('N_VALUES%d', paramSubLevelsDim));
                  end
               end
               
               % parameter variable and attributes
               if (~var_is_present_dec_argo(fCdf, profParamName))
                  
                  if (strcmp(profParamNcType, 'NC_DOUBLE'))
                     doubleTypeInFile = 1;
                  end
                  if (paramWithSubLevels == 0)
                     profParamVarId = netcdf.defVar(fCdf, profParamName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));
                  else
                     profParamVarId = netcdf.defVar(fCdf, profParamName, profParamNcType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
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
               
               % parameter adjusted variable and attributes
               if (profParam.adjAllowed == 1)
                  
                  profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                  if (~var_is_present_dec_argo(fCdf, profParamAdjName))
                     
                     if (paramWithSubLevels == 0)
                        profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));
                     else
                        profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, profParamNcType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
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
                        profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));
                     else
                        profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, profParamNcType, fliplr([nProfDimId nLevelsDimId nValuesDimId]));
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
         netcdf.putAtt(fCdf, historyParameterVarId, 'conventions', 'Reference table AUX_3a');
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
         
         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % DEFINE MODE END
         if (VERBOSE_MODE == 2)
            fprintf('STOP DEFINE MODE\n');
         end
         
         netcdf.endDef(fCdf);
         
         valueStr = 'Aux-Argo profile';
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
         
         % create profile variables
         
         for idP = 1:nbProfToStore
            prof = a_tabProfiles(idProfInFile(idP));
            
            profPos = idP-1+profShiftIfNoPrimary;
            
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
               
               if (~strcmp(parameterList(idParam).name(end-3:end), '_STD') && ...
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
            
            netcdf.putVar(fCdf, cycleNumberVarId, profPos, 1, outputCycleNumber);
            
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
         adjustedProfilesList = zeros(nbProfToStore, 1);
         for idP = 1:nbProfToStore
            prof = a_tabProfiles(idProfInFile(idP));
            if (~prof.fakeProfFlag)
               [adjustedProfilesList(idP)] = rt_adjusment_exist(prof, 0);
            end
         end
         
         % add profile data
         for idP = 1:nbProfToStore
            
            prof = a_tabProfiles(idProfInFile(idP));
            
            profPos = idP-1+profShiftIfNoPrimary;
            
            if (VERBOSE_MODE == 2)
               fprintf('Add profile #%d/%d data\n', ...
                  profPos, nbProfInFile);
            end
            
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
                  g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, ...
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
               
               profParam = parameterList(idParam);
               
               % parameter variable and attributes
               profParamName = profParam.name;
               profParamVarId = netcdf.inqVarID(fCdf, profParamName);
               
               % parameter QC variable and attributes
               profParamQcVarId = '';
               if ~(strcmp(profParam.name(end-3:end), '_STD') || ...
                     strcmp(profParam.name(end-3:end), '_MED'))
                  profParamQcName = sprintf('%s_QC', profParam.name);
                  profParamQcVarId = netcdf.inqVarID(fCdf, profParamQcName);
               end
               
               if (profParam.adjAllowed == 1)
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
                        
                        if ~(strcmp(profParam.name(end-3:end), '_STD') || ...
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
                  
                  % parameter RT adjustment
                  paramAdjData = [];
                  if (adjustedProfilesList(idP) == 1)
                     if (profParam.adjAllowed == 1)
                        
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
                  
                  % RT PRES adjustment of Apex float
                  if (~isempty(prof.presOffset))
                     if (profParam.adjAllowed == 1)
                        
                        paramDataIn = paramData;
                        if (~isempty(paramAdjData))
                           paramDataIn = paramAdjData;
                        end
                        
                        if (strcmp(profParamName, 'PRES'))
                           % process RT adjustment of this parameter
                           [paramAdjData] = compute_adjusted_pres(paramDataIn, prof.presOffset);
                           
                           % store parameter adjusted data in ADJUSTED variable
                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjData(measIds));
                           
                           paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                           paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));
                        else
                           % copy parameter data in ADJUSTED variable
                           netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramDataIn)]), paramDataIn(measIds));
                           
                           paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramDataIn, 1), 1);
                           paramAdjDataQcStr(find(paramDataIn ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataIn)]), paramAdjDataQcStr(measIds));
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
                        
                        if ~(strcmp(profParam.name(end-3:end), '_STD') || ...
                              strcmp(profParam.name(end-3:end), '_MED'))
                           profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                           profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                        end
                     end
                  end
                  
                  if (prof.direction == 'A')
                     measIds = fliplr([1:size(paramData, 1)]);
                  else
                     measIds = [1:size(paramData, 1)];
                  end
                  if (size(paramData, 2) == 1)
                     
                     netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));
                     
                     if (~isempty(profParamQcVarId))
                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQcStr)]), paramDataQcStr(measIds));
                     end
                     
                     if (adjustedProfilesList(idP) == 1)
                        if (profParam.adjAllowed == 1)
                           
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
                     
                     netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0 0]), fliplr([1 size(paramData)]), paramData(measIds, :)');
                     
                     if (~isempty(profParamQcVarId))
                        netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramDataQcStr)]), paramDataQcStr(measIds));
                     end
                     
                     if (adjustedProfilesList(idP) == 1)
                        if (profParam.adjAllowed == 1)
                           
                           % process RT adjustment of this parameter
                           [paramAdjData] = compute_adjusted_data(paramData, profParam, prof);
                           
                           if (~isempty(paramAdjData))
                              
                              adjustedParamIdList = [adjustedParamIdList paramPos];
                              
                              % store parameter adjusted data in ADJUSTED variable
                              netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 size(paramAdjData)]), paramAdjData(measIds, :)');
                              
                              paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                              for idL = 1: size(paramAdjData, 1)
                                 if (~isempty(find(paramAdjData(idL, :) ~= profParam.fillValue, 1)))
                                    paramAdjDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                 end
                              end
                              netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 size(paramAdjData, 1)]), paramAdjDataQcStr(measIds));
                           else
                              % copy parameter data in ADJUSTED variable
                              netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0 0]), fliplr([1 size(paramData)]), paramData(measIds, :)');
                              
                              paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramData, 1), 1);
                              for idL = 1: size(paramData, 1)
                                 if (~isempty(find(paramData(idL, :) ~= profParam.fillValue, 1)))
                                    paramAdjDataQcStr(idL) = g_decArgo_qcStrNoQc;
                                 end
                              end
                              netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 size(paramData, 1)]), paramAdjDataQcStr(measIds));
                           end
                        end
                     end
                  end
               end
               paramPos = paramPos + 1;
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
                  if (~isempty(metaData) && isstruct(metaData))
                     tabParam = unique(struct2cell(metaData));
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
            
            profInfo(idProfInFile(idP), 4) = 1;
         end
         
         % process calibration information
         
         % compute the N_CALIB dimension
         nbCalib = 1;
         for idC = 1:length(calibInfo)
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
         
         netcdf.reDef(fCdf);
         
         nCalibDimId = netcdf.defDim(fCdf, 'N_CALIB', nbCalib);
         
         % calibration information
         parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string64DimId]));
         netcdf.putAtt(fCdf, parameterVarId, 'long_name', 'List of parameters with calibration information');
         netcdf.putAtt(fCdf, parameterVarId, 'conventions', 'Reference table AUX_3a');
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
         
         % fill PARAMETER variable (even if there is no RT adjustments)
         ncParamlist = repmat({''}, nbProfToStore, nbProfParam);
         for idP = 1:nbProfToStore
            prof = a_tabProfiles(idProfInFile(idP));
            parameterList = prof.paramList;
            profPos = idP-1+profShiftIfNoPrimary;
            paramPos = 0;
            for idParam = 1:length(parameterList)
               
               if (~strcmp(parameterList(idParam).name(end-3:end), '_STD') && ...
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
         
         for idC = 1:length(calibInfo)
            profId = calibInfo{idC}.profId;
            profPos = profId-1+profShiftIfNoPrimary;
            tabParams = calibInfo{idC}.param;
            tabEquations = calibInfo{idC}.equation;
            tabCoefficients = calibInfo{idC}.coefficient;
            tabComments = calibInfo{idC}.comment;
            tabDates = calibInfo{idC}.date;
            
            for idParam = 1:length(tabParams)
               param = tabParams{idParam};
               idPosParam = find(strcmp(ncParamlist(profId, :), param) == 1);
               if (isempty(idPosParam))
                  continue
               end
               tabEquation = tabEquations{idParam};
               tabCoefficient = tabCoefficients{idParam};
               tabComment = tabComments{idParam};
               tabDate = tabDates{idParam};
               
               for idCalib = 1:max([length(tabEquation) length(tabCoefficient) length(tabComment) length(tabDate)])
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
         
         if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_applyRtqc == 1))
            % store information for the XML report
            g_decArgo_reportStruct.outputMonoProfAuxFiles = [g_decArgo_reportStruct.outputMonoProfAuxFiles ...
               {ncPathFileName}];
         end
      end
   end
end

fprintf('... NetCDF MONO-PROFILE AUX files created\n');

return
