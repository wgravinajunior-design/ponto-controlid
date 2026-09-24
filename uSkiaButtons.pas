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
  LEmojiBuilder, LTextBuilder, LTextShadowBuilder: ISkParagraphBuilder;
  LEmojiPara, LTextPara, LTextShadowPara: ISkParagraph;
  LEmojiStyle, LTextStyle, LTextShadowStyle: ISkTextStyle;
  LEmojiParaStyle, LTextParaStyle, LTextShadowParaStyle: ISkParagraphStyle;
  LEmojiW, LEmojiH, LTextW, LTextH, TotalW, Gap, StartX, EmojiX, EmojiY, TextX, TextY: Single;
  LFontFamilies: TArray<string>;
begin
  inherited;

  // Paleta de cores moderna, super vibrante, saturada e com alto contraste
  case FKind of
    sbkPrimary: // Azul Real Elétrico / Royal Blue Vibrante
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF0F3CB8;
        LBgColorBottom := $FF0A2A82;
        LBorderColor := $FF1652F0;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF2E6BF8;
        LBgColorBottom := $FF1652F0;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $701652F0;
      end
      else
      begin
        LBgColorTop := $FF1652F0;
        LBgColorBottom := $FF0F3CB8;
        LBorderColor := $FF4D82FF;
        LShadowColor := $500E3498;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkTeal: // Turquesa / Ciano Oceânico Vibrante
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF0E7490;
        LBgColorBottom := $FF155E75;
        LBorderColor := $FF0891B2;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF06B6D4;
        LBgColorBottom := $FF0891B2;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $700891B2;
      end
      else
      begin
        LBgColorTop := $FF0891B2;
        LBgColorBottom := $FF0E7490;
        LBorderColor := $FF22D3EE;
        LShadowColor := $500E5C72;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkSuccess: // Verde Esmeralda / Jade Vibrante
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF0A7B35;
        LBgColorBottom := $FF065424;
        LBorderColor := $FF10A348;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF16BA54;
        LBgColorBottom := $FF10A348;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $7010A348;
      end
      else
      begin
        LBgColorTop := $FF10A348;
        LBgColorBottom := $FF0A7B35;
        LBorderColor := $FF34D399;
        LShadowColor := $500A682D;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkDanger: // Vermelho Rubi / Carmim Vibrante
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FFB00F2E;
        LBgColorBottom := $FF800B22;
        LBorderColor := $FFE01A3F;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFF42E52;
        LBgColorBottom := $FFE01A3F;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $70E01A3F;
      end
      else
      begin
        LBgColorTop := $FFE01A3F;
        LBgColorBottom := $FFB00F2E;
        LBorderColor := $FFF43F5E;
        LShadowColor := $50900C25;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkWarning: // Laranja Solar Intenso / Flame Orange (alto contraste)
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FFC2410C;
        LBgColorBottom := $FF9A3412;
        LBorderColor := $FFE8590C;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFF97316;
        LBgColorBottom := $FFE8590C;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $70E8590C;
      end
      else
      begin
        LBgColorTop := $FFE8590C;
        LBgColorBottom := $FFC2410C;
        LBorderColor := $FFFB923C;
        LShadowColor := $509A3412;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkPurple: // Violeta Real / Roxo Vibrante
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF581C87;
        LBgColorBottom := $FF3B0764;
        LBorderColor := $FF7E22CE;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF9333EA;
        LBgColorBottom := $FF7E22CE;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $707E22CE;
      end
      else
      begin
        LBgColorTop := $FF7E22CE;
        LBgColorBottom := $FF581C87;
        LBorderColor := $FFA855F7;
        LShadowColor := $504A1572;
      end;
      LTextColor := TAlphaColors.White;
    end;

    sbkDark: // Grafite / Slate Nobre
    begin
      if FIsPressed then
      begin
        LBgColorTop := $FF1E293B;
        LBgColorBottom := $FF0F172A;
        LBorderColor := $FF334155;
        LShadowColor := TAlphaColors.Null;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FF475569;
        LBgColorBottom := $FF334155;
        LBorderColor := $FFFFFFFF;
        LShadowColor := $701E293B;
      end
      else
      begin
        LBgColorTop := $FF334155;
        LBgColorBottom := $FF1E293B;
        LBorderColor := $FF64748B;
        LShadowColor := $500F172A;
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
        LTextColor := $FF0F172A;
      end
      else if FIsHovered then
      begin
        LBgColorTop := $FFFFFFFF;
        LBgColorBottom := $FFE2E8F0;
        LBorderColor := $FF3B82F6;
        LShadowColor := $30000000;
        LTextColor := $FF1652F0;
      end
      else
      begin
        LBgColorTop := $FFFFFFFF;
        LBgColorBottom := $FFF1F5F9;
        LBorderColor := $FFCBD5E1;
        LShadowColor := $20000000;
        LTextColor := $FF0F172A;
      end;
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

  // 2. Fundo com Gradiente Linear Vertical Vibrante e 100% Sólido
  LPaint.Color := TAlphaColors.White; // Garante opacidade total (255) sem transparência indesejada
  LPaint.Shader := TSkShader.MakeGradientLinear(
    PointF(R.Left, R.Top),
    PointF(R.Left, R.Bottom),
    LBgColorTop,
    LBgColorBottom
  );
  LPaint.Style := TSkPaintStyle.Fill;
  ACanvas.DrawRoundRect(R, FRadius, FRadius, LPaint);
  LPaint.Shader := nil;

  // 3. Brilho sutil no topo interior (acabamento e profundidade sem esbranquiçar)
  if (not FIsPressed) and (FKind <> sbkDefault) then
  begin
    HighlightR := R;
    HighlightR.Inflate(-1, -1);
    LPaint.Color := $18FFFFFF;
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
      LPaint.StrokeWidth := 1.5;
    ACanvas.DrawRoundRect(R, FRadius, FRadius, LPaint);
  end;

  // 5. Renderização do Emoji e Texto em Alta Resolução (com sombra de texto para máxima nitidez)
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
    LTextShadowPara := nil;

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

      // Sombra suave do texto para contraste impecável em qualquer resolução
      if (LTextColor = TAlphaColors.White) and (FKind <> sbkDefault) then
      begin
        LTextShadowParaStyle := TSkParagraphStyle.Create;
        LTextShadowBuilder := TSkParagraphBuilder.Create(LTextShadowParaStyle);
        LTextShadowStyle := TSkTextStyle.Create;
        LTextShadowStyle.FontFamilies := LFontFamilies;
        LTextShadowStyle.FontSize := FFontSize;
        LTextShadowStyle.FontStyle := TSkFontStyle.Create(TSkFontWeight.Bold, TSkFontWidth.Normal, TSkFontSlant.Upright);
        LTextShadowStyle.Color := $60000000;
        LTextShadowBuilder.PushStyle(LTextShadowStyle);
        LTextShadowBuilder.AddText(LText);
        LTextShadowBuilder.Pop;
        LTextShadowPara := LTextShadowBuilder.Build;
        LTextShadowPara.Layout(R.Width);
      end;
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
      if LTextShadowPara <> nil then
        LTextShadowPara.Paint(ACanvas, TextX, TextY + 1.2);
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
      if LTextShadowPara <> nil then
        LTextShadowPara.Paint(ACanvas, TextX, TextY + 1.2);
      LTextPara.Paint(ACanvas, TextX, TextY);
    end;
  end;
end;

end.
