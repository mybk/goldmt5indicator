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
//|  V1.15: Grafikte 'S' tusuna basinca tum bolgeler (olusum / ilk      |
//|        temas tarihi dakikali + tum etiketler) CSV'ye yazilir.      |
//|        Dosya: <Veri klasoru>\MQL5\Files\SDZ_<sembol>_<TF>_<tarih>.csv|
//|  V1.16: Sol ust tabloya Net R kolonu eklendi (Net R = TPn*n - SLn,  |
//|        yani seviye n: risk 1R, odul nR). Tablonun altinda FILTRE    |
//|        paneli: Tip, Genislik/Uzaklasma (ATR), BO, YP, BU, BD, BY    |
//|        icin min-max araligi (ac/kapa), ORJ/NORJ, FFVGT, V/UV secimi.|
//|        Tablo (TP/SL/Net R) sadece filtreden gecen bolgelerle        |
//|        yeniden hesaplanir.                                         |
//|  V1.17: Gun ici SAAT filtresi (orn. 03:00 - 06:00, sunucu saati,    |
//|        iki ucu dahil, gece yarisini asan aralik da olur: 22:00-03:00)|
//|        Referans zaman: olusum (3.mum) / baslangic (1.mum) / ilk temas|
//|  V1.18: TARIH filtresi: baslangic ve bitis (GG.AA.YYYY, iki ucu      |
//|        dahil, bos = sinirsiz). Saat filtresiyle ayni referans zamani |
//|        kullanir.                                                    |
//|  V1.19: Filtre ayarlaninca YALNIZCA filtreden gecen bolgeler        |
//|        grafikte gorunur; gecmeyenlerin kutu / kenar / denge noktasi  |
//|        / yazi nesneleri gizlenir. Filtre sifirlaninca hepsi geri     |
//|        gelir (nesneler silinmez, sadece zaman dilimi gorunurlugu).   |
//|  V1.20: PERFORMANS (mantik degismedi, 400k+ mumda hizli yukleme):  |
//|        - Nesneler yalnizca GORUNEN pencere (+kenar payi) icinde ve  |
//|          filtreden gecen bolgeler icin olusturulur; kaydirma/zoom   |
//|          ile otomatik olusur / silinir (CHARTEVENT_CHART_CHANGE).   |
//|        - Her bolge yalnizca 1 kez cizilir, sabit ozellikler sadece  |
//|          olusturmada set edilir; degismeyen bolge yeniden cizilmez. |
//|        - Filtre hic aktif degilken filtre/gorunurluk maliyeti = 0.  |
//|        - Tablo/panel yalnizca degisim oldugunda guncellenir.        |
//|        - ATR tamponu her tickte tum seriyi degil, yalniz yeni        |
//|          barlari kopyalar. Aktif bolge listesi: biten bolgeler       |
//|          her tickte taranmaz. ArrayResize rezervli.                 |
//|  V1.21: TP/SL seviyeleri 3'ten 8'e cikarildi (TP4..TP8 / SL4..SL8, |
//|        mantik TP3/SL3 ile birebir ayni: TPn = n x bolge yuksekligi,|
//|        odul nR / risk 1R). Yazida tp1-tp3 / sl1-sl3 eskisi gibi;   |
//|        tp4-tp8 / sl4-sl8 ikinci bir yaziya (talepte kutunun ust,   |
//|        arzda kutunun alt sag kosesi) yazilir (63 karakter siniri). |
//|        Tablo 8 seviyeye cikti ve Net R'dan sonra Ort R kolonu      |
//|        eklendi (Ort R = Net R / sonuclanan islem sayisi (TP+SL)).  |
//|        CSV: TP1..TP8 kolonlari.                                    |
//|  V1.22: Yeni aralik filtresi 'Ilk N Mum ATR': FVG'yi dogrulayan     |
//|        mum (3.mum) DAHIL N mumda (vars. N=3, FirstNCandles ile      |
//|        4-5 vb. yapilabilir) ilk temastan once bolgeden ulasilan    |
//|        en uzak hareket, ATR cinsinden (talep: yukari, arz: asagi).  |
//|        Panelde min-max olarak girilir. CSV'ye son kolon eklendi.    |
//|  V1.23: Tabloya Ort R'dan sonra Win% (winrate) kolonu eklendi:      |
//|        Win% = TP / (TP+SL) x 100 (sonuclanan islem yoksa '-').      |
//|  V1.24: Filtre paneline seviye bazli sonuc butonlari: TP1..TP8 ve   |
//|        SL1..SL8 (ac/kapa). Orn. yalnizca TP1 acikken sadece TP1     |
//|        olan bolgeler gorunur; SL3 acikken sadece SL3 olanlar.        |
//|        Ayni seviyede TPn + SLn birlikte acik: ikisinden biri (VEYA). |
//|        Farkli seviyeler birlikte (orn. TP1 + SL2): ikisi de (VE).    |
//|        Tablo (TP/SL/Net R) ve grafik bu filtreye gore guncellenir.   |
//|        Strateji (bolge, temas, TP/SL) mantigina dokunulmadi.         |
//|  V1.25: (1) Uc yeni aralik filtresi: FVG mumu (3.mum), ondan sonraki |
//|        mum ve onu izleyen mum icin ayri ayri 'mum ATR' degeri.      |
//|        CandleAtrMode=0: mum boyu (high-low)/ATR, =1: mumun bolge    |
//|        kenarindan uzaklasmasi/ATR. Yazi (2. etiket): 'M a/b/c'.      |
//|        (2) ARD filtresi: FVG mumundan sonra SeqCandles (vars. 3)     |
//|        mum ust uste, talepte bir oncekinin ustunde, arzda ALTINDA     |
//|        kapanirsa bolgede 'ARD' yazar; panelde ARD var / ARD yok.     |
//|        CSV'ye FVG_Mum_ATR, FVG1_Mum_ATR, FVG2_Mum_ATR, ARD eklendi.   |
//+------------------------------------------------------------------+
#property copyright "Claude"
#property indicator_chart_window
#property indicator_plots 0

//--- Ayarlanabilir parametreler
input bool    ShowDemandZones   = true;             // Talep (destek) bolgelerini goster
input bool    ShowSupplyZones   = true;              // Arz (direnc) bolgelerini goster
input color   DemandColor       = clrLightCyan;       // Talep bolgesi rengi
input color   SupplyColor       = clrMistyRose;        // Arz bolgesi rengi
input bool    ShowBorder        = false;                // Kutu kenar cizgisi
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
input bool    ShowFilterPanel    = true;                    // Tablonun altinda filtre panelini goster
input int     YPLookback         = 240;                     // YP: bolge olusurken geriye kac mum taransin (temas sayisi)
input int     SwingStrength      = 2;                       // V/UV: swing icin her iki yanda kac mum (fractal gucu)
input int     SwingLookback      = 100;                     // V/UV: swing aramak icin 1.mumdan geriye kac mum bakilsin
input string  CsvSeparator       = ";";                     // CSV ayiraci (Excel TR icin ; , diger icin ,)
input int     ORJLookback        = 60;                      // ORJ/NORJ: onceki ayni yonlu bolge icin geriye kac mum taransin
input int     MaxZoneAgeBars     = 60;                      // Bolgenin azami yasi (mum). Sonra saga uzamaz (0 = sinirsiz)
input int     FirstNCandles      = 3;                       // Ilk N Mum ATR filtresi: FVG mumu (3.mum) dahil kac mum (3 / 4 / 5 ...)
input int     CandleAtrMode      = 0;                       // Mum ATR filtreleri: 0 = mum boyu (high-low)/ATR, 1 = bolge kenarindan uzaklasma/ATR
input int     SeqCandles         = 3;                       // ARD: FVG mumundan sonra kac mum ust uste yukselen (arzda dusen) kapanis yapsin

