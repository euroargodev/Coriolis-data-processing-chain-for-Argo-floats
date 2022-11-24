% ------------------------------------------------------------------------------
% Create a new set of NetCDF mono-profile files by adding Qc flags (provided in
% NetCDF unique-profile (N_PROF = 1) files).
%
% SYNTAX :
%   nc_copy_mono_profile_qc_rt(varargin)
%
% INPUT PARAMETERS :
%   no mandatory input parameters.
%   input parameter names are not case sensitive.
%   possible input parameters:
%      xmlReportDir   : directory to store the XML report
%      xmlReport      : file name of the XML report
%      floatWmo       : float to process (if not given: all the floats of the Qc
%                       directory are processed)
%      inputQcDir     : directory of input NetCDF files containing the Qc values
%      inputDmDir     : directory of DM input NetCDF files
%      inputArgosDir  : directory of input NetCDF files for Argos floats
%      inputSbdDir    : directory of input NetCDF files for Iridium SBD floats
%      inputRudicsDir : directory of input NetCDF files for Iridium Rudics
%                       floats (Remocean)
%      outputDir      : directory of output NetCDF updated files
%      logDir         : directory to store the log file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation (V 2.0)
%   10/28/2014 - RNU - V 2.1: in get_nc_profile_info, the comparison is done
%                             using the format '%.5f' (because bio data are
%                             rounded to 1E-5 in the Coriolis data base)
%   12/23/2014 - RNU - V 2.2: the temporary directory, used to duplicate the
%                             input file before updating its QC values, is now
%                             created in the DIR_INPUT_QC_NC_FILES/WMO/
%                             directory
%   01/14/2015 - RNU - V 2.3: before the string conversion (for the comparison),
%                             the data are rounded to 1.E-5 and the negative
%                             zeros converted to positive ones.
%   01/16/2015 - RNU - V 2.4: manage the case where there is no data in a B file
%                             for a given profile.
%   02/27/2015 - RNU - V 2.5: - in 'c' files, report <PARAM>_ADJUSTED_QC if the
%                             DATA_MODE of the concerned profile is 'A' or 'D'
%                             - in 'b' files, report <PARAM>_ADJUSTED_QC if the
%                             PARAMETER_DATA_MODE of the concerned profile and
%                             parameter is 'A' or 'D'
%   07/03/2015 - RNU - V 2.6: there is only one input directory for the nc files
%                             to be updated (this is the executive DAC). The
%                             first level sub-directories of this executive DAC
%                             are scanned when looking for the file to update.
%   07/06/2015 - RNU - V 2.7: the nc input file to update can have levels where
%                             PRES = FillValue, these levels are not present in
%                             the nc input file containing the QC values.
%   07/07/2015 - RNU - V 2.8: since V 2.7, final QC merged values can differ
%                             from input QC file ones. The PROFILE_<PARAM>_QC
%                             values should then be computed from final QC
%                             merged values (in the previous versions they were
%                             copied from input Qc file  ones.
%   10/20/2015 - RNU - V 2.9: when a D c-file to be updated is found, the
%                             associated b-file can be in D or in R mode.
%   07/11/2016 - RNU - V 3.0: new management of HISTORY information:
%                             - existing HISTORY information of input files is
%                             kept
%                             - HISTORY information of QC file (reporting
%                             Coriolis SCOOP tool actions) is copied in 'c'
%                             or 'b' files (according to HISTORY_PARAMETER
%                             information)
%                             - a last HISTORY step is added to report the use
%                             of the current tool (COCQ)
%   09/28/2016 - RNU - V 3.1: HISTORY information of QC file (reporting Coriolis
%                             Objective Analysis and SCOOP tool actions) is
%                             copied in 'c' or 'b' files (according to
%                             HISTORY_PARAMETER information) only for HISTORY
%                             steps where HISTORY_SOFTWARE is in a pre-defined
%                             list (g_cocq_historySoftwareToReport).
%   10/17/2016 - RNU - V 3.2: Also manage QC flags of adjusted parameters.
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_qc_rt(varargin)

global g_cocq_dirOutputXmlFile;
global g_cocq_xmlReportFileName;
global g_cocq_floatList;
global g_cocq_dirInputQcNcFiles;
global g_cocq_dirInputNcFiles;
global g_cocq_dirOutputNcFiles;
global g_cocq_dirLogFile;

% RT processing flag
global g_cocq_realtimeFlag;
g_cocq_realtimeFlag = 1;

% program version
global g_cocq_ncCopyMonoProfileQcVersion;
g_cocq_ncCopyMonoProfileQcVersion = '3.2';

% DOM node of XML report
global g_cocq_xmlReportDOMNode;

% report information structure
global g_cocq_reportData;
g_cocq_reportData = [];

% list of HISTORY_SOFTWARE that should be reported from the QC file to the
% output file
global g_cocq_historySoftwareToReport;
g_cocq_historySoftwareToReport = [ ...
   {'COOA'} ...
   {'SCOO'} ...
   ];

% top directory of input NetCDF files containing the Qc values
DIR_INPUT_QC_NC_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\test_20161017\dbqc\';

% top directory of input NetCDF files to be updated (executive DAC, thus top
% directory of the DAC name directories)
DIR_INPUT_NC_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\test_20161017\edac\';

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\test_20161017\out\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log';

% directory to store the xml report
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% default values initialization
init_default_values;


logFileName = [];
status = 'nok';
try
   
   % startTime
   ticStartTime = tic;
   
   % store the start time of the run
   currentTime = datestr(now, 'yyyymmddTHHMMSSZ');
   
   % init the XML report
   init_xml_report(currentTime);
   
   % get input parameters
   [inputError] = parse_input_param(varargin);
   
   if (inputError == 0)
      
      % set parameter default values
      if (isempty(g_cocq_dirOutputXmlFile))
         g_cocq_dirOutputXmlFile = DIR_XML_FILE;
      end
      if (isempty(g_cocq_dirInputQcNcFiles))
         g_cocq_dirInputQcNcFiles = DIR_INPUT_QC_NC_FILES;
      end
      if (isempty(g_cocq_dirInputNcFiles))
         g_cocq_dirInputNcFiles = DIR_INPUT_NC_FILES;
      end
      if (isempty(g_cocq_dirOutputNcFiles))
         g_cocq_dirOutputNcFiles = DIR_OUTPUT_NC_FILES;
      end
      if (isempty(g_cocq_dirLogFile))
         g_cocq_dirLogFile = DIR_LOG_FILE;
      end
      
      if (isempty(g_cocq_floatList))
         % all the floats of the g_cocq_dirInputQcNcFiles directory should be processed
         floatList = [];
         dirNames = dir([g_cocq_dirInputQcNcFiles '/*']);
         for idDir = 1:length(dirNames)
            
            dirName = dirNames(idDir).name;
            dirPathName = [g_cocq_dirInputQcNcFiles '/' dirName];
            
            if (isdir(dirPathName))
               if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
                  floatList = [floatList; str2num(dirName)];
               end
            end
         end
         g_cocq_floatList = floatList;
      end
      
      % log file creation
      if (~isempty(g_cocq_xmlReportFileName))
         logFileName = [g_cocq_dirLogFile '/nc_copy_mono_profile_qc_rt_' g_cocq_xmlReportFileName(10:end-4) '.log'];
      else
         logFileName = [g_cocq_dirLogFile '/nc_copy_mono_profile_qc_rt_' currentTime '.log'];
      end
      
      % process the files according to input and configuration parameters
      nc_copy_mono_profile_qc_(g_cocq_floatList, logFileName, ...
         g_cocq_dirInputQcNcFiles, ...
         g_cocq_dirInputNcFiles, ...
         g_cocq_dirOutputNcFiles, ...
         g_cocq_dirLogFile);
      
      % finalize XML report
      [status] = finalize_xml_report(ticStartTime, logFileName, []);
      
   else
      g_cocq_dirOutputXmlFile = DIR_XML_FILE;
   end
   
catch
   
   diary off;
   
   % finalize XML report
   [status] = finalize_xml_report(ticStartTime, logFileName, lasterror);
   
end

% create the XML report path file name
if (~isempty(g_cocq_xmlReportFileName))
   xmlFileName = [g_cocq_dirOutputXmlFile '/' g_cocq_xmlReportFileName];
else
   xmlFileName = [g_cocq_dirOutputXmlFile '/co041403_' currentTime '.xml'];
end

% save the XML report
xmlwrite(xmlFileName, g_cocq_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Create a new set of NetCDF mono-profile files by adding Qc flags (provided in
% NetCDF unique-profile (N_PROF = 1) files).
%
% SYNTAX :
%  nc_copy_mono_profile_qc_(a_floatList, a_logFile, ...
%    a_dirInputQcNcFiles, ...
%    a_dirInputNcFiles, ...
%    a_dirOutputNcFiles, ...
%    a_dirLogFile)
%
% INPUT PARAMETERS :
%   a_floatList             : list of floats to process
%   a_logFile               : log file name
%   a_dirInputQcNcFiles     : directory of input NetCDF files containing the Qc
%                             values
%   a_dirInputDmNcFiles     : directory of input NetCDF files to be updated
%                             (executive DAC)
%   a_dirOutputNcFiles      : directory of output NetCDF updated files
%   a_dirLogFile            : directory to store the log file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_qc_(a_floatList, a_logFile, ...
   a_dirInputQcNcFiles, ...
   a_dirInputNcFiles, ...
   a_dirOutputNcFiles, ...
   a_dirLogFile)

% RT processing flag
global g_cocq_realtimeFlag;

% report information structure
global g_cocq_reportData;
global g_cocq_reportStruct;

% top directory of input NetCDF files containing the Qc values
DIR_INPUT_QC_NC_FILES = a_dirInputQcNcFiles;

% top directory of input NetCDF files to be updated (executive DAC)
DIR_INPUT_NC_FILES = a_dirInputNcFiles;

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = a_dirOutputNcFiles;

% directory to store the log file
DIR_LOG_FILE = a_dirLogFile;

% flag to print data measurements (when different) in the log file
PRINT_DIFF_DATA_FLAG = 0;


diary(a_logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   Qc input files directory: %s\n', DIR_INPUT_QC_NC_FILES);
fprintf('   Input files directory (executive DAC): %s\n', DIR_INPUT_NC_FILES);
fprintf('   Output files directory: %s\n', DIR_OUTPUT_NC_FILES);
fprintf('   Log output directory: %s\n', DIR_LOG_FILE);
fprintf('   Floats to process:');
fprintf(' %d', a_floatList);
fprintf('\n');

% create the output directory
if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_NC_FILES);
end

% list of directories to scan
inputDirList = [];
if (exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   inputDirList = [inputDirList {DIR_OUTPUT_NC_FILES}];
end
if (exist(DIR_INPUT_NC_FILES, 'dir') == 7)
   % check the sub-directories of the executive DAC
   % there is one directory for each DAC (with the name of the DAC)
   dirNames = dir(DIR_INPUT_NC_FILES);
   for idDir = 1:length(dirNames)
      dirName = dirNames(idDir).name;
      if ~(strcmp(dirName, '.') || strcmp(dirName, '..'))
         inputDirList = [inputDirList {[DIR_INPUT_NC_FILES '/' dirName]}];
      end
   end
end

% process the floats
nbFloats = length(a_floatList);
for idFloat = 1:nbFloats
   
   floatNum = a_floatList(idFloat);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   if (g_cocq_realtimeFlag == 1)
      % initialize data structure to store report information
      g_cocq_reportStruct = get_report_init_struct(floatNum);
   end
   
   % directory to store temporary files
   DIR_TMP_FILE = [DIR_INPUT_QC_NC_FILES sprintf('/%d/tmp/', floatNum)];
   
   % delete the temp directory
   if (exist(DIR_TMP_FILE, 'dir') == 7)
      rmdir(DIR_TMP_FILE, 's');
   end
   
   % create the temp directory
   mkdir(DIR_TMP_FILE);
   
   % process the Qc files of this float
   subPath = sprintf('/%d/profiles/', floatNum);
   qcProfDirName = [DIR_INPUT_QC_NC_FILES subPath];
   qcProfFileName = [qcProfDirName sprintf('%d_*.nc', floatNum)];
   qcProfFiles = dir(qcProfFileName);
   for idFile = 1:length(qcProfFiles)
      
      % name of the current Qc file
      qcProfFileName = qcProfFiles(idFile).name;
      qcProfFilePathName = [qcProfDirName qcProfFileName];
      
      % look for the file(s) to be updated
      inputProfCFilePathName = '';
      inputProfBFilePathName = '';
      idF = strfind(qcProfFileName, '_');
      inputProfFileName = [qcProfFileName(1:idF(end)-1) '.nc'];
      for idDir = 1:length(inputDirList)
         filePathName = [inputDirList{idDir} subPath 'D' inputProfFileName];
         if (exist(filePathName, 'file') == 2)
            if (isempty(inputProfCFilePathName))
               inputProfCFilePathName = filePathName;
            end
            filePathName = [inputDirList{idDir} subPath 'BD' inputProfFileName];
            if (exist(filePathName, 'file') == 2)
               if (isempty(inputProfBFilePathName))
                  inputProfBFilePathName = filePathName;
               end
            else
               filePathName = [inputDirList{idDir} subPath 'BR' inputProfFileName];
               if (exist(filePathName, 'file') == 2)
                  if (isempty(inputProfBFilePathName))
                     inputProfBFilePathName = filePathName;
                  end
               end
            end
         else
            filePathName = [inputDirList{idDir} subPath 'R' inputProfFileName];
            if (exist(filePathName, 'file') == 2)
               if (isempty(inputProfCFilePathName))
                  inputProfCFilePathName = filePathName;
               end
               filePathName = [inputDirList{idDir} subPath 'BD' inputProfFileName];
               if (exist(filePathName, 'file') == 2)
                  if (isempty(inputProfBFilePathName))
                     inputProfBFilePathName = filePathName;
                  end
               else
                  filePathName = [inputDirList{idDir} subPath 'BR' inputProfFileName];
                  if (exist(filePathName, 'file') == 2)
                     if (isempty(inputProfBFilePathName))
                        inputProfBFilePathName = filePathName;
                     end
                  end
               end
            end
         end
      end
      
      if (isempty(inputProfCFilePathName))
         fprintf('ERROR: No input file to report Qc file information [Qc file: %s]\n', ...
            qcProfFilePathName);
         
         if (g_cocq_realtimeFlag == 1)
            g_cocq_reportStruct.input_ko = [g_cocq_reportStruct.input_ko {qcProfFilePathName}];
         end
         continue
      end
      
      % retrieve information from Qc file
      [vssQc, cParamStrQc, cDataStrQc, cDataIdQc, ...
         bParamStrQc, bDataStrQc, bDataIdQc, paramListQc] = ...
         get_nc_profile_info(qcProfFilePathName, []);
      
      % check that the Qc file contains only one profile
      if (length(vssQc) > 1)
         fprintf('ERROR: Qc file is expected to contain only one profile (%d profiles in the file) [Qc file: %s]\n', ...
            qcProfFilePathName, length(vssQc));
         
         if (g_cocq_realtimeFlag == 1)
            g_cocq_reportStruct.input_ko = [g_cocq_reportStruct.input_ko {qcProfFilePathName}];
         end
         continue
      end
      
      % retrieve information from input c file
      [vssCInput, cParamStrInput, cDataStrInput, cDataIdInput, ...
         ~, ~, ~, ~] = ...
         get_nc_profile_info(inputProfCFilePathName, paramListQc);
      
      % find the number of the profile to be updated
      profNumToUpdate = -1;
      nbInputProf = length(cDataStrInput);
      for idProf = 1:nbInputProf
         
         currentDataQc = cDataStrQc{:};
         currentdataInput = cDataStrInput{idProf};
         profNbLevelsQc = size(currentDataQc, 1);
         profNbLevelsInput = size(currentdataInput, 1);
         if (strcmp(vssQc{:}, vssCInput{idProf}) == 0)
            continue
         elseif (strcmp(cParamStrQc{:}, cParamStrInput{idProf}) == 0)
            continue
         elseif (profNbLevelsQc ~= profNbLevelsInput)
            continue
         else
            dataDiffer = 0;
            for idLev = 1:size(currentdataInput, 1)
               if (~strcmp(currentdataInput(idLev, :), currentDataQc(idLev, :)))
                  dataDiffer = 1;
                  break
               end
            end
            if (dataDiffer == 0)
               profNumToUpdate = idProf;
               break
            else
               if (PRINT_DIFF_DATA_FLAG == 1)
                  % the data comparison is not printed when we compare 2
                  % profiles of only PRES parameter (case of all c profiles of
                  % only b prameters)
                  if (strcmp(cParamStrQc{:}, 'PRES') == 0)
                     fprintf('FLAG: Input c (%s) | Qc c (%s)\n', ...
                        cParamStrQc{:}, ...
                        cParamStrInput{idProf});
                     for idLev = 1:size(currentdataInput, 1)
                        diffFlag = 0;
                        if (~strcmp(currentdataInput(idLev, :), currentDataQc(idLev, :)))
                           diffFlag = 1;
                        end
                        fprintf('  %d : %s | %s\n', ...
                           diffFlag, currentdataInput(idLev, :), currentDataQc(idLev, :));
                     end
                  end
               end
            end
         end
      end
      if (profNumToUpdate ~= -1)
         bDataIdInput = [];
         if (~isempty(inputProfBFilePathName))
            
            % retrieve information from input b file
            [vssBInput, ~, ~, ~, ...
               bParamStrInput, bDataStrInput, bDataIdInput, ~] = ...
               get_nc_profile_info(inputProfBFilePathName, paramListQc);
            
            dataQc = bDataStrQc{:};
            dataInput = bDataStrInput{profNumToUpdate};
            dataDiffer = 0;
            for idLev = 1:size(dataInput, 1)
               if (~strcmp(dataInput(idLev, :), dataQc(idLev, :)))
                  dataDiffer = 1;
                  break
               end
            end
            if (dataDiffer == 1)
               if (PRINT_DIFF_DATA_FLAG == 1)
                  fprintf('FLAG: Input b (%s) | Qc b (%s)\n', ...
                     bParamStrQc{:}, ...
                     bParamStrInput{idProf});
                  for idLev = 1:size(dataInput, 1)
                     diffFlag = 0;
                     if (~strcmp(dataInput(idLev, :), dataQc(idLev, :)))
                        diffFlag = 1;
                     end
                     fprintf('  %d : %s | %s\n', ...
                        diffFlag, dataInput(idLev, :), dataQc(idLev, :));
                  end
               end
               fprintf('ERROR: Qc file data fit c input file but not b input file [Qc file: %s] [c file: %s] [b file: %s]\n', ...
                  qcProfFilePathName, inputProfCFilePathName, inputProfBFilePathName);
               
               if (g_cocq_realtimeFlag == 1)
                  g_cocq_reportStruct.input_ko = [g_cocq_reportStruct.input_ko {qcProfFilePathName}];
               end
               continue
            end
         end
      else
         fprintf('ERROR: Unable to find the corresponding profile in c input file [Qc file: %s] [c file: %s]\n', ...
            qcProfFilePathName, inputProfCFilePathName);
         
         if (g_cocq_realtimeFlag == 1)
            g_cocq_reportStruct.input_ko = [g_cocq_reportStruct.input_ko {qcProfFilePathName}];
         end
         continue
      end
      
      % make a copy of the input file(s) to be updated
      copy_file(inputProfCFilePathName, DIR_TMP_FILE);
      [~, fileName, fileExtension] = fileparts(inputProfCFilePathName);
      outputProfCFilePathName = [DIR_TMP_FILE fileName fileExtension];
      
      outputProfBFilePathName = '';
      if (~isempty(inputProfBFilePathName))
         copy_file(inputProfBFilePathName, DIR_TMP_FILE);
         [~, fileName, fileExtension] = fileparts(inputProfBFilePathName);
         outputProfBFilePathName = [DIR_TMP_FILE fileName fileExtension];
      end
      
      % update the input file(s)
      bDataIdInputFinal = [];
      if (~isempty(bDataIdInput))
         bDataIdInputFinal = bDataIdInput{profNumToUpdate};
      end
      [ok, updatedCFile, updatedBFile] = ...
         nc_update_file(qcProfFilePathName, ...
         outputProfCFilePathName, outputProfBFilePathName, profNumToUpdate, ...
         cDataIdQc{:}, bDataIdQc{:}, cDataIdInput{profNumToUpdate}, bDataIdInputFinal, ...
         paramListQc);
      
      if (ok == 1)
         % if the update succeeded move the file(s) in the DIR_OUTPUT_NC_FILES
         % directory
         if ((updatedCFile == 1) || (updatedBFile == 1))
            
            % create the directory
            if ~(exist([DIR_OUTPUT_NC_FILES subPath], 'dir') == 7)
               mkdir([DIR_OUTPUT_NC_FILES subPath]);
            end
            
            if (updatedCFile == 1)
               [~, fileName, fileExtension] = fileparts(outputProfCFilePathName);
               finalOutputProfCFilePathName = [DIR_OUTPUT_NC_FILES subPath fileName fileExtension];
               move_file(outputProfCFilePathName, finalOutputProfCFilePathName);
               
               fprintf('INFO: Qc file contents successfully reported into prof #%d of c file [Qc file: %s] [c file: %s]\n', ...
                  profNumToUpdate, qcProfFilePathName, finalOutputProfCFilePathName);
               
               if (g_cocq_realtimeFlag == 1)
                  g_cocq_reportStruct.input_ok = [g_cocq_reportStruct.input_ok {qcProfFilePathName}];
                  g_cocq_reportStruct.output_ok = [g_cocq_reportStruct.output_ok {finalOutputProfCFilePathName}];
                  g_cocq_reportStruct.profNum_ok = [g_cocq_reportStruct.profNum_ok {profNumToUpdate}];
               end
            end
            
            if (updatedBFile == 1)
               [~, fileName, fileExtension] = fileparts(outputProfBFilePathName);
               finalOutputProfBFilePathName = [DIR_OUTPUT_NC_FILES subPath fileName fileExtension];
               move_file(outputProfBFilePathName, finalOutputProfBFilePathName);
               
               fprintf('INFO: Qc file contents successfully reported into prof #%d of b file [Qc file: %s] [b file: %s]\n', ...
                  profNumToUpdate, qcProfFilePathName, finalOutputProfBFilePathName);
               
               if (g_cocq_realtimeFlag == 1)
                  g_cocq_reportStruct.input_ok = [g_cocq_reportStruct.input_ok {qcProfFilePathName}];
                  g_cocq_reportStruct.output_ok = [g_cocq_reportStruct.output_ok {finalOutputProfBFilePathName}];
                  g_cocq_reportStruct.profNum_ok = [g_cocq_reportStruct.profNum_ok {profNumToUpdate}];
               end
            end
         end
      else
         if (g_cocq_realtimeFlag == 1)
            g_cocq_reportStruct.input_ko = [g_cocq_reportStruct.input_ko {qcProfFilePathName}];
         end
      end
   end
   
   % store the information for the XML report
   if (g_cocq_realtimeFlag == 1)
      g_cocq_reportData = [g_cocq_reportData g_cocq_reportStruct];
   end
   
   % delete the temp directory
   if (exist(DIR_TMP_FILE, 'dir') == 7)
      rmdir(DIR_TMP_FILE, 's');
   end
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve information on profile(s) of a mono-profile or unique-profile NetCDF
% file.
%
% SYNTAX :
%  [o_vss, o_cParamStr, o_cDataStr, o_cDataId, ...
%    o_bParamStr, o_bDataStr, o_bDataId, o_paramList] = ...
%    get_nc_profile_info(a_profFilePathName, a_refParamlist)
%
% INPUT PARAMETERS :
%   a_profFilePathName : NetCDF file path name
%   a_refParamlist     : list of parameter names to consider (if empty: consider
%                        all encountered parameters)
%
% OUTPUT PARAMETERS :
%   o_vss       : VSS of the profile(s)
%   o_cParamStr : lists of c parameter names of the profile(s)
%   o_cDataStr  : c parameter values of the profile(s)
%   o_cDataId   : c parameter value indices of the profile(s)
%   o_bParamStr : lists of b parameter names of the profile(s)
%   o_bDataStr  : b parameter values of the profile(s)
%   o_bDataId   : b parameter value indices of the profile(s)
%   o_paramList : list of all input file parameter names
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_vss, o_cParamStr, o_cDataStr, o_cDataId, ...
   o_bParamStr, o_bDataStr, o_bDataId, o_paramList] = ...
   get_nc_profile_info(a_profFilePathName, a_refParamlist)

% output parameters initialization
o_vss = [];
o_cParamStr = [];
o_cDataStr = [];
o_cDataId = [];
o_bParamStr = [];
o_bDataStr = [];
o_bDataId = [];
o_paramList = [];


% read the file and retrieve wanted information
if (exist(a_profFilePathName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_profFilePathName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_profFilePathName);
      return
   end
   
   % retrieve information
   if (var_is_present(fCdf, 'STATION_PARAMETERS') && ...
         var_is_present(fCdf, 'VERTICAL_SAMPLING_SCHEME'))
      
      % store the vertical sampling scheme of each profile
      verticalSamplingScheme = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'VERTICAL_SAMPLING_SCHEME'));
      [~, nProf] = size(verticalSamplingScheme);
      vssList = [];
      for idProf = 1:nProf
         vss = strtrim(verticalSamplingScheme(:, idProf)');
         vssList = [vssList {deblank(vss)}];
      end
      
      % store the parameters of each profile
      % store the parameter data of each profile as string
      stationParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));
      [~, nParam, nProf] = size(stationParameters);
      paramList = [];
      cParamList = [];
      bParamList = [];
      cParamDataStr = [];
      bParamDataStr = [];
      cParamDataId = [];
      bParamDataId = [];
      for idProf = 1:nProf
         cParamForProf = [];
         bParamForProf = [];
         for idParam = 1:nParam
            paramName = strtrim(stationParameters(:, idParam, idProf)');
            if (~isempty(paramName))
               if (~isempty(a_refParamlist))
                  % consider only the parameters of the reference list
                  if (isempty(find(strcmp(a_refParamlist, paramName) == 1)))
                     continue
                  end
               end
               paramList = [paramList {paramName}];
               param = get_netcdf_param_attributes_3_1(paramName);
               if ((param.paramType == 'c') || (param.paramType == 'j'))
                  cParamForProf{end+1} = paramName;
               else
                  bParamForProf{end+1} = paramName;
               end
            end
         end
         cParamForProf = sort(cParamForProf);
         bParamForProf = sort(bParamForProf);
         
         % store parameter names
         if (~isempty(cParamForProf))
            cParamForProfList = sprintf('%s ', cParamForProf{:});
            cParamList = [cParamList {cParamForProfList(1:end-1)}];
         end
         if (~isempty(bParamForProf))
            bParamForProf{end+1} = 'PRES';
            bParamForProf = sort(bParamForProf);
            bParamForProfList = sprintf('%s ', bParamForProf{:});
            bParamList = [bParamList {bParamForProfList(1:end-1)}];
         else
            bParamForProf{end+1} = 'PRES';
            bParamList = [bParamList {'PRES'}];
         end
         
         % store parameter data
         for idType = 1:2
            if (idType == 1)
               paramForProf = cParamForProf;
            else
               paramForProf = bParamForProf;
            end
            
            profDataStr = [];
            fillValueStr = [];
            presStrIdStart = -1;
            presStrIdStop = -1;
            pressFillValueStr = '';
            for idParam = 1:length(paramForProf)
               
               paramStr = paramForProf{idParam};
               
               [varName, xType, dimIds, nbAtts] = netcdf.inqVar(fCdf, netcdf.inqVarID(fCdf, paramStr));
               if (xType == netcdf.getConstant('NC_FLOAT'))
                  paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramStr));
               else
                  paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramStr), 'double');
               end
               if ((idType == 1) || (strcmp(paramStr, 'PRES')))
                  if (att_is_present(fCdf, paramStr, 'C_format'))
                     %                      paramFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramStr), 'C_format');
                     paramFormat = '%.5f';
                  else
                     paramFormat = '%.5f';
                  end
               else
                  paramFormat = '%.5f';
               end
               if (att_is_present(fCdf, paramStr, '_FillValue'))
                  paramFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramStr), '_FillValue');
               else
                  [varName, xType, dimIds, nbAtts] = netcdf.inqVar(fCdf, netcdf.inqVarID(fCdf, paramStr));
                  if (xType == netcdf.getConstant('NC_FLOAT'))
                     paramFillVal = single(99999);
                  else
                     paramFillVal = double(99999);
                  end
               end
               % TEMPORARY START: the pressures are rounded to 1/10 dbar in the
               % Coriolis data base
               %                if (strcmp(paramStr, 'PRES'))
               %                   idNoDef = find(paramData ~= paramFillVal);
               %                   paramData(idNoDef) = round(paramData(idNoDef)*10)/10;
               %                end
               % TEMPORARY END
               if (ndims(paramData) == 3)
                  dims = size(paramData);
                  paramFillVal = repmat(paramFillVal, 1, dims(1));
               end
               newFillValueStr = sprintf([paramFormat ' '], paramFillVal);
               
               profParamDataStr = [];
               nbLev = size(paramData, 1);
               if (ndims(paramData) == 3)
                  nbLev = size(paramData, 2);
               end
               for idLev = 1:nbLev
                  if (ndims(paramData) == 2)
                     dataValue = round(double(paramData(idLev, idProf))/0.00001)*0.00001;
                  else
                     dataValue = round(double(paramData(:, idLev, idProf))/0.00001)*0.00001;
                  end
                  if (dataValue == 0)
                     newData = sprintf([paramFormat ' '], 0);
                  else
                     newData = sprintf([paramFormat ' '], dataValue);
                  end
                  
                  if (~isempty(profParamDataStr))
                     if (length(newData) ~= size(profParamDataStr, 2))
                        [newData, profParamDataStr] = adjust_size(newData, profParamDataStr);
                     end
                  end
                  
                  profParamDataStr = [profParamDataStr; newData];
               end
               
               if (length(newFillValueStr) ~= size(profParamDataStr, 2))
                  [newFillValueStr, profParamDataStr] = adjust_size(newFillValueStr, profParamDataStr);
               end
               
               profDataStr = [profDataStr profParamDataStr];
               
               if (strcmp(paramStr, 'PRES'))
                  presStrIdStart = length(fillValueStr) + 1;
                  presStrIdStop = length(fillValueStr) + length(newFillValueStr);
                  pressFillValueStr = newFillValueStr;
               end
               fillValueStr = [fillValueStr newFillValueStr];
            end
            
            idDel = [];
            for idLev = 1:size(profDataStr, 1)
               if (strcmp(profDataStr(idLev, :), fillValueStr))
                  idDel = [idDel; idLev];
               elseif (presStrIdStart ~= -1)
                  if (strcmp(profDataStr(idLev, presStrIdStart:presStrIdStop), pressFillValueStr))
                     idDel = [idDel; idLev];
                  end
               end
            end
            profDataId = setdiff(1:size(profDataStr, 1), idDel)';
            profDataStr(idDel, :) = [];
            
            if (idType == 1)
               cParamDataStr = [cParamDataStr {profDataStr}];
               cParamDataId = [cParamDataId {profDataId}];
            else
               bParamDataStr = [bParamDataStr {profDataStr}];
               bParamDataId = [bParamDataId {profDataId}];
            end
         end
      end
      
      % update output data
      o_vss = vssList;
      o_cParamStr = cParamList;
      o_cDataStr = cParamDataStr;
      o_cDataId = cParamDataId;
      o_bParamStr = bParamList;
      o_bDataStr = bParamDataStr;
      o_bDataId = bParamDataId;
      o_paramList = sort(unique(paramList));
      
   else
      
      if (~var_is_present(fCdf, 'STATION_PARAMETERS'))
         fprintf('WARNING: Variable STATION_PARAMETERS not present in file : %s\n', ...
            a_profFilePathName);
      end
      if (~var_is_present(fCdf, 'VERTICAL_SAMPLING_SCHEME'))
         fprintf('WARNING: Variable VERTICAL_SAMPLING_SCHEME not present in file : %s\n', ...
            a_profFilePathName);
      end
   end
   
   netcdf.close(fCdf);
   
