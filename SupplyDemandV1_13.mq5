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
//|  V1.4: Yazida '|' sonrasi: ilk temasa kadar bolgeden uzaklasma     |
//|        (talepte +yukselis, arzda -dusus) ATR cinsinden; ilk        |
//|        temasta sabitlenir.                                         |
//|  V1.5: Ilk temas sonrasi TP/SL takibi (yazida '|' ile eklenir):    |
//|        TPn = bolge ust/alt kenarindan n x bolge yuksekligi hareket |
//|              (talep: yukari, arz: asagi), bolge ters yone         |
//|              kirilmadan. SLn = TPn'e ulasmadan bolge kirildi.     |
//|        Ayni mumda hem TPn hem kirilim varsa SLn yazilir.          |
//|  V1.6: Sol ustte TP1-3 / SL1-3 toplam sayilarini gosteren tablo.   |
//|  V1.7: Yazinin sonuna '| BOn': bolge olustugunda 1.mumdan sola    |
//|        dogru, bolge ust/alt sinirlariyla kesisen ardisik mum       |
//|        sayisi (kesismeyen ilk mumda durur, 1.mum dahil).          |
//|  V1.8: Yazinin sonuna '| YPn': bolge olustugunda 1.mumdan once    |
//|        YPLookback (vars. 240) mum geriye gidilir; bolge alt/ust    |
//|        sinirlariyla kesisen (temas eden) mum sayisi yazilir.      |
//|  V1.9: Yazinin sonuna '| ORJ' / '| NORJ': bolge olustugunda, ayni  |
//|        yondeki (talep/arz) ve son ORJLookback (vars. 60) mum icinde |
//|        olusmus bir onceki bolgenin alanina (bolge kutusu + ilk FVG)|
//|        fiyat olarak girdiyse NORJ, girmediyse ORJ yazilir. Eski     |
//|        bolge temas edilmis / suresi dolmus olsa da sayilir.        |
//|  V1.10: Yazinin sonuna '| FFVGT': bolgeye ILK TEMAS OLMADAN, bir   |
//|        (kapanmis) mum bolgenin FVG'sine girip FVG'nin disinda      |
//|        kapandiysa (talep: ustunde, arz: altinda) eklenir.          |
//|  V1.11: Yazinin sonuna '| BUn': bolge olustuktan (3.mum) sonra,    |
//|        ILK TEMASTAN ONCE en uzak noktaya (talep: en yuksek high,    |
//|        arz: en dusuk low) kac mumda ulasildigi. Temas sonrasi      |
//|        bakilmaz.                                                   |
//|  V1.12: Yazinin sonuna '| BDn': en uzak noktadan (BU'daki mum)      |
//|        bolgeye ILK TEMAS mumuna kac mumda donuldugu. Temas        |
//|        olmadiysa yazilmaz.                                         |
//|  V1.13: Yazinin sonuna '| BYn': bolge olusumundan (3.mum) ilk      |
//|        temas mumuna kadar gecen mum sayisi. Temas olmadiysa        |
//|        yazilmaz.                                                   |
//|  V1.14: Yazinin sonuna '| V' / '| UV': bolgeden (1.mum) onceki     |
//|        swing seviyesi (talep: son swing high, arz: son swing low)   |
//|        bolge olustuktan sonra (3.mumdan ilk temasa kadar, KAPANISLA)|
//|        kirildiysa V, kirilmadiysa UV.                              |
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
input bool    ShowStatsTable     = true;                    // Sol ustte TP/SL sayac tablosunu goster
input int     TableX             = 10;                      // Tablo yatay konum (piksel)
input int     TableY             = 20;                      // Tablo dikey konum (piksel)
input color   TableBgColor       = clrWhite;                // Tablo arka plan rengi
input int     YPLookback         = 240;                     // YP: bolge olusurken geriye kac mum taransin (temas sayisi)
input int     SwingStrength      = 2;                       // V/UV: swing icin her iki yanda kac mum (fractal gucu)
input int     SwingLookback      = 100;                     // V/UV: swing aramak icin 1.mumdan geriye kac mum bakilsin
input int     ORJLookback        = 60;                      // ORJ/NORJ: onceki ayni yonlu bolge icin geriye kac mum taransin
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
   double   ext;          // ilk temasa kadar ulasilan uc fiyat (talep: en yuksek high, arz: en dusuk low)
   int      touchIdx;     // ilk temas edilen bar (-1: henuz yok)
   int      outLast;      // sonuc takibinde en son islenen (kapanmis) bar
   bool     trackDone;    // takip bitti (3 seviye de sonuclandi ya da temas hic olmadi)
   int      out[3];       // TP1..TP3 sonucu: 0 = bekliyor, 1 = TP, 2 = SL
   int      bo;           // bolgeyi olusturan (sola dogru ardisik kesisen) mum sayisi
   int      yp;           // olusumdan once YPLookback mum icinde bolgeye temas eden mum sayisi
   double   fvgFar;       // FVG'nin bolgeden uzak ucu (talep: 3.mum low, arz: 3.mum high)
   bool     orj;          // true: ORJ (onceki bolge alanina girmedi), false: NORJ
   bool     ffvgt;        // ilk temastan once FVG'ye girip disinda kapanis yapildi mi
   int      extIdx;       // ext (en uzak nokta) degerine ulasilan bar index'i
   double   swLevel;      // kirilmasi beklenen onceki swing seviyesi (0 = swing bulunamadi)
   bool     vbrk;         // swing seviyesi kapanisla kirildi mi (V / UV)
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
//| startIdx mumundan baslayip sola dogru, high-low araligi bolgenin   |
//| [bottom,top] sinirlariyla kesisen ardisik mumlari say.             |
//| Kesismeyen ilk mumda durur.                                       |
//+------------------------------------------------------------------+
int CountBO(const double &high[],const double &low[],int startIdx,double top,double bottom)
  {
   int cnt = 0;
   for(int j=startIdx; j>=0; j--)
     {
      if(high[j] >= bottom && low[j] <= top)
         cnt++;
      else
         break;
     }
   return(cnt);
  }