#define NLEV 8          // TP/SL seviye sayisi (1 e N odul: TPn = n x bolge yuksekligi)
#define NLEV_MAIN 3     // ana yazida gosterilen seviye sayisi (kalanlar 2. yaziya)

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
   int      endIdx;       // kutunun sag ucunun bar index'i (ilk temas / yas siniri / son bar)
   datetime timeEnd;      // endIdx barinin zamani
   bool     hasObj;       // grafikte nesneleri var mi (gorunen pencere + filtre)
   bool     dirty;        // nesneleri yeniden cizilmeli mi
   double   atr;          // 3. mum barindaki ATR degeri
   double   ext;          // ilk temasa kadar ulasilan uc fiyat (talep: en yuksek high, arz: en dusuk low)
   double   extN;         // V1.22: ayni sey ama yalnizca FVG mumu dahil ilk N mum icinde
   int      touchIdx;     // ilk temas edilen bar (-1: henuz yok)
   int      outLast;      // sonuc takibinde en son islenen (kapanmis) bar
   bool     trackDone;    // takip bitti (3 seviye de sonuclandi ya da temas hic olmadi)
   int      out[NLEV];    // TP1..TP8 sonucu: 0 = bekliyor, 1 = TP, 2 = SL
   int      bo;           // bolgeyi olusturan (sola dogru ardisik kesisen) mum sayisi
   int      yp;           // olusumdan once YPLookback mum icinde bolgeye temas eden mum sayisi
   double   fvgFar;       // FVG'nin bolgeden uzak ucu (talep: 3.mum low, arz: 3.mum high)
   bool     orj;          // true: ORJ (onceki bolge alanina girmedi), false: NORJ
   bool     ffvgt;        // ilk temastan once FVG'ye girip disinda kapanis yapildi mi
   int      extIdx;       // ext (en uzak nokta) degerine ulasilan bar index'i
   double   swLevel;      // kirilmasi beklenen onceki swing seviyesi (0 = swing bulunamadi)
   bool     vbrk;         // swing seviyesi kapanisla kirildi mi (V / UV)
   datetime timeC1;       // 1.mum zamani (bolge baslangici)
   datetime timeForm;     // 3.mum zamani (bolge olusumu)
   datetime timeTouch;    // ilk temas zamani (0 = temas yok)
   double   cAtr[3];      // V1.25: FVG mumu, sonraki, onu izleyen mumun ATR degeri
   int      cCnt;         // V1.25: cAtr[] icinde hesaplanmis (kapanmis) mum sayisi (0..3)
   bool     seq;          // V1.25: ARD - ust uste yukselen (arzda dusen) kapanislar
   bool     seqChk;       // V1.25: ARD hesaplandi mi (gerekli mumlar kapandi mi)
  };

SDZoneInfo zones[];
int lastScanned = -1;   // yeni bolge taramasinda en son islenen bar (tekrar taramayi onler)

//--- V1.20 performans durum degiskenleri
int    atrBase     = 0;        // atrBuf[0] hangi bar index'ine ait
int    gWinN       = 3;        // V1.22: Ilk N Mum ATR filtresindeki N (OnInit'te FirstNCandles'tan)
int    activeZones[];          // hala islem gerektiren bolgelerin zones[] index'leri
int    gTotal      = 0;        // son OnCalculate'teki rates_total
bool   syncValid   = false;    // nesne senkron penceresi gecerli mi
int    syncL       = 0;        // nesne olusturulan pencere: sol bar index'i
int    syncR       = 0;        // nesne olusturulan pencere: sag bar index'i
bool   panelDirty  = true;     // filtre paneli (yeniden) cizilmeli mi
bool   fltActive   = false;    // herhangi bir filtre varsayilandan farkli mi

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
//| Bolge nesne adi. kind: "" = kutu, "eq" = denge, "bd" = kenar,     |
//| "lb" = yazi, "l2" = TP4-8 yazisi.  (Eski adlandirma ile birebir ayni: SDZ_D_123 ...)   |
//+------------------------------------------------------------------+
string ZObjName(const SDZoneInfo &z,const string kind)
  {
   return(prefix + (z.isDemand ? "D" : "S") + kind + "_" + IntegerToString(z.fvgIdx));
  }

//+------------------------------------------------------------------+
//| Zone kutusu olustur / guncelle                                   |
//| Sabit ozellikler yalnizca olusturmada set edilir.                 |
//+------------------------------------------------------------------+
void DrawZone(string name,datetime tStart,datetime tEnd,double top,double bottom,color clr)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_RECTANGLE,0,tStart,top,tEnd,bottom))
         return;
      ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,name,OBJPROP_FILL,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,ShowBorder?1:0);
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
     }
   else
     {
      ObjectMove(0,name,0,tStart,top);
      ObjectMove(0,name,1,tEnd,bottom);
     }
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
     {
      if(!ObjectCreate(0,name,OBJ_ARROW,0,tMid,pMid))
         return;
      ObjectSetInteger(0,name,OBJPROP_ARROWCODE,159); // dolu nokta
      ObjectSetInteger(0,name,OBJPROP_COLOR,EquilibriumColor);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
     }
   else
      ObjectMove(0,name,0,tMid,pMid);
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
   for(int q=0;q<NLEV;q++)
      z.out[q] = 0;
  }

//+------------------------------------------------------------------+
//| Ilk temastan sonra TP1-TP8 / SL1-SL8 sonuclarini guncelle.        |
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

      for(int n=1;n<=NLEV;n++)
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
      bool allDone = true;
      for(int q=0;q<NLEV;q++)
         if(z.out[q]==0)
           {
            allDone = false;
            break;
           }
      if(allDone)
        {
         z.trackDone = true;
         break;
        }
     }
   return(changed);
  }

