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
PRINT_DIFF_DATA_FLAG = 1;


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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
      [vssQc, cParamStrQc, cDataQc, cDataStrQc, cDataIdQc, ...
         bParamStrQc, bDataQc, bDataStrQc, bDataIdQc, paramListQc, histoQc] = ...
         get_nc_profile_info(qcProfFilePathName, [], 1);

      % check that the Qc file contains SCOOP QC
      if (isempty(histoQc))
         fprintf('WARNING: No SCOOP QC in Qc file [Qc file: %s]\n', ...
            qcProfFilePathName);
         continue
      end

      % check that the Qc file contains only one profile
      if (length(vssQc) > 1)
         fprintf('ERROR: Qc file is expected to contain only one profile (%d profiles in the file) [Qc file: %s]\n', ...
            length(vssQc), qcProfFilePathName);
         
         if (g_cocq_realtimeFlag == 1)
            g_cocq_reportStruct.input_ko = [g_cocq_reportStruct.input_ko {qcProfFilePathName}];
         end
         continue
      end
      
      % retrieve information from input c file
      [vssCInput, cParamStrInput, cDataInput, cDataStrInput, cDataIdInput, ...
         ~, ~, ~, ~, ~, ~] = ...
         get_nc_profile_info(inputProfCFilePathName, paramListQc, 0);
      
      % find the number of the profile to be updated
      profNumToUpdate = -1;
      nbInputProf = length(cDataStrInput);
      for idProf = 1:nbInputProf
         
         currentDataQc = cDataQc{:};
         currentdataInput = cDataInput{idProf};
         currentDataStrQc = cDataStrQc{:};
         currentdataStrInput = cDataStrInput{idProf};
         profNbLevelsQc = size(currentDataStrQc, 1);
         profNbLevelsInput = size(currentdataStrInput, 1);
         if (strcmp(vssQc{:}, vssCInput{idProf}) == 0)
            continue
         elseif (strcmp(cParamStrQc{:}, cParamStrInput{idProf}) == 0)
            continue
         elseif (profNbLevelsQc ~= profNbLevelsInput)
            continue
         else
            dataDiffer = 0;
            for idC = 1:size(currentdataInput, 2)
               if (any(abs(currentdataInput(:, idC)-currentDataQc(:, idC)) > 1.e-5))
                  dataDiffer = 1;
                  break
               end
            end
            %             for idLev = 1:size(currentdataStrInput, 1)
            %                if (~strcmp(currentdataStrInput(idLev, :), currentDataStrQc(idLev, :)))
            %                   dataDiffer = 1;
            %                   break
            %                end
            %             end
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
                     for idLev = 1:size(currentdataStrInput, 1)
                        diffFlag = 0;
                        if (~strcmp(currentdataStrInput(idLev, :), currentDataStrQc(idLev, :)))
                           diffFlag = 1;
                        end
                        fprintf('  %d : %s | %s\n', ...
                           diffFlag, currentdataStrInput(idLev, :), currentDataStrQc(idLev, :));
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
            [vssBInput, ~, ~, ~, ~, ...
               bParamStrInput, bDataInput, bDataStrInput, bDataIdInput, ~, ~] = ...
               get_nc_profile_info(inputProfBFilePathName, paramListQc, 0);
            
            dataQc = bDataQc{:};
            dataInput = bDataInput{profNumToUpdate};
            dataStrQc = bDataStrQc{:};
            dataStrInput = bDataStrInput{profNumToUpdate};
            dataDiffer = 0;
            for idC = 1:size(dataInput, 2)
               if (any(abs(dataInput(:, idC)-dataQc(:, idC)) > 1.e-5))
                  dataDiffer = 1;
                  break
               end
            end
            %             for idLev = 1:size(dataStrInput, 1)
            %                if (~strcmp(dataStrInput(idLev, :), dataStrQc(idLev, :)))
            %                   dataDiffer = 1;
            %                   break
            %                end
            %             end
            if (dataDiffer == 1)
               if (PRINT_DIFF_DATA_FLAG == 1)
                  fprintf('FLAG: Input b (%s) | Qc b (%s)\n', ...
                     bParamStrQc{:}, ...
                     bParamStrInput{idProf});
                  for idLev = 1:size(dataStrInput, 1)
                     diffFlag = 0;
                     if (~strcmp(dataStrInput(idLev, :), dataStrQc(idLev, :)))
                        diffFlag = 1;
                     end
                     fprintf('  %d : %s | %s\n', ...
                        diffFlag, dataStrInput(idLev, :), dataStrQc(idLev, :));
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
      [ok, updatedCFileParamList, updatedBFileParamList] = ...
         nc_update_file(qcProfFilePathName, ...
         outputProfCFilePathName, outputProfBFilePathName, profNumToUpdate, ...
         cDataIdQc{:}, bDataIdQc{:}, cDataIdInput{profNumToUpdate}, bDataIdInputFinal, ...
         paramListQc, histoQc);
      
      if (ok == 1)
         % if the update succeeded move the file(s) in the DIR_OUTPUT_NC_FILES
         % directory
         if (~isempty(updatedCFileParamList) || ~isempty(updatedBFileParamList))
            
            % create the directory
            if ~(exist([DIR_OUTPUT_NC_FILES subPath], 'dir') == 7)
               mkdir([DIR_OUTPUT_NC_FILES subPath]);
            end
            
            if (~isempty(updatedCFileParamList))
               [~, fileName, fileExtension] = fileparts(outputProfCFilePathName);
               finalOutputProfCFilePathName = [DIR_OUTPUT_NC_FILES subPath fileName fileExtension];
               move_file(outputProfCFilePathName, finalOutputProfCFilePathName);
               
               updatedParamList = sprintf('%s,', updatedCFileParamList{:});
               fprintf('INFO: Qc file contents successfully reported into prof #%d of c file [Updated parameters: %s] [Qc file: %s] [c file: %s]\n', ...
                  profNumToUpdate, updatedParamList(1:end-1), qcProfFilePathName, finalOutputProfCFilePathName);
               
               if (g_cocq_realtimeFlag == 1)
                  g_cocq_reportStruct.input_ok = [g_cocq_reportStruct.input_ok {qcProfFilePathName}];
                  g_cocq_reportStruct.output_ok = [g_cocq_reportStruct.output_ok {finalOutputProfCFilePathName}];
                  g_cocq_reportStruct.profNum_ok = [g_cocq_reportStruct.profNum_ok {profNumToUpdate}];
               end
            end
            
            if (~isempty(updatedBFileParamList))
               [~, fileName, fileExtension] = fileparts(outputProfBFilePathName);
               finalOutputProfBFilePathName = [DIR_OUTPUT_NC_FILES subPath fileName fileExtension];
               move_file(outputProfBFilePathName, finalOutputProfBFilePathName);

               updatedParamList = sprintf('%s,', updatedBFileParamList{:});
               fprintf('INFO: Qc file contents successfully reported into prof #%d of b file [Updated parameters: %s] [Qc file: %s] [b file: %s]\n', ...
                  profNumToUpdate, updatedParamList(1:end-1), qcProfFilePathName, finalOutputProfBFilePathName);
               
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
%  [o_vss, o_cParamStr, o_cData, o_cDataStr, o_cDataId, ...
%    o_bParamStr, o_bData, o_bDataStr, o_bDataId, o_paramList, o_histo] = ...
%    get_nc_profile_info(a_profFilePathName, a_refParamlist, a_qcFileFlag)
%
% INPUT PARAMETERS :
%   a_profFilePathName : NetCDF file path name
%   a_refParamlist     : list of parameter names to consider (if empty: consider
%                        all encountered parameters)
%   a_qcFileFlag       : flag to know if it is the QC file that is processed
%
% OUTPUT PARAMETERS :
%   o_vss       : VSS of the profile(s)
%   o_cParamStr : lists of c parameter names of the profile(s)
%   o_cData     : c parameter values of the profile(s)
%   o_cDataStr  : c parameter values of the profile(s) as strings
%   o_cDataId   : c parameter value indices of the profile(s)
%   o_bParamStr : lists of b parameter names of the profile(s)
%   o_bData     : b parameter values of the profile(s)
%   o_bDataStr  : b parameter values of the profile(s) as strings
%   o_bDataId   : b parameter value indices of the profile(s)
%   o_paramList : list of all input file parameter names
%   o_histo     : history information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_vss, o_cParamStr, o_cData, o_cDataStr, o_cDataId, ...
   o_bParamStr, o_bData, o_bDataStr, o_bDataId, o_paramList, o_histo] = ...
   get_nc_profile_info(a_profFilePathName, a_refParamlist, a_qcFileFlag)

