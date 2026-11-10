//+------------------------------------------------------------------+
//|                                             QuickTradePanel.mq5   |
//|  Küçük panel: Buy / Sell, lot ayarı, işlem açılınca 1 ATR SL      |
//+------------------------------------------------------------------+
#property version   "1.00"
#property description "Hızlı işlem paneli - Buy/Sell + lot ayarı + ATR bazlı otomatik Stop Loss"

#include <Trade\Trade.mqh>

//--- Ayarlar
input double           InpLot       = 0.10;       // Başlangıç lot
input double           InpLotStep   = 0.01;       // +/- butonu lot adımı
input int              InpAtrPeriod = 14;         // ATR periyodu
input double           InpAtrMult   = 1.0;        // SL mesafesi (ATR çarpanı)
input ENUM_TIMEFRAMES  InpAtrTf     = PERIOD_CURRENT; // ATR zaman dilimi
input ulong            InpMagic     = 20260101;   // Magic number
input int              InpDeviation = 20;         // Maks. kayma (point)
input int              InpX         = 20;         // Panel X konumu
input int              InpY         = 40;         // Panel Y konumu
input bool             InpAllSymbols = false;     // Close All / BE All: true = tüm semboller, false = sadece bu grafik
input int              InpBEOffset  = 0;          // Breakeven ofseti (point, + yönde kâr tarafı)

//--- Global
CTrade  trade;
int     atrHandle = INVALID_HANDLE;
double  curLot;
string  P = "QTP_";

//--- Nesne adları
string N_BG, N_TITLE, N_MINUS, N_EDIT, N_PLUS, N_BUY, N_SELL, N_INFO, N_CLOSE, N_BE;

//+------------------------------------------------------------------+
//| Yardımcı: nesne oluşturucular                                    |
//+------------------------------------------------------------------+
void BaseProps(string name, int x, int y, int w, int h)
{
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, w);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, h);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

void CreateRect(string name, int x, int y, int w, int h, color bg)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   BaseProps(name, x, y, w, h);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrDimGray);
}

void CreateLabel(string name, string text, int x, int y, color clr, int size)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, size);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetString(0, name, OBJPROP_TEXT, text);
}

void CreateButton(string name, string text, int x, int y, int w, int h, color bg)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   BaseProps(name, x, y, w, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, bg);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

void CreateEdit(string name, string text, int x, int y, int w, int h)
{
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   BaseProps(name, x, y, w, h);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
}

//+------------------------------------------------------------------+
//| Lot yardımcıları                                                 |
//+------------------------------------------------------------------+
int LotDigits()
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int d = 0;
   while(step < 1.0 && d < 8)
   {
      step *= 10.0;
      if(MathAbs(step - MathRound(step)) < 1e-8) { d++; break; }
      d++;
   }
   return d;
}

double NormalizeLot(double lot)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;
   lot = MathFloor(lot / step + 1e-8) * step;
   if(lot < vmin) lot = vmin;
   if(lot > vmax) lot = vmax;
   return NormalizeDouble(lot, LotDigits());
}