//+------------------------------------------------------------------+
//| Kenar cizgisi (ayri, dolgusuz dikdortgen) + ATR yazisi            |
//| Sabit ozellikler yalnizca olusturmada set edilir; guncellemede     |
//| sadece konum ve yazi metni degisir.                               |
//+------------------------------------------------------------------+
void DrawExtras(const SDZoneInfo &z,datetime tStart,datetime tEnd)
  {
   color bc = z.isDemand ? DemandBorderColor : SupplyBorderColor;

   if(ShowBorder)
     {
      string n = ZObjName(z,"bd");
      if(ObjectFind(0,n)<0)
        {
         if(ObjectCreate(0,n,OBJ_RECTANGLE,0,tStart,z.top,tEnd,z.bottom))
           {
            ObjectSetInteger(0,n,OBJPROP_COLOR,bc);
            ObjectSetInteger(0,n,OBJPROP_FILL,false);
            ObjectSetInteger(0,n,OBJPROP_BACK,true);
            ObjectSetInteger(0,n,OBJPROP_WIDTH,BorderWidth);
            ObjectSetInteger(0,n,OBJPROP_STYLE,STYLE_SOLID);
            ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
            ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
           }
        }
      else
        {
         ObjectMove(0,n,0,tStart,z.top);
         ObjectMove(0,n,1,tEnd,z.bottom);
        }
     }

   if(ShowATRLabel && z.atr>0.0)
     {
      string l = ZObjName(z,"lb");
      // Talep: sag alt kose (kutunun altinda), Arz: sag ust kose (kutunun ustunde)
      double price = z.isDemand ? z.bottom : z.top;
      if(ObjectFind(0,l)<0)
        {
         if(ObjectCreate(0,l,OBJ_TEXT,0,tEnd,price))
           {
            ObjectSetString(0,l,OBJPROP_FONT,"Arial");
            ObjectSetInteger(0,l,OBJPROP_FONTSIZE,8);
            ObjectSetInteger(0,l,OBJPROP_COLOR,bc);
            ObjectSetInteger(0,l,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
            ObjectSetInteger(0,l,OBJPROP_SELECTABLE,false);
            ObjectSetInteger(0,l,OBJPROP_HIDDEN,true);
           }
        }
      else
         ObjectMove(0,l,0,tEnd,price);

      // Bolge genisligi | ilk temasa kadar bolgeden uzaklasma (talep: +yukselis, arz: -dusus)
      double move = z.isDemand ? MathMax(0.0,z.ext-z.top) : MathMax(0.0,z.bottom-z.ext);
      string mv   = (move>0.0 ? (z.isDemand ? "+" : "-") : "") + DoubleToString(move/z.atr,2);
      // Sonuclanmis seviyeler: seviye sirasiyla " | tp1 | tp2 | sl3" gibi
      string res = "";
      for(int q=0;q<NLEV_MAIN;q++)
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
     }

   // V1.21: TP4..TP8 / SL4..SL8 sonuclari ikinci yaziya (talep: kutu ustu, arz: kutu alti)
   if(ShowATRLabel && NLEV>NLEV_MAIN)
     {
      string res2 = "";
      // V1.25: FVG mumu ve sonraki 2 mumun ATR degerleri 'M a/b/c' + ARD
      if(z.cCnt>0)
        {
         res2 = "M ";
         for(int cq=0;cq<z.cCnt;cq++)
            res2 += (cq>0 ? "/" : "") + DoubleToString(z.cAtr[cq],2);
        }
      if(z.seq)
         res2 += (res2=="" ? "" : " | ") + "ARD";
      for(int q=NLEV_MAIN;q<NLEV;q++)
        {
         if(z.out[q]==1)
            res2 += (res2=="" ? "" : " | ") + "tp"+IntegerToString(q+1);
         else if(z.out[q]==2)
            res2 += (res2=="" ? "" : " | ") + "sl"+IntegerToString(q+1);
        }
      string l2 = ZObjName(z,"l2");
      if(res2=="")
        {
         if(ObjectFind(0,l2)>=0)
            ObjectDelete(0,l2);
        }
      else
        {
         double price2 = z.isDemand ? z.top : z.bottom;
         if(ObjectFind(0,l2)<0)
           {
            if(ObjectCreate(0,l2,OBJ_TEXT,0,tEnd,price2))
              {
               ObjectSetString(0,l2,OBJPROP_FONT,"Arial");
               ObjectSetInteger(0,l2,OBJPROP_FONTSIZE,8);
               ObjectSetInteger(0,l2,OBJPROP_COLOR,bc);
               ObjectSetInteger(0,l2,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_LOWER : ANCHOR_RIGHT_UPPER);
               ObjectSetInteger(0,l2,OBJPROP_SELECTABLE,false);
               ObjectSetInteger(0,l2,OBJPROP_HIDDEN,true);
              }
           }
         else
            ObjectMove(0,l2,0,tEnd,price2);
         if(StringLen(res2)>63)
            StringReplace(res2," | ","|");
         if(StringLen(res2)>63)
            res2 = StringSubstr(res2,0,63);
         ObjectSetString(0,l2,OBJPROP_TEXT,res2);
        }
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
//| V1.16 FILTRE: ortak sabitler ve durum degiskenleri                |
//+------------------------------------------------------------------+
#define TBL_W     275   // tablo / panel genisligi (piksel)
#define TBL_ROWH  18    // istatistik tablosu satir yuksekligi
#define TBL_H     (TBL_ROWH*(NLEV+2)+10)   // tablo yuksekligi: baslik + NLEV seviye + bilgi satiri
#define FLT_N     11    // aralik (min-max) filtresi sayisi

string fltName[FLT_N] = {"Genislik ATR","Uzaklasma ATR","BO","YP","BU","BD","BY","Ilk 3 Mum ATR","FVG Mum ATR","FVG+1 Mum ATR","FVG+2 Mum ATR"};   // son ad OnInit'te N'e gore guncellenir
bool   fltOn[FLT_N];       // filtre acik mi
bool   fltHasMin[FLT_N];   // alt sinir girildi mi (bos = sinirsiz)
bool   fltHasMax[FLT_N];   // ust sinir girildi mi
double fltMin[FLT_N];
double fltMax[FLT_N];
bool   fltDemand = true, fltSupply = true;     // Tip
bool   fltOrj    = true, fltNorj   = true;     // ORJ / NORJ
bool   fltFfvgtY = true, fltFfvgtN = true;     // FFVGT var / yok
bool   fltSeqY   = true, fltSeqN   = true;     // V1.25: ARD var / yok
bool   fltV      = true, fltUV     = true;     // V / UV
bool   fltTimeOn   = false;                    // saat filtresi acik mi
bool   fltTimeHasS = false, fltTimeHasE = false; // baslangic / bitis girildi mi (bos = 00:00 / 23:59)
int    fltTimeS    = 0, fltTimeE = 0;          // gun ici dakika (0..1439)
int    fltTimeRef  = 0;                        // 0: olusum (3.mum), 1: baslangic (1.mum), 2: ilk temas
bool   fltDateOn   = false;                    // tarih filtresi acik mi
bool   fltDateHasS = false, fltDateHasE = false; // baslangic / bitis tarihi girildi mi (bos = sinirsiz)
datetime fltDateS  = 0, fltDateE = 0;          // gun baslangici (00:00) olarak tarihler
bool   fltCollapsed = false;                   // panel kucultuldu mu
bool   fltForce     = false;                   // true: var olan nesneler de yeniden ayarlanir
bool   fltTP[NLEV];                            // V1.24: TPn sonuclu bolgeler (seviye n = 1..NLEV)
bool   fltSL[NLEV];                            // V1.24: SLn sonuclu bolgeler

//+------------------------------------------------------------------+
//| Tum filtreleri sifirla (hepsi kapali / hepsi secili)              |
//+------------------------------------------------------------------+
void ResetFilters()
  {
   for(int i=0;i<FLT_N;i++)
     {
      fltOn[i]     = false;
      fltHasMin[i] = false;
      fltHasMax[i] = false;
      fltMin[i]    = 0.0;
      fltMax[i]    = 0.0;
     }
   fltDemand = true;  fltSupply = true;
   fltOrj    = true;  fltNorj   = true;
   fltFfvgtY = true;  fltFfvgtN = true;
   fltSeqY   = true;  fltSeqN   = true;
   fltV      = true;  fltUV     = true;
   fltTimeOn = false; fltTimeHasS = false; fltTimeHasE = false;
   fltTimeS  = 0;     fltTimeE    = 0;     fltTimeRef  = 0;
   fltDateOn = false; fltDateHasS = false; fltDateHasE = false;
   fltDateS  = 0;     fltDateE    = 0;
   for(int n=0;n<NLEV;n++)
     { fltTP[n] = false; fltSL[n] = false; }
   fltActive = false;
  }

//+------------------------------------------------------------------+
//| Herhangi bir filtre varsayilandan farkli mi? (hicbiri aktif        |
//| degilse ZonePasses dogrudan true doner -> filtre maliyeti sifir)   |
//+------------------------------------------------------------------+
void UpdateFilterActive()
  {
   bool a = (!fltDemand || !fltSupply || !fltOrj || !fltNorj ||
             !fltFfvgtY || !fltFfvgtN || !fltSeqY || !fltSeqN || !fltV || !fltUV);
   for(int i=0;i<FLT_N && !a;i++)
      if(fltOn[i] && (fltHasMin[i] || fltHasMax[i]))
         a = true;
   if(fltTimeOn && (fltTimeHasS || fltTimeHasE))
      a = true;
   if(fltDateOn && (fltDateHasS || fltDateHasE))
      a = true;
   for(int n=0;n<NLEV && !a;n++)
      if(fltTP[n] || fltSL[n])
         a = true;
   fltActive = a;
  }

//+------------------------------------------------------------------+
//| Bolgenin i. aralik filtresindeki degeri (etikette gorunen gibi     |
//| 2 basamaga yuvarlanmis). Deger yoksa (temas olmadi: BD/BY) false.  |
//| Uzaklasma mutlak deger alinir (arzda da pozitif).                  |
//+------------------------------------------------------------------+
bool FltValue(const SDZoneInfo &z,int i,double &v)
  {
   switch(i)
     {
      case 0:
         v = (z.atr>0.0) ? (z.top-z.bottom)/z.atr : 0.0;
         break;
      case 1:
        {
         double move = z.isDemand ? MathMax(0.0,z.ext-z.top) : MathMax(0.0,z.bottom-z.ext);
         v = (z.atr>0.0) ? move/z.atr : 0.0;
         break;
        }
      case 2:
         v = (double)z.bo;
         break;
      case 3:
         v = (double)z.yp;
         break;
      case 4:
         v = (double)(z.extIdx-z.fvgIdx);
         break;
      case 5:
         if(z.touchIdx<0)
            return(false);
         v = (double)(z.touchIdx-z.extIdx);
         break;
      case 6:
         if(z.touchIdx<0)
            return(false);
         v = (double)(z.touchIdx-z.fvgIdx);
         break;
      case 7:
        {
         // V1.22: FVG mumu dahil ilk N mumda bolgeden uzaklasma (ATR cinsinden, mutlak)
         double moveN = z.isDemand ? MathMax(0.0,z.extN-z.top) : MathMax(0.0,z.bottom-z.extN);
         v = (z.atr>0.0) ? moveN/z.atr : 0.0;
         break;
        }
      case 8:
      case 9:
      case 10:
         // V1.25: FVG mumu / sonraki / onu izleyen mumun ATR degeri (mum henuz kapanmadiysa deger yok)
         if(z.cCnt <= i-8)
            return(false);
         v = z.cAtr[i-8];
         break;
      default:
         return(false);
     }
   v = NormalizeDouble(v,2);
   return(true);
  }

//+------------------------------------------------------------------+
//| Bolge tum aktif filtrelerden geciyor mu?                          |
//+------------------------------------------------------------------+
bool ZonePasses(const SDZoneInfo &z)
  {
   if(!fltActive)
      return(true);          // hicbir filtre aktif degil

   if(z.isDemand ? !fltDemand  : !fltSupply)  return(false);
   if(z.orj      ? !fltOrj     : !fltNorj)    return(false);
   if(z.ffvgt    ? !fltFfvgtY  : !fltFfvgtN)  return(false);
   if(z.seq      ? !fltSeqY    : !fltSeqN)    return(false);
   if(z.vbrk     ? !fltV       : !fltUV)      return(false);

   // V1.24: seviye bazli sonuc filtresi. Seviyede TPn/SLn butonlarindan biri aciksa
   // o seviyenin sonucu acik olanlardan biri olmali (VEYA); seviyeler arasi VE.
   for(int ln=0;ln<NLEV;ln++)
     {
      if(!fltTP[ln] && !fltSL[ln])
         continue;
      int oc = z.out[ln];                       // 0 bekliyor, 1 TP, 2 SL
      if(!((fltTP[ln] && oc==1) || (fltSL[ln] && oc==2)))
         return(false);
     }

   for(int i=0;i<FLT_N;i++)
     {
      if(!fltOn[i])
         continue;
      if(!fltHasMin[i] && !fltHasMax[i])
         continue;
      double v;
      if(!FltValue(z,i,v))
         return(false);               // deger yok (temassiz bolge) -> filtre aciksa elenir
      if(fltHasMin[i] && v < NormalizeDouble(fltMin[i],2))
         return(false);
      if(fltHasMax[i] && v > NormalizeDouble(fltMax[i],2))
         return(false);
     }

   // Gun ici saat filtresi (iki uc dahil; baslangic > bitis ise gece yarisini asar)
   if(fltTimeOn && (fltTimeHasS || fltTimeHasE))
     {
      datetime tt = (fltTimeRef==0) ? z.timeForm : (fltTimeRef==1 ? z.timeC1 : z.timeTouch);
      if(tt==0)
         return(false);               // referans zaman yok (temassiz bolge) -> elenir
      MqlDateTime dt;
      TimeToStruct(tt,dt);
      int m  = dt.hour*60 + dt.min;
      int ts = fltTimeHasS ? fltTimeS : 0;
      int te = fltTimeHasE ? fltTimeE : 1439;
      bool inside = (ts<=te) ? (m>=ts && m<=te) : (m>=ts || m<=te);
      if(!inside)
         return(false);
     }

   // Tarih filtresi (iki uc dahil, gun bazinda)
   if(fltDateOn && (fltDateHasS || fltDateHasE))
     {
      datetime td = (fltTimeRef==0) ? z.timeForm : (fltTimeRef==1 ? z.timeC1 : z.timeTouch);
      if(td==0)
         return(false);
      datetime day = td - (td % 86400);   // o gunun 00:00'i (sunucu saati)
      if(fltDateHasS && day < fltDateS)
         return(false);
      if(fltDateHasE && day > fltDateE)
         return(false);
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Sayi metni -> double ('.' veya ',' kabul edilir). Gecersizse false |
//+------------------------------------------------------------------+
bool ParseNum(string s,double &v)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   StringReplace(s,",",".");
   int len = StringLen(s);
   if(len==0)
      return(false);
   int dots = 0, digits = 0;
   for(int i=0;i<len;i++)
     {
      ushort c = StringGetCharacter(s,i);
      if(c=='-' && i==0)
         continue;
      if(c=='.')
        { dots++; continue; }
      if(c<'0' || c>'9')
         return(false);
      digits++;
     }
   if(dots>1 || digits==0)
      return(false);
   v = StringToDouble(s);
   return(true);
  }

//+------------------------------------------------------------------+
//| Sayiyi kisa yaz: 25 -> "25", 0.5 -> "0.5", 1.25 -> "1.25"          |
//+------------------------------------------------------------------+
string FmtNum(double v)
  {
   string s = DoubleToString(v,2);
   if(StringFind(s,".")>=0)
     {
      while(StringLen(s)>0 && StringGetCharacter(s,StringLen(s)-1)=='0')
         s = StringSubstr(s,0,StringLen(s)-1);
      if(StringLen(s)>0 && StringGetCharacter(s,StringLen(s)-1)=='.')
         s = StringSubstr(s,0,StringLen(s)-1);
     }
   return(s);
  }

//+------------------------------------------------------------------+
//| Saat metni -> gun ici dakika. Kabul: "3", "03", "3:00", "03:30",   |
//| "03.30", "0300". Gecersizse false                                  |
//+------------------------------------------------------------------+
bool ParseTime(string s,int &minutes)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   StringReplace(s,".",":");
   int len = StringLen(s);
   if(len==0)
      return(false);
   for(int i=0;i<len;i++)
     {
      ushort c = StringGetCharacter(s,i);
      if(c!=':' && (c<'0' || c>'9'))
         return(false);
     }
   int hh = 0, mm = 0;
   int pos = StringFind(s,":");
   if(pos>=0)
     {
      string a = StringSubstr(s,0,pos);
      string b = StringSubstr(s,pos+1);
      if(StringLen(a)==0 || StringLen(a)>2 || StringLen(b)>2 || StringFind(b,":")>=0)
         return(false);
      hh = (int)StringToInteger(a);
      mm = (StringLen(b)>0) ? (int)StringToInteger(b) : 0;
     }
   else if(len<=2)
      hh = (int)StringToInteger(s);
   else if(len==3 || len==4)
     {
      hh = (int)StringToInteger(StringSubstr(s,0,len-2));
      mm = (int)StringToInteger(StringSubstr(s,len-2));
     }
   else
      return(false);
   if(hh<0 || hh>23 || mm<0 || mm>59)
      return(false);
   minutes = hh*60+mm;
   return(true);
  }

//+------------------------------------------------------------------+
//| Tarih metni -> o gunun 00:00 zamani. Kabul: GG.AA.YYYY, GG/AA/YYYY, |
//| GG-AA-YYYY, GG.AA.YY. Gecersiz tarihte (orn. 31.02) false         |
//+------------------------------------------------------------------+
bool ParseDate(string s,datetime &d)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   StringReplace(s,"/",".");
   StringReplace(s,"-",".");
   StringReplace(s," ","");
   string p[];
   if(StringSplit(s,'.',p)!=3)
      return(false);
   for(int k=0;k<3;k++)
     {
      int pl = StringLen(p[k]);
      if(pl==0 || pl>4)
         return(false);
      for(int c=0;c<pl;c++)
        {
         ushort ch = StringGetCharacter(p[k],c);
         if(ch<'0' || ch>'9')
            return(false);
        }
     }
   int dd = (int)StringToInteger(p[0]);
   int mo = (int)StringToInteger(p[1]);
   int yy = (int)StringToInteger(p[2]);
   if(StringLen(p[2])<=2)
      yy += 2000;
   else if(StringLen(p[2])!=4)
      return(false);
   if(yy<1971 || yy>2100 || mo<1 || mo>12 || dd<1 || dd>31)
      return(false);
   MqlDateTime dt;
   dt.year=yy; dt.mon=mo; dt.day=dd; dt.hour=0; dt.min=0; dt.sec=0; dt.day_of_week=0; dt.day_of_year=0;
   datetime t = StructToTime(dt);
   MqlDateTime chk;
   TimeToStruct(t,chk);
   if(chk.day!=dd || chk.mon!=mo || chk.year!=yy)
      return(false);               // 31.02 gibi tarihler
   d = t;
   return(true);
  }

string FmtDate(datetime d)
  {
   MqlDateTime dt;
   TimeToStruct(d,dt);
   return(StringFormat("%02d.%02d.%04d",dt.day,dt.mon,dt.year));
  }

string FmtTime(int minutes)
  {
   return(StringFormat("%02d:%02d",minutes/60,minutes%60));
  }

//+------------------------------------------------------------------+
//| Panel nesneleri: etiket / dugme / giris kutusu                    |
//| (fltForce=false iken var olan nesneye dokunulmaz; boylece kullanici |
//|  kutuya yazarken tick geldiginde metin ezilmez.)                  |
//+------------------------------------------------------------------+
void FltLabel(string name,int x,int y,string text,color clr)
  {
   bool exists = (ObjectFind(0,name)>=0);
   if(exists && !fltForce)
      return;
   if(!exists)
     {
      ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_COLOR,clr);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
  }

void FltButton(string name,int x,int y,int w,string text,bool on)
  {
   bool exists = (ObjectFind(0,name)>=0);
   if(exists && !fltForce)
      return;
   if(!exists)
     {
      ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrDimGray);
     }
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_STATE,on);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,on ? clrLightGreen : clrGainsboro);
   ObjectSetInteger(0,name,OBJPROP_COLOR,on ? clrBlack : clrDimGray);
  }

