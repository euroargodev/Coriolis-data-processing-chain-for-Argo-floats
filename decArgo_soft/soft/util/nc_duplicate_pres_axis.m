% ------------------------------------------------------------------------------
% Duplicate PRES axis from C profile file to B profile file.
%
% SYNTAX :
%   nc_duplicate_pres_axis or 
%   nc_duplicate_pres_axis(6900189, 7900118)
%
% INPUT PARAMETERS :
%   varargin : WMO number of floats to process
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/16/2017 - RNU - V 1.0: creation
% ------------------------------------------------------------------------------
function nc_duplicate_pres_axis(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of NetCDF files to update
% (expected path to NetCDF files: DIR_INPUT_OUTPUT_NC_FILES\dac_name\wmo_number)
DIR_INPUT_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\TEST_nc_duplicate_pres_axis\';
% DIR_INPUT_OUTPUT_NC_FILES = 'H:\archive_201705\';

% temporary directory used to update the files
DIR_TMP = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\temp_nc_duplicate_pres_axis\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% to print files that should be updated
INFO_ONLY = 0;

% INFO or ACTION flag
global g_codp_infoOnly;
g_codp_infoOnly = INFO_ONLY;

% program version
global g_codp_ncDuplicatePresAxisVersion;
g_codp_ncDuplicatePresAxisVersion = '1.0';

% DOM node of XML report
global g_codp_xmlReportDOMNode;

% report information structure
global g_codp_floatNum;
global g_codp_reportData;
g_codp_reportData = [];
g_codp_reportData.trajFile = [];
g_codp_reportData.mProfFil = [];
g_codp_reportData.profFile = [];
g_codp_reportData.float = [];


% store the start time of the run
currentTime = datestr(now, 'yyyymmddTHHMMSSZ');

% startTime
ticStartTime = tic;

try
   
   % init the XML report
   init_xml_report(currentTime);
   
   % input parameters management
   floatList = [];
   if (nargin == 0)
      if (~isempty(FLOAT_LIST_FILE_NAME))
         floatListFileName = FLOAT_LIST_FILE_NAME;
         
         % floats to process come from floatListFileName
         if ~(exist(floatListFileName, 'file') == 2)
            fprintf('ERROR: File not found: %s\n', floatListFileName);
            return;
         end
         
         fprintf('Floats from list: %s\n', floatListFileName);
         floatList = load(floatListFileName);
      end
   else
      % floats to process come from input parameters
      floatList = cell2mat(varargin);
   end
   
   
   % create a temporary directory for this run
   tmpDir = [DIR_TMP '/' 'nc_duplicate_pres_axis_' currentTime];
   status = mkdir(tmpDir);
   if (status ~= 1)
      fprintf('ERROR: cannot create temporary directory (%s)\n', tmpDir);
   end
   
   % create and start log file recording
   logFile = [DIR_LOG_FILE '/' 'nc_duplicate_pres_axis_' currentTime '.log'];
   diary(logFile);
   
   dacDir = dir(DIR_INPUT_OUTPUT_NC_FILES);
   for idDir = 1:length(dacDir)
      
      dacDirName = dacDir(idDir).name;
      dacDirPathName = [DIR_INPUT_OUTPUT_NC_FILES '/' dacDirName];
      if ((exist(dacDirPathName, 'dir') == 7) && ~strcmp(dacDirName, '.') && ~strcmp(dacDirName, '..'))
         
         fprintf('\nProcessing directory: %s\n', dacDirName);
         
         floatNum = 1;
         floatDir = dir(dacDirPathName);
         for idDir2 = 1:length(floatDir)
            
            floatDirName = floatDir(idDir2).name;
            floatDirPathName = [dacDirPathName '/' floatDirName];
            if ((exist(floatDirPathName, 'dir') == 7) && ~strcmp(floatDirName, '.') && ~strcmp(floatDirName, '..'))
               
               [floatWmo, status] = str2num(floatDirName);
               if (status == 1)
                  
                  if ((isempty(floatList)) || (~isempty(floatList) && ismember(floatWmo, floatList)))
                     
                     g_codp_floatNum = floatWmo;
                     fprintf('%03d/%03d %d\n', floatNum, length(floatDir)-2, floatWmo);
                                          
                     % mono-profile files
                     floatDirPathName = [floatDirPathName '/profiles'];
                     if (exist(floatDirPathName, 'dir') == 7)
                        floatFiles = dir([floatDirPathName '/' sprintf('B*%d_*.nc', floatWmo)]);
                        for idFile = 1:length(floatFiles)
                           
                           floatFileName = floatFiles(idFile).name;
                           floatFilePathName = [floatDirPathName '/' floatFileName];
                           if (exist(floatFilePathName, 'file') == 2)
                              process_nc_file(floatFilePathName, tmpDir);
                           end
                        end
                     end
                     
                     floatNum = floatNum + 1;
                  end
               end
            end
         end
      end
   end
   
   % remove the temporary directory of this run
   [status, message, messageid] = rmdir(tmpDir,'s');
   if (status ~= 1)
      fprintf('ERROR: cannot remove temporary directory (%s)\n', tmpDir);
   end
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, []);
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFile, lasterror);
   
