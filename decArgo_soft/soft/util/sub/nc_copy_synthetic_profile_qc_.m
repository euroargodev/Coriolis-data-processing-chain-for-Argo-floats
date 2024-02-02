% ------------------------------------------------------------------------------
% Create a new set of NetCDF mono-profile files by adding Qc flags (provided in
% NetCDF synthetic-profile file).
%
% SYNTAX :
% nc_copy_synthetic_profile_qc_(a_floatList, a_logFile, ...
%   a_dirInputQcNcFiles, ...
%   a_dirInputEdacNcFiles, ...
%   a_dirInputGdacNcFiles, ...
%   a_dirOutputNcFiles, ...
%   a_dirLogFile, ...
%   a_dirCsvFile)
%
% INPUT PARAMETERS :
%   a_floatList           : list of floats to process
%   a_logFile             : log file name
%   a_dirInputQcNcFiles   : directory of input NetCDF files containing the Qc
%                           values
%   a_dirInputEdacNcFiles : directory of input NetCDF files to be updated
%                           (E-DAC)
%   a_dirInputGdacNcFiles : directory of input S-PROF and META NetCDF files
%                           (G-DAC)
%   a_dirOutputNcFiles    : directory of output NetCDF updated files
%   a_dirLogFile          : directory to store the log file
%   a_dirCsvFile          : directory to store the CSV file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function nc_copy_synthetic_profile_qc_(a_floatList, a_logFile, ...
   a_dirInputQcNcFiles, ...
   a_dirInputEdacNcFiles, ...
   a_dirInputGdacNcFiles, ...
   a_dirOutputNcFiles, ...
   a_dirLogFile, ...
   a_dirCsvFile)

% float number
global g_cocsq_floatNum;

% RT processing flag
global g_cocsq_realtimeFlag;

% XML report information structure
global g_cocsq_reportXmlData;
global g_cocsq_reportXmlStruct;

% CSV report information structure
global g_cocsq_reportCsvData;
g_cocsq_reportCsvData = [];

% top directory of input NetCDF files containing the Qc values
% (top directory of the DAC name directories)
DIR_INPUT_QC_NC_FILES = a_dirInputQcNcFiles;

% top directory of input NetCDF files to be updated
% (E-DAC, thus top directory of the DAC name directories)
DIR_INPUT_EDAC_NC_FILES = a_dirInputEdacNcFiles;

% top directory of input S-PROF and META NetCDF files
% (G-DAC, thus top directory of the DAC name directories)
DIR_INPUT_GDAC_NC_FILES = a_dirInputGdacNcFiles;

% top directory of output NetCDF updated files
% (top directory of the DAC name directories)
DIR_OUTPUT_NC_FILES = a_dirOutputNcFiles;

% directory to store the log file
DIR_LOG_FILE = a_dirLogFile;

% directory to store the csv file
DIR_CSV_FILE = a_dirCsvFile;