void FltEdit(string name,int x,int y,int w,string text,bool active)
  {
   bool exists = (ObjectFind(0,name)>=0);
   if(exists && !fltForce)
      return;
   if(!exists)
     {
      ObjectCreate(0,name,OBJ_EDIT,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetString(0,name,OBJPROP_FONT,"Consolas");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_ALIGN,ALIGN_CENTER);
      ObjectSetInteger(0,name,OBJPROP_READONLY,false);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrWhite);
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrDimGray);
     }
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_COLOR,active ? clrBlack : clrGray);
  }

//+------------------------------------------------------------------+
//| Sol ust kose TP/SL/Net R tablosu (YALNIZCA filtreden gecen        |
//| bolgeler, talep + arz toplami)                                    |
//|   Seviye   TP   SL   Net R   Ort R   Win%                         |
//|     1      a    b    a*1 - b   NetR/(a+b)   a/(a+b)               |
//|    ...                                                            |
//|     8      o    p    o*8 - p   NetR/(o+p)                         |
//| Seviye n: risk = 1R (SL), odul = nR (TP)                          |
//+------------------------------------------------------------------+
void DrawStatsTable()
  {
   if(!ShowStatsTable)
      return;

   int tp[NLEV], sl[NLEV];
   ArrayInitialize(tp,0);
   ArrayInitialize(sl,0);
   int total = ArraySize(zones);
   int pass = 0, passTouched = 0;
   for(int k=0;k<total;k++)
     {
      if(!ZonePasses(zones[k]))
         continue;
      pass++;
      if(zones[k].touchIdx>=0)
         passTouched++;
      for(int q=0;q<NLEV;q++)
        {
         if(zones[k].out[q]==1)
            tp[q]++;
         else if(zones[k].out[q]==2)
            sl[q]++;
        }
     }

   int rowH = TBL_ROWH, w = TBL_W, h = TBL_H;
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

   int x0 = TableX+10, x1 = TableX+55, x2 = TableX+95, x3 = TableX+135, x4 = TableX+185, x5 = TableX+228;
   int y0 = TableY+5;

   SetCell(prefix+"STAT_H0",x0,y0,"Seviye",clrBlack);
   SetCell(prefix+"STAT_H1",x1,y0,"TP",clrGreen);
   SetCell(prefix+"STAT_H2",x2,y0,"SL",clrRed);
   SetCell(prefix+"STAT_H3",x3,y0,"Net R",clrBlack);
   SetCell(prefix+"STAT_H4",x4,y0,"Ort R",clrBlack);
   SetCell(prefix+"STAT_H5",x5,y0,"Win%",clrBlack);

   for(int q=0;q<NLEV;q++)
     {
      int y = y0 + rowH*(q+1);
      string id = IntegerToString(q+1);
      int netR = tp[q]*(q+1) - sl[q];     // seviye n: TP = +nR, SL = -1R
      color nc = (netR>0) ? clrGreen : (netR<0 ? clrRed : clrBlack);
      SetCell(prefix+"STAT_R"+id+"0",x0,y,id,clrBlack);
      SetCell(prefix+"STAT_R"+id+"1",x1,y,IntegerToString(tp[q]),clrGreen);
      SetCell(prefix+"STAT_R"+id+"2",x2,y,IntegerToString(sl[q]),clrRed);
      SetCell(prefix+"STAT_R"+id+"3",x3,y,(netR>0 ? "+" : "")+IntegerToString(netR),nc);
      // Ortalama R = Net R / sonuclanan islem sayisi (TP+SL); islem yoksa "-"
      int    nTr  = tp[q] + sl[q];
      double avgR = (nTr>0) ? (double)netR/nTr : 0.0;
      color  ac   = (avgR>0.0) ? clrGreen : (avgR<0.0 ? clrRed : clrBlack);
      string avTx = (nTr>0) ? ((avgR>0.0 ? "+" : "")+DoubleToString(avgR,2)) : "-";
      SetCell(prefix+"STAT_R"+id+"4",x4,y,avTx,ac);
      // Winrate = TP / (TP+SL); islem yoksa "-"
      string wrTx = (nTr>0) ? DoubleToString(100.0*tp[q]/nTr,1)+"%" : "-";
      SetCell(prefix+"STAT_R"+id+"5",x5,y,wrTx,ac);
     }

   SetCell(prefix+"STAT_INFO",x0,y0+rowH*(NLEV+1),
           "Bolge: "+IntegerToString(pass)+"/"+IntegerToString(total)+"  Temasli: "+IntegerToString(passTouched),
           clrDimGray);
  }

