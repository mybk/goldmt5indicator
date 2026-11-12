//+------------------------------------------------------------------+
//|                                           QuickTradePanelV2.mq5   |
//|  Sürüklenebilir SL çizgisi + $ risk bazlı otomatik lot + 1:3 TP   |
//+------------------------------------------------------------------+
#property version   "2.00"
#property description "SL çizgisini sürükle, risk ($) yaz, Buy/Sell'e bas: lot otomatik, TP = RR x SL mesafesi"

#include <Trade\Trade.mqh>

//--- Ayarlar
input double           InpRisk       = 30.0;          // Başlangıç risk (hesap para birimi, örn. $)
input double           InpRR         = 3.0;           // Ödül/Risk oranı (3 = 1:3)
input int              InpAtrPeriod  = 14;            // ATR periyodu
input double           InpAtrMult    = 1.0;           // "SL = 1 ATR" butonu için çarpan
input ENUM_TIMEFRAMES  InpAtrTf      = PERIOD_CURRENT;// ATR zaman dilimi
input ulong            InpMagic      = 20260101;      // Magic number
input int              InpDeviation  = 20;            // Maks. kayma (point)
input int              InpX          = 1900;            // Panel X konumu
input int              InpY          = 850;            // Panel Y konumu
input bool             InpAllSymbols = false;         // Close All / BE All: true = tüm semboller
input int              InpBEOffset   = 0;             // Breakeven ofseti (point)
input color            InpSLColor    = clrRed;        // SL çizgi rengi
input color            InpTPColor    = clrLime;       // TP çizgi rengi

//--- Global
CTrade  trade;
int     atrHandle = INVALID_HANDLE;
double  curRisk;
string  P = "QTP_";

string N_BG, N_TITLE, N_RLBL, N_RISK, N_BUY, N_SELL, N_CLOSE, N_BE, N_ATRBTN, N_INFO, N_INFO2, N_TLBL, N_TIMER, N_SLBL, N_STIME;
string L_SL, L_TP;

// Sunucu saati senkronu (tick damgasından, ms hassasiyetinde)
long    g_off      = 0;       // sunucu_ms - GetTickCount64()
bool    g_offTick  = false;   // ofset gerçek tick'ten mi alındı
ulong   g_offAt    = 0;       // ofsetin alındığı yerel zaman

//+------------------------------------------------------------------+
//| Nesne yardımcıları                                               |
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
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

void CreateEdit(string name, string text, int x, int y, int w, int h)
{
   ObjectCreate(0, name, OBJ_EDIT, 0, 0, 0);
   BaseProps(name, x, y, w, h);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_CENTER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrWhite);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
}

void CreateHLine(string name, double price, color clr, ENUM_LINE_STYLE style,
                 int width, bool selectable, string tip)
{
   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, selectable);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, selectable);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tip);
   ObjectSetString(0, name, OBJPROP_TEXT, tip);
}

//+------------------------------------------------------------------+
//| Lot yardımcıları                                                 |
//+------------------------------------------------------------------+
int LotDigits()
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   int d = 0;
   while(d < 8 && MathAbs(step * MathPow(10, d) - MathRound(step * MathPow(10, d))) > 1e-8) d++;
   return d;
}

// Aşağı yuvarlar (risk asla girilen değeri aşmasın). Min lotun altındaysa 0 döner.
double FloorLot(double lot)
{
   double step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double vmin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double vmax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(step <= 0) step = 0.01;
   lot = MathFloor(lot / step + 1e-8) * step;
   if(lot > vmax) lot = MathFloor(vmax / step + 1e-8) * step;
   if(lot < vmin - 1e-12) return 0.0;
   return NormalizeDouble(lot, LotDigits());
}

// 1 lotluk pozisyonun entry -> SL arasındaki zararı (hesap para biriminde)
double LossPerLot(bool isBuy, double entry, double sl)
{
   double p = 0.0;
   if(OrderCalcProfit(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, 1.0, entry, sl, p) && p != 0.0)
      return MathAbs(p);

   // Yedek yöntem: tick değeri
   double ts = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE_LOSS);
   if(tv <= 0) tv = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   if(ts <= 0 || tv <= 0) return 0.0;
   return MathAbs(entry - sl) / ts * tv;
}

