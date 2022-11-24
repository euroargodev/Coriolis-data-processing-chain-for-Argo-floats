% ------------------------------------------------------------------------------
% Retrieve SCIENTIFIC_CALIB_* data from NetCDF file to CSV file for manual
% search of inconsistencies.
%
% SYNTAX :
%   nc_get_scientific_calib_information_ter(varargin)
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
%   18/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_get_scientific_calib_information_ter(varargin)

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\201809-ArgoData\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% list of WMO floats to process (if empty, all floats are processed)
FLOATS_LIST = '';
FLOATS_LIST = 'C:\Users\jprannou\_RNU\Argo\ActionsCoriolis\Check_Snapshot_201809\SCIENTIFIC_CALIB\RUN2\erroneous_floats.txt';


floatList = [];
if (nargin == 0)
   if (~isempty(FLOATS_LIST))
      % floats to process come from FLOATS_LIST
      if ~(exist(FLOATS_LIST, 'file') == 2)
         fprintf('File not found: %s\n', FLOATS_LIST);
         return
      end
      
      fprintf('Floats from list: %s\n', FLOATS_LIST);
      floatList = load(FLOATS_LIST);
   end
else
   % floats to process come from input parameters
   floatList = cell2mat(varargin);
end

logFile = [DIR_LOG_CSV_FILE '/' 'nc_get_scientific_calib_information_ter_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% arrays to collect data
MAX_REC = 500000;
newData = [];
newData.DAC = '';
newData.WMO = '';
newData.FILE = '';
newData.PI = '';
newData.VERSION = '';
newData.N_PROF = '';
newData.N_CALIB = '';
newData.N_PARAM = '';
newData.ID_PROF = '';
newData.ID_CALIB = '';
newData.ID_PARAM = '';
newData.PARAM_BAD_FILL_VALUE = 0;
newData.PARAM_EMPTY = 0;
newData.PARAM = '';
newData.EQ = '';
newData.COE = '';
newData.COM = '';
newData.DAT = '';
data = repmat(newData, 2*MAX_REC, 1);
cpt = 0;

% output CSV file header
fileNum = 1;
header1 = ['DAC; WMO; FILE; PI NAME; VERSION; N_PROF; N_CALIB; N_PARAM; PROF#; CALIB#; PARAM_BAD_FILL_VALUE; PARAM_EMPTY'];
header2 = [];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   
   if (~strcmp(dacDirName, 'coriolis'))
      continue
   end
   
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         %       for idDir2 = 1:10
         
         floatDirName = floatDir(idDir2).name;
         if (~isempty(floatList))
            if (~ismember(str2double(floatDirName), floatList))
               continue
            end
         end
         
%          if (~strcmp(floatDirName, '1900379'))
%             continue
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
                     continue
                  end
                  profFilePathName = [floatProfDirPathName '/' profFileName];
                  if (exist(profFilePathName, 'file') == 2)
                     
                     % retrieve information from profile file
                     wantedInputVars = [ ...
                        {'PI_NAME'} ...
                        {'FORMAT_VERSION'} ...
                        {'PARAMETER'} ...
                        {'SCIENTIFIC_CALIB_EQUATION'} ...
                        {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
                        {'SCIENTIFIC_CALIB_COMMENT'} ...
                        {'SCIENTIFIC_CALIB_DATE'} ...
                        {'CALIBRATION_DATE'} ...
                        ];
                     [profData] = get_data_from_nc_file(profFilePathName, wantedInputVars);
                     
                     piName = get_data_from_name('PI_NAME', profData)';
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
                              if (~isempty(eq) || ~isempty(coe) || ~isempty(com) || ~isempty(dat))
                                 cpt = cpt + 1;
                                 data(cpt).DAC = dacDirName;
                                 data(cpt).WMO = floatDirName;
                                 data(cpt).FILE = profFileName;
                                 data(cpt).PI = strtrim(piName(idProf, :));
                                 data(cpt).VERSION = formatVersion;
                                 data(cpt).N_PROF = nProf;
                                 data(cpt).N_CALIB = nCalib;
                                 data(cpt).N_PARAM = nParam;
                                 data(cpt).ID_PROF = idProf;
                                 data(cpt).ID_CALIB = idCalib;
                                 data(cpt).ID_PARAM = idParam;
                                 if (any(param == 0))
                                    param(find(param == 0)) = [];
                                    data(cpt).PARAM_BAD_FILL_VALUE = 1;
                                 end
                                 if (isempty(param))
                                    param = ['EMPTY_PROF_ID_' num2str(idProf) '_PARAM_ID_' num2str(idParam)];
                                    data(cpt).PARAM_EMPTY = 1;
                                 end
                                 data(cpt).PARAM = param;
                                 data(cpt).EQ = eq;
                                 data(cpt).COE = coe;
                                 data(cpt).COM = com;
                                 data(cpt).DAT = dat;
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
         
         if (cpt > MAX_REC)
            
            cptList = 1:cpt;
            paramList = unique({data(cptList).PARAM});
            header2 = [];
            for id = 1:length(paramList)
               header2{end+1} = [paramList{id} '_EQUATION'];
               header2{end+1} = [paramList{id} '_COEFFICIENT'];
               header2{end+1} = [paramList{id} '_COMMENT'];
               header2{end+1} = [paramList{id} '_DATE'];
            end
            
            % create the CSV output file
            outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_scientific_calib_information_ter_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '_' num2str(fileNum) '.csv'];
            fidOut = fopen(outputFileName, 'wt');
            if (fidOut == -1)
               return
            end
            fprintf(fidOut, '%s ', header1);
            fprintf(fidOut, ';%s ', header2{:});
            fprintf(fidOut, '\n');
            
            dacList = {data(cptList).DAC};
            wmoList = {data(cptList).WMO};
            fileList = {data(cptList).FILE};
            profIdList = [data(cptList).ID_PROF];
            calibIdList = [data(cptList).ID_CALIB];
            
            uDacList = unique(dacList);
            for idDac = 1:length(uDacList)
               itemList1 = find(strcmp(dacList, uDacList{idDac}));
               uWmoList = unique(wmoList(itemList1));
               for idWmo = 1:length(uWmoList)
                  itemList2 = itemList1(find(strcmp(wmoList(itemList1), uWmoList{idWmo})));
                  uFileList = unique(fileList(itemList2));
                  for idFile = 1:length(uFileList)
                     itemList3 = itemList2(find(strcmp(fileList(itemList2), uFileList{idFile})));
                     uProfIdList = unique(profIdList(itemList3));
                     for idProf = 1:length(uProfIdList)
                        itemList4 = itemList3(find(profIdList(itemList3) == uProfIdList(idProf)));
                        uCalibIdList = unique(calibIdList(itemList4));
                        for idCal = 1:length(uCalibIdList)
                           itemList5 = itemList4(find(calibIdList(itemList4) == uCalibIdList(idCal)));
                           
                           dataStruct = data(cptList(itemList5(1)));
                           fprintf(fidOut, '%s;%s;%s;%s;%s;%d;%d;%d;%d;%d', ...
                              dataStruct.DAC, ...
                              dataStruct.WMO, ...
                              dataStruct.FILE, ...
                              dataStruct.PI, ...
                              dataStruct.VERSION, ...
                              dataStruct.N_PROF, ...
                              dataStruct.N_CALIB, ...
                              dataStruct.N_PARAM, ...
                              dataStruct.ID_PROF, ...
                              dataStruct.ID_CALIB);
                           
                           if (any([data(cptList(itemList5)).PARAM_BAD_FILL_VALUE] == 1))
                              fprintf(fidOut, ';1');
                           else
                              fprintf(fidOut, ';0');
                           end
                           
                           if (any([data(cptList(itemList5)).PARAM_EMPTY] == 1))
                              fprintf(fidOut, ';1');
                           else
                              fprintf(fidOut, ';0');
                           end
                           
                           idColPrev = 0;
                           profParam = {data(cptList(itemList5)).PARAM};
                           uProfParam = unique(profParam);
                           for idParam = 1:length(uProfParam)
                              idF = find(strcmp(uProfParam{idParam}, paramList), 1);
                              compStr = repmat(';', 1, (idF-idColPrev-1)*4);
                              if (~isempty(compStr))
                                 %                                  fprintf('SHIFT\n');
                              end
                              
                              idColPrev = idF;
                              fprintf(fidOut, '%s', compStr);
                              
                              idF = find(strcmp(uProfParam{idParam}, profParam));
                              if (length(idF) ~= 1)
                                 fprintf('ERROR: float %s\n', dataStruct.WMO);
                              end
                              fprintf(fidOut, ';"%s";"%s";"%s";"%s"', ...
                                 data(cptList(itemList5(idF))).EQ, ...
                                 data(cptList(itemList5(idF))).COE, ...
                                 data(cptList(itemList5(idF))).COM, ...
                                 data(cptList(itemList5(idF))).DAT ...
                                 );
                           end
                           fprintf(fidOut, '\n');
                        end
                     end
                  end
               end
            end
            fclose(fidOut);
            
            fileNum = fileNum + 1;
            cpt = 0;
         end
      end
      
      if (~isempty(data))
         
         cptList = 1:cpt;
         paramList = unique({data(cptList).PARAM});
         header2 = [];
         for id = 1:length(paramList)
            header2{end+1} = [paramList{id} '_EQUATION'];
            header2{end+1} = [paramList{id} '_COEFFICIENT'];
            header2{end+1} = [paramList{id} '_COMMENT'];
            header2{end+1} = [paramList{id} '_DATE'];
         end
         
         % create the CSV output file
         outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_get_scientific_calib_information_ter_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '_' num2str(fileNum) '.csv']
         fidOut = fopen(outputFileName, 'wt');
         if (fidOut == -1)
            return
         end
         fprintf(fidOut, '%s ', header1);
         fprintf(fidOut, ';%s ', header2{:});
         fprintf(fidOut, '\n');
         
         dacList = {data(cptList).DAC};
         wmoList = {data(cptList).WMO};
         fileList = {data(cptList).FILE};
         profIdList = [data(cptList).ID_PROF];
         calibIdList = [data(cptList).ID_CALIB];
         
         uDacList = unique(dacList);
         for idDac = 1:length(uDacList)
            itemList1 = find(strcmp(dacList, uDacList{idDac}));
            uWmoList = unique(wmoList(itemList1));
            for idWmo = 1:length(uWmoList)
               itemList2 = itemList1(find(strcmp(wmoList(itemList1), uWmoList{idWmo})));
               uFileList = unique(fileList(itemList2));
               for idFile = 1:length(uFileList)
                  itemList3 = itemList2(find(strcmp(fileList(itemList2), uFileList{idFile})));
                  uProfIdList = unique(profIdList(itemList3));
                  for idProf = 1:length(uProfIdList)
                     itemList4 = itemList3(find(profIdList(itemList3) == uProfIdList(idProf)));
                     uCalibIdList = unique(calibIdList(itemList4));
                     for idCal = 1:length(uCalibIdList)
                        itemList5 = itemList4(find(calibIdList(itemList4) == uCalibIdList(idCal)));
                        
                        dataStruct = data(cptList(itemList5(1)));
                        fprintf(fidOut, '%s;%s;%s;%s;%s;%d;%d;%d;%d;%d', ...
                           dataStruct.DAC, ...
                           dataStruct.WMO, ...
                           dataStruct.FILE, ...
                           dataStruct.PI, ...
                           dataStruct.VERSION, ...
                           dataStruct.N_PROF, ...
                           dataStruct.N_CALIB, ...
                           dataStruct.N_PARAM, ...
                           dataStruct.ID_PROF, ...
                           dataStruct.ID_CALIB);
                        
                        if (any([data(cptList(itemList5)).PARAM_BAD_FILL_VALUE] == 1))
                           fprintf(fidOut, ';1');
                        else
                           fprintf(fidOut, ';0');
                        end
                        
                        if (any([data(cptList(itemList5)).PARAM_EMPTY] == 1))
                           fprintf(fidOut, ';1');
                        else
                           fprintf(fidOut, ';0');
                        end
                        
                        idColPrev = 0;
                        profParam = {data(cptList(itemList5)).PARAM};
                        uProfParam = unique(profParam);
                        for idParam = 1:length(uProfParam)
                           idF = find(strcmp(uProfParam{idParam}, paramList), 1);
                           compStr = repmat(';', 1, (idF-idColPrev-1)*4);
                           if (~isempty(compStr))
                              %                                  fprintf('SHIFT\n');
                           end
                           
                           idColPrev = idF;
                           fprintf(fidOut, '%s', compStr);
                           
                           idF = find(strcmp(uProfParam{idParam}, profParam));
                           if (length(idF) ~= 1)
                              fprintf('ERROR: float %s\n', dataStruct.WMO);
                           end
                           fprintf(fidOut, ';"%s";"%s";"%s";"%s"', ...
                              data(cptList(itemList5(idF))).EQ, ...
                              data(cptList(itemList5(idF))).COE, ...
                              data(cptList(itemList5(idF))).COM, ...
                              data(cptList(itemList5(idF))).DAT ...
                              );
                        end
                        fprintf(fidOut, '\n');
                     end
                  end
               end
            end
         end
         fclose(fidOut);
      end
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

return

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

return