//+------------------------------------------------------------------+
//| Tablonun altindaki FILTRE paneli                                  |
//|  [FILTRE -] [Sifirla]                                             |
//|  [TALEP] [ARZ]                                                    |
//|  [Genislik ATR] [min] [max]   (dugme = filtreyi ac/kapa)          |
//|  ... Uzaklasma ATR, BO, YP, BU, BD, BY, Ilk N Mum ATR,            |
//|      FVG Mum ATR, FVG+1 Mum ATR, FVG+2 Mum ATR                   |
//|  [ORJ] [NORJ]   [FFVGT var] [FFVGT yok]   [ARD var] [ARD yok]     |
//|  [V] [UV]                                                         |
//+------------------------------------------------------------------+
void DrawFilterPanel()
  {
   if(!ShowFilterPanel)
      return;

   string fp   = prefix + "FLT_";
   int    px   = TableX;
   int    py   = TableY + (ShowStatsTable ? TBL_H+6 : 0);
   int    step = 22;
   int    fullH = 30 + 16 + step*21 + 6;
   int    H     = fltCollapsed ? 30 : fullH;

   string bg = fp + "BG";
   if(ObjectFind(0,bg)<0)
     {
      ObjectCreate(0,bg,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,bg,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,bg,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,bg,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,bg,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,bg,OBJPROP_BACK,false);
     }
   ObjectSetInteger(0,bg,OBJPROP_XDISTANCE,px);
   ObjectSetInteger(0,bg,OBJPROP_YDISTANCE,py);
   ObjectSetInteger(0,bg,OBJPROP_XSIZE,TBL_W);
   ObjectSetInteger(0,bg,OBJPROP_YSIZE,H);
   ObjectSetInteger(0,bg,OBJPROP_BGCOLOR,TableBgColor);
   ObjectSetInteger(0,bg,OBJPROP_COLOR,clrDimGray);

   FltButton(fp+"H_COL",px+8,py+5,100,fltCollapsed ? "FILTRE  [+]" : "FILTRE  [-]",!fltCollapsed);
   FltButton(fp+"H_RST",px+112,py+5,100,"Sifirla",false);

   if(fltCollapsed)
     {
      ObjectsDeleteAll(0,fp+"R_");
      return;
     }

   int y = py + 30;
   FltLabel(fp+"R_HINT",px+8,y,"Aralik (bos = sinirsiz)  Tarih: GG.AA.YYYY",clrDimGray);
   y += 16;

   FltButton(fp+"R_T_D",px+8,  y,100,"TALEP",fltDemand);
   FltButton(fp+"R_T_S",px+112,y,100,"ARZ",  fltSupply);
   y += step;

   for(int i=0;i<FLT_N;i++)
     {
      string id = IntegerToString(i);
      FltButton(fp+"R_L_"+id,  px+8,  y,100,fltName[i],fltOn[i]);
      FltEdit  (fp+"R_MIN_"+id,px+112,y, 48,fltHasMin[i] ? FmtNum(fltMin[i]) : "",fltOn[i]);
      FltEdit  (fp+"R_MAX_"+id,px+164,y, 48,fltHasMax[i] ? FmtNum(fltMax[i]) : "",fltOn[i]);
      y += step;
     }

   // Gun ici saat filtresi
   FltButton(fp+"R_TL",px+8,  y,100,"Saat (HH:MM)",fltTimeOn);
   FltEdit  (fp+"R_TS",px+112,y, 48,fltTimeHasS ? FmtTime(fltTimeS) : "",fltTimeOn);
   FltEdit  (fp+"R_TE",px+164,y, 48,fltTimeHasE ? FmtTime(fltTimeE) : "",fltTimeOn);
   y += step;
   // Tarih filtresi (GG.AA.YYYY, daha genis kutular)
   FltButton(fp+"R_DL",px+8,  y, 60,"Tarih",fltDateOn);
   FltEdit  (fp+"R_DS",px+72, y, 70,fltDateHasS ? FmtDate(fltDateS) : "",fltDateOn);
   FltEdit  (fp+"R_DE",px+146,y, 70,fltDateHasE ? FmtDate(fltDateE) : "",fltDateOn);
   y += step;
   string refTxt = (fltTimeRef==0) ? "Zaman ref: Olusum (3.mum)" :
                   (fltTimeRef==1) ? "Zaman ref: Baslangic (1.mum)" : "Zaman ref: Ilk temas";
   FltButton(fp+"R_TR",px+8,  y,208,refTxt,(fltTimeOn || fltDateOn));
   y += step;

   // V1.24: seviye bazli sonuc butonlari (TP1..TP8, SL1..SL8)
   for(int n=0;n<NLEV;n++)
      FltButton(fp+"R_TP_"+IntegerToString(n),px+8+n*32,y,30,"TP"+IntegerToString(n+1),fltTP[n]);
   y += step;
   for(int n2=0;n2<NLEV;n2++)
      FltButton(fp+"R_SL_"+IntegerToString(n2),px+8+n2*32,y,30,"SL"+IntegerToString(n2+1),fltSL[n2]);
   y += step;

   FltButton(fp+"R_O_Y",px+8,  y,100,"ORJ", fltOrj);
   FltButton(fp+"R_O_N",px+112,y,100,"NORJ",fltNorj);
   y += step;
   FltButton(fp+"R_F_Y",px+8,  y,100,"FFVGT var",fltFfvgtY);
   FltButton(fp+"R_F_N",px+112,y,100,"FFVGT yok",fltFfvgtN);
   y += step;
   FltButton(fp+"R_A_Y",px+8,  y,100,"ARD var",fltSeqY);
   FltButton(fp+"R_A_N",px+112,y,100,"ARD yok",fltSeqN);
   y += step;
   FltButton(fp+"R_V_Y",px+8,  y,100,"V", fltV);
   FltButton(fp+"R_V_N",px+112,y,100,"UV",fltUV);
  }

//+------------------------------------------------------------------+
//| V1.20: Bolgenin tum nesnelerini (kutu, denge, kenar, yazi) ciz     |
//+------------------------------------------------------------------+
void RenderZone(const SDZoneInfo &z)
  {
   color clr = z.isDemand ? DemandColor : SupplyColor;
   DrawZone(ZObjName(z,""),z.timeC1,z.timeEnd,z.top,z.bottom,clr);
   DrawEquilibrium(ZObjName(z,"eq"),z.timeC1,z.timeEnd,z.top,z.bottom);
   DrawExtras(z,z.timeC1,z.timeEnd);
  }

