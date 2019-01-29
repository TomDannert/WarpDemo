unit FMX.PathHelper;

{ *****************************************************************************
Copyright (C) 2019 by Thomas Dannert
Author: Thomas Dannert <thomas@dannert.com>
Website: www.dannert.com
TPathHelper for Delphi Firemonkey is free software: you can redistribute it
and/or modify it under the terms of the GNU Lesser General Public License
version 3as published by the Free Software Foundation and appearing in the
included file.
TPathHelper for Delphi Firemonkey is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.
You should have received a copy of the GNU Lesser General Public License
along with Dropbox Client Library. If not, see <http://www.gnu.org/licenses.
****************************************************************************** }


interface

uses System.Types, System.UITypes, FMX.Graphics;

type

  { ************************************************************************** }
  { TPathHelper }
  { ************************************************************************** }

  TPathHelper = class Helper for TPathData
    function WarpTo(const APath: TPathData; ADestPoints : array of TPointF; APerspective : Boolean = False) : Boolean;
  end;

implementation

uses System.Math;

{ **************************************************************************** }
{ TPathHelper }
{ **************************************************************************** }

{ TPathHelper.WarpTo() ------------------------------------------------------- }
{   APath: Destination Path                                                    }
{   ADestPoints: [topleft, topright, bottomright, bottomleft]                  }
{   APerspective: True = Perspective warp, False = Bilinear warp               }
{ -----------------------------------------------------------------------------}
{ Result: False = invalid number of destpoints or path is empty                }
{ -----------------------------------------------------------------------------}

function TPathHelper.WarpTo(const APath: TPathData; ADestPoints: array of TPointF; APerspective : Boolean = False) : Boolean;
var
  I : Integer;
  P1, P2, P3 : TPointF;
  Center : TPointF;
  SrcRect : TRectF;
  DstRect : TRectF;
  XScale, YScale : Single;
  x, y, xy, px, qx, rx, py, qy, ry, num : Extended;
  c1, c0, a1, a0, a2, b1, b0, b2, a3, b3 : Extended;

  function TransformPoint(APoint : TPointF) : TPointF;
  begin
    x := (APoint.X - Center.X) * XScale;
    y := (APoint.Y - Center.Y) * YScale;
    if APerspective then
    begin
      num := c0 * x + c1 * y + 1.0;
      Result.X := (a0 + a1 * x + a2 * y) / num;
      Result.Y := (b0 + b1 * x + b2 * y) / num;
     end
     else begin
       xy := x * y;
       Result.X := a0 + a1 * xy + a2 * x + a3 * y;
       Result.Y := b0 + b1 * xy + b2 * x + b3 * y;
     end;
  end;

