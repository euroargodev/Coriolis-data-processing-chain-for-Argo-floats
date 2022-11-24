% ------------------------------------------------------------------------------
% Retrieve float cycle that must be reprocessed with the '014g' decoder version.
%
% SYNTAX :
%   nc_get_cycle_to_reprocess_with_patch_014g
%
% INPUT PARAMETERS :
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/04/2017 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_cycle_to_reprocess_with_patch_014g

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\TEMP\';
% DIR_INPUT_NC_FILES = 'H:\archive_201709\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_cycle_to_reprocess_with_patch_014g_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;


% output CSV file header
header = ['DAC; WMO; CyNum; TECH; TRAJ; PROF'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   
   %    if (~strcmp(dacDirName, 'jma') && ~strcmp(dacDirName, 'kma') && ...
   %          ~strcmp(dacDirName, 'kordi') && ~strcmp(dacDirName, 'meds') && ...
   %          ~strcmp(dacDirName, 'nmdis'))
   %    if (~strcmp(dacDirName, 'coriolis'))
   %       continue
   %    end
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_cycle_to_reprocess_with_patch_014g_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);

            floatTechFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_tech.nc'];
            
            cyNumListTech = [];
            if (exist(floatTechFilePathName, 'file') == 2)
                              
               % retrieve information from technical file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'TECHNICAL_PARAMETER_NAME'} ...
                  {'TECHNICAL_PARAMETER_VALUE'} ...
                  {'CYCLE_NUMBER'} ...
                  ];
               [techData] = get_data_from_nc_file(floatTechFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', techData(1:2:end)) == 1, 1);
               formatVersion = techData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData(1:2:end)) == 1, 1);
               techParamNameList = cellstr(techData{2*idVal}');
               idVal = find(strcmp('TECHNICAL_PARAMETER_VALUE', techData(1:2:end)) == 1, 1);
               techParamValueList = cellstr(techData{2*idVal}');
               idVal = find(strcmp('CYCLE_NUMBER', techData(1:2:end)) == 1, 1);
               cycleNumber = techData{2*idVal};
               
               idF = find(strcmp('PRES_LastAscentPumpedRawSample_dbar', techParamNameList));
               for id = 1:length(idF)
                  if (str2num(techParamValueList{idF(id)}) == 0)
                     cyNumListTech = [cyNumListTech cycleNumber(idF(id))];
                  end
               end
            end
            
            floatTrajFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_Rtraj.nc'];
            
            cyNumListTraj = [];
            if (exist(floatTrajFilePathName, 'file') == 2)
                              
               % retrieve information from trajectory file
               wantedInputVars = [ ...
                  {'FORMAT_VERSION'} ...
                  {'CYCLE_NUMBER'} ...
                  {'MEASUREMENT_CODE'} ...
                  {'PRES'} ...
                  {'TEMP'} ...
                  {'PSAL'} ...
                  ];
               [trajData] = get_data_from_nc_file(floatTrajFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', trajData(1:2:end)) == 1, 1);
               formatVersion = trajData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('CYCLE_NUMBER', trajData(1:2:end)) == 1, 1);
               cycleNumber = trajData{2*idVal};
               idVal = find(strcmp('MEASUREMENT_CODE', trajData(1:2:end)) == 1, 1);
               measCode = trajData{2*idVal};
               idVal = find(strcmp('PRES', trajData(1:2:end)) == 1, 1);
               pres = trajData{2*idVal};
               idVal = find(strcmp('TEMP', trajData(1:2:end)) == 1, 1);
               temp = trajData{2*idVal};
               idVal = find(strcmp('PSAL', trajData(1:2:end)) == 1, 1);
               psal = trajData{2*idVal};
               
               idF = find(measCode == 599);
               for id = 1:length(idF)
                  if ~any([pres(idF(id)) temp(idF(id)) psal(idF(id))] ~= 0)
                     cyNumListTraj = [cyNumListTraj cycleNumber(idF(id))];
                  end
               end
            end
            
            cyNumList = unique([cyNumListTraj cyNumListTech]);
            for idCy = 1:length(cyNumList)
               techFileName = [];
               trajFileName = [];
               profFileNames = [];
               if (ismember(cyNumList(idCy), cyNumListTech))
                  techFileName = [floatDirName '_tech.nc'];
               end
               if (ismember(cyNumList(idCy), cyNumListTraj))
                  trajFileName = [floatDirName '_Rtraj.nc'];
               end
               
               floatProfFiles = dir([dacDirPathName '/' floatDirName '/profiles/' sprintf('R%s_%03d.nc', floatDirName, cyNumList(idCy))]);
               for idFile = 1:length(floatProfFiles)
                  profFileNames = [profFileNames '/' floatProfFiles(idFile).name];
               end
               floatProfFiles = dir([dacDirPathName '/' floatDirName '/profiles/' sprintf('D%s_%03d.nc', floatDirName, cyNumList(idCy))]);
               for idFile = 1:length(floatProfFiles)
                  profFileNames = [profFileNames '/' floatProfFiles(idFile).name];
               end
               
               if (~isempty(profFileNames))
                  fprintf(fidOut, '%s;%s;%d;%s;%s;%s\n', dacDirName, floatDirName, cyNumList(idCy), techFileName, trajFileName, profFileNames(2:end));
               else
                  fprintf(fidOut, '%s;%s;%d;%s;%s\n', dacDirName, floatDirName, cyNumList(idCy), techFileName, trajFileName);
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
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end
