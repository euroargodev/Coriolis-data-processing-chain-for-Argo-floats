% ------------------------------------------------------------------------------
% Update the Argo format of NetCDF files.
%
% SYNTAX :
%   nc_update_argo_format_move_mtime_10aa or 
%   nc_update_argo_format_move_mtime_10aa(6900189, 7900118)
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
%   03/15/2022 - RNU - V 10aa: move MTIME parameter from B-PROF to C-PROF file.
% ------------------------------------------------------------------------------
function nc_update_argo_format_move_mtime_10aa(varargin)

% only to check or to do the job
DO_IT = 0;

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of NetCDF files to update
% (expected path to NetCDF files: DIR_INPUT_OUTPUT_NC_FILES\dac_name\wmo_number)
DIR_INPUT_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\OUT\test_move_mtime\';
DIR_INPUT_OUTPUT_NC_FILES = 'D:\202202-ArgoData\';

% temporary directory used to update the files
DIR_TMP = 'C:\Users\jprannou\_DATA\OUT\tmp\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% program version
global g_couf_ncUpdateArgoFormatVersion;
g_couf_ncUpdateArgoFormatVersion = '10aa';

% DOM node of XML report
global g_couf_xmlReportDOMNode;

% report information structure
global g_couf_floatNum;
global g_couf_reportData;
g_couf_reportData = [];
g_couf_reportData.profFile = [];
g_couf_reportData.float = [];


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
            return
         end
         
         fprintf('Floats from list: %s\n', floatListFileName);
         floatList = load(floatListFileName);
      end
   else
      % floats to process come from input parameters
      floatList = cell2mat(varargin);
   end
   
   
   % create a temporary directory for this run
   tmpDir = [DIR_TMP '/' 'nc_update_argo_format_move_mtime_10aa_' currentTime];
   status = mkdir(tmpDir);
   if (status ~= 1)
      fprintf('ERROR: cannot create temporary directory (%s)\n', tmpDir);
   end
   
   % create and start log file recording
   logFile = [DIR_LOG_FILE '/' 'nc_update_argo_format_move_mtime_10aa_' currentTime '.log'];
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
                     
                     g_couf_floatNum = floatWmo;
                     fprintf('%03d/%03d %d\n', floatNum, length(floatDir)-2, floatWmo);
                                                       
                     floatDirPathName = [floatDirPathName '/profiles'];
                     if (exist(floatDirPathName, 'dir') == 7)

                        if (isempty(dir([floatDirPathName '/' sprintf('B*%d_*.nc', floatWmo)])))
                           continue
                        end

                        % gather files to process
                        floatFiles = dir([floatDirPathName '/' sprintf('*%d_*.nc', floatWmo)]);
                        fileList = cell(length(floatFiles), 4);
                        nbL = 0;
                        for idFile = 1:length(floatFiles)
                           
                           floatFileName = floatFiles(idFile).name;
                           if (ismember(floatFileName(1), 'RDB'))
                              idFUs = strfind(floatFileName, '_');
                              cyNum = str2double(floatFileName(idFUs+1:idFUs+3));
                              if (floatFileName(idFUs+4) == 'D')
                                 direction = 1;
                              else
                                 direction = 2;
                              end
                              if ((floatFileName(1) == 'R') || (floatFileName(1) == 'D'))
                                 if (nbL > 0)
                                    idF = find(([fileList{:, 1}] == cyNum) & ([fileList{:, 2}] == direction));
                                    if (isempty(idF))
                                       fileList{nbL+1, 1} = cyNum;
                                       fileList{nbL+1, 2} = direction;
                                       fileList{nbL+1, 3} = floatFileName;
                                       nbL = nbL + 1;
                                    else
                                       fileList{idF, 3} = floatFileName;
                                    end
                                 else
                                    fileList{nbL+1, 1} = cyNum;
                                    fileList{nbL+1, 2} = direction;
                                    fileList{nbL+1, 3} = floatFileName;
                                    nbL = nbL + 1;
                                 end
                              else
                                 if (nbL > 0)
                                    idF = find(([fileList{:, 1}] == cyNum) & ([fileList{:, 2}] == direction));
                                    if (isempty(idF))
                                       fileList{nbL+1, 1} = cyNum;
                                       fileList{nbL+1, 2} = direction;
                                       fileList{nbL+1, 4} = floatFileName;
                                       nbL = nbL + 1;
                                    else
                                       fileList{idF, 4} = floatFileName;
                                    end
                                 else
                                    fileList{nbL+1, 1} = cyNum;
                                    fileList{nbL+1, 2} = direction;
                                    fileList{nbL+1, 4} = floatFileName;
                                    nbL = nbL + 1;
                                 end
                              end
                           end
                        end
                        fileList(nbL+1:end, :) = [];

                        % process files by pairs
                        for idF = 1:size(fileList, 1)
                           process_nc_file(fileList{idF, 3}, fileList{idF, 4}, floatDirPathName, tmpDir, DO_IT);
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
   status = rmdir(tmpDir,'s');
   if (status ~= 1)
      fprintf('ERROR: cannot remove temporary directory (%s)\n', tmpDir);
   end
   
   diary off;
   
   % finalize XML report
   status = finalize_xml_report(ticStartTime, logFile, []);
   