diary(a_logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   Qc input files top directory: %s\n', DIR_INPUT_QC_NC_FILES);
fprintf('   Input C-PROF and B-PROF files directory (E-DAC): %s\n', DIR_INPUT_EDAC_NC_FILES);
fprintf('   Input S-PROF and META files directory (G-DAC): %s\n', DIR_INPUT_GDAC_NC_FILES);
fprintf('   Output files top directory: %s\n', DIR_OUTPUT_NC_FILES);
fprintf('   Log output directory: %s\n', DIR_LOG_FILE);
fprintf('   Csv output directory: %s\n', DIR_CSV_FILE);
fprintf('   Floats to process:');
fprintf(' %d', a_floatList);
fprintf('\n');

% create the output directory
if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_NC_FILES);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% list of directories to scan (when looking for C-PROF and/or B-PROF to
% update)
inputDirList = [];
if (exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   inputDirList = [inputDirList {[DIR_OUTPUT_NC_FILES '/']}];
end
inputDirList = [inputDirList {[DIR_INPUT_EDAC_NC_FILES '/']}];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% process the directories of the DIR_INPUT_QC_NC_FILES
nbFloats = length(a_floatList);
floatId = 0;
dirNames = dir(DIR_INPUT_QC_NC_FILES);
for idDir = 1:length(dirNames)

   dacName = dirNames(idDir).name;
   if (strcmp(dacName, '.') || strcmp(dacName, '..'))
      continue
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % process the floats
   dirFloats = dir([DIR_INPUT_QC_NC_FILES '/' dacName]);
   for idFloat = 1:length(dirFloats)

      dirFloat = dirFloats(idFloat).name;
      if (strcmp(dirFloat, '.') || strcmp(dirFloat, '..'))
         continue
      end
      floatNum = str2double(dirFloat);
      g_cocsq_floatNum = floatNum;
      if (~ismember(floatNum, a_floatList))
         continue
      end
      floatId = floatId + 1;
      fprintf('%03d/%03d %d\n', floatId, nbFloats, floatNum);

      if (g_cocsq_realtimeFlag == 1)
         % initialize data structure to store report information
         g_cocsq_reportXmlStruct = get_xml_report_init_struct(floatNum);
      end

      % directory to store temporary files
      DIR_TMP_FILE = [DIR_INPUT_QC_NC_FILES sprintf('/%s/%d/tmp/', dacName, floatNum)];

      % create the temp directory
      if (exist(DIR_TMP_FILE, 'dir') == 7)
         rmdir(DIR_TMP_FILE, 's');
      end
      mkdir(DIR_TMP_FILE);

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % look for the META file of this float
      inputMetaFilePathName = [DIR_INPUT_GDAC_NC_FILES sprintf('/%s/%d/%d_meta.nc', dacName, floatNum, floatNum)];
      if ~(exist(inputMetaFilePathName, 'file') == 2)
         fprintf('ERROR: Float %d: No input META file to get vertical offsets to report Qc file information - float not processed [META file expected in: %s]\n', ...
            g_cocsq_floatNum, [DIR_INPUT_GDAC_NC_FILES sprintf('/%s/%d/', dacName, floatNum)]);

         if (g_cocsq_realtimeFlag == 1)
            g_cocsq_reportXmlStruct.input_ko = [g_cocsq_reportXmlStruct.input_ko {inputMetaFilePathName}];
         end
         continue
      end

      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % process the Qc files of this float
      subPath = sprintf('/%s/%d/profiles/', dacName, floatNum);
      qcProfDirName = [DIR_INPUT_QC_NC_FILES subPath];
      qcProfFileName = [qcProfDirName sprintf('%d_*.nc', floatNum)];
      qcProfFiles = dir(qcProfFileName);

      for idFile = 1:length(qcProfFiles)

         % name of the current Qc file
         qcProfFileName = qcProfFiles(idFile).name;
         qcProfFilePathName = [qcProfDirName qcProfFileName];

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % look for the associated S-PROF file
         inputProfSFilePathName = '';
         idF = strfind(qcProfFileName, '_');
         inputProfFileName = [qcProfFileName(1:idF(end)-1) '.nc'];
         filePathName = [DIR_INPUT_GDAC_NC_FILES subPath 'SD' inputProfFileName];
         if (exist(filePathName, 'file') == 2)
            inputProfSFilePathName = filePathName;
         else
            filePathName = [DIR_INPUT_GDAC_NC_FILES subPath 'SR' inputProfFileName];
            if (exist(filePathName, 'file') == 2)
               inputProfSFilePathName = filePathName;
            end
         end

         % if (isempty(inputProfSFilePathName))
         %    fprintf('ERROR: Float %d: No input S-PROF file to report Qc file information - QC file not processed [Qc file: %s]\n', ...
         %       g_cocsq_floatNum, qcProfFilePathName);
         % 
         %    if (g_cocsq_realtimeFlag == 1)
         %       g_cocsq_reportXmlStruct.input_ko = [g_cocsq_reportXmlStruct.input_ko {qcProfFilePathName}];
         %    end
         %    continue
         % end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % look for the C-PROF and B-PROF files to be updated
         inputProfCFilePathName = '';
         inputProfBFilePathName = '';
         for idD = 1:length(inputDirList)

            % C-PROF file
            if (isempty(inputProfCFilePathName))
               filePathName = [inputDirList{idD} subPath 'D' inputProfFileName];
               if (exist(filePathName, 'file') == 2)
                  inputProfCFilePathName = filePathName;
               else
                  filePathName = [inputDirList{idD} subPath 'R' inputProfFileName];
                  if (exist(filePathName, 'file') == 2)
                     inputProfCFilePathName = filePathName;
                  end
               end
            end

            % B-PROF file
            if (isempty(inputProfBFilePathName))
               filePathName = [inputDirList{idD} subPath 'BD' inputProfFileName];
               if (exist(filePathName, 'file') == 2)
                  inputProfBFilePathName = filePathName;
               else
                  filePathName = [inputDirList{idD} subPath 'BR' inputProfFileName];
                  if (exist(filePathName, 'file') == 2)
                     inputProfBFilePathName = filePathName;
                  end
               end
            end
         end

         if (isempty(inputProfCFilePathName))
            fprintf('ERROR: Float %d: No input C-PROF file to report Qc file information - QC file not processed [Qc file: %s]\n', ...
               g_cocsq_floatNum, qcProfFilePathName);

            if (g_cocsq_realtimeFlag == 1)
               g_cocsq_reportXmlStruct.input_ko = [g_cocsq_reportXmlStruct.input_ko {qcProfFilePathName}];
            end
            continue
         end

         if (isempty(inputMetaFilePathName))
            fprintf('ERROR: Float %d: No input META file to get vertical offsets to report Qc file information - QC file not processed [Qc file: %s]\n', ...
               g_cocsq_floatNum, qcProfFilePathName);

            if (g_cocsq_realtimeFlag == 1)
               g_cocsq_reportXmlStruct.input_ko = [g_cocsq_reportXmlStruct.input_ko {inputMetaFilePathName}];
            end
            continue
         end

         %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % retrieve information on needed updates

         [linkStruct, qcProfData, cProfData, bProfData] = get_sprof_2_prof_links( ...
            qcProfFilePathName, inputProfSFilePathName, ...
            inputProfCFilePathName, inputProfBFilePathName, ...
            inputMetaFilePathName);

         % TEMPO
         % linkStruct = [linkStruct;
         %    [{'c'}    {'PSAL_QC'    }    {[  1]}    {[1 3 5 9]}    {'3'}]];
         % linkStruct = [linkStruct;
         %    [{'c'}    {'JULD_QC'    }    {nan}    {nan}    {'3'}]];
         % linkStruct = [linkStruct;
         %    [{'b'}    {'JULD_QC'    }    {nan}    {nan}    {'3'}]];
         % linkStruct

         if (~isempty(linkStruct))

            % make a copy of the input file(s) to be updated
            outputProfCFilePathName = '';
            if (any([linkStruct{:, 1}] == 'c'))
               copy_file(inputProfCFilePathName, DIR_TMP_FILE);
               [~, fileName, fileExtension] = fileparts(inputProfCFilePathName);
               outputProfCFilePathName = [DIR_TMP_FILE fileName fileExtension];
            end

            outputProfBFilePathName = '';
            if (any([linkStruct{:, 1}] == 'b'))
               copy_file(inputProfBFilePathName, DIR_TMP_FILE);
               [~, fileName, fileExtension] = fileparts(inputProfBFilePathName);
               outputProfBFilePathName = [DIR_TMP_FILE fileName fileExtension];
            end

            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % update the input file(s)
            [ok, updatedCFileParamList, updatedCFileProfList, ...
               updatedBFileParamList, updatedBFileProfList] = ...
               nc_update_file(qcProfData, cProfData, bProfData, ...
               outputProfCFilePathName, outputProfBFilePathName, linkStruct);

            if (ok == 1)
               % if the update succeeded move the file(s) in the
               % DIR_OUTPUT_NC_FILES/DacName directory
               if (~isempty(updatedCFileParamList) || ~isempty(updatedBFileParamList))

                  % create the directory
                  if ~(exist([DIR_OUTPUT_NC_FILES subPath], 'dir') == 7)
                     mkdir([DIR_OUTPUT_NC_FILES subPath]);
                  end

                  if (~isempty(updatedCFileParamList))
                     [~, fileName, fileExtension] = fileparts(outputProfCFilePathName);
                     finalOutputProfCFilePathName = [DIR_OUTPUT_NC_FILES subPath fileName fileExtension];
                     move_file(outputProfCFilePathName, finalOutputProfCFilePathName);

                     updatedCFileParamList = unique(updatedCFileParamList, 'stable');
                     updatedParamList = sprintf('%s,', updatedCFileParamList{:});
                     updatedProfIdList = sprintf('#%d,', updatedCFileProfList);
                     fprintf('INFO: Float: %d: Qc file contents successfully reported into prof %s of C-PROF file [Updated parameters: %s] [Qc file: %s] [c file: %s]\n', ...
                        g_cocsq_floatNum, updatedProfIdList(1:end-1), updatedParamList(1:end-1), qcProfFilePathName, finalOutputProfCFilePathName);

                     if (g_cocsq_realtimeFlag == 1)
                        g_cocsq_reportXmlStruct.input_ok = [g_cocsq_reportXmlStruct.input_ok {qcProfFilePathName}];
                        g_cocsq_reportXmlStruct.output_ok = [g_cocsq_reportXmlStruct.output_ok {finalOutputProfCFilePathName}];
                        g_cocsq_reportXmlStruct.profNum_ok = [g_cocsq_reportXmlStruct.profNum_ok {updatedCFileProfList}];
                     end
                  end

                  if (~isempty(updatedBFileParamList))
                     [~, fileName, fileExtension] = fileparts(outputProfBFilePathName);
                     finalOutputProfBFilePathName = [DIR_OUTPUT_NC_FILES subPath fileName fileExtension];
                     move_file(outputProfBFilePathName, finalOutputProfBFilePathName);

                     updatedBFileParamList = unique(updatedBFileParamList, 'stable');
                     updatedParamList = sprintf('%s,', updatedBFileParamList{:});
                     updatedProfIdList = sprintf('#%d,', updatedBFileProfList);
                     fprintf('INFO: Float: %d: Qc file contents successfully reported into prof %s of B-PROF file [Updated parameters: %s] [Qc file: %s] [c file: %s]\n', ...
                        g_cocsq_floatNum, updatedProfIdList(1:end-1), updatedParamList(1:end-1), qcProfFilePathName, finalOutputProfBFilePathName);

                     if (g_cocsq_realtimeFlag == 1)
                        g_cocsq_reportXmlStruct.input_ok = [g_cocsq_reportXmlStruct.input_ok {qcProfFilePathName}];
                        g_cocsq_reportXmlStruct.output_ok = [g_cocsq_reportXmlStruct.output_ok {finalOutputProfBFilePathName}];
                        g_cocsq_reportXmlStruct.profNum_ok = [g_cocsq_reportXmlStruct.profNum_ok {updatedBFileProfList}];
                     end
                  end
               end
            else
               if (g_cocsq_realtimeFlag == 1)
                  g_cocsq_reportXmlStruct.input_ko = [g_cocsq_reportXmlStruct.input_ko {qcProfFilePathName}];
               end
            end
         end
      end

      % store the information for the XML report
      if (g_cocsq_realtimeFlag == 1)
         g_cocsq_reportXmlData = [g_cocsq_reportXmlData g_cocsq_reportXmlStruct];
      end

      % delete the temp directory
      if (exist(DIR_TMP_FILE, 'dir') == 7)
         rmdir(DIR_TMP_FILE, 's');
      end
   end
end

% print CSV report
print_csv_report(DIR_CSV_FILE);

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Retrieve S-PROF to PROF links.
%
% SYNTAX :
% [o_linkStruct, o_qcProfData, o_cProfData, o_bProfData] = ...
%   get_sprof_2_prof_links(a_qcProfFileName, a_sProfFileName, ...
%   a_cProfFileName, a_bProfFileName, a_metaFileName)
%
% INPUT PARAMETERS :
%   a_qcProfFileName : input QC file path name
%   a_cProfFileName  : input S-PROF file path name
%   a_cProfFileName  : input C-PROF file path name
%   a_bProfFileName  : input B-PROF file path name
%   a_metaFileName   : input META file path name
%
% OUTPUT PARAMETERS :
%   o_linkStruct : information to link S-PROF to PROF
%   o_qcProfData : Qc file data
%   o_cProfData  : C-PROF file data
%   o_bProfData  : B-PROF file data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_linkStruct, o_qcProfData, o_cProfData, o_bProfData] = ...
   get_sprof_2_prof_links(a_qcProfFileName, a_sProfFileName, ...
   a_cProfFileName, a_bProfFileName, a_metaFileName)

