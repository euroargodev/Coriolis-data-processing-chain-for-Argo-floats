% ------------------------------------------------------------------------------
% Compute RTQC data for BBP data.
%
% SYNTAX :
% [o_profBbpQc, o_profBbpQcReportPassed, o_profBbpQcReportFailed] = ...
%   add_bbp_rtqc_to_profile_file( ...
%   a_profileDir, a_parkingPres, ...
%   a_profPres, a_profPresQc, a_presFillValue, ...
%   a_profBbp, a_profBbpQc, a_bbpFillValue)
%
% INPUT PARAMETERS :
%   a_profileDir    : profile direction
%   a_parkingPres   : cycle parking pressure
%   a_profPres      : input PRES data
%   a_profPresQc    : input PRES QC data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_profBbpQc     : input BBP QC data
%   a_bbpFillValue  : fill value for input BBP
%
% OUTPUT PARAMETERS :
%   o_profBbpQc             : Qcs of the BBP parameter profile
%   o_profBbpQcReportPassed : code to report passed tests
%   o_profBbpQcReportFailed : code to report failed tests
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profBbpQc, o_profBbpQcReportPassed, o_profBbpQcReportFailed] = ...
   add_bbp_rtqc_to_profile_file( ...
   a_profileDir, a_parkingPres, ...
   a_profPres, a_profPresQc, a_presFillValue, ...
   a_profBbp, a_profBbpQc, a_bbpFillValue)

% output parameters initialization
o_profBbpQc = [];
o_profBbpQcReportPassed = '';
o_profBbpQcReportFailed = '';


if (isempty(a_profBbp))
   return
end

% compute filtered BBP profile
[profPresFilt, profBbpFilt] = apply_median_filter( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_bbpFillValue);

profBbpQc = a_profBbpQc;
testDoneFlag = zeros(1, 5);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test #0: if PRES_QC=4 then BBP_QC=4
% select valid (PRES, BBP) data
% idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
% idToFlag = find(a_profPresQc(idNoDef) == g_decArgo_qcStrBad);
% testDoneFlag(1) = 1;
% if (~isempty(idToFlag))
%    profBbpQc(idNoDef(idToFlag)) = set_qc(profBbpQc(idNoDef(idToFlag)), g_decArgo_qcStrBad);
%    testDoneFlag(1) = 2;
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test #1: Missing-Data test
[profBbpQc, testDoneFlag(1)] = missing_data_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, profBbpQc, a_bbpFillValue);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test #2: High-Deep-Value test
[profBbpQc, testDoneFlag(2)] = high_deep_value_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, profBbpQc, a_bbpFillValue, ...
   profPresFilt, profBbpFilt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test #3: Negative-BBP test
[profBbpQc, testDoneFlag(3)] = negative_bbp_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, profBbpQc, a_bbpFillValue);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test #4: Noisy-Profile test
[profBbpQc, testDoneFlag(4)] = noisy_profile_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, profBbpQc, a_bbpFillValue, ...
   profPresFilt, profBbpFilt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test #5: Parking-Hook test
if ((a_profileDir == 'A') && ~isempty(a_parkingPres))
   [profBbpQc, testDoneFlag(5)] = parking_hook_test(a_parkingPres, ...
      a_profPres, a_presFillValue, ...
      a_profBbp, profBbpQc, a_bbpFillValue);
end

% compute failed tests report value
testPassedFlag = testDoneFlag;
testPassedFlag(testPassedFlag == 2) = 1;
rtqcPassed = num2str(testPassedFlag);
rtqcPassed = regexprep(rtqcPassed, ' ', '');
testFailedFlag = testDoneFlag;
testFailedFlag(testFailedFlag == 1) = 0;
testFailedFlag(testFailedFlag == 2) = 1;
rtqcFailed = num2str(testFailedFlag);
rtqcFailed = regexprep(rtqcFailed, ' ', '');

% if (any(testFailedFlag == 1))
%    fprintf('RTQC_APPLIED %s RTQC_FAILED %s \n', rtqcPassed, rtqcFailed);
% end

% set output data
o_profBbpQc = profBbpQc;
o_profBbpQcReportPassed = rtqcPassed;
o_profBbpQcReportFailed = rtqcFailed;

return

