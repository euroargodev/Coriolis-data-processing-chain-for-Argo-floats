% ------------------------------------------------------------------------------
% Check TECH label names and retrieve not allowed ones.
%
% SYNTAX :
%   nc_collect_not_allowed_tech_labels
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
%   02/19/2016 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_not_allowed_tech_labels(varargin)

% top directory of input NetCDF tech files
DIR_INPUT_NC_FILES = 'E:\archive_201602\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_update_format_tech\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% list of allowed labels
ALLOWED_TECH_LABEL_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_tech_labels_V7_1_20160202.xlsx';  
ALLOWED_SENSOR_LABEL_BIO_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_sensor_names_for_tech.xlsx';
ALLOWED_UNITS_LABEL_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_tech_conf_units_V2_1.xlsx';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_not_allowed_tech_labels_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% read the list of allowed names
[~, sensorLabelBio, ~] = xlsread(ALLOWED_SENSOR_LABEL_BIO_FILE);
[~, units, ~] = xlsread(ALLOWED_UNITS_LABEL_FILE);

% process the list of allowed conf labels
[~, labels, ~] = xlsread(ALLOWED_TECH_LABEL_FILE);
labelList = [];
templateList = [{'<Sensor>'} {'<int>'} {'<digit>'} {'<Z>'}];
for id = 1:length(labels)
   label = strtrim(labels{id});
   idF = strfind(label, '_');
   %    fprintf('%s\n', label(idF(end)+1:end));
   label = label(1:idF(end)-1);
   fprintf('%s => ', label);
   
   % replace the templates of each label
   tmpLabelListIn = {label};
   tmpLabelListOut = [];
   stop = 0;
   while (~stop)
      nbOk = 0;
      for idL = 1:length(tmpLabelListIn)
         tmpLabel = tmpLabelListIn{idL};
         if (any(strfind(tmpLabel, '<')))
            idFStart = strfind(tmpLabel, '<');
            idFEnd = strfind(tmpLabel, '>');
            template = tmpLabel(idFStart:idFEnd);
            if (~ismember(template, templateList))
               fprintf('ERROR: template ''%s'' is not in the referenced list - aborted\n', template);
               return
            end
            templateId = find(strcmp(template, templateList));
            tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, '');
            switch templateId
               case 1
                  for idT = 1:length(sensorLabelBio)
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, strtrim(sensorLabelBio{idT}));
                  end
               case 2
                  for idT = 1:10
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, num2str(idT));
                  end
               case 3
                  for idT = 1:5
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, num2str(idT));
                  end
               case 4
                  for idT = 1:5
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, num2str(idT));
                  end
            end
         else
            tmpLabelListOut{end+1} = tmpLabel;
            nbOk = nbOk + 1;
         end
      end
      if (nbOk == length(tmpLabelListIn))
         stop = 1;
      else
         tmpLabelListIn = tmpLabelListOut;
         tmpLabelListOut = [];
      end
   end
   fprintf('%d label(s)\n', length(tmpLabelListOut));
   labelList = [labelList tmpLabelListOut];
end

% for idL = 1:length(labelList)
%    fprintf('%s\n', labelList{idL});
% end

% add the units to the labels
labelListAll = [];
for idL = 1:length(labelList)
   for idU = 1:length(units)
      labelListAll{end+1} = [labelList{idL} '_' units{idU}];
   end
end
fprintf('Nb labels: %d\n', length(labelList));
fprintf('Nb labels with units: %d\n', length(labelListAll));

% output CSV file header
header = ['File; PLATFORM_NUMBER; FORMAT_VERSION; DATA_CENTRE; TECHNICAL_PARAMETER_NAME'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   %    if (~strcmp(dacDirName, 'jma') && ~strcmp(dacDirName, 'kma') && ...
   %          ~strcmp(dacDirName, 'kordi') && ~strcmp(dacDirName, 'meds') && ...
   %          ~strcmp(dacDirName, 'nmdis'))
   if (~strcmp(dacDirName, 'coriolis'))
      continue
   end
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_not_allowed_tech_labels_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         %          if (str2num(floatDirName) ~= 2901029)
         %             continue
         %          end
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatTechFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_tech.nc'];
            
            if (exist(floatTechFilePathName, 'file') == 2)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from technical file
               wantedInputVars = [ ...
                  {'PLATFORM_NUMBER'} ...
                  {'FORMAT_VERSION'} ...
                  {'DATA_CENTRE'} ...
                  {'TECHNICAL_PARAMETER_NAME'} ...
                  ];
               [techData] = get_data_from_nc_file(floatTechFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', techData(1:2:end)) == 1, 1);
               formatVersion = techData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('PLATFORM_NUMBER', techData(1:2:end)) == 1, 1);
               platformNumber = techData{2*idVal}';
               idVal = find(strcmp('DATA_CENTRE', techData(1:2:end)) == 1, 1);
               dataCentre = techData{2*idVal}';
               idVal = find(strcmp('TECHNICAL_PARAMETER_NAME', techData(1:2:end)) == 1, 1);
               techParamNameList = unique(cellstr(techData{2*idVal}'));
               
               % create the TECH label list for this file
               labelList = [];
               for id = 1:length(techParamNameList)
                  label = techParamNameList{id};
                  if (isempty(strtrim(label)))
                     fprintf('ERROR: empty label detected - label ignored\n');
                     continue
                  end
                  labelList{end+1} = label;
               end
               labelList = unique(labelList);
               
               % output not allowed ones
               if (~isempty(labelList))
                  koList = setdiff(labelList, labelListAll);
                  for id = 1:length(koList)
                     label = koList{id};
                     fprintf(fidOut, '%s; %s; %s; %s; %s\n', ...
                        [floatDirName '_tech.nc'], ...
                        strtrim(platformNumber), strtrim(formatVersion), strtrim(dataCentre), label);
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
