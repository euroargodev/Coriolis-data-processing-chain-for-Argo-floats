% ------------------------------------------------------------------------------
% Set DOXY_QC = '3' on DOXY parameter when in DM.
%
% SYNTAX :
%   nc_set_doxy_qc_to_dm_file or nc_set_doxy_qc_to_dm_file(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : - WMO number of floats to process
%              - if no input parameters, the floats of FLOAT_LIST_FILE_NAME file
%                are processed
%              - if FLOAT_LIST_FILE_NAME = '' the floats of the
%                DIR_INPUT_NC_FILES directory are processed
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2020 - RNU - creation
% ------------------------------------------------------------------------------
function nc_set_doxy_qc_to_dm_file(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - START
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% only to check or to do the job
DO_IT = 1;

% top directory of the input NetCDF files
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo\';
% DIR_INPUT_NC_FILES = 'E:\202002-ArgoData\coriolis\';

% default list of floats to convert (should be set to '' if we want to process
% all the floats of the DIR_INPUT_NC_FILES directory)
FLOAT_LIST_FILE_NAME = ''; % process all the floats of the DIR_INPUT_NC_FILES directory
% FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\tmp.txt';

% top directory of the output NetCDF files (should be set to '' if we want to
% update the existing files)
DIR_OUTPUT_NC_FILES = ''; % update existing files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\nc_output_decArgo_rtqc\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION - END
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% program version
global g_cosq_setDoxyQcToDmVersion;
g_cosq_setDoxyQcToDmVersion = '1.0';

% default values initialization
init_default_values;

% DOM node of XML report
global g_cosq_xmlReportDOMNode;

% report information structure
global g_cosq_floatNum;
global g_cosq_reportData;
g_cosq_reportData = [];
g_cosq_reportData.float = [];
g_cosq_reportData.monoProfFile = [];

% update or not the files
global g_cosq_doItFlag;
g_cosq_doItFlag = DO_IT;


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% startTime
ticStartTime = tic;

try
   
   % init the XML report
   init_xml_report(currentTime);
   
   floatList = [];
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         
         floatListFileName = FLOAT_LIST_FILE_NAME;
         
         % floats to process come from floatListFileName
         if ~(exist(floatListFileName, 'file') == 2)
            fprintf('ERROR: File not found: %s\n', floatListFileName);
            return
         end
         
         fprintf('Floats from list: %s\n', floatListFileName);
         floatList = load(floatListFileName);
      end
   else
      % floats to process come from input parameters
      floatList = cell2mat(varargin);
   end
   
   if (isempty(floatList))
      % process floats encountered in the DIR_INPUT_NC_FILES directory
      
      floatDirs = dir(DIR_INPUT_NC_FILES);
      for idDir = 1:length(floatDirs)
         
         floatDirName = floatDirs(idDir).name;
         floatDirPathName = [DIR_INPUT_NC_FILES '/' floatDirName];
         if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
            floatList = [floatList str2num(floatDirName)];
         end
      end
   end
   
   % create and start log file recording
   name = '';
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         [pathstr, name, ext] = fileparts(floatListFileName);
         name = ['_' name];
      end
   else
      name = sprintf('_%d', floatList);
   end
   
   logFile = [DIR_LOG_FILE '/' 'nc_set_doxy_qc_to_dm_file' name '_' currentTime '.log'];
   diary(logFile);
   tic;
   
   fprintf('PARAMETERS:\n');
   if (g_cosq_doItFlag == 0)
      fprintf('   This run is ONLY FOR CHECK (no file will be updated): DO_IT = %d\n', DO_IT);
   end
   fprintf('   Input files directory: DIR_INPUT_NC_FILES = ''%s''\n', DIR_INPUT_NC_FILES);
   if (isempty(DIR_OUTPUT_NC_FILES))
      fprintf('   Output files directory: DIR_OUTPUT_NC_FILES = DIR_INPUT_NC_FILES i.e. THE INPUT FILES WILL BE UPDATED\n');
   else
      fprintf('   Output files directory: DIR_OUTPUT_NC_FILES = ''%s''\n', DIR_OUTPUT_NC_FILES);
   end
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         fprintf('   Floats to process: %d floats of the list FLOAT_LIST_FILE_NAME = ''%s''\n', length(floatList), FLOAT_LIST_FILE_NAME);
      else
         fprintf('   Floats to process: %d floats of the directory DIR_INPUT_NC_FILES = ''%s''\n', length(floatList), DIR_INPUT_NC_FILES);
      end
   else
      fprintf('   Floats to process:');
      fprintf(' %d', floatList);
      fprintf('\n');
   end
   fprintf('   Log file directory: DIR_LOG_FILE = ''%s''\n', DIR_LOG_FILE);
   fprintf('   Xml file directory: DIR_XML_FILE = ''%s''\n', DIR_XML_FILE);
   fprintf('\n');
   
   % update existing files flag
   updateFiles = 0;
   if (isempty(DIR_OUTPUT_NC_FILES))
      updateFiles = 1;
   end
   
   % create output directory
   if (updateFiles == 0)
      if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
         if (g_cosq_doItFlag == 1)
            mkdir(DIR_OUTPUT_NC_FILES);
         end
      end
   end
   
   % process the floats
   nbFloats = length(floatList);
   for idFloat = 1:nbFloats
      
      floatNum = floatList(idFloat);
      g_cosq_floatNum = floatNum;
      floatNumStr = num2str(floatNum);
      fprintf('%03d/%03d %s\n', idFloat, nbFloats, floatNumStr);
      
      ncInputFileDir = [DIR_INPUT_NC_FILES '/' num2str(floatNum) '/'];
      
      if (exist(ncInputFileDir, 'dir') == 7)
         
         % create output directory
         if (updateFiles == 0)
            ncOutputFileDir = [DIR_OUTPUT_NC_FILES '/' num2str(floatNum) '/'];
            if ~(exist(ncOutputFileDir, 'dir') == 7)
               if (g_cosq_doItFlag == 1)
                  mkdir(ncOutputFileDir);
               end
            end
         end
         
         % process mono-profile files
         ncInputFileDir = [ncInputFileDir '/profiles/'];
         
         if (exist(ncInputFileDir, 'dir') == 7)
            
            % create output directory
            if (updateFiles == 0)
               ncOutputFileDir = [ncOutputFileDir '/profiles/'];
               if ~(exist(ncOutputFileDir, 'dir') == 7)
                  if (g_cosq_doItFlag == 1)
                     mkdir(ncOutputFileDir);
                  end
               end
            end
            
            ncInputFiles = dir([ncInputFileDir 'BD*.nc']);
            for idFile = 1:length(ncInputFiles)
               
               monoProfInputFileName = ncInputFiles(idFile).name;
               monoProfInputFilePathName = [ncInputFileDir '/' monoProfInputFileName];
               monoProfOutputFilePathName = '';
               if (updateFiles == 0)
                  monoProfOutputFilePathName = [ncOutputFileDir '/' monoProfInputFileName];
               end
               
               fprintf('%s\n', monoProfInputFileName);
               
               % process current file
               [modifiedFileFlag, tmpOutputFileName] = set_do_qc_to_profile_file(monoProfInputFilePathName);
               
               if (modifiedFileFlag == 1)
                  
                  [monoProfOutputPath, ~, ~] = fileparts(monoProfOutputFilePathName);
                  [~, fileName, fileExtension] = fileparts(tmpOutputFileName);
                  if (g_cosq_doItFlag == 1)
                     move_file(tmpOutputFileName, [monoProfOutputPath '/' fileName fileExtension]);
                  end
                  
                  % store the information for the XML report
                  g_cosq_reportData.float = [g_cosq_reportData.float g_cosq_floatNum];
                  g_cosq_reportData.monoProfFile = [g_cosq_reportData.monoProfFile {[monoProfOutputPath '/' fileName fileExtension]}];
               end
            end
         else
            fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
         end
      else
         fprintf('WARNING: Directory not found: %s\n', ncInputFileDir);
      end
   end
   
   ellapsedTime = toc;
   fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, []);
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, lasterror);
   