void ShowLot()
{
   ObjectSetString(0, N_EDIT, OBJPROP_TEXT, DoubleToString(curLot, LotDigits()));
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ATR                                                              |
//+------------------------------------------------------------------+
double GetATR()
{
   if(atrHandle == INVALID_HANDLE) return 0.0;
   double buf[];
   if(CopyBuffer(atrHandle, 0, 1, 1, buf) < 1) return 0.0; // kapanmış son mum
   return buf[0];
}

void UpdateInfo()
{
   double atr = GetATR();
   string txt;
   if(atr > 0)
      txt = StringFormat("ATR: %s   SL: %s", DoubleToString(atr, _Digits),
                         DoubleToString(atr * InpAtrMult, _Digits));
   else
      txt = "ATR hesaplanıyor...";
   ObjectSetString(0, N_INFO, OBJPROP_TEXT, txt);
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| İşlem aç                                                         |
//+------------------------------------------------------------------+
void OpenTrade(bool isBuy)
{
   double atr = GetATR();
   if(atr <= 0)
   {
      Alert("ATR değeri alınamadı, işlem açılmadı.");
      return;
   }

   double dist = atr * InpAtrMult;

   // Broker minimum stop mesafesi kontrolü
   long stopsLvl  = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long freezeLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double minDist = (double)MathMax(stopsLvl, freezeLvl) * _Point;
   if(dist < minDist) dist = minDist + _Point;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl = isBuy ? bid - dist : ask + dist;   // Buy: bid'e göre, Sell: ask'a göre kapanır
   sl = NormalizeDouble(sl, _Digits);

   double lot = NormalizeLot(curLot);

   bool ok;
   if(isBuy) ok = trade.Buy(lot, _Symbol, 0.0, sl, 0.0, "QTP Buy");
   else      ok = trade.Sell(lot, _Symbol, 0.0, sl, 0.0, "QTP Sell");

   if(!ok || (trade.ResultRetcode() != TRADE_RETCODE_DONE && trade.ResultRetcode() != TRADE_RETCODE_PLACED))
      Alert("İşlem hatası: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   else
      PrintFormat("%s %s lot=%s SL=%s", isBuy ? "BUY" : "SELL", _Symbol,
                  DoubleToString(lot, LotDigits()), DoubleToString(sl, _Digits));
}

//+------------------------------------------------------------------+
//| Init / Deinit                                                    |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Tüm pozisyonları kapat                                           |
//+------------------------------------------------------------------+
void CloseAll()
{
   int closed = 0, failed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(!InpAllSymbols && PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      if(trade.PositionClose(ticket)) closed++;
      else
      {
         failed++;
         PrintFormat("Kapatma hatası #%I64u: %d - %s", ticket,
                     trade.ResultRetcode(), trade.ResultRetcodeDescription());
      }
   }
   PrintFormat("Close All: %d kapandı, %d hata", closed, failed);
   if(failed > 0) Alert("Close All: ", failed, " pozisyon kapatılamadı. Experts sekmesine bak.");
}

//+------------------------------------------------------------------+
//| Tüm pozisyonları breakeven'a çek                                 |
//+------------------------------------------------------------------+
void BreakevenAll()
{
   int moved = 0, skipped = 0, failed = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      string sym = PositionGetString(POSITION_SYMBOL);
      if(!InpAllSymbols && sym != _Symbol) continue;

      long   type  = PositionGetInteger(POSITION_TYPE);
      double open  = PositionGetDouble(POSITION_PRICE_OPEN);
      double curSL = PositionGetDouble(POSITION_SL);
      double tp    = PositionGetDouble(POSITION_TP);

      double point  = SymbolInfoDouble(sym, SYMBOL_POINT);
      int    digits = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double bid    = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask    = SymbolInfoDouble(sym, SYMBOL_ASK);
      long   lvl    = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
      double minDist = (double)lvl * point;

      double newSL;
      if(type == POSITION_TYPE_BUY)
      {
         newSL = NormalizeDouble(open + InpBEOffset * point, digits);
         // zaten breakeven veya daha iyi
         if(curSL != 0.0 && curSL >= newSL) { skipped++; continue; }
         // henüz yeterli kâr yok (SL fiyata çok yakın / üstünde olur)
         if(newSL > bid - minDist)          { skipped++; continue; }
      }
      else
      {
         newSL = NormalizeDouble(open - InpBEOffset * point, digits);
         if(curSL != 0.0 && curSL <= newSL) { skipped++; continue; }
         if(newSL < ask + minDist)          { skipped++; continue; }
      }

      if(trade.PositionModify(ticket, newSL, tp)) moved++;
      else
      {
         failed++;
         PrintFormat("BE hatası #%I64u: %d - %s", ticket,
                     trade.ResultRetcode(), trade.ResultRetcodeDescription());
      }
   }
   PrintFormat("Breakeven: %d taşındı, %d atlandı (kârda değil/zaten BE), %d hata", moved, skipped, failed);
   if(failed > 0) Alert("Breakeven: ", failed, " pozisyon güncellenemedi. Experts sekmesine bak.");
}

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   trade.SetExpertMagicNumber(InpMagic);
   trade.SetDeviationInPoints(InpDeviation);
   trade.SetTypeFillingBySymbol(_Symbol);

   atrHandle = iATR(_Symbol, InpAtrTf, InpAtrPeriod);
   if(atrHandle == INVALID_HANDLE)
   {
      Print("ATR handle oluşturulamadı.");
      return INIT_FAILED;
   }

   curLot = NormalizeLot(InpLot);

   N_BG    = P + "bg";
   N_TITLE = P + "title";
   N_MINUS = P + "minus";
   N_EDIT  = P + "edit";
   N_PLUS  = P + "plus";
   N_BUY   = P + "buy";
   N_SELL  = P + "sell";
   N_INFO  = P + "info";
   N_CLOSE = P + "closeall";
   N_BE    = P + "beall";

   int x = InpX, y = InpY;
   CreateRect (N_BG,    x,       y,       190, 158, C'30,30,36');
   CreateLabel(N_TITLE, "Quick Trade  |  " + _Symbol, x + 10, y + 6, clrSilver, 9);
   CreateButton(N_MINUS, "-",    x + 10,  y + 28, 30, 24, C'70,70,80');
   CreateEdit  (N_EDIT,  "",     x + 45,  y + 28, 100, 24);
   CreateButton(N_PLUS,  "+",    x + 150, y + 28, 30, 24, C'70,70,80');
   CreateButton(N_BUY,   "BUY",  x + 10,  y + 60, 80, 32, clrDodgerBlue);
   CreateButton(N_SELL,  "SELL", x + 100, y + 60, 80, 32, clrCrimson);
   CreateButton(N_CLOSE, "CLOSE ALL", x + 10,  y + 100, 80, 26, C'120,60,0');
   CreateButton(N_BE,    "BE ALL",    x + 100, y + 100, 80, 26, C'0,110,80');
   CreateLabel (N_INFO,  "",     x + 10,  y + 136, clrSilver, 8);

   ShowLot();
   UpdateInfo();
   EventSetTimer(1);
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ObjectsDeleteAll(0, P);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   ChartRedraw();
}

void OnTimer() { UpdateInfo(); }
void OnTick()  { }

//+------------------------------------------------------------------+
//| Buton / edit olayları                                            |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == N_BUY || sparam == N_SELL || sparam == N_MINUS || sparam == N_PLUS ||
         sparam == N_CLOSE || sparam == N_BE)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // buton basılı kalmasın

      if(sparam == N_CLOSE)      CloseAll();
      else if(sparam == N_BE)    BreakevenAll();
      else if(sparam == N_BUY)   OpenTrade(true);
      else if(sparam == N_SELL)  OpenTrade(false);
      else if(sparam == N_MINUS) { curLot = NormalizeLot(curLot - InpLotStep); ShowLot(); }
      else if(sparam == N_PLUS)  { curLot = NormalizeLot(curLot + InpLotStep); ShowLot(); }
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == N_EDIT)
   {
      string t = ObjectGetString(0, N_EDIT, OBJPROP_TEXT);
      StringReplace(t, ",", ".");
      double v = StringToDouble(t);
      if(v > 0) curLot = NormalizeLot(v);
      ShowLot();
   }
}
//+------------------------------------------------------------------+
