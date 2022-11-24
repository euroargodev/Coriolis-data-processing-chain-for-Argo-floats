% ------------------------------------------------------------------------------
% Parse Apex Iridium Rudics engineering data.
%
% SYNTAX :
%  [o_engineeringData] = parse_apx_ir_engineering_data(a_engineeringDataStr)
%
% INPUT PARAMETERS :
%   a_engineeringDataStr : input ASCII engineering data
%
% OUTPUT PARAMETERS :
%   o_engineeringData : engineering data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   07/10/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_engineeringData] = parse_apx_ir_engineering_data(a_engineeringDataStr)

% output parameters initialization
o_engineeringData = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;


errorHeader = '';
if (~isempty(g_decArgo_floatNum))
   errorHeader = sprintf('Float #%d Cycle #%d: ', g_decArgo_floatNum, g_decArgo_cycleNum);
end

for idEng = 1:length(a_engineeringDataStr)
   
   data = a_engineeringDataStr{idEng};
   
   idF1 = find(strncmp(data, 'ParkDescentPCnt', length('ParkDescentPCnt')));
   if (~isempty(idF1))
      dataStr = data{idF1};
      idF2 = strfind(dataStr, '=');
      if (~isempty(idF2))
         nbPMark = str2num(dataStr(idF2(1)+1:end));
         if (nbPMark > 0)
            idDel = [];
            pMarkValues = [];
            for id = 1:nbPMark
               item = sprintf('ParkDescentP[%d]', id-1);
               idF3 = find(strncmp(data, item, length(item)));
               if (~isempty(idF3))
                  dataStr = data{idF3};
                  idF4 = strfind(dataStr, '=');
                  if (~isempty(idF4))
                     pMarkValues = [pMarkValues dataStr(idF4(1)+1:end) ','];
                  end
                  idDel = [idDel idF3];
               end
            end
            data{idF1} = ['ParkDescentP={' pMarkValues(1:end-1) '}'];
            data(idDel) = [];
         end
      end
   end
      
   engineeringData = [];
   for id = 1:length(data)
      dataStr = data{id};
      idF1 = strfind(dataStr, '=');
      
      if (~isempty(idF1))
         item = dataStr(1:idF1(1)-1);
         if (isempty(regexp(lower(item(1)), '[a-z]', 'once')))
            fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s''- ignored\n', errorHeader, dataStr);
            continue
         end
         if (any(strfind(item, ' ')))
            fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s''- ignored\n', errorHeader, dataStr);
            continue
         end
         if (any(strfind(item, '[')))
            item = regexprep(item, '[', '_');
            item = regexprep(item, ']', '_');
         end
         value = dataStr(idF1(1)+1:end);
         if (any(strfind(value, '{')))
            value = regexprep(value, '{', '');
            value = regexprep(value, '}', '');
            value = strtrim(strsplit(value, ','));
         end
         if (~isempty(value))
            engineeringData.(item) = value;
         end
      else
         fprintf('DEC_INFO: %sAnomaly detected while parsing ''%s''- ignored\n', errorHeader, dataStr);
         continue
      end
   end
   if (~isempty(engineeringData))
      o_engineeringData{end+1} = engineeringData;
   end
end

return
