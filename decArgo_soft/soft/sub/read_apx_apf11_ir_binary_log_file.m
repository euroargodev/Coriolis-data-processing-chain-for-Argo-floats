% ------------------------------------------------------------------------------
% Read Apex APF11 Iridium binary log file ('science' or 'vitals').
%
% SYNTAX :
%  [o_error, o_data] = read_apx_apf11_ir_binary_log_file( ...
%    a_logFileName, a_logFileType, a_fromLaunchFlag, a_outputCsvFlag, a_decoderId)
%
% INPUT PARAMETERS :
%   a_logFileName    : binary log file name
%   a_logFileType    : log file type ('science' or 'vitals')
%   a_fromLaunchFlag : consider events from float launch date
%   a_outputCsvFlag  : 1 to write data in a CSV file, 0 otherwise
%   a_decoderId      : float decoder Id
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
function [o_error, o_data] = read_apx_apf11_ir_binary_log_file( ...
   a_logFileName, a_logFileType, a_fromLaunchFlag, a_outputCsvFlag, a_decoderId)

% output parameters initialization
o_error = 0;
o_data = [];

% default values
global g_decArgo_janFirst1970InJulD;
global g_decArgo_janFirst1950InMatlab;

% float launch date
global g_decArgo_floatLaunchDate;


% for decoding comparison purposes (check_apex_apf11_ir_float_files)
if (a_outputCsvFlag == 1)
   
   sep = ';'; % use ',' for comparison
   %    sep = ','; % use ',' for comparison
   
   % output CSV dir name (used in read_apx_apf11_ir_binary_log_file)
   global g_decArgo_debug_outputCsvDirName;
   
   [~, logFileName, ~] = fileparts(a_logFileName);
   outputCsvFilePathName = [g_decArgo_debug_outputCsvDirName [logFileName '.csv']];
   outputCsvFileId = fopen(outputCsvFilePathName, 'wt');
   if (outputCsvFileId == -1)
      fprintf('ERROR: Unable to create CSV output file: %s\n', outputCsvFilePathName);
      return
   end
end

% check that file exists
if ~(exist(a_logFileName, 'file') == 2)
   fprintf('ERROR: File not found: %s\n', a_logFileName);
   o_error = 1;
   return
end

% open the file and read the data
fId = fopen(a_logFileName, 'r');
if (fId == -1)
   fprintf('ERROR: Unable to open file: %s\n', a_logFileName);
   o_error = 1;
   return
end
sbdData = fread(fId);
fclose(fId);

% initialize the output data structure
o_data = get_binary_log_data_init_struct(a_logFileType);

