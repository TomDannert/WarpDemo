{ ****************************************************************************

  Copyright (C) 2019 by Thomas Dannert
  Author: Thomas Dannert <thomas@dannert.com>
  Website: www.dannert.com

  TPathHelper for Delphi Firemonkey is free software:
  you can redistribute it and/or modify it under the terms of
  the GNU Lesser General Public License version 3
  as published by the Free Software Foundation and appearing in the
  included file.

  TPathHelper for Delphi Firemonkey is distributed in the hope
  that it will be useful, but WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public License
  along with Dropbox Client Library. If not, see <http://www.gnu.org/licenses/>.

 **************************************************************************** }


unit Main;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects,
  FMX.StdCtrls, FMX.Controls.Presentation;

type
  TfrmMain = class(TForm)
    PaintBox: TPaintBox;
    SourcePath: TPath;
    ToolBar: TToolBar;
    lblPoints: TLabel;
    procedure PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
    procedure PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
    procedure PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  private
    FPoints      : array[0..3] of TPointF;
    FHandle      : Integer;
    FPerspective : Boolean;
    function HandleRect(const AIndex : Integer) : TRectF;
    function FindHandle(X, Y : Single; var AIndex : Integer) : Boolean;
  public
    constructor Create(AOwner : TComponent); override;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses FMX.PathHelper, System.Math;

constructor TfrmMain.Create(AOwner: TComponent);
var
  P : TPointF;
  R : TRectF;
begin
  inherited Create(AOwner);
  FPerspective := False;
  P := PaintBox.LocalRect.CenterPoint;
  R := SourcePath.Data.GetBounds;
  lblPoints.Text := IntToStr(SourcePath.Data.Count) + ' source points';
  FPoints[0] := PointF(P.X - (R.Width / 2), P.Y - (R.Height / 2));
  FPoints[1] := PointF(P.X + (R.Width / 2), P.Y - (R.Height / 2));
  FPoints[2] := PointF(P.X + (R.Width / 2), P.Y + (R.Height / 2));
  FPoints[3] := PointF(P.X - (R.Width / 2), P.Y + (R.Height / 2));
  FHandle    := -1;
  PaintBox.AutoCapture := True;
end;

function TfrmMain.HandleRect(const AIndex: Integer) : TRectF;
begin
  Result := RectF(FPoints[AIndex].X - 5, FPoints[AIndex].Y - 5, FPoints[AIndex].X + 5, FPoints[AIndex].Y + 5);
end;

function TfrmMain.FindHandle(X, Y : Single; var AIndex : Integer) : Boolean;
var
  I : Integer;
begin
  Result := False;
  for I := Low(FPoints) to High(FPoints) do
  begin
    if HandleRect(I).Contains(PointF(X, Y)) then
    begin
      AIndex := I;
      Result := True;
      Break;
    end;
  end;
end;

procedure TfrmMain.PaintBoxMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
var
  H : Integer;
begin
  if FindHandle(X, Y, H) then
  begin
    FHandle := H;
    PaintBox.Repaint;
  end;
end;

procedure TfrmMain.PaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Single);
var
  H : Integer;
begin
  if FHandle <> -1 then
  begin
    if not FPoints[FHandle].EqualsTo(PointF(X, Y)) then
    begin
      FPoints[FHandle] := PointF(X, Y);
      PaintBox.Repaint;
    end;
    PaintBox.Cursor := crHandpoint;
  end
  else begin
    if FindHandle(X, Y, H) then
    begin
      PaintBox.Cursor := crHandpoint;
    end
    else begin
      PaintBox.Cursor := crDefault;
    end;
  end;
end;

procedure TfrmMain.PaintBoxMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
begin
  if FHandle <> -1 then
  begin
    FHandle := -1;
    PaintBox.Repaint;
  end;
end;

procedure TfrmMain.PaintBoxPaint(Sender: TObject; Canvas: TCanvas);
var
  I : Integer;
  S : Single;
  R : TRectF;
  Path : TPathData;
begin

  Canvas.Fill.Kind := TBrushKind.Solid;
  Canvas.Fill.Color := TAlphaColors.White;
  Canvas.FillRect(PaintBox.LocalRect, 0, 0, [], 1);
  Canvas.Fill.Color := TAlphaColors.Black;
  Canvas.Stroke.Kind := TBrushKind.None;

  //This is the main demo function, warping source path to a destination path with given points
  Path := TPathData.Create;
  try
    SourcePath.Data.WarpTo(Path, FPoints, FPerspective);
    Canvas.FillPath(Path, 1);
  finally
    FreeAndNil(Path);
  end;

  //this is only for demonstrating (paint target rect)
  R := RectF(99999, 99999, -99999, -99999);
  for I := Low(FPoints) to High(FPoints) do
  begin
    R.Left   := Min(FPoints[I].X, R.Left);
    R.Top    := Min(FPoints[I].Y, R.Top);
    R.Right  := Max(FPoints[I].X, R.Right);
    R.Bottom := Max(FPoints[I].Y, R.Bottom);
  end;
  Canvas.Stroke.Kind := TBrushKind.Solid;
  Canvas.Stroke.Color := TAlphaColors.LightGray;
  Canvas.DrawRect(R, 0, 0, [], 1);

  //drawing the handles
  Canvas.Fill.Color := TAlphaColors.Red;
  for I := Low(FPoints) to High(FPoints) do
  begin
    R := HandleRect(I);
    Canvas.FillEllipse(R, 1);
  end;

end;

end.
