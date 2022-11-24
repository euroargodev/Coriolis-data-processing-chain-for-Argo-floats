% ------------------------------------------------------------------------------
% Check if the parameters of the Matlab decoder need to be updated after the
% last update of the parameter list Excel file.
%
% SYNTAX :
%   check_param_attributes
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
function check_param_attributes()

% name of files to compare
PARAMETER_FILE_NAME = 'C:\Users\jprannou\_RNU\Argo\MANUELS_REF_ARGO\parameter_list\argo-parameters-list-core-and-b_20160104.xlsx';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% create and start log file recording
logFile = [DIR_LOG_FILE '/' 'check_param_attributes_' datestr(now, 'yyyymmddTHHMMSS') '.log'];
diary(logFile);

% read the new Excel files
ok = 0;
[~, ~, raw] = xlsread(PARAMETER_FILE_NAME);
for idL = 1:size(raw, 1)
   for idC = 1:size(raw, 2)
      if (isnan(raw{idL, idC}))
         raw{idL, idC} = '';
      end
   end
end
idF = find(strcmp(raw(:, 1), 'Order') == 1, 1);
if (~isempty(idF))
   headerLine = idF;
   idF = find(strcmp(raw(headerLine, :), 'parameter name') == 1, 1);
   if (~isempty(idF))
      parameterName = idF;
      idF = find(strcmp(raw(headerLine, :), 'long_name') == 1, 1);
      if (~isempty(idF))
         longName = idF;
         idF = find(strcmp(raw(headerLine, :), 'cf_standard_name') == 1, 1);
         if (~isempty(idF))
            standardName = idF;
            idF = find(strcmp(raw(headerLine, :), 'unit') == 1, 1);
            if (~isempty(idF))
               unit = idF;
               idF = find(strcmp(raw(headerLine, :), 'valid_min') == 1, 1);
               if (~isempty(idF))
                  validMin = idF;
                  idF = find(strcmp(raw(headerLine, :), 'valid_max') == 1, 1);
                  if (~isempty(idF))
                     validMax = idF;
                     idF = find(strcmp(raw(headerLine, :), 'core/bio/intermediate') == 1, 1);
                     if (~isempty(idF))
                        cbi = idF;
                        ok = 1;
                     end
                  end
               end
            end
         end
      end
   end
end

if (ok == 1)
   paramName = [];
   paramLongName = [];
   paramStandardName = [];
   paramUnit = [];
   paramValidMin = [];
   paramValidMax = [];
   paramCbi = [];
   for idL = headerLine+1:size(raw)
      if (isnumeric(raw{idL, 1}) && ~isnan(raw{idL, 1}))
         paramName{end+1} = raw{idL, parameterName};
         
         %          if (strcmp(raw{idL, parameterName}, 'C2PHASE_DOXY'))
         %             a=1
         %          end
         
         paramLongName{end+1} = raw{idL, longName};
         if (strcmp(raw{idL, standardName}, '-'))
            paramStandardName{end+1} = '';
         else
            paramStandardName{end+1} = raw{idL, standardName};
         end
         paramUnit{end+1} = raw{idL, unit};
         if (strcmp(raw{idL, validMin}, '-'))
            paramValidMin{end+1} = '';
         else
            paramValidMin{end+1} = str2num(regexprep(raw{idL, validMin}, 'f', ''));
         end
         if (strcmp(raw{idL, validMax}, '-'))
            paramValidMax{end+1} = '';
         else
            paramValidMax{end+1} = str2num(regexprep(raw{idL, validMax}, 'f', ''));
         end
         paramCbi{end+1} = raw{idL, cbi};
      else
         break;
      end
   end
else
   fprintf('ERROR: Cannot find expected fields in input file %s\n', PARAMETER_FILE_NAME);
   return;
end

% check parameter list
fprintf('The following parameters should be updated:\n\n');