end

% create the XML report path file name
xmlFileName = [DIR_XML_FILE '/' 'nc_set_doxy_qc_to_dm_file' name '_' currentTime '.xml'];

% save the XML report
xmlwrite(xmlFileName, g_cosq_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Set DOXY_QC = '3' on DOXY parameter when in DM.
%
% SYNTAX :
%  [o_modifiedFileFlag, o_profOutputFileName] = set_do_qc_to_profile_file(a_profInputFileName)
%
% INPUT PARAMETERS :
%   a_profInputFileName : input NetCDF file name
%
% OUTPUT PARAMETERS :
%   o_modifiedFileFlag   : 1 if the file has been modified, 0 otherwise
%   o_profOutputFileName : output NetCDF file name
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/24/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_modifiedFileFlag, o_profOutputFileName] = set_do_qc_to_profile_file(a_profInputFileName)
   
% output parameters initialization
o_modifiedFileFlag = 0;
o_profOutputFileName = '';
   
% QC flag values
global g_decArgo_qcStrGood;          % '1'
global g_decArgo_qcStrProbablyGood;  % '2'
global g_decArgo_qcStrCorrectable;   % '3'

% program version
global g_cosq_setDoxyQcToDmVersion;


% check if the file needs to be updated

doParamList = [ ...
   {'DOXY'} ...
   {'DOXY2'} ...
   ];

