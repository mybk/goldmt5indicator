//+------------------------------------------------------------------+
//|                                       SupplyDemand_FVG.mq5        |
//|  FVG'lere dayali arz / talep bolgesi (supply/demand zone) ciza.   |
//|                                                                     |
//|  Mum tanimlari (bir FVG icin):                                    |
//|    1. mum = FVG'nin ilk mumu   (index i-2)                        |
//|    2. mum = FVG mumu (displacement / gap'i olusturan mum) (i-1)    |
//|    3. mum = FVG'yi dogrulayan mum (index i)                        |
//|                                                                     |
//|  Bolge (arz/talep) her zaman 1. muma dayanir:                     |
//|    Talep: ust = 1.mum high, alt = 1.mum low; eger 2.mum low        |
//|           1.mum low'dan daha asagidaysa alt sinir oraya tasinir.   |
//|    Arz:   alt = 1.mum low, ust = 1.mum high; eger 2.mum high       |
//|           1.mum high'dan daha yukariysa ust sinir oraya tasinir.   |
//|                                                                     |
//|  OZEL DURUM 1 (mevcut): 1.mum ve 2.mum kendi basina birer FVG'nin  |
//|    tamamlayici (3.) mumu ise, bolge kosulsuz olarak 1.mum ile      |
//|    2.mum arasina sabitlenir.                                      |
//|                                                                     |
//|  OZEL DURUM 2 (yeni): Su anki 1.mum, DAHA ONCE OLUSMUS ayni        |
//|    yondeki bir bolgenin 2.mumu (displacement mumu) ise, bolge      |
//|    kosulsuz olarak 1.mum ile su anki 2.mum arasina sabitlenir.     |
//|    (Talep icin: onceki bir talep bolgesinin 2.mumu.                |
//|     Arz icin:   onceki bir arz bolgesinin 2.mumu.)                 |
//|                                                                     |
//|  Kutu, fiyat bolgeye ilk temas edene kadar saga dogru uzatilir.   |
//|  V1.2: Uyumlu renkli kenar cizgisi + bolge genisligi (ATR(14) kati) |
//|  V1.3: Bolge yasi siniri (MaxZoneAgeBars) - sonra uzama durur.     |
//+------------------------------------------------------------------+
#property copyright "Claude"
#property indicator_chart_window
#property indicator_plots 0

//--- Ayarlanabilir parametreler
input bool    ShowDemandZones   = true;             // Talep (destek) bolgelerini goster
input bool    ShowSupplyZones   = true;              // Arz (direnc) bolgelerini goster
input color   DemandColor       = clrLightCyan;       // Talep bolgesi rengi
input color   SupplyColor       = clrMistyRose;        // Arz bolgesi rengi
input bool    ShowBorder        = true;                 // Kutu kenar cizgisi
input bool    ShowEquilibrium   = true;                  // Ortadaki denge (50%) noktasini goster
input color   EquilibriumColor  = clrYellow;              // Denge noktasi rengi
input int     MaxHistoryBars    = 5000;                    // Geriye donuk en fazla kac bar taransin (0 = sinirsiz)
input bool    WaitForCandleClose = true;                 // Bolgeyi sadece KAPANMIS mumlara gore ciz (3. mum kapanisini bekle)

input color   DemandBorderColor  = clrDodgerBlue;           // Talep kenar cizgisi rengi
input color   SupplyBorderColor  = clrIndianRed;            // Arz kenar cizgisi rengi
input int     BorderWidth        = 1;                       // Kenar cizgisi kalinligi
input bool    ShowATRLabel       = true;                    // Bolge genisligini ATR cinsinden yaz
input int     ATRPeriod          = 14;                      // ATR periyodu
input int     MaxZoneAgeBars     = 60;                      // Bolgenin azami yasi (mum). Sonra saga uzamaz (0 = sinirsiz)

string prefix = "SDZ_";
int    atrHandle = INVALID_HANDLE;
double atrBuf[];

//+------------------------------------------------------------------+
//| Verilen a (1.mum) ve c (3.mum) index'leri bir FVG olusturuyor mu? |
//+------------------------------------------------------------------+
bool IsFVG(const double &high[],const double &low[],int a,int c,bool bullish)
  {
   if(a<0 || c<0)
      return(false);
   if(bullish)
      return(low[c] > high[a]);
   else
      return(high[c] < low[a]);
  }