% output parameter initialization
o_linkStruct = [];
o_qcProfData = [];
o_cProfData = [];
o_bProfData = [];

% float number
global g_cocsq_floatNum;

% default values
global g_decArgo_janFirst1950InMatlab;

% XML report information structure
global g_cocsq_reportXmlStruct;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve input file data
qcProfData = get_prof_data(a_qcProfFileName, 1);
if (~isempty(a_sProfFileName))
   sProfData = get_prof_data(a_sProfFileName, 2);
else
   sProfData = qcProfData; % we will use qcProfData under the assumption that all <PARAM>_dPRES = 0
end
cProfData = get_prof_data(a_cProfFileName, 3);
bProfData = [];
if (~isempty(a_sProfFileName))
   bProfData = get_prof_data(a_bProfFileName, 4);
end

if (isempty(qcProfData) || isempty(sProfData) || isempty(cProfData))
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve SCOOP QC from Qc file
histSoftware = qcProfData.HISTORY_SOFTWARE;
histSoftRelease = qcProfData.HISTORY_SOFTWARE_RELEASE;
histDate = qcProfData.HISTORY_DATE;
histAction = qcProfData.HISTORY_ACTION;
histParameter = qcProfData.HISTORY_PARAMETER;
histStartPres = qcProfData.HISTORY_START_PRES;
histStopPres = qcProfData.HISTORY_STOP_PRES;
histPrevVal = qcProfData.HISTORY_PREVIOUS_VALUE;