//+------------------------------------------------------------------+
//| startIdx mumundan baslayip sola dogru lookback mum tara; high-low  |
//| araligi bolgenin [bottom,top] sinirlariyla kesisen mumlari say.    |
//| (Ardisik olmasi gerekmez, kesismeyen mumda durulmaz.)             |
//+------------------------------------------------------------------+
int CountYP(const double &high[],const double &low[],int startIdx,int lookback,double top,double bottom)
  {
   int cnt = 0;
   int stop = MathMax(0,startIdx-lookback+1);
   for(int j=startIdx; j>=stop; j--)
     {
      if(high[j] >= bottom && low[j] <= top)
         cnt++;
     }
   return(cnt);
  }

//+------------------------------------------------------------------+
//| Yeni bolge (newC1 = 1.mum index'i), ayni yondeki ve son lookback    |
//| mum icinde (baseIdx) olusmus bir onceki bolgenin alanina fiyat     |
//| olarak girdi mi?                                                  |
//| Onceki bolge alani: bolge kutusu + ilk FVG (kutuya bitisik).       |
//|  Talep: [bottom , 3.mum low]     Arz: [3.mum high , top]          |
//| Hicbir bolge olu sayilmaz (temas / yas siniri dikkate alinmaz).    |
//| Donus: true = ORJ, false = NORJ                                   |
//+------------------------------------------------------------------+
bool IsOriginalZone(const double &high[],const double &low[],int newC1,bool isDemand,
                    double top,double bottom,int lookback)
  {
   for(int m=ArraySize(zones)-1; m>=0; m--)
     {
      if(zones[m].baseIdx < newC1-lookback)
         break; // baseIdx artan sirada; daha geriye gitmeye gerek yok
      if(zones[m].baseIdx >= newC1 || zones[m].isDemand!=isDemand)
         continue;

      // Onceki bolgenin alani (kutu + FVG)
      double aLow  = isDemand ? zones[m].bottom : zones[m].fvgFar;
      double aHigh = isDemand ? zones[m].fvgFar : zones[m].top;
      if(aLow > aHigh) { double t=aLow; aLow=aHigh; aHigh=t; }

      // Yeni bolgenin fiyat araligi bu alanla kesisiyor mu?
      if(top >= aLow && bottom <= aHigh)
         return(false); // NORJ
     }
   return(true); // ORJ
  }

