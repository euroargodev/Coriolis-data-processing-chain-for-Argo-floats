% ------------------------------------------------------------------------------
% Create decoding buffers.
%
% SYNTAX :
%  [o_decodedData] = create_decoding_buffers_arvor_c(a_decodedData)
%
% INPUT PARAMETERS :
%   a_decodedData : decoded data
%
% OUTPUT PARAMETERS :
%   o_decodedData : decoded data (decoding buffers are in 'cyNum' field)
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_decodedData] = create_decoding_buffers_arvor_c(a_decodedData)

% output parameters initialization
o_decodedData = [];

% current float WMO number
global g_decArgo_floatNum;

% output CSV file Id
global g_decArgo_outputCsvFileId;

% configuration values
global g_decArgo_dirOutputCsvFile;

% RT processing flag
global g_decArgo_realtimeFlag;

% default values
global g_decArgo_janFirst1950InMatlab;


tabFileName = {a_decodedData.fileName};
tabDate = [a_decodedData.fileDate];
tabDiffDate = [-1 diff(tabDate)];
tabPackType = [a_decodedData.packType];
tabExpNbAsc = [a_decodedData.expNbAsc];
tabDeep = [a_decodedData.deep];

tabCyNum = ones(size(tabPackType))*-1;
tabBase = zeros(size(tabPackType));
tabCompleted = zeros(size(tabPackType));
tabGo = ones(size(tabPackType));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET BASE PACKETS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set base packets

% first packet
tabBase(1) = 1;

% technical packets of deep cycles
startIds = find((tabPackType == 0) & (tabDeep == 1));
tabBase(startIds) = 1;

% packets with more than one hour of delay
ONE_HOUR = 1/24;
startIds = find(diff(tabDate) > ONE_HOUR) + 1;
tabBase(startIds) = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET CYCLE NUMBERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set a cycle number for each SBD
cyNum = -1;
idBase = find(tabBase == 1);
for idB = 1:length(idBase)
   idStart = idBase(idB);
   if (idB < length(idBase))
      idEnd = idBase(idB+1) - 1;
   else
      idEnd = length(tabPackType);
   end
   curList = idStart:idEnd;
   if (cyNum == -1)
      if (tabDeep(curList(1)) == 0)
         cyNum = 0;
      else
         cyNum = 1;
      end
   else
      cyNum = cyNum + 1;
   end
   tabCyNum(curList) = cyNum;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SET COMPLETED FLAGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set completed flags
ONE_DAY = 1;
cyNumList = unique(tabCyNum);
for cyNum = cyNumList
   idForCy = find(tabCyNum == cyNum);
   nbExpAsc = tabExpNbAsc(idForCy(find(tabExpNbAsc(idForCy) > 0)));
   if (~isempty(nbExpAsc))
      % one technical packet of a deep cycle => check that all expected CTD
      % packets have been received
      idCtd = find((tabPackType(idForCy) == 1) & (tabDeep(idForCy) == 1));
      if (length(idCtd) == nbExpAsc)
         tabCompleted(idForCy) = 1;
      end
   else
      % surface cycle or deep cycle without technical packet
      if (~any(tabPackType(idForCy) ~= 0))
         % surface cycle => always completed
         tabCompleted(idForCy) = 1;
      end
   end
   % check if last cycle should be processed
   if (cyNum == cyNumList(end))
      if (tabCompleted(idForCy(1)) == 0)
         if (~any((tabPackType(idForCy) == 0) & (tabDeep(idForCy) == 0)))
            if (~g_decArgo_realtimeFlag)
               % processed with PI decoder
               tabGo(idForCy) = 2;
            else
               if ((now_utc-g_decArgo_janFirst1950InMatlab) > max(tabDate(idForCy)) + ONE_DAY)
                  % processed because too old
                  tabGo(idForCy) = 3;
               else
                  % not processed => waiting for the next session
                  tabGo(idForCy) = 0;
               end
            end
         end
      end
   end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WRITE CYCLE INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% check received data
fprintf('BUFF_INFO: Float #%d :\n', ...
   g_decArgo_floatNum);
cyNumList = 0:max(tabCyNum);
for cyNum = cyNumList
   idForCy = find(tabCyNum == cyNum);
   if (isempty(idForCy))
      fprintf('BUFF_INFO: Float #%d Cycle #%3d : - NO DATA\n', ...
         g_decArgo_floatNum, cyNum);
   else
      idCy = idForCy(1);
      
      if (tabDeep(idCy) == 1)
         deepStr = 'DEEP CYCLE   ';
      elseif (tabDeep(idCy) == 0)
         deepStr = 'SURFACE CYCLE';
      end
      
      if (tabCompleted(idCy) == 1)
         completedStr = 'COMPLETED';
      else
         completedStr = 'UNCOMPLETED';
      end
      
      piDecStr = '';
      if (tabGo(idCy) == 2)
         piDecStr = ' => DECODED WITH PI DECODER';
      elseif (tabGo(idCy) == 3)
         piDecStr = ' => DECODED (TOO OLD)';
      end
      
      fprintf('BUFF_INFO: Float #%d Cycle #%3d : %3d SBD - %s - %s%s\n', ...
         g_decArgo_floatNum, cyNum, ...
         length(idForCy), deepStr, completedStr, piDecStr);
      
      if (tabCompleted(idCy) == 0)
         [~, ~, why] = check_buffer(idForCy, tabPackType, tabExpNbAsc, 1);
         for idL = 1:length(why)
            fprintf('   -> %s\n', why{idL});
         end
      end
   end
end