% ------------------------------------------------------------------------------
% Apply parking hook test to input data.
%
% SYNTAX :
% [o_profBbpQc, o_testDoneFlag] = parking_hook_test( ...
%   a_parkingPres, ...
%   a_profPres, a_presFillValue, ...
%   a_profBbp, a_profBbpQc, a_bbpFillValue)
%
% INPUT PARAMETERS :
%   a_parkingPres   : cycle parking pressure
%   a_profPres      : input PRES data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_profBbpQc     : input BBP QC data
%   a_bbpFillValue  : fill value for input BBP
%
% OUTPUT PARAMETERS :
%   o_profBbpQc    : output BBP QC data
%   o_testDoneFlag : 0: not passed, 1: passed, 2:failed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profBbpQc, o_testDoneFlag] = parking_hook_test( ...
   a_parkingPres, ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_profBbpQc, a_bbpFillValue)

% output parameters initialization
o_profBbpQc = a_profBbpQc;
o_testDoneFlag = 0;

% QC flag values
global g_decArgo_qcStrBad;           % '4'

DELTA_PRES0 = 100;
DELTA_PRES1 = 50;
DELTA_PRES2 = 20;
DEV = 0.0002;


% valid levels of the BBP profile
idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
if (~isempty(idNoDef))

   profPres = a_profPres(idNoDef);
   profBbp = a_profBbp(idNoDef);

   idMax = find(profPres == max(profPres), 1, 'last'); % last or first ? TBC
   maxPres = profPres(idMax);

   if (idMax ~= 1)
      if (maxPres - profPres(idMax-1) <= DELTA_PRES2)

         if (abs(maxPres - a_parkingPres) < DELTA_PRES0)

            idFirstPresR = find((profPres < (maxPres - DELTA_PRES2)) & ...
               (profPres >= (maxPres - DELTA_PRES1)));
            if (~isempty(idFirstPresR))
               baseline = median(profBbp(idFirstPresR)) + DEV;

               idSecondPresR = find(profPres >= (maxPres - DELTA_PRES1));
               if (~isempty(idSecondPresR))
                  o_testDoneFlag = 1;
                  idKo = find(profBbp(idSecondPresR) > baseline);
                  if (~isempty(idKo))
                     o_profBbpQc(idNoDef(idSecondPresR(idKo))) = set_qc(o_profBbpQc(idNoDef(idSecondPresR(idKo))), g_decArgo_qcStrBad);
                     o_testDoneFlag = 2;
                  end
               end
            end
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Apply noisy profile test to input data.
%
% SYNTAX :
%  [o_profBbpQc, o_testDoneFlag] = noisy_profile_test( ...
%    a_profPres, a_presFillValue, ...
%    a_profBbp, a_profBbpQc, a_bbpFillValue, ...
%    a_profPresFilt, a_profBbpFilt)
%
% INPUT PARAMETERS :
%   a_profPres      : input PRES data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_profBbpQc     : input BBP QC data
%   a_bbpFillValue  : fill value for input BBP
%   a_profPresFilt  : PRES values of BBP filtered data
%   a_profBbpFilt   : BBP filtered data
%
% OUTPUT PARAMETERS :
%   o_profBbpQc    : output BBP QC data
%   o_testDoneFlag : 0: not passed, 1: passed, 2:failed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profBbpQc, o_testDoneFlag] = noisy_profile_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_profBbpQc, a_bbpFillValue, ...
   a_profPresFilt, a_profBbpFilt)

% output parameters initialization
o_profBbpQc = a_profBbpQc;
o_testDoneFlag = 0;

% QC flag values
global g_decArgo_qcStrCorrectable;   % '3'

MIN_LEVEL_TO_PROCESS = 10;
NOISY_PRES_THRESHOLD = 100;
RES_THRESHOLD = 0.0005;
MAX_PERCENTAGE_OF_OUTLIER = 0.10;


if (isempty(a_profPresFilt))
   return
end

% valid levels of the BBP profile
idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
if (~isempty(idNoDef))

   profPres = a_profPres(idNoDef);
   profBbp = a_profBbp(idNoDef);

   if (length(profPres) > MIN_LEVEL_TO_PROCESS)

      idPresToUse = find(profPres > NOISY_PRES_THRESHOLD);
      if (any(idPresToUse))
         o_testDoneFlag = 1;
         bbpRes = abs(profBbp(idPresToUse) - a_profBbpFilt(idPresToUse));
         if ((length(find(bbpRes > RES_THRESHOLD))/length(idPresToUse)) >= MAX_PERCENTAGE_OF_OUTLIER)
            o_profBbpQc(idNoDef) = set_qc(o_profBbpQc(idNoDef), g_decArgo_qcStrCorrectable);
            o_testDoneFlag = 2;
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Apply negative BBP test to input data.
%
% SYNTAX :
% [o_profBbpQc, o_testDoneFlag] = negative_bbp_test( ...
%   a_profPres, a_presFillValue, ...
%   a_profBbp, a_profBbpQc, a_bbpFillValue)
%
% INPUT PARAMETERS :
%   a_profPres      : input PRES data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_profBbpQc     : input BBP QC data
%   a_bbpFillValue  : fill value for input BBP
%
% OUTPUT PARAMETERS :
%   o_profBbpQc    : output BBP QC data
%   o_testDoneFlag : 0: not passed, 1: passed, 2:failed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profBbpQc, o_testDoneFlag] = negative_bbp_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_profBbpQc, a_bbpFillValue)

