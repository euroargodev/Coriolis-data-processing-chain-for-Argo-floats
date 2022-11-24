% ------------------------------------------------------------------------------
% Parse common input parameters to set global input parameter variables.
%
% SYNTAX :
%  [o_unusedVarargin, o_inputError] = parse_input_param_common(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
%
% OUTPUT PARAMETERS :
%   o_unusedVarargin : not already used input parameters
%   o_inputError     : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_unusedVarargin, o_inputError] = parse_input_param_common(a_varargin)

% output parameters initialization
o_unusedVarargin = [];
o_inputError = 0;

% global input parameter information
global g_decArgo_configFilePathName;
g_decArgo_configFilePathName = [];
global g_decArgo_xmlReportFileName;
g_decArgo_xmlReportFileName = [];

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;


% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
configFileInputParam = 0;
xmlReportInputParam = 0;
idDel = [];
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'configfile'))
            idDel = [idDel id id+1];
            g_decArgo_configFilePathName{end+1} = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlreport'))
            if (xmlReportInputParam == 0)
               xmlReportInputParam = 1;    
               idDel = [idDel id id+1];
               g_decArgo_xmlReportFileName = a_varargin{id+1};
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_xmlreport', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments - exit\n');
               o_inputError = 1;
               return
            end
         end
      end
   end
end

if (length(g_decArgo_configFilePathName) == 1)
   g_decArgo_configFilePathName = g_decArgo_configFilePathName{1};
elseif (length(g_decArgo_configFilePathName) > 1)
   configFilePathNameList = g_decArgo_configFilePathName;
   % find the configuration file associated to float WMO
   [configFileNumber] = get_config_file_number(a_varargin);
   if (~isempty(configFileNumber))
      g_decArgo_configFilePathName = g_decArgo_configFilePathName{configFileNumber};
   else
      % assign g_decArgo_configFilePathName to the first provided configuration
      % file
      g_decArgo_configFilePathName = configFilePathNameList{1};
      o_inputError = 1;
      % no return so that the error can be reported in the XML report file
   end
end

% check the config input file
if (configFileInputParam == 1)
   if ~(exist(g_decArgo_configFilePathName, 'file') == 2)
      fprintf('ERROR: input configuration file (%s) does not exist - exit\n', g_decArgo_configFilePathName);
      o_inputError = 1;
      return
   end
end

% check the xml report file name consistency
if (xmlReportInputParam == 1)
   if (length(g_decArgo_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co041404_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_decArgo_xmlReportFileName);
      g_decArgo_xmlReportFileName = [];
   end
end

o_unusedVarargin = a_varargin;
o_unusedVarargin(idDel) = [];

return