qcHisto = [];
[~, ~, nHistory] = size(histSoftware);
for idH = 1:nHistory
   soft = strtrim(histSoftware(:, 1, idH)');
   action = strtrim(histAction(:, 1, idH)');
   if (strcmp(soft, 'SCOO') && strcmp(action, 'CF'))
      hist = '';
      hist.soft = soft;
      hist.action = action;
      hist.softRelease = {strtrim(histSoftRelease(:, 1, idH)')};
      hDate = strtrim(histDate(:, 1, idH)');
      hist.date = datenum(hDate, 'yyyymmddHHMMSS') - g_decArgo_janFirst1950InMatlab;
      hist.param = {strtrim(histParameter(:, 1, idH)')};
      hist.startPres = histStartPres(1, idH);
      hist.startPres = round_argo(hist.startPres, 'PRES');
      hist.stopPres = histStopPres(1, idH);
      hist.stopPres = round_argo(hist.stopPres, 'PRES');
      hist.startLev = -1;
      hist.stopLev = -1;
      hist.prevVal = histPrevVal(idH);
      qcHisto = [qcHisto hist];
   end
end
% no SCOOP QC to report
if (isempty(qcHisto))
   fprintf('WARNING: No SCOOP QC in Qc file : %s\n', ...
      a_qcProfFileName);
   return
end
[~, sortId] = sort([qcHisto.date]);
qcHisto = qcHisto(sortId);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% retrieve sensor vertical offsets and assign them to concerned B-PROF N_PROF Id
if (~isempty(a_sProfFileName))
   bProfData = get_vertical_offset(a_metaFileName, bProfData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% link SCOOP QC to C-PROF and/or B-PROF N_PROF and N_LEVEL

% list of parameters with SCOOP QC
paramListToReportAll = [qcHisto.param];
paramListToReport = unique(paramListToReportAll, 'stable');

% update JULD_QC
if (any(strcmp(paramListToReport, 'DAT$')))
   if (~isempty(a_sProfFileName))
      o_linkStruct = [o_linkStruct; ...
         [{'c'} {'JULD_QC'} {nan} {nan} {qcProfData.JULD_QC}]; ...
         [{'b'} {'JULD_QC'} {nan} {nan} {qcProfData.JULD_QC}]];
   else
      o_linkStruct = [o_linkStruct; ...
         [{'c'} {'JULD_QC'} {nan} {nan} {qcProfData.JULD_QC}]];
   end
end

% update POSITION_QC
if (any(strcmp(paramListToReport, 'POS$')))
   if (~isempty(a_sProfFileName))
      o_linkStruct = [o_linkStruct; ...
         [{'c'} {'POSITION_QC'} {nan} {nan} {qcProfData.POSITION_QC}]; ...
         [{'b'} {'POSITION_QC'} {nan} {nan} {qcProfData.POSITION_QC}]];
   else
      o_linkStruct = [o_linkStruct; ...
         [{'c'} {'POSITION_QC'} {nan} {nan} {qcProfData.POSITION_QC}]];
   end
end

% PRES values of Qc file
qcPresVal = qcProfData.PRES;
qcPresVal = round_argo(qcPresVal, 'PRES');

% PRES values of S-PROF file
sPresVal = sProfData.PRES;
sPresVal = round_argo(sPresVal, 'PRES');

% list of parameters with SCOOP QC (excluding JULD_QC and POSITION_QC)
paramListToReport = setdiff(paramListToReport, [{'DAT$'} {'POS$'}]);
for idParam = 1:length(paramListToReport)
   paramName = paramListToReport{idParam};
   paramNamePrefix = paramName;
   if ((length(paramName) > 8) && strcmp(paramName(end-8:end), '_ADJUSTED'))
      paramNamePrefix = paramName(1:end-9);
   end
   paramNameQc = [paramName '_QC'];
   paramNameDPres = [paramNamePrefix '_dPRES'];

   qcDataQc = qcProfData.(paramNameQc);

   sData = sProfData.(paramName);
   sData = round_argo(sData, paramName);

   paramInfo = get_netcdf_param_attributes(paramNamePrefix);
   if (ismember(paramInfo.paramType, 'ib'))

      if (isempty(a_sProfFileName))
         fprintf('ERROR: Float %d: No input S-PROF file to report Qc file information - QC file not processed [Qc file: %s]\n', ...
            g_cocsq_floatNum, a_qcProfFileName);

         if (g_cocsq_realtimeFlag == 1)
            g_cocsq_reportXmlStruct.input_ko = [g_cocsq_reportXmlStruct.input_ko {a_qcProfFileName}];
         end
         continue
      end

      profData = bProfData.(paramName);
      profPres = bProfData.PRES;
      profPresOffset = bProfData.PRES_OFFSET;
      profPresOffset(isnan(profPresOffset)) = 0;
      fileType = 'b';
      % when DOXY2 is measured by a PTSO float, it is provided in the same
      % N_PROF as the DOXY measurements, however, the OPTODE_DOXY vertical
      % offset should not be used, use a vertical offset of 0
      % this should not happen in a BGC float where DOXY2 is provided on its own
      % N_PROF
      if (strcmp(paramNamePrefix, 'DOXY2') && (size(profData, 2) == 2))
         profPresOffset = zeros(size(profPresOffset));
      end
   else
      profData = cProfData.(paramName);
      profPres = cProfData.PRES;
      profPresOffset = zeros(1, size(cProfData.PRES, 2));
      fileType = 'c';
   end

   % look for the concerned N_PROF
   profId = [];
   for idProf = 1:size(profData, 2)
      if (any(profData(:, idProf) ~= paramInfo.fillValue))
         profId = [profId idProf];
      end
   end
   profId = unique(profId);
   if (isempty(profId))
      fprintf('WARNING: Float %d: Cannot find profile with %s values [Qc file: %s] - SCOOP QC not reported\n', ...
         g_cocsq_floatNum, paramName, a_qcProfFileName);
      continue
   end

   % process SCOOP QCs for this parameter
   histoParamId = find(strcmp(paramListToReportAll, paramName));
   for idH = histoParamId
      hist = qcHisto(idH);

      % SCOOP2 1.x  PRES => value
      % SCOOP3 0.15 PRES => value
      % SCOOP3 0.19 PRES => imm_level
      % SCOOP3 0.33 PRES => imm_level
      % SCOOP3 0.34 PRES => imm_level
      % SCOOP3 0.36 PRES => value
      % SCOOP3 0.38 PRES => value

      % assign startLev and stopLev
      if (ismember(hist.softRelease, [{'0.19'} {'0.33'} {'0.34'}]))
         hist.startLev = hist.startPres;
         hist.stopLev = hist.stopPres;
         hist.startPres = qcPresVal(hist.startLev);
         hist.stopPres = qcPresVal(hist.stopLev);
      else
         hist.startLev = find(qcPresVal == hist.startPres);
         hist.stopLev = find(qcPresVal == hist.stopPres);
      end
      if (~isempty(hist.startLev) && ~isempty(hist.stopLev))
         qcHisto(idH) = hist;
      elseif (isempty(hist.startLev) || isempty(hist.stopLev))
         if (isempty(hist.startLev) )
            fprintf('WARNING: Float %d: PRES = %.3f not found in Qc file [Qc file: %s] - SCOOP QC not reported\n', ...
               g_cocsq_floatNum, hist.startPres, a_qcProfFileName);
         end
         if (isempty(hist.stopLev))
            fprintf('WARNING: Float %d: PRES = %.3f not found in Qc file [Qc file: %s] - SCOOP QC not reported\n', ...
               g_cocsq_floatNum, hist.stopPres, a_qcProfFileName);
         end
         continue
      end
         
      % retrieve <PARAM>_dPRES value in S-PROF
      % keep only Ids where <PARAM>_dPRES = 0
      if (~isempty(a_sProfFileName))
         if ((qcPresVal(hist.startLev) ~=  sPresVal(hist.startLev)) || ...
               (qcPresVal(hist.stopLev) ~=  sPresVal(hist.stopLev)))
            if (qcPresVal(hist.startLev) ~=  sPresVal(hist.startLev))
               fprintf('WARNING: Float %d: PRES = %.3f not found in S-PROF file [Qc file: %s] - SCOOP QC not reported\n', ...
                  g_cocsq_floatNum, hist.startPres, a_qcProfFileName);
            end
            if (qcPresVal(hist.stopLev) ~=  sPresVal(hist.stopLev))
               fprintf('WARNING: Float %d: PRES = %.3f not found in S-PROF file [Qc file: %s] - SCOOP QC not reported\n', ...
                  g_cocsq_floatNum, hist.stopPres, a_qcProfFileName);
            end
            continue
         end
         if (~strcmp(paramNamePrefix, 'PRES'))
            sDPres = sProfData.(paramNameDPres);
            levelList = hist.startLev:hist.stopLev;
            sDPres = sDPres(levelList);
            sDPres = round_argo(sDPres, 'PRES');
            % only _dPRES = 0 levels are reported
            idF = find(sDPres == 0);
            levelList = levelList(idF);
         else
            levelList = hist.startLev:hist.stopLev;
         end
      else
         sProfData = qcProfData;
         levelList = hist.startLev:hist.stopLev; % the input S-PROF file is created from a C-PROF file only (and is not available) => <PARAM>_dPRES = 0
      end

      if (~isempty(levelList))
         matchOnce = 0;
         for idProf = profId
            profIdData = profData(:, idProf);
            profIdData = round_argo(profIdData, paramName);

            profIdPres = round_argo(profPres(:, idProf), 'PRES');
            sPresValComp = round_argo(double(sProfData.PRES) - profPresOffset(idProf), 'PRES');

            for idLev = levelList
               if (length(sPresValComp) >= idLev)
                  matchList = find((profIdPres == sPresValComp(idLev)) & (profIdData == sData(idLev)));
                  if (~isempty(matchList))
                     o_linkStruct = [o_linkStruct; ...
                        [{fileType} {paramNameQc} {idProf} {matchList} {qcDataQc(idLev)}]];
                     matchOnce = 1;
                     % else
                     %    fprintf('ERROR: PRES = %.3f and %s = %.5f not found in PROF file [Qc file: %s] - SCOOP QC not reported\n', ...
                     %       sPresValComp(idLev), paramName, sData(idLev), a_qcProfFileName);
                  end
               end
            end
         end
         if (~matchOnce)
            fprintf('WARNING: Float %d: Some %s measurements not found in PROF file [Qc file: %s] - SCOOP QC not reported\n', ...
               g_cocsq_floatNum, paramName, a_qcProfFileName);
         end
      end
   end
end

o_qcProfData = qcProfData;
o_cProfData = cProfData;
o_bProfData = bProfData;

return

% ------------------------------------------------------------------------------
% Retrieve data from profile file.
%
% SYNTAX :
%  [o_profData] = get_prof_data(a_profFileName, a_profFileType)
%
% INPUT PARAMETERS :
%   a_profFileName : profile file path name
%   a_profFileType : profile file type (1: Qc file, 2: S-PROF, 3: C-PROF, 4:
%                    B-PROF)
%
% OUTPUT PARAMETERS :
%   o_profData : retrieved data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profData] = get_prof_data(a_profFileName, a_profFileType)

% output parameter initialization
o_profData = [];


% retrieve information from PROF file
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'STATION_PARAMETERS'} ...
   ];
[profData1] = get_data_from_nc_file(a_profFileName, wantedVars);

% check the PROF file format version
if (ismember(a_profFileType, [3 4 ])) % C-PROF and B-PROF
   formatVersion = deblank(get_data_from_name('FORMAT_VERSION', profData1)');
   if (~strcmp(formatVersion, '3.1'))
      fprintf('ERROR: Input PROF file (%s) format version is %s while 3.1 is expected - not used\n', ...
         a_profFileName, formatVersion);
      return
   end
end

% create the list of parameters to be retrieved from PROF file
if (a_profFileType == 1) % Qc file
   wantedVars = [ ...
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
elseif (a_profFileType == 2) % S-PROF file
   wantedVars = [];
else
   wantedVars = [ ...
      {'CYCLE_NUMBER'} ...
      {'DIRECTION'} ...
      {'DATA_CENTRE'} ...
      {'VERTICAL_SAMPLING_SCHEME'} ...
      ];
end

% add parameter measurements
stationParameters = get_data_from_name('STATION_PARAMETERS', profData1);
parameterList = [];
parameterList2 = [];
[~, nParam, nProf] = size(stationParameters);
for idProf = 1:nProf
   profParamList = [];
   for idParam = 1:nParam
      paramName = deblank(stationParameters(:, idParam, idProf)');

      if (strcmp(paramName, 'PRES_CORE'))
         continue
      end

      if (~isempty(paramName))
         paramInfo = get_netcdf_param_attributes(paramName);
         if ((paramInfo.paramType == 'c') || (paramInfo.paramType == 'b'))
            profParamList{end+1} = paramName;
            parameterList2{end+1} = paramName;
            if (strcmp(paramName, 'PRES') && (a_profFileType == 4)) % B-PROF
               wantedVars = [wantedVars ...
                  {paramName} ...
                  ];
            else
               wantedVars = [wantedVars ...
                  {paramName} ...
                  {[paramName '_QC']} ...
                  {[paramName '_ADJUSTED']} ...
                  {[paramName '_ADJUSTED_QC']} ...
                  {[paramName '_ADJUSTED_ERROR']} ...
                  ];
            end
            if (a_profFileType == 2) % S-PROF
               if (~strcmp(paramName, 'PRES'))
                  wantedVars = [wantedVars ...
                     {[paramName '_dPRES']} ...
                     ];
               end
            end
         end
      end
   end
   parameterList = [parameterList; {profParamList}];
end

% retrieve information from PROF file
[profData2] = get_data_from_nc_file(a_profFileName, wantedVars);

% store data into output structure
o_profData.PARAM_LIST = unique(parameterList2, 'stable');
o_profData.PARAM_LIST = parameterList;
for idP = 1:2:length(profData2)
   o_profData.(profData2{idP}) = profData2{idP+1};
end

return

% ------------------------------------------------------------------------------
% Update the QC of given mono-profile NetCDF file(s) (c file and b file if
% exists).
%
% SYNTAX :
% [o_ok, o_updatedCFileParamList, o_updatedCFileProfList, ...
%   o_updatedBFileParamList, o_updatedBFileProfList] = ...
%   nc_update_file(a_qcProfData, a_outputCFileName, a_outputBFileName, a_linkStruct)
%
% INPUT PARAMETERS :
%   o_qcProfData      : Qc file data
%   a_outputCFileName : output c file path name
%   a_outputBFileName : output b file path name
%   a_cProfData       : C-PROF file data
%   a_bProfData       : B-PROF file data
%   a_linkStruct      : information to link S-PROF to PROF
%
% OUTPUT PARAMETERS :
%   o_ok                    : success flag (1 if Ok, 0 otherwise)
%   o_updatedCFileParamList : updated c file parameters list
%   o_updatedCFileProfList  : updated c file profile Id list
%   o_updatedBFileParamList : updated b file parameters list
%   o_updatedBFileProfList  : updated b file profile Id list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_updatedCFileParamList, o_updatedCFileProfList, ...
   o_updatedBFileParamList, o_updatedBFileProfList] = ...
   nc_update_file(a_qcProfData, a_cProfData, a_bProfData, ...
   a_outputCFileName, a_outputBFileName, a_linkStruct)

% output parameters initialization
o_ok = 0;
o_updatedCFileParamList = [];
o_updatedCFileProfList = [];
o_updatedBFileParamList = [];
o_updatedBFileProfList = [];

% program version
global g_cocsq_ncCopySyntheticProfileQcVersion;

% QC flag values
global g_decArgo_qcStrDef;

% date of the run
global g_cocsq_nowUtc;

% CSV report information structure
global g_cocsq_reportCsvData;

% flag to print QC updated values
global g_cocsq_verboseMode;
VERBOSE_MODE = g_cocsq_verboseMode;

% update the output file(s)
for idType = 1:2
   updatedFlag = 0;
   updatedParamList = [];
   updatedProfIdList = [];
   if (idType == 1)
      % c file update
      idLink = find(strcmp(a_linkStruct(:, 1), 'c'));
      if (isempty(idLink))
         continue
      end
      outputFileName = a_outputCFileName;
      profData = a_cProfData;
   else
      % b file update
      idLink = find(strcmp(a_linkStruct(:, 1), 'b'));
      if (isempty(idLink))
         continue
      end
      outputFileName = a_outputBFileName;
      profData = a_bProfData;
   end

   % open the output file to update
   fCdf = netcdf.open(outputFileName, 'NC_WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', outputFileName);
      return
   end

   % retrieve the N_LEVELS dimension value
   [~, nbLevels] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_LEVELS'));

   % retrieve the N_PROF dimension value
   [~, nbProf] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_PROF'));

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update JULD_QC
   idForJuld = find(strcmp(a_linkStruct(idLink, 2), 'JULD_QC'));
   if (~isempty(idForJuld))
      % exclude bounce profiles from the update process
      noBounceProf = [];
      vssValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'VERTICAL_SAMPLING_SCHEME'));
      for idProf = 1:nbProf
         vss = strtrim(vssValue(:, idProf)');
         if (~strncmp(vss, 'Bounce sampling:', length('Bounce sampling:')))
            noBounceProf = [noBounceProf idProf];
         end
      end
      currentValueOri = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'));
      currentValue = currentValueOri(noBounceProf);
      newValue = currentValue;
      for idR = idLink(idForJuld)'
         newValue = repmat(a_linkStruct{idR, 5}, size(currentValue));
      end
      if (any(newValue ~= currentValue))
         newValueOri = currentValueOri;
         newValueOri(noBounceProf) = newValue;
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), newValueOri);
         updatedFlag = 1;
         updatedParamList{end+1} = 'JULD_QC';
         updatedProfIdList = [updatedProfIdList noBounceProf];
         if (VERBOSE_MODE)
            fprintf('Current JULD_QC: %c\n', currentValue(1));
            fprintf('New     JULD_QC: %c\n', newValue(1));
         end
         if (idType == 1) % no need to be duplicated in the CSV report
            for idProf = noBounceProf
               reportCsvStruct = get_csv_report_init_struct;

               reportCsvStruct.DAC_CODE = strtrim(profData.DATA_CENTRE(:, 1)');
               reportCsvStruct.CV_NUMBER = profData.CYCLE_NUMBER(1);
               reportCsvStruct.DIRECTION = profData.DIRECTION(1);
               reportCsvStruct.PARAMETER = 'DAT$';
               reportCsvStruct.START_IMMERSION = '';
               reportCsvStruct.STOP_IMMERSION = '';
               reportCsvStruct.OLD_QC = currentValue;
               reportCsvStruct.NEW_QC = newValue;
               reportCsvStruct.VERTICAL_SAMPLING_SCHEME = '';
               reportCsvStruct.START_IMMLEVEL = '';
               reportCsvStruct.STOP_IMMLEVEL = '';
               reportCsvStruct.PROFILE_NUMBER = idProf;

               g_cocsq_reportCsvData = [g_cocsq_reportCsvData reportCsvStruct];
            end
         end
      end
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update POSITION_QC
   idForPos = find(strcmp(a_linkStruct(idLink, 2), 'POSITION_QC'));
   if (~isempty(idForPos))
      % exclude bounce profiles from the update process
      noBounceProf = [];
      vssValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'VERTICAL_SAMPLING_SCHEME'));
      for idProf = 1:nbProf
         vss = strtrim(vssValue(:, idProf)');
         if (~strncmp(vss, 'Bounce sampling:', length('Bounce sampling:')))
            noBounceProf = [noBounceProf idProf];
         end
      end
      currentValueOri = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'));
      currentValue = currentValueOri(noBounceProf);
      newValue = currentValue;
      for idR = idLink(idForPos)'
         newValue = repmat(a_linkStruct{idR, 5}, size(currentValue));
      end
      if (any(newValue ~= currentValue))
         newValueOri = currentValueOri;
         newValueOri(noBounceProf) = newValue;
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), newValueOri);
         updatedFlag = 1;
         updatedParamList{end+1} = 'POSITION_QC';
         updatedProfIdList = [updatedProfIdList noBounceProf];
         if (VERBOSE_MODE)
            fprintf('Current POSITION_QC: %c\n', currentValue(1));
            fprintf('New     POSITION_QC: %c\n', newValue(1));
         end
         if (idType == 1) % no need to be duplicated in the CSV report
            for idProf = noBounceProf
               reportCsvStruct = get_csv_report_init_struct;

               reportCsvStruct.DAC_CODE = strtrim(profData.DATA_CENTRE(:, 1)');
               reportCsvStruct.CV_NUMBER = profData.CYCLE_NUMBER(1);
               reportCsvStruct.DIRECTION = profData.DIRECTION(1);
               reportCsvStruct.PARAMETER = 'POS$';
               reportCsvStruct.START_IMMERSION = '';
               reportCsvStruct.STOP_IMMERSION = '';
               reportCsvStruct.OLD_QC = currentValue;
               reportCsvStruct.NEW_QC = newValue;
               reportCsvStruct.VERTICAL_SAMPLING_SCHEME = '';
               reportCsvStruct.START_IMMLEVEL = '';
               reportCsvStruct.STOP_IMMLEVEL = '';
               reportCsvStruct.PROFILE_NUMBER = idProf;

               g_cocsq_reportCsvData = [g_cocsq_reportCsvData reportCsvStruct];
            end
         end
      end
   end

   % list of parameters with SCOOP QC
   paramListToReport = unique([a_linkStruct(idLink, 2)], 'stable');
   paramListToReport = setdiff(paramListToReport, [{'JULD_QC'} {'POSITION_QC'}]);

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % update <PARAM>_QC
   for idParamToReport = 1:length(paramListToReport)
      paramNameQc = paramListToReport{idParamToReport};
      paramName = paramNameQc(1:end-3);
      paramNamePrefix = paramName;
      if ((length(paramName) > 8) && strcmp(paramName(end-8:end), '_ADJUSTED'))
         paramNamePrefix = paramName(1:end-9);
      end

      if (var_is_present(fCdf, paramNameQc))
         idForParam = find(strcmp(a_linkStruct(idLink, 2), paramNameQc));

         profIdList = unique([a_linkStruct{idLink(idForParam)', 3}], 'stable');
         for profId = profIdList
            idForProf = find(strcmp(a_linkStruct(idLink, 2), paramNameQc) & ...
               ([a_linkStruct{idLink, 3}] == profId)');
            currentValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramNameQc), fliplr([profId-1 0]), fliplr([1 nbLevels]));
            newValue = currentValue;
            for idR = idLink(idForProf)'
               newValue(a_linkStruct{idR, 4}) = a_linkStruct{idR, 5};
            end
            if (any(newValue ~= currentValue))
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramNameQc), fliplr([profId-1 0]), fliplr([1 nbLevels]), newValue);
               updatedFlag = 1;
               updatedParamList{end+1} = paramNameQc;
               updatedProfIdList = [updatedProfIdList profId];
               idDiff = find(newValue ~= currentValue);
               for id = 1:length(idDiff)
                  reportCsvStruct = get_csv_report_init_struct;

                  reportCsvStruct.DAC_CODE = strtrim(profData.DATA_CENTRE(:, profId)');
                  reportCsvStruct.CV_NUMBER = profData.CYCLE_NUMBER(profId);
                  reportCsvStruct.DIRECTION = profData.DIRECTION(profId);
                  reportCsvStruct.PARAMETER = paramName;
                  reportCsvStruct.START_IMMERSION = profData.PRES(idDiff(id), profId);
                  reportCsvStruct.STOP_IMMERSION = profData.PRES(idDiff(id), profId);
                  reportCsvStruct.OLD_QC = currentValue(idDiff(id));
                  reportCsvStruct.NEW_QC = newValue(idDiff(id));
                  vss = strtrim(profData.VERTICAL_SAMPLING_SCHEME(:, profId)');
                  idF = strfind(vss, ':');
                  reportCsvStruct.VERTICAL_SAMPLING_SCHEME = vss(1:idF(1)-1);
                  reportCsvStruct.START_IMMLEVEL = idDiff(id);
                  reportCsvStruct.STOP_IMMLEVEL = idDiff(id);
                  reportCsvStruct.PROFILE_NUMBER = profId;

                  g_cocsq_reportCsvData = [g_cocsq_reportCsvData reportCsvStruct];
               end
               if (VERBOSE_MODE)
                  for id = 1:length(idDiff)
                     fprintf('Current %s(%d,%d): %c\n', ...
                        paramNameQc, profId, idDiff(id), currentValue(idDiff(id)));
                     fprintf('New     %s(%d,%d): %c\n', ...
                        paramNameQc, profId, idDiff(id), newValue(idDiff(id)));
                  end
               end

               % check if PROFILE_<PARAM>_QC should be updated
               updateProfQcFlag = 1;
               if (idType == 1)
                  dataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATA_MODE'));
                  if ((dataMode(profId) ~= 'R') && strcmp(paramNamePrefix, paramName))
                     updateProfQcFlag = 0; % <PARAM>_QC reported while <PARAM> is in 'A' or 'D' data mode (the PROFILE_<PARAM>_QC should be updated with <PARAM>_ADJUSTED_QC if modified)
                  end
               else
                  parameterDataMode = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER_DATA_MODE'))';
                  stationParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));

                  % create the list of adjusted parameters for this profile
                  adjustedParam = [];
                  for idParam = 1:size(stationParameters, 2)
                     paramName = strtrim(stationParameters(:, idParam, profId)');
                     if (~isempty(paramName))
                        if (ismember(parameterDataMode(profId, idParam), 'AD'))
                           adjustedParam = [adjustedParam {paramName}];
                        end
                     end
                  end
                  if (strcmp(paramNamePrefix, paramName) && any(strcmp([paramNamePrefix '_ADJUSTED' ], adjustedParam)))
                     updateProfQcFlag = 0; % <PARAM>_QC reported while <PARAM> is in 'A' or 'D' data mode (the PROFILE_<PARAM>_QC should be updated with <PARAM>_ADJUSTED_QC if modified)
                  end
               end

               %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
               % update of PROFILE_<PARAM>_QC
               if (updateProfQcFlag)
                  profParamQcName = ['PROFILE_' paramNamePrefix '_QC'];
                  if (var_is_present_dec_argo(fCdf, profParamQcName))
                     currentProfParamQc = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), profId-1, 1);
                     if ~((length(unique(newValue)) == 1) && (unique(newValue) == g_decArgo_qcStrDef))
                        newProfParamQc = compute_profile_quality_flag(newValue);
                     else
                        newProfParamQc = g_decArgo_qcStrDef;
                     end
                     if (newProfParamQc ~= currentProfParamQc)
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), profId-1, 1, newProfParamQc);
                        updatedFlag = 1;
                        updatedParamList{end+1} = profParamQcName;
                        updatedProfIdList = [updatedProfIdList profId];
                        if (VERBOSE_MODE)
                           fprintf('Current %s: %c\n', profParamQcName, currentProfParamQc);
                           fprintf('New     %s: %c\n', profParamQcName, newProfParamQc);
                        end
                     end
                  end
               end
            end
         end
      end
   end

   if (updatedFlag)

      % retrieve the current HISTORY Id of the output file
      currentHistoId = 0;
      outputHistoryInstitution = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'));
      if (~isempty(outputHistoryInstitution))
         currentHistoId = size(outputHistoryInstitution, 3);
      end

      % copy SCOOP HISTORY information from QC file to c or b output file
      historySoftware = a_qcProfData.HISTORY_SOFTWARE;
      historyAction = a_qcProfData.HISTORY_ACTION;
      historyParameter = a_qcProfData.HISTORY_PARAMETER;

      [~, nProf, nHistory] = size(historySoftware); % nProf = in QC file
      for idH = 1:nHistory
         for idP = 1:nProf
            software = strtrim(historySoftware(:, idP, idH)');
            action = strtrim(historyAction(:, idP, idH)');
            if (strcmp(software, 'SCOO') && strcmp(action, 'CF'))

               parameter = strtrim(historyParameter(:, 1, idH)');

               copyFlag = 0;
               if (strcmp(parameter, 'DAT$') || strcmp(parameter, 'POS$'))
                  copyFlag = 1;
               else
                  parameter = regexprep(parameter, '_ADJUSTED', '');
                  paramInfo = get_netcdf_param_attributes(parameter);
                  if ((((paramInfo.paramType == 'c') || (paramInfo.paramType == 'j')) && (idType == 1)) || ...
                        (((paramInfo.paramType ~= 'c') && (paramInfo.paramType ~= 'j')) && (idType == 2)))
                     copyFlag = 1;
                  end
               end

               if (copyFlag)

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

                     inputValue = a_qcProfData.(histoItemParamName);
                     if (~isempty(inputValue)) % if N_HISTORY = 0 (should not happen but has
                        % been seen for unknown reason) the variables are not present in the
                        % input Qc file
                        data = strtrim(inputValue(:, idP, idH)');
                        if (~isempty(data))
                           netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, histoItemParamName), ...
                              fliplr([currentHistoId idP-1 0]), ...
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

                     inputValue = a_qcProfData.(histoItemParamName);
                     if (~isempty(inputValue)) % if N_HISTORY = 0 (should not happen but has
                        % been seen for unknown reason) the variables are not present in the
                        % input Qc file
                        data = inputValue(idP, idH);
                        netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, histoItemParamName), ...
                           fliplr([currentHistoId idP-1]), ...
                           fliplr([1 1]), data);
                     end
                  end
                  currentHistoId = currentHistoId + 1;
               end
            end
         end
      end

      % add history information that concerns the current program
      dateUpdate = datestr(g_cocsq_nowUtc, 'yyyymmddHHMMSS');
      updatedProfIdList = unique(updatedProfIdList);
      for idProf = updatedProfIdList
         value = 'IF';
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
            fliplr([currentHistoId idProf-1 0]), ...
            fliplr([1 1 length(value)]), value');
         value = 'COCQ';
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
            fliplr([currentHistoId idProf-1 0]), ...
            fliplr([1 1 length(value)]), value');
         value = g_cocsq_ncCopySyntheticProfileQcVersion;
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
            fliplr([currentHistoId idProf-1 0]), ...
            fliplr([1 1 length(value)]), value');
         value = dateUpdate;
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
            fliplr([currentHistoId idProf-1 0]), ...
            fliplr([1 1 length(value)]), value');
      end

      % update the update date of the Output file
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);

      % update the 'history' global attribute of the Output file
      creationDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'));
      globalHistoryText = [ ...
         datestr(datenum(creationDate', 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; ' ...
         datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COCQ (V' num2str(g_cocsq_ncCopySyntheticProfileQcVersion) ') tool)'];
      netcdf.reDef(fCdf);
      netcdf.putAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'history', globalHistoryText);
      netcdf.endDef(fCdf);

      % set output parameters
      if (idType == 1)
         o_updatedCFileParamList = updatedParamList;
         o_updatedCFileProfList = updatedProfIdList;
      else
         o_updatedBFileParamList = updatedParamList;
         o_updatedBFileProfList = updatedProfIdList;
      end
   end

   netcdf.close(fCdf);
end

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Retrieve vertical offsets of each sensor from meta-data file and assign it to
% the concerned profile number.
%
% SYNTAX :
% [o_bProfData] = get_vertical_offset(a_metaFileName, a_bProfData)
%
% INPUT PARAMETERS :
%   a_metaFileName : meta-data file path name
%   a_bProfData    : input BGC profile data
%
% OUTPUT PARAMETERS :
%   o_bProfData : updated BGC profile data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bProfData] = get_vertical_offset(a_metaFileName, a_bProfData)

