% ------------------------------------------------------------------------------
% Compare two parameter lists (provided as Excel files).
%
% SYNTAX :
%   compare_parameter_list_excel_files
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
%   12/16/2015 - RNU - creation
% ------------------------------------------------------------------------------
function compare_parameter_list_excel_files()

% name of files to compare
NEW_PARAMETER_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\MANUELS_REF_ARGO\parameter_list\argo-parameters-list-core-and-b_20160104.xlsx';
OLD_PARAMETER_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\MANUELS_REF_ARGO\parameter_list\argo-parameters-list-core-and-b_20150513.xlsx';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'compare_parameter_list_excel_files_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% read the new Excel files
okForNew = 0;
[~, ~, rawN] = xlsread(NEW_PARAMETER_FILE_NAME);
for idL = 1:size(rawN, 1)
   for idC = 1:size(rawN, 2)
      if (isnan(rawN{idL, idC}))
         rawN{idL, idC} = '';
      end
   end
end
idF = find(strcmp(rawN(:, 1), 'Order') == 1, 1);
if (~isempty(idF))
   headerLineN = idF;
   idF = find(strcmp(rawN(headerLineN, :), 'parameter name') == 1, 1);
   if (~isempty(idF))
      parameterNameN = idF;
      idF = find(strcmp(rawN(headerLineN, :), 'long_name') == 1, 1);
      if (~isempty(idF))
         longNameN = idF;
         idF = find(strcmp(rawN(headerLineN, :), 'cf_standard_name') == 1, 1);
         if (~isempty(idF))
            standardNameN = idF;
            idF = find(strcmp(rawN(headerLineN, :), 'unit') == 1, 1);
            if (~isempty(idF))
               unitN = idF;
               idF = find(strcmp(rawN(headerLineN, :), 'valid_min') == 1, 1);
               if (~isempty(idF))
                  validMinN = idF;
                  idF = find(strcmp(rawN(headerLineN, :), 'valid_max') == 1, 1);
                  if (~isempty(idF))
                     validMaxN = idF;
                     idF = find(strcmp(rawN(headerLineN, :), 'core/bio/intermediate') == 1, 1);
                     if (~isempty(idF))
                        cbiN = idF;
                        okForNew = 1;
                     end
                  end
               end
            end
         end
      end
   end
end

if (okForNew == 1)
   paramNameN = [];
   paramLongNameN = [];
   paramStandardNameN = [];
   paramUnitN = [];
   paramValidMinN = [];
   paramValidMaxN = [];
   paramCbiN = [];
   for idL = headerLineN+1:size(rawN)
      if (isnumeric(rawN{idL, 1}) && ~isnan(rawN{idL, 1}))
         paramNameN{end+1} = rawN{idL, parameterNameN};
         paramLongNameN{end+1} = rawN{idL, longNameN};
         paramStandardNameN{end+1} = rawN{idL, standardNameN};
         paramUnitN{end+1} = rawN{idL, unitN};
         paramValidMinN{end+1} = rawN{idL, validMinN};
         paramValidMaxN{end+1} = rawN{idL, validMaxN};
         paramCbiN{end+1} = rawN{idL, cbiN};
      else
         break;
      end
   end
else
   fprintf('ERROR: Cannot find expected fields in input file %s\n', NEW_PARAMETER_FILE_NAME);
   return;
end

% read the old Excel files
okForOld = 0;
[~, ~, rawO] = xlsread(OLD_PARAMETER_FILE_NAME);
for idL = 1:size(rawO, 1)
   for idC = 1:size(rawO, 2)
      if (isnan(rawO{idL, idC}))
         rawO{idL, idC} = '';
      end
   end
end
idF = find(strcmp(rawO(:, 1), 'Order') == 1, 1);
if (~isempty(idF))
   headerLineO = idF;
   idF = find(strcmp(rawO(headerLineO, :), 'parameter name') == 1, 1);
   if (~isempty(idF))
      parameterNameO = idF;
      idF = find(strcmp(rawO(headerLineO, :), 'long_name') == 1, 1);
      if (~isempty(idF))
         longNameO = idF;
         idF = find(strcmp(rawO(headerLineO, :), 'cf standard_name') == 1, 1);
         if (~isempty(idF))
            standardNameO = idF;
            idF = find(strcmp(rawO(headerLineO, :), 'unit') == 1, 1);
            if (~isempty(idF))
               unitO = idF;
               idF = find(strcmp(rawO(headerLineO, :), 'valid_min') == 1, 1);
               if (~isempty(idF))
                  validMinO = idF;
                  idF = find(strcmp(rawO(headerLineO, :), 'valid_max') == 1, 1);
                  if (~isempty(idF))
                     validMaxO = idF;
                     idF = find(strcmp(rawO(headerLineO, :), 'core/bio/intermediate') == 1, 1);
                     if (~isempty(idF))
                        cbiO = idF;
                        okForOld = 1;
                     end
                  end
               end
            end
         end
      end
   end
end

