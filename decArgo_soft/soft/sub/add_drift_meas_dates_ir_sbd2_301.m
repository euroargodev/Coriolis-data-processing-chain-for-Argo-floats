% ------------------------------------------------------------------------------
% Add the dates of the drift measurements.
%
% SYNTAX :
%  [o_dataCTD, o_dataOXY, o_dataFLBB] = ...
%    add_drift_meas_dates_ir_sbd2_301(a_dataCTD, a_dataOXY, a_dataFLBB)
%
% INPUT PARAMETERS :
%   a_dataCTD  : input CTD data
%   a_dataOXY  : input OXY data
%   a_dataFLBB : input FLBB data
%
% OUTPUT PARAMETERS :
%   o_dataCTD  : output CTD data
%   o_dataOXY  : output OXY data
%   o_dataFLBB : output FLBB data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/01/2014 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataCTD, o_dataOXY, o_dataFLBB] = ...
   add_drift_meas_dates_ir_sbd2_301(a_dataCTD, a_dataOXY, a_dataFLBB)

% cycle phases
global g_decArgo_phaseParkDrift;


% output parameters initialization
o_dataCTD = [];
o_dataOXY = [];
o_dataFLBB = [];

% unpack the input data
a_dataCTDMean = a_dataCTD{1};
a_dataCTDStdMed = a_dataCTD{2};

a_dataCTDMeanDate = a_dataCTDMean{1};
a_dataCTDMeanDateTrans = a_dataCTDMean{2};
a_dataCTDMeanPres = a_dataCTDMean{3};
a_dataCTDMeanTemp = a_dataCTDMean{4};
a_dataCTDMeanSal = a_dataCTDMean{5};

a_dataCTDStdMedDate = a_dataCTDStdMed{1};
a_dataCTDStdMedDateTrans = a_dataCTDStdMed{2};
a_dataCTDStdMedPresMean  = a_dataCTDStdMed{3};
a_dataCTDStdMedTempStd  = a_dataCTDStdMed{4};
a_dataCTDStdMedSalStd  = a_dataCTDStdMed{5};
a_dataCTDStdMedPresMed  = a_dataCTDStdMed{6};
a_dataCTDStdMedTempMed  = a_dataCTDStdMed{7};
a_dataCTDStdMedSalMed  = a_dataCTDStdMed{8};

a_dataOXYMean = a_dataOXY{1};
a_dataOXYStdMed = a_dataOXY{2};

a_dataOXYMeanDate = a_dataOXYMean{1};
a_dataOXYMeanDateTrans = a_dataOXYMean{2};
a_dataOXYMeanPres = a_dataOXYMean{3};
a_dataOXYMeanC1Phase = a_dataOXYMean{4};
a_dataOXYMeanC2Phase = a_dataOXYMean{5};
a_dataOXYMeanTemp = a_dataOXYMean{6};

a_dataOXYStdMedDate = a_dataOXYStdMed{1};
a_dataOXYStdMedDateTrans = a_dataOXYStdMed{2};
a_dataOXYStdMedPresMean = a_dataOXYStdMed{3};
a_dataOXYStdMedC1PhaseStd = a_dataOXYStdMed{4};
a_dataOXYStdMedC2PhaseStd = a_dataOXYStdMed{5};
a_dataOXYStdMedTempStd = a_dataOXYStdMed{6};
a_dataOXYStdMedC1PhaseMed = a_dataOXYStdMed{7};
a_dataOXYStdMedC2PhaseMed = a_dataOXYStdMed{8};
a_dataOXYStdMedTempMed = a_dataOXYStdMed{9};

a_dataFLBBMean = a_dataFLBB{1};
a_dataFLBBStdMed = a_dataFLBB{2};

a_dataFLBBMeanDate = a_dataFLBBMean{1};
a_dataFLBBMeanDateTrans = a_dataFLBBMean{2};
a_dataFLBBMeanPres = a_dataFLBBMean{3};
a_dataFLBBMeanChloroA = a_dataFLBBMean{4};
a_dataFLBBMeanBackscat = a_dataFLBBMean{5};

a_dataFLBBStdMedDate = a_dataFLBBStdMed{1};
a_dataFLBBStdMedDateTrans = a_dataFLBBStdMed{2};
a_dataFLBBStdMedPresMean = a_dataFLBBStdMed{3};
a_dataFLBBStdMedChloroAStd = a_dataFLBBStdMed{4};
a_dataFLBBStdMedBackscatStd = a_dataFLBBStdMed{5};
a_dataFLBBStdMedChloroAMed = a_dataFLBBStdMed{6};
a_dataFLBBStdMedBackscatMed = a_dataFLBBStdMed{7};