% output parameter initialization
o_bProfData = a_bProfData;


if (isempty(a_bProfData))
   return
end

% retrieve information from NetCDF meta file
wantedVars = [ ...
   {'LAUNCH_CONFIG_PARAMETER_NAME'} ...
   {'LAUNCH_CONFIG_PARAMETER_VALUE'} ...
   {'PARAMETER'} ...
   {'PARAMETER_SENSOR'} ...
   ];

[ncMetaData] = get_data_from_nc_file(a_metaFileName, wantedVars);

launchConfigParameterName = [];
idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_NAME', ncMetaData) == 1);
if (~isempty(idVal))
   launchConfigParameterNameTmp = ncMetaData{idVal+1}';

   for id = 1:size(launchConfigParameterNameTmp, 1)
      launchConfigParameterName{end+1} = deblank(launchConfigParameterNameTmp(id, :));
   end
end

launchConfigParameterValue = [];
idVal = find(strcmp('LAUNCH_CONFIG_PARAMETER_VALUE', ncMetaData) == 1);
if (~isempty(idVal))
   launchConfigParameterValue = ncMetaData{idVal+1}';
end

parameterMeta = [];
idVal = find(strcmp('PARAMETER', ncMetaData) == 1);
if (~isempty(idVal))
   parameterMetaTmp = ncMetaData{idVal+1}';

   for id = 1:size(parameterMetaTmp, 1)
      parameterMeta{end+1} = deblank(parameterMetaTmp(id, :));
   end