//+------------------------------------------------------------------+
//| ATR                                                              |
//+------------------------------------------------------------------+
double GetATR()
{
   if(atrHandle == INVALID_HANDLE) return 0.0;
   double buf[];
   if(CopyBuffer(atrHandle, 0, 1, 1, buf) < 1) return 0.0;
   return buf[0];
}

// SL çizgisini 1 ATR mesafeye koyar. keepSide=true ise çizginin mevcut tarafını (üst/alt) korur.
bool SetSLByATR(bool keepSide)
{
   double atr = GetATR();
   if(atr <= 0) return false;
   double d   = atr * InpAtrMult;
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0) return false;

   bool above = false;
   if(keepSide && ObjectFind(0, L_SL) >= 0)
      above = ObjectGetDouble(0, L_SL, OBJPROP_PRICE) > (ask + bid) / 2.0;

   double p = NormalizeDouble(above ? bid + d : ask - d, _Digits);
   if(ObjectFind(0, L_SL) < 0)
      CreateHLine(L_SL, p, InpSLColor, STYLE_SOLID, 2, true, "SL (sürükle)");
   else
      ObjectSetDouble(0, L_SL, OBJPROP_PRICE, p);
   return true;
}

//+------------------------------------------------------------------+
//| Hesaplama: SL çizgisi -> yön, giriş, TP, lot, risk                |
//+------------------------------------------------------------------+
bool Compute(bool &isBuy, double &entry, double &sl, double &tp, double &lot, double &risk, string &err)
{
   err = ""; tp = 0; lot = 0; risk = 0; entry = 0; sl = 0; isBuy = true;

   if(ObjectFind(0, L_SL) < 0) { err = "SL çizgisi yok"; return false; }

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(ask <= 0 || bid <= 0) { err = "Fiyat alınamadı"; return false; }

   sl = NormalizeDouble(ObjectGetDouble(0, L_SL, OBJPROP_PRICE), _Digits);

   if(sl < bid)      isBuy = true;    // çizgi fiyatın altında -> Buy
   else if(sl > ask) isBuy = false;   // çizgi fiyatın üstünde -> Sell
   else { err = "Çizgi fiyata çok yakın"; return false; }

   entry = isBuy ? ask : bid;
   double dist = MathAbs(entry - sl);
   tp = NormalizeDouble(isBuy ? entry + InpRR * dist : entry - InpRR * dist, _Digits);

   // Broker minimum stop mesafesi
   long   sLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   long   fLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_FREEZE_LEVEL);
   double minDist = (double)MathMax(sLvl, fLvl) * _Point;
   double slDist  = isBuy ? (bid - sl) : (sl - ask);
   if(slDist < minDist) { err = "SL, broker min. mesafesinden yakın"; return false; }

   double lpl = LossPerLot(isBuy, entry, sl);
   if(lpl <= 0) { err = "Lot hesaplanamadı"; return false; }

   lot = FloorLot(curRisk / lpl);
   if(lot <= 0)
   {
      double minRisk = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN) * lpl;
      err = StringFormat("Min lot için risk >= %.2f", minRisk);
      return false;
   }
   risk = lot * lpl;
   return true;
}

//+------------------------------------------------------------------+
//| Ekranı güncelle (TP çizgisi + bilgi satırları)                   |
//+------------------------------------------------------------------+
void UpdateCalc()
{
   bool isBuy; double entry, sl, tp, lot, risk; string err;
   bool ok = Compute(isBuy, entry, sl, tp, lot, risk, err);

   // TP çizgisi
   if(tp > 0)
   {
      if(ObjectFind(0, L_TP) < 0) CreateHLine(L_TP, tp, InpTPColor, STYLE_DASH, 1, false, "TP");
      else                        ObjectSetDouble(0, L_TP, OBJPROP_PRICE, tp);
   }
   else
      ObjectDelete(0, L_TP);

   // Bilgi satırları
   if(entry > 0 && sl > 0)
   {
      double slPts = MathAbs(entry - sl) / _Point;
      ObjectSetString(0, N_INFO, OBJPROP_TEXT,
         StringFormat("%s  SL %s pt | TP %s pt (1:%s)", isBuy ? "BUY" : "SELL",
                      DoubleToString(slPts, 0), DoubleToString(slPts * InpRR, 0),
                      DoubleToString(InpRR, 1)));
   }
   else
      ObjectSetString(0, N_INFO, OBJPROP_TEXT, "-");

   if(ok)
   {
      ObjectSetString(0, N_INFO2, OBJPROP_TEXT,
         StringFormat("Lot %s | Risk $%.2f", DoubleToString(lot, LotDigits()), risk));
      ObjectSetInteger(0, N_INFO2, OBJPROP_COLOR, clrSilver);
   }
   else
   {
      ObjectSetString(0, N_INFO2, OBJPROP_TEXT, err);
      ObjectSetInteger(0, N_INFO2, OBJPROP_COLOR, clrTomato);
   }
   ChartRedraw();
}

