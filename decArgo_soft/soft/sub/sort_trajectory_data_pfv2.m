% ------------------------------------------------------------------------------
% Sort trajectory data N_MEASUREMENT information
%
% SYNTAX :
%  [o_tabTrajNMeas] = sort_trajectory_data_pfv2(a_tabTrajNMeas)
%
% INPUT PARAMETERS :
%   a_tabTrajNMeas : input N_MEASUREMENT trajectory data
%
% OUTPUT PARAMETERS :
%   o_tabTrajNMeas  : output N_MEASUREMENT trajectory data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHOR : Jean-Philippe Rannou (Capgemini) (jean.philippe.rannou@partenaire-exterieur.ifremer.fr)
% ------------------------------------------------------------------------------
% RELEASES :
%   10/11/2024 - RNU - creation
% ------------------------------------------------------------------------------
function [o_tabTrajNMeas] = sort_trajectory_data_pfv2(a_tabTrajNMeas)

% output parameters initialization
o_tabTrajNMeas = a_tabTrajNMeas;

% current float WMO number
global g_decArgo_floatNum;

% default values
global g_decArgo_dateDef;

% global measurement codes
global g_MC_FMT;
global g_MC_Surface;
global g_MC_LMT;


if (isempty(o_tabTrajNMeas))
   return
end

% since most of the N_MEAS are dated we first sort the dated MCs of a given
% cycle in chronological order and then insert the remaining MCs (sorted
% according to their value).

cycleNumList = unique([o_tabTrajNMeas.cycleNumber]);
for idC = 1:length(cycleNumList)
   cycleNum = cycleNumList(idC);

   % N_MEAS of the current cycle
   idTrajNMeasStruct = find([o_tabTrajNMeas.cycleNumber] == cycleNum);
   tabMeas = o_tabTrajNMeas(idTrajNMeasStruct).tabMeas;

   % create the array of dates of MCs
   tabDates = ones(size(tabMeas))*g_decArgo_dateDef;
   idDate1 = find(~cellfun(@isempty, {tabMeas.juld}));
   idDate2 = find([tabMeas(idDate1).juld] ~= g_decArgo_dateDef);
   tabDates(idDate1(idDate2)) = [tabMeas(idDate1(idDate2)).juld];
   if (any(tabDates == g_decArgo_dateDef))
      idF = find(tabDates == g_decArgo_dateDef);
      idDate1 = find(~cellfun(@isempty, {tabMeas(idF).juldAdj}));
      idDate2 = find([tabMeas(idF(idDate1)).juldAdj] ~= g_decArgo_dateDef);
      tabDates(idF(idDate1(idDate2))) = [tabMeas(idF(idDate1(idDate2))).juld];
   end

   % sort dated MCs
   idF = find(tabDates ~= g_decArgo_dateDef);
   [~, idSort] = sort(tabDates(idF));
   tabMeasNew = tabMeas(idF(idSort));

   % insert remaining MCs
   idF = find(tabDates == g_decArgo_dateDef);
   for idM = 1:length(idF)
      idIn = idF(idM);
      mcList = [];
      switch (tabMeas(idIn).measCode)
         case 99
            after = 0;
            mcList = 100;
         case 100
            after = 0;
            mcList = 150;
         case 198
            after = 0;
            mcList = 250;
         case 203
            after = 0;
            mcList = 198;
         case 297
            after = 1;
            mcList = 300;
         case 301
            after = 1;
            mcList = 300;
         case 298
            after = 1;
            mcList = 297;
         case 398
            after = 0;
            mcList = 450;
         case 497
            after = 1;
            mcList = 500;
         case 498
            after = 1;
            mcList = 497;
         case 599
            after = 0;
            mcList = 600;
         case 700
            after = 0;
            mcList = 702;
         case 800
            after = 1;
            mcList = 704;
         otherwise
            fprintf('WARNING: Float #%d Cycle #%d: No rule to sort not dated MC (%d)\n', ...
               g_decArgo_floatNum, cycleNum, tabMeas(idIn).measCode);
      end
      if (~isempty(mcList))
         if (after)
            idOut = find([tabMeasNew.measCode] == mcList, 1, 'last') + 1;
         else
            idOut = find([tabMeasNew.measCode] == mcList, 1, 'first');
         end
      else
         idOut = find([tabMeasNew.measCode] > tabMeas(idIn).measCode, 1, 'first');
      end
      tabMeasNew(idOut+1:end+1) = tabMeasNew(idOut:end);
      tabMeasNew(idOut) = tabMeas(idIn);
   end

    % set the "702: FIRST_MESSAGE" before the associated "703: SURFACE"
    idFmt = find([tabMeasNew.measCode] == g_MC_FMT);
    if (~isempty(idFmt))
       idS = find(([tabMeasNew.measCode] == g_MC_Surface));
       if (~isempty(idS))
          idFs = find([tabMeasNew(idS).juld] == tabMeasNew(idFmt).juld);
          if (~isempty(idFs))
             tmp = tabMeasNew(idS(idFs));
             tabMeasNew(idS(idFs)) = tabMeasNew(idFmt);
             tabMeasNew(idFmt) = tmp;
          end
       end
    end

    % set the "704: LAST_MESSAGE" after the associated "703: SURFACE"
    idLmt = find([tabMeasNew.measCode] == g_MC_LMT);
    if (~isempty(idLmt))
       idS = find(([tabMeasNew.measCode] == g_MC_Surface));
       if (~isempty(idS))
          idLs = find([tabMeasNew(idS).juld] == tabMeasNew(idLmt).juld);
          if (~isempty(idLs))
             tmp = tabMeasNew(idS(idLs));
             tabMeasNew(idS(idLs)) = tabMeasNew(idLmt);
             tabMeasNew(idLmt) = tmp;
          end
       end
    end

   o_tabTrajNMeas(idTrajNMeasStruct).tabMeas = tabMeasNew;
   clear tabMeas;
end

return