end

% create the XML report path file name
xmlFileName = [DIR_XML_FILE '/nc_duplicate_pres_axis_' currentTime '.xml'];

% save the XML report
xmlwrite(xmlFileName, g_codp_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return;

% ------------------------------------------------------------------------------
% Process one NetCDF file.
%
% SYNTAX :
%  process_nc_file(a_ncPathFileName, a_tmpDir)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : name of the file to process
%   a_tmpDir         : available temporary directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_ncBPathFileName, a_tmpDir)

% report information structure
global g_codp_floatNum;
global g_codp_reportData;

% INFO or ACTION flag
global g_codp_infoOnly;


if (exist(a_ncBPathFileName, 'file') == 2)
   
   % get information to see if the file should be updated
   updateNeeded = 0;
   needToInvestigate = 0;
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      {'PRES'} ...
      ];
   [ncDataB] = get_data_from_nc_file(a_ncBPathFileName, wantedInputVars);
   if (~isempty(ncDataB))
      
      idVal = find(strcmp('FORMAT_VERSION', ncDataB(1:2:end)) == 1, 1);
      formatVersion = strtrim(ncDataB{2*idVal}');
      if (strcmp(formatVersion, '3.1'))
         
         idVal = find(strcmp('PRES', ncDataB(1:2:end)) == 1, 1);
         presData = ncDataB{2*idVal};
         if (~isempty(presData))
            
            n_prof = size(presData, 2);
            for idP = 1:n_prof
               presProf = presData(:, idP);
               if (~any(presProf ~= 99999))
                  needToInvestigate = 1;
                  break;
               end
            end
         end
      end
   end
   
   if (needToInvestigate)
      
      [filePath, bFileName, ext] = fileparts(a_ncBPathFileName);
      cFileName = ['D' bFileName(3:end)]; % use D file first (R and D files can be (erroneously) present)
      ncCPathFileName = [filePath '/' cFileName ext];
      if ~(exist(ncCPathFileName, 'file') == 2)
         cFileName = ['R' bFileName(3:end)];
      end
      ncCPathFileName = [filePath '/' cFileName ext];
      
      if (exist(ncCPathFileName, 'file') == 2)
         
         [ncDataC] = get_data_from_nc_file(ncCPathFileName, wantedInputVars);
         if (~isempty(ncDataC))
            
            idVal = find(strcmp('FORMAT_VERSION', ncDataC(1:2:end)) == 1, 1);
            formatVersion = strtrim(ncDataC{2*idVal}');
            if (strcmp(formatVersion, '3.1'))
               
               idVal = find(strcmp('PRES', ncDataC(1:2:end)) == 1, 1);
               presDataC = ncDataC{2*idVal};
               idVal = find(strcmp('PRES', ncDataB(1:2:end)) == 1, 1);
               presDataB = ncDataB{2*idVal};
                  
               n_levelsC = size(presDataC, 1);
               n_LevelsB = size(presDataB, 1);
               if (n_levelsC ~= n_LevelsB)
                  fprintf('ERROR: file %s: N_LEVELS differ (C file: %d VS B file: %d)\n', [bFileName ext], n_LevelsB, n_levelsC);
                  return;
               end
               n_prof = size(presDataC, 2);
               for idP = 1:n_prof
                  presProfC = presDataC(:, idP);
                  presProfB = presDataB(:, idP);
                  if (any(presProfC ~= 99999) && ~any(presProfB ~= 99999))
                     updateNeeded = 1;
                     if (g_codp_infoOnly)
                        fprintf('INFO: file %s PRES profile #%d need to be duplicated ', [bFileName ext], idP);
                        if (n_levelsC == n_LevelsB)
                           fprintf('no need to update N_LEVELS\n');
                        else
                           fprintf('N_LEVELS should be updated (%d => %d)\n', n_LevelsB, n_levelsC);
                        end
                     else
                        break;
                     end
                  end
               end
            end
         end
      else
         fprintf('ERROR: cannot find file: %s\n', ncCPathFileName);
      end
   end
   
   if ((g_codp_infoOnly) && (updateNeeded == 0))
   
      [filePath, bFileName, ext] = fileparts(a_ncBPathFileName);
      if (bFileName(1) == 'B')
         % mono-profile file
         cFileName = ['D' bFileName(3:end)]; % use D file first (R and D files can be (erroneously) present)
         ncCPathFileName = [filePath '/' cFileName ext];
         if ~(exist(ncCPathFileName, 'file') == 2)
            cFileName = ['R' bFileName(3:end)];
         end
      else
         % multi-profile file
         cFileName = regexprep(bFileName, '_Bprof', '_prof');
      end
      ncCPathFileName = [filePath '/' cFileName ext];
      if (exist(ncCPathFileName, 'file') == 2)
         
         [ncDataC] = get_data_from_nc_file(ncCPathFileName, wantedInputVars);
         if (~isempty(ncDataC))
            
            idVal = find(strcmp('FORMAT_VERSION', ncDataC(1:2:end)) == 1, 1);
            formatVersion = strtrim(ncDataC{2*idVal}');
            if (strcmp(formatVersion, '3.1'))
               
               idVal = find(strcmp('PRES', ncDataC(1:2:end)) == 1, 1);
               presDataC = ncDataC{2*idVal};
               idVal = find(strcmp('PRES', ncDataB(1:2:end)) == 1, 1);
               presDataB = ncDataB{2*idVal};
               
               if (sum(presDataC-presDataB) ~= 0)
                  fprintf('WARNING: file %s PRES values differ', [bFileName ext]);
               end
            end
         end
      end
   end
   
   % update the file
   if (updateNeeded == 1)
      
      if (g_codp_infoOnly)
         fprintf('\n');
      else
         fprintf('File to update: %s\n', a_ncBPathFileName);
         
         % make a copy of the file in the temporary directory
         [~, fileName, fileExt] = fileparts(a_ncBPathFileName);
         fileToUpdate = [a_tmpDir '/' fileName fileExt];
         [status] = copyfile(a_ncBPathFileName, fileToUpdate);
         if (status == 1)
            
            % update the file
            ok = update_file(fileToUpdate, ncCPathFileName);
            
            if (ok == 1)
               
               % move the updated file
               [status, message, messageid] = movefile(fileToUpdate, a_ncBPathFileName);
               if (status ~= 1)
                  fprintf('ERROR: cannot move file to update (%s) to replace input file (%s)\n', fileToUpdate, a_ncBPathFileName);
                  return;
               end
               
               % store the information for the XML report
               if (any(strfind(fileName, 'prof')))
                  g_codp_reportData.mProfFile = [g_codp_reportData.mProfFile {a_ncBPathFileName}];
               else
                  g_codp_reportData.profFile = [g_codp_reportData.profFile {a_ncBPathFileName}];
               end
               g_codp_reportData.float = [g_codp_reportData.float g_codp_floatNum];
               
            end
         else
            fprintf('ERROR: cannot copy file to update (%s) to temporary directory (%s)\n', a_ncBPathFileName, a_tmpDir);
         end
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Update one NetCDF file.
%
% SYNTAX :
%  [o_ok] = update_file(a_ncBPathFileName, a_ncCPathFileName)
%
% INPUT PARAMETERS :
%   a_ncBPathFileName : name of the B file to update
%   a_ncCPathFileName : name of the C file to use
%
% OUTPUT PARAMETERS :
%   o_ok : 1 if update succeeded, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_file(a_ncBPathFileName, a_ncCPathFileName)

% output parameters initialization
o_ok = 0;

% program version
global g_codp_ncDuplicatePresAxisVersion;


if ((exist(a_ncBPathFileName, 'file') == 2) && (exist(a_ncCPathFileName, 'file') == 2))
   
   % create the list of profiles to be updated
   
   % retrieve PRES values from C file
   wantedInputVars = [ ...
      {'PRES'} ...
      ];
   [ncDataC] = get_data_from_nc_file(a_ncCPathFileName, wantedInputVars);
   idVal = find(strcmp('PRES', ncDataC(1:2:end)) == 1, 1);
   presDataC = ncDataC{2*idVal};
   
   % retrieve PRES values from B file
   [ncDataB] = get_data_from_nc_file(a_ncBPathFileName, wantedInputVars);
   idVal = find(strcmp('PRES', ncDataB(1:2:end)) == 1, 1);
   presDataB = ncDataB{2*idVal};
   
   profList = [];
   for idProf = 1:size(presDataC, 2)
      presProfC = presDataC(:, idProf);
      presProfB = presDataB(:, idProf);
      if (any(presProfC ~= 99999) && ~any(presProfB ~= 99999))
         profList = [profList idProf];
      end
   end
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncBPathFileName, 'WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncBPathFileName);
      return;
   end
   
   % duplicate C file PRES values in B file
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'), presDataC);
   
   % add history information that concerns the current program
   historyInstitution = 'IF';
   historySoftware = 'CODP';
   historySoftwareRelease = g_codp_ncDuplicatePresAxisVersion;
   historyDate = datestr(now_utc, 'yyyymmddHHMMSS');
   
   % update HISTORY_* variables
   
   % retrieve the creation date of the updated file
   dateCreation = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'))');
   
   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(historyDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis CODP software (V ' g_codp_ncDuplicatePresAxisVersion '))'];
   netcdf.reDef(fCdf);
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   netcdf.endDef(fCdf);
   
   % update the update date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), historyDate);
   
   % update HISTORY information for concerned profiles
   [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
   for idP = 1:length(profList)
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([nHistory profList(idP)-1 0]), ...
         fliplr([1 1 length(historyInstitution)]), historyInstitution');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([nHistory profList(idP)-1 0]), ...
         fliplr([1 1 length(historySoftware)]), historySoftware');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([nHistory profList(idP)-1 0]), ...
         fliplr([1 1 length(historySoftwareRelease)]), historySoftwareRelease');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistory profList(idP)-1 0]), ...
         fliplr([1 1 length(historyDate)]), historyDate');
   end
   
   netcdf.close(fCdf);
   
   o_ok = 1;
end

return;

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
%   05/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_codp_xmlReportDOMNode;

% decoder version
global g_codp_ncDuplicatePresAxisVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis duplicate PRES axis tool (nc_duplicate_pres_axis)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_codp_ncDuplicatePresAxisVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_codp_xmlReportDOMNode = docNode;

return;

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
%   05/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_codp_xmlReportDOMNode;

% report information structure
global g_codp_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_codp_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('updates');

newChildBis = docNode.createElement('updated_float_WMO_list');
if (isfield(g_codp_reportData, 'float'))
   wmoList = sort(unique(g_codp_reportData.float));
   newChildBis.appendChild(docNode.createTextNode(sprintf('%d ', wmoList)));
else
   newChildBis.appendChild(docNode.createTextNode(''));
end
newChild.appendChild(newChildBis);

% list of updated files
if (isfield(g_codp_reportData, 'profFile'))
   for idFile = 1:length(g_codp_reportData.profFile)
      newChildBis = docNode.createElement('updated_mono_profile_file');
      textNode = g_codp_reportData.profFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end
if (isfield(g_codp_reportData, 'mProfFil'))
   for idFile = 1:length(g_codp_reportData.mProfFil)
      newChildBis = docNode.createElement('updated_multi_profile_file');
      textNode = g_codp_reportData.mProfFil{idFile};
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
      textNode = char(infoMsg(idMsg));
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(warningMsg))
   
   for idMsg = 1:length(warningMsg)
      newChild = docNode.createElement('warning');
      textNode = char(warningMsg(idMsg));
      newChild.appendChild(docNode.createTextNode(textNode));
      docRootNode.appendChild(newChild);
   end