// Her tick'te sunucu saatini tick damgasına (ms) göre kalibre et.
// Tick'e kadar geçen ağ gecikmesi ofseti hep küçültür, bu yüzden en büyük örneği tutuyoruz.
void SyncServerClock()
{
   long msc = SymbolInfoInteger(_Symbol, SYMBOL_TIME_MSC);
   if(msc <= 0) return;
   ulong loc  = GetTickCount64();
   long  cand = msc - (long)loc;
   if(!g_offTick || cand > g_off || loc - g_offAt > 300000)   // 5 dk'da bir tazele (saat kayması için)
   {
      g_off = cand; g_offAt = loc; g_offTick = true;
   }
}

// Şu anki sunucu zamanı (ms): son tick damgası + yerel monotonik saat
long ServerNowMs()
{
   if(!g_offTick)   // henüz tick gelmediyse geçici tahmin
      return (long)TimeTradeServer() * 1000 + (long)(GetTickCount64() % 1000);
   return (long)GetTickCount64() + g_off;
}

// Mevcut mumun kapanışına kalan süre (SS:DD:SN) - sunucunun mum damgalarıyla senkron
void UpdateTimer()
{
   static string lastTxt = "";
   static string lastClk = "";
   datetime open = iTime(_Symbol, PERIOD_CURRENT, 0);
   string txt = "--:--:--";
   long nowMs = ServerNowMs();
   if(open > 0)
   {
      long per = (long)PeriodSeconds(PERIOD_CURRENT);
      long remMs;
      if(per > 0 && per < 7 * 86400)
      {
         long perMs  = per * 1000;
         long elapsed = nowMs - (long)open * 1000;
         if(elapsed < 0) elapsed = 0;
         remMs = perMs - (elapsed % perMs);
      }
      else                                          // MN1 (değişken uzunluk)
      {
         MqlDateTime dt; TimeToStruct(open, dt);
         dt.mon++; if(dt.mon > 12) { dt.mon = 1; dt.year++; }
         remMs = (long)StructToTime(dt) * 1000 - nowMs;
         if(remMs < 0) remMs = 0;
      }
      long rem = remMs / 1000;                      // aşağı yuvarla: son saniyede 00:00 görünür, sonra tam süre
      txt = StringFormat("%02d:%02d:%02d", (int)(rem / 3600), (int)((rem % 3600) / 60), (int)(rem % 60));
   }
   string clk = TimeToString((datetime)(nowMs / 1000), TIME_MINUTES);
   bool changed = false;
   if(txt != lastTxt) { ObjectSetString(0, N_TIMER, OBJPROP_TEXT, txt); lastTxt = txt; changed = true; }
   if(clk != lastClk) { ObjectSetString(0, N_STIME, OBJPROP_TEXT, clk); lastClk = clk; changed = true; }
   if(changed) ChartRedraw();
}

void ShowRisk()
{
   ObjectSetString(0, N_RISK, OBJPROP_TEXT, DoubleToString(curRisk, 2));
}

