function ThisColSegment = ColorFromHorPsiTheta01(a1,a2,a3)
%COLORFROMHORPSITHETA01 Legacy color helper. NOT part of the public API.
%   INTERNAL / DEAD CODE: this function is not called anywhere else in this
%   package (including PackingFigureRenderer, which supersedes it with its
%   own categorical color-assignment scheme). It predates PackingFigureRenderer
%   and is kept only for reference; see docs/known-untested.md for the coverage
%   note that flags it as a removal candidate. Do not build new functionality
%   on top of it.
%
%   Historical behavior: maps either a 3-D orientation vector [Hx,Hy,Hz] (3
%   input arguments) or an explicit (phi,theta) pair in radians (2 input
%   arguments) to an RGB color via an HSV colorwheel, so that orientation
%   direction maps to hue and polar angle maps to saturation/value. Returns a
%   neutral gray ([0.5 0.5 0.5]) if the computed HSV triple contains NaN.
if exist('a3')
    
    HxSegment = a1 ;
    HySegment = a2 ;
    HzSegment = a3 ;
%     thisThetaMean = acos(HzSegment./norm([HxSegment,HySegment,HzSegment])) ;
        thisThetaMean = acos(HzSegment./sqrt(HxSegment.^2+HySegment.^2+HzSegment.^2)) ;
    thisPhiMean = atan2(HySegment,HxSegment) ;
    
else
    
    thisPhiMean = a1 ;
    thisThetaMean = a2 ;
end



ThisHSV = [wrapTo2Pi(thisPhiMean+pi)./(2*pi),(thisThetaMean<=pi/2).*(1)+(thisThetaMean>pi/2).*(1-(thisThetaMean-pi/2)/(pi/2))  ,(thisThetaMean<=pi/2).*(thisThetaMean./(pi/2))+(thisThetaMean>pi/2).*(1)] ;
ThisColSegment = hsv2rgb(ThisHSV) ;
% ThisColSegment = hsv2rgb(wrapTo2Pi(thisPhiMean+pi)./(2*pi),(thisThetaMean<=pi/2).*(1)+(thisThetaMean>=pi/2).*(1-(thisThetaMean-pi/2)/(pi/2))  ,(thisThetaMean<=pi/2).*(thisThetaMean./(pi/2))+(thisThetaMean>=pi/2).*(1)) ;
if ~all(~isnan(ThisColSegment))
    ThisColSegment = .5.*[1,1,1] ;
end

'' ;