if (okForOld == 1)
   paramNameO = [];
   paramLongNameO = [];
   paramStandardNameO = [];
   paramUnitO = [];
   paramValidMinO = [];
   paramValidMaxO = [];
   paramCbiO = [];
   for idL = headerLineO+1:size(rawO)
      if (isnumeric(rawO{idL, 1}) && ~isnan(rawO{idL, 1}))
         paramNameO{end+1} = rawO{idL, parameterNameO};
         paramLongNameO{end+1} = rawO{idL, longNameO};
         paramStandardNameO{end+1} = rawO{idL, standardNameO};
         paramUnitO{end+1} = rawO{idL, unitO};
         paramValidMinO{end+1} = rawO{idL, validMinO};
         paramValidMaxO{end+1} = rawO{idL, validMaxO};
         paramCbiO{end+1} = rawO{idL, cbiO};
      else
         break;
      end
   end
else
   fprintf('ERROR: Cannot find expected fields in input file %s\n', NEW_PARAMETER_FILE_NAME);
   return;
end

% compare file contents
fprintf('The following parameters have been removed:\n\n');
[remParamList, remParamListId] = setdiff(paramNameO, paramNameN);
if (~isempty(remParamList))
   paramlist = sort(remParamList);
   fprintf('%s\n', paramlist{:});
else
   fprintf('none\n');
end
fprintf('\n');

fprintf('The following parameters have been added:\n\n');
[adParamList, adParamListId] = setdiff(paramNameN, paramNameO);
if (~isempty(adParamList))
   paramlist = sort(adParamList);
   fprintf('%s\n', paramlist{:});
else
   fprintf('none\n');
end
fprintf('\n');

fprintf('The following parameters have been modified:\n\n');

paramNameN(adParamListId) = [];
paramLongNameN(adParamListId) = [];
paramStandardNameN(adParamListId) = [];
paramUnitN(adParamListId) = [];
paramValidMinN(adParamListId) = [];
paramValidMaxN(adParamListId) = [];
paramCbiN(adParamListId) = [];

[paramNameN, idSort] = sort(paramNameN);
paramLongNameN = paramLongNameN(idSort);
paramStandardNameN = paramStandardNameN(idSort);
paramUnitN = paramUnitN(idSort);
paramValidMinN = paramValidMinN(idSort);
paramValidMaxN = paramValidMaxN(idSort);
paramCbiN = paramCbiN(idSort);

paramNameO(remParamListId) = [];
paramLongNameO(remParamListId) = [];
paramStandardNameO(remParamListId) = [];
paramUnitO(remParamListId) = [];
paramValidMinO(remParamListId) = [];
paramValidMaxO(remParamListId) = [];
paramCbiO(remParamListId) = [];

[paramNameO, idSort] = sort(paramNameO);
paramLongNameO = paramLongNameO(idSort);
paramStandardNameO = paramStandardNameO(idSort);
paramUnitO = paramUnitO(idSort);
paramValidMinO = paramValidMinO(idSort);
paramValidMaxO = paramValidMaxO(idSort);
paramCbiO = paramCbiO(idSort);

for idP = 1:length(paramNameN)
   if (~strcmp(paramLongNameN{idP}, paramLongNameO{idP}) || ...
         ~strcmp(paramStandardNameN{idP}, paramStandardNameO{idP}) || ...
         ~strcmp(paramUnitN{idP}, paramUnitO{idP}) || ...
         ~strcmp(paramValidMinN{idP}, paramValidMinO{idP}) || ...
         ~strcmp(paramValidMaxN{idP}, paramValidMaxO{idP}) || ...
         ~strcmp(paramCbiN{idP}, paramCbiO{idP}))
      
      fprintf('Parameter: %s\n', paramNameN{idP});
      if (~strcmp(paramLongNameN{idP}, paramLongNameO{idP}))
         fprintf('long_name NEW: %s\n', paramLongNameN{idP});
         fprintf('long_name OLD: %s\n', paramLongNameN{idP});
      end
      if (~strcmp(paramStandardNameN{idP}, paramStandardNameO{idP}))
         fprintf('standard_name NEW: %s\n', paramStandardNameN{idP});
         fprintf('standard_name OLD: %s\n', paramStandardNameO{idP});
      end
      if (~strcmp(paramUnitN{idP}, paramUnitO{idP}))
         fprintf('unit NEW: %s\n', paramUnitN{idP});
         fprintf('unit OLD: %s\n', paramUnitO{idP});
      end
      if (~strcmp(paramValidMinN{idP}, paramValidMinO{idP}))
         fprintf('valid_min NEW: %s\n', paramValidMinN{idP});
         fprintf('valid_min OLD: %s\n', paramValidMinO{idP});
      end
      if (~strcmp(paramValidMaxN{idP}, paramValidMaxO{idP}))
         fprintf('valid_max NEW: %s\n', paramValidMaxN{idP});
         fprintf('valid_max OLD: %s\n', paramValidMaxO{idP});
      end
      if (~strcmp(paramCbiN{idP}, paramCbiO{idP}))
         fprintf('param type NEW: %s\n', paramCbiN{idP});
         fprintf('param type OLD: %s\n', paramCbiO{idP});
      end
      fprintf('\n');
   end
end

diary off;

return;
