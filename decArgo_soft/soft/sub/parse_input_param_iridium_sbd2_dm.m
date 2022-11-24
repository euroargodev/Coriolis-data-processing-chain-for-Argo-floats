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
global g_decArgo_dirInputRsyncLog;
global g_decArgo_iridiumDataDirectory;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;


% check input parameters
floatWmo = [];
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'floatwmo'))
            if (isempty(floatWmo))
               floatWmo = str2num(a_varargin{id+1});
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_floatwmo', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments - exit\n');
               o_inputError = 1;
               return
            end
         else
            fprintf('INFO: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check mandatory input parameter
if (isempty(floatWmo))
   fprintf('ERROR: ''floatwmo'' input param is mandatory - exit\n');
   o_inputError = 1;
   return
end

% retrieve float IMEI number
[floatWmo, floatImei, ...
   floatDecVersion, floatDecId, ...
   floatFrameLen, ...
   floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
   floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
   floatRefDay, floatDmFlag] = get_one_float_info(floatWmo, []);
if (isempty(floatImei))
   fprintf('ERROR: no information on float #%d - exit\n', floatWmo);
   o_inputError = 1;
   return
end
g_decArgo_dirInputRsyncLog = [g_decArgo_dirInputRsyncLog '/' floatImei '/'];

% check the corresponding directories and files
if ~(exist(g_decArgo_dirInputRsyncLog, 'dir') == 7)
   fprintf('ERROR: rsync log file directory (%s) does not exist - exit\n', g_decArgo_dirInputRsyncLog);
   o_inputError = 1;
   return;
end

% get archive directory
checkRsyncLog = 0;
floatIriDirName = [g_decArgo_iridiumDataDirectory '/' floatImei '_' num2str(floatWmo) '/'];
archiveDmDir = [floatIriDirName 'archive_dm/'];
mailFiles = dir([archiveDmDir '/' sprintf('*_%s_*.txt', floatImei)]); % we can have *.txt and .sbd files but we should have at least one .txt file
if (isempty(mailFiles))
   checkRsyncLog = 1;
end

tabFloatMailFiles = [];
if (checkRsyncLog == 1)
   
   % parse rsync log files
   [ryncLogList] = get_rsync_log_dir_file_names_ir_rudics(g_decArgo_dirInputRsyncLog);
   
   for idFile = 1:length(ryncLogList)
      [floatImeiList, floatMailFiles, rsyncLogName] = parse_rsync_log_ir_sbd2(ryncLogList{idFile});
      idF = find(strcmp(floatImei, floatImeiList) == 1);
      tabFloatMailFiles = [tabFloatMailFiles floatMailFiles(idF)];
   end
end

g_decArgo_rsyncFloatWmoList = ones(size(tabFloatMailFiles))*floatWmo;
g_decArgo_rsyncFloatSbdFileList = tabFloatMailFiles;

% output data
o_floatList = unique(g_decArgo_rsyncFloatWmoList);

return
