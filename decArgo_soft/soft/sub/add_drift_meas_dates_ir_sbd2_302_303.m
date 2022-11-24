% ------------------------------------------------------------------------------
% Add the dates of the drift measurements.
%
% SYNTAX :
%  [o_dataCTD, o_dataOXY, o_dataFLNTU, o_dataCYCLOPS, o_dataSEAPOINT] = ...
%    add_drift_meas_dates_ir_sbd2_302_303(a_dataCTD, a_dataOXY, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT)
%
% INPUT PARAMETERS :
%   a_dataCTD      : input CTD data
%   a_dataOXY      : input OXY data
%   a_dataFLNTU    : input FLNTU data
%   a_dataCYCLOPS  : input CYCLOPS data
%   a_dataSEAPOINT : input SEAPOINT data
%
% OUTPUT PARAMETERS :
%   o_dataCTD      : output CTD data
%   o_dataOXY      : output OXY data
%   o_dataFLNTU    : output FLNTU data
%   o_dataCYCLOPS  : output CYCLOPS data
%   o_dataSEAPOINT : output SEAPOINT data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/26/2015 - RNU - creation
% ------------------------------------------------------------------------------
function [o_dataCTD, o_dataOXY, o_dataFLNTU, o_dataCYCLOPS, o_dataSEAPOINT] = ...
   add_drift_meas_dates_ir_sbd2_302_303(a_dataCTD, a_dataOXY, a_dataFLNTU, a_dataCYCLOPS, a_dataSEAPOINT)

% cycle phases
global g_decArgo_phaseParkDrift;


% output parameters initialization
o_dataCTD = [];
o_dataOXY = [];
o_dataFLNTU = [];
o_dataCYCLOPS = [];
o_dataSEAPOINT = [];

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
a_dataOXYMeanDPhase = a_dataOXYMean{4};
a_dataOXYMeanTemp = a_dataOXYMean{5};

a_dataOXYStdMedDate = a_dataOXYStdMed{1};
a_dataOXYStdMedDateTrans = a_dataOXYStdMed{2};
a_dataOXYStdMedPresMean = a_dataOXYStdMed{3};
a_dataOXYStdMedDPhaseStd = a_dataOXYStdMed{4};
a_dataOXYStdMedTempStd = a_dataOXYStdMed{5};
a_dataOXYStdMedDPhaseMed = a_dataOXYStdMed{6};
a_dataOXYStdMedTempMed = a_dataOXYStdMed{7};

a_dataFLNTUMean = a_dataFLNTU{1};
a_dataFLNTUStdMed = a_dataFLNTU{2};

a_dataFLNTUMeanDate = a_dataFLNTUMean{1};
a_dataFLNTUMeanDateTrans = a_dataFLNTUMean{2};
a_dataFLNTUMeanPres = a_dataFLNTUMean{3};
a_dataFLNTUMeanChloro = a_dataFLNTUMean{4};
a_dataFLNTUMeanTurbi = a_dataFLNTUMean{5};

a_dataFLNTUStdMedDate = a_dataFLNTUStdMed{1};
a_dataFLNTUStdMedDateTrans = a_dataFLNTUStdMed{2};
a_dataFLNTUStdMedPresMean = a_dataFLNTUStdMed{3};
a_dataFLNTUStdMedChloroStd = a_dataFLNTUStdMed{4};
a_dataFLNTUStdMedTurbiStd = a_dataFLNTUStdMed{5};
a_dataFLNTUStdMedChloroMed = a_dataFLNTUStdMed{6};
a_dataFLNTUStdMedTurbiMed = a_dataFLNTUStdMed{7};

if (~isempty(a_dataCYCLOPS))
   a_dataCYCLOPSMean = a_dataCYCLOPS{1};
   a_dataCYCLOPSStdMed = a_dataCYCLOPS{2};
   
   a_dataCYCLOPSMeanDate = a_dataCYCLOPSMean{1};
   a_dataCYCLOPSMeanDateTrans = a_dataCYCLOPSMean{2};
   a_dataCYCLOPSMeanPres = a_dataCYCLOPSMean{3};
   a_dataCYCLOPSMeanChloro = a_dataCYCLOPSMean{4};
   
   a_dataCYCLOPSStdMedDate = a_dataCYCLOPSStdMed{1};
   a_dataCYCLOPSStdMedDateTrans = a_dataCYCLOPSStdMed{2};
   a_dataCYCLOPSStdMedPresMean = a_dataCYCLOPSStdMed{3};
   a_dataCYCLOPSStdMedChloroStd = a_dataCYCLOPSStdMed{4};
   a_dataCYCLOPSStdMedChloroMed = a_dataCYCLOPSStdMed{5};