else
   fprintf('ERROR: file not found: %s\n', a_profFilePathName);
end

return

% ------------------------------------------------------------------------------
% Update the QC of given mono-profile NetCDF file(s) (c file and b file if
% exists).
%
% SYNTAX :
%  [o_ok, o_outputCFileName, o_outputBFileName] = ...
%    nc_update_file(a_qcFileName, ...
%    a_outputCFileName, a_outputBFileName, a_profNumToUpdate, ...
%    a_qcCDataId, a_qcBDataId, a_outputCDataId, a_outputBDataId, o_paramListQc)
%
% INPUT PARAMETERS :
%   a_qcFileName      : QC file name
%   a_outputCFileName : output c file name
%   a_outputBFileName : output b file name
%   a_profNumToUpdate : number of the profile to update
%   a_qcCDataId       : indices of the Qc file for the c parameter values
%   a_qcBDataId       : indices of the Qc file for the b parameter values
%   a_outputCDataId   : indices of the output file for the c parameter values
%   a_outputBDataId   : indices of the output file for the b parameter values
%   o_paramListQc     : list of Qc file parameter names
%
% OUTPUT PARAMETERS :
%   o_ok           : success flag (1 if Ok, 0 otherwise)
%   o_updatedCFile : updated c file flag
%   o_updatedBFile : updated b file flag
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_updatedCFile, o_updatedBFile] = ...
   nc_update_file(a_qcFileName, ...
   a_outputCFileName, a_outputBFileName, a_profNumToUpdate, ...
   a_qcCDataId, a_qcBDataId, a_outputCDataId, a_outputBDataId, o_paramListQc)