% retrieve data from profile file
wantedVars = [ ...
   {'DATE_CREATION'} ...
   {'STATION_PARAMETERS'} ...
   {'PARAMETER_DATA_MODE'} ...
   ];
[ncProfData] = get_data_from_nc_file(a_profInputFileName, wantedVars);

stationParameters = get_data_from_name('STATION_PARAMETERS', ncProfData);
parameterDataMode = get_data_from_name('PARAMETER_DATA_MODE', ncProfData)';

[~, nParam, nProf] = size(stationParameters);
profIdList = [];
for idProf = 1:nProf
   for idParam = 1:nParam
      paramName = deblank(stationParameters(:, idParam, idProf)');
      if (~isempty(paramName))
         if (ismember(paramName, doParamList))
            if (parameterDataMode(idProf, idParam) == 'D')
               profIdList = [profIdList idProf];
            end
         end
      end
   end
end

% update the file
if (~isempty(profIdList))
   
   % directory to store temporary files
   [profInputPath, ~, ~] = fileparts(a_profInputFileName);
   DIR_TMP_FILE = [profInputPath '/../tmp/'];
   
   % delete the temp directory
   remove_directory(DIR_TMP_FILE);
   
   % create the temp directory
   mkdir(DIR_TMP_FILE);
   
   % make a copy of the input mono profile file to be updated
   [~, fileName, fileExtension] = fileparts(a_profInputFileName);
   tmpProfOutputFileName = [DIR_TMP_FILE '/' fileName fileExtension];
   copy_file(a_profInputFileName, tmpProfOutputFileName);
   
   % open the file to update
   fCdf = netcdf.open(tmpProfOutputFileName, 'NC_WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF file: %s\n', tmpProfOutputFileName);
      return
   end
   
   o_modifiedFileFlag = 0;
   modifiedProfId = [];
   for idProf = profIdList
      for idParam = 1:nParam
         paramName = deblank(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            if (ismember(paramName, doParamList))
               if (parameterDataMode(idProf, idParam) == 'D')

                  dataQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, [paramName '_QC']));
                  idToSet = find((dataQc(:, idProf) == g_decArgo_qcStrGood) | (dataQc(:, idProf) == g_decArgo_qcStrProbablyGood));
                  if (~isempty(idToSet))
                     dataQc(idToSet, idProf) = g_decArgo_qcStrCorrectable;
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, [paramName '_QC']), dataQc);
                     o_modifiedFileFlag = 1;
                     modifiedProfId = [modifiedProfId idProf];
                  end
               end
            end
         end
      end
   end
   
   if (o_modifiedFileFlag == 1)
   
      % update miscellaneous information
      
      % date of the file update
      dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');
      
      % retrieve the creation date of the file
      dateCreation = get_data_from_name('DATE_CREATION', ncProfData)';
      if (isempty(deblank(dateCreation)))
         dateCreation = dateUpdate;
      end
      
      % set the 'history' global attribute
      globalVarId = netcdf.getConstant('NC_GLOBAL');
      globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
      globalHistoryText = [globalHistoryText ...
         datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COSQ software)'];
      netcdf.reDef(fCdf);
      netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
      netcdf.endDef(fCdf);
      
      % upate date
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);
      
      % update history information
      historyInstitution = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'));
      [~, ~, nHistory] = size(historyInstitution);
      histoInstitution = 'IF';
      histoSoftware = 'COSQ';
      histoSoftwareRelease = g_cosq_setDoxyQcToDmVersion;
      
      for idProf = 1:length(modifiedProfId)
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
            fliplr([nHistory modifiedProfId(idProf)-1 0]), ...
            fliplr([1 1 length(histoInstitution)]), histoInstitution');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
            fliplr([nHistory modifiedProfId(idProf)-1 0]), ...
            fliplr([1 1 length(histoSoftware)]), histoSoftware');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
            fliplr([nHistory modifiedProfId(idProf)-1 0]), ...
            fliplr([1 1 length(histoSoftwareRelease)]), histoSoftwareRelease');
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
            fliplr([nHistory modifiedProfId(idProf)-1 0]), ...
            fliplr([1 1 length(dateUpdate)]), dateUpdate');
      end
      
      o_profOutputFileName = tmpProfOutputFileName;
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Retrieve data from NetCDF file.
%
% SYNTAX :
%  [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : NetCDF variables to retrieve from the file
%
% OUTPUT PARAMETERS :
%   o_ncData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/15/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncData] = get_data_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Get data from name in a {name}/{data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {name}/{data} list
%
% OUTPUT PARAMETERS :
%   o_dataValues : concerned data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   01/21/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{idVal+1};
end

return

% ------------------------------------------------------------------------------
% Initialize XML report.
%
% SYNTAX :
%  init_xml_report(a_time)
%
% INPUT PARAMETERS :
%   a_time : start date of the run ('yyyymmddTHHMMSS' format)
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cosq_xmlReportDOMNode;

% decoder version
global g_cosq_setDoxyQcToDmVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

% newChild = docNode.createElement('function');
% newChild.appendChild(docNode.createTextNode('co041405 '));
% docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis set DOXY_QC in DM file tool (nc_set_doxy_qc_to_dm_file)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cosq_setDoxyQcToDmVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cosq_xmlReportDOMNode = docNode;

return

% ------------------------------------------------------------------------------
% Finalize the XML report.
%
% SYNTAX :
%  [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)
%
% INPUT PARAMETERS :
%   a_ticStartTime : identifier for the "tic" command
%   a_logFileName  : log file path name of the run
%   a_error        : Matlab error
%
% OUTPUT PARAMETERS :
%   o_status : final status of the run
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   06/22/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cosq_xmlReportDOMNode;

% report information structure
global g_cosq_reportData;

% update or not the files
global g_cosq_doItFlag;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cosq_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

if (g_cosq_doItFlag == 1)
   newChild = docNode.createElement('updates');
else
   newChild = docNode.createElement('needed_updates');
end

if (g_cosq_doItFlag == 1)
   newChildBis = docNode.createElement('updated_float_WMO_list');
else
   newChildBis = docNode.createElement('to_be_updated_float_WMO_list');
end
if (isfield(g_cosq_reportData, 'float'))
   wmoList = sort(unique(g_cosq_reportData.float));
   newChildBis.appendChild(docNode.createTextNode(sprintf('%d ', wmoList)));
else
   newChildBis.appendChild(docNode.createTextNode(''));
end
newChild.appendChild(newChildBis);

% list of updated files
if (isfield(g_cosq_reportData, 'monoProfFile'))
   for idFile = 1:length(g_cosq_reportData.monoProfFile)
      if (g_cosq_doItFlag == 1)
         newChildBis = docNode.createElement('updated_mono_profile_file');
      else
         newChildBis = docNode.createElement('to_be_updated_mono_profile_file');
      end
      textNode = g_cosq_reportData.monoProfFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end

docRootNode.appendChild(newChild);

% retrieve information from the log file
[infoMsg, warningMsg, errorMsg] = parse_log_file(a_logFileName);

if (~isempty(infoMsg))
   
   for idMsg = 1:length(infoMsg)
      newChild = docNode.createElement('info');
      textNode = infoMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(warningMsg))
   
   for idMsg = 1:length(warningMsg)
      newChild = docNode.createElement('warning');
      textNode = warningMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(errorMsg))
   
   for idMsg = 1:length(errorMsg)
      newChild = docNode.createElement('error');
      textNode = errorMsg{idMsg};
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
   o_status = 'nok';