begin

  Result  := False;
  if IsEmpty or (Length(ADestPoints) <> 4) then Exit;

  Result  := True;
  SrcRect := GetBounds;
  Center  := PointF(SrcRect.Left + SrcRect.Width / 2.0, SrcRect.Top + SrcRect.Height / 2.0);
  XScale  := (2.0 / SrcRect.Width);
  YScale  := (2.0 / SrcRect.Height);

  //calculation of the base values for the transformation

  if APerspective then //perspective warp
  begin
    px := ADestPoints[0].X + ADestPoints[1].X - ADestPoints[3].X - ADestPoints[2].X;
    qx := ADestPoints[0].X - ADestPoints[1].X + ADestPoints[3].X - ADestPoints[2].X;
    rx := ADestPoints[0].X - ADestPoints[1].X - ADestPoints[3].X + ADestPoints[2].X;
    py := ADestPoints[0].Y + ADestPoints[1].Y - ADestPoints[3].Y - ADestPoints[2].Y;
    qy := ADestPoints[0].Y - ADestPoints[1].Y + ADestPoints[3].Y - ADestPoints[2].Y;
    ry := ADestPoints[0].Y - ADestPoints[1].Y - ADestPoints[3].Y + ADestPoints[2].Y;
    num := px * qy - qx * py;
    if num = 0 then num := 0.00000001; //avoid divison by zero
    if px = 0 then px := 0.0000001; //avoid divison by zero
    c1 := (px * ry - rx * py) / num;
    c0 := (rx - qx * c1) / px;
    a1 := ((ADestPoints[0].X + ADestPoints[1].X) * c0 + (ADestPoints[0].X - ADestPoints[1].X) * (c1 - 1.0)) / 2.0;
    a0 := ((ADestPoints[1].X + ADestPoints[2].X) * (c0 + 1.0) + (- ADestPoints[1].X + ADestPoints[2].X) * c1) / 2.0 - a1;
    a2 := ((- ADestPoints[3].X + ADestPoints[2].X) * c0 + (ADestPoints[3].X + ADestPoints[2].X) * (c1 + 1.0)) / 2.0 - a0;
    b1 := ((ADestPoints[0].Y + ADestPoints[1].Y) * c0 + (ADestPoints[0].Y - ADestPoints[1].Y) * (c1 - 1.0)) / 2.0;
    b0 := ((ADestPoints[1].Y + ADestPoints[2].Y) * (c0 + 1.0) + (- ADestPoints[1].Y + ADestPoints[2].Y) * c1) / 2.0 - b1;
    b2 := ((- ADestPoints[3].Y + ADestPoints[2].Y) * c0 + (ADestPoints[3].Y + ADestPoints[2].Y) * (c1 + 1.0)) / 2.0 - b0;
  end
  else begin  //bilinear warp
    a0 := (  ADestPoints[0].X + ADestPoints[1].X + ADestPoints[3].X + ADestPoints[2].X) / 4.0;
    a1 := (  ADestPoints[0].X - ADestPoints[1].X - ADestPoints[3].X + ADestPoints[2].X) / 4.0;
    a2 := (- ADestPoints[0].X + ADestPoints[1].X - ADestPoints[3].X + ADestPoints[2].X) / 4.0;
    a3 := (- ADestPoints[0].X - ADestPoints[1].X + ADestPoints[3].X + ADestPoints[2].X) / 4.0;
    b0 := (  ADestPoints[0].Y + ADestPoints[1].Y + ADestPoints[3].Y + ADestPoints[2].Y) / 4.0;
    b1 := (  ADestPoints[0].Y - ADestPoints[1].Y - ADestPoints[3].Y + ADestPoints[2].Y) / 4.0;
    b2 := (- ADestPoints[0].Y + ADestPoints[1].Y - ADestPoints[3].Y + ADestPoints[2].Y) / 4.0;
    b3 := (- ADestPoints[0].Y - ADestPoints[1].Y + ADestPoints[3].Y + ADestPoints[2].Y) / 4.0;
  end;

  //create new path and transform points

  APath.Clear;
  I := 0;
  while I <= Count - 1 do
  begin
    case Points[I].Kind of
      TPathPointKind.MoveTo:
      begin
        P1 := TransformPoint(Points[I].Point);
        APath.MoveTo(P1);
        Inc(I);
      end;
      TPathPointKind.LineTo:
      begin
        P1 := TransformPoint(Points[I].Point);
        APath.LineTo(P1);
        Inc(I);
      end;
      TPathPointKind.CurveTo:
      begin
        P1 := TransformPoint(Points[I].Point);
        Inc(I);
        P2 := TransformPoint(Points[I].Point);
        Inc(I);
        P3 := TransformPoint(Points[I].Point);
        Inc(I);
        APath.CurveTo(P1, P2, P3);
      end;
      TPathPointKind.Close:
      begin
        APath.ClosePath;
        Inc(I);
      end;
    end;
  end;

  //calculate the destination rect

  DstRect := RectF(99999, 99999, -99999, -99999);
  for I := Low(ADestPoints) to High(ADestPoints) do
  begin
    DstRect.Left   := Min(ADestPoints[I].X, DstRect.Left);
    DstRect.Top    := Min(ADestPoints[I].Y, DstRect.Top);
    DstRect.Right  := Max(ADestPoints[I].X, DstRect.Right);
    DstRect.Bottom := Max(ADestPoints[I].Y, DstRect.Bottom);
  end;

  //finally fit to destination rect

  APath.FitToRect(DstRect);

end;


end.
