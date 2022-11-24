% ------------------------------------------------------------------------------
% Update the Argo format of NetCDF files.
%
% SYNTAX :
%   nc_update_argo_format_set_param_attribute_01aa or 
%   nc_update_argo_format_set_param_attribute_01aa(6900189, 7900118)
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
%   02/10/2016 - RNU - V 01aa: set 'valid_min' attribute of C2PHASE_DOXY parameter to 0
%                              set 'valid_max' attribute of C2PHASE_DOXY parameter to 15
%                              set 'valid_min' attribute of DOXY parameter to -5
% ------------------------------------------------------------------------------
function nc_update_argo_format_set_param_attribute_01aa(varargin)

% list of floats to process (if empty, all encountered files will be checked)
FLOAT_LIST_FILE_NAME = 'C:\Users\jprannou\_RNU\DecArgo_soft\lists\_apex_argos_all.txt';
FLOAT_LIST_FILE_NAME = '';

% top directory of NetCDF files to update
% (expected path to NetCDF files: DIR_INPUT_OUTPUT_NC_FILES\dac_name\wmo_number)
DIR_INPUT_OUTPUT_NC_FILES = 'C:\Users\jprannou\_DATA\IN\dac_executif\';

% temporary directory used to update the files
DIR_TMP = 'C:\Users\jprannou\_DATA\IN\dac_executif\tmp\';

% directory to store the log file
DIR_LOG_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\log\';

% directory to store the XML file
DIR_XML_FILE = 'C:\Users\jprannou\_RNU\DecArgo_soft\work\xml\';

% program version
global g_couf_ncUpdateArgoFormatVersion;
g_couf_ncUpdateArgoFormatVersion = '01aa';

% DOM node of XML report
global g_couf_xmlReportDOMNode;

% report information structure
global g_couf_floatNum;
global g_couf_reportData;
g_couf_reportData = [];
g_couf_reportData.trajFile = [];
g_couf_reportData.mProfFil = [];
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
   tmpDir = [DIR_TMP '/' 'nc_update_argo_format_set_param_attribute_01aa_' currentTime];
   status = mkdir(tmpDir);
   if (status ~= 1)
      fprintf('ERROR: cannot create temporary directory (%s)\n', tmpDir);
   end
   
   % create and start log file recording
   logFile = [DIR_LOG_FILE '/' 'nc_update_argo_format_set_param_attribute_01aa_' currentTime '.log'];
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
                     
                     % multi-profile files
                     floatFiles = dir([floatDirPathName '/' sprintf('%d_*prof.nc', floatWmo)]);
                     for idFile = 1:length(floatFiles)
                        
                        floatFileName = floatFiles(idFile).name;
                        floatFilePathName = [floatDirPathName '/' floatFileName];
                        if (exist(floatFilePathName, 'file') == 2)
                           process_nc_file(floatFilePathName, tmpDir);
                        end
                     end
                     
                     % trajectory files
                     floatFiles = dir([floatDirPathName '/' sprintf('%d_*traj.nc', floatWmo)]);
                     for idFile = 1:length(floatFiles)
                        
                        floatFileName = floatFiles(idFile).name;
                        floatFilePathName = [floatDirPathName '/' floatFileName];
                        if (exist(floatFilePathName, 'file') == 2)
                           process_nc_file(floatFilePathName, tmpDir);
                        end
                     end
                     
                     % mono-profile files
                     floatDirPathName = [floatDirPathName '/profiles'];
                     if (exist(floatDirPathName, 'dir') == 7)
                        floatFiles = dir([floatDirPathName '/' sprintf('*%d_*.nc', floatWmo)]);
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
xmlFileName = [DIR_XML_FILE '/co041405_' currentTime '.xml'];

% save the XML report
xmlwrite(xmlFileName, g_couf_xmlReportDOMNode);
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
%   12/15/2015 - RNU - creation
% ------------------------------------------------------------------------------
function process_nc_file(a_ncPathFileName, a_tmpDir)

