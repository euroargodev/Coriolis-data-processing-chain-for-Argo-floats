% ------------------------------------------------------------------------------
% Retrieve SCIENTIFIC_CALIB_* data from NetCDF file to CSV file for manual
% search of inconsistencies.
%
% SYNTAX :
%   nc_get_scientific_calib_information
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
%   09/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_scientific_calib_information

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\201809-ArgoData\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_scientific_calib_information_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% output CSV file header
fileNum = 1;
header1 = ['DAC; WMO; FILE; VERSION; N_PROF; N_CALIB; N_PARAM; PROF#; CALIB#; PARAM#'];
header2 = [];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   data = [];
   dacDirName = dacDir(idDir).name;
   
   if (~strcmp(dacDirName, 'coriolis'))
      continue;
   end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         
         %          if (~strcmp(floatDirName, '6900870'))
         %             continue;
         %          end
         
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatProfDirPathName = [dacDirPathName '/' floatDirName '/profiles/'];
            
            if (exist(floatProfDirPathName, 'dir') == 7)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               profDir = dir(floatProfDirPathName);
               for idFProf = 1:length(profDir)
                  
                  profFileName = profDir(idFProf).name;
                  %                   if (strcmp(profFileName, 'D6900870_001.nc'))
                  %                      a=1
                  %                   end
                  
                  if (profFileName(1) == 'M')
                     continue;
                  end
                  profFilePathName = [floatProfDirPathName '/' profFileName];
                  if (exist(profFilePathName, 'file') == 2)
                     
                     % retrieve information from profile file
                     wantedInputVars = [ ...
                        {'FORMAT_VERSION'} ...
                        {'PARAMETER'} ...
                        {'SCIENTIFIC_CALIB_EQUATION'} ...
                        {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
                        {'SCIENTIFIC_CALIB_COMMENT'} ...
                        {'SCIENTIFIC_CALIB_DATE'} ...
                        {'CALIBRATION_DATE'} ...
                        ];
                     [profData] = get_data_from_nc_file(profFilePathName, wantedInputVars);
                     
                     formatVersion = strtrim(get_data_from_name('FORMAT_VERSION', profData)');
                     sciCalibParameter = get_data_from_name('PARAMETER', profData);
                     sciCalibParameter = permute(sciCalibParameter, ndims(sciCalibParameter):-1:1);
                     sciCalibEquation = get_data_from_name('SCIENTIFIC_CALIB_EQUATION', profData);
                     sciCalibEquation = permute(sciCalibEquation, ndims(sciCalibEquation):-1:1);
                     sciCalibCoefficient = get_data_from_name('SCIENTIFIC_CALIB_COEFFICIENT', profData);
                     sciCalibCoefficient = permute(sciCalibCoefficient, ndims(sciCalibCoefficient):-1:1);
                     sciCalibComment = get_data_from_name('SCIENTIFIC_CALIB_COMMENT', profData);
                     sciCalibComment = permute(sciCalibComment, ndims(sciCalibComment):-1:1);
                     if (strcmp(formatVersion, '2.2'))
                        sciCalibDate = get_data_from_name('CALIBRATION_DATE', profData);
                     else
                        sciCalibDate = get_data_from_name('SCIENTIFIC_CALIB_DATE', profData);
                     end
                     sciCalibDate = permute(sciCalibDate, ndims(sciCalibDate):-1:1);
                     
                     if (ndims(sciCalibParameter) == 4)
                        nProf = size(sciCalibParameter, 1);
                        nCalib = size(sciCalibParameter, 2);
                        nParam = size(sciCalibParameter, 3);
                     elseif (ndims(sciCalibParameter) == 3)
                        nProf = 1;
                        nCalib = size(sciCalibParameter, 1);
                        nParam = size(sciCalibParameter, 2);
                     elseif (ndims(sciCalibParameter) == 2)
                        nProf = 1;
                        nCalib = 1;
                        nParam = size(sciCalibParameter, 1);
                     else
                        nProf = 1;
                        nCalib = 1;
                        nParam = 1;
                     end
                     
                     for idProf = 1:nProf
                        for idCalib = 1:nCalib
                           for idParam = 1:nParam
                              if (ndims(sciCalibParameter) == 4)
                                 param = strtrim(squeeze(sciCalibParameter(idProf, idCalib, idParam, :))');
                                 eq = strtrim(squeeze(sciCalibEquation(idProf, idCalib, idParam, :))');
                                 coe = strtrim(squeeze(sciCalibCoefficient(idProf, idCalib, idParam, :))');
                                 com = strtrim(squeeze(sciCalibComment(idProf, idCalib, idParam, :))');
                                 dat = strtrim(squeeze(sciCalibDate(idProf, idCalib, idParam, :))');
                              elseif (ndims(sciCalibParameter) == 3)
                                 param = strtrim(squeeze(sciCalibParameter(idCalib, idParam, :))');
                                 eq = strtrim(squeeze(sciCalibEquation(idCalib, idParam, :))');
                                 coe = strtrim(squeeze(sciCalibCoefficient(idCalib, idParam, :))');
                                 com = strtrim(squeeze(sciCalibComment(idCalib, idParam, :))');
                                 dat = strtrim(squeeze(sciCalibDate(idCalib, idParam, :))');
                              else
                                 param = strtrim(squeeze(sciCalibParameter(idParam, :)));
                                 eq = strtrim(squeeze(sciCalibEquation(idParam, :)));
                                 coe = strtrim(squeeze(sciCalibCoefficient(idParam, :)));
                                 com = strtrim(squeeze(sciCalibComment(idParam, :)));
                                 dat = strtrim(squeeze(sciCalibDate(idParam, :)));
                              end
                              if (~isempty(eq))
                                 newData = [];
                                 newData.DAC = dacDirName;
                                 newData.WMO = floatDirName;
                                 newData.FILE = profFileName;
                                 newData.VERSION = formatVersion;
                                 newData.N_PROF = nProf;
                                 newData.N_CALIB = nCalib;
                                 newData.N_PARAM = nParam;
                                 newData.PROF = idProf;
                                 newData.CALIB = idCalib;
                                 newData.PARAM = idParam;
                                 newData.LABEL = ([param '_EQUATION']);
                                 newData.VALUE = eq;
                                 data = [data newData];
                              end
                              if (~isempty(coe))
                                 newData = [];
                                 newData.DAC = dacDirName;
                                 newData.WMO = floatDirName;
                                 newData.FILE = profFileName;
                                 newData.VERSION = formatVersion;
                                 newData.N_PROF = nProf;
                                 newData.N_CALIB = nCalib;
                                 newData.N_PARAM = nParam;
                                 newData.PROF = idProf;
                                 newData.CALIB = idCalib;
                                 newData.PARAM = idParam;
                                 newData.LABEL = ([param '_COEFFICIENT']);
                                 newData.VALUE = coe;
                                 data = [data newData];
                              end
                              if (~isempty(com))
                                 newData = [];
                                 newData.DAC = dacDirName;
                                 newData.WMO = floatDirName;
                                 newData.FILE = profFileName;
                                 newData.VERSION = formatVersion;
                                 newData.N_PROF = nProf;
                                 newData.N_CALIB = nCalib;
                                 newData.N_PARAM = nParam;
                                 newData.PROF = idProf;
                                 newData.CALIB = idCalib;
                                 newData.PARAM = idParam;
                                 newData.LABEL = ([param '_COMMENT']);
                                 newData.VALUE = com;
                                 data = [data newData];
                              end
                              if (~isempty(dat))
                                 newData = [];
                                 newData.DAC = dacDirName;
                                 newData.WMO = floatDirName;
                                 newData.FILE = profFileName;
                                 newData.VERSION = formatVersion;
                                 newData.N_PROF = nProf;
                                 newData.N_CALIB = nCalib;
                                 newData.N_PARAM = nParam;
                                 newData.PROF = idProf;
                                 newData.CALIB = idCalib;
                                 newData.PARAM = idParam;
                                 newData.LABEL = ([param '_DATE']);
                                 newData.VALUE = dat;
                                 data = [data newData];
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
         
         if (length(data) > 100000)
            
            header2 = unique({data.LABEL}, 'stable');
            
            % create the CSV output file
            outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_scientific_calib_information_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '_' num2str(fileNum) '.csv']
            fidOut = fopen(outputFileName, 'wt');
            if (fidOut == -1)
               return;
            end
            fprintf(fidOut, '%s ', header1);
            fprintf(fidOut, ';%s ', header2{:});
            fprintf(fidOut, '\n');
            
            for id = 1:length(data)
               dataStruct = data(id);
               idF = find(strcmp(dataStruct.LABEL, header2));
               compStr = repmat(' ;', 1, idF-1);
               
               fprintf(fidOut, '%s; %s; %s; %s; %d; %d; %d; %d; %d; %d; %s "%s"\n', ...
                  dataStruct.DAC, ...
                  dataStruct.WMO, ...
                  dataStruct.FILE, ...
                  dataStruct.VERSION, ...
                  dataStruct.N_PROF, ...
                  dataStruct.N_CALIB, ...
                  dataStruct.N_PARAM, ...
                  dataStruct.PROF, ...
                  dataStruct.CALIB, ...
                  dataStruct.PARAM, ...
                  compStr, ...
                  dataStruct.VALUE);
            end
            
            fclose(fidOut);
            
            fileNum = fileNum + 1;
            clear data;
            data = [];
            
         end
      end
      
      if (~isempty(data))
         
         header2 = unique({data.LABEL}, 'stable');
         
         % create the CSV output file
         outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_scientific_calib_information_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '_' num2str(fileNum) '.csv']
         fidOut = fopen(outputFileName, 'wt');
         if (fidOut == -1)
            return;
         end
         fprintf(fidOut, '%s ', header1);
         fprintf(fidOut, ';%s ', header2{:});
         fprintf(fidOut, '\n');
         
         for id = 1:length(data)
            dataStruct = data(id);
            idF = find(strcmp(dataStruct.LABEL, header2));
            compStr = repmat(' ;', 1, idF-1);
            
            fprintf(fidOut, '%s; %s; %s; %s; %d; %d; %d; %d; %d; %d; %s "%s"\n', ...
               dataStruct.DAC, ...
               dataStruct.WMO, ...
               dataStruct.FILE, ...
               dataStruct.VERSION, ...
               dataStruct.N_PROF, ...
               dataStruct.N_CALIB, ...
               dataStruct.N_PARAM, ...
               dataStruct.PROF, ...
               dataStruct.CALIB, ...
               dataStruct.PARAM, ...
               compStr, ...
               dataStruct.VALUE);
         end
         
         fclose(fidOut);
      end
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

return;

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
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return;