//+------------------------------------------------------------------+
//| Zone bilgisini tutan yapi                                        |
//+------------------------------------------------------------------+
struct SDZoneInfo
  {
   int      baseIdx;      // 1. mumun index'i (kutunun sol kenari)
   int      fvgIdx;       // 3. mumun index'i (FVG'nin dogrulandigi bar)
   bool     isDemand;
   double   top;
   double   bottom;
   bool     touched;
   int      lastChecked;
   string   objName;
   string   eqName;
   string   borderName;   // kenar cizgisi nesnesi
   string   lblName;      // ATR yazisi nesnesi
   double   atr;          // 3. mum barindaki ATR degeri
  };

SDZoneInfo zones[];
int lastScanned = -1;   // yeni bolge taramasinda en son islenen bar (tekrar taramayi onler)

//+------------------------------------------------------------------+
//| idx indexli mum, daha once olusmus (wantDemand yonundeki) bir     |
//| bolgenin "2. mumu" (displacement mumu) muydu?                    |
//| zones[] dizisi baseIdx'e gore artan sirada oldugu icin (her       |
//| iterasyonda en fazla bir zone eklendigi ve i artarak ilerledigi   |
//| icin), sondan basa dogru arayip ilk uyumsuzlukta durabiliriz.     |
//+------------------------------------------------------------------+
bool WasSecondCandleOfZone(int idx,bool wantDemand)
  {
   for(int m=ArraySize(zones)-1; m>=0; m--)
     {
      if(zones[m].baseIdx < idx-1)
         break; // dizide daha geriye gitmenin anlami yok, baseIdx kucule kucule gidiyor

      if(zones[m].baseIdx == idx-1 && zones[m].isDemand==wantDemand)
         return(true);
     }
   return(false);
  }

//+------------------------------------------------------------------+
//| Zone kutusu olustur / guncelle                                   |
//+------------------------------------------------------------------+
void DrawZone(string name,datetime tStart,datetime tEnd,double top,double bottom,color clr)
  {
   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_RECTANGLE,0,tStart,top,tEnd,bottom);
   else
     {
      ObjectMove(0,name,0,tStart,top);
      ObjectMove(0,name,1,tEnd,bottom);
     }

   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(0,name,OBJPROP_FILL,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,ShowBorder?1:0);
   ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
  }

//+------------------------------------------------------------------+
//| Bolgenin ortasina denge (equilibrium) noktasi ciz                 |
//+------------------------------------------------------------------+
void DrawEquilibrium(string name,datetime tStart,datetime tEnd,double top,double bottom)
  {
   if(!ShowEquilibrium)
      return;

   datetime tMid = tStart + (long)((tEnd - tStart)/2);
   double   pMid = (top+bottom)/2.0;

   if(ObjectFind(0,name)<0)
      ObjectCreate(0,name,OBJ_ARROW,0,tMid,pMid);
   else
      ObjectMove(0,name,0,tMid,pMid);

   ObjectSetInteger(0,name,OBJPROP_ARROWCODE,159); // dolu nokta
   ObjectSetInteger(0,name,OBJPROP_COLOR,EquilibriumColor);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
   ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
   ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
   ObjectSetInteger(0,name,OBJPROP_BACK,true);
  }

//+------------------------------------------------------------------+
//| Kenar cizgisi (ayri, dolgusuz dikdortgen) + ATR yazisi            |
//+------------------------------------------------------------------+
void DrawExtras(const SDZoneInfo &z,datetime tStart,datetime tEnd)
  {
   color bc = z.isDemand ? DemandBorderColor : SupplyBorderColor;

   if(ShowBorder)
     {
      string n = z.borderName;
      if(ObjectFind(0,n)<0)
         ObjectCreate(0,n,OBJ_RECTANGLE,0,tStart,z.top,tEnd,z.bottom);
      else
        {
         ObjectMove(0,n,0,tStart,z.top);
         ObjectMove(0,n,1,tEnd,z.bottom);
        }
      ObjectSetInteger(0,n,OBJPROP_COLOR,bc);
      ObjectSetInteger(0,n,OBJPROP_FILL,false);
      ObjectSetInteger(0,n,OBJPROP_BACK,true);
      ObjectSetInteger(0,n,OBJPROP_WIDTH,BorderWidth);
      ObjectSetInteger(0,n,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
     }

   if(ShowATRLabel && z.atr>0.0)
     {
      string l = z.lblName;
      // Talep: sag alt kose (kutunun altinda), Arz: sag ust kose (kutunun ustunde)
      double price = z.isDemand ? z.bottom : z.top;
      if(ObjectFind(0,l)<0)
         ObjectCreate(0,l,OBJ_TEXT,0,tEnd,price);
      else
         ObjectMove(0,l,0,tEnd,price);

      ObjectSetString(0,l,OBJPROP_TEXT,DoubleToString((z.top-z.bottom)/z.atr,2)+" ATR");
      ObjectSetString(0,l,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,l,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,l,OBJPROP_COLOR,bc);
      ObjectSetInteger(0,l,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0,l,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,l,OBJPROP_HIDDEN,true);
     }
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   ArrayResize(zones,0);
   lastScanned = -1;
   atrHandle = iATR(_Symbol,_Period,ATRPeriod);
   if(atrHandle==INVALID_HANDLE)
      return(INIT_FAILED);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0,prefix);
   if(atrHandle!=INVALID_HANDLE)
      IndicatorRelease(atrHandle);
  }

