//+------------------------------------------------------------------+
//| DukascopyImporter.mq5                                            |
//| Panel: tarih araligi sec -> Dukascopy'den indir -> ozel sembole  |
//| aktar. Gereksinim: Node.js (npx) + "DLL import izni"             |
//+------------------------------------------------------------------+
#property version   "1.00"
#property strict
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#import "shell32.dll"
long ShellExecuteW(long hwnd, string op, string file, string params, string dir, int show);
#import

input string InpTarget    = "XAUUSD_HIST"; // Hedef ozel sembol (bos birakirsan grafik sembolu)
input string InpInstrument= "xauusd";// Dukascopy enstruman kodu s
input int    InpUtcOffset = 2;       // Broker sunucu saati: UTC + kac saat (kis)
input bool   InpUsDst     = true;    // Yaz saatinde (ABD DST) +1 saat ekle
input int    InpChunk     = 20000;   // Timer basina islenecek bar sayisi

#define P "DKI_"
#define FLAG_FILE "dki_done.flag"
#define CSV_NAME  "dki_data"

int      g_state = 0;               // 0 bosta, 1 indirme bekleniyor, 2 aktariliyor
int      g_h     = INVALID_HANDLE;
long     g_rows  = 0;
datetime g_last  = 0;
string   g_target;
int      g_dots  = 0;

//+------------------------------------------------------------------+
//| Panel yardimcilari                                               |
//+------------------------------------------------------------------+
void Rect(string n,int x,int y,int w,int h)
{
   ObjectCreate(0,P+n,OBJ_RECTANGLE_LABEL,0,0,0);
   ObjectSetInteger(0,P+n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,P+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,P+n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,P+n,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,P+n,OBJPROP_BGCOLOR,C'30,32,40');
   ObjectSetInteger(0,P+n,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,P+n,OBJPROP_COLOR,C'80,85,100');
   ObjectSetInteger(0,P+n,OBJPROP_SELECTABLE,false);
}
void Lbl(string n,int x,int y,string t,color c=clrWhite,int sz=9)
{
   ObjectCreate(0,P+n,OBJ_LABEL,0,0,0);
   ObjectSetInteger(0,P+n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,P+n,OBJPROP_YDISTANCE,y);
   ObjectSetString (0,P+n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,P+n,OBJPROP_COLOR,c);
   ObjectSetInteger(0,P+n,OBJPROP_FONTSIZE,sz);
   ObjectSetInteger(0,P+n,OBJPROP_SELECTABLE,false);
}
void Edt(string n,int x,int y,int w,string t)
{
   ObjectCreate(0,P+n,OBJ_EDIT,0,0,0);
   ObjectSetInteger(0,P+n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,P+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,P+n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,P+n,OBJPROP_YSIZE,20);
   ObjectSetString (0,P+n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,P+n,OBJPROP_BGCOLOR,C'50,53,65');
   ObjectSetInteger(0,P+n,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,P+n,OBJPROP_BORDER_COLOR,C'90,95,110');
   ObjectSetInteger(0,P+n,OBJPROP_FONTSIZE,9);
}
void Btn(string n,int x,int y,int w,int h,string t,color bg)
{
   ObjectCreate(0,P+n,OBJ_BUTTON,0,0,0);
   ObjectSetInteger(0,P+n,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,P+n,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,P+n,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,P+n,OBJPROP_YSIZE,h);
   ObjectSetString (0,P+n,OBJPROP_TEXT,t);
   ObjectSetInteger(0,P+n,OBJPROP_BGCOLOR,bg);
   ObjectSetInteger(0,P+n,OBJPROP_COLOR,clrWhite);
   ObjectSetInteger(0,P+n,OBJPROP_FONTSIZE,9);
}
string Get(string n){ return ObjectGetString(0,P+n,OBJPROP_TEXT); }
void Status(string s)
{
   ObjectSetString(0,P+"st",OBJPROP_TEXT,s);
   ChartRedraw();
}
string DateStr(datetime t)   // 2026-10-19
{
   string s=TimeToString(t,TIME_DATE);
   StringReplace(s,".","-");
   return s;
}
datetime ParseDate(string s)
{
   StringReplace(s,"-",".");
   StringTrimLeft(s); StringTrimRight(s);
   return StringToTime(s);
}
void SetPreset(int years)
{
   datetime to=TimeLocal();
   datetime from=to-(datetime)((long)years*365*86400);
   ObjectSetString(0,P+"from",OBJPROP_TEXT,DateStr(from));
   ObjectSetString(0,P+"to",OBJPROP_TEXT,DateStr(to));
   ChartRedraw();
}