% output parameters initialization
o_ok = 0;
o_updatedCFile = 0;
o_updatedBFile = 0;

% program version
global g_cocq_ncCopyMonoProfileQcVersion;

% QC flag values
global g_decArgo_qcStrDef;

% list of HISTORY_SOFTWARE that should be reported from the QC file to the
% output file
global g_cocq_historySoftwareToReport;


% retrieve needed information from QC file
wantedQcVars = [ ...
   {'JULD_QC'} ...
   {'POSITION_QC'} ...
   {'HISTORY_INSTITUTION'} ...
   {'HISTORY_STEP'} ...
   {'HISTORY_SOFTWARE'} ...
   {'HISTORY_SOFTWARE_RELEASE'} ...
   {'HISTORY_REFERENCE'} ...
   {'HISTORY_DATE'} ...
   {'HISTORY_ACTION'} ...
   {'HISTORY_PARAMETER'} ...
   {'HISTORY_START_PRES'} ...
   {'HISTORY_STOP_PRES'} ...
   {'HISTORY_PREVIOUS_VALUE'} ...
   {'HISTORY_QCTEST'} ...
   ];
for idParam = 1:length(o_paramListQc)
   paramName = o_paramListQc{idParam};
   profParamQcName = ['PROFILE_' paramName '_QC'];
   paramNameQc = [paramName '_QC'];
   paramNameAdjQc = [paramName '_ADJUSTED_QC'];
   wantedQcVars = [ ...
      wantedQcVars ...
      {profParamQcName} ...
      {paramNameQc} ...
      {paramNameAdjQc} ...
      ];
