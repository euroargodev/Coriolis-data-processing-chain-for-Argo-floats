% ------------------------------------------------------------------------------
% Parse input parameters and, for each SBD file to process, create the list of
% associated float WMO number, float Imei and SBD file name.
%
% SYNTAX :
%  [o_floatList, o_inputError] = ...
%    parse_input_param_iridium_sbd2_rt(a_varargin)
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
%   12/02/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_floatList, o_inputError] = ...
   parse_input_param_iridium_sbd2_rt(a_varargin)

% output parameters initialization
o_floatList = [];
o_inputError = 0;

% global configuration values
global g_decArgo_floatListFileName;
global g_decArgo_dirInputRsyncLog;
global g_decArgo_dirInputJsonFloatDecodingParametersFile;
global g_decArgo_iridiumDataDirectory;

% SBD sub-directory
global g_decArgo_tmpDirectory;

% rsync information
global g_decArgo_rsyncFloatWmoList;
global g_decArgo_rsyncFloatLoginNameList;
global g_decArgo_rsyncFloatSbdFileList;

% already processed rsync log information
global g_decArgo_floatWmoUnderProcessList;
global g_decArgo_rsyncLogFileUnderProcessList;

% DOM node of XML report
global g_decArgo_xmlReportDOMNode;

% default values
global g_decArgo_janFirst1950InMatlab;
global g_decArgo_dateDef;


% check input parameters
rsyncLogInputParam = 0;
allRsyncLogFlag = 0;
rsyncLogFile = [];
floatWmo = [];
floatWmoList = [];
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

% check mandatory input parameter
if (rsyncLogInputParam == 0)
   fprintf('ERROR: ''rsynclog'' input param is mandatory => exit\n');
   o_inputError = 1;
   return;
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
elseif (allRsyncLogFlag == 1)
   if ~(exist(g_decArgo_dirInputRsyncLog, 'dir') == 7)
      fprintf('ERROR: rsync log file directory (%s) does not exist => exit\n', g_decArgo_dirInputRsyncLog);
      o_inputError = 1;
      return;
   end
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

% parse rsync log files
ryncParamFlag = 1;
ryncLogList = [];
if (allRsyncLogFlag == 1)
   [ryncLogList] = get_rsync_log_dir_file_names_ir_rudics(g_decArgo_dirInputRsyncLog);
elseif (~isempty(rsyncLogPathFile))
   ryncLogList{end+1} = rsyncLogPathFile;
else
   ryncParamFlag = 0;
end

tabFloatImei = [];
tabFloatSbdFiles = [];
tabRsyncLogFiles = [];
if (ryncParamFlag == 1)
   if (~isempty(ryncLogList))
      for idFloat = 1:length(ryncLogList)
         [floatImei, floatSbdFiles, rsyncLogName] = parse_rsync_log_ir_sbd2(ryncLogList{idFloat});
         tabFloatImei = [tabFloatImei floatImei];
         tabFloatSbdFiles = [tabFloatSbdFiles floatSbdFiles];
         tabRsyncLogFiles = [tabRsyncLogFiles rsyncLogName];
      end
   end
   tabFloatWmoList = ones(length(tabFloatImei), 1)*-1;
else
   tabFloatWmoList = floatList;
end

