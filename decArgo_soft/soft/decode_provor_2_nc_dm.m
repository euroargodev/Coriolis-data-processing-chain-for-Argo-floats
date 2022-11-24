% ------------------------------------------------------------------------------
% Decode PROVOR data to NetCDF files in Delayed mode.
%
% SYNTAX :
%   decode_provor_2_nc_dm or decode_provor_2_nc_dm(varargin)
%
% INPUT PARAMETERS :
%   varargin : input parameters
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/09/2015 - RNU - creation
% ------------------------------------------------------------------------------
function decode_provor_2_nc_dm(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

g_decArgo_realtimeFlag = 0;
g_decArgo_delayedModeFlag = 1;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration variables/values
global g_decArgo_configVar;
global g_decArgo_configVal;

% configuration values
global g_decArgo_dirOutputLogFile;
global g_decArgo_dirOutputXmlFile;
global g_decArgo_floatTransType;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;

% report information structure
global g_decArgo_reportData;
g_decArgo_reportData = [];


% global input parameter information
global g_decArgo_xmlReportFileName;


logFileName = [];

try
   
   % startTime
   ticStartTime = tic;
   
   % store the start time of the run
   currentTime = datestr(now, 'yyyymmddTHHMMSSZ');
   
   % default values initialization
   init_default_values;
   
   % init the XML report
   init_xml_report(currentTime);
   
   % check and analyse common input parameters
   [unusedVarargin, inputError] = parse_input_param_common(varargin);
   
   if (inputError == 0)
      % configuration values initialization
      [unusedVarargin, inputError] = init_config_values(unusedVarargin);
   end
   
   if (inputError == 0)
      
      % log file creation
      if (~isempty(g_decArgo_xmlReportFileName))
         logFileName = [g_decArgo_dirOutputLogFile '/decode_provor_2_nc_dm_' g_decArgo_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_decArgo_dirOutputLogFile '/decode_provor_2_nc_dm_' currentTime '.log'];
      end
      diary(logFileName);   
      
      % print input parameters
      fprintf('CURRENT TIME: %s\n\n', currentTime);
      fprintf('INPUT PARAMETERS:\n');
      if (rem(nargin, 2) == 0)
         for id = 1:2:nargin
            fprintf('%s:%s\n', varargin{id}, varargin{id+1});
         end
      else
         fprintf('%s\n', varargin{:});
      end
      fprintf('\n');
      % print configuration parameters
      fprintf('CONFIGURATION PARAMETERS:\n');
      for idVar = 1:length(g_decArgo_configVar)
         fprintf(' %s : %s\n', ...
            g_decArgo_configVar{idVar}, g_decArgo_configVal{idVar});
      end
      fprintf('\n');

      % measurement codes initialization
      init_measurement_codes;

      stopProcess = 1;
      if (g_decArgo_floatTransType == 2)
         
         % Iridium Rudics
         
         % check and analyse input parameters
         [floatList, stopProcess] = ...
            parse_input_param_iridium_rudics_dm(unusedVarargin);
                  
      elseif (g_decArgo_floatTransType == 4)
         
         % Iridium SBD ProvBioII floats
         
         % check and analyse input parameters
         [floatList, stopProcess] = ...
            parse_input_param_iridium_sbd2_dm(unusedVarargin);

      end
      
      % empty CSV file Id
      g_decArgo_outputCsvFileId = [];
      
      if (stopProcess == 0)
         % decode the floats of the list
         decode_provor(floatList);
      end

      diary off;
      
      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);
      
   else
      status = 'nok';
   end

catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% create the XML report path file name
if (~isempty(g_decArgo_xmlReportFileName))
   xmlFileName = [g_decArgo_dirOutputXmlFile '/' g_decArgo_xmlReportFileName];
else
   xmlFileName = [g_decArgo_dirOutputXmlFile '/co041404_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_decArgo_xmlReportDOMNode);
if (strcmp(status, 'nok') == 1)
   edit(xmlFileName);
end

return;
