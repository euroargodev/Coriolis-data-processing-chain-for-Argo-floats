% ------------------------------------------------------------------------------
% Read Apex APF11 Iridium binary log file ('science' or 'vitals').
%
% SYNTAX :
%  [o_error, o_data] = read_apx_apf11_ir_binary_log_file(a_logFileName, a_logFileType)
%
% INPUT PARAMETERS :
%   a_logFileName : binary log file name
%   a_logFileType : log file type ('science' or 'vitals')
%
% OUTPUT PARAMETERS :
%   o_error : error flag
%   o_data  : output data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_error, o_data] = read_apx_apf11_ir_binary_log_file(a_logFileName, a_logFileType)

% output parameters initialization
o_error = 0;
o_data = [];

% default values
global g_decArgo_janFirst1970InJulD;
global g_decArgo_janFirst1950InMatlab;

% float launch date
global g_decArgo_floatLaunchDate;

% when used by check_apex_apf11_ir_float_files
DEBUG_FLAG = 0;


% for decoding comparison purposes (check_apex_apf11_ir_float_files)
if (DEBUG_FLAG == 1)
   
   sep = ';'; % use ',' for comparison
   
   % output CSv path file name (set in check_apex_apf11_ir_float_files)
   global g_decArgo_debug_outputCsvPathName;
   
   [~, logFileName, ~] = fileparts(a_logFileName);
   outputCsvFilePathName = [g_decArgo_debug_outputCsvPathName [logFileName '.csv']];
   outputCsvFileId = fopen(outputCsvFilePathName, 'wt');
   if (outputCsvFileId == -1)
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputCsvFilePathName);
      return;
   end
end

