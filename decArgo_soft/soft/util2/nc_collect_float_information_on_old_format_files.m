% % ------------------------------------------------------------------------------
% % Retrieve information from META and TRAJ files of an Argo monthly snapshot.
% %
% % SYNTAX :
% %   nc_collect_float_information_on_old_format_files
% %
% % INPUT PARAMETERS :
% %
% % OUTPUT PARAMETERS :
% %
% % EXAMPLES :
% %
% % SEE ALSO :
% % AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% % ------------------------------------------------------------------------------
% % RELEASES :
% %   03/06/2017 - RNU - creation
% % ------------------------------------------------------------------------------
function nc_collect_float_information_on_old_format_files(varargin)

% top directory of input NetCDF mono-profile files
DIR_INPUT_NC_FILES = 'H:\archive_201708\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_float_information_on_old_format_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

header = ['DAC; WMO; FILE; PROF_FORMAT_VERSION; META_FORMAT_VERSION; PLATFORM_TYPE; PLATFORM_MODEL; TRANS_SYSTEM; FIRMWARE_VERSION; DAC_FORMAT_ID; PI_NAME; DATA_MODE; INST_REFERENCE'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   
   % use the following lines to select/exclude DACs to be processed
   %    if (strcmp(dacDirName, 'doc') || ...
   %          strcmp(dacDirName, 'aoml'))
   %       continue;
   %    end
   if (strcmp(dacDirName, 'doc'))
      continue;
   end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_float_information_on_old_format_files_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return;
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         %       for idDir2 = 1:100
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            % META file
            
            floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
            
            if (exist(floatMetaFilePathName, 'file') == 2)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'PLATFORM_TYPE'} ...
                  {'PLATFORM_MODEL'} ...
                  {'TRANS_SYSTEM'} ...
                  {'FIRMWARE_VERSION'} ...
                  {'DAC_FORMAT_ID'} ...
                  {'PI_NAME'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
               formatVersionMeta = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_TYPE', metaData(1:2:end)) == 1, 1);
               platformType = metaData{2*idVal};
               idVal = find(strcmp('PLATFORM_MODEL', metaData(1:2:end)) == 1, 1);
               platformModel = metaData{2*idVal};
               idVal = find(strcmp('TRANS_SYSTEM', metaData(1:2:end)) == 1, 1);
               transSystem = metaData{2*idVal};
               idVal = find(strcmp('FIRMWARE_VERSION', metaData(1:2:end)) == 1, 1);
               firmwareVersion = metaData{2*idVal};
               idVal = find(strcmp('DAC_FORMAT_ID', metaData(1:2:end)) == 1, 1);
               dacFormatId = metaData{2*idVal};
               idVal = find(strcmp('PI_NAME', metaData(1:2:end)) == 1, 1);
               piName = metaData{2*idVal};
               %                if (str2double(formatVersionMeta) ~= 3.1)
               %                   fprintf(fidOut1, '%s; %s; %s; %s; %s; %s; %s; %s; %s\n', ...
               %                      strtrim(dacDirName), strtrim(floatDirName), ...
               %                      strtrim(formatVersionMeta'), strtrim(platformType'), strtrim(platformModel'), strtrim(transSystem'), strtrim(firmwareVersion'),...
               %                      strtrim(dacFormatId'), strtrim(piName'));
               %                end
            end
            
            % PROFILE file
            files = dir([dacDirPathName '/' floatDirName '/profiles/' '*' floatDirName '*.nc']);
            for idF = 1:length(files)
               
               fileName = files(idF).name;
               floatProfFilePathName = [dacDirPathName '/' floatDirName '/profiles/' fileName];
               
               if (exist(floatProfFilePathName, 'file') == 2)
                  
                  % retrieve information from profile file
                  wantedInputVars = [ ...
                     {'FORMAT_VERSION'} ...
                     {'DATA_MODE'} ...
                     {'INST_REFERENCE'} ...
                     ];
                  [profData] = get_data_from_nc_file(floatProfFilePathName, wantedInputVars);
                  idVal = find(strcmp('FORMAT_VERSION', profData(1:2:end)) == 1, 1);
                  formatVersionProf = profData{2*idVal};
                  if (str2double(formatVersionProf) ~= 3.1)
                     idVal = find(strcmp('DATA_MODE', profData(1:2:end)) == 1, 1);
                     dataMode = profData{2*idVal};
                     idVal = find(strcmp('INST_REFERENCE', profData(1:2:end)) == 1, 1);
                     instReference = profData{2*idVal};
                     
                     fprintf(fidOut, '%s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s; %s\n', ...
                        strtrim(dacDirName), strtrim(floatDirName), fileName, ...
                        strtrim(formatVersionProf'), strtrim(formatVersionMeta'), ...
                        strtrim(platformType'), strtrim(platformModel'), strtrim(transSystem'), strtrim(firmwareVersion'),...
                        strtrim(dacFormatId'), strtrim(piName'), strtrim(dataMode'), strtrim(instReference'));
                  end
               end
            end
         end
      end
      fclose(fidOut);
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return;

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
      return;
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
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

% ------------------------------------------------------------------------------
% Check if a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present_dec_argo(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present_dec_argo(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar= 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break;
   end
end

return;