% add the drift measurement dates
if (~isempty(a_dataCTDMeanDate))
   idDrift = find(a_dataCTDMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCTDMeanDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(0, ...
         a_dataCTDMeanDate(idDrift(idL), 1), ...
         a_dataCTDMeanDate(idDrift(idL), 2), ...
         a_dataCTDMeanDate(idDrift(idL), 4:end));
   end
end
if (~isempty(a_dataCTDStdMedDate))
   idDrift = find(a_dataCTDStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataCTDStdMedDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(0, ...
         a_dataCTDStdMedDate(idDrift(idL), 1), ...
         a_dataCTDStdMedDate(idDrift(idL), 2), ...
         a_dataCTDStdMedDate(idDrift(idL), 4:end));
   end
end

if (~isempty(a_dataOXYMeanDate))
   idDrift = find(a_dataOXYMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOXYMeanDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(1, ...
         a_dataOXYMeanDate(idDrift(idL), 1), ...
         a_dataOXYMeanDate(idDrift(idL), 2), ...
         a_dataOXYMeanDate(idDrift(idL), 4:end));
   end
end
if (~isempty(a_dataOXYStdMedDate))
   idDrift = find(a_dataOXYStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataOXYStdMedDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(1, ...
         a_dataOXYStdMedDate(idDrift(idL), 1), ...
         a_dataOXYStdMedDate(idDrift(idL), 2), ...
         a_dataOXYStdMedDate(idDrift(idL), 4:end));
   end
end

if (~isempty(a_dataFLBBMeanDate))
   idDrift = find(a_dataFLBBMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLBBMeanDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
         a_dataFLBBMeanDate(idDrift(idL), 1), ...
         a_dataFLBBMeanDate(idDrift(idL), 2), ...
         a_dataFLBBMeanDate(idDrift(idL), 4:end));
   end
end
if (~isempty(a_dataFLBBStdMedDate))
   idDrift = find(a_dataFLBBStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLBBStdMedDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
         a_dataFLBBStdMedDate(idDrift(idL), 1), ...
         a_dataFLBBStdMedDate(idDrift(idL), 2), ...
         a_dataFLBBStdMedDate(idDrift(idL), 4:end));
   end
end

% store output data in cell arrays
o_dataCTDMean{1} = a_dataCTDMeanDate;
o_dataCTDMean{2} = a_dataCTDMeanDateTrans;
o_dataCTDMean{3} = a_dataCTDMeanPres;
o_dataCTDMean{4} = a_dataCTDMeanTemp;
o_dataCTDMean{5} = a_dataCTDMeanSal;

o_dataCTDStdMed{1} = a_dataCTDStdMedDate;
o_dataCTDStdMed{2} = a_dataCTDStdMedDateTrans;
o_dataCTDStdMed{3} = a_dataCTDStdMedPresMean;
o_dataCTDStdMed{4} = a_dataCTDStdMedTempStd;
o_dataCTDStdMed{5} = a_dataCTDStdMedSalStd;
o_dataCTDStdMed{6} = a_dataCTDStdMedPresMed;
o_dataCTDStdMed{7} = a_dataCTDStdMedTempMed;
o_dataCTDStdMed{8} = a_dataCTDStdMedSalMed;

o_dataCTD{1} = o_dataCTDMean;
o_dataCTD{2} = o_dataCTDStdMed;

o_dataOXYMean{1} = a_dataOXYMeanDate;
o_dataOXYMean{2} = a_dataOXYMeanDateTrans;
o_dataOXYMean{3} = a_dataOXYMeanPres;
o_dataOXYMean{4} = a_dataOXYMeanC1Phase;
o_dataOXYMean{5} = a_dataOXYMeanC2Phase;
o_dataOXYMean{6} = a_dataOXYMeanTemp;

o_dataOXYStdMed{1} = a_dataOXYStdMedDate;
o_dataOXYStdMed{2} = a_dataOXYStdMedDateTrans;
o_dataOXYStdMed{3} = a_dataOXYStdMedPresMean;
o_dataOXYStdMed{4} = a_dataOXYStdMedC1PhaseStd;
o_dataOXYStdMed{5} = a_dataOXYStdMedC2PhaseStd;
o_dataOXYStdMed{6} = a_dataOXYStdMedTempStd;
o_dataOXYStdMed{7} = a_dataOXYStdMedC1PhaseMed;
o_dataOXYStdMed{8} = a_dataOXYStdMedC2PhaseMed;
o_dataOXYStdMed{9} = a_dataOXYStdMedTempMed;

o_dataOXY{1} = o_dataOXYMean;
o_dataOXY{2} = o_dataOXYStdMed;

o_dataFLBBMean{1} = a_dataFLBBMeanDate;
o_dataFLBBMean{2} = a_dataFLBBMeanDateTrans;
o_dataFLBBMean{3} = a_dataFLBBMeanPres;
o_dataFLBBMean{4} = a_dataFLBBMeanChloroA;
o_dataFLBBMean{5} = a_dataFLBBMeanBackscat;

o_dataFLBBStdMed{1} = a_dataFLBBStdMedDate;
o_dataFLBBStdMed{2} = a_dataFLBBStdMedDateTrans;
o_dataFLBBStdMed{3} = a_dataFLBBStdMedPresMean;
o_dataFLBBStdMed{4} = a_dataFLBBStdMedChloroAStd;
o_dataFLBBStdMed{5} = a_dataFLBBStdMedBackscatStd;
o_dataFLBBStdMed{6} = a_dataFLBBStdMedChloroAMed;
o_dataFLBBStdMed{7} = a_dataFLBBStdMedBackscatMed;

o_dataFLBB{1} = o_dataFLBBMean;
o_dataFLBB{2} = o_dataFLBBStdMed;

return;
