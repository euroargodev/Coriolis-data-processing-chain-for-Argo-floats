% ------------------------------------------------------------------------------
% Parse input parameters and, for each SBD file to process, create the list of
% associated float WMO number, float Imei and SBD file name.
%
% SYNTAX :
%  [o_floatList, o_inputError] = ...
%    parse_input_param_iridium_sbd2_dm(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin   : additional input parameters
%
% OUTPUT PARAMETERS :
%   o_inputError : input error flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   02/03/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatList, o_inputError] = ...
   parse_input_param_iridium_sbd2_dm(a_varargin)

% output parameters initialization
o_floatList = [];
o_inputError = 0;

% global configuration values
global g_decArgo_floatListFileName;
global g_decArgo_dirInputRsyncLog;
global g_decArgo_dirInputJsonFloatDecodingParametersFile;
global g_decArgo_iridiumDataDirectory;

% SBD sub-directory
global g_decArgo_historyDirectory;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatLoginNameList;
global g_decArgo_rsyncFloatSbdFileList;

% already processed rsync log information
global g_decArgo_floatWmoUnderProcessList;
global g_decArgo_rsyncLogFileUnderProcessList;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;


% check input parameters
floatWmo = [];
floatWmoList = [];
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      o_inputError = 1;
      return;
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'floatwmo'))
            if (isempty(floatWmo) && isempty(floatWmoList))
               floatWmo = a_varargin{id+1};
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_floatwmo', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return;
            end
         elseif (strcmpi(a_varargin{id}, 'floatwmolist'))
            if (isempty(floatWmo) && isempty(floatWmoList))
               floatWmoList = eval(a_varargin{id+1});
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_floatwmolist', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return;
            end
         else
            fprintf('WARNING: unexpected input argument (%s) => ignored\n', a_varargin{id});
         end
      end
   end
end

% check the corresponding directories and files
if ~(exist(g_decArgo_dirInputRsyncLog, 'dir') == 7)
   fprintf('ERROR: rsync log file directory (%s) does not exist => exit\n', g_decArgo_dirInputRsyncLog);
   o_inputError = 1;
   return;
end

floatList = [];
if (~isempty(floatWmo))
   floatList = str2num(floatWmo);
elseif (~isempty(floatWmoList))
   floatList = floatWmoList;
else
   floatWmoList = g_decArgo_floatListFileName;
   if ~(exist(floatWmoList, 'file') == 2)
      fprintf('ERROR: default WMO float file list (%s) does not exist => exit\n', floatWmoList);
      o_inputError = 1;
      return;
   end
   floatList = load(floatWmoList);
end

checkRsyncLog = 0;
for idFloat = 1:length(floatList)
   [floatNum, floatImei, ...
      floatDecVersion, floatDecId, ...
      floatFrameLen, ...
      floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
      floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
      floatRefDay, floatEndDate] = get_one_float_info(floatList(idFloat), []);
   
   archiveDir = [g_decArgo_iridiumDataDirectory '/' floatImei '_' num2str(floatNum) '/archive/'];
   mailFiles = dir([archiveDir '/' sprintf('*_%s_*.txt', floatImei)]);
   if (isempty(mailFiles))
      checkRsyncLog = 1;
      break;
   end
end

tabFloatWmoList = [];
tabFloatImei = [];
tabFloatMailFiles = [];

if (checkRsyncLog == 1)
   
   % parse rsync log files
   [ryncLogList] = get_rsync_log_dir_file_names_ir_rudics(g_decArgo_dirInputRsyncLog);
   
   for idFloat = 1:length(ryncLogList)
      [floatImei, floatMailFiles, rsyncLogName] = parse_rsync_log_ir_sbd2(ryncLogList{idFloat});
      tabFloatImei = [tabFloatImei floatImei];
      tabFloatMailFiles = [tabFloatMailFiles floatMailFiles];
   end
   
   % keep only the entries of the floatList floats
   idToDelete = ones(1, length(tabFloatImei));
   tabFloatWmoList = ones(1, length(tabFloatImei))*-1;
   for idFloat = 1:length(floatList)
      [floatNum, floatImei, ...
         floatDecVersion, floatDecId, ...
         floatFrameLen, ...
         floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
         floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
         floatRefDay, floatEndDate] = get_one_float_info(floatList(idFloat), []);
      
      idF = find(strcmp(tabFloatImei, floatImei) == 1);
      if (~isempty(idF))
         
         % some floats can share the same IMEI
         if (~isempty(find(tabFloatWmoList(idF) ~= -1, 1)))
            
            % duplicate these entries for this float
            tabFloatImei = [tabFloatImei tabFloatImei(idF)];
            tabFloatMailFiles = [tabFloatMailFiles tabFloatMailFiles(idF)];
            
            tabFloatWmoList = [tabFloatWmoList ones(1, length(idF))*floatList(idFloat)];
            idToDelete = [idToDelete zeros(1, length(idF))];
         else
            
            tabFloatWmoList(idF) = floatList(idFloat);
            idToDelete(idF) = 0;
         end
      end
   end
   
   idDel = find(idToDelete == 1);
   tabFloatImei(idDel) = [];
   tabFloatMailFiles(idDel) = [];
   tabFloatWmoList(idDel) = [];
end

g_decArgo_rsyncFloatWmoList = tabFloatWmoList;
g_decArgo_rsyncFloatLoginNameList = tabFloatImei;
g_decArgo_rsyncFloatSbdFileList = tabFloatMailFiles;

% output data
o_floatList = unique(g_decArgo_rsyncFloatWmoList);

return;
