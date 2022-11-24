% ------------------------------------------------------------------------------
% Compare 2 csv files generated from a Coriolis data base export.
%
% SYNTAX :
%  compare_data_base_export()
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
%   07/21/2014 - RNU - creation
% ------------------------------------------------------------------------------
function compare_data_base_export()

% meta-data BASE file exported from Coriolis data base
baseFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150217.txt';
baseFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\1-IN_DBexport_Apex_fromVB_20160122_pourMAJ_liste_avant_bascule.txt';
baseFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\2-IN_apex_DB_export_fromVB_20160817.txt';
baseFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\3-IN_apex_DB_export_fromVB_20160817.txt';
baseFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\3-IN_APEX_102015_DBExport.txt';
baseFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\4-IN_DB_export_Apx_Ir_&_Navis.txt';
baseFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\5-IN_DB_Export_APEX_Poland.txt';

% meta-data NEW file exported from Coriolis data base
newFileName = 'C:\Users\jprannou\_RNU\DecPrv_info\_configParamNames\meta_PRV_from_VB_REFERENCE_20150507.txt';
newFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\1-OUT_export_meta_APEX_from_VB_20150703.txt';
newFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\2-OUT_apex_DB_export_fromVB_20160817_20160823.txt';
newFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\3-OUT_apex_DB_export_fromVB_20160817_20160823.txt';
newFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\3-OUT_APEX_102015_DBExport_20160920.txt';
newFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\4-OUT_DB_export_Apx_Ir_&_Navis.txt';
newFileName = 'C:\Users\jprannou\Desktop\Sensor CTD\5-OUT_DB_export_ApexSbd_from_VB_20171026.txt';

% list of concerned floats
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/decoded_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/_nke_ir_rudics_rem_all.txt';
floatListFileName = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists/tmp.txt';
floatListFileName = '';

% directory to store the log and csv file
DIR_LOG_CSV_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\';


% create and start log file recording
logFile = [DIR_LOG_CSV_FILE '/' 'compare_data_base_export_' datestr(now, 'yyyymmddTHHMMSS') '.log'];

diary(logFile);
tic;

% create the CSV output file
outputFileName = [DIR_LOG_CSV_FILE '/compare_data_base_export_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
fidOut = fopen(outputFileName, 'wt');
if (fidOut == -1)
   fprintf('Erreur ouverture fichier: %s\n', outputFileName);
   return
end

header = ['WMO; in BASE; in NEW; TECH Id; dim level; BASE value; NEW value'];
fprintf(fidOut, '%s\n', header);

% BASE FILE
% read meta file
fprintf('Processing BASE file: %s\n', baseFileName);
fId = fopen(baseFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', baseFileName);
   return
end
baseFileContents = textscan(fId, '%s', 'delimiter', '\t');
baseFileContents = baseFileContents{:};
fclose(fId);

baseFileContents = regexprep(baseFileContents, '"', '');

baseMetaData = reshape(baseFileContents, 5, size(baseFileContents, 1)/5)';

baseWmoList = baseMetaData(:, 1);
for id = 1:length(baseWmoList)
   if (isempty(str2num(baseWmoList{id})))
      fprintf('%s is not a valid WMO number\n', baseWmoList{id});
      return
   end
end
S = sprintf('%s*', baseWmoList{:});
baseWmoList = sscanf(S, '%f*');
baseFloatList = unique(baseWmoList);
baseParamIdList = baseMetaData(:, 2);
S = sprintf('%s*', baseParamIdList{:});
baseParamIdList = sscanf(S, '%f*');
baseDimLevList = baseMetaData(:, 3);
S = sprintf('%s*', baseDimLevList{:});
baseDimLevList = sscanf(S, '%f*');

% New FILE
% read meta file
fprintf('Processing NEW file: %s\n', newFileName);
fId = fopen(newFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', newFileName);
   return
end
newFileContents = textscan(fId, '%s', 'delimiter', '\t');
newFileContents = newFileContents{:};
fclose(fId);

newFileContents = regexprep(newFileContents, '"', '');

newMetaData = reshape(newFileContents, 5, size(newFileContents, 1)/5)';

newWmoList = newMetaData(:, 1);
for id = 1:length(newWmoList)
   if (isempty(str2num(newWmoList{id})))
      fprintf('%s is not a valid WMO number\n', newWmoList{id});
      return
   end
end
S = sprintf('%s*', newWmoList{:});
newWmoList = sscanf(S, '%f*');
newFloatList = unique(newWmoList);
newParamIdList = newMetaData(:, 2);
S = sprintf('%s*', newParamIdList{:});
newParamIdList = sscanf(S, '%f*');
newDimLevList = newMetaData(:, 3);
S = sprintf('%s*', newDimLevList{:});
newDimLevList = sscanf(S, '%f*');

% create the list of floats to compare
if (~isempty(floatListFileName))
   floatList = load(floatListFileName);
else
   floatList = sort(unique([baseFloatList; newFloatList]));
end

baseFloatList = sort(intersect(floatList, baseFloatList));
newFloatList = sort(intersect(floatList, newFloatList));

notInBase = sort(setdiff(newFloatList, baseFloatList));
if (~isempty(notInBase))
   fprintf('WARNING: Following floats are not in base file:\n');
   fprintf('%d\n', notInBase);
end
notInNew = sort(setdiff(baseFloatList, newFloatList));
if (~isempty(notInNew))
   fprintf('WARNING: Following floats are not in new file:\n');
   fprintf('%d\n', notInNew);
end

% compare the files
for idFloat = 1:length(floatList)
   
   floatNum = floatList(idFloat);
   fprintf('%3d/%3d %d\n', idFloat, length(floatList), floatNum);

   idBaseForWmo = find(baseWmoList == floatList(idFloat));
   doneBase = zeros(length(idBaseForWmo), 1);
   idNewForWmo = find(newWmoList == floatList(idFloat));
   doneNew = zeros(length(idNewForWmo), 1);

   for idB = 1:length(idBaseForWmo)
      paramId = baseParamIdList(idBaseForWmo(idB));
      dimLev = baseDimLevList(idBaseForWmo(idB));
      paramVal = baseMetaData{idBaseForWmo(idB), 4};
      idF = find((newWmoList == floatNum) & ...
         (newParamIdList == paramId) & ...
         (newDimLevList == dimLev));
      if (~isempty(idF))
         if (~strcmp(paramVal, newMetaData{idF, 4}))
            fprintf(fidOut, '%d; 1; 1; %d; %d; %s; %s; %s\n', ...
               floatNum, paramId, dimLev, paramVal, newMetaData{idF, 4}, newMetaData{idF, 5});
         end
         doneBase(idB) = 1;
         idF = find(idNewForWmo == idF);
         doneNew(idF) = 1;
      else
         fprintf(fidOut, '%d; 1; 0; %d; %d; %s; ; %s\n', ...
            floatNum, paramId, dimLev, paramVal, baseMetaData{idBaseForWmo(idB), 5});
         doneBase(idB) = 1;
      end
   end
   
   idRemain = find(doneNew == 0);
   for idN = 1:length(idRemain)
      paramId = newParamIdList(idNewForWmo(idRemain(idN)));
      dimLev = newDimLevList(idNewForWmo(idRemain(idN)));
      paramVal = newMetaData{idNewForWmo(idRemain(idN)), 4};
      fprintf(fidOut, '%d; 0; 1; %d; %d; ; %s; %s\n', ...
         floatNum, paramId, dimLev, paramVal, newMetaData{idNewForWmo(idRemain(idN)), 5});
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

fclose(fidOut);

diary off;

return