% output parameters initialization
o_profBbpQc = a_profBbpQc;
o_testDoneFlag = 0;

% QC flag values
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'

NEGATIVE_PRES_THRESHOLD = 5;
MAX_PERCENTAGE_OF_BAD_POINTS = 0.10;


% valid levels of the BBP profile
idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
if (~isempty(idNoDef))

   o_testDoneFlag = 1;
   profPres = a_profPres(idNoDef);
   profBbp = a_profBbp(idNoDef);

   idLt5 = find(profPres < NEGATIVE_PRES_THRESHOLD);
   idNegValLt5 = find(profBbp(idLt5) < 0);
   idGe5 = find(profPres >= NEGATIVE_PRES_THRESHOLD);
   idNegValGe5 = find(profBbp(idGe5) < 0);

   if (any(idNegValLt5))
      o_profBbpQc(idNoDef(idLt5(idNegValLt5))) = set_qc(o_profBbpQc(idNoDef(idLt5(idNegValLt5))), g_decArgo_qcStrBad);
      o_testDoneFlag = 2;
   end

   if (any(idNegValGe5))
      if ((length(idNegValGe5)/length(idGe5)) > MAX_PERCENTAGE_OF_BAD_POINTS)
         o_profBbpQc(idNoDef) = set_qc(o_profBbpQc(idNoDef), g_decArgo_qcStrBad);
         o_testDoneFlag = 2;
      else
         o_profBbpQc(idNoDef) = set_qc(o_profBbpQc(idNoDef), g_decArgo_qcStrCorrectable);
         o_testDoneFlag = 2;
      end
   end
end

return

% ------------------------------------------------------------------------------
% Apply high deep value test to input data.
%
% SYNTAX :
% [o_profBbpQc, o_testDoneFlag] = high_deep_value_test( ...
%   a_profPres, a_presFillValue, ...
%   a_profBbp, a_profBbpQc, a_bbpFillValue, ...
%   a_profPresFilt, a_profBbpFilt)
%
% INPUT PARAMETERS :
%   a_profPres      : input PRES data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_profBbpQc     : input BBP QC data
%   a_bbpFillValue  : fill value for input BBP
%   a_profPresFilt  : PRES values of BBP filtered data
%   a_profBbpFilt   : BBP filtered data
%
% OUTPUT PARAMETERS :
%   o_profBbpQc    : output BBP QC data
%   o_testDoneFlag : 0: not passed, 1: passed, 2:failed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profBbpQc, o_testDoneFlag] = high_deep_value_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_profBbpQc, a_bbpFillValue, ...
   a_profPresFilt, a_profBbpFilt)

% output parameters initialization
o_profBbpQc = a_profBbpQc;
o_testDoneFlag = 0;

% QC flag values
global g_decArgo_qcStrCorrectable;   % '3'

DEEP_VALUE_PRES_THRESHOLD = 700;
HIGH_DEEP_VALUE_THRESHOLD = 0.0005;
N_OF_ANOM_POINTS_THRESHOLD  = 5;


if (isempty(a_profPresFilt))
   return
end

% valid levels of the BBP profile
idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
if (~isempty(idNoDef))

   idGt700 = find(a_profPresFilt > DEEP_VALUE_PRES_THRESHOLD);
   if (~isempty(idGt700))
      o_testDoneFlag = 1;
      if (length(idGt700) >= N_OF_ANOM_POINTS_THRESHOLD)
         if (median(a_profBbpFilt(idGt700)) > HIGH_DEEP_VALUE_THRESHOLD)
            o_profBbpQc(idNoDef) = set_qc(o_profBbpQc(idNoDef), g_decArgo_qcStrCorrectable);
            o_testDoneFlag = 2;
         end
      end
   end
end

return