//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total<3)
      return(0);

   //--- ATR verisini bar index'leriyle ayni sirada (eskiden yeniye) al
   if(BarsCalculated(atrHandle)<rates_total)
      return(0);
   ArraySetAsSeries(atrBuf,false);
   if(CopyBuffer(atrHandle,0,0,rates_total,atrBuf)<rates_total)
      return(0);

   int firstBar = 4; // en az c1-2 index'ine erisim gerekli (i-4)
   if(MaxHistoryBars>0 && rates_total-MaxHistoryBars>firstBar)
      firstBar = rates_total-MaxHistoryBars;

   //--- Tam yeniden hesaplama: eski bolgeleri ve nesneleri temizle
   if(prev_calculated==0)
     {
      ObjectsDeleteAll(0,prefix);
      ArrayResize(zones,0);
      lastScanned = firstBar-1;
     }

   //--- Son islenecek bar: mum kapanisi bekleniyorsa olusmakta olan mumu (rates_total-1) atla
   int lastBar = WaitForCandleClose ? rates_total-2 : rates_total-1;
   if(lastBar<firstBar)
      return(rates_total);

   //--- Yeni bolgeleri tespit et (her bar yalnizca bir kez islenir)
   for(int i=lastScanned+1;i<=lastBar;i++)
     {
      int c1 = i-2; // 1. mum
      int c2 = i-1; // 2. mum (FVG mumu)
      int c3 = i;   // 3. mum (dogrulayan mum)

      //--- Yukselis FVG -> Talep bolgesi
      if(ShowDemandZones && low[c3]>high[c1])
        {
         double zTop    = high[c1];  // 1. mumun tepesi (her zaman)
         double zBottom = low[c1];   // varsayilan: 1. mumun dibi

         // 1. mum kendisi ayri bir FVG'nin tamamlayici (3.) mumu MU,
         // VE 2. mum da kendisi ayri bir FVG'nin tamamlayici (3.) mumu MU?
         bool c1IsFVG = IsFVG(high,low,c1-2,c1,true);
         bool c2IsFVG = IsFVG(high,low,c1-1,c2,true);

         // YENI: su anki 1.mum, daha once olusmus bir TALEP bolgesinin
         // 2.mumu (displacement mumu) muydu?
         bool c1WasSecondOfDemand = WasSecondCandleOfZone(c1,true);

         if((c1IsFVG && c2IsFVG) || c1WasSecondOfDemand)
           {
            // Ozel durum: bolge = 1.mum tepesi ile 2.mum dibi arasi (kosulsuz)
            zBottom = low[c2];
           }
         else
           {
            // Genel/eski kural: sadece 2.mum daha asagi dip yaptiysa oraya tasi
            if(low[c2] < zBottom)
               zBottom = low[c2];
           }

         SDZoneInfo z;
         z.baseIdx     = c1;
         z.fvgIdx      = c3;
         z.isDemand    = true;
         z.top         = zTop;
         z.bottom      = zBottom;
         z.touched     = false;
         z.lastChecked = c2;
         z.objName     = prefix + "D_" + IntegerToString(c3);
         z.eqName      = prefix + "Deq_" + IntegerToString(c3);
         z.borderName  = prefix + "Dbd_" + IntegerToString(c3);
         z.lblName     = prefix + "Dlb_" + IntegerToString(c3);
         z.atr         = atrBuf[c3];

         int n = ArraySize(zones);
         ArrayResize(zones,n+1);
         zones[n] = z;

         DrawZone(z.objName,time[c1],time[c3],z.top,z.bottom,DemandColor);
         DrawEquilibrium(z.eqName,time[c1],time[c3],z.top,z.bottom);
         DrawExtras(z,time[c1],time[c3]);
        }

      //--- Dusus FVG -> Arz bolgesi
      if(ShowSupplyZones && high[c3]<low[c1])
        {
         double zBottom = low[c1];   // 1. mumun dibi (her zaman)
         double zTop    = high[c1];  // varsayilan: 1. mumun tepesi

         bool c1IsFVG = IsFVG(high,low,c1-2,c1,false);
         bool c2IsFVG = IsFVG(high,low,c1-1,c2,false);

         // YENI: su anki 1.mum, daha once olusmus bir ARZ bolgesinin
         // 2.mumu (displacement mumu) muydu?
         bool c1WasSecondOfSupply = WasSecondCandleOfZone(c1,false);

         if((c1IsFVG && c2IsFVG) || c1WasSecondOfSupply)
           {
            // Ozel durum: bolge = 1.mum dibi ile 2.mum tepesi arasi (kosulsuz)
            zTop = high[c2];
           }
         else
           {
            // Genel/eski kural: sadece 2.mum daha yuksek tepe yaptiysa oraya tasi
            if(high[c2] > zTop)
               zTop = high[c2];
           }

         SDZoneInfo z;
         z.baseIdx     = c1;
         z.fvgIdx      = c3;
         z.isDemand    = false;
         z.top         = zTop;
         z.bottom      = zBottom;
         z.touched     = false;
         z.lastChecked = c2;
         z.objName     = prefix + "S_" + IntegerToString(c3);
         z.eqName      = prefix + "Seq_" + IntegerToString(c3);
         z.borderName  = prefix + "Sbd_" + IntegerToString(c3);
         z.lblName     = prefix + "Slb_" + IntegerToString(c3);
         z.atr         = atrBuf[c3];

         int n = ArraySize(zones);
         ArrayResize(zones,n+1);
         zones[n] = z;

         DrawZone(z.objName,time[c1],time[c3],z.top,z.bottom,SupplyColor);
         DrawEquilibrium(z.eqName,time[c1],time[c3],z.top,z.bottom);
         DrawExtras(z,time[c1],time[c3]);
        }
     }

   if(lastBar>lastScanned)
      lastScanned = lastBar;

   //--- Var olan (temas edilmemis) bolgeleri kontrol et / saga uzat
   int total = ArraySize(zones);
   for(int k=0;k<total;k++)
     {
      if(zones[k].touched)
         continue;

      int checkFrom = MathMax(zones[k].fvgIdx, zones[k].lastChecked+1);
      bool hit = false;
      int hitIndex = -1;

      // YENI: yas siniri - bolge, 3. mumdan (fvgIdx) itibaren MaxZoneAgeBars mum yasar
      int  expiryIdx = (MaxZoneAgeBars>0) ? zones[k].fvgIdx+MaxZoneAgeBars : INT_MAX;
      int  scanTo    = MathMin(lastBar,expiryIdx);

      for(int j=checkFrom;j<=scanTo;j++)
        {
         if(zones[k].isDemand)
           {
            if(low[j] <= zones[k].top)
              {
               hit = true;
               hitIndex = j;
               break;
              }
           }
         else
           {
            if(high[j] >= zones[k].bottom)
              {
               hit = true;
               hitIndex = j;
               break;
              }
           }
        }

      datetime tStart = time[zones[k].baseIdx];

      if(hit)
        {
         zones[k].touched     = true;
         zones[k].lastChecked = hitIndex;
         color clr = zones[k].isDemand ? DemandColor : SupplyColor;
         DrawZone(zones[k].objName,tStart,time[hitIndex],zones[k].top,zones[k].bottom,clr);
         DrawEquilibrium(zones[k].eqName,tStart,time[hitIndex],zones[k].top,zones[k].bottom);
         DrawExtras(zones[k],tStart,time[hitIndex]);
        }
      else if(lastBar>=expiryIdx)
        {
         // YENI: Bolge yasini doldurdu, temas olmadi -> expiryIdx'te biter, bir daha cizilmez
         zones[k].touched     = true; // dongude tekrar islenmesin
         zones[k].lastChecked = expiryIdx;
         color clr = zones[k].isDemand ? DemandColor : SupplyColor;
         DrawZone(zones[k].objName,tStart,time[expiryIdx],zones[k].top,zones[k].bottom,clr);
         DrawEquilibrium(zones[k].eqName,tStart,time[expiryIdx],zones[k].top,zones[k].bottom);
         DrawExtras(zones[k],tStart,time[expiryIdx]);
        }
      else
        {
         // Kapanis bekleniyorsa lastBar tamamen kontrol edildi; beklenmiyorsa
         // olusmakta olan mum her tick'te yeniden kontrol edilsin diye bir geri al.
         zones[k].lastChecked = WaitForCandleClose ? lastBar : lastBar-1;
         color clr = zones[k].isDemand ? DemandColor : SupplyColor;
         DrawZone(zones[k].objName,tStart,time[lastBar],zones[k].top,zones[k].bottom,clr);
         DrawEquilibrium(zones[k].eqName,tStart,time[lastBar],zones[k].top,zones[k].bottom);
         DrawExtras(zones[k],tStart,time[lastBar]);
        }
     }

   return(rates_total);
  }
//+------------------------------------------------------------------+
