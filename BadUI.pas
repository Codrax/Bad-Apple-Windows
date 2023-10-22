unit BadUI;

{$SCOPEDENUMS ON}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, Types,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls,
  Vcl.StdCtrls, Cod.Visual.Button, Cod.Visual.CheckBox, Cod.Visual.Slider,
  Vcl.MPlayer;

type
  OFrame = array[1..79] of array[1..32] of boolean;
  TPlayState = (Stopped, Playing, Paused);

  TForm1 = class(TForm)
    FrameTick: TTimer;
    medplay: TMediaPlayer;
    Label1: TLabel;
    CButton2: CButton;
    CButton3: CButton;
    Edit1: TEdit;
    musiccheck: CCheckBox;
    PlayBt: CButton;
    progress: CSlider;
    Normal_Window: CCheckBox;
    Label2: TLabel;
    Label3: TLabel;
    procedure CButton2Click(Sender: TObject);
    procedure PlayBtClick(Sender: TObject);
    procedure FrameTickTimer(Sender: TObject);
    procedure CButton3Click(Sender: TObject);
    procedure musiccheckChange(Sender: CCheckBox; State: TCheckBoxState);
    procedure progressChange(Sender: CSlider; Position, Max, Min: Integer);
    procedure Normal_WindowChange(Sender: CCheckBox; State: TCheckBoxState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure DrawFrame(var ID: integer; ForceRedraw: boolean = false);
    procedure RedrawFrame;

    procedure LoadFrames;

    procedure CreateWindows;
    procedure SetWindow(X, Y: integer; Clear: boolean);

    procedure SetNormalWindow(Normal: boolean);

    procedure PrepAudio;

    procedure SplitDahResolution;

    procedure StartPlay;
    procedure StopPlay;
  end;

const
  FRMAX = 6569;
  CELL_SIZE = 10;

var
  Form1: TForm1;

  VID_WIDTH: integer = 0;
  VID_HEIGHT: integer = 0;

  COLOR_0: TColor = clWhite;
  COLOR_1: TColor = clBlack;

  AppleWindowsStyle: TFormBorderStyle = bsToolWindow;

  frame: integer;
  FRAMES: TArray<OFrame>;

  Windows: TArray<TArray<TForm>>;

  PlayState: TPlayState;
  AudioEnable: boolean = true;

  preparingexce: boolean;

  WindowWidth: integer;
  WindowHeight: integer;

  SpacingX,
  SpacingY: integer;

implementation

{$R *.dfm}

{ TForm1 }

procedure TForm1.PlayBtClick(Sender: TObject);
begin
  // Set State as playing
  PlayBt.BSegoeIcon := '';
  PlayBt.Text := 'Pause';

  // Start Play
  case PlayState of
    // Play
    TPlayState.Stopped: StartPlay;

    // Pause
    TPlayState.Playing: begin
      Medplay.Pause;
      PlayBt.Text := 'Resume';
      PlayBt.BSegoeIcon := '';

      PlayState := TPlayState.Paused;
    end;

    // Resume
    TPlayState.Paused: begin
      Medplay.Play;

      PlayState := TPlayState.Playing;
    end;
  end;
    
  FrameTick.Enabled := PlayState = TPlayState.Playing;
end;

procedure TForm1.CButton2Click(Sender: TObject);
begin
  StopPlay;
end;

procedure TForm1.CButton3Click(Sender: TObject);
begin
  Frame := strtoint( Edit1.Text );

  medplay.Position := trunc(Frame / FRMAX * medplay.Length);
  if PlayState = TPlayState.Playing then
    medplay.Play;
end;

procedure TForm1.Normal_WindowChange(Sender: CCheckBox; State: TCheckBoxState);
begin
  SetNormalWindow( State = cbChecked );
end;

procedure TForm1.CreateWindows;
var
  X: Integer;
  Y: Integer;
begin
  SpacingX := 0;
  SpacingY := 0;

  WindowWidth := Screen.Width div VID_WIDTH - SpacingX;
  WindowHeight := Screen.Height div VID_HEIGHT - SpacingY;

  // Windows
  SetLength(Windows, VID_WIDTH, VID_HEIGHT);

  for X := 0 to High(Windows) do
    for Y := 0 to High(Windows[X]) do
      begin
        Windows[X, Y] := TForm.Create(Application);

        with Windows[X, Y] do
          begin
            Color := COLOR_1;

            BorderStyle := AppleWindowsStyle;

            BorderIcons := [];

            Position := poDesigned;

            Width := WindowWidth;
            Height := WindowHeight;

            Left := X * (WindowWidth+SpacingX);
            Top := Y * (WindowHeight+SpacingY);

            // Custom Title Bar
            with Windows[X, Y].CustomTitleBar do
              begin
                Enabled := true;
                //Control := P;

                SystemColors := false;
                SystemButtons := false;
                ShowIcon := false;
                ShowCaption := false;
                SystemHeight := false;

                Height := 1;
                Height := 0;
              end;

            // Drag Move
            OnMouseDown := FormMouseDown;

            // Show
            Show;
          end;
      end;
end;

procedure TForm1.progressChange(Sender: CSlider; Position, Max, Min: Integer);
begin
  // Frame
  Frame := trunc(Position / Max * FRMAX);

  // Audio
  if AudioEnable then
    begin
      medplay.Position := trunc(Frame / FRMAX * medplay.Length);
      if PlayState = TPlayState.Playing then
        medplay.Play;
    end;

  DrawFrame(Frame, true);

  if PlayState = TPlayState.Stopped then
    begin
      PlayState := TPlayState.Paused;
    end;
end;

procedure TForm1.RedrawFrame;
begin
  DrawFrame(frame);
end;

procedure TForm1.DrawFrame(var ID: integer; ForceRedraw: boolean);
var
  X, Y: integer;
  LastFrameID: integer;
  lastfram, fram: boolean;
begin
  // Data
  LastFrameID := id-1;

  // Music
  if AudioEnable then
    if PlayState <> TPlayState.Stopped then
      if (medplay.Position / medplay.Length - id/FRMAX)*100 > 0.1 then
        begin
          // Change audio position
          {medplay.Position := trunc(id/FRMAX * medplay.Length);
          if PlayState = TPlayState.Playing then
            medplay.Play;}

          // Jump frame (reccomended)
          LastFrameID := ID-1;
          ID := round(medplay.Position / medplay.Length * FRMAX);

          // Since ID is a Pointer(var), the Frame will also get changed
        end;

  // Graphic mode
  {qW := pb.Width div VID_WIDTH;
  qH := pb.Height div VID_HEIGHT;  }

  // Draw Frames
  for Y := 1 to VID_HEIGHT do
    for X := 1 to VID_WIDTH do
      begin
        fram := FRAMES[id][X][Y];
        lastfram := false;
        if LastFrameID <> -1 then
          lastfram := FRAMES[LastFrameID][X][Y];

        if (fram <> lastfram) or (LastFrameID = -1) or ForceRedraw then
          begin
            // Graphic Mode
            {if fram then
              pb.Canvas.Brush.Color := COLOR_0
            else
              pb.Canvas.Brush.Color := COLOR_1;

            pb.Canvas.FillRect(
              Rect(X * qW,
                Y * qH,
                (X + 1) * qW,
                (Y+1) * qH)
              );       }

            SetWindow(X-1, Y-1, fram);
          end;
      end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(TForm(Sender).Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
end;

procedure TForm1.FrameTickTimer(Sender: TObject);
begin
  progress.Position := trunc(frame / FRMAX * progress.Max);

  // Draw
  RedrawFrame;

  // Stop
  if frame = FRMAX then
    StopPlay;

  // Inc
  inc(frame);
end;

procedure TForm1.LoadFrames;
var
  fl: string;
  st: TStringList;
  I, X, Y, lastf: Integer;

  s: string;
begin
  lastf := 1;

  st := TStringList.Create;

  SetLength(FRAMES, FRMAX);

  for I := 1 to FRMAX do
    begin
      fl := '.\res\BA' + I.ToString + '.txt';

      ZeroMemory( @FRAMES[I], SizeOf(FRAMES[I]) );

      if fileexists(fl) then
        begin
          st.LoadFromFile(fl);

          for Y := 1 to st.Count do
            begin
              s := st[Y - 1];

              for X := 1 to length(S) do
                Frames[I][X][Y] := S[X] <> ' ';
            end;

          VID_HEIGHT := st.Count;
          VID_WIDTH := length(s);

          lastf := I;
        end
      else
        Frames[I] := Frames[lastf];
    end;

    st.Free;
end;

procedure TForm1.musiccheckChange(Sender: CCheckBox; State: TCheckBoxState);
begin
  AudioEnable := State = cbChecked;
  if AudioEnable then
    begin
      PrepAudio;

      medplay.Position := trunc(Frame / FRMAX * medplay.Length);
      if PlayState = TPlayState.Playing then
        medplay.Play;
    end
      else
        if medplay.FileName <> '' then
          medplay.stop;
end;

procedure TForm1.PrepAudio;
begin
  if medplay.FileName = '' then
    begin
      medplay.FileName := '.\res\ba.wav';
      medplay.Open;
    end;

  // Play
  medplay.Play;            
end;

procedure TForm1.SetNormalWindow(Normal: boolean);
var
  X: Integer;
  Y: Integer;
begin
  if Normal then
    AppleWindowsStyle := bsToolWindow
  else
    AppleWindowsStyle := bsNone;

  // Already created
  for X := 0 to High(Windows) do
    for Y := 0 to High(Windows[X]) do
      Windows[X, Y].BorderStyle := AppleWindowsStyle;
end;

procedure TForm1.SetWindow(X, Y: integer; Clear: boolean);
var
  AColor: TColor;
begin
  if Clear then
    AColor := COLOR_0
  else
    AColor := COLOR_1;

  with Windows[X, Y] do
    begin
      Color := AColor;
    end;
end;

procedure TForm1.SplitDahResolution;
var
  I, J, K: integer;
  O, N: TStringList;
  fl, S, P: string;
begin
  // Split resolution in 2
  O := TStringList.Create;
  N := TStringList.Create;
  for I := 1 to FRMAX do
    begin
      fl := '.\res\BA' + I.ToString + '.txt';

      O.Clear;
      O.LoadFromFile(fl);

      // Write
      N.Clear;

      for J := 1 to O.Count div 2 do
        begin
          S := O[(J-1)*2];

          P := '';
          for K := Low(S) to High(S) div 2 do
            P := P + S[K*2-1];

          N.Add(P);
        end;

      // Save
      N.SaveToFile(fl);
    end;
  O.Free;
  N.Free;
end;

procedure TForm1.StartPlay;
begin
  // Reset position
  frame := 0;

  // Load frames
  if Length(FRAMES) = 0 then
    begin
      // File IO
      LoadFrames;

      // Windows
      CreateWindows;
    end;

  // State
  PlayState := TPlayState.Playing;

  // Audio
  if musiccheck.Checked then
    PrepAudio;

  // Framerate
  FrameTick.Enabled := true;

  // UI
  Normal_Window.Enabled := false;
  Normal_Window.Invalidate;
end;

procedure TForm1.StopPlay;
begin
  FrameTick.Enabled := false;
  Frame := 0;

  PlayState := TPlayState.Stopped;

  // Status
  PlayBt.Text := 'Play';
  PlayBt.BSegoeIcon := '';

  // Audio
  {sndPlaySound(0, SND_ASYNC);}
  if AudioEnable then
    begin
      medplay.Stop;
      medplay.Position := 0;
    end;
end;

end.
