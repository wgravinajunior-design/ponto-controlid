unit uSkiaButtons;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.Types,
  System.UITypes, Vcl.Controls, Vcl.Graphics, System.Skia, Vcl.Skia;

type
  TSkButtonKind = (sbkDefault, sbkPrimary, sbkSuccess, sbkDanger, sbkWarning, sbkTeal, sbkDark, sbkPurple);

  TSkModernButton = class(TSkCustomControl)
  private
    FCaption: string;
    FEmoji: string;
    FKind: TSkButtonKind;
    FIsHovered: Boolean;
    FIsPressed: Boolean;
    FRadius: Single;
    FFontSize: Single;
    FEmojiSize: Single;
    procedure SetCaption(const AValue: string);
    procedure SetEmoji(const AValue: string);
    procedure SetKind(const AValue: TSkButtonKind);
    procedure SetRadius(const AValue: Single);
    procedure SetFontSize(const AValue: Single);
    procedure SetEmojiSize(const AValue: Single);
  protected
    procedure Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single); override;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Action;
    property Align;
    property Anchors;
    property Caption: string read FCaption write SetCaption;
    property Cursor default crHandPoint;
    property Emoji: string read FEmoji write SetEmoji;
    property EmojiSize: Single read FEmojiSize write SetEmojiSize;
    property Enabled;
    property Font;
    property FontSize: Single read FFontSize write SetFontSize;
    property Height;
    property Hint;
    property Kind: TSkButtonKind read FKind write SetKind default sbkDefault;
    property Left;
    property Radius: Single read FRadius write SetRadius;
    property ShowHint;
    property Top;
    property Visible;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure SepararEmoji(const AFullCaption: string; out AEmoji, AText: string);

implementation

procedure SepararEmoji(const AFullCaption: string; out AEmoji, AText: string);
var
  SpaceIdx, I: Integer;
  HasEmoji: Boolean;
begin
  AEmoji := '';
  AText := AFullCaption;
  if AFullCaption = '' then
    Exit;

  HasEmoji := False;
  for I := 1 to Length(AFullCaption) do
  begin
    if AFullCaption[I] = ' ' then
    begin
      SpaceIdx := I;
      if HasEmoji and (SpaceIdx > 1) and (SpaceIdx <= 8) then
      begin
        AEmoji := Trim(Copy(AFullCaption, 1, SpaceIdx - 1));
        AText := Trim(Copy(AFullCaption, SpaceIdx + 1, MaxInt));
        Exit;
      end
      else
        Break;
    end
    else if Ord(AFullCaption[I]) > 127 then
      HasEmoji := True;
  end;
end;

constructor TSkModernButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Cursor := crHandPoint;
  FRadius := 10;
  FFontSize := 11.0;
  FEmojiSize := 16.0;
  FKind := sbkDefault;
  Width := 145;
  Height := 38;
end;

procedure TSkModernButton.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then
  begin
    FCaption := AValue;
    Redraw;
  end;
end;

procedure TSkModernButton.SetEmoji(const AValue: string);
begin
  if FEmoji <> AValue then
  begin
    FEmoji := AValue;
    Redraw;
  end;
end;

procedure TSkModernButton.SetKind(const AValue: TSkButtonKind);
begin
  if FKind <> AValue then
  begin
    FKind := AValue;
    Redraw;
  end;
end;

procedure TSkModernButton.SetRadius(const AValue: Single);
begin
  if FRadius <> AValue then
  begin
    FRadius := AValue;
    Redraw;
  end;
end;

procedure TSkModernButton.SetFontSize(const AValue: Single);
begin
  if FFontSize <> AValue then
  begin
    FFontSize := AValue;
    Redraw;
  end;
end;

procedure TSkModernButton.SetEmojiSize(const AValue: Single);
begin
  if FEmojiSize <> AValue then
  begin
    FEmojiSize := AValue;
    Redraw;
  end;
end;

procedure TSkModernButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FIsHovered := True;
  Redraw;
end;

procedure TSkModernButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FIsHovered := False;
  FIsPressed := False;
  Redraw;
end;

procedure TSkModernButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    FIsPressed := True;
    Redraw;
  end;
end;

procedure TSkModernButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FIsPressed then
  begin
    FIsPressed := False;
    Redraw;
  end;
end;

procedure TSkModernButton.Draw(const ACanvas: ISkCanvas; const ADest: TRectF; const AOpacity: Single);
var
  LPaint: ISkPaint;
  LBgColorTop, LBgColorBottom, LBorderColor, LTextColor, LShadowColor: TAlphaColor;
  R, ShadowR, HighlightR: TRectF;
  LEmoji, LText: string;
  LEmojiBuilder, LTextBuilder: ISkParagraphBuilder;
  LEmojiPara, LTextPara: ISkParagraph;
  LEmojiStyle, LTextStyle: ISkTextStyle;
  LEmojiParaStyle, LTextParaStyle: ISkParagraphStyle;
  LEmojiW, LEmojiH, LTextW, LTextH, TotalW, Gap, StartX, EmojiX, EmojiY, TextX, TextY: Single;
  LFontFamilies: TArray<string>;