[paramName, idSort] = sort(paramName);
paramLongName = paramLongName(idSort);
paramStandardName = paramStandardName(idSort);
paramUnit = paramUnit(idSort);
paramValidMin = paramValidMin(idSort);
paramValidMax = paramValidMax(idSort);
paramCbi = paramCbi(idSort);

unusedParamList = [];
for idP = 1:length(paramName)
   paramStruct = get_netcdf_param_attributes_3_1(paramName{idP});
   if (~isempty(paramStruct))
      if (~strcmp(paramLongName{idP}, paramStruct.longName) || ...
            ~strcmp(paramStandardName{idP}, paramStruct.standardName) || ...
            ~strcmp(paramUnit{idP}, paramStruct.units) || ...
            (isempty(paramValidMin{idP}) && ~isempty(paramStruct.validMin)) || ...
            (~isempty(paramValidMin{idP}) && isempty(paramStruct.validMin)) || ...
            (~isempty(paramValidMin{idP}) && ~isempty(paramStruct.validMin) && (paramValidMin{idP} ~= paramStruct.validMin)) || ...
            (isempty(paramValidMax{idP}) && ~isempty(paramStruct.validMax)) || ...
            (~isempty(paramValidMax{idP}) && isempty(paramStruct.validMax)) || ...
            (~isempty(paramValidMax{idP}) && ~isempty(paramStruct.validMax) && (paramValidMax{idP} ~= paramStruct.validMax)) || ...
            (paramCbi{idP} ~= paramStruct.paramType))
         
         %          if (strcmp(paramStruct.name, 'C2PHASE_DOXY'))
         %             a=1
         %          end
         
         fprintf('Parameter: %s\n', paramName{idP});
         if (~strcmp(paramLongName{idP}, paramStruct.longName))
            fprintf('long_name code  : %s\n', paramStruct.longName);
            fprintf('long_name update: %s\n', paramLongName{idP});
         end
         if (~strcmp(paramStandardName{idP}, paramStruct.standardName))
            fprintf('standard_name code  : %s\n', paramStruct.standardName);
            fprintf('standard_name update: %s\n', paramStandardName{idP});
         end
         if (~strcmp(paramUnit{idP}, paramStruct.units))
            fprintf('unit code  : %s\n', paramStruct.units);
            fprintf('unit update: %s\n', paramUnit{idP});
         end
         if ((isempty(paramValidMin{idP}) && ~isempty(paramStruct.validMin)) || ...
               (~isempty(paramValidMin{idP}) && isempty(paramStruct.validMin)) || ...
               (~isempty(paramValidMin{idP}) && ~isempty(paramStruct.validMin) && (paramValidMin{idP} ~= paramStruct.validMin)))
            fprintf('valid_min code  : %g\n', paramStruct.validMin);
            fprintf('valid_min update: %g\n', paramValidMin{idP});
         end
         if ((isempty(paramValidMax{idP}) && ~isempty(paramStruct.validMax)) || ...
               (~isempty(paramValidMax{idP}) && isempty(paramStruct.validMax)) || ...
               (~isempty(paramValidMax{idP}) && ~isempty(paramStruct.validMax) && (paramValidMax{idP} ~= paramStruct.validMax)))
            fprintf('valid_max code  : %g\n', paramStruct.validMax);
            fprintf('valid_max update: %g\n', paramValidMax{idP});
         end
         if (paramCbi{idP} ~= paramStruct.paramType)
            fprintf('param type code  : %c\n', paramStruct.paramType);
            fprintf('param type update: %c\n', paramCbi{idP});
         end
         fprintf('\n');
      end
   else
      unusedParamList{end+1} = paramName{idP};
   end
end
fprintf('\n');

fprintf('The following parameters are not considered in the Matlab decoder:\n\n');

if (~isempty(unusedParamList))
   fprintf('%s\n', unusedParamList{:});
else
   fprintf('none\n');
end
fprintf('\n');

diary off;

return;