//+------------------------------------------------------------------+
//| Bolgenin grafikteki nesnelerini sil (veri zones[]'ta kalir)        |
//+------------------------------------------------------------------+
void DeleteZoneObjects(const SDZoneInfo &z)
  {
   ObjectDelete(0,ZObjName(z,""));
   if(ShowEquilibrium)
      ObjectDelete(0,ZObjName(z,"eq"));
   if(ShowBorder)
      ObjectDelete(0,ZObjName(z,"bd"));
   if(ShowATRLabel)
     {
      ObjectDelete(0,ZObjName(z,"lb"));
      ObjectDelete(0,ZObjName(z,"l2"));
     }
  }

//+------------------------------------------------------------------+
//| Gorunen pencerenin bar index araligi (zones[] ile ayni index)      |
//+------------------------------------------------------------------+
void GetVisibleRange(int &visL,int &visR)
  {
   int vis   = (int)ChartGetInteger(0,CHART_VISIBLE_BARS);
   int first = (int)ChartGetInteger(0,CHART_FIRST_VISIBLE_BAR); // en soldaki gorunen bar (seri index)
   if(vis<=0)
      vis = 500;
   visL = gTotal-1-first;
   visR = visL+vis-1;
  }

//+------------------------------------------------------------------+
//| V1.20: Nesneleri gorunen pencereye (+kenar payi) ve filtreye gore  |
//| senkronla: olmasi gerekenleri olustur / guncelle, gerekmeyeni sil. |
//| force=false iken pencere guvenli bolgenin icindeyse hicbir sey     |
//| yapmaz. Donus: bir sey yapildiysa true.                           |
//+------------------------------------------------------------------+
bool SyncObjects(const bool force)
  {
   int total = ArraySize(zones);
   if(total==0 || gTotal<=0)
      return(false);

   int visL,visR;
   GetVisibleRange(visL,visR);
   int margin = MathMax(visR-visL+1,200);

   if(!force && syncValid && visL>=syncL+margin/2 && visR<=syncR-margin/2)
      return(false);

   syncValid = true;
   syncL     = visL-margin;
   syncR     = visR+margin;

   for(int k=0;k<total;k++)
     {
      bool want = (zones[k].baseIdx<=syncR && zones[k].endIdx>=syncL) && ZonePasses(zones[k]);
      if(want)
        {
         if(!zones[k].hasObj || zones[k].dirty)
           {
            RenderZone(zones[k]);
            zones[k].hasObj = true;
            zones[k].dirty  = false;
           }
        }
      else if(zones[k].hasObj)
        {
         DeleteZoneObjects(zones[k]);
         zones[k].hasObj = false;
        }
     }
   return(true);
  }

//+------------------------------------------------------------------+
//| Tablo + panel. zonesChanged: bolge verisi / filtre degistiyse true |
//+------------------------------------------------------------------+
void RefreshTables(const bool zonesChanged)
  {
   UpdateFilterActive();
   if(zonesChanged || fltForce)
     {
      SyncObjects(true);
      DrawStatsTable();
     }
   if(panelDirty || fltForce)
     {
      DrawFilterPanel();
      panelDirty = false;
     }
  }

//+------------------------------------------------------------------+
//| Panel olaylari: dugme tiklamasi ve kutuya deger girisi             |
//+------------------------------------------------------------------+
void HandleFilterEvent(const int id,const string &sparam)
  {
   string fp = prefix + "FLT_";
   if(StringFind(sparam,fp)!=0)
      return;
   string key = StringSubstr(sparam,StringLen(fp));
   bool changed = false;

   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(key=="H_COL")        fltCollapsed = !fltCollapsed;
      else if(key=="H_RST")   ResetFilters();
      else if(key=="R_TL")    fltTimeOn = !fltTimeOn;
      else if(key=="R_DL")    fltDateOn = !fltDateOn;
      else if(key=="R_TR")    fltTimeRef = (fltTimeRef+1)%3;
      else if(key=="R_T_D")   fltDemand = !fltDemand;
      else if(key=="R_T_S")   fltSupply = !fltSupply;
      else if(key=="R_O_Y")   fltOrj    = !fltOrj;
      else if(key=="R_O_N")   fltNorj   = !fltNorj;
      else if(key=="R_F_Y")   fltFfvgtY = !fltFfvgtY;
      else if(key=="R_F_N")   fltFfvgtN = !fltFfvgtN;
      else if(key=="R_A_Y")   fltSeqY   = !fltSeqY;
      else if(key=="R_A_N")   fltSeqN   = !fltSeqN;
      else if(key=="R_V_Y")   fltV      = !fltV;
      else if(key=="R_V_N")   fltUV     = !fltUV;
      else if(StringFind(key,"R_TP_")==0)
        {
         int ti = (int)StringToInteger(StringSubstr(key,5));
         if(ti<0 || ti>=NLEV)
            return;
         fltTP[ti] = !fltTP[ti];
        }
      else if(StringFind(key,"R_SL_")==0)
        {
         int si = (int)StringToInteger(StringSubstr(key,5));
         if(si<0 || si>=NLEV)
            return;
         fltSL[si] = !fltSL[si];
        }
      else if(StringFind(key,"R_L_")==0)
        {
         int i = (int)StringToInteger(StringSubstr(key,4));
         if(i<0 || i>=FLT_N)
            return;
         fltOn[i] = !fltOn[i];
        }
      else
         return;
      changed = true;
     }
   else if(id==CHARTEVENT_OBJECT_ENDEDIT)
     {
      // Saat kutulari
      if(key=="R_TS" || key=="R_TE")
        {
         bool isS = (key=="R_TS");
         string tx = ObjectGetString(0,sparam,OBJPROP_TEXT);
         StringTrimLeft(tx);
         StringTrimRight(tx);
         if(StringLen(tx)==0)
           {
            if(isS) fltTimeHasS = false;
            else    fltTimeHasE = false;
           }
         else
           {
            int mn;
            if(ParseTime(tx,mn))
              {
               if(isS) { fltTimeHasS = true; fltTimeS = mn; }
               else    { fltTimeHasE = true; fltTimeE = mn; }
               fltTimeOn = true;     // deger girilince filtre otomatik acilir
              }
            // gecersiz metin: eski deger korunur, yeniden cizimde kutu eski haline doner
           }
         fltForce = true;
         RefreshTables(true);
         fltForce = false;
         ChartRedraw();
         return;
        }

      // Tarih kutulari
      if(key=="R_DS" || key=="R_DE")
        {
         bool isS = (key=="R_DS");
         string tx = ObjectGetString(0,sparam,OBJPROP_TEXT);
         StringTrimLeft(tx);
         StringTrimRight(tx);
         if(StringLen(tx)==0)
           {
            if(isS) fltDateHasS = false;
            else    fltDateHasE = false;
           }
         else
           {
            datetime dd;
            if(ParseDate(tx,dd))
              {
               if(isS) { fltDateHasS = true; fltDateS = dd; }
               else    { fltDateHasE = true; fltDateE = dd; }
               fltDateOn = true;     // deger girilince filtre otomatik acilir
              }
            // gecersiz metin: eski deger korunur, yeniden cizimde kutu eski haline doner
           }
         fltForce = true;
         RefreshTables(true);
         fltForce = false;
         ChartRedraw();
         return;
        }

      bool isMin = (StringFind(key,"R_MIN_")==0);
      bool isMax = (StringFind(key,"R_MAX_")==0);
      if(!isMin && !isMax)
         return;
      int i = (int)StringToInteger(StringSubstr(key,6));
      if(i<0 || i>=FLT_N)
         return;

      string txt = ObjectGetString(0,sparam,OBJPROP_TEXT);
      StringTrimLeft(txt);
      StringTrimRight(txt);
      if(StringLen(txt)==0)
        {
         if(isMin) fltHasMin[i] = false;
         else      fltHasMax[i] = false;
        }
      else
        {
         double v;
         if(ParseNum(txt,v))
           {
            if(isMin) { fltHasMin[i] = true; fltMin[i] = v; }
            else      { fltHasMax[i] = true; fltMax[i] = v; }
            fltOn[i] = true;      // deger girilince filtre otomatik acilir
           }
         // gecersiz metin: eski deger korunur, yeniden cizimde kutu eski haline doner
        }
      changed = true;
     }

   if(changed)
     {
      fltForce = true;
      RefreshTables(true);
      fltForce = false;
      ChartRedraw();
     }
  }

//+------------------------------------------------------------------+
//| Zaman metni (dakika dahil); 0 ise bos                             |
//+------------------------------------------------------------------+
string CsvTime(datetime t)
  {
   if(t==0)
      return("");
   return(TimeToString(t,TIME_DATE|TIME_MINUTES));
  }