% output parameters initialization
o_vss = [];
o_cParamStr = [];
o_cData = [];
o_cDataStr = [];
o_cDataId = [];
o_bParamStr = [];
o_bData = [];
o_bDataStr = [];
o_bDataId = [];
o_paramList = [];
o_histo = [];

% default values
global g_decArgo_janFirst1950InMatlab;


% read the file and retrieve wanted information
if (exist(a_profFilePathName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_profFilePathName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_profFilePathName);
      return
   end

   % in the QC file, look for SCOOP QC information
   if (a_qcFileFlag)

      histSoftware = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'));
      histSoftRelease = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'));
      histDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'));
      histAction = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_ACTION'));
      histParameter = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_PARAMETER'));
      histStartPres = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_START_PRES'));
      histStopPres = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_STOP_PRES'));
      histPreviousValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_PREVIOUS_VALUE'));

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
            hist.startPres = round(double(hist.startPres)/0.001)*0.001;
            hist.stopPres = histStopPres(1, idH);
            hist.stopPres = round(double(hist.stopPres)/0.001)*0.001;
            hist.startLev = -1;
            hist.stopLev = -1;
            hist.qcValues = {''};
            hist.prevVal = histPreviousValue(1, idH);
            o_histo = [o_histo hist];
         end
      end
      % no SCOOP QC to report
      if (isempty(o_histo))
         netcdf.close(fCdf);
         return
      end
      [~, sortId] = sort([o_histo.date]);
      o_histo = o_histo(sortId);
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
      cParamData = [];
      cParamDataAdj = [];
      bParamData = [];
      bParamDataAdj = [];
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

            for idAdj = 1:2

               profData = [];
               profDataStr = [];
               fillValueStr = [];
               presStrIdStart = -1;
               presStrIdStop = -1;
               pressFillValueStr = '';
               for idParam = 1:length(paramForProf)

                  paramStr = paramForProf{idParam};
                  if (idAdj == 1)
                     paramStrAdj = paramStr;
                  else
                     paramStrAdj = [paramStr '_ADJUSTED'];
                     if (~var_is_present_dec_argo(fCdf, paramStrAdj))
                        % for PRES_ADJUSTED in a B-PROF file, we store PRES
                        % values (they will never be used because parameters are
                        % first searched in the cParamForProf list)
                        paramStrAdj = paramStr;
                     end
                  end

                  [varName, xType, dimIds, nbAtts] = netcdf.inqVar(fCdf, netcdf.inqVarID(fCdf, paramStrAdj));
                  if (xType == netcdf.getConstant('NC_FLOAT'))
                     paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramStrAdj));
                  else
                     paramData = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramStrAdj), 'double');
                  end
                  if (ndims(paramData) == 2)
                     profData = [profData paramData(:, idProf)];
                  else
                     profData = [profData paramData(:, :, idProf)];
                  end
                  if (strcmp(paramStr, 'PRES'))
                     profData = round(double(profData)/0.001)*0.001;
                  else
                     profData = round(double(profData)/0.00001)*0.00001;
                  end
                  if ((idType == 1) || (strcmp(paramStr, 'PRES')))
                     if (att_is_present(fCdf, paramStrAdj, 'C_format'))
                        %                      paramFormat = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramStr), 'C_format');
                        paramFormat = '%.5f';
                     else
                        paramFormat = '%.5f';
                     end
                  else
                     paramFormat = '%.5f';
                  end
                  if (att_is_present(fCdf, paramStrAdj, '_FillValue'))
                     paramFillVal = netcdf.getAtt(fCdf, netcdf.inqVarID(fCdf, paramStrAdj), '_FillValue');
                  else
                     [varName, xType, dimIds, nbAtts] = netcdf.inqVar(fCdf, netcdf.inqVarID(fCdf, paramStrAdj));
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
               profData(idDel, :) = [];

               if (idType == 1)
                  if (idAdj == 1)
                     cParamData = [cParamData {profData}];
                     cParamDataStr = [cParamDataStr {profDataStr}];
                     cParamDataId = [cParamDataId {profDataId}];
                  else
                     cParamDataAdj = [cParamDataAdj {profData}];
                  end
               else
                  if (idAdj == 1)
                     bParamData = [bParamData {profData}];
                     bParamDataStr = [bParamDataStr {profDataStr}];
                     bParamDataId = [bParamDataId {profDataId}];
                  else
                     bParamDataAdj = [bParamDataAdj {profData}];
                  end
               end
            end
         end
      end
      
      % update output data
      o_vss = vssList;
      o_cParamStr = cParamList;
      o_cData = cParamData;
      o_cDataStr = cParamDataStr;
      o_cDataId = cParamDataId;
      o_bParamStr = bParamList;
      o_bData = bParamData;
      o_bDataStr = bParamDataStr;
      o_bDataId = bParamDataId;
      o_paramList = unique(paramList);

      if (a_qcFileFlag)

         idPres = find(strcmp(cParamForProf, 'PRES'), 1);
         cVal = cParamData{:};
         presVal = cVal(:, idPres);
         presVal = round(double(presVal)/0.001)*0.001;

         % add QC SCOOP level and check HISTORY information
         for idH = 1:length(o_histo)

            if (~ismember(o_histo(idH).param, [{'DAT$'} {'POS$'}]))

               % SCOOP2 1.x  PRES => value
               % SCOOP3 0.15 PRES => value
               % SCOOP3 0.19 PRES => imm_level
               % SCOOP3 0.33 PRES => imm_level
               % SCOOP3 0.34 PRES => imm_level
               % SCOOP3 0.36 PRES => value
               % SCOOP3 0.38 PRES => value

               hist = o_histo(idH);
               if (ismember(hist.softRelease, [{'0.19'} {'0.33'} {'0.34'}]))
                  hist.startLev = hist.startPres;
                  hist.stopLev = hist.stopPres;
                  hist.startPres = presVal(hist.startLev);
                  hist.stopPres = presVal(hist.stopLev);
               else
                  hist.startLev = find(presVal == hist.startPres);
                  hist.stopLev = find(presVal == hist.stopPres);
               end

               if (isempty(hist.startLev))
                  fprintf('ERROR: PRES value %.3f not found in Qc file information [Qc file: %s]\n', ...
                     hist.startPres, a_profFilePathName);
                  continue
               end
               if (isempty(hist.stopLev))
                  fprintf('ERROR: PRES value %.3f not found in Qc file information [Qc file: %s]\n', ...
                     hist.stopPres, a_profFilePathName);
                  continue
               end

               if ((length(hist.startLev) > 1) || (length(hist.stopLev) > 1))
                  % retrieve hist.param associated values
                  paramNameAdj = hist.param{:};
                  paramName = regexprep(paramNameAdj, '_ADJUSTED', '');
                  idParam = find(strcmp(cParamForProf, paramName), 1);
                  if (~isempty(idParam))
                     if (strcmp(paramName, paramNameAdj))
                        cVal = cParamData{:};
                        paramVal = cVal(:, idParam);
                     else
                        cVal = cParamDataAdj{:};
                        paramVal = cVal(:, idParam);
                     end
                  else
                     idParam = find(strcmp(bParamForProf, paramName), 1);
                     if (strcmp(paramName, paramNameAdj))
                        bVal = bParamData{:};
                        paramVal = bVal(:, idParam);
                     else
                        bVal = bParamDataAdj{:};
                        paramVal = bVal(:, idParam);
                     end
                  end

                  if (length(hist.startLev) > 1)
                     % more than one level have the hist.startLev PRES value
                     % the history action will be considered only if :
                     % 1- the immersion levels are contiguous
                     % 2- the hist.param associated values are the same
                     uDiff = unique(diff(hist.startLev));
                     if ((length(uDiff) == 1) && (uDiff == 1))
                        if (length(unique(paramVal(hist.startLev))) == 1)
                           fprintf('INFO: PRES value %.3f found at %d levels in Qc file information with common ''%s'' value - considered [Qc file: %s]\n', ...
                              hist.startPres, length(hist.startLev), paramNameAdj, a_profFilePathName);
                           hist.startLev = min(hist.startLev);
                        else
                           fprintf('WARNING: PRES value %.3f found at %d levels in Qc file information with multiple ''%s'' values - ignored [Qc file: %s]\n', ...
                              hist.startPres, length(hist.startLev), paramNameAdj, a_profFilePathName);
                           continue
                        end
                     else
                        fprintf('WARNING: PRES value %.3f found at %d levels in Qc file but immersion levels are not contiguous - ignored [Qc file: %s]\n', ...
                           hist.startPres, length(hist.startLev), a_profFilePathName);
                        continue
                     end
                  end

                  if (length(hist.stopLev) > 1)
                     % more than one level have the hist.stopLev PRES value
                     % the history action will be considered only if :
                     % 1- the immersion levels are contiguous
                     % 2- the hist.param associated values are the same
                     uDiff = unique(diff(hist.stopLev));
                     if ((length(uDiff) == 1) && (uDiff == 1))
                        if (length(unique(paramVal(hist.stopLev))) == 1)
                           fprintf('INFO: PRES value %.3f found at %d levels in Qc file information with common ''%s'' value - considered [Qc file: %s]\n', ...
                              hist.stopPres, length(hist.stopLev), paramNameAdj, a_profFilePathName);
                           hist.stopLev = max(hist.stopLev);
                        else
                           fprintf('WARNING: PRES value %.3f found at %d levels in Qc file information with multiple ''%s'' values - ignored [Qc file: %s]\n', ...
                              hist.stopPres, length(hist.stopLev), paramNameAdj, a_profFilePathName);
                           continue
                        end
                     else
                        fprintf('WARNING: PRES value %.3f found at %d levels in Qc file but immersion levels are not contiguous - ignored [Qc file: %s]\n', ...
                           hist.stopPres, length(hist.stopLev), a_profFilePathName);
                        continue
                     end
                  end
               end

               o_histo(idH) = hist;
            end
         end
      end
      
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
%  [o_ok, o_updatedCFileParamList, o_updatedBFileParamList] = ...
%    nc_update_file(a_qcFileName, ...
%    a_outputCFileName, a_outputBFileName, a_profNumToUpdate, ...
%    a_qcCDataId, a_qcBDataId, a_outputCDataId, a_outputBDataId, a_paramListQc, a_histoQc)
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
%   a_paramListQc     : list of Qc file parameter names
%   a_histoQc         : Qc file history information
%
% OUTPUT PARAMETERS :
%   o_ok                    : success flag (1 if Ok, 0 otherwise)
%   o_updatedCFileParamList : updated c file parameters list
%   o_updatedBFileParamList : updated b file parameters list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/18/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok, o_updatedCFileParamList, o_updatedBFileParamList] = ...
   nc_update_file(a_qcFileName, ...
   a_outputCFileName, a_outputBFileName, a_profNumToUpdate, ...
   a_qcCDataId, a_qcBDataId, a_outputCDataId, a_outputBDataId, a_paramListQc, a_histoQc)

