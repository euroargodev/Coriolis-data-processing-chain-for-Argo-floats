% ------------------------------------------------------------------------------
% Decode Argo float data to NetCDF files in Real Time mode.
%
% SYNTAX :
%   decode_argo_2_nc_rt or decode_argo_2_nc_rt(varargin)
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
%   04/16/2013 - RNU - creation
% ------------------------------------------------------------------------------
function decode_argo_2_nc_rt(varargin)

% mode processing flags
global g_decArgo_realtimeFlag;
global g_decArgo_delayedModeFlag;

g_decArgo_realtimeFlag = 1;
g_decArgo_delayedModeFlag = 0;

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

% Argos Id temporary sub-directory
global g_decArgo_tmpArgosIdDirectory;

% global input parameter information
global g_decArgo_xmlReportFileName;

% global input parameter information
global g_decArgo_processModeRedecode;
global g_decArgo_inputFloatWmo;
global g_decArgo_inputFloatWmoList;


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
         logFileName = [g_decArgo_dirOutputLogFile '/decode_argo_2_nc_rt_' g_decArgo_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_decArgo_dirOutputLogFile '/decode_argo_2_nc_rt_' currentTime '.log'];
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
      
      if (g_decArgo_floatTransType == 1)
         
         % Argos
         
         % check and analyse input parameters
         [stopProcess] = parse_input_param_argos(unusedVarargin);
         
         if (stopProcess == 0)
            if (g_decArgo_processModeRedecode == 0)
               [floatList, stopProcess] = rename_argos_input_file;
            elseif (g_decArgo_processModeRedecode == 1)
               if (~isempty(g_decArgo_inputFloatWmo))
                  floatList = str2num(g_decArgo_inputFloatWmo);
               elseif (~isempty(g_decArgo_inputFloatWmoList))
                  floatList = load(g_decArgo_inputFloatWmoList);
               end
            end
         end
         
      elseif (g_decArgo_floatTransType == 2)
         
         % Iridium Rudics
         
         % check and analyse input parameters
         [floatList, stopProcess] = ...
            parse_input_param_iridium_rudics_rt(unusedVarargin);
         
      elseif (g_decArgo_floatTransType == 3)
         
         % Iridium SBD
         
         % check and analyse input parameters
         [floatList, stopProcess] = ...
            parse_input_param_iridium_sbd_rt(unusedVarargin);
         
      elseif (g_decArgo_floatTransType == 4)
         
         % Iridium SBD ProvBioII floats
         
         % check and analyse input parameters
         [floatList, stopProcess] = ...
            parse_input_param_iridium_sbd2_rt(unusedVarargin);

      end
      
      % empty CSV file Id
      g_decArgo_outputCsvFileId = [];
      
      if (stopProcess == 0)
         % decode the floats of the list
         decode_argo(floatList);
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

% delete the temporary sub-directory
if (~isempty(g_decArgo_tmpArgosIdDirectory) && (exist(g_decArgo_tmpArgosIdDirectory, 'dir') == 7))
   [statusRmdir, message, messageId] = rmdir(g_decArgo_tmpArgosIdDirectory, 's');
   if (statusRmdir == 0)
      fprintf('ERROR: Error while deleting the %s directory (%s)\n', ...
         g_decArgo_tmpArgosIdDirectory, ...
         message);
   end
end

% when no configuration file has been selected, set the path of the XML report
if (isempty(g_decArgo_dirOutputXmlFile))
   if (ispc)
      g_decArgo_dirOutputXmlFile = '.'; % local dir for windows
   elseif (isunix)
      g_decArgo_dirOutputXmlFile = '/tmp'; % local dir for windows
   end
   fprintf('WARNING: XML report is stored in ''%s'' directory\n', ...
      g_decArgo_dirOutputXmlFile);
end

% create the XML report path file name
if (~isempty(g_decArgo_xmlReportFileName))
   xmlFileName = [g_decArgo_dirOutputXmlFile '/' g_decArgo_xmlReportFileName];
else
   xmlFileName = [g_decArgo_dirOutputXmlFile '/co041404_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_decArgo_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return