end

if (~isempty(a_dataSEAPOINT))
   a_dataSEAPOINTMean = a_dataSEAPOINT{1};
   a_dataSEAPOINTStdMed = a_dataSEAPOINT{2};
   
   a_dataSEAPOINTMeanDate = a_dataSEAPOINTMean{1};
   a_dataSEAPOINTMeanDateTrans = a_dataSEAPOINTMean{2};
   a_dataSEAPOINTMeanPres = a_dataSEAPOINTMean{3};
   a_dataSEAPOINTMeanTurbi = a_dataSEAPOINTMean{4};
   
   a_dataSEAPOINTStdMedDate = a_dataSEAPOINTStdMed{1};
   a_dataSEAPOINTStdMedDateTrans = a_dataSEAPOINTStdMed{2};
   a_dataSEAPOINTStdMedPresMean = a_dataSEAPOINTStdMed{3};
   a_dataSEAPOINTStdMedTurbiStd = a_dataSEAPOINTStdMed{4};
   a_dataSEAPOINTStdMedTurbiMed = a_dataSEAPOINTStdMed{5};
end

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

if (~isempty(a_dataFLNTUMeanDate))
   idDrift = find(a_dataFLNTUMeanDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLNTUMeanDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
         a_dataFLNTUMeanDate(idDrift(idL), 1), ...
         a_dataFLNTUMeanDate(idDrift(idL), 2), ...
         a_dataFLNTUMeanDate(idDrift(idL), 4:end));
   end
