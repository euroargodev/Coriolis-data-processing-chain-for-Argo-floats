% ------------------------------------------------------------------------------
% Retrieve parameter values from configuration file (should be in the MATLAB
% path), they can be overriden by input arguments.
%
% SYNTAX :
%  [o_configVal, o_unusedVarargin, o_inputError] = ...
%    get_config_dec_argo(a_configVar, a_varargin)
%
% INPUT PARAMETERS :
%   a_configVar : wanted configuration parameter names
%   a_varargin  : additional input parameters
%
% OUTPUT PARAMETERS :
%   o_configVal      : wanted configuration parameter values
%   o_unusedVarargin : additional input parameters (not found in the
%                      configuration file)
%   o_inputError     : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_configVal, o_unusedVarargin, o_inputError] = ...
   get_config_dec_argo(a_configVar, a_varargin)

% output parameters initialization
o_configVal = [];
o_unusedVarargin = [];
o_inputError = 0;

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

% configuration variables/values
global g_decArgo_configVar;
global g_decArgo_configVal;

% global input parameter information
global g_decArgo_configFilePathName;


% read configuration file and store the configVarName/configVarvalue parameters
varList1 = [];
valList1 = [];
if ((g_decArgo_realtimeFlag == 1) || (g_decArgo_delayedModeFlag == 1))
   
   % configuration file name
   if (~isempty(g_decArgo_configFilePathName))
      CONFIG_FILE_NAME = g_decArgo_configFilePathName;
   else
      CONFIG_FILE_NAME = '_argo_decoder_conf.json';
   end
   if ~(exist(CONFIG_FILE_NAME, 'file') == 2)
      fprintf('ERROR: Configuration file not found: %s\n', CONFIG_FILE_NAME);
      o_inputError = 1;
      return;
   else
      
      fprintf('INFO: Using configuration file: %s\n', which(CONFIG_FILE_NAME));
      
      % read configuration file
      fileContents = loadjson(CONFIG_FILE_NAME);
      
      % variable
      varList1 = fieldnames(fileContents);
      for idField = 1:length(varList1)
         valList1 = [valList1; {getfield(fileContents, char(varList1(idField)))}];
      end
      
   end
   
else
   
   % configuration file name
   CONFIG_FILE_NAME = '_argo_decoder.conf';
   if ~(exist(CONFIG_FILE_NAME, 'file') == 2)
      fprintf('ERROR: Configuration file not found: %s\n', CONFIG_FILE_NAME);
      o_inputError = 1;
      return;
   else
      
      fprintf('INFO: Using configuration file: %s\n', which(CONFIG_FILE_NAME));
      
      % read configuration file
      fId = fopen(CONFIG_FILE_NAME, 'r');
      if (fId == -1)
         fprintf('ERROR: Unable to open file: %s\n', CONFIG_FILE_NAME);
         o_inputError = 1;
         return;
      end
      fileContents = textscan(fId, '%s', 'delimiter', '\n', 'commentstyle', 'matlab');
      fileContents = fileContents{:};
      fclose(fId);

      % get rid of comments lines
      idLine = 1;
      while (1)
         if (length(fileContents{idLine}) == 0)
            fileContents(idLine) = [];
         elseif (fileContents{idLine}(1) == '%')
            fileContents(idLine) = [];
         else
            idLine = idLine + 1;
         end
         if (idLine > length(fileContents))
            break;
         end
      end
      
      % find and store parameter values
      for idLine = 1:size(fileContents, 1)
         line = fileContents{idLine};
         eqPos = strfind(line, '=');
         if (isempty(eqPos) || (length(line) == eqPos))
            fprintf('ERROR: Error in configuration file, in line: %s\n', line);
            o_inputError = 1;
            return;
         end;
         
         % variable
         var = line(1:eqPos-1);
         var = strtrim(var);
         varList1 = [varList1; {var}];
         
         % value
         val = line(eqPos+1:end);
         val = strtrim(val);
         valList1 = [valList1; {val}];
      end
   end
   
end

% store the data
for idVar = 1:length(a_configVar)
   row = strmatch(a_configVar{idVar}, varList1, 'exact');
   if (isempty(row))
%       fprintf('Configuration file %s, parameter %s not found\n', ...
%          CONFIG_FILE_NAME, a_configVar{idVar});
      o_configVal{end+1} = [];
   else
      if (isempty(valList1{row}))
%          fprintf('Configuration file %s, parameter %s not filled\n', ...
%             CONFIG_FILE_NAME, a_configVar{idVar});
      end
      o_configVal{end+1} = valList1{row};
   end
end

% read input args and store the configVarName/configVarvalue parameters
varList2 = [];
valList2 = [];
if (~isempty(a_varargin))
   % input arguments
   inputArgs = a_varargin;

   if (rem(length(inputArgs), 2) ~= 0)
      fprintf('ERROR: odd number of input arguments => exit\n');
      o_inputError = 1;
   else
      varList2 = [inputArgs(1:2:end)];
      valList2 = [inputArgs(2:2:end)];
   end
end

% override configuration file parameters with input args
listToDel = [];
for idVar = 1:length(a_configVar)
   row = strmatch(a_configVar{idVar}, varList2, 'exact');
   if (~isempty(row))
      o_configVal{idVar} = valList2{row};
      listToDel = [listToDel row];
   end
end

o_unusedVarargin = a_varargin;
o_unusedVarargin([listToDel*2-1 listToDel*2]) = [];

g_decArgo_configVar = a_configVar;
g_decArgo_configVal = o_configVal;

return;