% assign cycle number to Iridium mail files
tabSbdFileName = [];
tabCycleNumber = [];
cyNumList = unique(tabCyNum);
for cyNum = cyNumList
   idForCy = find(tabCyNum == cyNum);
   tabSbdFileName = [tabSbdFileName tabFileName(idForCy)];
   tabCycleNumber = [tabCycleNumber repmat(cyNum, 1, length(idForCy))];
end
update_mail_data_ir_sbd_delayed(tabSbdFileName, tabCycleNumber);

% output data
o_decodedData = a_decodedData;
tabCyNumCell = num2cell(tabCyNum);
[o_decodedData.cyNum] = deal(tabCyNumCell{:});
tabDeepCell = num2cell(tabDeep);
[o_decodedData.deep] = deal(tabDeepCell{:});
tabCompletedCell = num2cell(tabCompleted);
[o_decodedData.completed] = deal(tabCompletedCell{:});

if (~isempty(g_decArgo_outputCsvFileId))
   if (1)
      % CSV output
      csvFilepathName = [g_decArgo_dirOutputCsvFile '/' num2str(g_decArgo_floatNum) '_buffers_' datestr(now, 'yyyymmddTHHMMSS') '.csv'];
      fId = fopen(csvFilepathName, 'wt');
      if (fId ~= -1)
         
         header = '#;Base;Date;DiffDate;CyNum;Deep;Completed;PackType;tabExpNbAsc;PackTypeInfo';
         fprintf(fId, '%s\n', header);
         
         for idL = 1:length(tabPackType)
            
            if (idL > 1)
               if (tabCyNum(idL) ~= tabCyNum(idL-1))
                  fprintf(fId, '%d\n', -1);
               end
            end
            
            if (tabDiffDate(idL) == -1)
               diffDate = '';
            else
               diffDate = format_time_dec_argo(tabDiffDate(idL)*24);
            end
                                    
            fprintf(fId, '%d;%d;%s;%s;%d;%d;%d;%d;%d;%s\n', ...
               idL, ...
               tabBase(idL), ...
               julian_2_gregorian_dec_argo(tabDate(idL)), ...
               diffDate, ...
               tabCyNum(idL), ...
               tabDeep(idL), ...
               tabCompleted(idL), ...
               tabPackType(idL), ...
               tabExpNbAsc(idL), ...
               get_pack_type_desc(tabPackType(idL)) ...
               );
            
         end
         
         fclose(fId);
      end
   end
end

return

% ------------------------------------------------------------------------------
% Check buffer completion.
%
% SYNTAX :
%  [o_completed, o_deep, o_whyStr] = check_buffer( ...
%    a_idForCheck, a_tabPackType, a_tabExpNbAsc, a_whyFlag)
%
% INPUT PARAMETERS :
%   a_idForCheck    : Id list of SBD to be checked
%   a_tabPackType   : SBD packet types
%   a_tabExpNbAsc   : expected number of ascending data packets
%   a_whyFlag       : if set to 1, print why the buffer is not completed
%
% OUTPUT PARAMETERS :
%   o_completed : 1 if the buffer is completed, 0 otherwise
%   o_deep      : 1 if it is a deep cycle, 0 if it is a surface cycle
%   o_whyStr    : outpout strings that explain why the buffer is not
%                 completed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_completed, o_deep, o_whyStr] = check_buffer( ...
   a_idForCheck, a_tabPackType, a_tabExpNbAsc, a_whyFlag)

% output parameter initialization
o_completed = 0;
o_deep = 0;
o_whyStr = '';


% check buffer completion
idPackTech = find(a_tabPackType(a_idForCheck) == 0);
idPackAsc = find(a_tabPackType(a_idForCheck) == 1);

if (~isempty(idPackAsc))
   recNbAsc = length(idPackAsc);
   o_deep = 1;
else
   recNbAsc = 0;
end

if (~isempty(idPackTech))
   expNbAsc = a_tabExpNbAsc(a_idForCheck(idPackTech));
   if (expNbAsc == 0)
      % surface cycle
      o_completed = 1;
   else
      % deep cycle
      if (recNbAsc == expNbAsc)
         o_completed = 1;
      end
      o_deep = 1;
   end
end

% print what is missing in the buffer
if (a_whyFlag && ~o_completed)
   if (isempty(idPackTech))
      o_whyStr{end+1} = 'Tech packet is missing';
   end
   if (~isempty(idPackTech))
      if (recNbAsc ~= expNbAsc)
         if (expNbAsc > recNbAsc)
            o_whyStr{end+1} = sprintf('%d ascending data packets are MISSING', expNbAsc-recNbAsc);
         else
            o_whyStr{end+1} = sprintf('%d ascending data packets are NOT EXPECTED', -(expNbAsc-recNbAsc));
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Convert packet type number into description string.
%
% SYNTAX :
%  [o_packTypeDesc] = get_pack_type_desc(a_packType)
%
% INPUT PARAMETERS :
%   a_packType  : packet type number
%
% OUTPUT PARAMETERS :
%   o_packTypeDesc : packet type description
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   09/17/2019 - RNU - creation
% ------------------------------------------------------------------------------
function [o_packTypeDesc] = get_pack_type_desc(a_packType)

% output parameter initialization
o_packTypeDesc = '';

switch (a_packType)
   case 0
      o_packTypeDesc = 'Tech#1';
   case 1
      o_packTypeDesc = 'Asc meas';
   otherwise
      fprintf('WARNING: Unknown packet type #%d for decoderId #%d\n', ...
         a_packType, a_decoderId);
end

return