//+------------------------------------------------------------------+
//| Tum bolgeleri ve etiketlerini CSV'ye yaz ('S' tusu)               |
//+------------------------------------------------------------------+
void ExportZonesCSV()
  {
   string sep = (StringLen(CsvSeparator)>0) ? CsvSeparator : ";";
   string tf  = EnumToString(_Period);
   StringReplace(tf,"PERIOD_","");
   string stamp = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
   StringReplace(stamp,".","");
   StringReplace(stamp,":","");
   StringReplace(stamp," ","_");
   string fname = "SDZ_"+_Symbol+"_"+tf+"_"+stamp+".csv";

   int h = FileOpen(fname,FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h==INVALID_HANDLE)
     {
      Alert("CSV acilamadi: ",fname," (hata ",GetLastError(),")");
      return;
     }

   FileWriteString(h,"Tip"+sep+"Bolge_Baslangic(1.mum)"+sep+"Bolge_Olusum(3.mum)"+sep+"Ilk_Temas"+sep+
                     "Ust"+sep+"Alt"+sep+"Genislik_ATR"+sep+"Uzaklasma_ATR"+sep+
                     "TP1"+sep+"TP2"+sep+"TP3"+sep+"TP4"+sep+"TP5"+sep+"TP6"+sep+"TP7"+sep+"TP8"+sep+"BO"+sep+"YP"+sep+"ORJ"+sep+"FFVGT"+sep+
                     "BU"+sep+"BD"+sep+"BY"+sep+"V"+sep+"Ilk"+IntegerToString(gWinN)+"Mum_ATR"+sep+"FVG_Mum_ATR"+sep+"FVG1_Mum_ATR"+sep+"FVG2_Mum_ATR"+sep+"ARD"+"\r\n");

   int total = ArraySize(zones);
   for(int k=0;k<total;k++)
     {
      SDZoneInfo z;
      z = zones[k];

      double width = (z.atr>0.0) ? (z.top-z.bottom)/z.atr : 0.0;
      double move  = z.isDemand ? MathMax(0.0,z.ext-z.top) : MathMax(0.0,z.bottom-z.ext);
      double mvAtr = (z.atr>0.0) ? move/z.atr : 0.0;
      if(!z.isDemand)
         mvAtr = -mvAtr;   // arzda dusus eksi isaretli (grafik yazisiyla ayni)

      string line = (z.isDemand ? "TALEP" : "ARZ")+sep+
                    CsvTime(z.timeC1)+sep+CsvTime(z.timeForm)+sep+CsvTime(z.timeTouch)+sep+
                    DoubleToString(z.top,_Digits)+sep+DoubleToString(z.bottom,_Digits)+sep+
                    DoubleToString(width,2)+sep+DoubleToString(mvAtr,2);

      for(int q=0;q<NLEV;q++)
         line += sep + (z.out[q]==1 ? "TP" : (z.out[q]==2 ? "SL" : ""));

      line += sep + IntegerToString(z.bo);
      line += sep + IntegerToString(z.yp);
      line += sep + (z.orj ? "ORJ" : "NORJ");
      line += sep + (z.ffvgt ? "FFVGT" : "");
      line += sep + IntegerToString(z.extIdx-z.fvgIdx);
      line += sep + (z.touchIdx>=0 ? IntegerToString(z.touchIdx-z.extIdx) : "");
      line += sep + (z.touchIdx>=0 ? IntegerToString(z.touchIdx-z.fvgIdx) : "");
      line += sep + (z.vbrk ? "V" : "UV");

      double moveN = z.isDemand ? MathMax(0.0,z.extN-z.top) : MathMax(0.0,z.bottom-z.extN);
      double mvN   = (z.atr>0.0) ? moveN/z.atr : 0.0;
      if(!z.isDemand)
         mvN = -mvN;
      line += sep + DoubleToString(mvN,2);
      for(int cc=0;cc<3;cc++)
         line += sep + (z.cCnt>cc ? DoubleToString(z.cAtr[cc],2) : "");
      line += sep + (z.seq ? "ARD" : "");

      FileWriteString(h,line+"\r\n");
     }

   FileClose(h);
   string path = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"+fname;
   Print("SupplyDemand CSV yazildi (",total," bolge): ",path);
   Alert("CSV kaydedildi (",total," bolge): ",path);
  }

//+------------------------------------------------------------------+
int OnInit()
  {
   ArrayResize(zones,0);
   ArrayResize(activeZones,0);
   lastScanned = -1;
   gTotal      = 0;
   syncValid   = false;
   panelDirty  = true;
   gWinN = MathMax(1,FirstNCandles);
   fltName[7] = "Ilk "+IntegerToString(gWinN)+" Mum ATR";
   ResetFilters();
   fltCollapsed = false;
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
//| 'S' tusuna basilinca bolgeleri CSV'ye aktar                       |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   if(id==CHARTEVENT_KEYDOWN && lparam=='S')
      ExportZonesCSV();

   // V1.20: kaydirma / zoom / boyut degisince nesne penceresini senkronla
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      if(SyncObjects(false))
         ChartRedraw();
     }

   // V1.16: filtre paneli (dugme tiklama / kutuya deger girme)
   if(id==CHARTEVENT_OBJECT_CLICK || id==CHARTEVENT_OBJECT_ENDEDIT)
      HandleFilterEvent(id,sparam);
  }

//+------------------------------------------------------------------+
//| V1.25: mum ATR degerleri ve ARD durumu icin baslangic degerleri    |
//+------------------------------------------------------------------+
void InitCandleInfo(SDZoneInfo &z)
  {
   z.cAtr[0] = 0.0;
   z.cAtr[1] = 0.0;
   z.cAtr[2] = 0.0;
   z.cCnt    = 0;
   z.seq     = false;
   z.seqChk  = false;
  }