% output parameters initialization
o_ok = 0;
o_updatedCFileParamList = [];
o_updatedBFileParamList = [];

% program version
global g_cocq_ncCopyMonoProfileQcVersion;

% QC flag values
global g_decArgo_qcStrDef;

% flag to print QC updated values
global g_cocq_verboseMode;
VERBOSE_MODE = g_cocq_verboseMode;


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
for idParam = 1:length(a_paramListQc)
   paramName = a_paramListQc{idParam};
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
   updatedFlag = 0;
   updatedParamlist = [];
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

   % list of parameters with SCOOP QC
   paramListToReport = unique([a_histoQc.param]);

   % update JULD_QC
   if (any(strcmp(paramListToReport, 'DAT$')))
      idVal = find(strcmp('JULD_QC', qcData) == 1, 1);
      qcJuldQc = qcData{idVal+1};
      currentValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), profPos, 1);
      if (currentValue ~= qcJuldQc)
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'JULD_QC'), profPos, 1, qcJuldQc);
         updatedFlag = 1;
         updatedParamlist{end+1} = 'JULD_QC';
         if (VERBOSE_MODE)
            fprintf('Current JULD_QC: %c\n', currentValue);
            fprintf('New     JULD_QC: %c\n', qcJuldQc);
         end
      end
   end

   % update POSITION_QC
   if (any(strcmp(paramListToReport, 'POS$')))
      idVal = find(strcmp('POSITION_QC', qcData) == 1, 1);
      qcPositionQc = qcData{idVal+1};
      currentValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), profPos, 1);
      if (currentValue ~= qcPositionQc)
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'POSITION_QC'), profPos, 1, qcPositionQc);
         updatedFlag = 1;
         updatedParamlist{end+1} = 'POSITION_QC';
         if (VERBOSE_MODE)
            fprintf('Current POSITION_QC: %c\n', currentValue);
            fprintf('New     POSITION_QC: %c\n', qcPositionQc);
         end
      end
   end

   % PRES values of the current profile
   presValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'PRES'), fliplr([profPos 0]), fliplr([1 nbLevels]));
   presValue = round(double(presValue)/0.001)*0.001;

   % list of parameters with SCOOP QC (excluding JULD_QC and POSITION_QC)
   paramListToReport = setdiff(paramListToReport, [{'DAT$'} {'POS$'}]);

   % update profile and parameter Qc
   for idParam = 1:length(paramListToReport)
      paramName = paramListToReport{idParam};
      paramNamePrefix = paramName;
      if ((length(paramName) > 8) && strcmp(paramName(end-8:end), '_ADJUSTED'))
         paramNamePrefix = paramName(1:end-9);
      end
      paramNameQc = [paramName '_QC'];

      if (var_is_present(fCdf, paramNameQc))
         if (~strcmp(paramNamePrefix, paramName)) % ADJUSTED values
            if (idType == 1)
               if (dataMode(a_profNumToUpdate) == 'R')
                  fprintf('INFO: profile #%d is in ''R'' mode - %s not reported in profile #%d of file : %s\n', ...
                     a_profNumToUpdate, paramNameQc, a_profNumToUpdate, outputFileName);
                  continue
               end
            else
               if (~any(strcmp(paramNamePrefix, adjustedParam)))
                  fprintf('INFO: parameter %s of profile #%d is in ''R'' mode - %s not reported in profile #%d of file : %s\n', ...
                     paramNamePrefix, a_profNumToUpdate, paramNameQc, a_profNumToUpdate, outputFileName);
                  continue
               end
            end
         end

         % <PARAM>_QC values
         idVal = find(strcmp(paramNameQc, qcData) == 1, 1);
         inputValue = qcData{idVal+1};
         inputValue = inputValue(qcDataId);
         currentValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, paramNameQc), fliplr([profPos 0]), fliplr([1 nbLevels]));
         newValue = currentValue(outputDataId);
         newValueOri = newValue;

         for idH = 1:length(a_histoQc)
            hist = a_histoQc(idH);
            if (strcmp(hist.param{:}, paramName))
               if (hist.startLev ~= -1) && (hist.stopLev ~= -1) % error already raised for this case
                  if ((hist.startPres == presValue(hist.startLev)) && ...
                        (hist.stopPres == presValue(hist.stopLev)))
                     if (VERBOSE_MODE)
                     currentStr = sprintf('%c ', newValue(hist.startLev:hist.stopLev));
                     end
                     newValue(hist.startLev:hist.stopLev) = inputValue(hist.startLev:hist.stopLev);
                     if (VERBOSE_MODE)
                        newStr = sprintf('%c ', newValue(hist.startLev:hist.stopLev));
                        fprintf('Current %s(%d,%d): %s\n', ...
                           paramName, hist.startLev, hist.stopLev, currentStr(1:end-1));
                        fprintf('New     %s(%d,%d): %s\n', ...
                           paramName, hist.startLev, hist.stopLev, newStr(1:end-1));
                     end
                  else
                     fprintf('ERROR: parameter %s of profile #%d start and/or stop PRES levels are not consistent\n', ...
                        paramName, a_profNumToUpdate);
                     continue
                  end
               end
            end
         end

         if (any(newValueOri ~= newValue))
            currentValue(outputDataId) = newValue;
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramNameQc), fliplr([profPos 0]), fliplr([1 length(currentValue)]), currentValue);

            % update of PROFILE_<PARAM>_QC
            updateProfQcFlag = 1;
            if (idType == 1)
               if ((dataMode(a_profNumToUpdate) ~= 'R') && strcmp(paramNamePrefix, paramName))
                  updateProfQcFlag = 0; % <PARAM>_QC reported while <PARAM> is in 'A' or 'D' data mode (the PROFILE_<PARAM>_QC should be updated with <PARAM>_ADJUSTED_QC if modified)
               end
            else
               if (strcmp(paramNamePrefix, paramName) && any(strcmp([paramName '_ADJUSTED' ], adjustedParam)))
                  updateProfQcFlag = 0; % <PARAM>_QC reported while <PARAM> is in 'A' or 'D' data mode (the PROFILE_<PARAM>_QC should be updated with <PARAM>_ADJUSTED_QC if modified)
               end
            end

            if (updateProfQcFlag)
               profParamQcName = ['PROFILE_' paramNamePrefix '_QC'];
               if (var_is_present_dec_argo(fCdf, profParamQcName))
                  if ~((length(unique(newValue)) == 1) && (unique(newValue) == g_decArgo_qcStrDef))
                     newProfParamQc = compute_profile_quality_flag(newValue);
                  else
                     newProfParamQc = g_decArgo_qcStrDef;
                  end
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQcName), profPos, 1, newProfParamQc);
               end
            end

            updatedFlag = 1;
            updatedParamlist{end+1} = paramNameQc;
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
      % depending on concerned parameter
      idF = find(strcmp('HISTORY_SOFTWARE', qcData) == 1, 1);
      historySoftware = qcData{idF+1};
      idF = find(strcmp('HISTORY_ACTION', qcData) == 1, 1);
      historyAction = qcData{idF+1};
      idF = find(strcmp('HISTORY_PARAMETER', qcData) == 1, 1);
      historyParameter = qcData{idF+1};
      for idHistory = 1:size(historySoftware, 3)
         for idProf = 1:size(historySoftware, 2) % size(historyParameter, 2) = 1 (only one Coriolis 'station' is concerned by the Qc reported in each file)

            software = historySoftware(:, idProf, idHistory)';
            software = strtrim(software);
            action = historyAction(:, idProf, idHistory)';
            action = strtrim(action);
            parameter = historyParameter(:, idProf, idHistory)';
            parameter = strtrim(parameter);

            copyFlag = 0;
            if (strcmp(software, 'SCOO') && strcmp(action, 'CF') && ~isempty(parameter))
               if (strcmp(parameter, 'DAT$') || strcmp(parameter, 'POS$'))
                  copyFlag = 1;
               else
                  paramName = regexprep(parameter, '_ADJUSTED', '');
                  paramInfo = get_netcdf_param_attributes(paramName);
                  if ((((paramInfo.paramType == 'c') || (paramInfo.paramType == 'j')) && (idType == 1)) || ...
                        (((paramInfo.paramType ~= 'c') && (paramInfo.paramType ~= 'j')) && (idType == 2)))
                     copyFlag = 1;
                  end
               end

               if (copyFlag)

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

      % add history information that concerns the current program

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

      % set output parameters
      if (idType == 1)
         o_updatedCFileParamList = updatedParamlist;
      else
         o_updatedBFileParamList = updatedParamlist;
      end
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