end

parameterSensorMeta = [];
idVal = find(strcmp('PARAMETER_SENSOR', ncMetaData) == 1);
if (~isempty(idVal))
   parameterSensorMetaTmp = ncMetaData{idVal+1}';

   for id = 1:size(parameterSensorMetaTmp, 1)
      parameterSensorMeta{end+1} = deblank(parameterSensorMetaTmp(id, :));
   end
end

% assign each defined vertical pressure offset to its corresponding N_PROF
o_bProfData.PRES_OFFSET = nan(1, size(o_bProfData.PRES, 2));
idF = cellfun(@(x) strfind(launchConfigParameterName, x), {'VerticalPressureOffset_dbar'}, 'UniformOutput', 0);
idF = find(~cellfun(@isempty, idF{:}) == 1);
for idC = idF

   % get short sensor name from configuration label
   configName = launchConfigParameterName{idC};
   configValue = launchConfigParameterValue(idC);
   idF1 = strfind(configName, 'VerticalPressureOffset_dbar');
   shortSensorName = configName(8:idF1-1);
   shortSensorName = lower(shortSensorName);

   % retrieve list of sensors associated to short sensor name
   switch (shortSensorName)
      case 'crover'
         sensorNameList = [{'TRANSMISSOMETER_CP'}];
      case 'eco'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'FLUOROMETER_CDOM'} {'BACKSCATTERINGMETER_BBP'}];
      case 'flbb'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_BBP'}];
      case 'flntu'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'BACKSCATTERINGMETER_TURBIDITY'}];
      case 'isus'
         sensorNameList = [{'SPECTROPHOTOMETER_NITRATE'}];
      case 'mcoms'
         sensorNameList = [{'FLUOROMETER_CHLA'} {'FLUOROMETER_CDOM'} {'BACKSCATTERINGMETER_BBP'}];
      case 'ocr'
         sensorNameList = [{'RADIOMETER_DOWN_IRR'} {'RADIOMETER_PAR'}];
      case 'optode'
         sensorNameList = [{'OPTODE_DOXY'}];
      case 'sfet'
         sensorNameList = [{'TRANSISTOR_PH'}];
      case 'suna'
         sensorNameList = [{'SPECTROPHOTOMETER_NITRATE'} {'SPECTROPHOTOMETER_BISULFIDE'}];
      otherwise
         fprintf('ERROR: Don''t know how to manage short sensor name ''%s'' to assign VerticalPressureOffset_dbar to the concerned profile data - not considered\n', ...
            shortSensorName);
         continue
   end

   % retrieve associated list of parameters
   paramList = [];
   for idS = 1:length(sensorNameList)
      idF2 = find(cellfun(@(x) strcmp(x, sensorNameList(idS)), parameterSensorMeta));
      for id = idF2
         paramList{end+1} = parameterMeta{id};
      end
   end

   % look for the concerned N_PROF
   profId = [];
   for idParam = 1:length(paramList)
      if (isfield(a_bProfData, paramList{idParam}))
         paramName = paramList{idParam};
         paramInfo = get_netcdf_param_attributes(paramName);
         data = a_bProfData.(paramName);
         for idProf = 1:size(data, 2)
            if (any(data(:, idProf) ~= paramInfo.fillValue))
               profId = [profId idProf];
            end
         end
      end
   end
   profId = unique(profId);

   if (~isempty(profId))
      o_bProfData.PRES_OFFSET(profId) = configValue;
   end