% check that file exists
if ~(exist(a_logFileName, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_logFileName);
   o_error = 1;
   return;
end

% open the file and read the data
fId = fopen(a_logFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_logFileName);
   o_error = 1;
   return;
end
sbdData = fread(fId);
fclose(fId);

% initialize the output data structure
o_data = get_binary_log_data_init_struct(a_logFileType);

% decode the binary data
recCurPos = 1;
while (1)
   
   if (recCurPos > length(sbdData))
      break;
   end
   
   recLength = sbdData(recCurPos);
   recId = sbdData(recCurPos+1);
   decStruct = get_decoding_info(a_logFileType, recId);
   if (~isempty(decStruct))
      % timestamp
      dataTime = flipud(sbdData(recCurPos+2:recCurPos+5));
      timeStampRaw = get_bits(1, 32, dataTime);
      timeStamp = g_decArgo_janFirst1970InJulD + timeStampRaw/86400;
      
      if (~isempty(g_decArgo_floatLaunchDate) && (timeStamp < g_decArgo_floatLaunchDate))
         recCurPos = recCurPos + recLength + 1;
         continue;
      end
      
      % data
      data = sbdData(recCurPos+6:recCurPos+recLength);
      if (recId == 0)
         decData = get_bits(1, ones(1, length(data))*8, data);
         o_data.(decStruct.recType) = [o_data.(decStruct.recType); ...
            [timeStamp {char(decData')}]];
         
         % for decoding comparison purposes (check_apex_apf11_ir_float_files)
         if (DEBUG_FLAG == 1)
            fprintf(outputCsvFileId, '%s%c%s%c%s\n', ...
               decStruct(1).recType, sep, ...
               datestr(timeStamp+g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS'), sep, ...
               char(decData'));
         end
         
      else
         % check decoding information VS data length consistency
         if (5+sum([decStruct.tabBytes]) ~= recLength)
            fprintf('ERROR: science_log file reader: recId #%d inconsistency in decoding information => data ignored\n', recId);
            continue;
         end
         dataVal = nan(1, length(decStruct)+1);
         dataVal(1) = timeStamp;
         dataCurPos = 1;
         for id = 1:length(decStruct)
            dataCur = flipud(data(dataCurPos:dataCurPos+decStruct(id).tabBytes-1)); % get bytes
            decData = get_bits(1, decStruct(id).tabBytes*8, dataCur); % decode data
            decData = typecast(decStruct(id).tabFunc(decData), decStruct(id).outputType); % convert to approriate type
            dataVal(id+1) = str2double(sprintf(decStruct(id).outputFormat, decData)); % format to given resolution
            dataCurPos = dataCurPos + decStruct(id).tabBytes;
         end
         o_data.(decStruct(1).recType) = [o_data.(decStruct(1).recType); ...
            dataVal];
         
         % for decoding comparison purposes (check_apex_apf11_ir_float_files)
         if (DEBUG_FLAG == 1)
            format = ['%s' sep '%s'];
            for id = 1:length(decStruct)
               format = [format sep decStruct(id).outputFormat];
            end
            fprintf(outputCsvFileId, [format '\n'], ...
               decStruct(1).recType, ...
               datestr(dataVal(1)+g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS'), ...
               dataVal(2:end));
         end
         
      end
      if (~isfield(o_data, [decStruct(1).recType '_labels']))
         o_data.([decStruct(1).recType '_labels']) = get_binary_log_data_labels(decStruct(1).recType);
      end
   else
      fprintf('ERROR: %s file reader: recId #%d not managed yet => data ignored (ASK FOR AN UPDATE OF THE DECODER)\n', a_logFileType, recId);
   end
   
   recCurPos = recCurPos + recLength + 1;
end

% for decoding comparison purposes (check_apex_apf11_ir_float_files)
if (DEBUG_FLAG == 1)
   fclose(outputCsvFileId);
end
         
return;

% ------------------------------------------------------------------------------
% Get the decoding information for a given record Id.
%
% SYNTAX :
%  [o_decStruct] = get_decoding_info(a_logFileType, a_recordId)
%
% INPUT PARAMETERS :
%   a_logFileType : log file type ('science' or 'vitals')
%   a_recordId    : record Id
%
% OUTPUT PARAMETERS :
%   o_decStruct : decoding information
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decStruct] = get_decoding_info(a_logFileType, a_recordId)

% output parameters initialization
o_decStruct = [];

switch (a_logFileType)
   
   case 'science'
      switch (a_recordId)
         case 0
            o_decStruct = struct( ...
               'recType', 'Message', ...
               'outputFormat', [{'%s'}] ...
               );
         case 1
            o_decStruct = struct( ...
               'recType', 'GPS', ...
               'tabBytes', [{4} {4} {4}], ...
               'tabFunc', {@uint32, @uint32, @uint32}, ...
               'outputType', [{'single'} {'single'} {'uint32'}], ...
               'outputFormat', [{'%.6f'} {'%.6f'} {'%d'}] ...
               );
         case 10
            o_decStruct = struct( ...
               'recType', 'CTD_bins', ...
               'tabBytes', [{4} {2} {4}], ...
               'tabFunc', {@uint32, @uint16, @uint32}, ...
               'outputType', [{'uint32'} {'uint16'} {'single'}], ...
               'outputFormat', [{'%d'} {'%d'} {'%.3f'}] ...
               );
         case 11
            o_decStruct = struct( ...
               'recType', 'CTD_P', ...
               'tabBytes', [{4}], ...
               'tabFunc', {@uint32}, ...
               'outputType', [{'single'}], ...
               'outputFormat', [{'%.2f'}] ...
               );
         case 12
            o_decStruct = struct( ...
               'recType', 'CTD_PT', ...
               'tabBytes', [{4} {4}], ...
               'tabFunc', {@uint32, @uint32}, ...
               'outputType', [{'single'} {'single'}], ...
               'outputFormat', [{'%.2f'} {'%.4f'}] ...
               );
         case 13
            o_decStruct = struct( ...
               'recType', 'CTD_PTS', ...
               'tabBytes', [{4} {4} {4}], ...
               'tabFunc', {@uint32, @uint32, @uint32}, ...
               'outputType', [{'single'} {'single'} {'single'}], ...
               'outputFormat', [{'%.2f'} {'%.4f'} {'%.4f'}] ...
               );
         case 14
            o_decStruct = struct( ...
               'recType', 'CTD_CP', ...
               'tabBytes', [{4} {4} {4} {2}], ...
               'tabFunc', {@uint32, @uint32, @uint32, @uint16}, ...
               'outputType', [{'single'} {'single'} {'single'} {'uint16'}], ...
               'outputFormat', [{'%.2f'} {'%.4f'} {'%.4f'} {'%d'}] ...
               );
      end
      
   case 'vitals'
      switch (a_recordId)
         case 0
            o_decStruct = struct( ...
               'recType', 'Message' ...
               );
         case 1
            o_decStruct = struct( ...
               'recType', 'VITALS_CORE', ...
               'tabBytes', [{4} {2} {4} {2} {4} {4} {4} {2} {4} {4} {2}], ...
               'tabFunc', {@uint32 @uint16 @uint32 @uint16 @uint32 @uint32 @uint32 @uint16 @uint32 @uint32 @uint16}, ...
               'outputType', [{'single'} {'uint16'} {'single'} {'uint16'} {'single'} {'single'} {'single'} {'uint16'} {'single'} {'single'} {'int16'}], ...
               'outputFormat', [{'%.3f'} {'%d'} {'%.3f'} {'%d'} {'%.3f'} {'%.3f'} {'%.3f'} {'%d'} {'%.3f'} {'%.3f'} {'%d'}] ...
               );
         case 3
            o_decStruct = struct( ...
               'recType', 'WD_CNT', ...
               'tabBytes', [{4}], ...
               'tabFunc', {@uint32}, ...
               'outputType', [{'uint32'}], ...
               'outputFormat', [{'%d'}] ...
               );
      end
end

return;

% ------------------------------------------------------------------------------
% Get the basic structure to store binary log file data.
%
% SYNTAX :
%  [o_binLogDataStruct] = get_binary_log_data_init_struct(a_logFileType)
%
% INPUT PARAMETERS :
%   a_logFileType : log file type ('science' or 'vitals')
%
% OUTPUT PARAMETERS :
%   o_binLogDataStruct : binary log file data structure
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_binLogDataStruct] = get_binary_log_data_init_struct(a_logFileType)

% output parameters initialization
o_binLogDataStruct = [];

switch (a_logFileType)
   
   case 'science'
      o_binLogDataStruct = struct( ...
         'Message', [], ...
         'GPS', [], ...
         'CTD_bins', [], ...
         'CTD_P', [], ...
         'CTD_PT', [], ...
         'CTD_PTS', [], ...
         'CTD_CP', [] ...
         );
      
   case 'vitals'
      o_binLogDataStruct = struct( ...
         'Message', [], ...
         'VITALS_CORE', [], ...
         'WD_CNT', [] ...
         );
end

return;

% ------------------------------------------------------------------------------
% Get the decoded data labels list associated to a given record type.
%
% SYNTAX :
% function [o_recLabels] = get_binary_log_data_labels(a_recType)
%
% INPUT PARAMETERS :
%   a_recType : record type
%
% OUTPUT PARAMETERS :
%   o_recLabels : associated labels list
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/13/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_recLabels] = get_binary_log_data_labels(a_recType)

% output parameters initialization
o_recLabels = [];

switch (a_recType)
   case 'Message'
      o_recLabels = [{'timestamp'} {'message_contents'}];
      
   case 'GPS'
      o_recLabels = [{'timestamp'} {'LATITUDE'} {'LONGITUDE'} {'nb_sat'}];
   case 'CTD_bins'
      o_recLabels = [{'timestamp'} {'nb_sample'} {'nb_bin'} {'max_pres'}];
   case 'CTD_P'
      o_recLabels = [{'timestamp'} {'PRES'}];
   case 'CTD_PT'
      o_recLabels = [{'timestamp'} {'PRES'} {'TEMP'}];
   case 'CTD_PTS'
      o_recLabels = [{'timestamp'} {'PRES'} {'TEMP'} {'PSAL'}];
   case 'CTD_CP'
      o_recLabels = [{'timestamp'} {'PRES'} {'TEMP'} {'PSAL'} {'nb_sample'}];
      
   case 'VITALS_CORE'
      o_recLabels = [{'timestamp'} {'air_bladder(dbar)'} {'air_bladder(count)'} ...
         {'battery_voltage(V)'} {'battery_voltage(count)'} {'humidity'} ...
         {'leak_detect(V)'} {'vacuum(dbar)'} {'vacuum(count)'} ...
         {'coulomb(AHrs)'} {'battery_current(mA)'} {'battery_current_raw'}];
   case 'WD_CNT'
      o_recLabels = [{'timestamp'} {'Events(count)'}];
      
   otherwise
      fprintf('WARNING: binary log file reader: no label defined yet for recType ''%s''\n', a_recType);
end

return;