void BuildPanel()
{
   int x=10,y=20;
   Rect("bg",x,y,262,282);
   Lbl("title",x+10,y+6,"Dukascopy -> Ozel Sembol",clrGold,10);

   Lbl("l1",x+10,y+34,"Hedef sembol");  Edt("sym" ,x+110,y+30,142,g_target);
   Lbl("l2",x+10,y+60,"Enstruman");     Edt("ins" ,x+110,y+56,142,InpInstrument);
   Lbl("l3",x+10,y+86,"Baslangic");     Edt("from",x+110,y+82,142,"");
   Lbl("l4",x+10,y+112,"Bitis");        Edt("to"  ,x+110,y+108,142,"");
   Lbl("l5",x+10,y+138,"UTC ofset (s)");Edt("off" ,x+110,y+134,142,IntegerToString(InpUtcOffset));

   Btn("p1",x+10 ,y+166,74,22,"Son 1 Yil",C'60,64,80');
   Btn("p3",x+94 ,y+166,74,22,"Son 3 Yil",C'60,64,80');
   Btn("p5",x+178,y+166,74,22,"Son 5 Yil",C'60,64,80');

   Btn("go" ,x+10,y+196,242,28,"Indir + Ice Aktar",C'20,110,70');
   Btn("imp",x+10,y+230,242,24,"Sadece Mevcut CSV'yi Aktar",C'45,85,150');
   Lbl("st",x+10,y+260,"Hazir.",clrSilver,8);
   SetPreset(5);
}

//+------------------------------------------------------------------+
//| US DST (ikinci Pazar Mart 07:00 UTC -> ilk Pazar Kasim 06:00 UTC) |
//+------------------------------------------------------------------+
bool UsDst(datetime utc)
{
   MqlDateTime d; TimeToStruct(utc,d);
   if(d.mon<3 || d.mon>11) return false;
   if(d.mon>3 && d.mon<11) return true;
   int dow1=(d.day_of_week-((d.day-1)%7)+7)%7;      // ayin 1'inin haftanin gunu
   int firstSun=(7-dow1)%7+1;
   if(d.mon==3)
   {
      int secondSun=firstSun+7;
      if(d.day>secondSun) return true;
      if(d.day<secondSun) return false;
      return d.hour>=7;
   }
   if(d.day<firstSun) return true;
   if(d.day>firstSun) return false;
   return d.hour<6;
}

//+------------------------------------------------------------------+
//| Indirme baslat                                                   |
//+------------------------------------------------------------------+
void StartFetch()
{
   if(g_state==2){ Status("Aktarim suruyor, bekleyin."); return; }

   g_target=Get("sym");
   long isCustom=0;
   if(!SymbolInfoInteger(g_target,SYMBOL_CUSTOM,isCustom) || isCustom==0)
   { Status("HATA: '"+g_target+"' ozel sembol degil/yok."); return; }

   datetime from=ParseDate(Get("from")), to=ParseDate(Get("to"));
   if(from<=0 || to<=0 || to<=from)
   { Status("HATA: tarih araligi gecersiz (YYYY-AA-GG)."); return; }

   string ins=Get("ins");
   FileDelete(FLAG_FILE);
   FileDelete(CSV_NAME+".csv");

   string dir=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files";
   string args="/c npx dukascopy-node -i "+ins+" -from "+DateStr(from)+" -to "+DateStr(to)
              +" -t m1 -f csv -dir . -fn "+CSV_NAME+" && echo ok> "+FLAG_FILE+" || pause";

   long r=ShellExecuteW(0,"open","cmd.exe",args,dir,1);
   if(r<=32)
   { Status("HATA: cmd calistirilamadi (DLL izni?) kod="+IntegerToString((int)r)); return; }

   g_state=1; g_dots=0;
   Status("Indiriliyor... (cmd penceresine bakin)");
}

//+------------------------------------------------------------------+
//| CSV aktarimi                                                     |
//+------------------------------------------------------------------+
void BeginImport()
{
   if(g_state==2) return;
   g_target=Get("sym");
   long isCustom=0;
   if(!SymbolInfoInteger(g_target,SYMBOL_CUSTOM,isCustom) || isCustom==0)
   { Status("HATA: '"+g_target+"' ozel sembol degil/yok."); g_state=0; return; }

   g_h=FileOpen(CSV_NAME+".csv",FILE_READ|FILE_CSV|FILE_ANSI|FILE_SHARE_READ,',');
   if(g_h==INVALID_HANDLE)
   { Status("HATA: "+CSV_NAME+".csv bulunamadi (MQL5\\Files)."); g_state=0; return; }

   // baslik satiri var mi?
   string first=FileReadString(g_h);
   if(StringToInteger(first)==0)
   { for(int i=0;i<5;i++) FileReadString(g_h); }   // basligi atla
   else
      FileSeek(g_h,0,SEEK_SET);

   SymbolSelect(g_target,true);
   g_rows=0; g_last=0; g_state=2;
   Status("Aktariliyor...");
}

