% ------------------------------------------------------------------------------
% Create NetCDF MONO-PROFILE c files.
%
% SYNTAX :
%  [o_cFileInfo] = create_nc_mono_prof_c_files_3_1( ...
%    a_decoderId, a_tabProfiles, a_metaDataFromJson, a_cFileToCreate)
%
% INPUT PARAMETERS :
%   a_decoderId        : float decoder Id
%   a_tabProfiles      : decoded profiles
%   a_metaDataFromJson : additional information retrieved from JSON meta-data
%                        file
%   a_cFileToCreate    : information on C-PROF files that should be generated
%
% OUTPUT PARAMETERS :
%   o_cFileInfo : information on generated C-PROF files
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_cFileInfo] = create_nc_mono_prof_c_files_3_1( ...
   a_decoderId, a_tabProfiles, a_metaDataFromJson, a_cFileToCreate)

% output parameters initialization
o_cFileInfo = [];

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

% to store information on PARAM adjustment
global g_decArgo_paramProfAdjInfo;

% max length allowed for VERTICAL_SAMPLING_SCHEME
global g_decArgo_vssMaxLength;


% verbose mode flag
VERBOSE_MODE = 1;

% no data to save
if (isempty(a_tabProfiles))
   return
end

% select Auxiliary profiles
idProfAux = find([a_tabProfiles.sensorNumber] > 100);
a_tabAuxProfiles = a_tabProfiles(idProfAux);
a_tabProfiles(idProfAux) = [];

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

% 03/24/2015: the GDAC checker cannot check 'empty' profiles, we will add a
% default profile with fillValue measurements

% collect information on profiles
profInfo = [];
for idProf = 1:length(a_tabProfiles)
   profile = a_tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag]];
end

% add 'default' primary profiles
tabProfiles = a_tabProfiles;
cyNumList = unique(profInfo(:, 1));
dirList = unique(profInfo(:, 2));
for idCy = 1:length(cyNumList)
   cyNum = cyNumList(idCy);
   for idDir = 1:length(dirList)
      direction = dirList(idDir);

      if (~isempty(find( ...
            (profInfo(:, 1) == cyNum) & ...
            (profInfo(:, 2) == direction), 1)))

         idProfInFile = find( ...
            (profInfo(:, 1) == cyNum) & ...
            (profInfo(:, 2) == direction));
         idPrimary = find(profInfo(idProfInFile, 3) == 1, 1);

         if (isempty(idPrimary))

            % create a 'default' primary c profile
            defaultPrimaryProfile = create_default_primary_profile( ...
               cyNum, direction, ...
               tabProfiles, a_decoderId);

            fprintf('DEC_INFO: Float #%d Output Cycle #%d ''%c'': no primary sampling profile - adding a ''default'' one\n', ...
               g_decArgo_floatNum, cyNum, defaultPrimaryProfile.direction);

            % add it to the profiles to process
            tabProfiles(end+1) = defaultPrimaryProfile;
         end
      end
   end
end

% collect information on profiles
profInfo = [];
for idProf = 1:length(tabProfiles)
   profile = tabProfiles(idProf);
   direction = 2;
   if (profile.direction == 'D')
      direction = 1;
   end
   profInfo = [profInfo; ...
      [profile.outputCycleNumber direction profile.primarySamplingProfileFlag 0]];
end

