% ------------------------------------------------------------------------------
% Compute the JAMSTEC QC test for a surface trajectory.
% (see Nakamura et al (2008), “Quality control method of Argo float position
%  data”, JAMSTEC Report of Research and Development, Vol. 7, 11-18).
%
% SYNTAX :
%  [o_argosLocQc] = compute_jamstec_qc( ...
%    a_argosLocDate, a_argosLocLon, a_argosLocLat, a_argosLocAcc, ...
%    a_lastLocDateOfPrevCycle, a_lastLocLonOfPrevCycle, a_lastLocLatOfPrevCycle, a_fidOut)
%
% INPUT PARAMETERS :
%   a_argosLocDate           : surface location dates
%   a_argosLocLon            : surface location longitudes
%   a_argosLocLat            : surface location latitudes
%   a_argosLocAcc            : surface location accuracies (Argos classes)
%   a_lastLocDateOfPrevCycle : last surface location date of the previous cycle
%   a_lastLocLonOfPrevCycle  : last surface location longitude of the previous
%                              cycle
%   a_lastLocLatOfPrevCycle  : last surface location latitude of the previous
%                              cycle
%   a_fidOut                 : output file Id (only for debugging purposes)
%
% OUTPUT PARAMETERS :
%   o_argosLocQc : associated QCs
%
% EXAMPLES :
%
% SEE ALSO :
% AUTHORS  : Jean-Philippe Rannou (Altran)(jean-philippe.rannou@altran.com)
% ------------------------------------------------------------------------------
% RELEASES :
%   12/11/2012 - RNU - creation
% ------------------------------------------------------------------------------
function [o_argosLocQc] = compute_jamstec_qc( ...
   a_argosLocDate, a_argosLocLon, a_argosLocLat, a_argosLocAcc, ...
   a_lastLocDateOfPrevCycle, a_lastLocLonOfPrevCycle, a_lastLocLatOfPrevCycle, a_fidOut)

% output parameters initialization
o_argosLocQc = [];

% current float WMO number
global g_decArgo_floatNum;

% current cycle number
global g_decArgo_cycleNum;

% default values
global g_decArgo_dateDef;


% maximal surface velocity (m/s)
MAX_VEL = 3;

% convert Argos classes into numerical values
posAccNum = ones(length(a_argosLocDate), 1)*-1;
posAccNum(find(a_argosLocAcc == 'G')) = 1;
posAccNum(find(a_argosLocAcc == '3')) = 2;
posAccNum(find(a_argosLocAcc == '2')) = 3;
posAccNum(find(a_argosLocAcc == '1')) = 4;
posAccNum(find(a_argosLocAcc == '0')) = 5;
posAccNum(find(a_argosLocAcc == 'A')) = 6;
posAccNum(find(a_argosLocAcc == 'B')) = 7;
posAccNum(find(a_argosLocAcc == 'Z')) = 8;

% provide a precision for each Argos class (in m)
% provided by Argos
precision(4) = 1000;
precision(3) = 350;
precision(2) = 150;
% arbitrarily chosen
precision(5) = 1500;
precision(6) = 1501;
precision(7) = 1502;
precision(8) = 1503;

% provide a precision for a GPS class (in m)
precision(1) = 30;

% sort the Argos locations
[date, idSort] = sort(a_argosLocDate);
longitude = a_argosLocLon(idSort);
latitude = a_argosLocLat(idSort);
posAccStr = a_argosLocAcc(idSort);
posAccNum = posAccNum(idSort);
flag = ones(length(date), 1);
order = 1:length(date);

driftSpeed = ones(length(date), 1)*-1;
driftDst = ones(length(date), 1)*-1;
distErr = ones(length(date), 1)*-1;

n = 1;
m = 1;