end
if (~isempty(a_dataFLNTUStdMedDate))
   idDrift = find(a_dataFLNTUStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
   for idL = 1:length(idDrift)
      [a_dataFLNTUStdMedDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
         a_dataFLNTUStdMedDate(idDrift(idL), 1), ...
         a_dataFLNTUStdMedDate(idDrift(idL), 2), ...
         a_dataFLNTUStdMedDate(idDrift(idL), 4:end));
   end
end

if (~isempty(a_dataCYCLOPS))
   if (~isempty(a_dataCYCLOPSMeanDate))
      idDrift = find(a_dataCYCLOPSMeanDate(:, 3) == g_decArgo_phaseParkDrift);
      for idL = 1:length(idDrift)
         [a_dataCYCLOPSMeanDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
            a_dataCYCLOPSMeanDate(idDrift(idL), 1), ...
            a_dataCYCLOPSMeanDate(idDrift(idL), 2), ...
            a_dataCYCLOPSMeanDate(idDrift(idL), 4:end));
      end
   end
   if (~isempty(a_dataCYCLOPSStdMedDate))
      idDrift = find(a_dataCYCLOPSStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
      for idL = 1:length(idDrift)
         [a_dataCYCLOPSStdMedDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
            a_dataCYCLOPSStdMedDate(idDrift(idL), 1), ...
            a_dataCYCLOPSStdMedDate(idDrift(idL), 2), ...
            a_dataCYCLOPSStdMedDate(idDrift(idL), 4:end));
      end
   end
end

if (~isempty(a_dataSEAPOINT))
   if (~isempty(a_dataSEAPOINTMeanDate))
      idDrift = find(a_dataSEAPOINTMeanDate(:, 3) == g_decArgo_phaseParkDrift);
      for idL = 1:length(idDrift)
         [a_dataSEAPOINTMeanDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
            a_dataSEAPOINTMeanDate(idDrift(idL), 1), ...
            a_dataSEAPOINTMeanDate(idDrift(idL), 2), ...
            a_dataSEAPOINTMeanDate(idDrift(idL), 4:end));
      end
   end
   if (~isempty(a_dataSEAPOINTStdMedDate))
      idDrift = find(a_dataSEAPOINTStdMedDate(:, 3) == g_decArgo_phaseParkDrift);
      for idL = 1:length(idDrift)
         [a_dataSEAPOINTStdMedDate(idDrift(idL), 4:end)] = compute_dates_ir_sbd2(4, ...
            a_dataSEAPOINTStdMedDate(idDrift(idL), 1), ...
            a_dataSEAPOINTStdMedDate(idDrift(idL), 2), ...
            a_dataSEAPOINTStdMedDate(idDrift(idL), 4:end));
      end
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
o_dataOXYMean{4} = a_dataOXYMeanDPhase;
o_dataOXYMean{5} = a_dataOXYMeanTemp;

o_dataOXYStdMed{1} = a_dataOXYStdMedDate;
o_dataOXYStdMed{2} = a_dataOXYStdMedDateTrans;
o_dataOXYStdMed{3} = a_dataOXYStdMedPresMean;
o_dataOXYStdMed{4} = a_dataOXYStdMedDPhaseStd;
o_dataOXYStdMed{5} = a_dataOXYStdMedTempStd;
o_dataOXYStdMed{6} = a_dataOXYStdMedDPhaseMed;
o_dataOXYStdMed{7} = a_dataOXYStdMedTempMed;

o_dataOXY{1} = o_dataOXYMean;
o_dataOXY{2} = o_dataOXYStdMed;

o_dataFLNTUMean{1} = a_dataFLNTUMeanDate;
o_dataFLNTUMean{2} = a_dataFLNTUMeanDateTrans;
o_dataFLNTUMean{3} = a_dataFLNTUMeanPres;
o_dataFLNTUMean{4} = a_dataFLNTUMeanChloro;
o_dataFLNTUMean{5} = a_dataFLNTUMeanTurbi;

o_dataFLNTUStdMed{1} = a_dataFLNTUStdMedDate;
o_dataFLNTUStdMed{2} = a_dataFLNTUStdMedDateTrans;
o_dataFLNTUStdMed{3} = a_dataFLNTUStdMedPresMean;
o_dataFLNTUStdMed{4} = a_dataFLNTUStdMedChloroStd;
o_dataFLNTUStdMed{5} = a_dataFLNTUStdMedTurbiStd;
o_dataFLNTUStdMed{6} = a_dataFLNTUStdMedChloroMed;
o_dataFLNTUStdMed{7} = a_dataFLNTUStdMedTurbiMed;

o_dataFLNTU{1} = o_dataFLNTUMean;
o_dataFLNTU{2} = o_dataFLNTUStdMed;

if (~isempty(a_dataCYCLOPS))
   o_dataCYCLOPSMean{1} = a_dataCYCLOPSMeanDate;
   o_dataCYCLOPSMean{2} = a_dataCYCLOPSMeanDateTrans;
   o_dataCYCLOPSMean{3} = a_dataCYCLOPSMeanPres;
   o_dataCYCLOPSMean{4} = a_dataCYCLOPSMeanChloro;
   
   o_dataCYCLOPSStdMed{1} = a_dataCYCLOPSStdMedDate;
   o_dataCYCLOPSStdMed{2} = a_dataCYCLOPSStdMedDateTrans;
   o_dataCYCLOPSStdMed{3} = a_dataCYCLOPSStdMedPresMean;
   o_dataCYCLOPSStdMed{4} = a_dataCYCLOPSStdMedChloroStd;
   o_dataCYCLOPSStdMed{5} = a_dataCYCLOPSStdMedChloroMed;
   
   o_dataCYCLOPS{1} = o_dataCYCLOPSMean;
   o_dataCYCLOPS{2} = o_dataCYCLOPSStdMed;
end

if (~isempty(a_dataSEAPOINT))
   o_dataSEAPOINTMean{1} = a_dataSEAPOINTMeanDate;
   o_dataSEAPOINTMean{2} = a_dataSEAPOINTMeanDateTrans;
   o_dataSEAPOINTMean{3} = a_dataSEAPOINTMeanPres;
   o_dataSEAPOINTMean{4} = a_dataSEAPOINTMeanTurbi;
   
   o_dataSEAPOINTStdMed{1} = a_dataSEAPOINTStdMedDate;
   o_dataSEAPOINTStdMed{2} = a_dataSEAPOINTStdMedDateTrans;
   o_dataSEAPOINTStdMed{3} = a_dataSEAPOINTStdMedPresMean;
   o_dataSEAPOINTStdMed{4} = a_dataSEAPOINTStdMedTurbiStd;
   o_dataSEAPOINTStdMed{5} = a_dataSEAPOINTStdMedTurbiMed;
   
   o_dataSEAPOINT{1} = o_dataSEAPOINTMean;
   o_dataSEAPOINT{2} = o_dataSEAPOINTStdMed;
end

return