end

% add matlab error
if (~isempty(a_error))
   o_status = 'nok';
   
   newChild = docNode.createElement('matlab_error');
   
   newChildBis = docNode.createElement('error_message');
   textNode = regexprep(a_error.message, char(10), ': ');
   newChildBis.appendChild(docNode.createTextNode(textNode));
   newChild.appendChild(newChildBis);
   
   for idS = 1:size(a_error.stack, 1)
      newChildBis = docNode.createElement('stack_line');
      textNode = sprintf('Line: %3d File: %s (func: %s)', ...
         a_error.stack(idS). line, ...
         a_error.stack(idS). file, ...
         a_error.stack(idS). name);
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   docRootNode.appendChild(newChild);
end

newChild = docNode.createElement('duration');
newChild.appendChild(docNode.createTextNode(format_time(toc(a_ticStartTime)/3600)));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('status');
newChild.appendChild(docNode.createTextNode(o_status));
docRootNode.appendChild(newChild);

return

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_decInfoMsg     : DECODER INFO messages
%   o_decWarningMsg  : DECODER WARNING messages
%   o_decErrorMsg    : DECODER ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_decInfoMsg = [];
o_decWarningMsg = [];
o_decErrorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      if (~isempty(fileContents))
         idLine = 1;
         while (1)
            line = fileContents{idLine};
            if (strncmpi(line, 'INFO:', length('INFO:')))
               o_decInfoMsg = [o_decInfoMsg {strtrim(line(length('INFO:')+1:end))}];
            elseif (strncmpi(line, 'WARNING:', length('WARNING:')))
               o_decWarningMsg = [o_decWarningMsg {strtrim(line(length('WARNING:')+1:end))}];
            elseif (strncmpi(line, 'ERROR:', length('ERROR:')))
               o_decErrorMsg = [o_decErrorMsg {strtrim(line(length('ERROR:')+1:end))}];
            end
            idLine = idLine + 1;
            if (idLine > length(fileContents))
               break
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Duration format.
%
% SYNTAX :
%   [o_time] = format_time(a_time)
%
% INPUT PARAMETERS :
%   a_time : hour (in float)
%
% OUTPUT PARAMETERS :
%   o_time : formated duration
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_time] = format_time(a_time)

% output parameters initialization
o_time = [];

if (a_time >= 0)
   sign = '';
else
   sign = '-';
end
a_time = abs(a_time);
h = fix(a_time);
m = fix((a_time-h)*60);
s = round(((a_time-h)*60-m)*60);
if (s == 60)
   s = 0;
   m = m + 1;
   if (m == 60)
      m = 0;
      h = h + 1;
   end
end
if (isempty(sign))
   o_time = sprintf('%02d:%02d:%02d', h, m, s);
else
   o_time = sprintf('%c %02d:%02d:%02d', sign, h, m, s);
end

return