end
[qcData] = get_data_from_nc_file(a_qcFileName, wantedQcVars);
                  
% update output c and b files

profPos = a_profNumToUpdate-1;

% update the output file(s)
for idType = 1:2
   if (idType == 1)
      % c file update
      outputFileName = a_outputCFileName;
      qcDataId = a_qcCDataId;
      outputDataId = a_outputCDataId;
   else
      % b file update
      if (isempty(a_outputBFileName))
         continue
      end
      outputFileName = a_outputBFileName;
      qcDataId = a_qcBDataId;
      outputDataId = a_outputBDataId;
   end
   
   % open the output file to update
   fCdf = netcdf.open(outputFileName, 'NC_WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', outputFileName);
      return
   end
   
   % retrieve the N_LEVELS dimension value
   nbLevelsId = netcdf.inqDimID(fCdf, 'N_LEVELS');
   [~, nbLevels] = netcdf.inqDim(fCdf, nbLevelsId);
   
   if (idType == 1)
      % for c files retrieve DATA_MODE
      dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'));
   else
      % for b files retrieve PARAMETER_DATA_MODE and STATION_PARAMETERS
      parameterDataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER_DATA_MODE'))';
      
      stationParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));
      [~, nParam, nProf] = size(stationParameters);
      
      % create the list of adjusted parameters
      adjustedParam = [];
      for idParam = 1:nParam
         paramName = strtrim(stationParameters(:, idParam, a_profNumToUpdate)');
         if (~isempty(paramName))
            if (ismember(parameterDataMode(a_profNumToUpdate, idParam), 'AD'))
               adjustedParam = [adjustedParam {paramName}];
            end
         end
      end
   end

   % update JULD_QC
   idVal = find(strcmp('JULD_QC', qcData) == 1, 1);
   qcJuldQc = qcData{idVal+1};
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), profPos, 1, qcJuldQc);
   
   % update POSITION_QC
   idVal = find(strcmp('POSITION_QC', qcData) == 1, 1);
   qcPositionQc = qcData{idVal+1};
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), profPos, 1, qcPositionQc);
      
   % update profile and parameter Qc
   sufixList = [{'_QC'} {'_ADJUSTED_QC'}];
   for idParam = 1:length(o_paramListQc)
      paramNamePrefix = o_paramListQc{idParam};
      
      for idS = 1:length(sufixList)
         
         paramName = [paramNamePrefix sufixList{idS}];
         
         if (var_is_present(fCdf, paramName))
            if (idS == 2)
               if (idType == 1)
                  if (dataMode(a_profNumToUpdate) == 'R')
                     fprintf('INFO: profile #%d is in ''R'' mode - %s not reported in profile #%d of file : %s\n', ...
                        a_profNumToUpdate, paramName, a_profNumToUpdate, outputFileName);
                     continue
                  end
               else
                  if (isempty(find(strcmp(paramNamePrefix, adjustedParam), 1)))
                     fprintf('INFO: parameter %s of profile #%d is in ''R'' mode - %s not reported in profile #%d of file : %s\n', ...
                        paramNamePrefix, a_profNumToUpdate, paramName, a_profNumToUpdate, outputFileName);
                     continue
                  end
               end
            end
            
            % <PARAM>_QC values
            idVal = find(strcmp(paramName, qcData) == 1, 1);
            inputValue = qcData{idVal+1};
            inputValue = inputValue(qcDataId);
            oldValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramName), fliplr([profPos 0]), fliplr([1 nbLevels]));
            newValue = oldValue;
            newValue(outputDataId) = inputValue;
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramName), fliplr([profPos 0]), fliplr([1 length(newValue)]), newValue);
            
            % PROFILE_<PARAM>_QC values
            % the <PARAM>_ADJUSTED_QC values are after the <PARAM>_QC values in
            % the sufixList list. So, if <PARAM>_ADJUSTED_QC values differ from
            % FillValue, they will be used to compute PROFILE_<PARAM>_QC values.
            profParamQcName = ['PROFILE_' paramNamePrefix '_QC'];
            if (idS == 1)
               if (var_is_present(fCdf, profParamQcName))
                  % compute PROFILE_<PARAM>_QC from <PARAM>_QC values
                  newProfParamQc = compute_profile_quality_flag(newValue);
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), profPos, 1, newProfParamQc);
               end
            else
               if ~((length(unique(newValue)) == 1) && (unique(newValue) == g_decArgo_qcStrDef))
                  if (var_is_present_dec_argo(fCdf, profParamQcName))
                     % compute PROFILE_<PARAM>_QC from <PARAM>_ADJUSTED_QC values
                     newProfParamQc = compute_profile_quality_flag(newValue);
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), profPos, 1, newProfParamQc);
                  end
               end
            end
         end
      end
   end
   
   % retrieve the current HISTORY Id of the output file
   currentHistoId = 0;
   outputHistoryInstitution = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'));
   if (~isempty(outputHistoryInstitution))
      currentHistoId = size(outputHistoryInstitution, 3);
   end
   
   % copy HISTORY information from QC file to c or b output file depending on
   % concerned parameter
   idF = find(strcmp('HISTORY_PARAMETER', qcData) == 1, 1);
   historyParameter = qcData{idF+1};
   idF = find(strcmp('HISTORY_SOFTWARE', qcData) == 1, 1);
   historySoftware = qcData{idF+1};
   for idHistory = 1:size(historyParameter, 3)
      for idProf = 1:size(historyParameter, 2) % size(historyParameter, 2) = 1 (only one Coriolis 'station' is concerned by the Qc reported in each file)
         
         paramName = historyParameter(:, idProf, idHistory)';
         paramName = strtrim(paramName);
         if (~isempty(paramName))
            
            % use HISTORY_PARAMETER to decide if output file should be
            % updated
            updateFile = 0;
            if (strcmp(paramName, 'DAT$') || strcmp(paramName, 'POS$'))
               % if JULD_QC has been modified, it is reported in HISTORY
               % information through HISTORY_PARAMETER='DAT$'
               % if POSITION_QC has been modified, it is reported in HISTORY
               % information through HISTORY_PARAMETER='POS$'
               % in both cases the output file should be updated
               updateFile = 1;
            else
               if (~isempty(strfind(paramName, '_ADJUSTED')))
                  paramName2 = regexprep(paramName, '_ADJUSTED', '');
                  paramInfo = get_netcdf_param_attributes(paramName2);
               else
                  paramInfo = get_netcdf_param_attributes(paramName);
               end
               if ((((paramInfo.paramType == 'c') || (paramInfo.paramType == 'j')) && (idType == 1)) || ...
                     (((paramInfo.paramType ~= 'c') && (paramInfo.paramType ~= 'j')) && (idType == 2)))
                  updateFile = 1;
               end
            end
            
            if (updateFile == 1)
               
               % the output file should be updated
               if (idType == 1)
                  o_updatedCFile = 1;
               else
                  o_updatedBFile = 1;
               end
               
               % output file HISTORY information should be updated only for
               % history steps where HISTORY_SOFTWARE is in the
               % g_cocq_historySoftwareToReport list
               softwareName = historySoftware(:, idProf, idHistory)';
               softwareName = strtrim(softwareName);
               if (ismember(softwareName, g_cocq_historySoftwareToReport))
                  
                  % the current output file should be updated
                  histoItemList = [ ...
                     {'HISTORY_INSTITUTION'} ...
                     {'HISTORY_STEP'} ...
                     {'HISTORY_SOFTWARE'} ...
                     {'HISTORY_SOFTWARE_RELEASE'} ...
                     {'HISTORY_REFERENCE'} ...
                     {'HISTORY_DATE'} ...
                     {'HISTORY_ACTION'} ...
                     {'HISTORY_PARAMETER'} ...
                     {'HISTORY_QCTEST'} ...
                     ];
                  for idHI = 1:length(histoItemList)
                     histoItemParamName = histoItemList{idHI};
                     
                     idVal = find(strcmp(histoItemParamName, qcData) == 1, 1);
                     inputValue = qcData{idVal+1};
                     if (~isempty(inputValue)) % if N_HISTORY = 0 (should not happen but has
                        % been seen for unknown reason) the variables are not present in the
                        % input Qc file
                        data = inputValue(:, idProf, idHistory)';
                        data = strtrim(data);
                        if (~isempty(data))
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, histoItemParamName), ...
                              fliplr([currentHistoId profPos 0]), ...
                              fliplr([1 1 length(data)]), data');
                        end
                     end
                  end
                  
                  histoItemList = [ ...
                     {'HISTORY_START_PRES'} ...
                     {'HISTORY_STOP_PRES'} ...
                     {'HISTORY_PREVIOUS_VALUE'} ...
                     ];
                  for idHI = 1:length(histoItemList)
                     histoItemParamName = histoItemList{idHI};
                     
                     idVal = find(strcmp(histoItemParamName, qcData) == 1, 1);
                     inputValue = qcData{idVal+1};
                     if (~isempty(inputValue)) % if N_HISTORY = 0 (should not happen but has
                        % been seen for unknown reason) the variables are not present in the
                        % input Qc file
                        data = inputValue(idProf, idHistory);
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, histoItemParamName), ...
                           fliplr([currentHistoId profPos]), ...
                           fliplr([1 1]), data);
                     end
                  end
                  currentHistoId = currentHistoId + 1;
               end
            end
         end
      end
   end
   
   % add history information that concerns the current program
   if (((idType == 1) && (o_updatedCFile == 1)) || ...
         ((idType == 2) && (o_updatedBFile == 1)))
      
      dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');
      value = 'IF';
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([currentHistoId profPos 0]), ...
         fliplr([1 1 length(value)]), value');
      value = 'COCQ';
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([currentHistoId profPos 0]), ...
         fliplr([1 1 length(value)]), value');
      value = g_cocq_ncCopyMonoProfileQcVersion;
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([currentHistoId profPos 0]), ...
         fliplr([1 1 length(value)]), value');
      value = dateUpdate;
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([currentHistoId profPos 0]), ...
         fliplr([1 1 length(value)]), value');
      
      % update the update date of the Output file
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);
      
      % update the 'history' global attribute of the Output file
      creationDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'));
      globalHistoryText = [ ...
         datestr(datenum(creationDate', 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; ' ...
         datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COCQ (V' num2str(g_cocq_ncCopyMonoProfileQcVersion) ') tool)'];
      netcdf.reDef(fCdf);
      netcdf.putAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'history', globalHistoryText);
      netcdf.endDef(fCdf);
   end
   
   netcdf.close(fCdf);
end

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Check if a given variable is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = var_is_present(a_ncId, a_varName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/27/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = var_is_present(a_ncId, a_varName)

o_present = 0;

[nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(a_ncId);

for idVar = 0:nbVars-1
   [varName, varType, varDims, nbAtts] = netcdf.inqVar(a_ncId, idVar);
   if (strcmp(varName, a_varName))
      o_present = 1;
      break
   end
end

return

% ------------------------------------------------------------------------------
% Check if a variable attribute is present in a NetCDF file.
%
% SYNTAX :
%  [o_present] = att_is_present(a_ncId, a_varName, a_attName)
%
% INPUT PARAMETERS :
%   a_ncId    : NetCDF file Id
%   a_varName : variable name
%   a_attName : variable attribute name
%
% OUTPUT PARAMETERS :
%   o_present : 1 if the variable is present (0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_present] = att_is_present(a_ncId, a_varName, a_attName)

o_present = 0;

varId = netcdf.inqVarID(a_ncId, a_varName);
[varName, xType, dimIds, nbAtts] = netcdf.inqVar(a_ncId, varId);

for idAttr = 0:nbAtts-1
   attName = netcdf.inqAttName(a_ncId, varId, idAttr);
   if (strcmp(attName, a_attName))
      o_present = 1;
      break
   end
end

return

% ------------------------------------------------------------------------------
% Adjust the size of 2 character arrays along the second dimension (by padding
% with ' ' characters).
%
% SYNTAX :
%  [o_tab1, o_tab2] = adjust_size(a_tab1, a_tab2)
%
% INPUT PARAMETERS :
%   a_tab1 : input array #1
%   a_tab2 : input array #2
%
% OUTPUT PARAMETERS :
%   a_tab1 : output array #1
%   a_tab2 : output array #2
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tab1, o_tab2] = adjust_size(a_tab1, a_tab2)

o_tab1 = [];
o_tab2 = [];

if (size(a_tab1, 2) > size(a_tab2, 2))
   nColToAdd = size(a_tab1, 2) - size(a_tab2, 2);
   a_tab2 = cat(2, ...
      repmat(' ', size(a_tab2, 1), nColToAdd), ...
      a_tab2);
elseif (size(a_tab1, 2) < size(a_tab2, 2))
   nColToAdd = size(a_tab2, 2) - size(a_tab1, 2);
   a_tab1 = cat(2, ...
      repmat(' ', size(a_tab1, 1), nColToAdd), ...
      a_tab1);
end

o_tab1 = a_tab1;
o_tab2 = a_tab2;

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
      
      if (var_is_present(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         o_ncData = [o_ncData {varName} {varValue}];
      else
         fprintf('WARNING: Variable %s not present in file : %s\n', ...
            varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {' '}];
      end
      
   end
   
   netcdf.close(fCdf);
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
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function init_xml_report(a_time)

% DOM node of XML report
global g_cocq_xmlReportDOMNode;

% decoder version
global g_cocq_ncCopyMonoProfileQcVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041403'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis Qc reporting tool (nc_copy_mono_profile_qc_rt)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_cocq_ncCopyMonoProfileQcVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_cocq_xmlReportDOMNode = docNode;

return

% ------------------------------------------------------------------------------
% Parse input parameters.
%
% SYNTAX :
%  [o_inputError] = parse_input_param(a_varargin)
%
% INPUT PARAMETERS :
%   a_varargin : input parameters
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
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_inputError] = parse_input_param(a_varargin)

% output parameters initialization
o_inputError = 0;

global g_cocq_dirOutputXmlFile;
global g_cocq_xmlReportFileName;
global g_cocq_floatList;
global g_cocq_dirInputQcNcFiles;
global g_cocq_dirInputNcFiles;
global g_cocq_dirOutputNcFiles;
global g_cocq_dirLogFile;

g_cocq_dirOutputXmlFile = [];
g_cocq_xmlReportFileName = [];
g_cocq_floatList = [];
g_cocq_dirInputQcNcFiles = [];
g_cocq_dirInputNcFiles = [];
g_cocq_dirOutputNcFiles = [];
g_cocq_dirLogFile = [];


% ignore empty input parameters
idDel = [];
for id = 1:length(a_varargin)
   if (isempty(a_varargin{id}))
      idDel = [idDel id];
   end
end
a_varargin(idDel) = [];

% check input parameters
if (~isempty(a_varargin))
   if (rem(length(a_varargin), 2) ~= 0)
      fprintf('ERROR: expecting an even number of input arguments (e.g. (''argument_name'', ''argument_value'') - exit\n');
      o_inputError = 1;
      return
   else
      for id = 1:2:length(a_varargin)
         if (strcmpi(a_varargin{id}, 'xmlReportDir'))
            g_cocq_dirOutputXmlFile = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'xmlReport'))
            g_cocq_xmlReportFileName = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'floatWmo'))
            g_cocq_floatList = str2num(a_varargin{id+1});
         elseif (strcmpi(a_varargin{id}, 'inputQcDir'))
            g_cocq_dirInputQcNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'inputDir'))
            g_cocq_dirInputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'outputDir'))
            g_cocq_dirOutputNcFiles = a_varargin{id+1};
         elseif (strcmpi(a_varargin{id}, 'logDir'))
            g_cocq_dirLogFile = a_varargin{id+1};
         else
            fprintf('WARNING: unexpected input argument (%s) - ignored\n', a_varargin{id});
         end
      end
   end