% decode the binary data
if (~strcmp(a_logFileType, 'irad'))
   
   % for science_log and vitals_log files
   recCurPos = 1;
   cpt = 1;
   while (1)
      
      if (recCurPos > length(sbdData))
         break
      end
      
      recLength = sbdData(recCurPos);
      recId = sbdData(recCurPos+1);
      decStruct = get_decoding_info(a_logFileType, recId, a_decoderId);
      if (~isempty(decStruct))
         % timestamp
         dataTime = flipud(sbdData(recCurPos+2:recCurPos+5));
         timeStampRaw = get_bits(1, 32, dataTime);
         if (timeStampRaw == 0)
            timeStampRaw = nan;
         end
         timeStamp = g_decArgo_janFirst1970InJulD + timeStampRaw/86400;
         
         if (a_fromLaunchFlag)
            if (~isempty(g_decArgo_floatLaunchDate) && (timeStamp < g_decArgo_floatLaunchDate))
               recCurPos = recCurPos + recLength + 1;
               continue
            end
         end
         
         % data
         data = sbdData(recCurPos+6:recCurPos+recLength);
         if (recId == 0)
            decData = get_bits(1, ones(1, length(data))*8, data);
            o_data.(decStruct.recType) = [o_data.(decStruct.recType); ...
               [timeStamp {char(decData')}]];
            
            % for decoding comparison purposes (check_apex_apf11_ir_float_files)
            if (a_outputCsvFlag == 1)
               fprintf(outputCsvFileId, '%s%c%s%c%s\n', ...
                  decStruct(1).recType, sep, ...
                  datestr(timeStamp+g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS'), sep, ...
                  char(decData'));
            end
            
         else
            
            % check decoding information VS data length consistency
            if (5+sum([decStruct.tabBytes]) ~= recLength)
               fprintf('ERROR: science_log file reader: recId #%d inconsistency in decoding information - data ignored\n', recId);
               continue
            end
            dataVal = nan(1, length(decStruct)+2);
            dataVal(1) = cpt;
            cpt = cpt + 1;
            dataVal(2) = timeStamp;
            dataCurPos = 1;
            for id = 1:length(decStruct)
               dataCur = flipud(data(dataCurPos:dataCurPos+decStruct(id).tabBytes-1)); % get bytes
               decData = get_bits(1, decStruct(id).tabBytes*8, dataCur); % decode data
               decData = typecast(decStruct(id).tabFunc(decData), decStruct(id).outputType); % convert to approriate type
               dataVal(id+2) = str2double(sprintf(decStruct(id).outputFormat, decData)); % format to given resolution
               dataCurPos = dataCurPos + decStruct(id).tabBytes;
            end
            o_data.(decStruct(1).recType) = [o_data.(decStruct(1).recType); ...
               dataVal];
            
            % for decoding comparison purposes (check_apex_apf11_ir_float_files)
            if (a_outputCsvFlag == 1)
               format = ['%s' sep '%s'];
               for id = 1:length(decStruct)
                  format = [format sep decStruct(id).outputFormat];
               end
               if (~isnan(dataVal(2)))
                  fprintf(outputCsvFileId, [format '\n'], ...
                     decStruct(1).recType, ...
                     datestr(dataVal(2)+g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS'), ...
                     dataVal(3:end));
               else
                  fprintf(outputCsvFileId, [format '\n'], ...
                     decStruct(1).recType, ...
                     '99999999T999999', ...
                     dataVal(3:end));
               end
            end
            
         end
         if (~isfield(o_data, [decStruct(1).recType '_labels']))
            o_data.([decStruct(1).recType '_labels']) = get_binary_log_data_labels(decStruct(1).recType, a_decoderId);
         end
      else
         fprintf('ERROR: %s file reader: recId #%d not managed yet - data ignored (ASK FOR AN UPDATE OF THE DECODER)\n', a_logFileType, recId);
      end
      
      recCurPos = recCurPos + recLength + 1;
   end
else
   
   % for irad_log file
   
   decStruct = get_decoding_info(a_logFileType, '', a_decoderId);
   
   if (~isempty(decStruct))
      
      % 4 bytes (timestamp) + 255 x 2 bytes (data) = 514 bytes per meas
      % check expected information VS data length consistency
      if (mod(length(sbdData), sum([decStruct.tabBytes])+4) ~= 0)
         fprintf('ERROR: irad_log file reader: inconsistency in decoding information - data ignored\n');
         o_error = 1;
         return
      end
      
      nbLines = length(sbdData)/(sum([decStruct.tabBytes])+4);
      dataVal = nan(nbLines, length(decStruct)+1);
      recCurPos = 1;
      for idL = 1:nbLines
         
         % timestamp
         dataTime = flipud(sbdData(recCurPos:recCurPos+3));
         timeStampRaw = get_bits(1, 32, dataTime);
         if (timeStampRaw == 0)
            timeStampRaw = nan;
         end
         timeStamp = g_decArgo_janFirst1970InJulD + timeStampRaw/86400;
         
         if (a_fromLaunchFlag)
            if (~isempty(g_decArgo_floatLaunchDate) && (timeStamp < g_decArgo_floatLaunchDate))
               recCurPos = recCurPos + sum([decStruct.tabBytes]) + 4 + 1;
               continue
            end
         end
         
         % data
         dataVal(idL, 1) = timeStamp;
         dataCurPos = recCurPos + 4;
         for id = 1:length(decStruct)
            dataCur = flipud(sbdData(dataCurPos:dataCurPos+decStruct(id).tabBytes-1)); % get bytes
            decData = get_bits(1, decStruct(id).tabBytes*8, dataCur); % decode data
            decData = typecast(decStruct(id).tabFunc(decData), decStruct(id).outputType); % convert to approriate type
            dataVal(idL, id+1) = str2double(sprintf(decStruct(id).outputFormat, decData)); % format to given resolution
            dataCurPos = dataCurPos + decStruct(id).tabBytes;
         end
         
         recCurPos = dataCurPos;
      end
      
      o_data.(decStruct(1).recType) = dataVal;
      
      % for decoding comparison purposes (check_apex_apf11_ir_float_files)
      if (a_outputCsvFlag == 1)
         format = ['%s' sep '%s'];
         for id = 1:length(decStruct)
            format = [format sep decStruct(id).outputFormat];
         end
         for idL = 1:nbLines
            if (~isnan(dataVal(idL, 1)))
               fprintf(outputCsvFileId, [format '\n'], ...
                  decStruct(1).recType, ...
                  datestr(dataVal(idL, 1)+g_decArgo_janFirst1950InMatlab, 'yyyymmddTHHMMSS'), ...
                  dataVal(idL, 2:end));
            else
               fprintf(outputCsvFileId, [format '\n'], ...
                  decStruct(1).recType, ...
                  '99999999T999999', ...
                  dataVal(idL, 2:end));
            end
         end
      end
   else
      fprintf('ERROR: %s file reader: format not managed yet - data ignored (ASK FOR AN UPDATE OF THE DECODER)\n', a_logFileType);
   end
end

% for decoding comparison purposes (check_apex_apf11_ir_float_files)
if (a_outputCsvFlag == 1)
   fclose(outputCsvFileId);
end
         
return

% ------------------------------------------------------------------------------
% Get the decoding information for a given record Id.
%
% SYNTAX :
%  [o_decStruct] = get_decoding_info(a_logFileType, a_recordId)
%
% INPUT PARAMETERS :
%   a_logFileType : log file type ('science' or 'vitals')
%   a_recordId    : record Id
%   a_decoderId   : float decoder Id
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
function [o_decStruct] = get_decoding_info(a_logFileType, a_recordId, a_decoderId)

% output parameters initialization
o_decStruct = [];

% current float WMO number
global g_decArgo_floatNum;


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
         case 15
            o_decStruct = struct( ...
               'recType', 'CTD_PTSH', ...
               'tabBytes', [{4} {4} {4} {4}], ...
               'tabFunc', {@uint32, @uint32, @uint32, @uint32}, ...
               'outputType', [{'single'} {'single'} {'single'} {'single'}], ...
               'outputFormat', [{'%.2f'} {'%.4f'} {'%.4f'} {'%.6f'}] ...
               );
         case 16
            o_decStruct = struct( ...
               'recType', 'CTD_CP_H', ...
               'tabBytes', [{4} {4} {4} {2} {4} {2}], ...
               'tabFunc', {@uint32, @uint32, @uint32, @uint16, @uint32, @uint16}, ...
               'outputType', [{'single'} {'single'} {'single'} {'uint16'} {'single'} {'uint16'}], ...
               'outputFormat', [{'%.2f'} {'%.4f'} {'%.4f'} {'%d'} {'%.6f'} {'%d'}] ...
               );
         case 40
            o_decStruct = struct( ...
               'recType', 'O2', ...
               'tabBytes', [{4} {4} {4} {4} {4} {4} {4} {4} {4} {4}], ...
               'tabFunc', {@uint32, @uint32, @uint32, @uint32, @uint32, @uint32, @uint32, @uint32, @uint32, @uint32}, ...
               'outputType', [{'single'} {'single'} {'single'} {'single'} {'single'} {'single'} {'single'} {'single'} {'single'} {'single'}], ...
               'outputFormat', [{'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'}] ...
               );
         case 51
            if (~ismember(a_decoderId, [1121, 1122, 1123, 1124, 1126, 1127, 1321, 1322, 1323])) % the decoding template differs for decoders before 2.15.0

               if (g_decArgo_floatNum ~= 6903552)
                  
                  fprintf('ERROR: %s file reader: decId %d: new version of recId #%d implemented but not checked - data used but ASK FOR A CHECK OF THE IMPLEMENTATION\n', a_logFileType, a_decoderId, a_recordId);
                  
                  % nominal case
                  
                  % # LOG_SCIENCE_FLBB_BB
                  % science.add_record_with_id(51, 'FLBB_BB', 'Thhhh', ('timestamp', 'chl_sig', 'bsc_sig0', 'bsc_sig1','therm_sig'))
                  
                  o_decStruct = struct( ...
                     'recType', 'FLBB_BB', ...
                     'tabBytes', [{2} {2} {2} {2}], ...
                     'tabFunc', {@uint16, @uint16, @uint16, @uint16}, ...
                     'outputType', [{'uint16'} {'uint16'} {'uint16'} {'uint16'}], ...
                     'outputFormat', [{'%d'} {'%d'} {'%d'} {'%d'}] ...
                     );
               else
                  
                  % specific
                  
                  % for float 6903552 FLBB_CD is transmitted as FLBB_BB
                  
                  o_decStruct = struct( ...
                     'recType', 'FLBB_CD', ...
                     'tabBytes', [{2} {2} {2} {2}], ...
                     'tabFunc', {@uint16, @uint16, @uint16, @uint16}, ...
                     'outputType', [{'uint16'} {'uint16'} {'uint16'} {'uint16'}], ...
                     'outputFormat', [{'%d'} {'%d'} {'%d'} {'%d'}] ...
                     );
               end
            end
         case 52
            if (ismember(a_decoderId, [1121, 1122, 1123, 1124, 1126, 1127, 1321, 1322, 1323]))
               
               % # LOG_SCIENCE_FLBB_CD
               % science.addtype(52, 'FLBB_CD', 'Thhhhhhh', ('timestamp', 'chl_wave', 'chl_sig', 'bsc_wave', 'bcs_sig', 'cd_wave', 'cd_sig', 'therm_sig'))
               
               o_decStruct = struct( ...
                  'recType', 'FLBB_CD', ...
                  'tabBytes', [{2} {2} {2} {2} {2} {2} {2}], ...
                  'tabFunc', {@uint16, @uint16, @uint16, @uint16, @uint16, @uint16, @uint16}, ...
                  'outputType', [{'uint16'} {'uint16'} {'uint16'} {'uint16'} {'uint16'} {'uint16'} {'uint16'}], ...
                  'outputFormat', [{'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'}] ...
                  );
            else
               
               fprintf('ERROR: %s file reader: decId %d: new version of recId #%d implemented but not checked - data used but ASK FOR A CHECK OF THE IMPLEMENTATION\n', a_logFileType, a_decoderId, a_recordId);

               % since 2.15.0
               % # LOG_SCIENCE_FLBB_CD
               % science.add_record_with_id(52, 'FLBB_CD', 'Thhhh', ('timestamp', 'chl_sig', 'bcs_sig', 'cd_sig', 'therm_sig'))
               
               o_decStruct = struct( ...
                  'recType', 'FLBB_CD', ...
                  'tabBytes', [{2} {2} {2} {2}], ...
                  'tabFunc', {@uint16, @uint16, @uint16, @uint16}, ...
                  'outputType', [{'uint16'} {'uint16'} {'uint16'} {'uint16'}], ...
                  'outputFormat', [{'%d'} {'%d'} {'%d'} {'%d'}] ...
                  );
            end
         case 54
            if (~ismember(a_decoderId, [1121, 1122, 1123, 1124, 1126, 1127, 1321, 1322, 1323])) % the decoding template differs for decoders before 2.15.0

               if (g_decArgo_floatNum ~= 6903552)
                  
                  fprintf('ERROR: %s file reader: decId %d: new version of recId #%d implemented but not checked - data used but ASK FOR A CHECK OF THE IMPLEMENTATION\n', a_logFileType, a_decoderId, a_recordId);
                  
                  % nominal case
                  
                  % # LOG_SCIENCE_FLBB_BB_CFG
                  % science.add_record_with_id(54, 'FLBB_BB_CFG', 'Thhh', ('timestamp', 'chl_wave', 'bsc_wave0', 'bsc_wave1'))
                  
                  o_decStruct = struct( ...
                     'recType', 'FLBB_BB_CFG', ...
                     'tabBytes', [{2} {2} {2}], ...
                     'tabFunc', {@uint16, @uint16, @uint16}, ...
                     'outputType', [{'uint16'} {'uint16'} {'uint16'}], ...
                     'outputFormat', [{'%d'} {'%d'} {'%d'}] ...
                     );
               else
                  
                  % specific
                  
                  % for float 6903552 FLBB_CD_CFG is transmitted as FLBB_BB_CFG
                  
                  o_decStruct = struct( ...
                     'recType', 'FLBB_CD_CFG', ...
                     'tabBytes', [{2} {2} {2}], ...
                     'tabFunc', {@uint16, @uint16, @uint16}, ...
                     'outputType', [{'uint16'} {'uint16'} {'uint16'}], ...
                     'outputFormat', [{'%d'} {'%d'} {'%d'}] ...
                     );
               end
            end            
         case 61
            o_decStruct = struct( ...
               'recType', 'OCR_504I', ...
               'tabBytes', [{4} {4} {4} {4}], ...
               'tabFunc', {@uint32, @uint32, @uint32, @uint32}, ...
               'outputType', [{'single'} {'single'} {'single'} {'single'}], ...
               'outputFormat', [{'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'}] ...
               );
         case 110
            o_decStruct = struct( ...
               'recType', 'RAFOS_RTC', ...
               'tabBytes', [{4}], ...
               'tabFunc', {@uint32}, ...
               'outputType', [{'uint32'}], ...
               'outputFormat', [{'%d'}] ...
               );
         case 115
            o_decStruct = struct( ...
               'recType', 'RAFOS', ...
               'tabBytes', [{1} {2} {1} {2} {1} {2} {1} {2} {1} {2} {1} {2}], ...
               'tabFunc', {@uint8, @uint16, @uint8, @uint16, @uint8, @uint16, @uint8, @uint16, @uint8, @uint16, @uint8, @uint16}, ...
               'outputType', [{'uint8'} {'uint16'} {'uint8'} {'uint16'} {'uint8'} {'uint16'} {'uint8'} {'uint16'} {'uint8'} {'uint16'} {'uint8'} {'uint16'}], ...
               'outputFormat', [{'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'} {'%d'}] ...
               );
         case 125
            o_decStruct = struct( ...
               'recType', 'IRAD', ...
               'tabBytes', [{2} {4} {4} {4} {4}], ...
               'tabFunc', {@uint16, @uint32, @uint32, @uint32, @uint32}, ...
               'outputType', [{'uint16'} {'single'} {'single'} {'single'} {'single'}], ...
               'outputFormat', [{'%d'} {'%.5f'} {'%.5f'} {'%.5f'} {'%.5f'}] ...
               );
      end
      
   case 'irad'
      tabFunc = repmat({'uint16'}, 1, 255);
      tabFunc = cellfun(@(x) str2func(x), tabFunc, 'UniformOutput', 0);
      o_decStruct = struct( ...
         'recType', 'IRAD_SPECTRUM', ...
         'tabBytes', repmat({2}, 1, 255), ...
         'tabFunc', tabFunc, ...
         'outputType', repmat({'uint16'}, 1, 255), ...
         'outputFormat', repmat({'%d'}, 1, 255) ...
         );

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

return

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
         'CTD_PTSH', [], ...
         'CTD_CP', [], ...
         'CTD_CP_H', [], ...
         'O2', [], ...
         'FLBB_CD', [], ...
         'FLBB_CD_CFG', [], ...
         'OCR_504I', [], ...
         'RAFOS_RTC', [], ...
         'RAFOS', [], ...
         'IRAD', [] ...
         );
      
   case 'irad'
      o_binLogDataStruct = struct( ...
         'IRAD_SPECTRUM', [] ...
         );

   case 'vitals'
      o_binLogDataStruct = struct( ...
         'Message', [], ...
         'VITALS_CORE', [], ...
         'WD_CNT', [] ...
         );
end

return

% ------------------------------------------------------------------------------
% Get the decoded data labels list associated to a given record type.
%
% SYNTAX :
% function [o_recLabels] = get_binary_log_data_labels(a_recType, a_decoderId)
%
% INPUT PARAMETERS :
%   a_recType   : record type
%   a_decoderId : float decoder Id
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
function [o_recLabels] = get_binary_log_data_labels(a_recType, a_decoderId)

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
   case 'CTD_PTSH'
      o_recLabels = [{'timestamp'} {'PRES'} {'TEMP'} {'PSAL'} {'VRS_PH'}];
   case 'CTD_CP'
      o_recLabels = [{'timestamp'} {'PRES'} {'TEMP'} {'PSAL'} {'nb_sample'}];
   case 'CTD_CP_H'
      o_recLabels = [{'timestamp'} {'PRES'} {'TEMP'} {'PSAL'} {'nb_sample'} {'VRS_PH'} {'nb_sample'}];
   case 'O2'
      o_recLabels = [{'timestamp'} {'O2'} {'AirSat'} {'Temp'} {'CalPhase'} {'TCPhase'} {'C1RPh'} {'C2RPh'} {'C1Amp'} {'C2Amp'} {'RawTemp'}];
   case 'FLBB_CD'
      if (ismember(a_decoderId, [1121, 1122, 1123, 1124, 1126, 1127, 1321, 1322, 1323])) % the decoding template differs for decoders before 2.15.0
         o_recLabels = [{'timestamp'} {'chl_wave'} {'chl_sig'} {'bsc_wave'} {'bcs_sig'} {'cd_wave'} {'cd_sig'} {'therm_sig'}];
      else
         o_recLabels = [{'timestamp'} {'chl_sig'} {'bcs_sig'} {'cd_sig'} {'therm_sig'}];
      end
   case 'FLBB_CD_CFG'
      o_recLabels = [{'timestamp'} {'chl_wave'} {'bsc_wave'} {'cd_wave'}];
   case 'OCR_504I'
      o_recLabels = [{'timestamp'} {'channel1'} {'channel2'} {'channel3'} {'channel4'}];
   case 'RAFOS_RTC'
      o_recLabels = [{'timestamp'} {'RAFOS_RTC_time'}];
   case 'RAFOS'
      o_recLabels = [{'timestamp'} {'correlation1'} {'rawTOA1'} {'correlation2'} {'rawTOA2'} {'correlation3'} {'rawTOA3'} {'correlation4'} {'rawTOA4'} {'correlation5'} {'rawTOA5'} {'correlation6'} {'rawTOA6'} ];
   case 'IRAD'
      o_recLabels = [{'timestamp'} {'integration_time'} {'temperature'} {'pressure'} {'pre_inclination'} {'post_inclination'}];

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

return
