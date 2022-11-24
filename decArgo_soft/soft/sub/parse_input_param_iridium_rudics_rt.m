% ------------------------------------------------------------------------------
% Parse input parameters and, for each SBD file to process, create the list of
% associated float WMO number, float login name and SBD file name.
%
% SYNTAX :
%  [o_floatList, o_inputError] = ...
%    parse_input_param_iridium_rudics_rt(a_varargin)
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
%   09/18/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatList, o_inputError] = ...
   parse_input_param_iridium_rudics_rt(a_varargin)

% output parameters initialization
o_floatList = [];
o_inputError = 0;

% global configuration values
global g_decArgo_dirInputRsyncLog;
global g_decArgo_iridiumDataDirectory;

% SBD sub-directory
global g_decArgo_historyDirectory;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatSbdFileList;

% already processed rsync log information
global g_decArgo_rsyncLogFileUnderProcessList;
global g_decArgo_rsyncLogFileUsedList;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;


% check input parameters
rsyncLogInputParam = 0;
allRsyncLogFlag = 0;
rsyncLogFile = [];
floatWmo = [];
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') => exit\n');
      o_inputError = 1;
      return;
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'rsynclog'))
            if (rsyncLogInputParam == 0)
               rsyncLogInputParam = 1;
               if (strcmpi(a_varargin{id+1}, 'all'))
                  allRsyncLogFlag = 1;
               else
                  rsyncLogFile = a_varargin{id+1};
               end
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_rsynclog', a_varargin{id+1});
            else
               fprintf('ERROR: inconsistent input arguments => exit\n');
               o_inputError = 1;
               return;
            end
         elseif (strcmpi(a_varargin{id}, 'floatwmo'))
            if (isempty(floatWmo))
               floatWmo = str2num(a_varargin{id+1});
               
               % store input parameter in the XML report
               g_decArgo_xmlReportDOMNode = add_element_in_xml_report(g_decArgo_xmlReportDOMNode, 'param_floatwmo', a_varargin{id+1});
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

% check mandatory input parameter
if (rsyncLogInputParam == 0)
   fprintf('ERROR: ''rsynclog'' input param is mandatory => exit\n');
   o_inputError = 1;
   return;
end
if (isempty(floatWmo))
   fprintf('ERROR: ''floatwmo'' input param is mandatory => exit\n');
   o_inputError = 1;
   return;
end

% retrieve float login name and float decId
[floatWmo, floatLoginName, ...
   floatDecVersion, floatDecId, ...
   floatFrameLen, ...
   floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
   floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
   floatRefDay, floatEndDate, floatDmFlag] = get_one_float_info(floatWmo, []);
if (isempty(floatLoginName))
   fprintf('ERROR: no information on float #%d => exit\n', floatWmo);
   o_inputError = 1;
   return;
end

% g_decArgo_dirInputRsyncLog depends on decoder version 
if (ismember(floatDecId, [111]))
   g_decArgo_dirInputRsyncLog = [g_decArgo_dirInputRsyncLog '/' floatLoginName '/'];
end

% check the corresponding directories and files
rsyncLogPathFile = [];
if (~isempty(rsyncLogFile))
   rsyncLogPathFile = [g_decArgo_dirInputRsyncLog '/' rsyncLogFile];
   if ~(exist(rsyncLogPathFile, 'file') == 2)
      fprintf('ERROR: rsync log file (%s) does not exist => exit\n', rsyncLogPathFile);
      o_inputError = 1;
      return;
   end
end
if (allRsyncLogFlag == 1)
   if ~(exist(g_decArgo_dirInputRsyncLog, 'dir') == 7)
      fprintf('ERROR: rsync log file directory (%s) does not exist => exit\n', g_decArgo_dirInputRsyncLog);
      o_inputError = 1;
      return;
   end
end

% create the g_decArgo_historyDirectory directory (used below when there is no
% input files to process); additional directories will be created later
% according to float type and decoder configuration

% create the float directory
if (floatDecId < 1000)
   % NKE floats
   floatIriDirName = [g_decArgo_iridiumDataDirectory '/' floatLoginName '_' num2str(floatWmo) '/'];