% filter the tabFloatImei and tabFloatSbdFiles according to float list
uFloatImei = unique(tabFloatImei);
for idFloat = 1:length(uFloatImei)
   % find the corresponding float wmo number in the name of the json info file
   floatInfoFileNames = dir([g_decArgo_dirInputJsonFloatDecodingParametersFile '/' ...
      sprintf('*_%s_info.json', uFloatImei{idFloat})]);
   
   if (length(floatInfoFileNames) == 1)
      
      jsonFile = floatInfoFileNames(1).name;
      idF = strfind(jsonFile, '_');
      floatNum = str2num(jsonFile(1:idF(1)-1));

      if (~isempty(find(floatList == floatNum, 1)))
         idEq = find(strcmp(tabFloatImei, uFloatImei{idFloat}) == 1);
         tabFloatWmoList(idEq) = floatNum;
      end
   else
      
      for idInfoFile = 1:length(floatInfoFileNames)
         
         jsonFile = floatInfoFileNames(idInfoFile).name;
         idF = strfind(jsonFile, '_');
         floatNum = str2num(jsonFile(1:idF(1)-1));
         
         if (~isempty(find(floatList == floatNum, 1)))
            
            [floatNum, floatArgosId, ...
               floatDecVersion, floatDecId, ...
               floatFrameLen, ...
               floatCycleTime, floatDriftSamplingPeriod, floatDelay, ...
               floatLaunchDate, floatLaunchLon, floatLaunchLat, ...
               floatRefDay, floatEndDate, floatDmFlag] = get_one_float_info(floatNum, []);
      
            idEq = find(strcmp(tabFloatImei, uFloatImei{idFloat}) == 1);
            for idFile = 1:length(idEq)
               
               fileName = tabFloatSbdFiles{idEq(idFile)};
               idF = strfind(fileName, '/');
               fileName = fileName(idF+1:end);
               fileDate = datenum([fileName(4:11) fileName(13:18)], 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
               
               if (((floatEndDate == g_decArgo_dateDef) && (fileDate >= floatLaunchDate)) || ...
                     ((floatEndDate ~= g_decArgo_dateDef) && (fileDate >= floatLaunchDate) && (fileDate <= floatEndDate)))
                  
                  % the current float is concerned by this file
                  tabFloatWmoList(idEq(idFile)) = floatNum;
               end
            end
         end
      end
   end
end
idDel = find(tabFloatWmoList == -1);
tabFloatImei(idDel) = [];
tabFloatSbdFiles(idDel) = [];
tabRsyncLogFiles(idDel) = [];
tabFloatWmoList(idDel) = [];   

% filter the tabFloatImei and tabFloatSbdFiles according to rsync log
% already processed
uFloatWmo = unique(tabFloatWmoList);
tabFloatWmoUnderProcessList = [];
tabRsyncLogFileUnderProcessList = [];
if (~isempty(tabFloatImei))
   for idFloat = 1:length(uFloatWmo)
      floatNum = uFloatWmo(idFloat);
      floatImei = tabFloatImei(find(tabFloatWmoList == floatNum, 1));
      floatImei = floatImei{:};
      
      % create the float directory
      floatIriDirName = [g_decArgo_iridiumDataDirectory '/' floatImei '_' num2str(floatNum) '/'];
      if ~(exist(floatIriDirName, 'dir') == 7)
         mkdir(floatIriDirName);
      end
      % create the float tmp directory
      g_decArgo_tmpDirectory = [floatIriDirName 'mat/'];
      if ~(exist(g_decArgo_tmpDirectory, 'dir') == 7)
         mkdir(g_decArgo_tmpDirectory);
      end
      
      % get the list of the rsync log already processed for this float
      [rsyncDoneLogList] = read_processed_rsync_log_file_ir_rudics_sbd_sbd2(floatNum);
      
      for idFile = 1:length(rsyncDoneLogList)
         % do not consider the SBD files already processed
         idEq = find((tabFloatWmoList == floatNum) & ...
            (strcmp(tabRsyncLogFiles, rsyncDoneLogList(idFile)) == 1)');
         tabFloatImei(idEq) = [];
         tabFloatSbdFiles(idEq) = [];
         tabRsyncLogFiles(idEq) = [];
         tabFloatWmoList(idEq) = [];
      end
      
      % update the list of the rsync log already processed for this float
      idEq = find(tabFloatWmoList == floatNum);
      tabFloatWmoUnderProcessList(end+1) = floatNum;
      tabRsyncLogFileUnderProcessList{end+1} = unique(tabRsyncLogFiles(idEq));
      %    write_processed_rsync_log_file_ir_rudics_sbd2(floatNum, unique(tabRsyncLogFiles(idEq)));
   end
end

g_decArgo_rsyncFloatWmoList = tabFloatWmoList;
g_decArgo_rsyncFloatLoginNameList = tabFloatImei;
g_decArgo_rsyncFloatSbdFileList = tabFloatSbdFiles;
g_decArgo_floatWmoUnderProcessList = tabFloatWmoUnderProcessList;
g_decArgo_rsyncLogFileUnderProcessList = tabRsyncLogFileUnderProcessList;

% output data
o_floatList = unique(g_decArgo_rsyncFloatWmoList);

return;