//+------------------------------------------------------------------+
//| Bolgenin 1.mumundan (c1) onceki en yakin swing seviyesini bul.     |
//|  Talep: son swing HIGH (seviye bolge ustunun ustunde olmali)      |
//|  Arz:   son swing LOW  (seviye bolge altinin altinda olmali)      |
//| Swing: sol ve sag 'strength' mumdan yuksek (talep) / dusuk (arz).  |
//| Sag taraftaki mumlar c1'den once olmali (c1 haric).                |
//| Donus: seviye, bulunamazsa 0.0                                    |
//+------------------------------------------------------------------+
double FindSwingLevel(const double &high[],const double &low[],int c1,bool isDemand,
                      double top,double bottom,int strength,int lookback)
  {
   int st = MathMax(1,strength);
   int sFrom = c1-1-st;
   int sTo   = MathMax(st,c1-1-lookback);
   for(int s=sFrom; s>=sTo; s--)
     {
      bool ok = true;
      if(isDemand)
        {
         for(int k=1;k<=st && ok;k++)
            if(!(high[s] > high[s-k] && high[s] >= high[s+k]))
               ok = false;
         if(ok && high[s] > top)
            return(high[s]);
        }
      else
        {
         for(int k=1;k<=st && ok;k++)
            if(!(low[s] < low[s-k] && low[s] <= low[s+k]))
               ok = false;
         if(ok && low[s] < bottom)
            return(low[s]);
        }
     }
   return(0.0);
  }

//+------------------------------------------------------------------+
//| Sonuc takibi alanlarini sifirla                                  |
//+------------------------------------------------------------------+
void InitOutcome(SDZoneInfo &z)
  {
   z.touchIdx  = -1;
   z.outLast   = -1;
   z.trackDone = false;
   z.ffvgt     = false;
   z.extIdx    = z.fvgIdx;
   z.vbrk      = false;
   z.swLevel   = 0.0;
   for(int q=0;q<3;q++)
      z.out[q] = 0;
  }

//+------------------------------------------------------------------+
//| Ilk temastan sonra TP1-TP3 / SL1-SL3 sonuclarini guncelle.        |
//| Yalnizca KAPANMIS mumlar islenir (closedLast'a kadar).            |
//| - Kirilim: talepte low < bolge alti, arzda high > bolge ustu      |
//| - TPn:     bolge ust (talep) / alt (arz) kenarindan n x bolge     |
//|            yuksekligi kadar hareket                               |
//| - Temas mumunda yalnizca kirilim kontrol edilir (TP sayilmaz,     |
//|   cunku mum icindeki sira bilinemez).                             |
//| - Ayni mumda TPn ve kirilim birlikte olursa SLn yazilir.          |
//| Donus: bir seviye yeni sonuclandiysa true                         |
//+------------------------------------------------------------------+
bool UpdateOutcome(SDZoneInfo &z,const double &high[],const double &low[],int closedLast)
  {
   if(z.touchIdx<0 || z.trackDone)
      return(false);

   bool   changed = false;
   double h       = z.top - z.bottom;
   int    from    = MathMax(z.touchIdx,z.outLast+1);

   for(int j=from;j<=closedLast;j++)
     {
      bool broke = z.isDemand ? (low[j] < z.bottom) : (high[j] > z.top);

      for(int n=1;n<=3;n++)
        {
         if(z.out[n-1]!=0)
            continue;

         bool reached = false;
         if(j>z.touchIdx)
            reached = z.isDemand ? (high[j] >= z.top    + n*h)
                                 : (low[j]  <= z.bottom - n*h);

         if(broke)            // kirilim oncelikli (ayni mumda ikisi de olsa SL)
           {
            z.out[n-1] = 2;
            changed    = true;
           }
         else if(reached)
           {
            z.out[n-1] = 1;
            changed    = true;
           }
        }

      z.outLast = j;
      if(z.out[0]!=0 && z.out[1]!=0 && z.out[2]!=0)
        {
         z.trackDone = true;
         break;
        }
     }
   return(changed);
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

      // Bolge genisligi | ilk temasa kadar bolgeden uzaklasma (talep: +yukselis, arz: -dusus)
      double move = z.isDemand ? MathMax(0.0,z.ext-z.top) : MathMax(0.0,z.bottom-z.ext);
      string mv   = (move>0.0 ? (z.isDemand ? "+" : "-") : "") + DoubleToString(move/z.atr,2);
      // Sonuclanmis seviyeler: seviye sirasiyla " | tp1 | tp2 | sl3" gibi
      string res = "";
      for(int q=0;q<3;q++)
        {
         if(z.out[q]==1)
            res += " | tp"+IntegerToString(q+1);
         else if(z.out[q]==2)
            res += " | sl"+IntegerToString(q+1);
        }
      string txt = DoubleToString((z.top-z.bottom)/z.atr,2)+" ATR | "+mv+" ATR"+res+" | BO"+IntegerToString(z.bo)+" | YP"+IntegerToString(z.yp)+(z.orj ? " | ORJ" : " | NORJ")+(z.ffvgt ? " | FFVGT" : "")+" | BU"+IntegerToString(z.extIdx-z.fvgIdx)+(z.touchIdx>=0 ? " | BD"+IntegerToString(z.touchIdx-z.extIdx)+" | BY"+IntegerToString(z.touchIdx-z.fvgIdx) : "")+(z.vbrk ? " | V" : " | UV");
      // MT5 nesne yazisi en fazla 63 karakter: uzunsa kesilmesin diye ayiraclardaki bosluklar kaldirilir
      if(StringLen(txt)>63)
         StringReplace(txt," | ","|");
      if(StringLen(txt)>63)             // hala uzunsa (cok nadir): " ATR" ekleri de kaldirilir
         StringReplace(txt," ATR","");
      ObjectSetString(0,l,OBJPROP_TEXT,txt);
      ObjectSetString(0,l,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,l,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,l,OBJPROP_COLOR,bc);
      ObjectSetInteger(0,l,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0,l,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,l,OBJPROP_HIDDEN,true);
     }
  }