end

return

% ------------------------------------------------------------------------------
% Get the basic structure to store XML report information.
%
% SYNTAX :
%  [o_reportStruct] = get_xml_report_init_struct(a_floatNum)
%
% INPUT PARAMETERS :
%   a_floatNum : float WMO number
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
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportStruct] = get_xml_report_init_struct(a_floatNum)

% output parameters initialization
o_reportStruct = struct( ...
   'floatNum', a_floatNum, ...
   'input_ok', '', ...
   'output_ok', '', ...
   'profNum_ok', '', ...
   'input_ko', '');

return

% ------------------------------------------------------------------------------
% Get the basic structure to store CSV report information.
%
% SYNTAX :
%  [o_reportStruct] = get_csv_report_init_struct
%
% INPUT PARAMETERS :
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
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_reportStruct] = get_csv_report_init_struct

% float number
global g_cocsq_floatNum;

% date of the run
global g_cocsq_nowUtc;

% output parameters initialization
o_reportStruct = struct( ...
   'DAC_CODE', '', ...
   'PLATFORM_CODE', g_cocsq_floatNum, ...
   'CV_NUMBER', '', ...
   'DATE_UPDATE', datestr(g_cocsq_nowUtc, 'dd/mm/yyyy HH:MM:SS'), ...
   'DIRECTION', '', ...
   'WEB_URL', ['https://fleetmonitoring.euro-argo.eu/float/' num2str(g_cocsq_floatNum)], ...
   'PARAMETER', '', ...
   'START_IMMERSION', '', ...
   'STOP_IMMERSION', '', ...
   'OLD_QC', '', ...
   'NEW_QC', '', ...
   'VERTICAL_SAMPLING_SCHEME', '', ...
   'START_IMMLEVEL', '', ...
   'STOP_IMMLEVEL', '', ...
   'PROFILE_NUMBER', '');

return

% ------------------------------------------------------------------------------
% Print output CSV report on QC updates.
%
% SYNTAX :
% print_csv_report(a_dirCsvFile)
%
% INPUT PARAMETERS :
%   a_dirCsvFile : directory to store the CSV file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function print_csv_report(a_dirCsvFile)

% CSV report information structure
global g_cocsq_reportCsvData;

% date of the run
global g_cocsq_nowUtc;


if (isempty(g_cocsq_reportCsvData))
   return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clean CSV report data