catch
   
   diary off;
   
   % finalize XML report
   status = finalize_xml_report(ticStartTime, logFile, lasterror);
   
end

% create the XML report path file name
xmlFileName = [DIR_XML_FILE '/co041405_' currentTime '.xml'];

% save the XML report
xmlwrite(xmlFileName, g_couf_xmlReportDOMNode);
% if (strcmp(status, 'nok') == 1)
%    edit(xmlFileName);
% end

return

% ------------------------------------------------------------------------------
% Process NetCDF C and B files of a given cycle.
%
% SYNTAX :
%  process_nc_file(a_cFileName, a_bFileName, a_ncPathFileName, a_tmpDir, a_doItFlag)
%
% INPUT PARAMETERS :
%   a_cFileName      : C-PROF file name
%   a_bFileName      : B-PROF file name
%   a_ncPathFileName : directory of the file to process
%   a_tmpDir         : temporary directory
%   a_doItFlag       : only to check or to do the job flag
%
% OUTPUT PARAMETERS :
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_cFileName, a_bFileName, a_ncPathFileName, a_tmpDir, a_doIt)

% report information structure
global g_couf_floatNum;
global g_couf_reportData;


if (isempty(a_cFileName) || isempty(a_bFileName))
   return
end

cFilePathName = [a_ncPathFileName '/' a_cFileName];
bFilePathName = [a_ncPathFileName '/' a_bFileName];