% report information structure
global g_couf_floatNum;
global g_couf_reportData;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % get information to see if the file should be updated
   updateNeeded = 0;
   wantedInputVars = [ ...
      {'FORMAT_VERSION'} ...
      {'DOXY'} ...
      {'DOXY2'} ...
      {'C2PHASE_DOXY'} ...
      ];
   [varList] = get_var_from_nc_file(a_ncPathFileName, wantedInputVars);
   if (~isempty(varList))
      
      idVal = find(strcmp('FORMAT_VERSION', varList(1:3:end)) == 1, 1);
      formatVersion = strtrim(varList{3*idVal-1}');
      if (strcmp(formatVersion, '3.1'))
         
         idVal = find(strcmp('DOXY', varList(1:3:end)) == 1, 1);
         paramVar = varList{3*idVal};
         if (~isempty(paramVar))
            
            attList = paramVar.Attributes;
            idF = find(strcmp({attList.Name}, 'valid_min') == 1, 1);
            if (~isempty(idF))
               if (attList(idF).Value ~= -5)
                  updateNeeded = 1;
               end
            end
         end
         if (updateNeeded == 0)
            idVal = find(strcmp('DOXY2', varList(1:3:end)) == 1, 1);
            paramVar = varList{3*idVal};
            if (~isempty(paramVar))
               
               attList = paramVar.Attributes;
               idF = find(strcmp({attList.Name}, 'valid_min') == 1, 1);
               if (~isempty(idF))
                  if (attList(idF).Value ~= -5)
                     updateNeeded = 1;
                  end
               end
            end
         end
         if (updateNeeded == 0)
            idVal = find(strcmp('C2PHASE_DOXY', varList(1:3:end)) == 1, 1);
            paramVar = varList{3*idVal};
            if (~isempty(paramVar))
               
               attList = paramVar.Attributes;
               idF = find(strcmp({attList.Name}, 'valid_min') == 1, 1);
               if (~isempty(idF))
                  if (attList(idF).Value ~= 0)
                     updateNeeded = 1;
                  end
               end
               idF = find(strcmp({attList.Name}, 'valid_max') == 1, 1);
               if (~isempty(idF))
                  if (attList(idF).Value ~= 15)
                     updateNeeded = 1;
                  end
               end
            end
         end
      end
   end
   
   % update the file
   if (updateNeeded == 1)
      
      fprintf('File to update: %s\n', a_ncPathFileName);
      
      % make a copy of the file in the temporary directory
      [~, fileName, fileExt] = fileparts(a_ncPathFileName);
      fileToUpdate = [a_tmpDir '/' fileName fileExt];
      [status] = copyfile(a_ncPathFileName, fileToUpdate);
      if (status == 1)
         
         % update the file
         ok = update_file(fileToUpdate);
         
         if (ok == 1)
            
            % move the updated file
            [status, message, messageid] = movefile(fileToUpdate, a_ncPathFileName);
            if (status ~= 1)
               fprintf('ERROR: cannot move file to update (%s) to replace input file (%s)\n', fileToUpdate, a_ncPathFileName);
               return;
            end
            
            % store the information for the XML report
            if (any(strfind(fileName, 'traj')))
               g_couf_reportData.trajFile = [g_couf_reportData.trajFile {a_ncPathFileName}];
            elseif (any(strfind(fileName, 'prof')))
               g_couf_reportData.mProfFile = [g_couf_reportData.mProfFile {a_ncPathFileName}];
            else
               g_couf_reportData.profFile = [g_couf_reportData.profFile {a_ncPathFileName}];
            end
            g_couf_reportData.float = [g_couf_reportData.float g_couf_floatNum];
            
         end
      else
         fprintf('ERROR: cannot copy file to update (%s) to temporary directory (%s)\n', a_ncPathFileName, a_tmpDir);
      end
   end
end

return;

% ------------------------------------------------------------------------------
% Update one NetCDF file.
%
% SYNTAX :
%  [o_ok] = update_file(a_ncPathFileName)
%
% INPUT PARAMETERS :
%   a_ncPathFileName : name of the file to update
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
%   12/15/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ok] = update_file(a_ncPathFileName)

% output parameters initialization
o_ok = 0;