end

if (~isempty(errorMsg))
   
   for idMsg = 1:length(errorMsg)
      newChild = docNode.createElement('error');
      textNode = char(errorMsg(idMsg));
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

return;

% ------------------------------------------------------------------------------
% Retrieve INFO, WARNING and ERROR messages from the log file.
%
% SYNTAX :
%  [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
%    o_rtQcInfoMsg, o_rtQcWarningMsg, o_rtQcErrorMsg, ...
%    o_rtAdjInfoMsg, o_rtAdjWarningMsg, o_rtAdjErrorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_decInfoMsg      : DECODER INFO messages
%   o_decWarningMsg   : DECODER WARNING messages
%   o_decErrorMsg     : DECODER ERROR messages
%   o_rtQcInfoMsg     : RTQC INFO messages
%   o_rtQcWarningMsg  : RTQC WARNING messages
%   o_rtQcErrorMsg    : RTQC ERROR messages
%   o_rtAdjInfoMsg    : RTADJ INFO messages
%   o_rtAdjWarningMsg : RTADJ WARNING messages
%   o_rtAdjErrorMsg   : RTADJ ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/16/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decInfoMsg, o_decWarningMsg, o_decErrorMsg, ...
   o_rtQcInfoMsg, o_rtQcWarningMsg, o_rtQcErrorMsg, ...
   o_rtAdjInfoMsg, o_rtAdjWarningMsg, o_rtAdjErrorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_decInfoMsg = [];
o_decWarningMsg = [];
o_decErrorMsg = [];
o_rtQcInfoMsg = [];
o_rtQcWarningMsg = [];
o_rtQcErrorMsg = [];
o_rtAdjInfoMsg = [];
o_rtAdjWarningMsg = [];
o_rtAdjErrorMsg = [];

if (~isempty(a_logFileName))
   % read log file
   fId = fopen(a_logFileName, 'r');
   if (fId == -1)
      errorLine = sprintf('ERROR: Unable to open file: %s\n', a_logFileName);
      o_errorMsg = [o_errorMsg {errorLine}];
      return;
   end
   fileContents = textscan(fId, '%s', 'delimiter', '\n');
   fclose(fId);
   
   if (~isempty(fileContents))
      % retrieve wanted messages
      fileContents = fileContents{:};
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(upper(line), 'INFO:', length('INFO:')))
            o_decInfoMsg = [o_decInfoMsg {strtrim(line(length('INFO:')+1:end))}];
         elseif (strncmp(upper(line), 'WARNING:', length('WARNING:')))
            o_decWarningMsg = [o_decWarningMsg {strtrim(line(length('WARNING:')+1:end))}];
         elseif (strncmp(upper(line), 'ERROR:', length('ERROR:')))
            o_decErrorMsg = [o_decErrorMsg {strtrim(line(length('ERROR:')+1:end))}];
         elseif (strncmp(upper(line), 'RTQC_INFO:', length('RTQC_INFO:')))
            o_rtQcInfoMsg = [o_rtQcInfoMsg {strtrim(line(length('RTQC_INFO:')+1:end))}];
         elseif (strncmp(upper(line), 'RTQC_WARNING:', length('RTQC_WARNING:')))
            o_rtQcWarningMsg = [o_rtQcWarningMsg {strtrim(line(length('RTQC_WARNING:')+1:end))}];
         elseif (strncmp(upper(line), 'RTQC_ERROR:', length('RTQC_ERROR:')))
            o_rtQcErrorMsg = [o_rtQcErrorMsg {strtrim(line(length('RTQC_ERROR:')+1:end))}];
         elseif (strncmp(upper(line), 'RTADJ_INFO:', length('RTADJ_INFO:')))
            o_rtAdjInfoMsg = [o_rtAdjInfoMsg {strtrim(line(length('RTADJ_INFO:')+1:end))}];
         elseif (strncmp(upper(line), 'RTADJ_WARNING:', length('RTADJ_WARNING:')))
            o_rtAdjWarningMsg = [o_rtAdjWarningMsg {strtrim(line(length('RTADJ_WARNING:')+1:end))}];
         elseif (strncmp(upper(line), 'RTADJ_ERROR:', length('RTADJ_ERROR:')))
            o_rtAdjErrorMsg = [o_rtAdjErrorMsg {strtrim(line(length('RTADJ_ERROR:')+1:end))}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break;
         end
      end
   end
end

return;

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
%   05/16/2017 - RNU - creation
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

return;