end

% check the xml report file name consistency
if (~isempty(g_cocq_xmlReportFileName))
   if (length(g_cocq_xmlReportFileName) < 29)
      fprintf('WARNING: inconsistent xml report file name (%s) expecting co041403_yyyymmddTHHMMSSZ[_PID].xml - ignored\n', g_cocq_xmlReportFileName);
      g_cocq_xmlReportFileName = [];
   end
end

return

% ------------------------------------------------------------------------------
% Get the basic structure to store report information.
%
% SYNTAX :
%  [o_reportStruct] = get_report_init_struct(a_floatNum, a_floatCycleList)
%
% INPUT PARAMETERS :
%   a_floatNum       : float WMO number
%   a_floatCycleList : processed float cycle list
%
% OUTPUT PARAMETERS :
%   o_reportStruct : report initialized structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportStruct] = get_report_init_struct(a_floatNum)

% output parameters initialization
o_reportStruct = struct( ...
   'floatNum', a_floatNum, ...
   'input_ok', '', ...
   'output_ok', '', ...
   'profNum_ok', '', ...
   'input_ko', '');

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
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_cocq_xmlReportDOMNode;

% report information structure
global g_cocq_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_cocq_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

% list of processings done
for idFloat = 1:length(g_cocq_reportData)
   
   reportStruct = g_cocq_reportData(idFloat);
   
   newChild = docNode.createElement(sprintf('float_%d', idFloat));
   
   newChildBis = docNode.createElement('float_wmo');
   newChildBis.appendChild(docNode.createTextNode(num2str(reportStruct.floatNum)));
   newChild.appendChild(newChildBis);
   
   for idFile = 1:length(reportStruct.input_ok)
      newChildBis = docNode.createElement('ok_file_in');
      textNode = reportStruct.input_ok{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.output_ok)
      newChildBis = docNode.createElement('ok_file_out');
      textNode = reportStruct.output_ok{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.profNum_ok)
      newChildBis = docNode.createElement('ok_prof_num');
      textNode = num2str(reportStruct.profNum_ok{idFile});
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   
   for idFile = 1:length(reportStruct.input_ko)
      newChildBis = docNode.createElement('ko_file_in');
      textNode = reportStruct.input_ko{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
   if (~isempty(reportStruct.input_ko))
      o_status = 'nok';
   end
   
   docRootNode.appendChild(newChild);
end

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
%  [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)
%
% INPUT PARAMETERS :
%   a_logFileName  : log file path name of the run
%
% OUTPUT PARAMETERS :
%   o_infoMsg    : INFO messages
%   o_warningMsg : WARNING messages
%   o_errorMsg   : ERROR messages
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/12/2013 - RNU - creation
% ------------------------------------------------------------------------------
function [o_infoMsg, o_warningMsg, o_errorMsg] = parse_log_file(a_logFileName)

% output parameters initialization
o_infoMsg = [];
o_warningMsg = [];
o_errorMsg = [];

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
      idLine = 1;
      while (1)
         line = fileContents{idLine};
         if (strncmp(line, 'INFO: ', length('INFO: ')))
            o_infoMsg = [o_infoMsg {line(length('INFO: ')+1:end)}];
         elseif (strncmp(line, 'WARNING: ', length('WARNING: ')))
            o_warningMsg = [o_warningMsg {line(length('WARNING: ')+1:end)}];
         elseif (strncmp(line, 'ERROR: ', length('ERROR: ')))
            o_errorMsg = [o_errorMsg {line(length('ERROR: ')+1:end)}];
         end
         idLine = idLine + 1;
         if (idLine > length(fileContents))
            break
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
%   01/02/2010 - RNU - creation
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