mergedList = [];
uDacCode = unique({g_cocsq_reportCsvData.DAC_CODE});
for idDac = 1:length(uDacCode)
   dacCode = uDacCode{idDac};
   idForDac = find(strcmp({g_cocsq_reportCsvData.DAC_CODE}, dacCode));

   % TEMPO
   % data = [ ...
   %    {g_cocsq_reportCsvData(idForDac).PLATFORM_CODE}' ...
   %    {g_cocsq_reportCsvData(idForDac).PARAMETER}' ...
   %    {g_cocsq_reportCsvData(idForDac).CV_NUMBER}' ...
   %    {g_cocsq_reportCsvData(idForDac).DIRECTION}' ...
   %    {g_cocsq_reportCsvData(idForDac).PROFILE_NUMBER}' ...
   %    {g_cocsq_reportCsvData(idForDac).START_IMMLEVEL}' ...
   %    {g_cocsq_reportCsvData(idForDac).STOP_IMMLEVEL}' ...
   %    {g_cocsq_reportCsvData(idForDac).OLD_QC}' ...
   %    {g_cocsq_reportCsvData(idForDac).NEW_QC}' ...
   %    ];
   % g_cocsq_reportCsvData(idForDac(3)).STOP_IMMLEVEL = 4;
   % g_cocsq_reportCsvData(idForDac(3)).OLD_QC = '1';
   % data = [ ...
   %    {g_cocsq_reportCsvData(idForDac).PLATFORM_CODE}' ...
   %    {g_cocsq_reportCsvData(idForDac).PARAMETER}' ...
   %    {g_cocsq_reportCsvData(idForDac).CV_NUMBER}' ...
   %    {g_cocsq_reportCsvData(idForDac).DIRECTION}' ...
   %    {g_cocsq_reportCsvData(idForDac).PROFILE_NUMBER}' ...
   %    {g_cocsq_reportCsvData(idForDac).START_IMMLEVEL}' ...
   %    {g_cocsq_reportCsvData(idForDac).STOP_IMMLEVEL}' ...
   %    {g_cocsq_reportCsvData(idForDac).OLD_QC}' ...
   %    {g_cocsq_reportCsvData(idForDac).NEW_QC}' ...
   %    ];

   uParam = unique({g_cocsq_reportCsvData(idForDac).PARAMETER});
   for idParam = 1:length(uParam)
      param = uParam{idParam};
      if (ismember(param, [{'POS$'} {'DAT$'}]))
         continue
      end
      idForParam = find(strcmp({g_cocsq_reportCsvData.DAC_CODE}, dacCode) & ...
         strcmp({g_cocsq_reportCsvData.PARAMETER}, param));
      data = [];
      for idL = idForParam
         if (g_cocsq_reportCsvData(idL).DIRECTION == 'D')
            dir = 1;
         else
            dir = 2;
         end
         data = [data; ...
            [g_cocsq_reportCsvData(idL).PLATFORM_CODE ...
            dir ...
            g_cocsq_reportCsvData(idL).CV_NUMBER ...
            g_cocsq_reportCsvData(idL).PROFILE_NUMBER ...
            str2num(g_cocsq_reportCsvData(idL).OLD_QC) ...
            str2num(g_cocsq_reportCsvData(idL).NEW_QC) ...
            g_cocsq_reportCsvData(idL).START_IMMLEVEL ...
            g_cocsq_reportCsvData(idL).STOP_IMMLEVEL ...
            idL] ...
            ];
      end
      [uData, ~, idDouble] = unique(data(:, 1:6), 'rows');
      if (size(uData, 1) ~= size(data, 1))
         uIdDouble = unique(idDouble);
         for idD = 1:length(uIdDouble)
            idForD = find(idDouble == uIdDouble(idD));
            if (length(idForD) > 1)
               data2 = data(idForD, :);
               [~, idSort] = sort(data2(:, 7));
               data2 = data2(idSort, :);
               merge = 1;
               stop = data2(1, 8);
               for id = 2:size(data2, 1)
                  if (data2(id, 7) == stop + 1)
                     merge = [merge id];
                  else
                     if (length(merge) > 1)
                        mergedList{end+1} = data2(merge', 9);
                     end
                     merge = id;
                  end
                  stop = data2(id, 8);
               end
               if (length(merge) > 1)
                  mergedList{end+1} = data2(merge', 9);
               end
            end
         end
      end
   end
end
idDel = [];
for idM = 1:length(mergedList)
   mList = mergedList{idM}';
   g_cocsq_reportCsvData(mList(1)).STOP_IMMERSION = g_cocsq_reportCsvData(mList(end)).STOP_IMMERSION;
   g_cocsq_reportCsvData(mList(1)).STOP_IMMLEVEL = g_cocsq_reportCsvData(mList(end)).STOP_IMMLEVEL;
   idDel = [idDel mList(2:end)];
end
g_cocsq_reportCsvData(idDel) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create CSV reports (one for each DATA_CENTRE)

uDacCode = unique({g_cocsq_reportCsvData.DAC_CODE});
for idDac = 1:length(uDacCode)
   dacCode = uDacCode{idDac};
   idForDac = find(strcmp({g_cocsq_reportCsvData.DAC_CODE}, dacCode));

   % CSV output file path name
   csvFilepathName = [a_dirCsvFile '/ar_scoop_' dacCode '_' datestr(g_cocsq_nowUtc, 'yyyymmddTHHMMSS') '.csv'];

   % write CSV report
   fId = fopen(csvFilepathName, 'wt');
   if (fId == -1)
      fprintf('ERROR: Unable to create output CSV file: %s\n', csvFilepathName);
      return
   end

   header = 'DAC_CODE,PLATFORM_CODE,CV_NUMBER,DATE_UPDATE,DIRECTION,WEB_URL,PARAMETER,START_IMMERSION,STOP_IMMERSION,OLD_QC,NEW_QC,VERTICAL_SAMPLING_SCHEME,START_IMMLEVEL,STOP_IMMLEVEL,PROFILE_NUMBER';
   fprintf(fId, '%s\n', header);

   for idL = idForDac
      reportCsvStruct = g_cocsq_reportCsvData(idL);
      if (ismember(reportCsvStruct.PARAMETER, [{'POS$'} {'DAT$'}]))
         fprintf(fId, '%s,%d,%d,%s,%c,%s,%s,,,%c,%c,,,,%d\n', ...
            reportCsvStruct.DAC_CODE, ...
            reportCsvStruct.PLATFORM_CODE, ...
            reportCsvStruct.CV_NUMBER, ...
            reportCsvStruct.DATE_UPDATE, ...
            reportCsvStruct.DIRECTION, ...
            reportCsvStruct.WEB_URL, ...
            reportCsvStruct.PARAMETER, ...
            unique(reportCsvStruct.OLD_QC), ...
            unique(reportCsvStruct.NEW_QC), ...
            reportCsvStruct.PROFILE_NUMBER);

      else
         fprintf(fId, '%s,%d,%d,%s,%c,%s,%s,%.3f,%.3f,%c,%c,%s,%d,%d,%d\n', ...
            reportCsvStruct.DAC_CODE, ...
            reportCsvStruct.PLATFORM_CODE, ...
            reportCsvStruct.CV_NUMBER, ...
            reportCsvStruct.DATE_UPDATE, ...
            reportCsvStruct.DIRECTION, ...
            reportCsvStruct.WEB_URL, ...
            reportCsvStruct.PARAMETER, ...
            reportCsvStruct.START_IMMERSION, ...
            reportCsvStruct.STOP_IMMERSION, ...
            reportCsvStruct.OLD_QC, ...
            reportCsvStruct.NEW_QC, ...
            reportCsvStruct.VERTICAL_SAMPLING_SCHEME, ...
            reportCsvStruct.START_IMMLEVEL, ...
            reportCsvStruct.STOP_IMMLEVEL, ...
            reportCsvStruct.PROFILE_NUMBER);
      end
   end

   fclose(fId);
end

return

% ------------------------------------------------------------------------------
% Round parameter measurement to a precision associated to each parameter
%
% SYNTAX :
% [o_values] = round_argo(a_values, a_paramName)
%
% INPUT PARAMETERS :
%   a_values    : input data
%   a_paramName : parameter name
%
% OUTPUT PARAMETERS :
%   o_values : output rounded data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_values] = round_argo(a_values, a_paramName)

o_values = double(a_values);

paramName = regexprep(a_paramName, '_ADJUSTED', '');

switch (paramName)
   case {'PRES'}
      res = 1e-3;
   case {'TEMP'}
      res = 1e-3;
   case {'PSAL'}
      res = 1e-4;
   case {'DOXY'}
      res = 1e-3;
   case {'CHLA', 'CHLA_FLUORESCENCE'}
      res = 1e-4;
   case {'NITRATE'}
      res = 1e-3;
   case {'PH_IN_SITU_TOTAL'}
      res = 1e-4;
   case {'BBP470', 'BBP532', 'BBP700'}
      res = 1e-7;
   otherwise
      res = 1e-7;
end

paramInfo = get_netcdf_param_attributes(paramName);
if (~isempty(paramInfo))
   idNoDef = find(a_values ~= paramInfo.fillValue);
else
   idNoDef = 1:length(a_values);
end
o_values(idNoDef) = round(double(a_values(idNoDef))/res)*res;

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
%   09/20/2023 - RNU - creation
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
%   09/20/2023 - RNU - creation
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
% Get data from name in a {var_name}/{var_data} list.
%
% SYNTAX :
%  [o_dataValues] = get_data_from_name(a_dataName, a_dataList)
%
% INPUT PARAMETERS :
%   a_dataName : name of the data to retrieve
%   a_dataList : {var_name}/{var_data} list
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
%   09/20/2023 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
end

return