//+------------------------------------------------------------------+
//| V1.25: kapanmis mumlara gore (lastClosed'a kadar) mum ATR           |
//| degerlerini ve ARD'yi hesapla. Donus: bir sey degistiyse true.     |
//|  mum 0 = FVG mumu (fvgIdx), 1 = sonraki, 2 = onu izleyen.          |
//|  Mod 0: (high-low)/ATR | Mod 1: bolge kenarindan uzaklasma/ATR.     |
//|  ARD: fvgIdx'ten sonraki SeqCandles mum ust uste, talepte bir       |
//|  oncekinin kapanisinin USTUNDE, arzda ALTINDA kapanir.             |
//+------------------------------------------------------------------+
bool UpdateCandleInfo(SDZoneInfo &z,const double &high[],const double &low[],
                      const double &close[],const int lastClosed)
  {
   bool ch = false;

   for(int n=z.cCnt; n<3; n++)
     {
      int idx = z.fvgIdx + n;
      if(idx > lastClosed)
         break;
      double v;
      if(CandleAtrMode==1)
         v = z.isDemand ? MathMax(0.0,high[idx]-z.top) : MathMax(0.0,z.bottom-low[idx]);
      else
         v = high[idx]-low[idx];
      z.cAtr[n] = (z.atr>0.0) ? v/z.atr : 0.0;
      z.cCnt    = n+1;
      ch = true;
     }

   if(!z.seqChk)
     {
      int sn = MathMax(1,SeqCandles);
      if(z.fvgIdx + sn <= lastClosed)
        {
         bool ok = true;
         for(int q=1;q<=sn && ok;q++)
           {
            double cur  = close[z.fvgIdx+q];
            double prev = close[z.fvgIdx+q-1];
            if(z.isDemand ? !(cur > prev) : !(cur < prev))
               ok = false;
           }
         z.seq    = ok;
         z.seqChk = true;
         ch = true;
        }
     }
   return(ch);
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

   if(BarsCalculated(atrHandle)<rates_total)
      return(0);

   int firstBar = 4; // en az c1-2 index'ine erisim gerekli (i-4)
   if(MaxHistoryBars>0 && rates_total-MaxHistoryBars>firstBar)
      firstBar = rates_total-MaxHistoryBars;

   //--- Tam yeniden hesaplama: eski bolgeleri ve nesneleri temizle
   bool fullCalc = (prev_calculated==0);
   if(fullCalc)
     {
      ObjectsDeleteAll(0,prefix);
      ArrayResize(zones,0);
      ArrayResize(activeZones,0);
      lastScanned = firstBar-1;
      syncValid   = false;
      panelDirty  = true;
     }

   //--- Son islenecek bar: mum kapanisi bekleniyorsa olusmakta olan mumu (rates_total-1) atla
   int lastBar = WaitForCandleClose ? rates_total-2 : rates_total-1;
   if(lastBar<firstBar)
      return(rates_total);

   gTotal = rates_total;
   bool changed = fullCalc;   // bolge verisi / nesne gerektiren bir degisiklik oldu mu

   //--- ATR: tum seri yerine yalnizca yeni taranacak barlar kopyalanir
   //    (atrBuf[0] = bar index'i atrBase, eskiden yeniye)
   if(lastBar>lastScanned)
     {
      int atrFrom = lastScanned+1;
      int cnt     = rates_total-atrFrom;
      ArraySetAsSeries(atrBuf,false);
      if(CopyBuffer(atrHandle,0,0,cnt,atrBuf)<cnt)
         return(0);
      atrBase = atrFrom;
     }

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
         z.timeC1      = time[c1];
         z.timeForm    = time[c3];
         z.timeTouch   = 0;
         z.isDemand    = true;
         z.top         = zTop;
         z.bottom      = zBottom;
         z.touched     = false;
         z.lastChecked = c2;
         z.endIdx      = c3;
         z.timeEnd     = time[c3];
         z.hasObj      = false;
         z.dirty       = true;
         z.atr         = atrBuf[c3-atrBase];
         z.fvgFar      = low[c3];
         z.ext         = z.top;
         z.extN        = z.top;
         InitOutcome(z);
         z.bo          = CountBO(high,low,c1,z.top,z.bottom);
         z.yp          = CountYP(high,low,c1-1,YPLookback,z.top,z.bottom);
         z.orj         = IsOriginalZone(high,low,c1,z.isDemand,z.top,z.bottom,ORJLookback);
         z.swLevel     = FindSwingLevel(high,low,c1,z.isDemand,z.top,z.bottom,SwingStrength,SwingLookback);
         InitCandleInfo(z);
         UpdateCandleInfo(z,high,low,close,rates_total-2);

         int n = ArraySize(zones);
         ArrayResize(zones,n+1,4096);
         zones[n] = z;
         int na = ArraySize(activeZones);
         ArrayResize(activeZones,na+1,4096);
         activeZones[na] = n;
         changed = true;
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
         z.timeC1      = time[c1];
         z.timeForm    = time[c3];
         z.timeTouch   = 0;
         z.isDemand    = false;
         z.top         = zTop;
         z.bottom      = zBottom;
         z.touched     = false;
         z.lastChecked = c2;
         z.endIdx      = c3;
         z.timeEnd     = time[c3];
         z.hasObj      = false;
         z.dirty       = true;
         z.atr         = atrBuf[c3-atrBase];
         z.fvgFar      = high[c3];
         z.ext         = z.bottom;
         z.extN        = z.bottom;
         InitOutcome(z);
         z.bo          = CountBO(high,low,c1,z.top,z.bottom);
         z.yp          = CountYP(high,low,c1-1,YPLookback,z.top,z.bottom);
         z.orj         = IsOriginalZone(high,low,c1,z.isDemand,z.top,z.bottom,ORJLookback);
         z.swLevel     = FindSwingLevel(high,low,c1,z.isDemand,z.top,z.bottom,SwingStrength,SwingLookback);
         InitCandleInfo(z);
         UpdateCandleInfo(z,high,low,close,rates_total-2);

         int n = ArraySize(zones);
         ArrayResize(zones,n+1,4096);
         zones[n] = z;
         int na = ArraySize(activeZones);
         ArrayResize(activeZones,na+1,4096);
         activeZones[na] = n;
         changed = true;
        }
     }

   if(lastBar>lastScanned)
      lastScanned = lastBar;

   //--- V1.25: mum ATR / ARD icin henuz yeterli mumu kapanmamis (en yeni) bolgeleri guncelle
   //    zones[] fvgIdx'e gore artan; tamamlanmis ilk bolgede durulur (daha eskiler de tamam)
   for(int m=ArraySize(zones)-1; m>=0; m--)
     {
      if(zones[m].cCnt>=3 && zones[m].seqChk)
         break;
      if(UpdateCandleInfo(zones[m],high,low,close,rates_total-2))
        {
         zones[m].dirty = true;
         changed = true;
        }
     }

   //--- Aktif bolgeleri (temas bekleyen / TP-SL takibi suren) isle.
   //    Biten bolgeler listeden cikarilir; her tickte tum zones[] taranmaz.
   int nActive = ArraySize(activeZones);
   int keep    = 0;
   for(int a=0;a<nActive;a++)
     {
      int k = activeZones[a];

      if(zones[k].touched)
        {
         // temas edilmis bolgenin TP/SL sonucunu kapanmis mumlarla takip et
         if(!zones[k].trackDone && UpdateOutcome(zones[k],high,low,rates_total-2))
           {
            zones[k].dirty = true;   // yazi (tp/sl) degisti
            changed = true;
           }
         if(!zones[k].trackDone)
            activeZones[keep++] = k;
         continue;
        }

      int checkFrom = MathMax(zones[k].fvgIdx, zones[k].lastChecked+1);
      bool hit = false;
      int hitIndex = -1;

      // yas siniri - bolge, 3. mumdan (fvgIdx) itibaren MaxZoneAgeBars mum yasar
      int  expiryIdx = (MaxZoneAgeBars>0) ? zones[k].fvgIdx+MaxZoneAgeBars : INT_MAX;
      int  scanTo    = MathMin(lastBar,expiryIdx);

      // degisim tespiti icin onceki durum
      double oExt    = zones[k].ext;
      double oExtN   = zones[k].extN;
      int    oExtIdx = zones[k].extIdx;
      bool   oFf     = zones[k].ffvgt;
      bool   oV      = zones[k].vbrk;

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
            // temas olmayan barlarda ulasilan en yuksek seviyeyi takip et
            if(high[j] > zones[k].ext)
              {
               zones[k].ext    = high[j];
               zones[k].extIdx = j;   // BU: en uzak noktaya ulasilan bar
              }
            // V1.22: yalnizca FVG mumu (fvgIdx) dahil ilk N mum icindeki en yuksek seviye
            if(j<=zones[k].fvgIdx+gWinN-1 && high[j] > zones[k].extN)
               zones[k].extN = high[j];
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
            // temas olmayan barlarda ulasilan en dusuk seviyeyi takip et
            if(low[j] < zones[k].ext)
              {
               zones[k].ext    = low[j];
               zones[k].extIdx = j;   // BU: en uzak noktaya ulasilan bar
              }
            // V1.22: yalnizca FVG mumu (fvgIdx) dahil ilk N mum icindeki en dusuk seviye
            if(j<=zones[k].fvgIdx+gWinN-1 && low[j] < zones[k].extN)
               zones[k].extN = low[j];
            // FFVGT: ilk temastan once FVG'ye girip (high > FVG alt) altinda kapanis
            if(!zones[k].ffvgt && j<=rates_total-2 && j>zones[k].fvgIdx &&
               high[j] > zones[k].fvgFar && close[j] < zones[k].fvgFar)
               zones[k].ffvgt = true;
            // V: onceki swing low, bolge olustuktan sonra (ilk temastan once) kapanisla kirildi mi
            if(!zones[k].vbrk && zones[k].swLevel>0.0 && j<=rates_total-2 && close[j] < zones[k].swLevel)
               zones[k].vbrk = true;
           }
        }

      if(hit)
        {
         zones[k].touched     = true;
         zones[k].lastChecked = hitIndex;
         zones[k].touchIdx    = hitIndex;      // sonuc takibi bu bardan baslar
         zones[k].timeTouch   = time[hitIndex];
         zones[k].outLast     = hitIndex-1;
         UpdateOutcome(zones[k],high,low,rates_total-2);
         zones[k].endIdx      = hitIndex;
         zones[k].timeEnd     = time[hitIndex];
         zones[k].dirty       = true;
         changed = true;
         if(!zones[k].trackDone)
            activeZones[keep++] = k;           // TP/SL takibi suruyor
        }
      else if(lastBar>=expiryIdx)
        {
         // Bolge yasini doldurdu, temas olmadi -> expiryIdx'te biter, bir daha cizilmez
         zones[k].touched     = true; // dongude tekrar islenmesin
         zones[k].trackDone   = true; // temas olmadi -> TP/SL takibi yok
         zones[k].lastChecked = expiryIdx;
         zones[k].endIdx      = expiryIdx;
         zones[k].timeEnd     = time[expiryIdx];
         zones[k].dirty       = true;
         changed = true;
         // listeden cikar (touched && trackDone)
        }
      else
        {
         // Kapanis bekleniyorsa lastBar tamamen kontrol edildi; beklenmiyorsa
         // olusmakta olan mum her tick'te yeniden kontrol edilsin diye bir geri al.
         zones[k].lastChecked = WaitForCandleClose ? lastBar : lastBar-1;

         // Yalnizca kutunun sag ucu ya da yazi icerigi degistiyse yeniden ciz
         if(zones[k].endIdx!=lastBar || zones[k].ext!=oExt || zones[k].extN!=oExtN || zones[k].extIdx!=oExtIdx ||
            zones[k].ffvgt!=oFf || zones[k].vbrk!=oV)
           {
            zones[k].endIdx  = lastBar;
            zones[k].timeEnd = time[lastBar];
            zones[k].dirty   = true;
            changed = true;
           }
         activeZones[keep++] = k;
        }
     }
   ArrayResize(activeZones,keep);

   RefreshTables(changed);

   return(rates_total);
  }
//+------------------------------------------------------------------+