elseif ((floatDecId > 1000) && (floatDecId < 2000))
   % APEX Iridium RUDICS & NAVIS floats
   floatIriDirName = [g_decArgo_iridiumDataDirectory '/' sprintf('%04d', str2double(floatLoginName)) '_' num2str(floatWmo) '/'];
end
if ~(exist(floatIriDirName, 'dir') == 7)
   mkdir(floatIriDirName);
end
% create the float history directory
g_decArgo_historyDirectory = [floatIriDirName 'history_of_processed_data/'];
if ~(exist(g_decArgo_historyDirectory, 'dir') == 7)
   mkdir(g_decArgo_historyDirectory);
end
   
% retrieve rsync log file names
ryncLogList = [];
if (~isempty(rsyncLogPathFile))
   ryncLogList{end+1} = rsyncLogPathFile;
end
if (allRsyncLogFlag == 1)
   [ryncLogList] = get_rsync_log_dir_file_names_ir_sbd(g_decArgo_dirInputRsyncLog);
end

% filter the ryncLogList file names according to rsync log files already processed

% get the list of the rsync log already processed for this float
[rsyncDoneLogList] = read_processed_rsync_log_file_ir_rudics_sbd_sbd2(floatWmo);

if (~isempty(rsyncDoneLogList))
   idToDel = [];
   for idFile = 1:length(rsyncDoneLogList)
      idF = find(strcmp(rsyncDoneLogList{idFile}, ryncLogList));
      idToDel = [idToDel idF];
   end
   ryncLogList(idToDel) = [];
end

% parse remaining rsync log files
tabFloatSbdFiles = [];
tabRsyncLogFiles = [];
for idFile = 1:length(ryncLogList)
   if (floatDecId < 1000)
      % NKE floats
      switch (floatDecId)
         case {105, 106, 107, 108, 109, 110}
            % CTS4 Iridium RUDICS floats (rsync to Villefranche global server)
            floatFiles = parse_rsync_log_ir_rudics_cts4_105_to_110(ryncLogList{idFile}, floatLoginName);
         case {111}
            % CTS4 Iridium RUDICS floats (ftp to individual float account + internal rsync at Coriolis)
            floatFiles = parse_rsync_log_ir_rudics_cts4_111(ryncLogList{idFile}, floatLoginName);
         case {121 122 123}
            % CTS5 Iridium RUDICS floats (rsync to Villefranche global server)
            floatFiles = parse_rsync_log_ir_rudics_cts5(ryncLogList{idFile}, floatLoginName);
         otherwise
            fprintf('ERROR: don''t know how to parse rsync log file for decId #%d => exit\n', floatDecId);
            o_inputError = 1;
            return;
      end
   elseif ((floatDecId > 1000) && (floatDecId < 2000))
      % APEX Iridium RUDICS & NAVIS floats
      floatFiles = parse_rsync_log_ir_rudics_apex(ryncLogList{idFile}, floatLoginName);
   end   
   if (~isempty(floatFiles))
      tabFloatSbdFiles = [tabFloatSbdFiles floatFiles];
      tabRsyncLogFiles = [tabRsyncLogFiles repmat(ryncLogList(idFile), size(floatFiles))];
   end
end

g_decArgo_rsyncFloatWmoList = ones(size(tabFloatSbdFiles))*floatWmo;
g_decArgo_rsyncFloatSbdFileList = tabFloatSbdFiles;
g_decArgo_rsyncLogFileUnderProcessList = ryncLogList;
g_decArgo_rsyncLogFileUsedList = tabRsyncLogFiles;

% if there is no mail files to process, save now the list of already processed
% rsync lo files in the temp directory of the float
if (isempty(tabFloatSbdFiles))
   write_processed_rsync_log_file_ir_rudics_sbd_sbd2(floatWmo, 'processed', ...
      g_decArgo_rsyncLogFileUnderProcessList);
end

% output data
o_floatList = unique(g_decArgo_rsyncFloatWmoList);

return;
