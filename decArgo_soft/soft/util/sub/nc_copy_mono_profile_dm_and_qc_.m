% ------------------------------------------------------------------------------
% Copy DM data and QC values set by the COriolis SCOOP tool.
%
% SYNTAX :
%  nc_copy_mono_profile_dm_and_qc_(a_floatList, a_logFile, ...
%    a_dirInputOldNcFiles, ...
%    a_dirInputNewNcFiles, ...
%    a_dirOutputNcFiles, ...
%    a_ignoredParameterList, ...
%    a_dirLogFile)
%
% INPUT PARAMETERS :
%   a_floatList            : list of float WMO to be processed
%   a_logFile              : log file name
%   a_dirInputOldNcFiles   : name of input OLD data set directory
%   a_dirInputNewNcFiles   : name of input NEW data set directory
%   a_dirOutputNcFiles     : name of output data set directory
%   a_ignoredParameterList : list of 'B' parameters to ignore in the copy of DM
%                            data and the report of SCOOP QCs
%   a_dirLogFile           : directory to store the log file
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function nc_copy_mono_profile_dm_and_qc_(a_floatList, a_logFile, ...
   a_dirInputOldNcFiles, ...
   a_dirInputNewNcFiles, ...
   a_dirOutputNcFiles, ...
   a_ignoredParameterList, ...
   a_dirLogFile)

% RT processing flag
global g_cocd_realtimeFlag;

% report information structure
global g_cocd_reportData;
global g_cocd_reportStruct;

% current references
global g_cocd_floatNum;
global g_cocd_cycleNum;
global g_cocd_cycleDir;

% list of updated files
global g_cocd_updatedFileNameList;

% list of deleted files
global g_cocd_deletedFileNameList;

% top directory of OLD input NetCDF files containing the Qc values and DM
% data
DIR_INPUT_OLD_NC_FILES = a_dirInputOldNcFiles;

% top directory of NEW input NetCDF files
DIR_INPUT_NEW_NC_FILES = a_dirInputNewNcFiles;

% top directory of output NetCDF updated files
DIR_OUTPUT_NC_FILES = a_dirOutputNcFiles;

% directory to store the log file
DIR_LOG_FILE = a_dirLogFile;


% retrieve the list of parameters to be ignored in the report of SCOOP QCs
ignoredParamListAll = get_associated_param(a_ignoredParameterList);

diary(a_logFile);
tic;

fprintf('PARAMETERS:\n');
fprintf('   OLD input files directory (existing files with DM data and QC flag set with external tools): %s\n', DIR_INPUT_OLD_NC_FILES);
fprintf('   NEW input files directory (''newly'' decoded files): %s\n', DIR_INPUT_NEW_NC_FILES);
fprintf('   Output files directory: %s\n', DIR_OUTPUT_NC_FILES);
fprintf('   Log output directory: %s\n', DIR_LOG_FILE);
fprintf('   Parameters ignored in the report of SCOOP QCs:');
if (~isempty(ignoredParamListAll))
   fprintf(' %s', a_ignoredParameterList{:});
else
   fprintf(' NONE');
end
fprintf('\n');
fprintf('   Floats to process:');
fprintf(' %d', a_floatList);
fprintf('\n');

% create the output directory
if ~(exist(DIR_OUTPUT_NC_FILES, 'dir') == 7)
   mkdir(DIR_OUTPUT_NC_FILES);
end