if ((exist(cFilePathName, 'file') == 2) && (exist(bFilePathName, 'file') == 2))

   % check data to see if the file should be updated
   updateNeeded = 0;
   wantedVars = [ ...
      {'FORMAT_VERSION'} ...
      {'STATION_PARAMETERS'} ...
      ];
   ncData = get_var_from_nc_file(bFilePathName, wantedVars);

   formatVersion = strtrim(get_data_from_name('FORMAT_VERSION', ncData)');
   if (strcmp(formatVersion, '3.1'))
      stationParameters = get_data_from_name('STATION_PARAMETERS', ncData);
      [~, nParam, nProf] = size(stationParameters);
      for idProf = 1:nProf
         for idParam = 1:nParam
            paramName = strtrim(stationParameters(:, idParam, idProf)');
            if (strcmp(paramName, 'MTIME'))
               updateNeeded = 1;
               break
            end
         end
         if (updateNeeded)
            break
         end
      end
   end

   % update the file
   if (updateNeeded == 1)

      if (~a_doIt)
         fprintf('Float to update: %d\n', g_couf_floatNum);
         return
      end
      
      fprintf('Files to update: %s and %s\n', a_cFileName, a_bFileName);

      % remove MTIME information from B file
      [mtimeData, ok] = remove_mtime_from_file(a_bFileName, a_ncPathFileName, a_tmpDir);

      if (ok == 1)

         % insert MTIME information in C file
         ok = add_mtime_in_file(mtimeData, a_cFileName, a_ncPathFileName, a_tmpDir);

         if (ok == 1)
            % store the information for the XML report
            g_couf_reportData.profFile = [g_couf_reportData.profFile {cFilePathName}];
            g_couf_reportData.float = [g_couf_reportData.float g_couf_floatNum];
            g_couf_reportData.profFile = [g_couf_reportData.profFile {bFilePathName}];
            g_couf_reportData.float = [g_couf_reportData.float g_couf_floatNum];
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Add MTIME parameter information in NetCDF B-PROF file.
%
% SYNTAX :
%  [o_ok] = add_mtime_in_file(a_mtimeData, a_ncFileName, a_ncPathFileName, a_tmpDir)
%
% INPUT PARAMETERS :
%   a_mtimeData      : MTIME information to add
%   a_ncFileName     : name of the file to update
%   a_ncPathFileName : directory of the file to update
%   a_tmpDir         : temporary directory
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
%   03/16/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = add_mtime_in_file(a_mtimeData, a_ncFileName, a_ncPathFileName, a_tmpDir)

% output parameters initialization
o_ok = 0;


% program version
global g_couf_ncUpdateArgoFormatVersion;


cFilePathName = [a_ncPathFileName '/' a_ncFileName];
if (exist(cFilePathName, 'file') == 2)

   % make a copy of the file in the temporary directory
   fileToUpdate = [a_tmpDir '/' a_ncFileName];
   status = copyfile(cFilePathName, fileToUpdate);
   if (status ~= 1)
      fprintf('ERROR: cannot copy file to update (%s) to temporary directory (%s)\n', cFilePathName, a_tmpDir);
      return
   end

   % retrieve the file schema
   outputFileSchema = ncinfo(fileToUpdate);

   % update the file schema
   outputFileSchema = update_file_schema(outputFileSchema, 1);

   % create a temporary file with the updated file schema
   [filePath, fileName, fileExtension] = fileparts(fileToUpdate);
   tmpProfFileName = [filePath '/' fileName '_tmp' fileExtension];
   ncwriteschema(tmpProfFileName, outputFileSchema);

   % copy data in updated file
   data = [];
   for idVar = 1:length(outputFileSchema.Variables)
      varName = outputFileSchema.Variables(idVar).Name;
      varData = ncread(cFilePathName, outputFileSchema.Variables(idVar).Name);
      if (~isempty(varData))
         if (~ismember(varName, [ ...
               {'STATION_PARAMETERS'} ...
               {'PARAMETER_DATA_MODE'} ...
               {'PARAMETER'} ...
               {'SCIENTIFIC_CALIB_EQUATION'} ...
               {'SCIENTIFIC_CALIB_COEFFICIENT'} ...
               {'SCIENTIFIC_CALIB_COMMENT'} ...
               {'SCIENTIFIC_CALIB_DATE'} ...
               ]))
            ncwrite(tmpProfFileName, outputFileSchema.Variables(idVar).Name, varData);
         else
            data.(varName) = varData;
         end
      end
   end

   % add MTIME related variables in updated file

   % open NetCDF file
   fCdf = netcdf.open(tmpProfFileName, 'WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', tmpProfFileName);
      return
   end

   netcdf.reDef(fCdf);

   nProfDimId = netcdf.inqDimID(fCdf, 'N_PROF');
   nLevelsDimId = netcdf.inqDimID(fCdf, 'N_LEVELS');

   % PROFILE_MTIME_QC
   profileParamQcVarId = netcdf.defVar(fCdf, 'PROFILE_MTIME_QC', 'NC_CHAR', nProfDimId);
   netcdf.putAtt(fCdf, profileParamQcVarId, 'long_name', sprintf('Global quality flag of MTIME profile'));
   netcdf.putAtt(fCdf, profileParamQcVarId, 'conventions', 'Argo reference table 2a');
   netcdf.putAtt(fCdf, profileParamQcVarId, '_FillValue', ' ');

   % MTIME
   paramMtimeVarId = netcdf.defVar(fCdf, 'MTIME', 'NC_DOUBLE', fliplr([nProfDimId nLevelsDimId]));
   paramMtime = get_netcdf_param_attributes('MTIME');
   if (~isempty(paramMtime.longName))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'long_name', paramMtime.longName);
   end
   if (~isempty(paramMtime.standardName))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'standard_name', paramMtime.standardName);
   end
   if (~isempty(paramMtime.fillValue))
      netcdf.putAtt(fCdf, paramMtimeVarId, '_FillValue', paramMtime.fillValue);
   end
   if (~isempty(paramMtime.units))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'units', paramMtime.units);
   end
   if (~isempty(paramMtime.validMin))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'valid_min', paramMtime.validMin);
   end
   if (~isempty(paramMtime.validMax))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'valid_max', paramMtime.validMax);
   end
   if (~isempty(paramMtime.cFormat))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'C_format', paramMtime.cFormat);
   end
   if (~isempty(paramMtime.fortranFormat))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'FORTRAN_format', paramMtime.fortranFormat);
   end
   if (~isempty(paramMtime.resolution))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'resolution', paramMtime.resolution);
   end
   if (~isempty(paramMtime.axis))
      netcdf.putAtt(fCdf, paramMtimeVarId, 'axis', paramMtime.axis);
   end

   % MTIME_QC
   paramMtimeQcVarId = netcdf.defVar(fCdf, 'MTIME_QC', 'NC_CHAR', fliplr([nProfDimId nLevelsDimId]));
   netcdf.putAtt(fCdf, paramMtimeQcVarId, 'long_name', 'quality flag');
   netcdf.putAtt(fCdf, paramMtimeQcVarId, 'conventions', 'Argo reference table 2');
   netcdf.putAtt(fCdf, paramMtimeQcVarId, '_FillValue', ' ');

   netcdf.endDef(fCdf);

   % add history information that concerns the current program
   historyInstitution = 'IF';
   historySoftware = 'COUF';
   historySoftwareRelease = g_couf_ncUpdateArgoFormatVersion;
   historyDate = datestr(now_utc, 'yyyymmddHHMMSS');

   % retrieve the creation date of the updated file
   dateCreation = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'))');

   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(historyDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COUF software (V ' g_couf_ncUpdateArgoFormatVersion '))'];
   netcdf.reDef(fCdf);
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   netcdf.endDef(fCdf);

   % update the update date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), historyDate);

   % update HISTORY information
   profList = unique([a_mtimeData.stationParametersProfList a_mtimeData.parameterProfList]);
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

   % update N_PARAM related variables

   % STATION_PARAMETERS
   stationParametersDataOld = data.STATION_PARAMETERS;
   [string16, nParam, nProf] = size(stationParametersDataOld);
   stationParametersDataNew = repmat(' ', string16, nParam+1, nProf);
   for idProf = 1:nProf
      if (ismember(idProf, a_mtimeData.stationParametersProfList))
         stationParametersDataNew(1:length('MTIME'), 1, idProf) = ('MTIME')';
      end
      for idParam = 1:nParam
         stationParametersDataNew(:, idParam+1, idProf) = stationParametersDataOld(:, idParam, idProf);
      end
   end
   ncwrite(tmpProfFileName, 'STATION_PARAMETERS', stationParametersDataNew);

   % PARAMETER and SCIENTIFC_CALIB_*
   parameterDataOld = data.PARAMETER;
   [string16, nParam, nCalib, nProf] = size(parameterDataOld);
   parameterDataNew = repmat(' ', string16, nParam+1, nCalib, nProf);
   sciCalibEqOld = data.SCIENTIFIC_CALIB_EQUATION;
   [string, nParam, nCalib, nProf] = size(sciCalibEqOld);
   sciCalibEqNew = repmat(' ', string, nParam+1, nCalib, nProf);
   sciCalibCoefOld = data.SCIENTIFIC_CALIB_COEFFICIENT;
   [string, nParam, nCalib, nProf] = size(sciCalibCoefOld);
   sciCalibCoefNew = repmat(' ', string, nParam+1, nCalib, nProf);
   sciCalibComOld = data.SCIENTIFIC_CALIB_COMMENT;
   [string, nParam, nCalib, nProf] = size(sciCalibComOld);
   sciCalibComNew = repmat(' ', string, nParam+1, nCalib, nProf);
   sciCalibDateOld = data.SCIENTIFIC_CALIB_DATE;
   [string, nParam, nCalib, nProf] = size(sciCalibDateOld);
   sciCalibDateNew = repmat(' ', string, nParam+1, nCalib, nProf);
   for idProf = 1:nProf
      for idCalib = 1:nCalib
         if (ismember(idProf, a_mtimeData.parameterProfList))
            parameterDataNew(1:length('MTIME'), 1, idCalib, idProf) = ('MTIME')';
         end
         if (~isempty(a_mtimeData.scientificData.equation))
            idF = find(([a_mtimeData.scientificData.equation{:, 1}] == idProf) & ...
               ([a_mtimeData.scientificData.equation{:, 2}] == idCalib));
            if (~isempty(idF))
               info = a_mtimeData.scientificData.equation{idF, 3};
               sciCalibEqNew(1:length(info), 1, idCalib, idProf) = info';
            end
         end
         if (~isempty(a_mtimeData.scientificData.coefficient))
            idF = find(([a_mtimeData.scientificData.coefficient{:, 1}] == idProf) & ...
               ([a_mtimeData.scientificData.coefficient{:, 2}] == idCalib));
            if (~isempty(idF))
               info = a_mtimeData.scientificData.coefficient{idF, 3};
               sciCalibCoefNew(1:length(info), 1, idCalib, idProf) = info';
            end
         end
         if (~isempty(a_mtimeData.scientificData.comment))
            idF = find(([a_mtimeData.scientificData.comment{:, 1}] == idProf) & ...
               ([a_mtimeData.scientificData.comment{:, 2}] == idCalib));
            if (~isempty(idF))
               info = a_mtimeData.scientificData.comment{idF, 3};
               sciCalibComNew(1:length(info), 1, idCalib, idProf) = info';
            end
         end
         if (~isempty(a_mtimeData.scientificData.date))
            idF = find(([a_mtimeData.scientificData.date{:, 1}] == idProf) & ...
               ([a_mtimeData.scientificData.date{:, 2}] == idCalib));
            if (~isempty(idF))
               info = a_mtimeData.scientificData.date{idF, 3};
               sciCalibDateNew(1:length(info), 1, idCalib, idProf) = info';
            end
         end
         for idParam = 1:nParam
            parameterDataNew(:, idParam+1, idCalib, idProf) = parameterDataOld(:, idParam, idCalib, idProf);
            sciCalibEqNew(:, idParam+1, idCalib, idProf) = sciCalibEqOld(:, idParam, idCalib, idProf);
            sciCalibCoefNew(:, idParam+1, idCalib, idProf) = sciCalibCoefOld(:, idParam, idCalib, idProf);
            sciCalibComNew(:, idParam+1, idCalib, idProf) = sciCalibComOld(:, idParam, idCalib, idProf);
            sciCalibDateNew(:, idParam+1, idCalib, idProf) = sciCalibDateOld(:, idParam, idCalib, idProf);
         end
      end
   end
   ncwrite(tmpProfFileName, 'PARAMETER', parameterDataNew);
   ncwrite(tmpProfFileName, 'SCIENTIFIC_CALIB_EQUATION', sciCalibEqNew);
   ncwrite(tmpProfFileName, 'SCIENTIFIC_CALIB_COEFFICIENT', sciCalibCoefNew);
   ncwrite(tmpProfFileName, 'SCIENTIFIC_CALIB_COMMENT', sciCalibComNew);
   ncwrite(tmpProfFileName, 'SCIENTIFIC_CALIB_DATE', sciCalibDateNew);

   % fill MTIME related variables in updated file
   ncwrite(tmpProfFileName, 'PROFILE_MTIME_QC', a_mtimeData.profileMtimeQcData);
   ncwrite(tmpProfFileName, 'MTIME', a_mtimeData.mtimeData);
   ncwrite(tmpProfFileName, 'MTIME_QC', a_mtimeData.mtimeQcData);

   % move the updated file to the original directory
   status = movefile(tmpProfFileName, cFilePathName);
   if (status ~= 1)
      fprintf('ERROR: cannot move updated file (%s) to replace input file (%s)\n', tmpProfFileName, bFilePathName);
      return
   end

   % output parameters
   o_ok = 1;