begin
  inherited;

  // Paleta de cores moderna, super vibrante e com alto contraste
  case FKind of
    sbkPrimary: // Azul Elétrico / Royal
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF1D4ED8;
        LBgColorBottom := $FF1E40AF;
        LBorderColor := $FF3B82F6;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF60A5FA;
        LBgColorBottom := $FF2563EB;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $602563EB;
      end
      else
      begin
        LBgColorTop := $FF3B82F6;
        LBgColorBottom := $FF1D4ED8;
        LBorderColor := $FFA4CAFE;
        LShadowColor := $451D4ED8;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkTeal: // Turquesa / Ciano Oceânico
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF0D9488;
        LBgColorBottom := $FF0F766E;
        LBorderColor := $FF14B8A6;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF22D3EE;
        LBgColorBottom := $FF06B6D4;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $6006B6D4;
      end
      else
      begin
        LBgColorTop := $FF06B6D4;
        LBgColorBottom := $FF0D9488;
        LBorderColor := $FF67E8F9;
        LShadowColor := $450E7490;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkSuccess: // Verde Esmeralda Elétrico
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF059669;
        LBgColorBottom := $FF047857;
        LBorderColor := $FF10B981;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF34D399;
        LBgColorBottom := $FF10B981;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $60059669;
      end
      else
      begin
        LBgColorTop := $FF10B981;
        LBgColorBottom := $FF059669;
        LBorderColor := $FF6EE7B7;
        LShadowColor := $45047857;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkDanger: // Vermelho Coral / Ruby Vibrante
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FFE11D48;
        LBgColorBottom := $FFBE123C;
        LBorderColor := $FFF43F5E;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFFB7185;
        LBgColorBottom := $FFF43F5E;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $60E11D48;
      end
      else
      begin
        LBgColorTop := $FFF43F5E;
        LBgColorBottom := $FFE11D48;
        LBorderColor := $FFFCA5A5;
        LShadowColor := $45BE123C;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkWarning: // Âmbar Dourado / Solar
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FFD97706;
        LBgColorBottom := $FFB45309;
        LBorderColor := $FFF59E0B;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFFBBF24;
        LBgColorBottom := $FFF59E0B;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $60D97706;
      end
      else
      begin
        LBgColorTop := $FFF59E0B;
        LBgColorBottom := $FFD97706;
        LBorderColor := $FFFDE047;
        LShadowColor := $45B45309;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkPurple: // Violeta / Roxo Nobre
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF7C3AED;
        LBgColorBottom := $FF6D28D9;
        LBorderColor := $FF8B5CF6;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFA78BFA;
        LBgColorBottom := $FF7C3AED;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $607C3AED;
      end
      else
      begin
        LBgColorTop := $FF8B5CF6;
        LBgColorBottom := $FF6D28D9;
        LBorderColor := $FFC4B5FD;
        LShadowColor := $455B21B6;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkDark: // Grafite / Slate Claro e Nítido
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF334155;
        LBgColorBottom := $FF1E293B;
        LBorderColor := $FF475569;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF64748B;
        LBgColorBottom := $FF475569;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $601E293B;
      end
      else
      begin
        LBgColorTop := $FF475569;
        LBgColorBottom := $FF334155;
        LBorderColor := $FFCBD5E1;
        LShadowColor := $400F172A;
      end;
      LTextColor := TAlphaColors.White;
    end;

    else // sbkDefault
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FFE2E8F0;
        LBgColorBottom := $FFCBD5E1;
        LBorderColor := $FF64748B;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFFFFFFF;
        LBgColorBottom := $FFE2E8F0;
        LBorderColor := $FF94A3B8;
        LShadowColor := $25000000;
      end
      else
      begin
        LBgColorTop := $FFFFFFFF;
        LBgColorBottom := $FFF1F5F9;
        LBorderColor := $FFCBD5E1;
        LShadowColor := $15000000;
      end;
      LTextColor := $FF0F172A;
    end;
  end;

  R := ADest;
  R.Inflate(-1, -1);

  LPaint := TSkPaint.Create;
  LPaint.AntiAlias := True;

  // 1. Sombra física suave e elevada
  if (not FIsPressed) and (LShadowColor <> TAlphaColors.Null) then
  begin
    ShadowR := R;
    if FIsHovered then
      ShadowR.Offset(0, 3.0)
    else
      ShadowR.Offset(0, 2.0);
    LPaint.Color := LShadowColor;
    LPaint.Style := TSkPaintStyle.Fill;
    ACanvas.DrawRoundRect(ShadowR, FRadius, FRadius, LPaint);
  end;

  // 2. Fundo com Gradiente Linear Vertical Vibrante
  LPaint.Shader := TSkShader.MakeGradientLinear(
    PointF(R.Left, R.Top),
    PointF(R.Left, R.Bottom),
    LBgColorTop,
    LBgColorBottom
  );
  LPaint.Style := TSkPaintStyle.Fill;
  ACanvas.DrawRoundRect(R, FRadius, FRadius, LPaint);
  LPaint.Shader := nil;

  // 3. Brilho no topo interior (Efeito de acabamento e profundidade)
  if (not FIsPressed) and (FKind <> sbkDefault) then
  begin
    HighlightR := R;
    HighlightR.Inflate(-1, -1);
    LPaint.Color := $30FFFFFF;
    LPaint.Style := TSkPaintStyle.Stroke;
    LPaint.StrokeWidth := 1.0;
    ACanvas.DrawRoundRect(HighlightR, FRadius - 1, FRadius - 1, LPaint);
  end;

  // 4. Borda Nítida e Elegante
  if LBorderColor <> TAlphaColors.Null then
  begin
    LPaint.Color := LBorderColor;
    LPaint.Style := TSkPaintStyle.Stroke;
    if FIsHovered then
      LPaint.StrokeWidth := 2.0
    else
      LPaint.StrokeWidth := 1.3;
    ACanvas.DrawRoundRect(R, FRadius, FRadius, LPaint);
  end;

  // 5. Renderização do Emoji e Texto em Alta Resolução (Independentes e Alinhados)
  if (FCaption <> '') or (FEmoji <> '') then
  begin
    if FEmoji <> '' then
    begin
      LEmoji := FEmoji;
      LText := FCaption;
    end
    else
      SepararEmoji(FCaption, LEmoji, LText);

    LEmojiW := 0;
    LEmojiH := 0;
    LTextW := 0;
    LTextH := 0;

    // Emoji em alta definição
    if LEmoji <> '' then
    begin
      LEmojiParaStyle := TSkParagraphStyle.Create;
      LEmojiBuilder := TSkParagraphBuilder.Create(LEmojiParaStyle);

      LEmojiStyle := TSkTextStyle.Create;
      SetLength(LFontFamilies, 1);
      LFontFamilies[0] := 'Segoe UI Emoji';
      LEmojiStyle.FontFamilies := LFontFamilies;
      LEmojiStyle.FontSize := FEmojiSize;
      LEmojiStyle.Color := LTextColor;

      LEmojiBuilder.PushStyle(LEmojiStyle);
      LEmojiBuilder.AddText(LEmoji);
      LEmojiBuilder.Pop;

      LEmojiPara := LEmojiBuilder.Build;
      LEmojiPara.Layout(120);
      LEmojiW := LEmojiPara.MaxIntrinsicWidth;
      LEmojiH := LEmojiPara.Height;
    end;

    // Texto em fonte Segoe UI Bold nítida
    if LText <> '' then
    begin
      LTextParaStyle := TSkParagraphStyle.Create;
      LTextBuilder := TSkParagraphBuilder.Create(LTextParaStyle);

      LTextStyle := TSkTextStyle.Create;
      SetLength(LFontFamilies, 1);
      LFontFamilies[0] := 'Segoe UI';
      LTextStyle.FontFamilies := LFontFamilies;
      LTextStyle.FontSize := FFontSize;
      LTextStyle.FontStyle := TSkFontStyle.Create(TSkFontWeight.Bold, TSkFontWidth.Normal, TSkFontSlant.Upright);
      LTextStyle.Color := LTextColor;

      LTextBuilder.PushStyle(LTextStyle);
      LTextBuilder.AddText(LText);
      LTextBuilder.Pop;

      LTextPara := LTextBuilder.Build;
      LTextPara.Layout(R.Width);
      LTextW := LTextPara.MaxIntrinsicWidth;
      LTextH := LTextPara.Height;
    end;

    Gap := 8.0;

    if (LEmoji <> '') and (LText <> '') then
    begin
      TotalW := LEmojiW + Gap + LTextW;
      StartX := R.Left + (R.Width - TotalW) / 2;
      EmojiX := StartX;
      EmojiY := R.Top + (R.Height - LEmojiH) / 2;
      TextX := StartX + LEmojiW + Gap;
      TextY := R.Top + (R.Height - LTextH) / 2;
      if FIsPressed then
      begin
        EmojiY := EmojiY + 1;
        TextY := TextY + 1;
      end;
      LEmojiPara.Paint(ACanvas, EmojiX, EmojiY);
      LTextPara.Paint(ACanvas, TextX, TextY);
    end
    else if LEmoji <> '' then
    begin
      EmojiX := R.Left + (R.Width - LEmojiW) / 2;
      EmojiY := R.Top + (R.Height - LEmojiH) / 2;
      if FIsPressed then
        EmojiY := EmojiY + 1;
      LEmojiPara.Paint(ACanvas, EmojiX, EmojiY);
    end
    else if LText <> '' then
    begin
      TextX := R.Left + (R.Width - LTextW) / 2;
      TextY := R.Top + (R.Height - LTextH) / 2;
      if FIsPressed then
        TextY := TextY + 1;
      LTextPara.Paint(ACanvas, TextX, TextY);
    end;
  end;
end;

end.