% program version
global g_couf_ncUpdateArgoFormatVersion;


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'WRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
   end
   
   % update attribute value
   varName = 'DOXY';
   if (var_is_present_dec_argo(fCdf, varName))
      attName = 'valid_min';
      attValue = single(-5);
      netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, attValue);
   end
   
   varName = 'DOXY_ADJUSTED';
   if (var_is_present_dec_argo(fCdf, varName))
      attName = 'valid_min';
      attValue = single(-5);
      netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, attValue);
   end
   
   varName = 'DOXY2';
   if (var_is_present_dec_argo(fCdf, varName))
      attName = 'valid_min';
      attValue = single(-5);
      netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, attValue);
   end
   
   varName = 'DOXY2_ADJUSTED';
   if (var_is_present_dec_argo(fCdf, varName))
      attName = 'valid_min';
      attValue = single(-5);
      netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, attValue);
   end
   
   varName = 'C2PHASE_DOXY';
   if (var_is_present_dec_argo(fCdf, varName))
      attName = 'valid_min';
      attValue = single(0);
      netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, attValue);
      attName = 'valid_max';
      attValue = single(15);
      netcdf.putAtt(fCdf, netcdf.inqVarID(fCdf, varName), attName, attValue);
   end
   
   % add history information that concerns the current program
   historyInstitution = 'IF';
   historySoftware = 'COUF';
   historySoftwareRelease = g_couf_ncUpdateArgoFormatVersion;
   historyDate = datestr(now_utc, 'yyyymmddHHMMSS');
   
   [filePath, fileName, fileExt] = fileparts(a_ncPathFileName);
   % we only update HISTORY_* variables for:
   % - C and B mono-profile files (not M mono-profile files nor multi-profile files)
   % - C and B trajectory files (not M trajectory files)
   
   % mono-profile file names are: <M><B><R/D>WMO_CyNum<D>.nc
   % multi-profile file names are: WMO_<M><B><R/D>prof.nc
   % trajectory file names are: WMO_<M><B><R/D>traj.nc
   if (isempty(strfind(fileName, 'prof')) && ...
         isempty(strfind(fileName, 'traj')) && ...
         (fileName(1) ~= 'M'))
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % C and B mono-profile files
      
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
      
      % create the list of profiles concerned by HISTORY update
      varNameList = [ ...
         {'DOXY'} ...
         {'DOXY2'} ...
         {'C2PHASE_DOXY'} ...
         ];
      profList = [];
      stationParameters = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, 'STATION_PARAMETERS'));
      [~, nParam, nProf] = size(stationParameters);
      for idProf = 1:nProf
         for idParam = 1:nParam
            paramName = strtrim(stationParameters(:, idParam, idProf)');
            if (~isempty(find(strcmp(paramName, varNameList) == 1, 1)))
               profList = [profList idProf];
            end
         end
      end
      
      % update HISTORY information
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
      
   elseif (~isempty(strfind(fileName, 'traj')) && isempty(strfind(fileName, 'M')))
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % C and B trajectory files
      
      % retrieve N_HISTORY dim value
      [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
      
      netcdf.close(fCdf);
      
      % rename updated file
      tmpPathFileName = [filePath '/' fileName '_tmp' fileExt];
      [status, message, messageid] = movefile(a_ncPathFileName, tmpPathFileName);
      if (status ~= 1)
         fprintf('ERROR: cannot move file (%s) to (%s)\n', a_ncPathFileName, tmpPathFileName);
         return;
      end
      
      % retrieve file schema from updated file
      outputFileSchema = ncinfo(tmpPathFileName);
      
      % update output file schema with the correct N_HISTORY dimension
      [outputFileSchema] = update_dim_in_nc_schema(outputFileSchema, ...
         'N_HISTORY', nHistory+1);
      
      % create output files
      ncwriteschema(a_ncPathFileName, outputFileSchema);
      
      for idVar = 1:length(outputFileSchema.Variables)
         varData = ncread(tmpPathFileName, outputFileSchema.Variables(idVar).Name);
         if (~isempty(varData))
            ncwrite(a_ncPathFileName, outputFileSchema.Variables(idVar).Name, varData);
         end
      end
      
      % open NetCDF file
      fCdf = netcdf.open(a_ncPathFileName, 'WRITE');
      if (isempty(fCdf))
         fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
         return;
      end
      
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
      [~, nHistory] = netcdf.inqDim(fCdf, netcdf.inqDimID(fCdf, 'N_HISTORY'));
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_INSTITUTION'), ...
         fliplr([nHistory-1 0]), fliplr([1 length(historyInstitution)]), historyInstitution');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE'), ...
         fliplr([nHistory-1 0]), fliplr([1 length(historySoftware)]), historySoftware');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_SOFTWARE_RELEASE'), ...
         fliplr([nHistory-1 0]), fliplr([1 length(historySoftwareRelease)]), historySoftwareRelease');
      netcdf.putVar(fCdf, netcdf.inqVarID(fCdf, 'HISTORY_DATE'), ...
         fliplr([nHistory-1 0]), fliplr([1 length(historyDate)]), historyDate');
      
      netcdf.close(fCdf);
   else
      
      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % other files (no need to update HISTORY_* variables)
      
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
      
      netcdf.close(fCdf);
   end
   
   o_ok = 1;
end

return;

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
%   12/15/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_ncVarList] = get_var_from_nc_file(a_ncPathFileName, a_wantedVars)

% output parameters initialization
o_ncVarList = [];


if (exist(a_ncPathFileName, 'file') == 2)
   
   % open NetCDF file
   fCdf = netcdf.open(a_ncPathFileName, 'NC_NOWRITE');
   if (isempty(fCdf))
      fprintf('ERROR: Unable to open NetCDF input file: %s\n', a_ncPathFileName);
      return;
   end
   
   % retrieve variables from NetCDF file
   for idVar = 1:length(a_wantedVars)
      varName = a_wantedVars{idVar};
      
      if (var_is_present_dec_argo(fCdf, varName))
         varValue = netcdf.getVar(fCdf, netcdf.inqVarID(fCdf, varName));
         varInfo = ncinfo(a_ncPathFileName, varName);
         o_ncVarList = [o_ncVarList {varName} {varValue} {varInfo}];
      else
         o_ncVarList = [o_ncVarList {varName} {[]} {[]}];
      end
      
   end
   
   netcdf.close(fCdf);
end

return;

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
%   12/15/2015 - RNU - creation
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
newChild.appendChild(docNode.createTextNode('Argo Coriolis update format tool (nc_update_argo_format_set_param_attribute_01aa)'));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('tool_version');
newChild.appendChild(docNode.createTextNode(g_couf_ncUpdateArgoFormatVersion));
docRootNode.appendChild(newChild);

newChild = docNode.createElement('date');
newChild.appendChild(docNode.createTextNode(datestr(datenum(a_time, 'yyyymmddTHHMMSSZ'), 'dd/mm/yyyy HH:MM:SS')));
docRootNode.appendChild(newChild);

g_couf_xmlReportDOMNode = docNode;

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
%   12/15/2015 - RNU - creation
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
%   05/12/2013 - RNU - creation
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

return;