void ImportStep()
{
   int cap=MathMax(1000,InpChunk);
   MqlRates r[];
   ArrayResize(r,cap);
   int n=0;
   int digits=(int)SymbolInfoInteger(g_target,SYMBOL_DIGITS);

   while(n<cap && !FileIsEnding(g_h))
   {
      string s0=FileReadString(g_h);
      if(s0=="" && FileIsEnding(g_h)) break;
      double o=StringToDouble(FileReadString(g_h));
      double h=StringToDouble(FileReadString(g_h));
      double l=StringToDouble(FileReadString(g_h));
      double c=StringToDouble(FileReadString(g_h));
      double v=StringToDouble(FileReadString(g_h));

      long ts=StringToInteger(s0);
      if(ts<=0) continue;
      if(ts>100000000000) ts/=1000;               // ms -> sn
      datetime utc=(datetime)ts;
      int off=(int)StringToInteger(Get("off"));
      if(InpUsDst && UsDst(utc)) off++;
      datetime t=utc+off*3600;

      r[n].time=t;
      r[n].open=NormalizeDouble(o,digits);
      r[n].high=NormalizeDouble(h,digits);
      r[n].low =NormalizeDouble(l,digits);
      r[n].close=NormalizeDouble(c,digits);
      r[n].tick_volume=(long)MathMax(1.0,MathRound(v*1000.0));
      r[n].spread=0;
      r[n].real_volume=0;
      g_last=t;
      n++;
   }

   if(n>0)
   {
      ArrayResize(r,n);
      int res=CustomRatesUpdate(g_target,r);
      if(res<=0)
      {
         Status("HATA: CustomRatesUpdate kod="+IntegerToString(GetLastError()));
         FileClose(g_h); g_h=INVALID_HANDLE; g_state=0;
         return;
      }
      g_rows+=n;
   }

   if(FileIsEnding(g_h))
   {
      FileClose(g_h); g_h=INVALID_HANDLE; g_state=0;
      FileDelete(FLAG_FILE);
      Status("Bitti: "+IntegerToString(g_rows)+" bar aktarildi.");
      ChartSetSymbolPeriod(0,_Symbol,_Period);    // grafigi yenile
   }
   else
      Status("Aktariliyor: "+IntegerToString(g_rows)+" bar | "+TimeToString(g_last,TIME_DATE));
}

//+------------------------------------------------------------------+
int OnInit()
{
   g_target=(InpTarget=="")?_Symbol:InpTarget;
   Print("DukascopyImporter: OnInit basladi, sembol=",g_target,
         " DLL izni=",(bool)TerminalInfoInteger(TERMINAL_DLLS_ALLOWED));
   if(!TerminalInfoInteger(TERMINAL_DLLS_ALLOWED))
      Alert("DukascopyImporter: DLL import izni kapali! Tools > Options > Expert Advisors > 'Allow DLL imports'");
   BuildPanel();
   ChartRedraw();
   EventSetMillisecondTimer(100);
   return INIT_SUCCEEDED;
}
void OnDeinit(const int reason)
{
   EventKillTimer();
   if(g_h!=INVALID_HANDLE){ FileClose(g_h); g_h=INVALID_HANDLE; }
   ObjectsDeleteAll(0,P);
}
void OnTimer()
{
   if(ObjectFind(0,P+"bg")<0)
   {
      Print("DukascopyImporter: panel bulunamadi, yeniden olusturuluyor");
      BuildPanel();
      ChartRedraw();
   }
   if(g_state==1)
   {
      if(FileIsExist(FLAG_FILE))
         BeginImport();
      else
      {
         g_dots=(g_dots+1)%30;
         if(g_dots==0) Status("Indiriliyor... (cmd penceresine bakin)");
      }
   }
   else if(g_state==2)
      ImportStep();
}
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id!=CHARTEVENT_OBJECT_CLICK) return;
   if(sparam==P+"p1") SetPreset(1);
   else if(sparam==P+"p3") SetPreset(3);
   else if(sparam==P+"p5") SetPreset(5);
   else if(sparam==P+"go")  StartFetch();
   else if(sparam==P+"imp") BeginImport();
   if(StringFind(sparam,P)==0)
   {
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      ChartRedraw();
   }
}
int OnCalculate(const int rates_total,const int prev_calculated,const datetime &time[],
                const double &open[],const double &high[],const double &low[],
                const double &close[],const long &tick_volume[],const long &volume[],
                const int &spread[])
{
   return rates_total;
}
