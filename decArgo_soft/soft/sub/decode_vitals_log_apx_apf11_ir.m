% ------------------------------------------------------------------------------
% Decode vitals_log files of one cycle of APEX APF11 Iridium data.
%
% SYNTAX :
%  [o_miscInfo, o_vitalsCore] = ...
%    decode_vitals_log_apx_apf11_ir(a_vitalsLogFileList)
%
% INPUT PARAMETERS :
%   a_vitalsLogFileList : list of vitals_log files
%
% OUTPUT PARAMETERS :
%   o_miscInfo   : misc information from vitals_log files
%   o_vitalsCore : vitals data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   04/27/2018 - RNU - creation
% ------------------------------------------------------------------------------
function [o_miscInfo, o_vitalsCore] = ...
   decode_vitals_log_apx_apf11_ir(a_vitalsLogFileList)

% output parameters initialization
o_miscInfo = [];
o_vitalsCore = [];

% default values
global g_decArgo_dateDef;

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


if (isempty(a_vitalsLogFileList))
   return;
end

if (length(a_vitalsLogFileList) > 1)
   fprintf('DEC_INFO: Float #%d Cycle #%d: multiple (%d) vitals_log file for this cycle\n', ...
      g_decArgo_floatNum, g_decArgo_cycleNum, length(a_vitalsLogFileList));
end

expectedFields = [ ...
   {'Message'} ...
   {'VITALS_CORE'} ...
   {'WD_CNT'} ...
   ];

usedMessages = [ ...
   {'None'} ...
   ];

ignoredMessages = [ ...
   {'Firmware: '} ...
   {'Float ID: '} ...
   ];

for idFile = 1:length(a_vitalsLogFileList)
   
   vitFilePathName = a_vitalsLogFileList{idFile};
   
   % read input file
   [error, data] = read_apx_apf11_ir_binary_log_file(vitFilePathName, 'vitals');
   if (error == 1)
      fprintf('ERROR: Float #%d Cycle #%d: Error in file: %s => ignored\n', ...
         g_decArgo_floatNum, g_decArgo_cycleNum, vitFilePathName);
      return;
   end
   
   dataFields = fieldnames(data);
   for idFld = 1:length(dataFields)
      fieldName = dataFields{idFld};
      if (~any(strfind(fieldName, '_labels')))
         if (~isempty(data.(fieldName)))
            if (ismember(fieldName, expectedFields))
               switch (fieldName)
                  case 'Message'
                     msg = data.(fieldName);
                     for idM = 1:size(msg, 1)
                        msgData = msg{idM, 2};
                        idF = cellfun(@(x) strfind(msgData, x), usedMessages, 'UniformOutput', 0);
                        if (~isempty([idF{:}]))
                           % nothing used
                        else
                           idF = cellfun(@(x) strfind(msgData, x), ignoredMessages, 'UniformOutput', 0);
                           if (isempty([idF{:}]))
                              fprintf('ERROR: Float #%d Cycle #%d: Not managed ''%s'' information (''%s'') in file: %s => ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
                                 g_decArgo_floatNum, g_decArgo_cycleNum, 'Message', msgData, vitFilePathName);
                              continue;
                           end
                        end
                     end
                  case 'VITALS_CORE'
                     vitalsCore = data.(fieldName);
                     o_vitalsCore = [o_vitalsCore; [vitalsCore(:, 1) ones(size(vitalsCore, 1), 1)*g_decArgo_dateDef vitalsCore(:, 2:end)]];
                  case 'WD_CNT'
                     info = data.(fieldName);
                     
                     dataStruct = get_apx_misc_data_init_struct('Watchdog', [], [], []);
                     dataStruct.label = 'Whatchdog';
                     dataStruct.value = info(2);
                     dataStruct.format = '%d';
                     o_miscInfo{end+1} = dataStruct;
               end
            else
               fprintf('ERROR: Float #%d Cycle #%d: Field ''%s'' not expected in file: %s => ignored (ASK FOR AN UPDATE OF THE DECODER)\n', ...
                  g_decArgo_floatNum, g_decArgo_cycleNum, fieldName, vitFilePathName);
            end
         end
      end
   end
end

return;