//+------------------------------------------------------------------+
//| İşlem aç                                                         |
//+------------------------------------------------------------------+
void OpenTrade(bool wantBuy)
{
   bool isBuy; double entry, sl, tp, lot, risk; string err;
   if(!Compute(isBuy, entry, sl, tp, lot, risk, err))
   {
      Alert("İşlem açılmadı: ", err);
      return;
   }
   if(isBuy != wantBuy)
   {
      Alert(wantBuy ? "BUY için SL çizgisi fiyatın ALTINDA olmalı."
                    : "SELL için SL çizgisi fiyatın ÜSTÜNDE olmalı.");
      return;
   }

   // Marjin kontrolü
   double margin = 0;
   if(OrderCalcMargin(isBuy ? ORDER_TYPE_BUY : ORDER_TYPE_SELL, _Symbol, lot, entry, margin) &&
      margin > AccountInfoDouble(ACCOUNT_MARGIN_FREE))
   {
      Alert("Yetersiz marjin. Gereken: ", DoubleToString(margin, 2));
      return;
   }

   bool ok;
   if(isBuy) ok = trade.Buy (lot, _Symbol, 0.0, sl, tp, "QTP Buy");
   else      ok = trade.Sell(lot, _Symbol, 0.0, sl, tp, "QTP Sell");

   uint rc = trade.ResultRetcode();
   if(!ok || (rc != TRADE_RETCODE_DONE && rc != TRADE_RETCODE_PLACED))
      Alert("İşlem hatası: ", rc, " - ", trade.ResultRetcodeDescription());
   else
      PrintFormat("%s %s lot=%s SL=%s TP=%s risk=$%.2f", isBuy ? "BUY" : "SELL", _Symbol,
                  DoubleToString(lot, LotDigits()), DoubleToString(sl, _Digits),
                  DoubleToString(tp, _Digits), risk);
}

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

      double point   = SymbolInfoDouble(sym, SYMBOL_POINT);
      int    digits  = (int)SymbolInfoInteger(sym, SYMBOL_DIGITS);
      double bid     = SymbolInfoDouble(sym, SYMBOL_BID);
      double ask     = SymbolInfoDouble(sym, SYMBOL_ASK);
      long   lvl     = SymbolInfoInteger(sym, SYMBOL_TRADE_STOPS_LEVEL);
      double minDist = (double)lvl * point;

      double newSL;
      if(type == POSITION_TYPE_BUY)
      {
         newSL = NormalizeDouble(open + InpBEOffset * point, digits);
         if(curSL != 0.0 && curSL >= newSL) { skipped++; continue; }
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
//| Init / Deinit                                                    |
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

   curRisk = (InpRisk > 0) ? InpRisk : 10.0;

   N_BG     = P + "bg";
   N_TITLE  = P + "title";
   N_RLBL   = P + "rlbl";
   N_RISK   = P + "risk";
   N_BUY    = P + "buy";
   N_SELL   = P + "sell";
   N_CLOSE  = P + "closeall";
   N_BE     = P + "beall";
   N_ATRBTN = P + "atrbtn";
   N_INFO   = P + "info";
   N_INFO2  = P + "info2";
   N_TLBL   = P + "tlbl";
   N_TIMER  = P + "timer";
   N_SLBL   = P + "slbl";
   N_STIME  = P + "stime";
   L_SL     = P + "SL_LINE";
   L_TP     = P + "TP_LINE";

   int x = InpX, y = InpY;
   CreateRect  (N_BG,     x,       y,       190, 254, C'30,30,36');
   CreateLabel (N_TITLE,  "Quick Trade  |  " + _Symbol, x + 10, y + 6, clrSilver, 9);
   CreateLabel (N_RLBL,   "Risk ($):", x + 10, y + 33, clrWhite, 9);
   CreateEdit  (N_RISK,   "",          x + 75, y + 28, 105, 24);
   CreateLabel (N_TLBL,   "Mum:",      x + 10, y + 63, clrWhite, 9);
   CreateEdit  (N_TIMER,  "--:--:--",  x + 75, y + 58, 105, 24);
   ObjectSetInteger(0, N_TIMER, OBJPROP_READONLY, true);
   ObjectSetInteger(0, N_TIMER, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, N_TIMER, OBJPROP_BGCOLOR, C'20,20,24');
   ObjectSetInteger(0, N_TIMER, OBJPROP_BORDER_COLOR, clrGreen);
   ObjectSetInteger(0, N_TIMER, OBJPROP_FONTSIZE, 11);
   ObjectSetString (0, N_TIMER, OBJPROP_FONT, "Arial Bold");
   CreateLabel (N_SLBL,   "Sunucu:",   x + 10, y + 93, clrWhite, 9);
   CreateEdit  (N_STIME,  "--:--",     x + 75, y + 88, 105, 24);
   ObjectSetInteger(0, N_STIME, OBJPROP_READONLY, true);
   ObjectSetInteger(0, N_STIME, OBJPROP_COLOR, clrLime);
   ObjectSetInteger(0, N_STIME, OBJPROP_BGCOLOR, C'20,20,24');
   ObjectSetInteger(0, N_STIME, OBJPROP_BORDER_COLOR, clrGreen);
   ObjectSetInteger(0, N_STIME, OBJPROP_FONTSIZE, 11);
   ObjectSetString (0, N_STIME, OBJPROP_FONT, "Arial Bold");
   CreateButton(N_BUY,    "BUY",       x + 10,  y + 120,  80, 32, clrDodgerBlue);
   CreateButton(N_SELL,   "SELL",      x + 100, y + 120,  80, 32, clrCrimson);
   CreateButton(N_CLOSE,  "CLOSE ALL", x + 10,  y + 158,  80, 26, C'120,60,0');
   CreateButton(N_BE,     "BE ALL",    x + 100, y + 158,  80, 26, C'0,110,80');
   CreateButton(N_ATRBTN, "SL = 1 ATR",x + 10,  y + 188, 170, 24, C'70,70,80');
   CreateLabel (N_INFO,   "",          x + 10,  y + 218, clrSilver, 8);
   CreateLabel (N_INFO2,  "",          x + 10,  y + 234, clrSilver, 8);

   ShowRisk();
   SetSLByATR(false);                       // ATR hazırsa çizgiyi hemen koy (değilse timer koyar)
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
   EventSetMillisecondTimer(250);
   UpdateTimer();
   UpdateCalc();
   return INIT_SUCCEEDED;
}