% process the floats
errorProfInfoAll = [];
nbFloats = length(a_floatList);
for idFloat = 1:nbFloats
   
   g_cocd_floatNum = a_floatList(idFloat);
   floatNum = g_cocd_floatNum;
   floatNumStr = num2str(floatNum);
   fprintf('%03d/%03d %d\n', idFloat, nbFloats, floatNum);
   
   errorProfInfo = [];

   if (g_cocd_realtimeFlag == 1)
      % initialize data structure to store report information
      g_cocd_reportStruct = get_report_init_struct(floatNum);
   end
   
   % check that float directory exists in OLD and NEW file directories
   floatOldDirPathName = [DIR_INPUT_OLD_NC_FILES '/' floatNumStr '/'];
   floatNewDirPathName = [DIR_INPUT_NEW_NC_FILES '/' floatNumStr '/'];
   if ((exist(floatOldDirPathName, 'dir') == 7) && (exist(floatNewDirPathName, 'dir') == 7))
      
      oldProfDir = [DIR_INPUT_OLD_NC_FILES '/' floatNumStr '/profiles/'];
      newProfDir = [DIR_INPUT_NEW_NC_FILES '/' floatNumStr '/profiles/'];
      
      % check that it is a BGC float
      files = dir([newProfDir '/' 'B*' floatNumStr '_' '*.nc']);
      if (isempty(files))
         fprintf('   => not a BGC float\n');
         continue
      end
      
      % create the list of available cycle numbers (from PROF files)
      cyNumListOld = [];
      cyNumListOldNot31 = [];
      cyNumListNew = [];
      for idDir = 1:2
         if (idDir == 1)
            dirName = oldProfDir;
         else
            dirName = newProfDir;
         end
         files = dir([dirName '/' '*' floatNumStr '_' '*.nc']);
         cyNumList = [];
         cyNumListNot31 = [];
         for idFile = 1:length(files)
            fileName = files(idFile).name;
            if ((fileName(1) == 'D') || (fileName(1) == 'R'))
               idF = strfind(fileName, floatNumStr);
               cyNumStr = fileName(idF+length(floatNumStr)+1:end-3);
               if (cyNumStr(end) == 'D')
                  cyNumStr(end) = [];
               end
               % consider only OLD files in Argo 3.1 format
               if (idDir == 1)
                  profDataOld = get_data_from_nc_file([dirName '/' fileName], {'FORMAT_VERSION'});
                  formatVersionOld = deblank(get_data_from_name('FORMAT_VERSION', profDataOld)');
                  if (strcmp(formatVersionOld, '3.1'))
                     cyNumList = [cyNumList str2num(cyNumStr)];
                  else
                     fprintf('INFO: File %s is not in 3.1 version - not considered\n', ...
                        fileName);
                     cyNumListNot31 = [cyNumListNot31 str2num(cyNumStr)];
                  end
               else
                  cyNumList = [cyNumList str2num(cyNumStr)];
               end
            end
         end
         cyNumList = unique(cyNumList);
         cyNumListNot31 = unique(cyNumListNot31);
         if (idDir == 1)
            cyNumListOld = cyNumList;
            cyNumListOldNot31 = cyNumListNot31;
         else
            cyNumListNew = cyNumList;
         end
      end
      
      % compare cycle lists
      if (~isempty(setdiff([cyNumListOld cyNumListOldNot31], cyNumListNew)))
         cyNumMissingList = setdiff([cyNumListOld cyNumListOldNot31], cyNumListNew);
         cyNumMissingListStr = sprintf('#%d ', cyNumMissingList);
         fprintf('ERROR: Following cycles (%s) are only in "OLD DIRECTORY" (%s)\n', ...
            cyNumMissingListStr(1:end-1), floatOldDirPathName);
      end
      if (~isempty(setdiff(cyNumListNew, [cyNumListOld cyNumListOldNot31])))
         cyNumMissingList = setdiff(cyNumListNew, [cyNumListOld cyNumListOldNot31]);
         cyNumMissingListStr = sprintf('#%d ', cyNumMissingList);
         fprintf('INFO: Following cycles (%s) are only in "NEW DIRECTORY" (%s)\n', ...
            cyNumMissingListStr(1:end-1), floatNewDirPathName);
      end
      
      % process PROF files
      cyNumList = intersect(cyNumListOld, cyNumListNew);
      for idCy = 1:length(cyNumList)
         
         g_cocd_cycleNum = cyNumList(idCy);
                  
         % process descending and ascending profiles
         for idDir = 1:2
            
            if (idDir == 1)
               g_cocd_cycleDir = 'D';
            else
               g_cocd_cycleDir = '';
            end
            
            profFileNameOld = '';
            cProfFileDmOld = '';
            bProfFileNameOld = '';
            bProfFileDmOld = '';
            profFileNameNew = '';
            cProfFileDmNew = '';
            bProfFileNameNew = '';
            bProfFileDmNew = '';
            for id = 1:2
               if (id == 1)
                  profDir = oldProfDir;
               else
                  profDir = newProfDir;
               end
               profFileName = '';
               cProfFileDm = '';
               bProfFileName = '';
               bProfFileDm = '';
               if (exist([profDir '/' sprintf('D%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)], 'file') == 2)
                  profFileName = [profDir '/' sprintf('D%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)];
                  cProfFileDm = 1;
               elseif (exist([profDir '/' sprintf('R%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)], 'file') == 2)
                  profFileName = [profDir '/' sprintf('R%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)];
                  cProfFileDm = 0;
               end
               if (exist([profDir '/' sprintf('BD%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)], 'file') == 2)
                  bProfFileName = [profDir '/' sprintf('BD%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)];
                  bProfFileDm = 1;
               elseif (exist([profDir '/' sprintf('BR%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)], 'file') == 2)
                  bProfFileName = [profDir '/' sprintf('BR%d_%03d%c.nc', g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir)];
                  bProfFileDm = 0;
               end
               if (id == 1)
                  profFileNameOld = profFileName;
                  cProfFileDmOld = cProfFileDm;
                  bProfFileNameOld = bProfFileName;
                  bProfFileDmOld = bProfFileDm;
               else
                  profFileNameNew = profFileName;
                  cProfFileDmNew = cProfFileDm;
                  bProfFileNameNew = bProfFileName;
                  bProfFileDmNew = bProfFileDm;
               end
            end
            
            if (~isempty(profFileNameOld) && ~isempty(bProfFileNameOld) && ...
                  ~isempty(profFileNameNew) && ~isempty(bProfFileNameNew))
               if ((cProfFileDmOld >= cProfFileDmNew) && ...
                     (bProfFileDmOld >= bProfFileDmNew))
                  
                  fprintf('   %02d/%02d: Float #%d Cycle #%d%c\n', ...
                     idCy, length(cyNumList), g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
                  
                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % process current cycle files
                  process_cycle( ...
                     profFileNameOld, cProfFileDmOld, ...
                     bProfFileNameOld, bProfFileDmOld, ...
                     profFileNameNew, cProfFileDmNew, ...
                     bProfFileNameNew, bProfFileDmNew, ...
                     a_ignoredParameterList, ignoredParamListAll, a_dirOutputNcFiles);
                  
               else
                  if (cProfFileDmOld < cProfFileDmNew)
                     fprintf('ERROR: Float #%d Cycle #%d%c: C-PROF file in DM in "NEW DIRECTORY" only\n', ...
                        g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
                  end
                  if (bProfFileDmOld < bProfFileDmNew)
                     fprintf('ERROR: Float #%d Cycle #%d%c: B-PROF file in DM in "NEW DIRECTORY" only\n', ...
                        g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
                  end
                  errorProfInfo = [errorProfInfo; [g_cocd_floatNum, g_cocd_cycleNum, idDir]];
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.errorProf = [g_cocd_reportStruct.errorProf {[g_cocd_floatNum, g_cocd_cycleNum, idDir]}];
                  end
                  continue
               end
            elseif (~isempty(profFileNameOld) && isempty(bProfFileNameOld) && ...
                  ~isempty(profFileNameNew) && isempty(bProfFileNameNew))
               if ((cProfFileDmOld >= cProfFileDmNew))

                  fprintf('   %02d/%02d: Float #%d Cycle #%d%c - only C-PROF files\n', ...
                     idCy, length(cyNumList), g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);

                  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                  % process current cycle files
                  process_cycle( ...
                     profFileNameOld, cProfFileDmOld, ...
                     bProfFileNameOld, bProfFileDmOld, ...
                     profFileNameNew, cProfFileDmNew, ...
                     bProfFileNameNew, bProfFileDmNew, ...
                     a_ignoredParameterList, ignoredParamListAll, a_dirOutputNcFiles);

               else
                  if (cProfFileDmOld < cProfFileDmNew)
                     fprintf('ERROR: Float #%d Cycle #%d%c: C-PROF file in DM in "NEW DIRECTORY" only\n', ...
                        g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
                  end
                  errorProfInfo = [errorProfInfo; [g_cocd_floatNum, g_cocd_cycleNum, idDir]];
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.errorProf = [g_cocd_reportStruct.errorProf {[g_cocd_floatNum, g_cocd_cycleNum, idDir]}];
                  end
                  continue
               end
            else
               if ((isempty(profFileNameOld) && ~isempty(bProfFileNameOld)) && ...
                     (~isempty(profFileNameNew) && ~isempty(bProfFileNameNew)))
                  fprintf('ERROR: Float #%d Cycle #%d%c: No C-PROF file in "OLD DIRECTORY" (%s)\n', ...
                     g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, floatOldDirPathName);
                  errorProfInfo = [errorProfInfo; [g_cocd_floatNum, g_cocd_cycleNum, idDir]];
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.errorProf = [g_cocd_reportStruct.errorProf {[g_cocd_floatNum, g_cocd_cycleNum, idDir]}];
                  end
                  continue
               end
               if ((~isempty(profFileNameOld) && isempty(bProfFileNameOld)) && ...
                     (~isempty(profFileNameNew) && ~isempty(bProfFileNameNew)))
                  fprintf('ERROR: Float #%d Cycle #%d%c: No B-PROF file in "OLD DIRECTORY" (%s)\n', ...
                     g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, floatOldDirPathName);
                  errorProfInfo = [errorProfInfo; [g_cocd_floatNum, g_cocd_cycleNum, idDir]];
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.errorProf = [g_cocd_reportStruct.errorProf {[g_cocd_floatNum, g_cocd_cycleNum, idDir]}];
                  end
                  continue
               end
               if ((~isempty(profFileNameOld) && ~isempty(bProfFileNameOld)) && ...
                     (isempty(profFileNameNew) && ~isempty(bProfFileNameNew)))
                  fprintf('ERROR: Float #%d Cycle #%d%c: No C-PROF file in "NEW DIRECTORY" (%s)\n', ...
                     g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, floatNewDirPathName);
                  errorProfInfo = [errorProfInfo; [g_cocd_floatNum, g_cocd_cycleNum, idDir]];
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.errorProf = [g_cocd_reportStruct.errorProf {[g_cocd_floatNum, g_cocd_cycleNum, idDir]}];
                  end
                  continue
               end
               if ((~isempty(profFileNameOld) && ~isempty(bProfFileNameOld)) && ...
                     (~isempty(profFileNameNew) && isempty(bProfFileNameNew)))
                  fprintf('ERROR: Float #%d Cycle #%d%c: No B-PROF file in "NEW DIRECTORY" (%s)\n', ...
                     g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, floatNewDirPathName);
                  errorProfInfo = [errorProfInfo; [g_cocd_floatNum, g_cocd_cycleNum, idDir]];
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.errorProf = [g_cocd_reportStruct.errorProf {[g_cocd_floatNum, g_cocd_cycleNum, idDir]}];
                  end
                  continue
               end
            end
         end
      end
   end

   % check output data set VS input one
   finalize_data_set(floatNum, a_dirInputOldNcFiles, a_dirInputNewNcFiles, a_dirOutputNcFiles, errorProfInfo);

   errorProfInfoAll = [errorProfInfoAll; errorProfInfo];

   % store the information for the XML report
   if (g_cocd_realtimeFlag == 1)
      g_cocd_reportData = [g_cocd_reportData g_cocd_reportStruct];
   end
end

if (g_cocd_realtimeFlag == 0)
   fprintf('\nUPDATED FILES START\n');
   for idFile = 1:length(g_cocd_updatedFileNameList)
      fprintf('UPDATED FILE: %s\n', g_cocd_updatedFileNameList{idFile});
   end
   fprintf('UPDATED FILES END\n\n');

   fprintf('\nDELETED FILES START\n');
   for idFile = 1:length(g_cocd_deletedFileNameList)
      fprintf('DELETED FILE: %s\n', g_cocd_deletedFileNameList{idFile});
   end
   fprintf('DELETED FILES END\n\n');

   fprintf('\nERROR PROFILES START\n');
   for idErr = 1:size(errorProfInfoAll, 1)
      dirStr = '';
      if (errorProfInfoAll(idErr, 3) == 1)
         dirStr = 'D';
      end
      fprintf('ERROR PROFILE: Float %d Cycle #%d%c\n', errorProfInfoAll(idErr, 1), errorProfInfoAll(idErr, 2), dirStr);
   end
   fprintf('ERROR PROFILES END\n\n');
end

ellapsedTime = toc;
fprintf('done (Elapsed time is %.1f seconds)\n', ellapsedTime);

diary off;

return

% ------------------------------------------------------------------------------
% Process C and B PROF files of a given cycle.
%
% SYNTAX :
%  process_cycle( ...
%    a_profFileNameOld, a_cProfFileDmOld, ...
%    a_bProfFileNameOld, a_bProfFileDmOld, ...
%    a_profFileNameNew, a_cProfFileDmNew, ...
%    a_bProfFileNameNew, a_bProfFileDmNew, ...
%    a_ignoredParameterList, a_ignoredParameterListAll, a_dirOutputNcFiles)
%
% INPUT PARAMETERS :
%   a_profFileNameOld         : OLD C PROF file path name
%   a_cProfFileDmOld          : OLD C PROF file DM flag
%   a_bProfFileNameOld        : OLD B PROF file path name
%   a_bProfFileDmOld          : OLD B PROF file DM flag
%   a_profFileNameNew         : NEW C PROF file path name
%   a_cProfFileDmNew          : NEW C PROF file DM flag
%   a_bProfFileNameNew        : NEW B PROF file path name
%   a_bProfFileDmNew          : NEW B PROF file DM flag
%   a_ignoredParameterList    : 'B' parameters to ignore
%   a_ignoredParameterListAll : 'B' and associted 'I' parameters to ignore
%   a_dirOutputNcFiles        : name of output data set directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_cycle( ...
   a_profFileNameOld, a_cProfFileDmOld, ...
   a_bProfFileNameOld, a_bProfFileDmOld, ...
   a_profFileNameNew, a_cProfFileDmNew, ...
   a_bProfFileNameNew, a_bProfFileDmNew, ...
   a_ignoredParameterList, a_ignoredParameterListAll, a_dirOutputNcFiles)


% process C-PROF file
process_cycle_file( ...
   a_profFileNameOld, a_cProfFileDmOld, ...
   a_profFileNameNew, a_cProfFileDmNew, ...
   a_ignoredParameterList, a_ignoredParameterListAll, a_dirOutputNcFiles, 0);

% process B-PROF file
if (~isempty(a_bProfFileNameOld) && ~isempty(a_bProfFileNameNew))
   process_cycle_file( ...
      a_bProfFileNameOld, a_bProfFileDmOld, ...
      a_bProfFileNameNew, a_bProfFileDmNew, ...
      a_ignoredParameterList, a_ignoredParameterListAll, a_dirOutputNcFiles, 1);
end

return

% ------------------------------------------------------------------------------
% Process C or B PROF files of a given cycle.
%
% SYNTAX :
%  process_cycle_file( ...
%    a_profFileNameOld, a_profFileDmOld, ...
%    a_profFileNameNew, a_profFileDmNew, ...
%    a_ignoredParameterList, a_ignoredParameterListAll, ...
%    a_dirOutputNcFiles, a_bFileFlag)
%
% INPUT PARAMETERS :
%   a_profFileNameOld         : OLD PROF file path name
%   a_profFileDmOld           : OLD PROF file DM flag
%   a_profFileNameNew         : NEW PROF file path name
%   a_profFileDmNew           : NEW PROF file DM flag
%   a_ignoredParameterList    : 'B' parameters to ignore
%   a_ignoredParameterListAll : 'B' and associted 'I' parameters to ignore
%   a_dirOutputNcFiles        : name of output data set directory
%   a_bFileFlag               : B PROF file flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function process_cycle_file( ...
   a_profFileNameOld, a_profFileDmOld, ...
   a_profFileNameNew, a_profFileDmNew, ...
   a_ignoredParameterList, a_ignoredParameterListAll, ...
   a_dirOutputNcFiles, a_bFileFlag)

% current references
global g_cocd_floatNum;
global g_cocd_cycleNum;
global g_cocd_cycleDir;


if (a_bFileFlag)
   fileType = 'B';
else
   fileType = 'C';
end

% original list
% varListInfo = [ ...
%    {'PLATFORM_NUMBER'} ...
%    {'PROJECT_NAME'} ...
%    {'PI_NAME'} ...
%    {'STATION_PARAMETERS'} ...
%    {'CYCLE_NUMBER'} ...
%    {'DIRECTION'} ...
%    {'DATA_CENTRE'} ...
%    {'DC_REFERENCE'} ...
%    {'DATA_STATE_INDICATOR'} ...
%    {'DATA_MODE'} ...
%    {'PLATFORM_TYPE'} ...
%    {'FLOAT_SERIAL_NO'} ...
%    {'FIRMWARE_VERSION'} ...
%    {'WMO_INST_TYPE'} ...
%    {'JULD'} ...
%    {'JULD_QC'} ...
%    {'JULD_LOCATION'} ...
%    {'LATITUDE'} ...
%    {'LONGITUDE'} ...
%    {'POSITION_QC'} ...
%    {'POSITIONING_SYSTEM'} ...
%    {'VERTICAL_SAMPLING_SCHEME'} ...
%    {'CONFIG_MISSION_NUMBER'} ...
%    {'PARAMETER'} ...
%    {'SCIENTIFIC_CALIB_EQUATION'} ...
%    {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
%    {'SCIENTIFIC_CALIB_COMMENT'} ...
%    {'SCIENTIFIC_CALIB_DATE'} ...
%    {'HISTORY_INSTITUTION'} ...
%    {'HISTORY_STEP'} ...
%    {'HISTORY_SOFTWARE'} ...
%    {'HISTORY_SOFTWARE_RELEASE'} ...
%    {'HISTORY_REFERENCE'} ...
%    {'HISTORY_DATE'} ...
%    {'HISTORY_ACTION'} ...
%    {'HISTORY_PARAMETER'} ...
%    {'HISTORY_START_PRES'} ...
%    {'HISTORY_STOP_PRES'} ...
%    {'HISTORY_PREVIOUS_VALUE'} ...
%    {'HISTORY_QCTEST'} ...
%    ];

% variables removed from original list (the NEW file content will be used
% for all N_PROF) - to consider possible update of the Coriolis data base
%    {'PLATFORM_NUMBER'} ...
%    {'PROJECT_NAME'} ...
%    {'PI_NAME'} ...
%    {'CYCLE_NUMBER'} ...
%    {'DIRECTION'} ...
%    {'DATA_CENTRE'} ...
%    {'DC_REFERENCE'} ...
%    {'PLATFORM_TYPE'} ...
%    {'FLOAT_SERIAL_NO'} ...
%    {'FIRMWARE_VERSION'} ...
%    {'WMO_INST_TYPE'} ...
%    {'VERTICAL_SAMPLING_SCHEME'} ...
%    {'CONFIG_MISSION_NUMBER'} ...

% updated list
varListInfo = [ ...
   {'STATION_PARAMETERS'} ...
   {'DATA_STATE_INDICATOR'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   {'JULD_LOCATION'} ...
   {'LATITUDE'} ...
   {'LONGITUDE'} ...
   {'POSITION_QC'} ...
   {'POSITIONING_SYSTEM'} ...
   {'PARAMETER'} ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'SCIENTIFIC_CALIB_DATE'} ...
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

% retrieve information from PROF file
wantedVars = [ ...
   {'FORMAT_VERSION'} ...
   {'STATION_PARAMETERS'} ...
   {'DATA_MODE'} ...
   {'PARAMETER_DATA_MODE'} ...
   {'VERTICAL_SAMPLING_SCHEME'} ...
   {'HISTORY_SOFTWARE'} ...
   {'HISTORY_SOFTWARE_RELEASE'} ...
   {'HISTORY_REFERENCE'} ...
   {'HISTORY_DATE'} ...
   {'HISTORY_ACTION'} ...
   {'HISTORY_PARAMETER'} ...
   ];
profDataOld = get_data_from_nc_file(a_profFileNameOld, wantedVars);
profDataNew = get_data_from_nc_file(a_profFileNameNew, wantedVars);
globalAttOld = get_global_att_from_nc_file(a_profFileNameOld);
globalAttNew = get_global_att_from_nc_file(a_profFileNameNew);

formatVersionOld = deblank(get_data_from_name('FORMAT_VERSION', profDataOld)');
formatVersionNew = deblank(get_data_from_name('FORMAT_VERSION', profDataNew)');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% check if the file needs to be processed

% check the file format version
if (~strcmp(formatVersionOld, '3.1'))
   fprintf('ERROR: Float #%d Cycle #%d%c: %c file (%s) is in format version %s - not managed\n', ...
      g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
      fileType, a_profFileNameOld, formatVersionOld);
   return
end
if (~strcmp(formatVersionNew, '3.1'))
   fprintf('ERROR: Float #%d Cycle #%d%c: %c file (%s) is in format version %s - not managed\n', ...
      g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
      fileType, a_profFileNameNew, formatVersionNew);
   return
end

% check the DATA_MODE/PARAMETER_DATA_MODE
dataModeOld = get_data_from_name('DATA_MODE', profDataOld)';
parameterDataModeOld = get_data_from_name('PARAMETER_DATA_MODE', profDataOld)';
needUpdate = 0;
if (any(dataModeOld == 'D') || ~isempty(find(parameterDataModeOld == 'D', 1)))
   needUpdate = 1;
end

% check the SCOOP QC modifications
if (~needUpdate)
   histSoftware = get_data_from_name('HISTORY_SOFTWARE', profDataOld);
   histSoftware = permute(histSoftware, ndims(histSoftware):-1:1);
   histAction = get_data_from_name('HISTORY_ACTION', profDataOld);
   histAction = permute(histAction, ndims(histAction):-1:1);
   histParam = get_data_from_name('HISTORY_PARAMETER', profDataOld);
   histParam = permute(histParam, ndims(histParam):-1:1);
   for idProf = 1:length(dataModeOld)
      for idHisto = 1:size(histSoftware, 1)
         if (strcmp(squeeze(histSoftware(idHisto, idProf, :))', 'SCOO') && ...
               strcmp(strtrim(squeeze(histAction(idHisto, idProf, :))'), 'CF'))
            paramName = squeeze(histParam(idHisto, idProf, :))';
            paramName = regexprep(paramName, '_ADJUSTED', '');
            if (~ismember(paramName, a_ignoredParameterListAll))
               needUpdate = 1;
               break
            end
         end
      end
      if (needUpdate)
         break
      end
   end
end
if (~needUpdate)
   return
end

dataModeOld = get_data_from_name('DATA_MODE', profDataOld)';
dataModeNew = get_data_from_name('DATA_MODE', profDataNew)';
parameterDataModeOld = get_data_from_name('PARAMETER_DATA_MODE', profDataOld)';
parameterDataModeNew = get_data_from_name('PARAMETER_DATA_MODE', profDataNew)';
stationParametersOld = get_data_from_name('STATION_PARAMETERS', profDataOld);
stationParametersNew = get_data_from_name('STATION_PARAMETERS', profDataNew);
verticalSamplingSchemeOld = get_data_from_name('VERTICAL_SAMPLING_SCHEME', profDataOld)';
verticalSamplingSchemeNew = get_data_from_name('VERTICAL_SAMPLING_SCHEME', profDataNew)';

% modify the parameterDataModeOld and dataModeOld for ignored parameters
% should be set to parameterDataModeNew and then dataModeOld reprocessed
if (~isempty(a_ignoredParameterListAll))
   [~, nParam, nProf] = size(stationParametersOld);
   for idProf = 1:nProf
      for idParam = 1:nParam
         paramName = deblank(stationParametersOld(:, idParam, idProf)');
         if (~isempty(paramName))
            if (ismember(paramName, a_ignoredParameterListAll))
               if (parameterDataModeOld(idProf, idParam) ~= parameterDataModeNew(idProf, idParam))
                  parameterDataModeOld(idProf, idParam) = parameterDataModeNew(idProf, idParam);
                  if (any(parameterDataModeOld(idProf, :) == 'D'))
                     dataModeOld(idProf) = 'D';
                  elseif (~any(parameterDataModeOld(idProf, :) == 'D') && any(parameterDataModeOld(idProf, :) == 'A'))
                     dataModeOld(idProf) = 'A';
                  else
                     dataModeOld(idProf) = 'R';
                  end
               end
            end
         end
      end
   end   
end

profStructOld = [];
profStructNew = [];
parameterListOld = [];
parameterListNew = [];
for idLoop = 1:2
   wantedVars = varListInfo;
   if (idLoop == 1)
      stationParameters = stationParametersOld;
      profFileName = a_profFileNameOld;
      dataMode = dataModeOld;
      parameterDataMode = parameterDataModeOld;
      verticalSamplingScheme = verticalSamplingSchemeOld;
   else
      stationParameters = stationParametersNew;
      profFileName = a_profFileNameNew;
      dataMode = dataModeNew;
      parameterDataMode = parameterDataModeNew;
      verticalSamplingScheme = verticalSamplingSchemeNew;
   end

   % create the list of parameters to be retrieved from PROF file
   
   % add parameter measurements
   parameterList = [];
   [~, nParam, nProf] = size(stationParameters);
   for idProf = 1:nProf
      profParamList = [];
      for idParam = 1:nParam
         paramName = deblank(stationParameters(:, idParam, idProf)');
         if (~isempty(paramName))
            if (~ismember(paramName, a_ignoredParameterListAll))
               paramInfo = get_netcdf_param_attributes(paramName);
               profParamList{end+1} = paramName;
               wantedVars = [wantedVars ...
                  {paramName}];
               if ~((a_bFileFlag == 1) && (strcmp(paramName, 'PRES')))
                  wantedVars = [wantedVars ...
                     {[paramName '_QC']} ...
                     {['PROFILE_' paramName '_QC']} ...
                     ];
                  if (paramInfo.adjAllowed)
                     wantedVars = [wantedVars ...
                        {[paramName '_ADJUSTED']} ...
                        {[paramName '_ADJUSTED_QC']} ...
                        {[paramName '_ADJUSTED_ERROR']} ...
                        ];
                  end
               end
            end
         end
      end
      parameterList = [parameterList; {profParamList}];
   end
   
   % retrieve information from PROF file
   profData = get_data_from_nc_file(profFileName, wantedVars);
   
   profStruct = [];
   profStruct.bFileFlag = a_bFileFlag;
   profStruct.dataMode = dataMode;
   profStruct.parameterDataMode = parameterDataMode;
   profStruct.verticalSamplingScheme = verticalSamplingScheme;
   profStruct.parameterList = parameterList;
   profStruct.parameterListUnique = unique([parameterList{:}]);
   profStruct.data = [];
   profStruct.info = [];
   for id = 1:2:length(profData)
      data = get_data_from_name(profData{id}, profData);
      data = permute(data, ndims(data):-1:1);
      if (ismember(profData{id}, varListInfo))
         profStruct.info.(profData{id}) = data;
      else
         profStruct.data.(profData{id}) = data;
      end
   end
   
   if (idLoop == 1)
      profStructOld = profStruct;
      parameterListOld = parameterList;
   else
      profStructNew = profStruct;
      parameterListNew = parameterList;
   end
end

% check consistency between file name and DATA_MODE
if (isempty(a_ignoredParameterList))
   if ((a_profFileDmOld == 1) && (~any(dataModeOld == 'D')))
      fprintf('ERROR: Float #%d Cycle #%d%c: %c file name and DATA_MODE are not consistent in file (%s)\n', ...
         g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
         fileType, a_profFileNameOld);
      return
   end
else
   % if all DM data is ignored through a_ignoredParameterList file name and
   % DATA_MODE can be inconsistent
end
if ((a_profFileDmNew == 1) && (~any(dataModeNew == 'D')))
   fprintf('ERROR: Float #%d Cycle #%d%c: %c file name and DATA_MODE are not consistent in file (%s)\n', ...
      g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
      fileType, a_profFileNameNew);
   return
end

% check consistency between DATA_MODE and PARAMETER_DATA_MODE
for idProf = 1:size(parameterDataModeOld, 1)
   if ((((dataModeOld(idProf) == 'D') && ...
         ~any(parameterDataModeOld(idProf, :) == 'D'))) || ...
         ((dataModeOld(idProf) == 'A') && ...
         (any(parameterDataModeOld(idProf, :) == 'D') || ~any(parameterDataModeOld(idProf, :) == 'A'))) || ...
         ((dataModeOld(idProf) == 'R') && ...
         (any(parameterDataModeOld(idProf, :) == 'D') || any(parameterDataModeOld(idProf, :) == 'A'))))
      fprintf('ERROR: Float #%d Cycle #%d%c: DATA_MODE and PARAMETER_DATA_MODE are not consistent in %c file (%s)\n', ...
         g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
         fileType, a_profFileNameOld);
      return
   end
end
for idProf = 1:size(parameterDataModeNew, 1)
   if ((((dataModeNew(idProf) == 'D') && ...
         ~any(parameterDataModeNew(idProf, :) == 'D'))) || ...
         ((dataModeNew(idProf) == 'A') && ...
         (any(parameterDataModeNew(idProf, :) == 'D') || ~any(parameterDataModeNew(idProf, :) == 'A'))) || ...
         ((dataModeNew(idProf) == 'R') && ...
         (any(parameterDataModeNew(idProf, :) == 'D') || any(parameterDataModeNew(idProf, :) == 'A'))))
      fprintf('ERROR: Float #%d Cycle #%d%c: DATA_MODE and PARAMETER_DATA_MODE are not consistent in %c file (%s)\n', ...
         g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
         fileType, a_profFileNameNew);
      return
   end
end

% check consistency between N_PROF dimension
if (length(profStructOld.dataMode) ~= length(profStructNew.dataMode))
   
   % try to concatenate additional profile
   ok = 0;
   if (length(profStructOld.dataMode) == length(profStructNew.dataMode) + 1)
      vssList = cellstr(profStructOld.verticalSamplingScheme);
      idUnpumped = cellfun(@(x) strfind(x, 'Near-surface sampling') & strfind(x, 'unpumped'), vssList, 'UniformOutput', 0);
      idUnpumped = find(~cellfun(@isempty, idUnpumped) == 1);
      idSecondary = cellfun(@(x) strfind(x, 'Secondary sampling'), vssList, 'UniformOutput', 0);
      idSecondary = find(~cellfun(@isempty, idSecondary) == 1);
      if ((length(idUnpumped) == 2) && any(idSecondary == max(idUnpumped)-1))
         idUnpumped = max(idUnpumped);
         idSecondary = idUnpumped-1;
         
         idSecondaryNew = cellfun(@(x) strfind(x, 'Secondary sampling'), cellstr(profStructNew.verticalSamplingScheme), 'UniformOutput', 0);
         idSecondaryNew = min(find(~cellfun(@isempty, idSecondaryNew) == 1));
         newPresData = profStructNew.data.PRES(idSecondaryNew, :);
         nLevelNew = length(newPresData);
         
         paramPres = get_netcdf_param_attributes('PRES');
         concatPresAxis = ones(size(newPresData))*paramPres.fillValue;
         idUnpumpedLength = find(profStructOld.data.PRES(idUnpumped, :) ~= paramPres.fillValue, 1, 'last');
         idSecondaryLength = find(profStructOld.data.PRES(idSecondary, :) ~= paramPres.fillValue, 1, 'last');
         concatPresAxis(1:idUnpumpedLength) = profStructOld.data.PRES(idUnpumped, 1:idUnpumpedLength);
         concatPresAxis(idUnpumpedLength+1:idUnpumpedLength+idSecondaryLength) = profStructOld.data.PRES(idSecondary, 1:idSecondaryLength);
         
         if (~any(newPresData ~= concatPresAxis))
            
            % the concatenated profile matches the NEW one => update the
            % OLD data structure so that the comparison could be done
            paramListUnpumped = parameterListOld{idUnpumped};
            paramListSecondary = parameterListOld{idSecondary};
            if (isempty(setdiff(paramListUnpumped, paramListSecondary)) && ...
                  isempty(setdiff(paramListSecondary, paramListUnpumped)))
               
               % extend OLD data set if needed
               nLevelOld = size(profStructOld.data.PRES, 2);
               if (nLevelOld < nLevelNew)
                  
                  paramListAll = unique([parameterListOld{:}]);
                  for idParam = 1:length(paramListAll)
                     paramName = paramListAll{idParam};
                     paramInfo = get_netcdf_param_attributes(paramName);
                     
                     for idLoop = 1:2
                        if (idLoop == 1)
                           param = paramName;
                        else
                           if (paramInfo.adjAllowed && ...
                                 ((a_bFileFlag == 0) || ...
                                 ((a_bFileFlag == 1) && (~strcmp(paramName, 'PRES')))))
                              param = [paramName '_ADJUSTED'];
                           else
                              break
                           end
                        end
                        
                        profStructOld.data.(param) = cat(2, ...
                           profStructOld.data.(param), ...
                           ones(size(profStructOld.data.(param), 1), nLevelNew-nLevelOld)*paramInfo.fillValue);
                        
                        if ~((a_bFileFlag == 1) && (strcmp(paramName, 'PRES')))
                           
                           paramQc = [param '_QC'];
                           profStructOld.data.(paramQc) = cat(2, ...
                              profStructOld.data.(paramQc), ...
                              repmat(' ', size(profStructOld.data.(param), 1), nLevelNew-nLevelOld));
                           
                           if (idLoop == 2)
                              param = [paramName '_ADJUSTED_ERROR'];
                              
                              profStructOld.data.(param) = cat(2, ...
                                 profStructOld.data.(param), ...
                                 ones(size(profStructOld.data.(param), 1), nLevelNew-nLevelOld)*paramInfo.fillValue);
                           end
                        end
                     end
                  end
               end
               
               % update OLD data set
               paramList = parameterListOld{idUnpumped};
               for idParam = 1:length(paramList)
                  paramName = paramList{idParam};
                  paramInfo = get_netcdf_param_attributes(paramName);
                  
                  for idLoop = 1:2
                     if (idLoop == 1)
                        param = paramName;
                     else
                        if (profStructOld.dataMode(idSecondary) == 'A')
                           if (paramInfo.adjAllowed && ...
                                 ((a_bFileFlag == 0) || ...
                                 ((a_bFileFlag == 1) && (~strcmp(paramName, 'PRES')))))
                              param = [paramName '_ADJUSTED'];
                           else
                              break
                           end
                        else
                           break
                        end
                     end
                  
                     concatParamData = ones(1, nLevelNew)*paramInfo.fillValue;
                     idUnpumpedLength = find(profStructOld.data.(param)(idUnpumped, :) ~= paramInfo.fillValue, 1, 'last');
                     idSecondaryLength = find(profStructOld.data.(param)(idSecondary, :) ~= paramInfo.fillValue, 1, 'last');
                     concatParamData(1:idUnpumpedLength) = profStructOld.data.(param)(idUnpumped, 1:idUnpumpedLength);
                     concatParamData(idUnpumpedLength+1:idUnpumpedLength+idSecondaryLength) = profStructOld.data.(param)(idSecondary, 1:idSecondaryLength);
                     profStructOld.data.(param)(idSecondary, :) = concatParamData;
                     
                     if ~((a_bFileFlag == 1) && (strcmp(paramName, 'PRES')))
                        
                        paramQc = [param '_QC'];
                        concatParamQcData = repmat(' ', 1, nLevelNew);
                        concatParamQcData(1:idUnpumpedLength) = profStructOld.data.(paramQc)(idUnpumped, 1:idUnpumpedLength);
                        concatParamQcData(idUnpumpedLength+1:idUnpumpedLength+idSecondaryLength) = profStructOld.data.(paramQc)(idSecondary, 1:idSecondaryLength);
                        profStructOld.data.(paramQc)(idSecondary, :) = concatParamQcData;
                        
                        profParamQc = ['PROFILE_' paramName '_QC'];
                        profStructOld.data.(profParamQc)(idSecondary) = compute_profile_quality_flag(concatParamQcData);
                        
                        if (idLoop == 2)
                           param = [paramName '_ADJUSTED_ERROR'];
                           
                           concatParamData = ones(1, nLevelNew)*paramInfo.fillValue;
                           idUnpumpedLength = find(profStructOld.data.(param)(idUnpumped, :) ~= paramInfo.fillValue, 1, 'last');
                           idSecondaryLength = find(profStructOld.data.(param)(idSecondary, :) ~= paramInfo.fillValue, 1, 'last');
                           concatParamData(1:idUnpumpedLength) = profStructOld.data.(param)(idUnpumped, 1:idUnpumpedLength);
                           concatParamData(idUnpumpedLength+1:idUnpumpedLength+idSecondaryLength) = profStructOld.data.(param)(idSecondary, 1:idSecondaryLength);
                           profStructOld.data.(param)(idSecondary, :) = concatParamData;
                        end
                     end
                  end
               end
               
               % remove idUnpumped profile
               paramListAll = unique([parameterListOld{:}]);
               for idParam = 1:length(paramListAll)
                  paramName = paramListAll{idParam};
                  
                  for idLoop = 1:2
                     if (idLoop == 1)
                        param = paramName;
                     else
                        if (paramInfo.adjAllowed && ...
                              ((a_bFileFlag == 0) || ...
                              ((a_bFileFlag == 1) && (~strcmp(paramName, 'PRES')))))
                           param = [paramName '_ADJUSTED'];
                        else
                           break
                        end
                     end
                     profStructOld.data.(param)(idUnpumped, :) = [];
                     
                     if ~((a_bFileFlag == 1) && (strcmp(paramName, 'PRES')))
                        
                        paramQc = [param '_QC'];
                        profStructOld.data.(paramQc)(idUnpumped, :) = [];
                        
                        if (idLoop == 1)
                           profParamQc = ['PROFILE_' paramName '_QC'];
                           profStructOld.data.(profParamQc)(idUnpumped) = [];
                        else
                           param = [paramName '_ADJUSTED_ERROR'];
                           profStructOld.data.(param)(idUnpumped, :) = [];
                        end
                     end
                  end
               end
               profStructOld.dataMode(idUnpumped) =  [];
               %                fprintf('INFO: Float #%d Cycle #%d%c: profile concatenated before check\n', ...
               %                   g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
               ok = 1;
            end
         end
      end
   end
   
   if (~ok)
      fprintf('ERROR: Float #%d Cycle #%d%c: N_PROF=%d in OLD %c file whereas N_PROF=%d in NEW %c file\n', ...
         g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
         length(profStructOld.dataMode), fileType, length(profStructNew.dataMode), fileType);
      return
   end
end

% check data and store information if the file should be updated
dmProfIdToUpdate = find(profStructOld.dataMode == 'D');
% DEBUG START
% if (profStructOld.bFileFlag)
%    dmProfIdToUpdate = 1;
% end
% DEBUG STOP
rtProfIdToUpdate = [];
nHistoryData = [];

% for 'R' or 'A' profiles, retrieve SCOO information from HISTORY data
for idProf = 1:length(profStructOld.dataMode)
   if (~ismember(idProf, dmProfIdToUpdate))
      for idHisto = 1:size(profStructOld.info.HISTORY_SOFTWARE, 1)
         if (strcmp(squeeze(profStructOld.info.HISTORY_SOFTWARE(idHisto, idProf, :))', 'SCOO') && ...
               strcmp(strtrim(squeeze(profStructOld.info.HISTORY_ACTION(idHisto, idProf, :))'), 'CF'))
            newHisto = [];
            newHisto.profileId = idProf;
            newHisto.HISTORY_INSTITUTION = squeeze(profStructOld.info.HISTORY_INSTITUTION(idHisto, idProf, :))';
            newHisto.HISTORY_STEP = squeeze(profStructOld.info.HISTORY_STEP(idHisto, idProf, :))';
            newHisto.HISTORY_SOFTWARE = squeeze(profStructOld.info.HISTORY_SOFTWARE(idHisto, idProf, :))';
            newHisto.HISTORY_SOFTWARE_RELEASE = squeeze(profStructOld.info.HISTORY_SOFTWARE_RELEASE(idHisto, idProf, :))';
            newHisto.HISTORY_REFERENCE = squeeze(profStructOld.info.HISTORY_REFERENCE(idHisto, idProf, :))';
            newHisto.HISTORY_DATE = squeeze(profStructOld.info.HISTORY_DATE(idHisto, idProf, :))';
            newHisto.HISTORY_ACTION = squeeze(profStructOld.info.HISTORY_ACTION(idHisto, idProf, :))';
            newHisto.HISTORY_PARAMETER = squeeze(profStructOld.info.HISTORY_PARAMETER(idHisto, idProf, :))';
            newHisto.HISTORY_START_PRES = profStructOld.info.HISTORY_START_PRES(idHisto, idProf);
            newHisto.HISTORY_STOP_PRES = profStructOld.info.HISTORY_STOP_PRES(idHisto, idProf);
            newHisto.HISTORY_PREVIOUS_VALUE = profStructOld.info.HISTORY_PREVIOUS_VALUE(idHisto, idProf);
            newHisto.HISTORY_QCTEST = squeeze(profStructOld.info.HISTORY_QCTEST(idHisto, idProf, :))';
            
            nHistoryData = [nHistoryData newHisto];
            rtProfIdToUpdate = [rtProfIdToUpdate idProf];
         end
      end
   end
end

% for each N_PROF that needs update:
% - check consistency of the data (identical PRES axis and identical parameter list)
% - update QC in the NEW structure data
updatedData = [];
profIdToUpdate = unique(rtProfIdToUpdate);
for idProf = 1:length(profIdToUpdate)
   profId = profIdToUpdate(idProf);
   
   % check that PRES axis are identical
   oldPresData = profStructOld.data.PRES(profId, :);
   newPresData = profStructNew.data.PRES(profId, :);
   if ((length(oldPresData) ~= length(newPresData)) || any(oldPresData ~= newPresData))
      fprintf('ERROR: Float #%d Cycle #%d%c: PRES values differ in N_PROF=%d of %c file\n', ...
         g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
         profId, fileType);
      idDel = find(rtProfIdToUpdate == profId);
      rtProfIdToUpdate(idDel) = [];
      nHistoryData(idDel) = [];
      continue
   end
   
   % check that parameter lists are identical
   paramListOld = parameterListOld{profId};
   paramListNew = parameterListNew{profId};
   if (~isempty(setdiff(paramListOld, paramListNew)) || ~isempty(setdiff(paramListNew, paramListOld)))
      fprintf('ERROR: Float #%d Cycle #%d%c: parameter lists differ in N_PROF=%d of %c file\n', ...
         g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
         profId, fileType);
      idDel = find(rtProfIdToUpdate == profId);
      rtProfIdToUpdate(idDel) = [];
      nHistoryData(idDel) = [];
      continue
   end
   
   % update the NEW structure data
   historyIdList = find(rtProfIdToUpdate == profId);
   for idH = 1:length(historyIdList)
      parameter = strtrim(nHistoryData(historyIdList(idH)).HISTORY_PARAMETER);
      startPres = nHistoryData(historyIdList(idH)).HISTORY_START_PRES;
      stopPres = nHistoryData(historyIdList(idH)).HISTORY_STOP_PRES;
      prevVal = nHistoryData(historyIdList(idH)).HISTORY_PREVIOUS_VALUE;
      softwareRelease = nHistoryData(historyIdList(idH)).HISTORY_SOFTWARE_RELEASE;
      
      % check that PARAM exists
      if (~isfield(profStructOld.data, parameter) || ~isfield(profStructNew.data, parameter))
         if (~isfield(profStructOld.data, parameter))
            fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' parameter is not in N_PROF=%d of OLD %c file data\n', ...
               g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
               parameter, profId, fileType);
         end
         if (~isfield(profStructNew.data, parameter))
            fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' parameter is not in N_PROF=%d of NEW %c file data\n', ...
               g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
               parameter, profId, fileType);
         end
         continue
      end
      
      % check that PARAM values are identical
      oldParamData = profStructOld.data.(parameter)(profId, :);
      newParamData = profStructNew.data.(parameter)(profId, :);
      if ((length(oldParamData) ~= length(newParamData)) || any(oldParamData ~= newParamData))
         fprintf('ERROR: Float #%d Cycle #%d%c: ''%s'' values differ in N_PROF=%d of %c file\n', ...
            g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
            parameter, profId, fileType);
         continue
      end
      
      % check consistency of HISTORY information
      oldParamQcData = profStructOld.data.([parameter '_QC'])(profId, :);
      newParamQcData = profStructNew.data.([parameter '_QC'])(profId, :);
      idDiff = find(oldParamQcData ~= newParamQcData);
      if (ismember(parameter, [{'PRES'} {'PRES_ADJUSTED'}]))
         
         % SCOOP2 1.x  PRES => value
         % SCOOP3 0.15 PRES => value
         % SCOOP3 0.19 PRES => imm_level
         % SCOOP3 0.33 PRES => imm_level
         % SCOOP3 0.34 PRES => imm_level
         % SCOOP3 0.36 PRES => value
         % SCOOP3 0.38 PRES => value
         
         if (ismember(strtrim(softwareRelease), [{'0.19'} {'0.33'} {'0.34'}]))
            idFStart = startPres;
            idFStop = stopPres;
            if ~(ismember(idFStart, idDiff) && ismember(idFStop, idDiff))
               idFStart = find(oldPresData == startPres);
               idFStop = find(oldPresData == stopPres);
            end
         else
            idFStart = find(oldPresData == startPres);
            idFStop = find(oldPresData == stopPres);
            if ((isempty(idFStart) || isempty(idFStop)) || ...
                  ~(ismember(idFStart, idDiff) && ismember(idFStop, idDiff)))
               idFStart = startPres;
               idFStop = stopPres;
            end
         end
         if ((isempty(idFStart) || isempty(idFStop)) || ...
               ~(ismember(idFStart, idDiff) && ismember(idFStop, idDiff)))
            idFStart = [];
            idFStop = [];
         end
      else
         idFStart = find(oldPresData == startPres);
         idFStop = find(oldPresData == stopPres);
      end
      if (isempty(idFStart) || isempty(idFStop))
         if (isempty(idFStart))
            fprintf('ERROR: Float #%d Cycle #%d%c: update of %s_QC: cannot find START_PRES=%g dbar in N_PROF=%d of %c file OLD data (scoop V%s)\n', ...
               g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
               parameter, startPres, profId, fileType, softwareRelease);
         end
         if (isempty(idFStop))
            fprintf('ERROR: Float #%d Cycle #%d%c: update of %s_QC: cannot find STOP_PRES=%g dbar in N_PROF=%d of %c file OLD data (scoop V%s)\n', ...
               g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
               parameter, stopPres, profId, fileType, softwareRelease);
         end
         continue
      end
      
      % update QC in the NEW structure data
      profStructNew.data.([parameter '_QC'])(profId, idFStart:idFStop) = ...
         profStructOld.data.([parameter '_QC'])(profId, idFStart:idFStop);
      if (isempty(updatedData) || ...
            ~any(([updatedData{:, 1}] == profId) & strcmp({updatedData{:, 2}}, parameter)))
         updatedData = [updatedData; ...
            profId {parameter}];
      end
   end
end

% update PROFILE_PARAM_QC
if (~isempty(updatedData))
   prodIdList = unique([updatedData{:, 1}]);
   for idProf = 1:length(prodIdList)
      profId = prodIdList(idProf);
      paramList = updatedData(find([updatedData{:, 1}] == profId), 2);
      uParamList = unique(regexprep(paramList, '_ADJUSTED', ''));
      for idParam = 1:length(uParamList)
         paramName = uParamList{idParam};
         param = paramName;
         if (ismember([param '_ADJUSTED'], paramList))
            param = [param '_ADJUSTED'];
         end
         profParamQc = ['PROFILE_' paramName '_QC'];
         profStructNew.data.(profParamQc)(profId) = ...
            compute_profile_quality_flag(profStructNew.data.([param '_QC'])(profId, :));
      end
   end
end

needUpdate = 0;
if (~isempty(dmProfIdToUpdate))
   profList = sprintf('#%d ', dmProfIdToUpdate);
   fprintf('INFO: Float #%d Cycle #%d%c: %c file: profiles (%s) are in DM - need to be duplicated in NEW file\n', ...
      g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
      fileType, profList(1:end-1));
   needUpdate = 1;
end
profIdToUpdate = unique(rtProfIdToUpdate);
if (~isempty(profIdToUpdate))
   profList = sprintf('#%d ', profIdToUpdate);
   fprintf('INFO: Float #%d Cycle #%d%c: %c file: profiles (%s) have modified QC - need to be updated in NEW file\n', ...
      g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
      fileType, profList(1:end-1));
   needUpdate = 1;
end

if (needUpdate)
   
   % create the list of new global attributes to copy in output file
   newGlobalAtt = [];
   for idG = 1:size(globalAttOld, 1)
      if (~ismember(globalAttOld(idG, 1), globalAttNew(:, 1)))
         if (any(strfind(globalAttOld{idG, 1}, 'comment_dmqc_operator')))
            attValue = globalAttOld{idG, 2};
            idF = strfind(attValue, '|');
            if (~isempty(idF))
               paramName = strtrim(attValue(1:idF(1)-1));
               if (ismember(paramName, a_ignoredParameterList))
                  globalAttOld{idG, 2} = [paramName ' | | '];
               end
            end
         end
         newGlobalAtt = [newGlobalAtt; globalAttOld(idG, :)];
      end
   end
   
   % update the PROF file
   update_prof_file( ...
      a_profFileNameOld, a_profFileNameNew, ...
      profStructOld, profStructNew, dmProfIdToUpdate, ...
      rtProfIdToUpdate, updatedData, nHistoryData, newGlobalAtt, ...
      a_dirOutputNcFiles);
end

return

% ------------------------------------------------------------------------------
% Update PROF file.
%
% SYNTAX :
%  update_prof_file( ...
%    a_profFileNameOld, a_profFileNameNew, ...
%    a_profStructOld, a_profStructNew, a_dmProfIdToUpdate, ...
%    a_rtProfIdToUpdate, a_updatedData, a_nHistoryData, a_newGlobalAtt, ...
%    a_dirOutputNcFiles)
%
% INPUT PARAMETERS :
%   a_profFileNameOld  : OLD PROF file path name
%   a_profFileNameNew  : NEW PROF file path name
%   a_profStructOld    : OLD PROF data
%   a_profStructNew    : NEW PROF data
%   a_dmProfIdToUpdate : list of DM profiles
%   a_rtProfIdToUpdate : list of RT profiles with updated SCOOP QCs
%   a_updatedData      : list of RT updated profiles and associated variables
%   a_nHistoryData     : HISTORY data of each updated profile
%   a_newGlobalAtt     : additional global attributes for the NEW PROF
%   a_dirOutputNcFiles : name of output data set directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function update_prof_file( ...
   a_profFileNameOld, a_profFileNameNew, ...
   a_profStructOld, a_profStructNew, a_dmProfIdToUpdate, ...
   a_rtProfIdToUpdate, a_updatedData, a_nHistoryData, a_newGlobalAtt, ...
   a_dirOutputNcFiles)

% current references
global g_cocd_floatNum;
global g_cocd_cycleNum;
global g_cocd_cycleDir;

% list of updated files
global g_cocd_updatedFileNameList;

% RT processing flag
global g_cocd_realtimeFlag;

% report information structure
global g_cocd_reportStruct;


% create output file directory
outputDirName = [a_dirOutputNcFiles '/' num2str(g_cocd_floatNum) '/profiles/'];
if ~(exist(outputDirName, 'dir') == 7)
   mkdir(outputDirName);
end

% create output file path name
[~, fileName, fileExtension] = fileparts(a_profFileNameOld);
outputProfFileName = [outputDirName fileName fileExtension];

% duplicate NEW file
copy_file(a_profFileNameNew, outputProfFileName);

% check if N_CALIB dimension should be updated
if (~isempty(a_dmProfIdToUpdate))
   
   if (ndims(a_profStructOld.info.PARAMETER) == 4)
      nCalibOld = size(a_profStructOld.info.PARAMETER, 2);
   elseif (ndims(a_profStructOld.info.PARAMETER) == 3)
      nCalibOld = size(a_profStructOld.info.PARAMETER, 1);
   else
      nCalibOld = 1;
   end
   if (ndims(a_profStructNew.info.PARAMETER) == 4)
      nCalibNew = size(a_profStructNew.info.PARAMETER, 2);
   elseif (ndims(a_profStructNew.info.PARAMETER) == 3)
      nCalibNew = size(a_profStructNew.info.PARAMETER, 1);
   else
      nCalibNew = 1;
   end
   
   if (nCalibOld ~= nCalibNew)
      if (nCalibNew > nCalibOld)
         fprintf('ERROR: Float #%d Cycle #%d%c: N_CALIB=%d in OLD file and N_CALIB=%d in NEW\n', ...
            g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir, ...
            nCalibOld, nCalibNew);
         return
      end
      
      % update N_CALIB dimension in new file
      ok = update_n_calib_dim_in_prof_file(outputProfFileName, nCalibOld);
      if (~ok)
         fprintf('ERROR: Float #%d Cycle #%d%c: an error occured during update of N_CALIB dimension in NEW file\n', ...
            g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
         return
      end
   end
end

% directory to store temporary files
[filePath, fileName, fileExtension] = fileparts(outputProfFileName);
DIR_TMP_FILE = [filePath '/tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the file in the temp directory
tmpProfFileName = [DIR_TMP_FILE '/' fileName fileExtension];
copy_file(outputProfFileName, tmpProfFileName);

% update PROF file
ok = update_prof_file_(tmpProfFileName, ...
   a_profStructOld, a_profStructNew, a_dmProfIdToUpdate, ...
   a_rtProfIdToUpdate, a_updatedData, a_nHistoryData, a_newGlobalAtt);
if (~ok)
   fprintf('ERROR: Float #%d Cycle #%d%c: an error occured during update of NEW file\n', ...
      g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
   return
end

% update input file
move_file(tmpProfFileName, outputProfFileName);

% store updated file name list
g_cocd_updatedFileNameList{end+1} = outputProfFileName;
if (g_cocd_realtimeFlag == 1)
   g_cocd_reportStruct.updatedFile = [g_cocd_reportStruct.updatedFile {outputProfFileName}];
end

% delete the temp directory
remove_directory(DIR_TMP_FILE);

return

% ------------------------------------------------------------------------------
% Update PROF file.
%
% SYNTAX :
%  [o_ok] = update_prof_file_(a_profFileName, ...
%    a_profStructOld, a_profStructNew, a_dmProfIdToUpdate, ...
%    a_rtProfIdToUpdate, a_updatedData, a_nHistoryData, a_newGlobalAtt)
%
% INPUT PARAMETERS :
%   a_profFileName     : output PROF file path name
%   a_profStructOld    : OLD PROF data
%   a_profStructNew    : NEW PROF data
%   a_dmProfIdToUpdate : list of DM profiles
%   a_rtProfIdToUpdate : list of RT profiles with updated SCOOP QCs
%   a_updatedData      : list of RT updated profiles and associated variables
%   a_nHistoryData     : HISTORY data of each updated profile
%   a_newGlobalAtt     : additional global attributes for the NEW PROF
%
% OUTPUT PARAMETERS :
%   o_ok : update operation report flag (1 if ok, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_prof_file_(a_profFileName, ...
   a_profStructOld, a_profStructNew, a_dmProfIdToUpdate, ...
   a_rtProfIdToUpdate, a_updatedData, a_nHistoryData, a_newGlobalAtt)

% output parameters initialization
o_ok = 0;

% current references
global g_cocd_floatNum;
global g_cocd_cycleNum;
global g_cocd_cycleDir;

% program version
global g_cocd_ncCopyMonoProfileDmAndQcVersion;

% information to set in 'HISTORY_REFERENCE (N_HISTORY, STRING64);' for the current action
global g_cocd_historyReferenceToReport;

% flag to keep DM profile location
global g_cocd_reportProfLocFlag;
global g_cocd_reportProfLocAllFlag;


% original list
% varList1 = [ ...
%    {'PLATFORM_NUMBER'} ...
%    {'PROJECT_NAME'} ...
%    {'PI_NAME'} ...
%    {'CYCLE_NUMBER'} ...
%    {'DIRECTION'} ...
%    {'DATA_CENTRE'} ...
%    {'DC_REFERENCE'} ...
%    {'DATA_STATE_INDICATOR'} ...
%    {'DATA_MODE'} ...
%    {'PLATFORM_TYPE'} ...
%    {'FLOAT_SERIAL_NO'} ...
%    {'FIRMWARE_VERSION'} ...
%    {'WMO_INST_TYPE'} ...
%    {'JULD'} ...
%    {'JULD_QC'} ...
%    {'JULD_LOCATION'} ...
%    {'LATITUDE'} ...
%    {'LONGITUDE'} ...
%    {'POSITION_QC'} ...
%    {'POSITIONING_SYSTEM'} ...
%    {'VERTICAL_SAMPLING_SCHEME'} ...
%    {'CONFIG_MISSION_NUMBER'} ...
%    ];

% variables removed from original list (the NEW file content will be used
% for all N_PROF) - to consider possible update of the Coriolis data base
%    {'PLATFORM_NUMBER'} ...
%    {'PROJECT_NAME'} ...
%    {'PI_NAME'} ...
%    {'CYCLE_NUMBER'} ...
%    {'DIRECTION'} ...
%    {'DATA_CENTRE'} ...
%    {'DC_REFERENCE'} ...
%    {'PLATFORM_TYPE'} ...
%    {'FLOAT_SERIAL_NO'} ...
%    {'FIRMWARE_VERSION'} ...
%    {'WMO_INST_TYPE'} ...
%    {'VERTICAL_SAMPLING_SCHEME'} ...
%    {'CONFIG_MISSION_NUMBER'} ...

% updated list
varList1 = [ ...
   {'DATA_STATE_INDICATOR'} ...
   {'DATA_MODE'} ...
   {'JULD'} ...
   {'JULD_QC'} ...
   ];
varList1Pos = [];
if (g_cocd_reportProfLocFlag == 1)
   varList1Pos = [ ...
      {'JULD_LOCATION'} ...
      {'LATITUDE'} ...
      {'LONGITUDE'} ...
      {'POSITION_QC'} ...
      {'POSITIONING_SYSTEM'} ...
      ];
end

varList1_1 = [ ...
   {'DATA_MODE'} ...
   {'JULD_QC'} ...
   {'POSITION_QC'} ...
   ];

varList2 = [ ...
   {'PARAMETER'} ...
   {'SCIENTIFIC_CALIB_EQUATION'} ...
   {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
   {'SCIENTIFIC_CALIB_COMMENT'} ...
   {'SCIENTIFIC_CALIB_DATE'} ...
   ];

varList3 = [ ...
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

varList3_1 = [ ...
   {'HISTORY_START_PRES'} ...
   {'HISTORY_STOP_PRES'} ...
   {'HISTORY_PREVIOUS_VALUE'} ...
   ];

dateUpdate = datestr(now_utc, 'yyyymmddHHMMSS');

% open NetCDF file
fCdf = netcdf.open(a_profFileName, 'WRITE');
if (isempty(fCdf))
   fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_profFileName);
   return
end

% copy variables with N_PROF dimension for DM profiles
if (~isempty(a_dmProfIdToUpdate))
   
   for idProf = 1:length(a_dmProfIdToUpdate)
      profId = a_dmProfIdToUpdate(idProf);
      paramListOld = a_profStructOld.parameterList{profId};
      paramListNew = a_profStructNew.parameterList{profId};
   
      % copy variables
      for idVar = 1:length(varList1)
         varName = varList1{idVar};
         value = a_profStructOld.info.(varName);
         if (ischar(value))
            if (ismember(varName, varList1_1))
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                  profId-1, 1, value(profId));
            else
               value = value(profId, :)';
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                  fliplr([profId-1  0]), fliplr([1 length(value)]), value');
            end
         else
            value = value(profId);
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
               profId-1, 1, value);
         end
      end

      % copy positions information
      if (~isempty(varList1Pos))
         for idVar = 1:length(varList1Pos)
            varName = varList1Pos{idVar};
            value = a_profStructOld.info.(varName);
            if (ischar(value))
               if (ismember(varName, varList1_1))
                  if (g_cocd_reportProfLocAllFlag)
                     value = repmat(value(a_dmProfIdToUpdate(1)), size(value));
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), value);
                  else
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                        profId-1, 1, value(profId));
                  end
               else
                  if (g_cocd_reportProfLocAllFlag)
                     value = repmat(value(a_dmProfIdToUpdate(1), :)', 1, size(value, 1));
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), value);
                  else
                     value = value(profId, :)';
                     netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                        fliplr([profId-1  0]), fliplr([1 length(value)]), value');
                  end
               end
            else
               if (g_cocd_reportProfLocAllFlag)
                  value = repmat(value(a_dmProfIdToUpdate(1)), size(value));
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), value);
               else
                  value = value(profId);
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                     profId-1, 1, value);
               end
            end
         end
      end
      
      if (a_profStructNew.bFileFlag)
         parameterDataModeOld = a_profStructOld.parameterDataMode(profId, :);
         dmIdList = find(parameterDataModeOld == 'D');
         for idParam = dmIdList
            idParamNew = find(strcmp(paramListOld{idParam}, paramListNew));
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'PARAMETER_DATA_MODE'), ...
               fliplr([profId-1  idParamNew-1]), fliplr([1 1]), parameterDataModeOld(idParam));
         end
      end
      
      %       stationParameters = a_profStructOld.info.STATION_PARAMETERS;
      %       if (ndims(stationParameters) == 3)
      %          nProf = size(stationParameters, 1);
      %          nParam = size(stationParameters, 2);
      %       elseif (ndims(stationParameters) == 2)
      %          nProf = 1;
      %          nParam = size(stationParameters, 1);
      %       end
      %       stationParametersVarId = netcdf.inqVarID(fCdf, 'STATION_PARAMETERS');
      %       for idParam = 1:nParam
      %          if (nProf == 1)
      %             valueStr = stationParameters(idParam, :);
      %          else
      %             valueStr = squeeze(stationParameters(profId, idParam, :))';
      %          end
      %          netcdf.putVar(fCdf, stationParametersVarId, ...
      %             fliplr([profId-1 idParam-1 0]), fliplr([1 1 length(valueStr)]), valueStr');
      %       end

      % for varList2 parameters, only N_PARAM with PARAMETER_DATA_MODE = 'D' are
      % copied
      parameter = a_profStructOld.info.PARAMETER;
      if (ndims(parameter) == 4)
         nProf = size(parameter, 1);
         nCalib = size(parameter, 2);
         nParam = size(parameter, 3);
      elseif (ndims(parameter) == 3)
         nProf = 1;
         nCalib = size(parameter, 1);
         nParam = size(parameter, 2);
      elseif (ndims(parameter) == 2)
         nProf = 1;
         nCalib = 1;
         nParam = size(parameter, 1);
      end

      if (a_profStructOld.bFileFlag)
         parameterDataModeOld = a_profStructOld.parameterDataMode(profId, :);
         parameterListOld = a_profStructOld.parameterList{profId};
      end

      dmList = [];
      for idCalib = 1:nCalib
         for idParam = 1:nParam
            if (a_profStructOld.bFileFlag)
               if (ndims(parameter) == 4)
                  paramName = strtrim(squeeze(parameter(profId, idCalib, idParam, :))');
               elseif (ndims(parameter) == 3)
                  paramName = strtrim(squeeze(parameter(idCalib, idParam, :))');
               elseif (ndims(parameter) == 2)
                  paramName = strtrim(squeeze(parameter(idParam, :)));
               end
               paramNameId  = find(strcmp(parameterListOld, paramName), 1);
               if (parameterDataModeOld(paramNameId) == 'D')
                  dmList = [dmList; [idCalib idParam]];
               end
            else
               dmList = [dmList; [idCalib idParam]];
            end
         end
      end

      for idVar = 1:length(varList2)
         varName = varList2{idVar};
         value = a_profStructOld.info.(varName);
         if (ndims(value) == 4)
            nProf = size(value, 1);
            nCalib = size(value, 2);
            nParam = size(value, 3);
         elseif (ndims(value) == 3)
            nProf = 1;
            nCalib = size(value, 1);
            nParam = size(value, 2);
         elseif (ndims(value) == 2)
            nProf = 1;
            nCalib = 1;
            nParam = size(value, 1);
         end

         for idCalib = 1:nCalib
            for idParam = 1:nParam
               if (any((dmList(:, 1) == idCalib) & (dmList(:, 2) == idParam)))
                  if (nProf == 1)
                     if (nCalib == 1)
                        valueStr = value(idParam, :);
                     else
                        valueStr = squeeze(value(idCalib, idParam, :))';
                     end
                  else
                     valueStr = squeeze(value(profId, idCalib, idParam, :))';
                  end
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                     fliplr([profId-1 idCalib-1 idParam-1 0]), fliplr([1 1 1 length(valueStr)]), valueStr');
               end
            end
         end
      end
      
      for idVar = 1:length(varList3)
         varName = varList3{idVar};
         value = a_profStructOld.info.(varName);
         
         if (ismember(varName, varList3_1))
            if (ndims(value) == 2)
               nHisto = size(value, 1);
               nProf = size(value, 2);
            elseif (ndims(value) == 1)
               nHisto = 1;
               nProf = size(value, 1);
            end
            
            for idHisto = 1:nHisto
               if (nHisto == 1)
                  valueFloat = value(profId, :);
               else
                  valueFloat = value(idHisto, profId);
               end
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                  fliplr([idHisto-1 profId-1]), fliplr([1 1]), valueFloat);
            end
         else
            if (ndims(value) == 3)
               nHisto = size(value, 1);
               nProf = size(value, 2);
            elseif (ndims(value) == 2)
               nHisto = 1;
               nProf = size(value, 1);
            end
            
            for idHisto = 1:nHisto
               if (nHisto == 1)
                  valueStr = value(profId, :);
               else
                  valueStr = squeeze(value(idHisto, profId, :))';
               end
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                  fliplr([idHisto-1 profId-1 0]), fliplr([1 1 length(valueStr)]), valueStr');
            end
         end
      end
      
      % copy parameters
      paramList = a_profStructOld.parameterList{profId};
      if (a_profStructOld.bFileFlag)
         parameterDataModeOld = a_profStructOld.parameterDataMode(profId, :);
      end
      for idParam = 1:length(paramList)

         if (a_profStructOld.bFileFlag)
            if (parameterDataModeOld(idParam) ~= 'D')
               continue
            end
         end

         paramName = paramList{idParam};
         paramInfo = get_netcdf_param_attributes(paramName);

         for idLoop = 1:2
            if (idLoop == 1)
               param = paramName;
            else
               if (paramInfo.adjAllowed && ...
                     ((a_profStructOld.bFileFlag == 0) || ...
                     ((a_profStructOld.bFileFlag == 1) && (~strcmp(paramName, 'PRES')))))
                  param = [paramName '_ADJUSTED'];
               else
                  break
               end
            end
            
            if (ndims(a_profStructOld.data.(param)) == 2)
               value = a_profStructOld.data.(param)(profId, :);
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, param), ...
                  fliplr([profId-1 0]), fliplr([1 length(value)]), value);
            else
               % for UV_INTENSITY_NITRATE
               value = a_profStructOld.data.(param)(profId, :, :);
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, param), ...
                  fliplr([profId-1 0 0]), fliplr(size(value)), permute(value, fliplr(1:ndims(value))));
            end
            
            if ~((a_profStructOld.bFileFlag == 1) && (strcmp(paramName, 'PRES')))
               
               param = [param '_QC'];
               value = a_profStructOld.data.(param)(profId, :);
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, param), ...
                  fliplr([profId-1 0]), fliplr([1 length(value)]), value);

               if (idLoop == 1)
                  param = ['PROFILE_' paramName '_QC'];
                  value = a_profStructOld.data.(param)(profId);
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, param), ...
                     profId-1, 1, value);
               else
                  param = [paramName '_ADJUSTED_ERROR'];
                  value = a_profStructOld.data.(param)(profId, :);
                  netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, param), ...
                     fliplr([profId-1 0]), fliplr([1 length(value)]), value);
               end
            end
         end
      end
      
      % add history information that concerns the current program
      [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
      value = 'IF';
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([nHistory profId-1 0]), ...
         fliplr([1 1 length(value)]), value');
      value = 'COCD';
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([nHistory profId-1 0]), ...
         fliplr([1 1 length(value)]), value');
      value = g_cocd_ncCopyMonoProfileDmAndQcVersion;
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([nHistory profId-1 0]), ...
         fliplr([1 1 length(value)]), value');
      value = g_cocd_historyReferenceToReport;
      if (~isempty(value))
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_REFERENCE'), ...
         fliplr([nHistory profId-1 0]), ...
         fliplr([1 1 length(value)]), value');
      end
      value = dateUpdate;
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistory profId-1 0]), ...
         fliplr([1 1 length(value)]), value');
   end   
end

% update QC that have been set with SCOOP
if (~isempty(a_rtProfIdToUpdate))
      
   for idProf = 1:length(a_rtProfIdToUpdate)
      profId = a_rtProfIdToUpdate(idProf); 
      profNHistory = a_nHistoryData(idProf);
      
      % update QC data
      if (~isempty(a_updatedData))
         paramList = a_updatedData(find([a_updatedData{:, 1}] == profId), 2);
         for idParam = 1:length(paramList)
            paramNameQc = [paramList{idParam} '_QC'];
            value = a_profStructNew.data.(paramNameQc)(profId, :);
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, paramNameQc), ...
               fliplr([profId-1 0]), fliplr([1 length(value)]), value);

            paramName = regexprep(paramList{idParam}, '_ADJUSTED', '');
            profParamQc = ['PROFILE_' paramName '_QC'];
            value = a_profStructNew.data.(profParamQc)(profId);
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, profParamQc), ...
               profId-1, 1, value);
         end
      end
      
      % update HISTORY data
      if (sum(sum(sum(sum(a_profStructNew.info.PARAMETER ~= a_profStructOld.info.PARAMETER, 1), 2), 3), 4) ~= 0)
         fprintf('ERROR: Float #%d Cycle #%d%c: PARAMETER information differ - SCCOP HISTORY cannot be reported\n', ...
            g_cocd_floatNum, g_cocd_cycleNum, g_cocd_cycleDir);
      else
         [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
         fielNames = fields(profNHistory);
         for idVar = 2:length(fielNames)
            varName = fielNames{idVar};
            value = profNHistory.(varName);
            if (ischar(value))
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                  fliplr([nHistory profId-1 0]), fliplr([1 1 length(value)]), value');
            else
               netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, varName), ...
                  fliplr([nHistory profId-1]), fliplr([1 1]), value);
            end
         end
      end
   end
   
   % add history information that concerns the current program
   uniqueDmProfIdToUpdate = unique(a_dmProfIdToUpdate);
   for idProf = 1:length(uniqueDmProfIdToUpdate)
      profId = uniqueDmProfIdToUpdate(idProf);
      if (~ismember(profId, a_dmProfIdToUpdate))
         [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
         value = 'IF';
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
            fliplr([nHistory profId-1 0]), ...
            fliplr([1 1 length(value)]), value');
         value = 'COCD';
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
            fliplr([nHistory profId-1 0]), ...
            fliplr([1 1 length(value)]), value');
         value = g_cocd_ncCopyMonoProfileDmAndQcVersion;
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
            fliplr([nHistory profId-1 0]), ...
            fliplr([1 1 length(value)]), value');
         value = g_cocd_historyReferenceToReport;
         if (~isempty(value))
            netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_REFERENCE'), ...
               fliplr([nHistory profId-1 0]), ...
               fliplr([1 1 length(value)]), value');
         end
         value = dateUpdate;
         netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
            fliplr([nHistory profId-1 0]), ...
            fliplr([1 1 length(value)]), value');
      end
   end
end

% update the update date of the Output file
netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), dateUpdate);

% update the 'history' global attribute of the Output file
creationDate = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'));
globalHistoryText = [ ...
   datestr(datenum(creationDate', 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; ' ...
   datestr(datenum(dateUpdate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COCD (V' g_cocd_ncCopyMonoProfileDmAndQcVersion ') tool)'];
netcdf.reDef(fCdf);
netcdf.putAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), 'history', globalHistoryText);

% add new global attributes
for idG = 1:size(a_newGlobalAtt, 1)
   netcdf.putAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), a_newGlobalAtt{idG, 1}, a_newGlobalAtt{idG, 2});
end

netcdf.endDef(fCdf);

netcdf.close(fCdf);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Update the N_CALIB dimension of a PROF file.
%
% SYNTAX :
%  [o_ok] = update_n_calib_dim_in_prof_file(a_profFileName, a_nCalibNew)
%
% INPUT PARAMETERS :
%   a_profFileName : PROF file path name
%   a_nCalibNew    : new N_CALIB dimension
%
% OUTPUT PARAMETERS :
%   o_ok : ok flag (1 if in the update succeeded, 0 otherwise)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_n_calib_dim_in_prof_file(a_profFileName, a_nCalibNew)

% output parameters initialization
o_ok = 0;


% directory to store temporary files
[filePath, fileName, fileExtension] = fileparts(a_profFileName);
DIR_TMP_FILE = [filePath '/tmp/'];

% delete the temp directory
remove_directory(DIR_TMP_FILE);

% create the temp directory
mkdir(DIR_TMP_FILE);

% make a copy of the file in the temp directory
profFileName = [DIR_TMP_FILE '/' fileName fileExtension];
tmpProfFileName = [DIR_TMP_FILE '/' fileName '_tmp' fileExtension];
copy_file(a_profFileName, tmpProfFileName);

% retrieve the file schema
outputFileSchema = ncinfo(tmpProfFileName);

% update the file schema with the correct N_CALIB dimension
[outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
   'N_CALIB', a_nCalibNew);

% create updated file
ncwriteschema(profFileName, outputFileSchema);

% copy data in updated file
for idVar = 1:length(outputFileSchema.Variables)
   varData = ncread(tmpProfFileName, outputFileSchema.Variables(idVar).Name);
   if (~isempty(varData))
      ncwrite(profFileName, outputFileSchema.Variables(idVar).Name, varData);
   end
end

% update input file
move_file(profFileName, a_profFileName);

% delete the temp directory
remove_directory(DIR_TMP_FILE);

o_ok = 1;

return

% ------------------------------------------------------------------------------
% Modify the value of a dimension in a NetCDF schema.
%
% SYNTAX :
%  [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
%    a_dimName, a_dimVal)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_dimName      : dimension name
%   a_dimVal       : dimension value
%
% OUTPUT PARAMETERS :
%   o_outputSchema  : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/09/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_dim_in_nc_schema(a_inputSchema, ...
   a_dimName, a_dimVal)

% output parameters initialization
o_outputSchema = [];

% update the dimension
idDim = find(strcmp(a_dimName, {a_inputSchema.Dimensions.Name}) == 1, 1);

if (~isempty(idDim))
   a_inputSchema.Dimensions(idDim).Length = a_dimVal;
   
   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      idDims = find(strcmp(a_dimName, {var.Dimensions.Name}) == 1);
      a_inputSchema.Variables(idVar).Size(idDims) = a_dimVal;
      for idDim = 1:length(idDims)
         a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = a_dimVal;
      end
   end
end

o_outputSchema = a_inputSchema;

return

% ------------------------------------------------------------------------------
% Retrieve I parameters associated to a given list of B parameters.
%
% SYNTAX :
%  [o_paramNameList] = get_associated_param(a_paramNameList)
%
% INPUT PARAMETERS :
%   a_paramNameList : list of B parameter names
%
% OUTPUT PARAMETERS :
%   o_paramNameList : B parameter and associated I ones
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   08/10/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_paramNameList] = get_associated_param(a_paramNameList)

% output parameters initialization
o_paramNameList = [];

for idP = 1:length(a_paramNameList)
   
   switch (a_paramNameList{idP})
      
      case {'CNDC', 'PRES', 'PSAL', 'TEMP'}
         fprintf('WARNING: You set "PARAMETER TO IGNORE" to ''%s'': a core parameter is not accepted by this tool - exit\n', a_paramNameList{idP});
         
      case 'DOXY'
         o_paramNameList = [o_paramNameList ...
            {'DOXY'} ...
            {'TEMP_DOXY'} ...
            {'TEMP_VOLTAGE_DOXY'} ...
            {'VOLTAGE_DOXY'} ...
            {'FREQUENCY_DOXY'} ...
            {'COUNT_DOXY'} ...
            {'BPHASE_DOXY'} ...
            {'DPHASE_DOXY'} ...
            {'TPHASE_DOXY'} ...
            {'C1PHASE_DOXY'} ...
            {'C2PHASE_DOXY'} ...
            {'MOLAR_DOXY'} ...
            {'PHASE_DELAY_DOXY'} ...
            {'MLPL_DOXY'} ...
            {'RPHASE_DOXY'} ...
            {'TEMP_COUNT_DOXY'} ...
            {'LED_FLASHING_COUNT_DOXY'} ...
            {'PPOX_DOXY'} ...
            {'DOXY2'} ...
            {'TEMP_DOXY2'} ...
            {'TEMP_VOLTAGE_DOXY2'} ...
            {'VOLTAGE_DOXY2'} ...
            {'FREQUENCY_DOXY2'} ...
            {'COUNT_DOXY2'} ...
            {'BPHASE_DOXY2'} ...
            {'DPHASE_DOXY2'} ...
            {'TPHASE_DOXY2'} ...
            {'C1PHASE_DOXY2'} ...
            {'C2PHASE_DOXY2'} ...
            {'MOLAR_DOXY2'} ...
            {'PHASE_DELAY_DOXY2'} ...
            {'MLPL_DOXY2'} ...
            {'RPHASE_DOXY2'} ...
            {'TEMP_COUNT_DOXY2'} ...
            {'LED_FLASHING_COUNT_DOXY2'} ...
            {'PPOX_DOXY2'} ...
            ];
         
      case 'BBP532'
         o_paramNameList = [o_paramNameList ...
            {'BBP532'} ...
            {'BETA_BACKSCATTERING532'} ...
            ];
         
      case 'BBP700'
         o_paramNameList = [o_paramNameList ...
            {'BBP700'} ...
            {'BETA_BACKSCATTERING700'} ...
            ];
         
      case 'CDOM'
         o_paramNameList = [o_paramNameList ...
            {'CDOM'} ...
            {'FLUORESCENCE_CDOM'} ...
            ];
         
      case 'CHLA'
         o_paramNameList = [o_paramNameList ...
            {'CHLA'} ...
            {'CHLA_FLUORESCENCE'} ...
            {'FLUORESCENCE_CHLA'} ...
            {'FLUORESCENCE_VOLTAGE_CHLA'} ...
            {'TEMP_CPU_CHLA'} ...
            ];
         
      case 'DOWN_IRRADIANCE380'
         o_paramNameList = [o_paramNameList ...
            {'DOWN_IRRADIANCE380'} ...
            {'RAW_DOWNWELLING_IRRADIANCE380'} ...
            ];
         
      case 'DOWN_IRRADIANCE412'
         o_paramNameList = [o_paramNameList ...
            {'DOWN_IRRADIANCE412'} ...
            {'RAW_DOWNWELLING_IRRADIANCE412'} ...
            ];
         
      case 'DOWN_IRRADIANCE443'
         o_paramNameList = [o_paramNameList ...
            {'DOWN_IRRADIANCE443'} ...
            {'RAW_DOWNWELLING_IRRADIANCE443'} ...
            ];
         
      case 'DOWN_IRRADIANCE490'
         o_paramNameList = [o_paramNameList ...
            {'DOWN_IRRADIANCE490'} ...
            {'RAW_DOWNWELLING_IRRADIANCE490'} ...
            ];
         
      case 'DOWN_IRRADIANCE555'
         o_paramNameList = [o_paramNameList ...
            {'DOWN_IRRADIANCE555'} ...
            {'RAW_DOWNWELLING_IRRADIANCE555'} ...
            ];
         
      case 'DOWNWELLING_PAR'
         o_paramNameList = [o_paramNameList ...
            {'DOWNWELLING_PAR'} ...
            {'RAW_DOWNWELLING_PAR'} ...
            ];
         
      case 'NITRATE'
         o_paramNameList = [o_paramNameList ...
            {'NITRATE'} ...
            {'MOLAR_NITRATE'} ...
            {'UV_INTENSITY_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE'} ...
            {'UV_INTENSITY_DARK_SEAWATER_NITRATE'} ...
            {'FIT_ERROR_NITRATE'} ...
            {'TEMP_NITRATE'} ...
            {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
            {'HUMIDITY_NITRATE'} ...
            ];
         
      case 'BISULFIDE'
         o_paramNameList = [o_paramNameList ...
            {'BISULFIDE'} ...
            {'UV_INTENSITY_NITRATE'} ...
            {'UV_INTENSITY_DARK_NITRATE'} ...
            {'UV_INTENSITY_DARK_SEAWATER_NITRATE'} ...
            {'FIT_ERROR_NITRATE'} ...
            {'TEMP_NITRATE'} ...
            {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
            {'HUMIDITY_NITRATE'} ...
            ];
         
      case 'PH_IN_SITU_TOTAL'
         o_paramNameList = [o_paramNameList ...
            {'PH_IN_SITU_TOTAL'} ...
            {'PH_IN_SITU_FREE'} ...
            {'PH_IN_SITU_SEAWATER'} ...
            {'VRS_PH'} ...
            {'VK_PH'} ...
            {'IB_PH'} ...
            {'IK_PH'} ...
            {'TEMP_PH'} ...
            {'TEMP_SPECTROPHOTOMETER_NITRATE'} ...
            ];
         
      case 'TURBIDITY'
         o_paramNameList = [o_paramNameList ...
            {'TURBIDITY'} ...
            {'SIDE_SCATTERING_TURBIDITY'} ...
            {'TURBIDITY_VOLTAGE'} ...
            ];
         
      otherwise
         fprintf('WARNING: You set "PARAMETER TO IGNORE" to ''%s'': this parameter is not managed yet by this tool - exit\n', a_paramNameList{idP});
   end
end

return

% ------------------------------------------------------------------------------
% Check OUTPUT data set to report files that disapeared and to duplicate
% associated NEW files if any.
%
% SYNTAX :
%  finalize_data_set(a_floatWmo,  ...
%    a_dirInputOldNcFiles,  a_dirInputNewNcFiles,  a_dirOutputNcFiles, a_errorProfInfo)
%
% INPUT PARAMETERS :
%   a_floatWmo            : float WMO to be processed
%   a_dirInputOldNcFiles  : name of input OLD data set directory
%   a_dirOutputNcFiles    : name of output data set directory
%   a_dirInputNewNcFiles  : name of input NEW data set directory
%   a_errorProfInfo       : profiles that should not be considered
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function finalize_data_set(a_floatWmo,  ...
   a_dirInputOldNcFiles,  a_dirInputNewNcFiles,  a_dirOutputNcFiles, a_errorProfInfo)

% list of updated files
global g_cocd_updatedFileNameList;

% list of deleted files
global g_cocd_deletedFileNameList;

% RT processing flag
global g_cocd_realtimeFlag;

% report information structure
global g_cocd_reportStruct;


% process the float
floatNum = a_floatWmo;
floatNumStr = num2str(floatNum);

floatOutputDirPathName = [a_dirOutputNcFiles '/' floatNumStr '/'];
floatOldDirPathName = [a_dirInputOldNcFiles '/' floatNumStr '/'];
floatNewDirPathName = [a_dirInputNewNcFiles '/' floatNumStr '/'];
if ((exist(floatOutputDirPathName, 'dir') == 7) && ...
      (exist(floatOldDirPathName, 'dir') == 7) && ...
      (exist(floatNewDirPathName, 'dir') == 7))

   outputProfDir = [a_dirOutputNcFiles '/' floatNumStr '/profiles/'];
   oldProfDir = [a_dirInputOldNcFiles '/' floatNumStr '/profiles/'];
   newProfDir = [a_dirInputNewNcFiles '/' floatNumStr '/profiles/'];

   % retrieve information of OLD and output data sets
   oldProfInfo = get_prof_info(floatNumStr, oldProfDir);
   outputProfInfo = get_prof_info(floatNumStr, outputProfDir);

   % if a BD file is missing in the OUTPUT dir:
   % - report that it has been removed (so that it will be removed from the
   % GDAC)
   % - if the corresponding BR file exists in the NEW dir, duplicate it in
   % the OUTPUT dir
   oldCyNumList = unique(oldProfInfo(:, 1));
   for idCy = 1:length(oldCyNumList)

      cyNum = oldCyNumList(idCy);

      % process descending and ascending profiles
      for idDir = 1:2

         % do not consider profiles in error
         if (~isempty(a_errorProfInfo))
            if (any((a_errorProfInfo(:, 1) == floatNum) & ...
                  (a_errorProfInfo(:, 2) == cyNum) & (a_errorProfInfo(:, 3) == idDir)))
               continue
            end
         end

         idProfOld = find((oldProfInfo(:, 1) == cyNum) & (oldProfInfo(:, 2) == idDir) & ...
            (oldProfInfo(:, 3) == 1) & (oldProfInfo(:, 4) == 1), 1);
         if (~isempty(idProfOld))
            idProfOut = find((outputProfInfo(:, 1) == cyNum) & (outputProfInfo(:, 2) == idDir) & ...
               (outputProfInfo(:, 3) == 1) & (outputProfInfo(:, 4) == 1), 1);
            if (isempty(idProfOut))

               if (idDir == 1)
                  deletedProfFilePathName = [oldProfDir '/' sprintf('BD%d_%03dD.nc', floatNum, cyNum)];
                  duplicateProfFilePathName = [newProfDir '/' sprintf('BR%d_%03dD.nc', floatNum, cyNum)];
               else
                  deletedProfFilePathName = [oldProfDir '/' sprintf('BD%d_%03d.nc', floatNum, cyNum)];
                  duplicateProfFilePathName = [newProfDir '/' sprintf('BR%d_%03dD.nc', floatNum, cyNum)];
               end

               % store deleted file name list
               g_cocd_deletedFileNameList{end+1} = deletedProfFilePathName;
               if (g_cocd_realtimeFlag == 1)
                  g_cocd_reportStruct.deletedFile = [g_cocd_reportStruct.deletedFile {deletedProfFilePathName}];
               end

               if (exist(duplicateProfFilePathName, 'file') == 2)

                  copy_file(duplicateProfFilePathName, outputProfDir);

                  % store updated file name list
                  g_cocd_updatedFileNameList{end+1} = duplicateProfFilePathName;
                  if (g_cocd_realtimeFlag == 1)
                     g_cocd_reportStruct.updatedFile = [g_cocd_reportStruct.updatedFile {duplicateProfFilePathName}];
                  end
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Retrieve information on prof files of a given directory.
%
% SYNTAX :
%  [o_profInfo] = get_prof_info(a_floatNumStr, a_dirName)
%
% INPUT PARAMETERS :
%   a_floatNumStr : float WMO number
%   a_dirName     : concerned directory
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profInfo] = get_prof_info(a_floatNumStr, a_dirName)

% output parameters initialization
o_profInfo = [];


files = dir([a_dirName '/' '*' a_floatNumStr '*.nc']);
o_profInfo = nan(length(files), 4);
for idFile = 1:length(files)
   fileName = files(idFile).name;
   fileName = fileName(1:end-3);
   idFUs = strfind(fileName, '_');
   cyNum = str2double(fileName(idFUs+1:idFUs+3));
   if (fileName(end) == 'D')
      profDir = 1;
   else
      profDir = 2;
   end
   if (fileName(1) == 'R')
      dmFlag = 0;
      bFlag = 0;
   elseif (fileName(1) == 'D')
      dmFlag = 1;
      bFlag = 0;
   elseif (fileName(1) == 'B')
      bFlag = 1;
      if (fileName(2) == 'R')
         dmFlag = 0;
      elseif (fileName(2) == 'D')
         dmFlag = 1;
      end
   end
   o_profInfo(idFile, :) = [cyNum profDir bFlag dmFlag];
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
%   06/12/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataValues] = get_data_from_name(a_dataName, a_dataList)

% output parameters initialization
o_dataValues = [];

idVal = find(strcmp(a_dataName, a_dataList(1:2:end)) == 1, 1);
if (~isempty(idVal))
   o_dataValues = a_dataList{2*idVal};
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
         %          fprintf('WARNING: Variable %s not present in file : %s\n', ...
         %             varName, a_ncPathFileName);
         o_ncData = [o_ncData {varName} {''}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return

% ------------------------------------------------------------------------------
% Retrieve global attributes from NetCDF file.
%
% SYNTAX :
%  [o_globalAttData] = get_global_att_from_nc_file(a_ncPathFileName)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%
% OUTPUT PARAMETERS :
%   o_globalAttData : retrieved global attributes
%
% EXAMPLES :
%
% SEE ALSO : 
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/04/2020 - RNU - creation
% ------------------------------------------------------------------------------
function [o_globalAttData] = get_global_att_from_nc_file(a_ncPathFileName)

% output parameters initialization
o_globalAttData = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return
   end
   
   [nbDims, nbVars, nbGAtts, unlimId] = netcdf.inq(fCdf);
   
   % store global attributes
   for idGAtt = 0:nbGAtts-1
      attName = netcdf.inqAttName(fCdf, netcdf.getConstant('NC_GLOBAL'), idGAtt);
      attValue = netcdf.getAtt(fCdf, netcdf.getConstant('NC_GLOBAL'), attName);
      o_globalAttData = [o_globalAttData; [{attName} {attValue}]];
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
   'updatedFile', '', ...
   'deletedFile', '', ...
   'errorProf', '');

return