% ------------------------------------------------------------------------------
% Apply missing data test to input data.
%
% SYNTAX :
%  [o_profBbpQc, o_testDoneFlag] = missing_data_test( ...
%    a_profPres, a_presFillValue, ...
%    a_profBbp, a_profBbpQc, a_bbpFillValue)
%
% INPUT PARAMETERS :
%   a_profPres      : input PRES data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_profBbpQc     : input BBP QC data
%   a_bbpFillValue  : fill value for input BBP
%
% OUTPUT PARAMETERS :
%   o_profBbpQc    : output BBP QC data
%   o_testDoneFlag : 0: not passed, 1: passed, 2:failed
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profBbpQc, o_testDoneFlag] = missing_data_test( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_profBbpQc, a_bbpFillValue)

% output parameters initialization
o_profBbpQc = a_profBbpQc;
o_testDoneFlag = 0;

% QC flag values
global g_decArgo_qcStrCorrectable;   % '3'
global g_decArgo_qcStrBad;           % '4'
global g_decArgo_qcStrMissing;       % '9'

MIN_N_PER_BIN = 1;


% select valid (PRES, BBP) data
idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
if (~isempty(idNoDef))

   o_testDoneFlag = 1;
   profPres = a_profPres(idNoDef);

   % count the number of BBP measurements in a defined list of bin pressure levels
   presBinThres = [50, 156, 261, 367, 472, 578, 683, 789, 894, 1000];
   presbin = zeros(1, length(presBinThres));
   for idB = 1:length(presBinThres)
      if (idB == 1)
         presbin(idB) = length(find(profPres < presBinThres(idB)));
      else
         presbin(idB) = length(find((profPres >= presBinThres(idB-1)) & (profPres < presBinThres(idB))));
      end
   end

   % set QC values
   if (any(presbin < MIN_N_PER_BIN) && (length(find(presbin > MIN_N_PER_BIN)) > 1)) % some (more than one) but not all bins have more than MIN_N_PER_BIN points
      o_profBbpQc(idNoDef) = set_qc(o_profBbpQc(idNoDef), g_decArgo_qcStrCorrectable);
      o_testDoneFlag = 2;
   elseif (length(find(presbin > MIN_N_PER_BIN)) == 1) % only one bin has more than MIN_N_PER_BIN points
      o_profBbpQc(idNoDef) = set_qc(o_profBbpQc(idNoDef), g_decArgo_qcStrBad);
      o_testDoneFlag = 2;
   end
   if (all(presbin == 0))
      idToFlag = find(profPres < presBinThres(end));
      o_profBbpQc(idNoDef(idToFlag)) = set_qc(o_profBbpQc(idNoDef(idToFlag)), g_decArgo_qcStrMissing);
   end
end

return

% ------------------------------------------------------------------------------
% Compute adaptative median filter of a set of BBP values.
%
% SYNTAX :
%  [o_profPresFilt, o_profBbpFilt] = apply_median_filter( ...
%    a_profPres, a_presFillValue, ...
%    a_profBbp, a_bbpFillValue)
%
% INPUT PARAMETERS :
%   a_profPres      : input PRES data
%   a_presFillValue : fill value for input PRES
%   a_profBbp       : input BBP data
%   a_bbpFillValue  : fill value for input BBP
%
% OUTPUT PARAMETERS :
%   o_profPresFilt : pressures of filtered BBP data
%   o_profBbpFilt  : filtered BBP data
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_profPresFilt, o_profBbpFilt] = apply_median_filter( ...
   a_profPres, a_presFillValue, ...
   a_profBbp, a_bbpFillValue)

% output parameters initialization
o_profPresFilt = [];
o_profBbpFilt = [];


% valid levels of the BBP profile
idNoDef = find((a_profPres ~= a_presFillValue) & (a_profBbp ~= a_bbpFillValue));
if (~isempty(idNoDef))

   profPres = a_profPres(idNoDef);
   profBbp = a_profBbp(idNoDef);

   o_profPresFilt = profPres;
   o_profBbpFilt = median_filter(profBbp, 11);

end

return

% ------------------------------------------------------------------------------
% Compute median values of a set of data.
%
% SYNTAX :
%  [o_bbpFiltVal] = median_filter(a_bbpVal, a_size)
%
% INPUT PARAMETERS :
%   a_bbpVal : input set of values
%   a_size   : size of the median filter
%
% OUTPUT PARAMETERS :
%   o_bbpFiltVal : median values
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   11/15/2022 - RNU - creation
% ------------------------------------------------------------------------------
function [o_bbpFiltVal] = median_filter(a_bbpVal, a_size)

% output parameters initialization
o_bbpFiltVal = nan(size(a_bbpVal));


halfSize = fix(a_size/2);
for id = 1:length(a_bbpVal)
   id1 = max(1, id-halfSize);
   id2 = min(length(a_bbpVal), id+halfSize);
   o_bbpFiltVal(id) = median(a_bbpVal(id1:id2));
end

return