void OnDeinit(const int reason)
{
   EventKillTimer();
   ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, false);
   ObjectsDeleteAll(0, P);
   if(atrHandle != INVALID_HANDLE) IndicatorRelease(atrHandle);
   ChartRedraw();
}

void OnTimer()
{
   UpdateTimer();                                   // 250 ms'de bir (sadece metin değişince çizer)
   static ulong lastHeavy = 0;
   ulong t = GetTickCount64();
   if(t - lastHeavy >= 1000)                        // ağır işler saniyede bir
   {
      lastHeavy = t;
      if(ObjectFind(0, L_SL) < 0) SetSLByATR(false);   // çizgi yoksa (silindiyse / ATR yeni hazır) oluştur
      UpdateCalc();
   }
}

void OnTick()
{
   SyncServerClock();
   UpdateTimer();
   UpdateCalc();
}

//+------------------------------------------------------------------+
//| Olaylar                                                          |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == N_BUY || sparam == N_SELL || sparam == N_CLOSE || sparam == N_BE || sparam == N_ATRBTN)
         ObjectSetInteger(0, sparam, OBJPROP_STATE, false); // buton basılı kalmasın

      if(sparam == N_BUY)         OpenTrade(true);
      else if(sparam == N_SELL)   OpenTrade(false);
      else if(sparam == N_CLOSE)  CloseAll();
      else if(sparam == N_BE)     BreakevenAll();
      else if(sparam == N_ATRBTN)
      {
         if(!SetSLByATR(true)) Alert("ATR değeri alınamadı.");
         UpdateCalc();
      }
   }
   else if(id == CHARTEVENT_OBJECT_ENDEDIT && sparam == N_RISK)
   {
      string t = ObjectGetString(0, N_RISK, OBJPROP_TEXT);
      StringReplace(t, ",", ".");
      double v = StringToDouble(t);
      if(v > 0) curRisk = v;
      ShowRisk();
      UpdateCalc();
   }
   else if(id == CHARTEVENT_OBJECT_DRAG && sparam == L_SL)
   {
      UpdateCalc();
   }
   else if(id == CHARTEVENT_MOUSE_MOVE)
   {
      // Çizgi sürüklenirken TP/lot canlı güncellensin (hafif throttle)
      static uint last = 0;
      uint now = GetTickCount();
      if(now - last > 60) { last = now; UpdateCalc(); }
   }
}
//+------------------------------------------------------------------+
