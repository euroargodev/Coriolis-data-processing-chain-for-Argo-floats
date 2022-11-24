% ------------------------------------------------------------------------------
% Clean duplicates in received data.
%
% SYNTAX :
%  [o_tabData, o_tabDataDates] = clean_duplicates_in_received_data_216(...
%    a_tabData, a_tabDataDates, a_procLevel)
%
% INPUT PARAMETERS :
%   a_tabData      : received data frame
%   a_tabDataDates : corresponding dates of Iridium SBD
%   a_procLevel    : processing level (0: collect only rough information, 1:
%                    decode the data)
%
% OUTPUT PARAMETERS :
%   o_tabData      : cleaned received data frame
%   o_tabDataDates : corresponding dates of Iridium SBD
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/22/2017 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabData, o_tabDataDates] = clean_duplicates_in_received_data_216(...
   a_tabData, a_tabDataDates, a_procLevel)

% output parameters initialization
o_tabData = a_tabData;
o_tabDataDates = a_tabDataDates;

% current float WMO number
global g_decArgo_floatNum;

% clean multiple transmission
% some messages may be transmitted more than once
if ((size(o_tabData, 1) ~= size(unique(o_tabData, 'rows'), 1)))
   if (a_procLevel == 1)
      fprintf('\n');
   end
   [uTabData, ia, ic] = unique(o_tabData, 'rows', 'stable');
   for idMes = 1:size(uTabData, 1)
      idEq = [];
      for idM = 1:size(o_tabData, 1)
         if (sum(uTabData(idMes, :) == o_tabData(idM, :)) == size(o_tabData, 2))
            idEq = [idEq idM];
         end
      end
      if (length(idEq) > 1)
         % packet type
         packType = o_tabData(idEq(1), 1);
         if (packType == 0)
            packetName = 'one technical packet #1';
         elseif (packType == 4)
            packetName = 'one technical packet #2';
         elseif (packType == 5)
            packetName = 'one parameter packet #1';
         elseif (packType == 6)
            packetName = 'one hydraulic valve packet';
         elseif (packType == 7)
            packetName = 'one hydraulic pump packet';
         else
            packetName = 'one data packet';
         end
         
         if (a_procLevel == 1)
            if (length(idEq) == 2)
               fprintf('INFO: Float #%d: %s received twice => only one is decoded\n', ...
                  g_decArgo_floatNum, ...
                  packetName);
            else
               fprintf('INFO: Float #%d: %s received %d times => only one is decoded\n', ...
                  g_decArgo_floatNum, ...
                  packetName, ...
                  length(idEq));
            end
         end
      end
   end
   idDel = setdiff(1:size(o_tabData, 1), ia);
   o_tabData = uTabData;
   o_tabDataDates(idDel) = [];
end

return;