generatedProfList = [];
for idProf = 1:length(tabProfiles)
   if (profInfo(idProf, 4) == 0)
      profile = tabProfiles(idProf);
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

      % put the primary sampling profile on top of the list
      idPrimary = find(profInfo(idProfInFile, 3) == 1);
      profShiftIfNoPrimary = 0;
      if (length(idPrimary) == 1)
         idProfInFile = [idProfInFile(idPrimary); idProfInFile];
         idProfInFile(idPrimary+1) = [];
      else
         if (isempty(idPrimary))
            % should never append since 03/24/2015 (see above)
            fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no primary sampling profile\n', ...
               g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
            profShiftIfNoPrimary = 1;
         else
            fprintf('ERROR: Float #%d Cycle #%d Profile #%d Output Cycle #%d: multiple (%d) primary sampling profiles\n', ...
               g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, length(idPrimary));
         end
      end
      nbProfInFile = nbProfToStore + profShiftIfNoPrimary;

      % create the profile parameters list and compute the number of levels
      profParamName = [];
      nbProfParam = 0;
      nbProfLevels = 0;
      for idP = 1:nbProfToStore
         paramNameOfProf = [];
         prof = tabProfiles(idProfInFile(idP));
         parameterList = prof.paramList;
         profileData = prof.data;
         for idParam = 1:length(parameterList)
            if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))
               profParamName = [profParamName; {parameterList(idParam).name}];
               paramNameOfProf = [paramNameOfProf; {parameterList(idParam).name}];
               nbProfLevels = max(nbProfLevels, size(profileData, 1));
            end
         end
         nbProfParam = max(nbProfParam, length(unique(paramNameOfProf)));
      end
      profUniqueParamName = unique(profParamName, 'stable');

      if (nbProfParam > 0)

         % create output file pathname
         floatNumStr = num2str(g_decArgo_floatNum);
         outputDirName = [g_decArgo_dirOutputNetcdfFile '/' floatNumStr '/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end
         outputDirName = [outputDirName '/profiles/'];
         if ~(exist(outputDirName, 'dir') == 7)
            mkdir(outputDirName);
         end

         if (direction == 1)
            ncFileName = sprintf('R%d_%03dD.nc', ...
               g_decArgo_floatNum, outputCycleNumber);
         else
            ncFileName = sprintf('R%d_%03d.nc', ...
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
                        (isempty(find([tabProfiles(idProfInFile).updated] == 1, 1))))
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
                        (isempty(find([tabProfiles(idProfInFile).updated] == 1, 1))))
                     generate = 0;
                  end
               end
            end

         else

            if (g_decArgo_generateNcMonoProf == 2)

               if (g_decArgo_realtimeFlag == 1)

                  fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: no strategy to generate or not profile NetCDF files - generating all profile fles\n', ...
                     g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber);
               end
            end
         end

         % some files should be generated from input parameter list
         if (generate == 0)
            if (~isempty(a_cFileToCreate))
               if (any((a_cFileToCreate(:, 1) == outputCycleNumber) & (a_cFileToCreate(:, 2) == direction)))
                  generate = 1;
               end
            end
         end

         % some profile positions may have been updated
         if (generate == 0)
            if (exist(ncPathFileName, 'file') == 2)

               % retrieve profile location of the nc file
               [ncProfLocStr, ncProfQc] = get_nc_profile_location(ncPathFileName);

               % compare profile location
               prof = tabProfiles(idProfInFile(1));
               profLocStr = sprintf('%s %.3f %.3f %s', ...
                  julian_2_gregorian_dec_argo(prof.locationDate), ...
                  prof.locationLat, prof.locationLon, prof.posSystem);
               if ((((ncProfQc == '8') && (prof.locationQc ~= '8')) || ...
                     ((ncProfQc ~= '8') && (prof.locationQc == '8'))) || ...
                     ~strcmp(profLocStr, ncProfLocStr))
                  generate = 1;
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
                        profPos = idP-1+profShiftIfNoPrimary;
                        if (profPos+1 > length(ncProfLev))
                           % new pofiles should be added in the file
                           differ = 1;
                           break
                        end

                        prof = tabProfiles(idProfInFile(idP));

                        % profile parameter data
                        parameterList = prof.paramList;
                        nLevelsParam = 0;
                        idNoDefAll = [];
                        for idParam = 1:length(parameterList)
                           if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))
                              profParam = parameterList(idParam);
                              profParamName = profParam.name;
                              paramInfo = get_netcdf_param_attributes(profParamName);
                              % prof.data is empty in 'default' primary profiles
                              if (~isempty(prof.data))
                                 % parameter data
                                 paramData = prof.data(:, idParam);
                                 idNoDef = find(paramData ~= paramInfo.fillValue);
                                 idNoDefAll = [idNoDefAll idNoDef'];
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

                     if (generate == 0)
                        if ((a_decoderId > 2000) && (a_decoderId < 3000))

                           % NOVA/DOVA float
                           % the clock offset is not defined for the last cycle
                           % (needed information for cycle N is transmitted during
                           % cycle N+1) => profile JULD (and JULD_LOCATION since
                           % it is in float time) can be adjusted during the
                           % following cycles
                           % => the file should be updated if it was the last one
                           % of the previous run and we received a new one

                           fileCycleNum = [];
                           floatFiles = [dir([outputDirName '/' sprintf('R%d_*.nc', g_decArgo_floatNum)]); ...
                              dir([outputDirName '/' sprintf('D%d_*.nc', g_decArgo_floatNum)])];
                           for idFile = 1:length(floatFiles)
                              floatFileName = floatFiles(idFile).name;
                              idFUs = strfind(floatFileName, '_');
                              fileCycleNum = [fileCycleNum str2num(floatFileName(idFUs+1:idFUs+3))];
                           end

                           if (~isempty(fileCycleNum))
                              if ((outputCycleNumber == max(fileCycleNum)) && ...
                                    (any(profInfo(:, 1) == outputCycleNumber+1)))
                                 generate = 1;
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
         if (generate == 0)
            continue
         end

         generatedProfList = [generatedProfList; outputCycleNumber direction];

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
               fprintf('Updating NetCDF MONO-PROFILE file (%s) ...\n', ncFileName);
            end

         else
            if ((VERBOSE_MODE == 1) || (VERBOSE_MODE == 2))
               fprintf('Creating NetCDF MONO-PROFILE file (%s) ...\n', ncFileName);
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
         string64DimId = netcdf.defDim(fCdf, 'STRING64', 64);
         paramNameLength = 16;
         string32DimId = netcdf.defDim(fCdf, 'STRING32', 32);
         string16DimId = netcdf.defDim(fCdf, 'STRING16', 16);
         string8DimId = netcdf.defDim(fCdf, 'STRING8', 8);
         string4DimId = netcdf.defDim(fCdf, 'STRING4', 4);
         string2DimId = netcdf.defDim(fCdf, 'STRING2', 2);

         nProfDimId = netcdf.defDim(fCdf, 'N_PROF', nbProfInFile);
         nParamDimId = netcdf.defDim(fCdf, 'N_PARAM', nbProfParam);
         nLevelsDimId = netcdf.defDim(fCdf, 'N_LEVELS', nbProfLevels);
         % N_CALIB dimension is processed and created later
         nHistoryDimId = netcdf.defDim(fCdf, 'N_HISTORY', netcdf.getConstant('NC_UNLIMITED'));

         if (VERBOSE_MODE == 2)
            fprintf('N_PROF = %d\n', nbProfInFile);
            fprintf('N_PARAM = %d\n', nbProfParam);
            fprintf('N_LEVELS = %d\n', nbProfLevels);
         end

         % create global attributes
         globalVarId = netcdf.getConstant('NC_GLOBAL');
         netcdf.putAtt(fCdf, globalVarId, 'title', 'Argo float vertical profile');
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
         netcdf.putAtt(fCdf, globalVarId, 'featureType', 'trajectoryProfile');
         netcdf.putAtt(fCdf, globalVarId, 'decoder_version', sprintf('CODA_%s', g_decArgo_decoderVersion));

         % create misc variables
         dataTypeVarId = netcdf.defVar(fCdf, 'DATA_TYPE', 'NC_CHAR', string16DimId);
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

         stationParametersVarId = netcdf.defVar(fCdf, 'STATION_PARAMETERS', 'NC_CHAR', fliplr([nProfDimId nParamDimId string16DimId]));
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
         for idP = 1:nbProfToStore

            prof = tabProfiles(idProfInFile(idP));

            % profile parameter data
            parameterList = prof.paramList;
            for idParam = 1:length(parameterList)

               if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                  profParam = parameterList(idParam);
                  profParamName = profParam.name;
                  profParamNcType = profParam.paramNcType;

                  % parameter variable and attributes
                  if (~var_is_present_dec_argo(fCdf, profParamName))

                     profParamVarId = netcdf.defVar(fCdf, profParamName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));

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
                  profParamQcName = sprintf('%s_QC', profParam.name);
                  if (~var_is_present_dec_argo(fCdf, profParamQcName))

                     profParamQcVarId = netcdf.defVar(fCdf, profParamQcName, 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));

                     netcdf.putAtt(fCdf, profParamQcVarId, 'long_name', 'quality flag');
                     netcdf.putAtt(fCdf, profParamQcVarId, 'conventions', 'Argo reference table 2');
                     netcdf.putAtt(fCdf, profParamQcVarId, '_FillValue', ' ');
                  end

                  % parameter adjusted variable and attributes
                  if (profParam.adjAllowed == 1)

                     profParamAdjName = sprintf('%s_ADJUSTED', profParam.name);
                     if (~var_is_present_dec_argo(fCdf, profParamAdjName))

                        profParamAdjVarId = netcdf.defVar(fCdf, profParamAdjName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));

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

                        profParamAdjErrVarId = netcdf.defVar(fCdf, profParamAdjErrName, profParamNcType, fliplr([nProfDimId nLevelsDimId]));

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

         historyParameterVarId = netcdf.defVar(fCdf, 'HISTORY_PARAMETER', 'NC_CHAR', fliplr([nHistoryDimId nProfDimId string16DimId]));
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

         historyPreviousValueVarId = netcdf.defVar(fCdf, 'HISTORY_PREVIOUS_VALUE', 'NC_FLOAT', fliplr([nHistoryDimId nProfDimId]));
         netcdf.putAtt(fCdf, historyPreviousValueVarId, 'long_name', 'Parameter/Flag previous value before action');
         netcdf.putAtt(fCdf, historyPreviousValueVarId, '_FillValue', single(99999));

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

         valueStr = 'Argo profile';
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
         valueStr = sprintf('%d', g_decArgo_floatNum);
         valueStr = [valueStr blanks(8-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, platformNumberVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         valueStr = ' ';
         idVal = find(strcmp('PROJECT_NAME', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         valueStr = [valueStr blanks(64-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, projectNameVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         valueStr = ' ';
         idVal = find(strcmp('PI_NAME', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         valueStr = [valueStr blanks(64-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, piNameVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         for idP = 1:nbProfToStore
            prof = tabProfiles(idProfInFile(idP));
            parameterList = prof.paramList;
            profPos = idP-1+profShiftIfNoPrimary;
            paramPos = 0;
            for idParam = 1:length(parameterList)

               if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                  valueStr = parameterList(idParam).name;
                  if (length(valueStr) > paramNameLength)
                     fprintf('ERROR: Float #%d : NetCDF variable name %s too long (> %d) - name truncated\n', ...
                        g_decArgo_floatNum, valueStr, paramNameLength);
                     valueStr = valueStr(1:paramNameLength);
                  end

                  netcdf.putVar(fCdf, stationParametersVarId, ...
                     fliplr([profPos paramPos 0]), fliplr([1 1 length(valueStr)]), valueStr');
                  paramPos = paramPos + 1;
               end
            end
         end

         netcdf.putVar(fCdf, cycleNumberVarId, profShiftIfNoPrimary, nbProfToStore, ones(1, nbProfToStore)*outputCycleNumber);

         valueStr = ' ';
         idVal = find(strcmp('DATA_CENTRE', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         valueStr = [valueStr blanks(2-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, dataCenterVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         valueStr = '1A';
         valueStr = [valueStr blanks(4-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, dataStateIndicatorVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         netcdf.putVar(fCdf, dataModeVarId, profShiftIfNoPrimary, nbProfToStore, repmat('R', 1, nbProfToStore));

         valueStr = get_platform_type(a_decoderId);
         valueStr = [valueStr blanks(32-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, platformTypeVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         valueStr = ' ';
         idVal = find(strcmp('FLOAT_SERIAL_NO', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         valueStr = [valueStr blanks(32-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, floatSerialNoVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         valueStr = ' ';
         idVal = find(strcmp('FIRMWARE_VERSION', a_metaDataFromJson) == 1);
         if (~isempty(idVal))
            valueStr = char(a_metaDataFromJson{idVal+1});
         end
         valueStr = [valueStr blanks(32-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, firmwareVersionVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

         valueStr = get_wmo_instrument_type(a_decoderId);
         valueStr = [valueStr blanks(4-length(valueStr))];
         tabValue = repmat(valueStr, nbProfToStore, 1);
         netcdf.putVar(fCdf, wmoInstTypeVarId, ...
            fliplr([profShiftIfNoPrimary 0]), ...
            fliplr([nbProfToStore size(tabValue, 2)]), permute(tabValue, fliplr(1:ndims(tabValue))));

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
               fprintf('WARNING: Float #%d : N_PROF=%d in existing file, N_PROF=%d in updated file - history information not copied when updating file %s\n', ...
                  g_decArgo_floatNum, size(histoInstitution, 2), nbProfInFile, ncPathFileName);
            end
         end

         % add profile data
         for idP = 1:nbProfToStore
            if (VERBOSE_MODE == 2)
               fprintf('Add profile #%d/%d data\n', ...
                  idP+profShiftIfNoPrimary, nbProfInFile);
            end

            profPos = idP-1+profShiftIfNoPrimary;
            prof = tabProfiles(idProfInFile(idP));

            % profile direction
            netcdf.putVar(fCdf, directionVarId, profPos, 1, prof.direction);

            % profile date
            profDate = prof.date;
            if (profDate ~= g_decArgo_dateDef)
               netcdf.putVar(fCdf, juldVarId, profPos, 1, profDate);
               if (~isempty(prof.dateQc))
                  netcdf.putVar(fCdf, juldQcVarId, profPos, 1, prof.dateQc);
               else
                  netcdf.putVar(fCdf, juldQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
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
               if (~isempty(profLocationQc))
                  netcdf.putVar(fCdf, positionQcVarId, profPos, 1, profLocationQc);
               else
                  netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrNoQc);
               end
            else
               netcdf.putVar(fCdf, positionQcVarId, profPos, 1, g_decArgo_qcStrMissing);
            end
            netcdf.putVar(fCdf, positioningSystemVarId, fliplr([profPos 0]), fliplr([1 length(profPosSystem)]), profPosSystem');

            % vertical sampling scheme
            vertSampScheme = prof.vertSamplingScheme;
            if (length(vertSampScheme) > g_decArgo_vssMaxLength)
               fprintf('WARNING: Float #%d Cycle #%d Profile #%d Output Cycle #%d: vertical sampling scheme too long (length = %d > %d) - vertical sampling scheme ''%s'' not set\n', ...
                  g_decArgo_floatNum, cycleNumber, profileNumber, outputCycleNumber, ...
                  length(vertSampScheme), g_decArgo_vssMaxLength, ...
                  vertSampScheme);
               idF1 = strfind(vertSampScheme, '[');
               idF2 = strfind(vertSampScheme, ']');
               vertSampScheme = [vertSampScheme(1:idF1(1)) 'detailed description too long for available space' vertSampScheme(idF2(end):end)];
            end
            netcdf.putVar(fCdf, verticalSamplingSchemeVarId, fliplr([profPos 0]), fliplr([1 length(vertSampScheme)]), vertSampScheme');

            % configuration mission number
            if (~isempty(prof.configMissionNumber))
               netcdf.putVar(fCdf, configMissionNumberVarId, profPos, 1, prof.configMissionNumber);
            end

            % profile parameter data
            parameterList = prof.paramList;
            parameterDataMode = prof.paramDataMode;
            adjInCoreFlag = 0;
            if (~isempty(parameterDataMode))
               if (any(parameterDataMode([parameterList.paramType] == 'c') == 'A') || any(parameterDataMode([parameterList.paramType] == 'j') == 'A'))
                  adjInCoreFlag = 1;
                  netcdf.putVar(fCdf, dataModeVarId, profPos, 1, 'A');
               end
            end
            for idParam = 1:length(parameterList)

               if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

                  profParam = parameterList(idParam);

                  % parameter variable and attributes

                  profParamName = profParam.name;
                  profParamVarId = netcdf.inqVarID(fCdf, profParamName);

                  % parameter QC variable and attributes
                  profParamQcName = sprintf('%s_QC', profParam.name);
                  profParamQcVarId = netcdf.inqVarID(fCdf, profParamQcName);

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

                  % prof.data is empty in 'default' primary profiles
                  if (~isempty(prof.data))

                     % parameter data
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

                           profQualityFlag = compute_profile_quality_flag(paramDataQcStr);
                           profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                        end
                     end

                     if (prof.direction == 'A')
                        measIds = fliplr([1:length(paramData)]);
                     else
                        measIds = [1:length(paramData)];
                     end
                     netcdf.putVar(fCdf, profParamVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramData(measIds));

                     netcdf.putVar(fCdf, profParamQcVarId, fliplr([profPos 0]), fliplr([1 length(paramData)]), paramDataQcStr(measIds));

                     if ((profParam.adjAllowed == 1) && (adjInCoreFlag))

                        % parameter adjusted data
                        if (parameterDataMode(idParam) == ' ')
                           paramAdjData = paramData;
                           paramAdjDataQcStr = paramDataQcStr;
                        else
                           paramAdjData = prof.dataAdj(:, idParam);
                           if (isempty(prof.dataAdjQc))
                              paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                              paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                           else
                              paramAdjDataQc = prof.dataAdjQc(:, idParam);
                              if (all(paramAdjDataQc == g_decArgo_qcDef))
                                 paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, size(paramAdjData, 1), 1);
                                 paramAdjDataQcStr(find(paramAdjData ~= profParam.fillValue)) = g_decArgo_qcStrNoQc;
                              else
                                 paramAdjDataQcStr = repmat(g_decArgo_qcStrDef, length(paramAdjData), 1);
                                 idNoDef = find(paramAdjDataQc ~= g_decArgo_qcDef);
                                 paramAdjDataQcStr(idNoDef) = num2str(paramAdjDataQc(idNoDef));

                                 profQualityFlag = compute_profile_quality_flag(paramAdjDataQcStr);
                                 profileParamQcName = sprintf('PROFILE_%s_QC', profParam.name);
                                 netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profileParamQcName), profPos, 1, profQualityFlag);
                              end
                           end
                        end

                        netcdf.putVar(fCdf, profParamAdjVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjData(measIds));

                        netcdf.putVar(fCdf, profParamAdjQcVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjData)]), paramAdjDataQcStr(measIds));

                        if (~isempty(prof.dataAdjError))
                           paramAdjDataError = prof.dataAdjError(:, idParam);
                           if (any(paramAdjDataError ~= profParam.fillValue))
                              netcdf.putVar(fCdf, profParamAdjErrVarId, fliplr([profPos 0]), fliplr([1 length(paramAdjDataError)]), paramAdjDataError(measIds));
                           end
                        end
                     end
                  end
               end
            end

            % add PRES adjustment information
            if (any(strcmp({prof.paramList.name}, 'PRES')))
               if (~isempty(prof.presOffset))

                  tabParam = {'PRES'};
                  tabEquation = {'PRES_ADJUSTED = PRES - Surface Pressure'};
                  tabCoefficient = {['Surface Pressure = ' num2str(prof.presOffset) ' dbar']};
                  tabComment = {'Pressure adjusted in real time by using pressure offset at the sea surface'};
                  if (isempty(ncCreationDate))
                     date = currentDate;
                  else
                     date = ncCreationDate;
                  end
                  tabDate = {date};

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

            % for decoder RT adjustments:
            % retrieve SCIENTIFIC_CALIB_* from decoder g_decArgo_paramProfAdjInfo
            % global variable
            if (~isempty(prof.rtParamAdjIdList))
               for idAdj = prof.rtParamAdjIdList

                  % retrieve information on PARAM adjustment
                  idF = find([g_decArgo_paramProfAdjInfo{:, 1}] == idAdj);
                  paramAdjInfo = g_decArgo_paramProfAdjInfo(idF, :);
                  paramName = paramAdjInfo{4};

                  paramInfo = get_netcdf_param_attributes(paramName);
                  if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'j'))
                     paramEquation = paramAdjInfo{5};
                     paramCoefficient = paramAdjInfo{6};
                     paramComment = paramAdjInfo{7};
                     paramDate = paramAdjInfo{8};

                     if (isempty(paramDate))
                        if (isempty(ncCreationDate))
                           paramDate = currentDate;
                        else
                           paramDate = ncCreationDate;
                        end
                     end
                     tabParam = {paramName};
                     tabEquation = {paramEquation};
                     tabCoefficient = {paramCoefficient};
                     tabComment = {paramComment};
                     tabDate = {paramDate};

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

            % add a SCIENTIFIC_CALIB_COMMENT for duplicated data
            if (~isempty(calibInfo))
               calibList = [calibInfo{:}];
               idF = find([calibList.profId] == idP);
               if (~isempty(idF))
                  calibListForProf = [calibInfo{idF}];
                  newList = setdiff({prof.paramList.name}, [calibListForProf.param]);
                  for idParam = 1:length(newList)
                     paramName = newList{idParam};
                     paramInfo = get_netcdf_param_attributes(paramName);
                     if (paramInfo.paramType == 'c')

                        tabParam = {paramName};
                        tabEquation = {[paramName '_ADJUSTED = ' paramName]};
                        tabCoefficient = {'Not applicable'};
                        tabComment = {'No adjustment performed (values duplicated)'};
                        if (isempty(ncCreationDate))
                           date = currentDate;
                        else
                           date = ncCreationDate;
                        end
                        tabDate = {date};

                        % store calibration information for this profile
                        profCalibInfo = [];
                        profCalibInfo.profId = idP;
                        profCalibInfo.param = tabParam;
                        profCalibInfo.equation = tabEquation;
                        profCalibInfo.coefficient = tabCoefficient;
                        profCalibInfo.comment = tabComment;
                        profCalibInfo.date = tabDate;
                        calibInfo{end+1} = profCalibInfo;
                     elseif (paramInfo.paramType == 'j')

                        tabParam = {paramName};
                        tabEquation = {'Not applicable'};
                        tabCoefficient = {'Not applicable'};
                        tabComment = {'Not applicable'};
                        if (isempty(ncCreationDate))
                           date = currentDate;
                        else
                           date = ncCreationDate;
                        end
                        tabDate = {date};

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
         if (~isempty(calibInfo))
            tabCalibInfo1 = [];
            for idC = 1:length(calibInfo)
               if (isempty(tabCalibInfo1))
                  tabCalibInfo1 = [tabCalibInfo1; calibInfo{idC}.profId calibInfo{idC}.param 1];
               else
                  idF = find(([tabCalibInfo1{:, 1}] == calibInfo{idC}.profId)' & ...
                     strcmp(tabCalibInfo1(:, 2), calibInfo{idC}.param{:}));
                  if (isempty(idF))
                     tabCalibInfo1 = [tabCalibInfo1; calibInfo{idC}.profId calibInfo{idC}.param 1];
                  else
                     tabCalibInfo1{idF, end} = tabCalibInfo1{idF, end} + 1;
                  end
               end
            end
            nbCalib = max([tabCalibInfo1{:, end}]);
         end

         netcdf.reDef(fCdf);

         nCalibDimId = netcdf.defDim(fCdf, 'N_CALIB', nbCalib);

         % calibration information
         parameterVarId = netcdf.defVar(fCdf, 'PARAMETER', 'NC_CHAR', fliplr([nProfDimId nCalibDimId nParamDimId string16DimId]));
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

         % fill PARAMETER variable (even if there is no RT adjustments)
         ncParamlist = repmat({''}, nbProfToStore, nbProfParam);
         for idP = 1:nbProfToStore
            prof = tabProfiles(idProfInFile(idP));
            parameterList = prof.paramList;
            profPos = idP-1+profShiftIfNoPrimary;
            paramPos = 0;
            for idParam = 1:length(parameterList)
               if ((parameterList(idParam).paramType == 'c') || (parameterList(idParam).paramType == 'j'))

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

         tabCalibInfo2 = [];
         for idC = 1:length(calibInfo)
            profId = calibInfo{idC}.profId;
            profPos = profId-1+profShiftIfNoPrimary;
            param = calibInfo{idC}.param{:};
            idPosParam = find(strcmp(ncParamlist(profId, :), param) == 1);
            equation = calibInfo{idC}.equation{:};
            coef = calibInfo{idC}.coefficient{:};
            comment = calibInfo{idC}.comment{:};
            date = calibInfo{idC}.date{:};

            % compute start calibId
            if (isempty(tabCalibInfo2))
               tabCalibInfo2 = [tabCalibInfo2; calibInfo{idC}.profId calibInfo{idC}.param 1];
               idCalibStart = 1;
            else
               idF = find(([tabCalibInfo2{:, 1}] == calibInfo{idC}.profId)' & ...
                  strcmp(tabCalibInfo2(:, 2), calibInfo{idC}.param{:}));
               if (isempty(idF))
                  tabCalibInfo2 = [tabCalibInfo2; calibInfo{idC}.profId calibInfo{idC}.param 1];
                  idCalibStart = 1;
               else
                  tabCalibInfo2{idF, end} = tabCalibInfo2{idF, end} + 1;
                  idCalibStart = idCalibStart + 1;
               end
            end

            idF = find(([tabCalibInfo1{:, 1}] == profId)' & strcmp(tabCalibInfo1(:, 2), param));
            idCalibStop = idCalibStart + (nbCalib-tabCalibInfo1{idF, end});

            for id = idCalibStart:idCalibStop
               value = param;
               if (~isempty(value))
                  netcdf.putVar(fCdf, parameterVarId, ...
                     fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
               end
               value = equation;
               if (~isempty(value))
                  netcdf.putVar(fCdf, scientificCalibEquationVarId, ...
                     fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
               end
               value = coef;
               if (~isempty(value))
                  netcdf.putVar(fCdf, scientificCalibCoefficientVarId, ...
                     fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
               end
               value = comment;
               if (~isempty(value))
                  netcdf.putVar(fCdf, scientificCalibCommentVarId, ...
                     fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
               end
               value = date;
               if (~isempty(value))
                  netcdf.putVar(fCdf, scientificCalibDateVarId, ...
                     fliplr([profPos id-1 idPosParam-1 0]), fliplr([1 1 1 length(value)]), value');
               end
            end
         end

         netcdf.close(fCdf);

         if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_applyRtqc == 1))
            % store information for the XML report
            g_decArgo_reportStruct.outputMonoProfFiles = [g_decArgo_reportStruct.outputMonoProfFiles ...
               {ncPathFileName}];
         end
      end
   end
end

fprintf('... NetCDF MONO-PROFILE c files created\n');

% process Auxiliary profiles
if (~isempty(a_tabAuxProfiles))
   create_nc_mono_prof_aux_files( ...
      a_decoderId, a_tabAuxProfiles, a_metaDataFromJson, generatedProfList);
end

o_cFileInfo = generatedProfList;

return
