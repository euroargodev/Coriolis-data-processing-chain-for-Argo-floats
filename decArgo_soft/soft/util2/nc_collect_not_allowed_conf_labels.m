% ------------------------------------------------------------------------------
% Check CONFIG label names and retrieve not allowed ones.
%
% SYNTAX :
%   nc_collect_not_allowed_conf_labels
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
%   02/18/2016 - RNU - creation
% ------------------------------------------------------------------------------
function nc_collect_not_allowed_conf_labels(varargin)

% top directory of input NetCDF meta files
DIR_INPUT_NC_FILES = 'H:\archive_201603\';
% DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_update_format_conf\';

% directory to store the log and the csv files
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';

% list of allowed labels
ALLOWED_CONF_LABEL_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_conf_labels_20160215.xlsx';  
ALLOWED_PARAM_LABEL_BIO_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_param_names_for_bio_conf.xlsx';
ALLOWED_PARAM_LABEL_CORE_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_param_names_for_core_conf.xlsx';
ALLOWED_SENSOR_LABEL_BIO_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_sensor_names_for_bio_conf.xlsx';
ALLOWED_UNITS_LABEL_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\soft\util2\ref_lists\_allowed_tech_conf_units_V2_1.xlsx';

logFile = [DIR_LOG_CSV_FILE '/' 'nc_collect_not_allowed_conf_labels_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);
tic;

% read the list of allowed names
[~, paramLabelBio, ~] = xlsread(ALLOWED_PARAM_LABEL_BIO_FILE);
[~, paramLabelCore, ~] = xlsread(ALLOWED_PARAM_LABEL_CORE_FILE);
[~, sensorLabelBio, ~] = xlsread(ALLOWED_SENSOR_LABEL_BIO_FILE);
[~, units, ~] = xlsread(ALLOWED_UNITS_LABEL_FILE);

% process the list of allowed conf labels
[~, labels, ~] = xlsread(ALLOWED_CONF_LABEL_FILE);
labelList = [];
templateList = [{'<PARAM>'} {'<param>'} {'<sensor_short_name>'} {'<short_sensor_name>'} {'<I>'} {'<N>'} {'<N+1>'} {'<D>'} ];
for id = 1:length(labels)
   label = strtrim(labels{id});
   idF = strfind(label, '_');
   %    fprintf('%s\n', label(idF(end)+1:end));
   label = label(1:idF(end)-1);
   fprintf('%s - ', label);
   
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
            if (templateId == 7)
               idF = strfind(tmpLabel, '<N+1>');
               tmpLabel(idF:idF+length('<N+1>')-1) = '<N_1>';
               tmpLabelListOut{end+1} = regexprep(tmpLabel, '<N_1>', '');
            else
               tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, '');
            end
            switch templateId
               case 1
                  for idT = 1:length(paramLabelCore)
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, strtrim(paramLabelCore{idT}));
                  end
               case 2
                  for idT = 1:length(paramLabelBio)
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, strtrim(paramLabelBio{idT}));
                  end
               case {3, 4}
                  for idT = 1:length(sensorLabelBio)
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, strtrim(sensorLabelBio{idT}));
                  end
               case 5
                  for idT = 1:3
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, num2str(idT));
                  end
               case 6
                  for idT = 1:5
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, templateList{templateId}, num2str(idT));
                  end
               case 7
                  for idT = 2:5
                     tmpLabelListOut{end+1} = regexprep(tmpLabel, '<N_1>', num2str(idT));
                  end
               case 8
                  for idT = 0:9
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
   fprintf('%d labels\n', length(tmpLabelListOut));
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
header = ['File; PLATFORM_NUMBER; FORMAT_VERSION; DATA_CENTRE; CONFIGURATION_PARAMETER_NAME'];

dacDir = dir(DIR_INPUT_NC_FILES);
for idDir = 1:length(dacDir)
   
   dacDirName = dacDir(idDir).name;
   if (~strcmp(dacDirName, 'coriolis'))
      continue
   end
   dacDirPathName = [DIR_INPUT_NC_FILES '/' dacDirName];
   if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
      
      fprintf('\nProcessing directory: %s\n', dacDirName);
      
      % create the CSV output file
      outputFileName = [DIR_LOG_CSV_FILE '/' 'nc_collect_not_allowed_conf_labels_' dacDirName '_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fidOut = fopen(outputFileName, 'wt');
      if (fidOut == -1)
         return
      end
      fprintf(fidOut, '%s\n', header);
      
      floatDir = dir(dacDirPathName);
      for idDir2 = 1:length(floatDir)
         
         floatDirName = floatDir(idDir2).name;
         %          if (str2num(floatDirName) ~= 1900848)
         %             continue
         %          end
         floatDirPathName = [dacDirPathName '/' floatDirName];
         if (exist(floatDirPathName, 'dir') == 7)
            
            floatMetaFilePathName = [dacDirPathName '/' floatDirName '/' floatDirName '_meta.nc'];
            
            if (exist(floatMetaFilePathName, 'file') == 2)
               
               fprintf('%03d/%03d %s\n', idDir2, length(floatDir), floatDirName);
               
               % retrieve information from meta-data file
               wantedInputVars = [ ...
                  {'PLATFORM_NUMBER'} ...
                  {'FORMAT_VERSION'} ...
                  {'DATA_CENTRE'} ...
                  {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
                  {'CONFIG_PARAMETER_NAME'} ...
                  ];
               [metaData] = get_data_from_nc_file(floatMetaFilePathName, wantedInputVars);
               idVal = find(strcmp('FORMAT_VERSION', metaData(1:2:end)) == 1, 1);
               formatVersion = metaData{2*idVal}';
               if (str2num(formatVersion) ~= 3.1)
                  continue
               end
               idVal = find(strcmp('PLATFORM_NUMBER', metaData(1:2:end)) == 1, 1);
               platformNumber = metaData{2*idVal}';
               idVal = find(strcmp('DATA_CENTRE', metaData(1:2:end)) == 1, 1);
               dataCentre = metaData{2*idVal}';
               idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
               launchConfigParamNameList = unique(cellstr(metaData{2*idVal}'));
               idVal = find(strcmp('CONFIG_PARAMETER_NAME', metaData(1:2:end)) == 1, 1);
               configParamNameList = unique(cellstr(metaData{2*idVal}'));
               
               % create the CONFIG label list for this file
               labelList = [];
               for id = 1:length(launchConfigParamNameList)
                  label = launchConfigParamNameList{id};
                  if (isempty(strtrim(label)))
                     fprintf('ERROR: empty label detected - label ignored\n');
                     continue
                  end
                  labelList{end+1} = label;
               end
               for id = 1:length(configParamNameList)
                  label = configParamNameList{id};
                  if (isempty(strtrim(label)))
                     fprintf('ERROR: empty label detected - label ignored\n');
                     continue
                  end
                  labelList{end+1} = label;
               end
               labelList = unique(labelList);
               
               % output not allowed ones
               koList = setdiff(labelList, labelListAll);
               for id = 1:length(koList)
                  label = koList{id};
                  fprintf(fidOut, '%s; %s; %s; %s; %s\n', ...
                     [floatDirName '_meta.nc'], ...
                     strtrim(platformNumber), strtrim(formatVersion), strtrim(dataCentre), label);
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