while (1)

   flagged = -9;
   exeptid = 0;
   maxSpeed = 0;
   maxId = 0;
   distSum = 0;
   
   distance = ones(length(date), 1)*-1;
   deltaTime = ones(length(date), 1)*-1;
   speed = ones(length(date), 1)*-1;
   
   % calculation of subsurface drift speed
   if ((a_lastLocDateOfPrevCycle ~= g_decArgo_dateDef) && (length(order) > 0))
      distance(order(1)) = distance_lpo([a_lastLocLatOfPrevCycle latitude(order(1))], ...
         [a_lastLocLonOfPrevCycle longitude(order(1))]);
      deltaTime(order(1)) = abs(date(order(1)) - a_lastLocDateOfPrevCycle);
      speed(order(1)) = distance(order(1))/(deltaTime(order(1))*86400);
      if (m == 1)
         driftSpeed(order(1)) = speed(order(1));
         driftDst(order(1)) = distance(order(1))/1000;
      elseif (speed(order(1)) > MAX_VEL)
         flag(order(1)) = 4;
         order(1) = [];
         m = m + 1;
         continue
      end
   elseif (isempty(order))
      if (~isempty(a_fidOut))
         fprintf(a_fidOut, ' %d ---- ---- .. no data\n', n);
      end
      break
   end
   
   % calculation of surface drift speed
   for ii = 2:length(order)
      im1 = order(ii-1);
      i0 = order(ii);
      distance(i0) = distance_lpo([latitude(im1) latitude(i0)], [longitude(im1) longitude(i0)]);
      distSum = distSum + distance(i0);
      deltaTime(i0) = date(i0) - date(im1);
      if (deltaTime(i0) < 1/86400)
         deltaTime(i0) = 1/86400;
      end
      speed(i0) = distance(i0)/(deltaTime(i0)*86400);
      
      if (m == 1)
         driftSpeed(i0) = speed(i0);
         driftDst(i0) = distance(i0)/1000;
      else
         % deletion of duplicated data
         if ((latitude(im1) == latitude(i0)) && (longitude(im1) == longitude(i0)) && ...
               ((date(i0) == date(im1))))
            flag(i0) = 4;
            exeptid = exeptid + 1;
         elseif (deltaTime(i0) > 1)
            % deletion of another cycle data
            flag(i0) = 4;
            exeptid = exeptid + 1;
         end
      end
      
      if (flag(i0) == 1)
         speed(i0) = abs(speed(i0));
         if (speed(i0) > maxSpeed)
            maxSpeed = speed(i0);
            maxId = ii - exeptid;
         end
      end
   end
   
   if ((exeptid > 0) || (m == 1))
      idDel = find(flag(order) == 4);
      order(idDel) = [];
      if (isempty(order))
         if (~isempty(a_fidOut))
            fprintf(a_fidOut, ' %d ---- ---- .. no data\n', n);
         end
         break
      end
      m = m + 1;
      continue
   end
   
   if (length(order) == 1)
      maxSpeed = speed(order(1));
      avgSpeed = speed(order(1));
   else
      avgSpeed = distSum/((date(order(end)) - date(order(1)))*86400);
   end
   
   if (~isempty(a_fidOut))
      fprintf(a_fidOut, '%2d %4.2f %4.2f ..%3dpoints\n', n, avgSpeed, maxSpeed, length(order));
   end
   
   % discrimination of abnormal position
   if (maxSpeed > MAX_VEL)
      posAcc0 = posAccNum(order(maxId-1));
      posAcc1 = posAccNum(order(maxId));
      prec0 = precision(posAcc0);
      prec1 = precision(posAcc1);
      
      % case of another Argos class
      if (posAcc0 ~= posAcc1)
         if (posAcc0 > posAcc1)
            flagged = maxId - 1;
         else
            flagged = maxId;
         end
      else
         % case of same Argos class
         
         if (length(order) == 2)
            % 2 points at same cycle
            
         elseif (length(order) == 3)
            % 3 points at same cycle
            
            if (maxId == 2)
               ip1 = order(maxId+1);
               im1 = order(maxId-1);
               i0 = order(maxId);
               distanceF = distance_lpo([latitude(i0) latitude(ip1)], [longitude(i0) longitude(ip1)]);
               deltaTimeF = date(ip1) - date(i0);
               distanceL = distance_lpo([latitude(im1) latitude(ip1)], [longitude(im1) longitude(ip1)]);
               deltaTimeL = date(ip1) - date(im1);
            else % maxId == 3
               im1 = order(maxId-1);
               im2 = order(maxId-2);
               i0 = order(maxId);
               distanceF = distance_lpo([latitude(im2) latitude(i0)], [longitude(im2) longitude(i0)]);
               deltaTimeF = date(i0) - date(im2);
               distanceL = distance_lpo([latitude(im2) latitude(im1)], [longitude(im2) longitude(im1)]);
               deltaTimeL = date(im1) - date(im2);
            end
            
            spdF = distanceF/(deltaTimeF*86400);
            spdL = distanceL/(deltaTimeL*86400);
            if (spdF > spdL)
               flagged = maxId;
            else
               flagged = maxId - 1;
            end
            
         elseif (length(order) > 3)
            % 4 points or more at same cycle
            
            if (maxId == 2) % maxspeed is the first section
               ip2 = order(maxId+2);
               ip1 = order(maxId+1);
               distance1F = distance_lpo([latitude(ip1) latitude(ip2)], [longitude(ip1) longitude(ip2)]);
               deltaTime1F = date(ip2) - date(ip1);
               distance1L = distance1F;
               deltaTime1L = deltaTime1F;
            elseif (maxId > 2)
               im1 = order(maxId-1);
               im2 = order(maxId-2);
               i0 = order(maxId);
               distance1F = distance_lpo([latitude(im2) latitude(i0)], [longitude(im2) longitude(i0)]);
               deltaTime1F = date(i0) - date(im2);
               distance1L = distance_lpo([latitude(im2) latitude(im1)], [longitude(im2) longitude(im1)]);
               deltaTime1L = date(im1) - date(im2);
            else
               fprintf('DEC_ERROR: Float #%d Cycle #%d: maxId error! maxId = %d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  maxId);
               return
            end
            
            if (maxId == length(order)) % maxspeed is the end section
               im3 = order(maxId-3);
               im2 = order(maxId-2);
               distance2F = distance_lpo([latitude(im3) latitude(im2)], [longitude(im3) longitude(im2)]);
               deltaTime2F = date(im2) - date(im3);
               distance2L = distance2F;
               deltaTime2L = deltaTime2F;
            elseif (maxId < length(order))
               im1 = order(maxId-1);
               i0 = order(maxId);
               ip1 = order(maxId+1);
               distance2F = distance_lpo([latitude(i0) latitude(ip1)], [longitude(i0) longitude(ip1)]);
               deltaTime2F = date(ip1) - date(i0);
               distance2L = distance_lpo([latitude(im1) latitude(ip1)], [longitude(im1) longitude(ip1)]);
               deltaTime2L = date(ip1) - date(im1);
            else
               fprintf('DEC_ERROR: Float #%d Cycle #%d: maxId error! maxId = %d\n', ...
                  g_decArgo_floatNum, ...
                  g_decArgo_cycleNum, ...
                  maxId);
               return
            end
            
            % comparing speeds of 2 routes
            spdF = (distance1F + distance2F)/((deltaTime1F + deltaTime2F)*86400);
            spdL = (distance1L + distance2L)/((deltaTime1L + deltaTime2L)*86400);
            if (spdF > spdL)
               flagged = maxId;
            else
               flagged = maxId - 1;
            end
         end
      end
      
      % calculation of distance error
      dderr = 1*sqrt(prec0*prec0 + prec1*prec1);
      distErr(order(maxId)) = dderr/1000;
      
      % flagging at abnormal point
      if (distance(order(maxId)) >= dderr)
         if (length(order) == 2)
            flag(order(maxId-1)) = 3;
            flag(order(maxId)) = 3;
         else
            flag(order(flagged)) = 3;
         end
      end
      if (length(order) == 2)
         break
      end
      
      order(flagged) = [];
   end
   
   if (flagged < 0)
      break
   end
   
   n = n + 1;
   m = m + 1;
end

if (~isempty(a_fidOut))
   if (~isempty(date))
      fprintf(a_fidOut, '   Lat    Lon     Date       Time    cls new    speed  dist(km) distErr\n');
      for idP = 1:length(date)
         driftSpeedStr = [];
         if (driftSpeed(idP) ~= -1)
            driftSpeedStr = sprintf('%7.2f', driftSpeed(idP));
         end
         driftDstStr = [];
         if (driftDst(idP) ~= -1)
            driftDstStr = sprintf('%7.3f', driftDst(idP));
         end
         distErrStr = [];
         if (distErr(idP) ~= -1)
            distErrStr = sprintf('%5.3f', distErr(idP));
         end
         
         fprintf(a_fidOut, ' %5.3f  %6.3f %19s %3s %3s  %8s %8s %6s\n', ...
            latitude(idP), longitude(idP), ...
            julian_2_gregorian_dec_argo(date(idP)), ...
            posAccStr(idP), num2str(flag(idP)), ...
            driftSpeedStr, driftDstStr, distErrStr);
      end
   end
end

% output parameters
o_argosLocQc = num2str(flag)';

return