//+------------------------------------------------------------------+
//| Tek bir tablo hucresi (etiket) olustur / guncelle                 |
//+------------------------------------------------------------------+
void SetCell(string name,int x,int y,string text,color clr)
  {
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
     }
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }

//+------------------------------------------------------------------+
//| Sol ust kose TP/SL sayac tablosu (talep + arz toplami)            |
//|          TP    SL                                                 |
//|   1       a     b                                                 |
//|   2       c     d                                                 |
//|   3       e     f                                                 |
//+------------------------------------------------------------------+
void DrawStatsTable()
  {
   if(!ShowStatsTable)
      return;

   int tp[3]={0,0,0};
   int sl[3]={0,0,0};
   int total = ArraySize(zones);
   for(int k=0;k<total;k++)
      for(int q=0;q<3;q++)
        {
         if(zones[k].out[q]==1)
            tp[q]++;
         else if(zones[k].out[q]==2)
            sl[q]++;
        }

   int rowH = 18, w = 150, h = rowH*4+10;
   string bg = prefix + "STAT_BG";
   if(ObjectFind(0,bg)<0)
     {
      ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,bg,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,bg,OBJPROP_BACK,false);
     }
   ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,TableX);
   ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,TableY);
   ObjectSetInteger(0,bg,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,bg,OBJPROP_YSIZE,h);
   ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,TableBgColor);
   ObjectSetInteger(0,bg,OBJPROP_COLOR,clrDimGray);

   int x0 = TableX+10, x1 = TableX+60, x2 = TableX+105;
   int y0 = TableY+5;

   SetCell(prefix+"STAT_H0",x0,y0,"Seviye",clrBlack);
   SetCell(prefix+"STAT_H1",x1,y0,"TP",clrGreen);
   SetCell(prefix+"STAT_H2",x2,y0,"SL",clrRed);

   for(int q=0;q<3;q++)
     {
      int y = y0 + rowH*(q+1);
      string id = IntegerToString(q+1);
      SetCell(prefix+"STAT_R"+id+"0",x0,y,id,clrBlack);
      SetCell(prefix+"STAT_R"+id+"1",x1,y,IntegerToString(tp[q]),clrGreen);
      SetCell(prefix+"STAT_R"+id+"2",x2,y,IntegerToString(sl[q]),clrRed);
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
         z.fvgFar      = low[c3];
         z.ext         = z.top;
         InitOutcome(z);
         z.bo          = CountBO(high,low,c1,z.top,z.bottom);
         z.yp          = CountYP(high,low,c1-1,YPLookback,z.top,z.bottom);
         z.orj         = IsOriginalZone(high,low,c1,z.isDemand,z.top,z.bottom,ORJLookback);
         z.swLevel     = FindSwingLevel(high,low,c1,z.isDemand,z.top,z.bottom,SwingStrength,SwingLookback);

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
         z.fvgFar      = high[c3];
         z.ext         = z.bottom;
         InitOutcome(z);
         z.bo          = CountBO(high,low,c1,z.top,z.bottom);
         z.yp          = CountYP(high,low,c1-1,YPLookback,z.top,z.bottom);
         z.orj         = IsOriginalZone(high,low,c1,z.isDemand,z.top,z.bottom,ORJLookback);
         z.swLevel     = FindSwingLevel(high,low,c1,z.isDemand,z.top,z.bottom,SwingStrength,SwingLookback);

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
        {
         // YENI: temas edilmis bolgenin TP/SL sonucunu kapanmis mumlarla takip et
         if(!zones[k].trackDone && UpdateOutcome(zones[k],high,low,rates_total-2))
            DrawExtras(zones[k],time[zones[k].baseIdx],time[zones[k].touchIdx]);
         continue;
        }

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
            // YENI: temas olmayan barlarda ulasilan en yuksek seviyeyi takip et
            if(high[j] > zones[k].ext)
              {
               zones[k].ext    = high[j];
               zones[k].extIdx = j;   // BU: en uzak noktaya ulasilan bar
              }
            // FFVGT: ilk temastan once FVG'ye girip (low < FVG ust) ustunde kapanis
            if(!zones[k].ffvgt && j<=rates_total-2 && j>zones[k].fvgIdx &&
               low[j] < zones[k].fvgFar && close[j] > zones[k].fvgFar)
               zones[k].ffvgt = true;
            // V: onceki swing high, bolge olustuktan sonra (ilk temastan once) kapanisla kirildi mi
            if(!zones[k].vbrk && zones[k].swLevel>0.0 && j<=rates_total-2 && close[j] > zones[k].swLevel)
               zones[k].vbrk = true;
           }
         else
           {
            if(high[j] >= zones[k].bottom)
              {
               hit = true;
               hitIndex = j;
               break;
              }
            // YENI: temas olmayan barlarda ulasilan en dusuk seviyeyi takip et
            if(low[j] < zones[k].ext)
              {
               zones[k].ext    = low[j];
               zones[k].extIdx = j;   // BU: en uzak noktaya ulasilan bar
              }
            // FFVGT: ilk temastan once FVG'ye girip (high > FVG alt) altinda kapanis
            if(!zones[k].ffvgt && j<=rates_total-2 && j>zones[k].fvgIdx &&
               high[j] > zones[k].fvgFar && close[j] < zones[k].fvgFar)
               zones[k].ffvgt = true;
            // V: onceki swing low, bolge olustuktan sonra (ilk temastan once) kapanisla kirildi mi
            if(!zones[k].vbrk && zones[k].swLevel>0.0 && j<=rates_total-2 && close[j] < zones[k].swLevel)
               zones[k].vbrk = true;
           }
        }

      datetime tStart = time[zones[k].baseIdx];

      if(hit)
        {
         zones[k].touched     = true;
         zones[k].lastChecked = hitIndex;
         zones[k].touchIdx    = hitIndex;      // YENI: sonuc takibi bu bardan baslar
         zones[k].outLast     = hitIndex-1;
         UpdateOutcome(zones[k],high,low,rates_total-2);
         color clr = zones[k].isDemand ? DemandColor : SupplyColor;
         DrawZone(zones[k].objName,tStart,time[hitIndex],zones[k].top,zones[k].bottom,clr);
         DrawEquilibrium(zones[k].eqName,tStart,time[hitIndex],zones[k].top,zones[k].bottom);
         DrawExtras(zones[k],tStart,time[hitIndex]);
        }
      else if(lastBar>=expiryIdx)
        {
         // YENI: Bolge yasini doldurdu, temas olmadi -> expiryIdx'te biter, bir daha cizilmez
         zones[k].touched     = true; // dongude tekrar islenmesin
         zones[k].trackDone   = true; // temas olmadi -> TP/SL takibi yok
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

   DrawStatsTable();

   return(rates_total);
  }
//+------------------------------------------------------------------+