end

return

% ------------------------------------------------------------------------------
% Remove MTIME parameter information from NetCDF B-PROF file.
%
% SYNTAX :
%  [o_mtimeData, o_ok] = remove_mtime_from_file(a_ncFileName, a_ncPathFileName, a_tmpDir)
%
% INPUT PARAMETERS :
%   a_ncFileName     : name of the file to update
%   a_ncPathFileName : directory of the file to update
%   a_tmpDir         : temporary directory
%
% OUTPUT PARAMETERS :
%   o_mtimeData : removed MTIME information
%   o_ok        : 1 if update succeeded, 0 otherwise
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_mtimeData, o_ok] = remove_mtime_from_file(a_ncFileName, a_ncPathFileName, a_tmpDir)

% output parameters initialization
o_mtimeData = [];
o_ok = 0;


% program version
global g_couf_ncUpdateArgoFormatVersion;


bFilePathName = [a_ncPathFileName '/' a_ncFileName];
if (exist(bFilePathName, 'file') == 2)

   % make a copy of the file in the temporary directory
   fileToUpdate = [a_tmpDir '/' a_ncFileName];
   status = copyfile(bFilePathName, fileToUpdate);
   if (status ~= 1)
      fprintf('ERROR: cannot copy file to update (%s) to temporary directory (%s)\n', bFilePathName, a_tmpDir);
      return
   end

   % retrieve the input file schema
   inputFileSchema = ncinfo(bFilePathName);

   % retrieve the output file schema
   outputFileSchema = ncinfo(fileToUpdate);

   % update the file schema
   outputFileSchema = update_file_schema(outputFileSchema, -1);

   % create a temporary file with the updated file schema
   [filePath, fileName, fileExtension] = fileparts(fileToUpdate);
   tmpProfFileName = [filePath '/' fileName '_tmp' fileExtension];
   ncwriteschema(tmpProfFileName, outputFileSchema);

   % copy data in updated file
   mtimeId1 = -1;
   mtimeId2 = -1;
   profList = [];
   stationParametersProfList = [];
   parameterProfList = [];
   scientificData = [];
   scientificData.equation = [];
   scientificData.coefficient = [];
   scientificData.comment = [];
   scientificData.date = [];
   profileMtimeQcData = [];
   mtimeData = [];
   mtimeQcData = [];
   for idVar = 1:length(inputFileSchema.Variables)
      varName = inputFileSchema.Variables(idVar).Name;
      varData = ncread(bFilePathName, varName);
      if (~isempty(varData))
         switch (varName)
            case 'STATION_PARAMETERS'
               [~, nParam, nProf] = size(varData);
               for idProf = 1:nProf
                  for idParam = 1:nParam
                     paramName = strtrim(varData(:, idParam, idProf)');
                     if (strcmp(paramName, 'MTIME'))
                        mtimeId1 = idParam;
                        profList = [profList idProf];
                        stationParametersProfList = [stationParametersProfList idProf];
                     end
                  end
               end
               if (mtimeId1 ~= -1)
                  varData(:, mtimeId1, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case 'PARAMETER_DATA_MODE'
               if (mtimeId1 ~= -1)
                  varData(mtimeId1, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case 'PARAMETER'
               [~, nParam, nCalib, nProf] = size(varData);
               for idProf = 1:nProf
                  for idCalib = 1:nCalib
                     for idParam = 1:nParam
                        paramName = strtrim(varData(:, idParam, idCalib, idProf)');
                        if (strcmp(paramName, 'MTIME'))
                           mtimeId2 = idParam;
                           profList = [profList idProf];
                           parameterProfList = [parameterProfList idProf];
                        end
                     end
                     if (mtimeId2 ~= -1)
                        break
                     end
                  end
               end
               if (mtimeId2 ~= -1)
                  varData(:, mtimeId2, :, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case {'SCIENTIFIC_CALIB_EQUATION'}
               if (mtimeId2 ~= -1)
                  [~, ~, nCalib, nProf] = size(varData);
                  for idProf = 1:nProf
                     for idCalib = 1:nCalib
                        scientificCalibEq = strtrim(varData(:, mtimeId2, idCalib, idProf)');
                        if (~isempty(scientificCalibEq))
                           scientificData.equation = [scientificData.equation; ...
                              [idProf idCalib {scientificCalibEq}]];
                        end
                     end
                  end
                  varData(:, mtimeId2, :, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case {'SCIENTIFIC_CALIB_COEFFICIENT'}
               if (mtimeId2 ~= -1)
                  [~, ~, nCalib, nProf] = size(varData);
                  for idProf = 1:nProf
                     for idCalib = 1:nCalib
                        scientificCalibCoef = strtrim(varData(:, mtimeId2, idCalib, idProf)');
                        if (~isempty(scientificCalibCoef))
                           scientificData.coefficient = [scientificData.coefficient; ...
                              [idProf idCalib {scientificCalibCoef}]];
                        end
                     end
                  end
                  varData(:, mtimeId2, :, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case {'SCIENTIFIC_CALIB_COMMENT'}
               if (mtimeId2 ~= -1)
                  [~, ~, nCalib, nProf] = size(varData);
                  for idProf = 1:nProf
                     for idCalib = 1:nCalib
                        scientificCalibCom = strtrim(varData(:, mtimeId2, idCalib, idProf)');
                        if (~isempty(scientificCalibCom))
                           scientificData.comment = [scientificData.comment; ...
                              [idProf idCalib {scientificCalibCom}]];
                        end
                     end
                  end
                  varData(:, mtimeId2, :, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case {'SCIENTIFIC_CALIB_DATE'}
               if (mtimeId2 ~= -1)
                  [~, ~, nCalib, nProf] = size(varData);
                  for idProf = 1:nProf
                     for idCalib = 1:nCalib
                        scientificCalibDate = strtrim(varData(:, mtimeId2, idCalib, idProf)');
                        if (~isempty(scientificCalibDate))
                           scientificData.date = [scientificData.date; ...
                              [idProf idCalib {scientificCalibDate}]];
                        end
                     end
                  end
                  varData(:, mtimeId2, :, :) = [];
                  ncwrite(tmpProfFileName, varName, varData);
               end
            case 'PROFILE_MTIME_QC'
               profileMtimeQcData = varData;
            case 'MTIME'
               mtimeData = varData;
            case 'MTIME_QC'
               mtimeQcData = varData;
            otherwise
               ncwrite(tmpProfFileName, varName, varData);
         end
      end
   end

   % open NetCDF file
   fCdf = netcdf.open(tmpProfFileName, 'WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', tmpProfFileName);
      return
   end

   % add history information that concerns the current program
   historyInstitution = 'IF';
   historySoftware = 'COUF';
   historySoftwareRelease = g_couf_ncUpdateArgoFormatVersion;
   historyDate = datestr(now_utc, 'yyyymmddHHMMSS');

   % retrieve the creation date of the updated file
   dateCreation = deblank(netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_CREATION'))');

   % set the 'history' global attribute
   globalVarId = netcdf.getConstant('NC_GLOBAL');
   globalHistoryText = [datestr(datenum(dateCreation, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' creation; '];
   globalHistoryText = [globalHistoryText ...
      datestr(datenum(historyDate, 'yyyymmddHHMMSS'), 'yyyy-mm-ddTHH:MM:SSZ') ' last update (coriolis COUF software (V ' g_couf_ncUpdateArgoFormatVersion '))'];
   netcdf.reDef(fCdf);
   netcdf.putAtt(fCdf, globalVarId, 'history', globalHistoryText);
   netcdf.endDef(fCdf);

   % update the update date
   netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'DATE_UPDATE'), historyDate);

   % update HISTORY information
   profList = unique(profList);
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

   % move the updated file to the original directory
   status = movefile(tmpProfFileName, bFilePathName);
   if (status ~= 1)
      fprintf('ERROR: cannot move updated file (%s) to replace input file (%s)\n', tmpProfFileName, bFilePathName);
      return
   end

   % output parameters
   o_mtimeData.stationParametersProfList = stationParametersProfList;
   o_mtimeData.parameterProfList = parameterProfList;
   o_mtimeData.scientificData = scientificData;
   o_mtimeData.profileMtimeQcData = profileMtimeQcData;
   o_mtimeData.mtimeData = mtimeData;
   o_mtimeData.mtimeQcData = mtimeQcData;
   o_ok = 1;

end

return

% ------------------------------------------------------------------------------
% Update NetCDF file schema.
%
% SYNTAX :
%  [o_outputSchema] = update_file_schema(a_inputSchema, a_nParamOffset)
%
% INPUT PARAMETERS :
%   a_inputSchema  : input NetCDF schema
%   a_nParamOffset : offset for N_PARAM dimension
%
% OUTPUT PARAMETERS :
%   o_outputSchema : output NetCDF schema
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   03/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_outputSchema] = update_file_schema(a_inputSchema, a_nParamOffset)

% output parameters initialization
o_outputSchema = [];


if (a_nParamOffset == -1)

   % remove PROFILE_MTIME_QC, MTIME and MTIME_QC variables
   idDel = find(strcmp('PROFILE_MTIME_QC', {a_inputSchema.Variables.Name}), 1);
   idDel = [idDel find(strcmp('MTIME', {a_inputSchema.Variables.Name}), 1)];
   idDel = [idDel find(strcmp('MTIME_QC', {a_inputSchema.Variables.Name}), 1)];
   a_inputSchema.Variables(idDel) = [];
end

% update the N_PARAM dimension
dimName = 'N_PARAM';
idDim = find(strcmp(dimName, {a_inputSchema.Dimensions.Name}), 1);
if (~isempty(idDim))
   nParamNew = a_inputSchema.Dimensions(idDim).Length + a_nParamOffset;
   a_inputSchema.Dimensions(idDim).Length = nParamNew;
   
   % update the dimensions of the variables
   for idVar = 1:length(a_inputSchema.Variables)
      var = a_inputSchema.Variables(idVar);
      idDims = find(strcmp(dimName, {var.Dimensions.Name}));
      if (~isempty(idDims))
         a_inputSchema.Variables(idVar).Size(idDims) = nParamNew;
         for idDim = 1:length(idDims)
            a_inputSchema.Variables(idVar).Dimensions(idDims(idDim)).Length = nParamNew;
         end
      end
   end
end

o_outputSchema = a_inputSchema;

return

% ------------------------------------------------------------------------------
% Retrieve Matlab variable (definition and contents) from a NetCDF file.
%
% SYNTAX :
%  [o_ncVarList] = get_var_from_nc_file(a_ncPathFileName, a_wantedVars)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : NetCDF file name
%   a_wantedVars     : name of the variables to retrieve
%
% OUTPUT PARAMETERS :
%   o_ncVarList : retrieved information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncVarList] = get_var_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncVarList = [];


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
         varInfo = ncinfo(a_ncPathFileName, varName);
         o_ncVarList = [o_ncVarList {varName} {varValue}];
      else
         o_ncVarList = [o_ncVarList {varName} {[]}];
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
global g_couf_xmlReportDOMNode;

% decoder version
global g_couf_ncUpdateArgoFormatVersion;


% initialize XML report
docNode = com.mathworks.xml.XMLUtils.createDocument('coriolis_function_report');
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('function');
newChild.appendChild(docNode.createTextNode('co041405 '));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('comment');
newChild.appendChild(docNode.createTextNode('Argo Coriolis update format tool (nc_update_argo_format_move_mtime_10aa)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_couf_ncUpdateArgoFormatVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_couf_xmlReportDOMNode = docNode;

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
%   05/11/2016 - RNU - creation
% ------------------------------------------------------------------------------
function [o_status] = finalize_xml_report(a_ticStartTime, a_logFileName, a_error)

% DOM node of XML report
global g_couf_xmlReportDOMNode;

% report information structure
global g_couf_reportData;


% initalize final status
o_status = 'ok';

% finalize the report
docNode = g_couf_xmlReportDOMNode;
docRootNode = docNode.getDocumentElement;

newChild = docNode.createElement('updates');

newChildBis = docNode.createElement('updated_float_WMO_list');
if (isfield(g_couf_reportData, 'float'))
   wmoList = sort(unique(g_couf_reportData.float));
   newChildBis.appendChild(docNode.createTextNode(sprintf('%d ', wmoList)));
else
   newChildBis.appendChild(docNode.createTextNode(''));
end
newChild.appendChild(newChildBis);

% list of updated files
if (isfield(g_couf_reportData, 'profFile'))
   for idFile = 1:length(g_couf_reportData.profFile)
      newChildBis = docNode.createElement('updated_mono_profile_file');
      textNode = g_couf_reportData.profFile{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end
if (isfield(g_couf_reportData, 'mProfFil'))
   for idFile = 1:length(g_couf_reportData.mProfFil)
      newChildBis = docNode.createElement('updated_multi_profile_file');
      textNode = g_couf_reportData.mProfFil{idFile};
      newChildBis.appendChild(docNode.createTextNode(textNode));
      newChild.appendChild(newChildBis);
   end
end
if (isfield(g_couf_reportData, 'trajFile'))
   for idFile = 1:length(g_couf_reportData.trajFile)
      newChildBis = docNode.createElement('updated_trajectory_file');
      textNode = g_couf_reportData.trajFile{idFile};
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
%   05/11/2016 - RNU - creation
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
         if (strncmpi(line, 'INFO:', length('INFO:')))
            o_decInfoMsg = [o_decInfoMsg {strtrim(line(length('INFO:')+1:end))}];
         elseif (strncmpi(line, 'WARNING:', length('WARNING:')))
            o_decWarningMsg = [o_decWarningMsg {strtrim(line(length('WARNING:')+1:end))}];
         elseif (strncmpi(line, 'ERROR:', length('ERROR:')))
            o_decErrorMsg = [o_decErrorMsg {strtrim(line(length('ERROR:')+1:end))}];
         elseif (strncmpi(line, 'RTQC_INFO:', length('RTQC_INFO:')))
            o_rtQcInfoMsg = [o_rtQcInfoMsg {strtrim(line(length('RTQC_INFO:')+1:end))}];
         elseif (strncmpi(line, 'RTQC_WARNING:', length('RTQC_WARNING:')))
            o_rtQcWarningMsg = [o_rtQcWarningMsg {strtrim(line(length('RTQC_WARNING:')+1:end))}];
         elseif (strncmpi(line, 'RTQC_ERROR:', length('RTQC_ERROR:')))
            o_rtQcErrorMsg = [o_rtQcErrorMsg {strtrim(line(length('RTQC_ERROR:')+1:end))}];
         elseif (strncmpi(line, 'RTADJ_INFO:', length('RTADJ_INFO:')))
            o_rtAdjInfoMsg = [o_rtAdjInfoMsg {strtrim(line(length('RTADJ_INFO:')+1:end))}];
         elseif (strncmpi(line, 'RTADJ_WARNING:', length('RTADJ_WARNING:')))
            o_rtAdjWarningMsg = [o_rtAdjWarningMsg {strtrim(line(length('RTADJ_WARNING:')+1:end))}];
         elseif (strncmpi(line, 'RTADJ_ERROR:', length('RTADJ_ERROR:')))
            o_rtAdjErrorMsg = [o_rtAdjErrorMsg {strtrim(line(length('RTADJ_ERROR:')+1:end))}];
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
