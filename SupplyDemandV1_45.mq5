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
//|  V1.28: ARD filtresi SIZINTI duzeltmesi (look-ahead). ARD, FVG      |
//|        mumundan sonraki SeqCandles kapanisina bakar; bolge bu       |
//|        pencere BITMEDEN (touchIdx <= fvgIdx+SeqCandles) temas       |
//|        edildiyse, temas aninda henuz bilinmeyen kapanislar filtreye |
//|        sizmis oluyordu. Artik bu bolgelerde ARD her zaman 'yok'.    |
//|        Temas pencereden SONRA ise (veya hic temas yoksa) degisiklik |
//|        yok. Strateji (bolge, temas, TP/SL) mantigina dokunulmadi.   |
//|  V1.29: Tarih filtresine ileri/geri sardirma butonlari. Tarih       |
//|        satirinin altinda 'Bas' (baslangic) ve 'Bit' (bitis) icin    |
//|        ikiser satir: [< Gun][Gun >] [< Ay][Ay >] [< Yil][Yil >].    |
//|        Ay/yil kaydirmada gun ay sonuna gore kisitlanir (31.01 ->    |
//|        28.02). Kutu bossa son bar gununden baslar ve tarih          |
//|        filtresini otomatik acar.                                    |
//|  V1.52: Kombinasyon testi kapsami DARALTILDI: Tip (TALEP/ARZ), HTF,     |
//|        1dk bolge / giris modeli satiri ve TARIH panelde nasil ise        |
//|        OLDUGU GIBI uygulanir (denenmez). DENENEN: formasyon satiri       |
//|        (ENG/PIN/RR/KB ve tum alt kumeleri, ornek ENG+KB), 12 aralik      |
//|        filtresi, Saat dilimi. FILTRE DISI: TP/SL butonlari ve altindaki  |
//|        ORJ/NORJ, FFVGT, ARD, V/UV (ne uygulanir ne denenir).             |
//|  V1.51: KOMBINASYON TESTI. Filtre panelinin ust satirindaki             |
//|        [Kombinasyon] butonu: Tarih araligi HARIC tum filtrelerin         |
//|        kombinasyonlarini dener, CSV'ye yazar. Veri = tabloyla ayni       |
//|        (1dk bolge acikken ana grafik bolgeleri, kapaliyken giris         |
//|        sinyalleri; yalniz TP/SL takibi baslamis olanlar). Tip, HTF,      |
//|        formasyon, saat dilimi, ORJ/FFVGT/ARD/V ve 12 aralik filtresi     |
//|        denenir; TP/SL seviye filtreleri sonuc oldugu icin denenmez.      |
//|        Aralik filtreleri icin 5 aralik veriden hesaplanir (alt/orta/ust  |
//|        ucte bir, alt/ust yari). Iki dosya yazilir: ..._KOMB.csv          |
//|        (sonuclar) ve ..._ARALIK.csv (hangi aralik / ayar denendi).       |
//|        Panel filtrelerine dokunmaz; zamanlayiciyla parca parca calisir,  |
//|        buton 'Iptal' olur.                                               |
//|  V1.50: Bolge OZELLIGI filtreleri (Tip, ORJ, FFVGT, ARD, V, BO, YP,      |
//|        uzaklasma, ATR vb. tum aralik filtreleri) artik giris sinyalini   |
//|        URETEN HTF BOLGESINE uygulanir; TP/SL seviye filtreleri ile saat  |
//|        / tarih filtresi sinyalin kendisine. 'Genislik ATR' icin           |
//|        EntryWidthOwn=true yapilirsa sinyalin kendi bolgesine bakilir.    |
//|  V1.49: Tablo (TP/SL sayaci) artik yalnizca GORUNEN sinyalleri sayar:     |
//|        kapatilan HTF'nin / kapatilan giris modelinin sinyalleri ve       |
//|        'Iptal goster' kapaliyken iptal sinyaller tabloya girmez.        |
//|  V1.48: KARA BULUT (KB) formasyonu eklendi (arzda dark cloud cover,   |
//|        talepte delici mum): 2. mum 1. mumun kapanisi civarinda/ustunde|
//|        acilir, 1. mum govdesinin YARISININ otesinde kapanir ama onu    |
//|        tamamen yutmaz. Bolge = iki mumun toplam araligi. Panelde        |
//|        [Kara Bulut] butonu. Oncelik: RR > ENG > KB > PIN.              |
//|  V1.47: GIRIS MODELI (V1.46 HTF uyum filtresi KALDIRILDI; taban V1.45)|
//|        Panelde [1dk bolge] ile ana grafik bolgeleri tamamen kapatilir. |
//|        Acik HTF bolgesinde, fiyat bolgeden uzaklasip BOLGEYE ILK KEZ   |
//|        temas ettiginde (temas mumu dahil, fiyat bolgenin icindeyken)    |
//|        ana grafikte 3 formasyondan biri olusursa giris bolgesi cizilir: |
//|          ENG (engulf)  : yutan mumun GOVDESI                           |
//|          PIN (pinbar)  : pinbar mumunun tum araligi (fitil dahil)      |
//|          RR  (railroad): iki ters mumun toplam araligi                 |
//|        Giris = bolgenin KARSI-YON kenari (arzda alt, talepte ust),     |
//|        STOP = diger kenar, TP1..TP8 = n x bolge yuksekligi. Giris,     |
//|        stop, TP1..TP8 cizgi + fiyat yazilari cizilir; sonuc (tp/sl)    |
//|        mevcut TP/SL takibiyle izlenir. Tablo giris sinyallerini sayar. |
//|  V1.45: UST ZAMAN DILIMI (HTF) BOLGELERI. Ana grafik (orn. 1dk)    |
//|        kalirken M5 / M15 / M30 / H1 / H4 / D1 bolgeleri de cizilir. |
//|        Her HTF icin AYNI bolge motoru (FVG tespiti, bolge siniri,   |
//|        temas, TP/SL, BO/YP/ORJ/FFVGT/BU/BD/BY/V/ARD/AF) o zaman     |
//|        diliminin kendi mumlari uzerinde calisir; mantik degismedi.  |
//|        Filtre panelinde Tip satirinin altinda M5..D1 ac/kapa        |
//|        butonlari var; her HTF ayri renkte. Yazinin basina TF eki    |
//|        eklenir ('M15 tp1|...'). HTF bolgeleri de panel filtrelerine |
//|        uyar (HtfUseFilters). Sol ust TP/SL tablosu ve CSV yalnizca  |
//|        ana grafik bolgelerini sayar (degismedi).                    |
//|  V1.44: Filtre panelinde Min/Max kutularinin yanina [-] [+] sardirma |
//|        butonlari. ATR filtreleri 0.05, sayi filtreleri (BO, YP, BU, |
//|        BD, BY, Acik FVG) 1 adimla artar/azalir. Alt sinir 0'in      |
//|        altina inmez. Kutu bossa 0'dan baslar ve filtreyi otomatik   |
//|        acar. Filtre/strateji mantigina dokunulmadi.                 |
//|  V1.43: Bolge siniri FVG boslugunun %25'ine cekildi (ZoneFvgPct).   |
//|        Talep: ust sinir = 1.mum tepesi + %25 x (3.mum dibi - 1.mum  |
//|        tepesi). Arz: alt sinir = 1.mum dibi - %25 x (1.mum dibi -   |
//|        3.mum tepesi). 0 yapilirsa eski davranis.                    |
//|  V1.42: AF YON KURALI. Talep bolgesinde yalnizca bolgenin ALTINDAKI  |
//|        yukselis FVG'leri, arz bolgesinde yalnizca bolgenin USTUNDEKI |
//|        dusus FVG'leri sayilir (onceden iki yon de sayiliyordu).      |
//|  V1.41: Tum bolge yazisi TEK NOKTADA ve 63 karakter sinirina gore   |
//|        SAYFALI: once TP/SL'ler sirali, kalan yere bilgiler sigdigi  |
//|        kadar; sigmayanlar sonraki sayfada. 'A' sayfalari degistirir.|
//|  V1.40: (yerine V1.41 gecti) YAZI GRUPLARI. Bolge yazilari 3 gruba ayrildi; 'A' tusu     |
//|        gruplari dongu halinde degistirir: 0 = TP/SL (varsayilan),   |
//|        1 = olculer (ATR, BO, YP, ORJ, FFVGT, BU, BD, BY, V/UV),     |
//|        2 = mum ATR / ARD / AF. Ayni anda tek grup gorunur.          |
//|  V1.39: ACIK FVG SAYISI duzeltmesi. (1) OpenFvgLookback varsayilani   |
//|        70 -> 10. (2) Pencere hatasi: yalnizca FVG'nin 3. mumu       |
//|        pencereye bakiyordu, 1. mum 2 mum disari tasiyordu. Simdi    |
//|        FVG'nin 3 mumu da son OpenFvgLookback mum icinde olmali.     |
//|  V1.38: ACIK FVG SAYISI. Bolge olustugunda (FVG mumu kapanisinda)   |
//|        son OpenFvgLookback (vars. 10) muma bakilir; o ana kadar     |
//|        henuz kapatilmamis (doldurulmamis) FVG'lerin sayisi bir     |
//|        KEZ hesaplanip bolgenin sol ust kosesinde 'AF:n' olarak       |
//|        yazilir, sonradan degismez. Panelde 'Acik FVG' min-max       |
//|        filtresi, CSV'de AcikFVG kolonu. Bolgenin kendi FVG'si       |
//|        sayilmaz. OpenFvgFillMode: 0 = tam kapanma (FVG alt/ust      |
//|        siniri gecilmis), 1 = kismi (FVG'ye giren her fiyat).        |
//|  V1.37: Varsayilan bitis tarihi 01.01.2020 yapildi.                 |
//|  V1.36: Bolge yazisinda ARD artik etkin pencere uzunlugunu da       |
//|        gosterir ('ARD3', 'ARD4' ...). Hangi SeqCandles degerinin    |
//|        gercekten calistigini grafikten dogrulamak icin.             |
//|  V1.35: ARD penceresine 2. mum (FVG'den bir onceki, displacement)  |
//|        dahil edilebilir: SeqIncludeC2=true iken pencere 2. mum +   |
//|        sonraki (SeqCandles-1) mum = vars. 3 mum (2., 3. ve 4. mum). |
//|        false = eski: FVG mumundan SONRAKI SeqCandles mum. Sizinti   |
//|        korumasi pencerenin son mumuna gore guncellendi.            |
//|  V1.34: ARD tanimi degisti: FVG mumundan (3.mum) sonraki SeqCandles |
//|        mum UST USTE AYNI RENKTE olmali: talepte hepsi yukselen      |
//|        (kapanis > acilis), arzda hepsi dusen (kapanis < acilis).    |
//|        Eskiden kapanislarin birbirinden yuksek/dusuk olmasina       |
//|        bakiliyordu, mum rengi onemsizdi. Sizinti korumasi (V1.28)   |
//|        aynen duruyor.                                               |
//|  V1.33: TP/SL KURALI (temas mumu dahil). Islem bolgeden girdikten  |
//|        sonra bir mum KAPANDIGINDA: mum boyunca SL fiyatina (bolge   |
//|        kirilimi) dokunulmadiysa ve kapanis bir TP fiyatinin ote-    |
//|        sindeyse (arz: altinda, talep: ustunde) o TP KESIN olmustur. |
//|        Temas mumunda yalnizca KAPANIS esas alinir (mum ici dip/tepe |
//|        temastan once olmus olabilir). Sonraki mumlarda SL'e         |
//|        dokunulmadiysa mumun dip/tepesinin TP'ye ulasmasi yeterli.   |
//|        Mumda SL'e dokunulduysa sonuclanmamis tum seviyeler SL.      |
//|        (V1.30-V1.32 mum yonu / alt zaman dilimi denemeleri kalkti.) |
//|  AMA: Kaufman Adaptive Moving Average eklendi (vars. periyot 9,     |
//|        hizli EMA 2, yavas EMA 30). Ayarlar 'Adaptive Moving Average'|
//|        grubunda; kapanis fiyatina gore hesaplanir.                  |
//+------------------------------------------------------------------+
#property copyright "Claude"
#property indicator_chart_window
#property indicator_buffers 1
#property indicator_plots   1
#property indicator_label1  "AMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrRed
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

//--- Ayarlanabilir parametreler
input bool    ShowDemandZones   = true;             // Talep (destek) bolgelerini goster
input bool    ShowSupplyZones   = true;              // Arz (direnc) bolgelerini goster
input color   DemandColor       = clrLightCyan;       // Talep bolgesi rengi
input color   SupplyColor       = clrMistyRose;        // Arz bolgesi rengi
input bool    ShowBorder        = false;                // Kutu kenar cizgisi
input bool    ShowEquilibrium   = true;                  // Ortadaki denge (50%) noktasini goster
input color   EquilibriumColor  = clrYellow;              // Denge noktasi rengi
input int     MaxHistoryBars    = 0;                       // Geriye donuk en fazla kac bar taransin (0 = sinirsiz)
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
input bool    CsvDecimalComma    = false;                   // Ozet CSV: ondalik ayraci virgul olsun (yalnizca ayirac ; iken). Kayma olursa kapali tut
input int     ORJLookback        = 60;                      // ORJ/NORJ: onceki ayni yonlu bolge icin geriye kac mum taransin
input int     MaxZoneAgeBars     = 60;                      // Bolgenin azami yasi (mum). Sonra saga uzamaz (0 = sinirsiz)
input int     FirstNCandles      = 3;                       // Ilk N Mum ATR filtresi: FVG mumu (3.mum) dahil kac mum (3 / 4 / 5 ...)
input int     CandleAtrMode      = 0;                       // Mum ATR filtreleri: 0 = mum boyu (high-low)/ATR, 1 = bolge kenarindan uzaklasma/ATR
input int     OpenFvgLookback    = 10;                      // V1.38: Acik FVG sayisi icin kac mum geriye bakilsin (FVG'nin 3 mumu da bu pencerede olmali)
input double  ZoneFvgPct         = 25.0;                    // V1.43: Bolge siniri FVG boslugunun yuzde kacina cekilsin (0 = eski: 1. mum siniri, 100 = FVG'nin ucu). Talep: ust sinir, arz: alt sinir
input int     OpenFvgFillMode    = 0;                       // V1.38: FVG kapanmis sayilma: 0 = tam (talep FVG'de alt siniri, arz FVG'de ust siniri gecen fiyat), 1 = kismi (FVG'ye giren herhangi fiyat)
input bool    SeqIncludeC2       = true;                    // V1.35: ARD penceresi 2. mumu (FVG'den onceki) da icersin; false = yalnizca FVG mumundan sonraki mumlar
input int     SeqCandles         = 3;                       // ARD: FVG mumundan sonra kac mum ust uste yukselen (arzda dusen) RENKLI mum olsun

input group "=== V1.45 Ust Zaman Dilimi (HTF) Bolgeleri ==="
input bool    HtfShowM5          = false;                   // Acilista M5 bolgeleri gorunsun (panelden de acilip kapanir)
input bool    HtfShowM15         = false;                   // Acilista M15 bolgeleri gorunsun
input bool    HtfShowM30         = false;                   // Acilista M30 bolgeleri gorunsun
input bool    HtfShowH1          = false;                   // Acilista H1 bolgeleri gorunsun
input bool    HtfShowH4          = false;                   // Acilista H4 bolgeleri gorunsun
input bool    HtfShowD1          = false;                   // Acilista D1 bolgeleri gorunsun
input bool    HtfUseFilters      = true;                    // HTF bolgeleri de panel filtrelerine (ATR, tarih, TP/SL...) uysun
input bool    HtfShowLabels      = true;                    // HTF bolgelerine yazi (TF eki + TP/SL + bilgiler) yazilsin
input int     HtfMaxBars         = 0;                       // Her HTF icin en fazla kac HTF mumu taransin (0 = tum gecmis)
input color   HtfM5DemandColor   = clrPaleGreen;            // M5 talep rengi
input color   HtfM5SupplyColor   = clrPink;                 // M5 arz rengi
input color   HtfM15DemandColor  = clrLightSkyBlue;         // M15 talep rengi
input color   HtfM15SupplyColor  = clrLightSalmon;          // M15 arz rengi
input color   HtfM30DemandColor  = clrAquamarine;           // M30 talep rengi
input color   HtfM30SupplyColor  = clrKhaki;                // M30 arz rengi
input color   HtfH1DemandColor   = clrPlum;                 // H1 talep rengi
input color   HtfH1SupplyColor   = clrSandyBrown;           // H1 arz rengi
input color   HtfH4DemandColor   = clrThistle;              // H4 talep rengi
input color   HtfH4SupplyColor   = clrTan;                  // H4 arz rengi
input color   HtfD1DemandColor   = clrLightSteelBlue;       // D1 talep rengi
input color   HtfD1SupplyColor   = clrRosyBrown;            // D1 arz rengi

input group "=== V1.47 Giris Modeli (HTF bolgesine ilk temas + formasyon) ==="
input bool    MainZonesVisible   = true;                    // Acilista ana grafik (1dk) bolgeleri gorunsun (panelden [1dk bolge] ile kapatilir)
input bool    EntryModelOn       = true;                    // Giris modeli acik (panelden [Giris modeli]); en az bir HTF acik olmali
input bool    EntryUseEngulf     = true;                    // Engulf formasyonu (yutan mumun govdesi bolge olur)
input bool    EntryUsePinbar     = true;                    // Pinbar formasyonu (mumun tum araligi bolge olur)
input bool    EntryUseRail       = true;                    // Railroad track (iki ters mumun toplam araligi bolge olur)
input bool    EntryUseKb         = true;                    // Kara Bulut (arzda dark cloud cover / talepte delici mum; iki mumun toplam araligi bolge olur)
input int     KbOpenTolPct       = 25;                      // Kara Bulut: 2. mum 1. mumun kapanisindan en fazla bu kadar (% govde) ters yonde acilabilir
input int     KbBodyPct          = 50;                      // Kara Bulut: 1. mumun govdesi kendi araliginin en az % kaci
input bool    EntryShowCancelled = false;                   // Girisi gerceklesmeyen (stop once vuruldu / sure doldu) sinyaller de cizilsin
input bool    EntryNeedAway      = true;                    // Ilk temastan once fiyat bolgeden uzaklasmis (bolgeye degmeyen mum) olmali
input bool    EntryWidthOwn      = false;                   // 'Genislik ATR' filtresi sinyalin KENDI bolgesine uygulansin (false: sinyali ureten HTF bolgesine)
input int     EntryMaxWaitBars   = 20;                      // Formasyondan sonra giris seviyesine en fazla kac mumda ulasilmali
input int     PinWickPct         = 60;                      // Pinbar: fitil, mum araliginin en az % kaci
input int     PinOppWickPct      = 25;                      // Pinbar: karsi fitil, mum araliginin en fazla % kaci
input int     RailBodyPct        = 60;                      // Railroad: her iki mumun govdesi kendi araliginin en az % kaci
input int     RailTolPct         = 30;                      // Railroad: govde boyu / acilis-kapanis eslesme toleransi (%)
input bool    EntryShowLevels    = true;                    // Giris / stop / TP1..TP8 cizgileri ve fiyat yazilari
input color   EntryDemandColor   = clrDodgerBlue;           // Giris bolgesi rengi (talep / alis)
input color   EntrySupplyColor   = clrRed;                  // Giris bolgesi rengi (arz / satis)

input group "=== V1.51 Kombinasyon Testi (panelde [Kombinasyon] butonu) ==="
input int     OptMinTrades       = 30;                      // Bir kombinasyonun CSV'ye yazilmasi icin en az islem sayisi (TP/SL takibi baslamis)
input int     OptMaxDepth        = 3;                       // Ayni anda en fazla kac filtre birlestirilsin (1-4; yuksek deger cok uzun surer)
input int     OptMaxRows         = 300000;                  // CSV'ye yazilacak en fazla satir (guvenlik siniri)

input group "=== Adaptive Moving Average (Kaufman AMA) ==="
input bool    ShowAMA            = true;                    // AMA cizgisini goster
input int     AMAPeriod          = 9;                       // AMA periyodu (Efficiency Ratio icin)
input int     AMAFastEMA         = 2;                       // AMA hizli EMA periyodu
input int     AMASlowEMA         = 30;                      // AMA yavas EMA periyodu
input color   AMAColor           = clrRed;                  // AMA cizgi rengi
input int     AMAWidth           = 1;                       // AMA cizgi kalinligi

double AMABuf[];   // AMA gostergesi tamponu

#define NLEV 8          // TP/SL seviye sayisi (1 e N odul: TPn = n x bolge yuksekligi)
#define NLEV_MAIN 3     // ana yazida gosterilen seviye sayisi (kalanlar 2. yaziya)

//--- V1.45: ust zaman dilimi (HTF) ortak durum degiskenleri
#define NHTF 6
bool            htfOn[NHTF];                 // panelde acik mi
bool            htfAvail[NHTF];              // HTF > grafik zaman dilimi mi (degilse kullanilmaz)
ENUM_TIMEFRAMES htfTf[NHTF];
string          htfName[NHTF] = {"M5","M15","M30","H1","H4","D1"};
color           htfDemClr[NHTF];
color           htfSupClr[NHTF];
bool            htfSyncValid = false;        // HTF nesne senkron penceresi gecerli mi
int             htfSyncL     = 0;            // senkron penceresi (ana grafik bar index'i)
int             htfSyncR     = 0;
bool            htfPending   = false;        // hazir olmayan (veri/ATR bekleyen) HTF var mi

//--- V1.47: giris modeli durum degiskenleri
bool            fltMain   = true;            // ana grafik (1dk) bolgeleri gorunur mu
bool            entryOn   = true;            // giris modeli acik mi
bool            entryEng  = true;            // formasyonlar
bool            entryPin  = true;
bool            entryRail = true;
bool            entryKb   = true;            // V1.48: Kara Bulut
bool            entryCxl  = false;           // iptal olan sinyaller de gosterilsin mi
int             gSigSeq   = 0;               // sinyal numarasi (nesne adlari icin)
//--- ana grafik OHLC aynasi (olay / zamanlayicidan da taranabilsin diye)
datetime        mT[];
double          mO[];
double          mH[];
double          mL[];
double          mC[];
int             mN = 0;

//--- HTF islevleri (govdeleri OnCalculate'ten once; burada on tanim)
bool   EntryUpdate();
void   EntryResetAll();
bool   optRunning = false;       // V1.51: kombinasyon testi calisiyor mu
void   OptToggle();
string OptButtonText();
void   OptOnTimer();
void   OptShutdown();
bool   HtfSync(const bool force);
bool   HtfUpdateAll();
void   HtfMarkAllDirty();
void   HtfOnFullCalc();
int    HtfMaxLabelPages();
void   HtfOnToggle(const int i);
void   HtfInit();
void   HtfDeinit();

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
//| V1.38/V1.42: idx mumunun (bolgeyi dogrulayan FVG mumu) kapanisindaki |
//| ACIK FVG sayisi. YALNIZCA bolgenin yonune uygun FVG'ler sayilir:    |
//|  TALEP bolgesi: bolgenin ALTINDAKI (FVG ust siniri low[k] <= bolge  |
//|                 dibi) YUKSELIS FVG'leri                              |
//|  ARZ bolgesi  : bolgenin USTUNDEKI (FVG alt siniri high[k] >= bolge |
//|                 tepesi) DUSUS FVG'leri                               |
//| Pencere: idx-lookback .. idx-1; FVG'nin UC mumu da (k-2,k-1,k) bu    |
//| pencerede olmali -> 3. mum k, idx-lookback+2 .. idx-1. Bolgenin      |
//| kendi FVG'si haric.                                                  |
//| Bir FVG, k+1 .. idx arasindaki mumlarla kapandiysa sayilmaz:        |
//|  mod 0 (tam): yukselis FVG'de low <= FVG alt siniri (high[k-2]),   |
//|               dusus FVG'de high >= FVG ust siniri (low[k-2]).       |
//|  mod 1 (kismi): yukselis FVG'de low < low[k] (FVG ust siniri),       |
//|               dusus FVG'de high > high[k].                          |
//| Yalnizca idx'e kadar olan veri kullanilir (gelecege bakilmaz).      |
//+------------------------------------------------------------------+
int CountOpenFVG(const double &high[],const double &low[],const int idx,const int lookback,
                 const bool isDemand,const double zTop,const double zBottom)
  {
   int cnt  = 0;
   // V1.39: FVG'nin 1. mumu (k-2) da pencere icinde olmali -> k >= idx-lookback+2.
   int from = MathMax(2,idx-MathMax(3,lookback)+2);
   for(int k=from;k<idx;k++)
     {
      // V1.42: talepte yalnizca yukselis FVG (bolgenin altinda), arzda yalnizca dusus FVG (bolgenin ustunde)
      bool bull = false, bear = false;
      if(isDemand)
        {
         bull = IsFVG(high,low,k-2,k,true) && (low[k] <= zBottom);
         if(!bull)
            continue;
        }
      else
        {
         bear = IsFVG(high,low,k-2,k,false) && (high[k] >= zTop);
         if(!bear)
            continue;
        }
      bool closed = false;
      for(int m=k+1;m<=idx && !closed;m++)
        {
         if(bull)
            closed = (OpenFvgFillMode==1) ? (low[m]  < low[k])    : (low[m]  <= high[k-2]);
         else
            closed = (OpenFvgFillMode==1) ? (high[m] > high[k])   : (high[m] >= low[k-2]);
        }
      if(!closed)
         cnt++;
     }
   return(cnt);
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
   int      openFvg;      // V1.38: bolge olustugunda henuz kapatilmamis FVG sayisi (bir kez hesaplanir)
   int      tfSec;        // V1.45: 0 = ana grafik bolgesi, >0 = HTF bolgesi (zaman diliminin saniyesi), V1.47: -1 = giris sinyali
   int      sigType;      // V1.47: sinyal formasyonu 1 = ENG, 2 = PIN, 3 = RR
   int      sigSlot;      // V1.47: sinyali ureten HTF (htfName index'i)
   int      sigState;     // V1.47: 0 = giris bekliyor, 1 = girildi (sonuc takibi), 2 = iptal, 3 = silindi
   int      sigId;        // V1.47: benzersiz sinyal numarasi
   int      sigZone;      // V1.50: sinyali ureten HTF bolgesinin motor icindeki index'i
  };

SDZoneInfo zones[];
SDZoneInfo sigs[];        // V1.47: giris sinyalleri (SDZoneInfo ile ayni sonuc takibi; tfSec = -1)
int        sigActive[];  // V1.47: takibi suren sinyal index'leri
bool       SigParentGet(const SDZoneInfo &z,SDZoneInfo &p);   // V1.50: sinyalin ana HTF bolgesi (govdesi HTF blogunda)
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
//| V1.43: ZoneFvgPct'i 0..1 araligina cevir                          |
//+------------------------------------------------------------------+
double FvgPctClamp()
  {
   return(MathMax(0.0,MathMin(100.0,ZoneFvgPct))/100.0);
  }

//+------------------------------------------------------------------+
//| Bolge nesne adi. kind: "" = kutu, "eq" = denge, "bd" = kenar,     |
//| "lb" = yazi, "l2" = TP4-8 yazisi.  (Eski adlandirma ile birebir ayni: SDZ_D_123 ...)   |
//+------------------------------------------------------------------+
string ZObjName(const SDZoneInfo &z,const string kind)
  {
   // V1.47: giris sinyali adlari
   if(z.tfSec<0)
      return(prefix + "E" + IntegerToString(z.sigId) + (z.isDemand ? "D" : "S") + kind);
   // V1.45: HTF bolgelerinde ada TF eki girer (ana grafik adlari AYNEN eskisi gibi)
   return(prefix + (z.tfSec>0 ? "H"+IntegerToString(z.tfSec)+"_" : "") + (z.isDemand ? "D" : "S") + kind + "_" + IntegerToString(z.fvgIdx));
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
//| - SL (kirilim) o mumda yoksa:                                     |
//|     * temas mumu: kapanis TPn fiyatinin otesindeyse TPn (kesin)   |
//|     * sonraki mumlar: dip/tepe TPn'ye ulastiysa TPn               |
//| - SL (kirilim) o mumda varsa: sonuclanmamis tum seviyeler SLn     |
//|   (mum ici sira bilinemez -> SL oncelikli).                       |
//| Donus: bir seviye yeni sonuclandiysa true                         |
//+------------------------------------------------------------------+
bool UpdateOutcome(SDZoneInfo &z,const double &high[],const double &low[],const double &close[],int closedLast)
  {
   if(z.touchIdx<0 || z.trackDone)
      return(false);

   bool   changed = false;
   double h       = z.top - z.bottom;
   int    from    = MathMax(z.touchIdx,z.outLast+1);

   for(int j=from;j<=closedLast;j++)
     {
      bool broke = z.isDemand ? (low[j] < z.bottom) : (high[j] > z.top);

      bool isTouchBar = (j==z.touchIdx);

      for(int n=1;n<=NLEV;n++)
        {
         if(z.out[n-1]!=0)
            continue;

         // TP: yalnizca mumda SL'e dokunulmadiysa degerlendirilir.
         //  temas mumu : KAPANIS TPn fiyatinin otesinde mi (kesin)
         //  diger mumlar: dip/tepe TPn fiyatina ulasti mi
         bool reached = false;
         if(!broke)
           {
            if(isTouchBar)
               reached = z.isDemand ? (close[j] >= z.top    + n*h)
                                    : (close[j] <= z.bottom - n*h);
            else
               reached = z.isDemand ? (high[j]  >= z.top    + n*h)
                                    : (low[j]   <= z.bottom - n*h);
           }

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
//| V1.41: TEK NOKTADA SAYFALI YAZI. Bolgenin tum bilgisi tek yazida,  |
//| MT5'in 63 karakter sinirina gore sayfalara bolunur:                |
//|   [tp1|tp2|sl3 ...] ~ [bilgi|bilgi|...]                            |
//| Her sayfa once sonuclanmis TP/SL'leri SIRAYLA yazar, kalan yere    |
//| siradaki bilgileri sigabildigi kadar ekler; sigmayanlar sonraki    |
//| sayfaya gecer. 'A' tusu sayfalari dongu halinde degistirir.        |
//| Bilgi sirasi: genislik ATR, uzaklasma ATR, BO, YP, ORJ, FFVGT, BU, |
//| BD, BY, V/UV, M a/b/c, ARD, AF.                                    |
//+------------------------------------------------------------------+
#define LBL_MAXLEN 63
int gLabelPage = 0;   // 'A' ile degisen sayfa no (bolge kendi sayfa sayisina gore modlar)

//--- q0 .. q1-1 arasi sonuclanmis TP/SL seviyeleri: "tp1|sl2|..."
string LevelText(const SDZoneInfo &z,const int q0,const int q1)
  {
   string r = "";
   for(int q=q0;q<q1;q++)
     {
      if(z.out[q]==1)
         r += (r=="" ? "" : "|") + "tp"+IntegerToString(q+1);
      else if(z.out[q]==2)
         r += (r=="" ? "" : "|") + "sl"+IntegerToString(q+1);
     }
   return(r);
  }

//--- Bolgenin bilgi parcalari (oncelik sirasiyla)
int ZoneInfoItems(const SDZoneInfo &z,string &it[])
  {
   ArrayResize(it,24);   // en fazla ~13 parca
   int n = 0;
   if(z.atr>0.0)
     {
      double move = z.isDemand ? MathMax(0.0,z.ext-z.top) : MathMax(0.0,z.bottom-z.ext);
      string mv   = (move>0.0 ? (z.isDemand ? "+" : "-") : "") + DoubleToString(move/z.atr,2);
      it[n++] = DoubleToString((z.top-z.bottom)/z.atr,2)+"ATR";
      it[n++] = mv+"ATR";
     }
   it[n++] = "BO"+IntegerToString(z.bo);
   it[n++] = "YP"+IntegerToString(z.yp);
   it[n++] = (z.orj ? "ORJ" : "NORJ");
   if(z.ffvgt)
      it[n++] = "FFVGT";
   it[n++] = "BU"+IntegerToString(z.extIdx-z.fvgIdx);
   if(z.touchIdx>=0)
     {
      it[n++] = "BD"+IntegerToString(z.touchIdx-z.extIdx);
      it[n++] = "BY"+IntegerToString(z.touchIdx-z.fvgIdx);
     }
   it[n++] = (z.vbrk ? "V" : "UV");
   if(z.cCnt>0)
     {
      string m = "M ";
      for(int cq=0;cq<z.cCnt;cq++)
         m += (cq>0 ? "/" : "") + DoubleToString(z.cAtr[cq],2);
      it[n++] = m;
     }
   if(z.seq)
      it[n++] = "ARD"+IntegerToString(MathMax(1,SeqCandles));
   it[n++] = "AF:"+IntegerToString(z.openFvg);
   ArrayResize(it,n);
   return(n);
  }

//--- Bolgenin yazisi: page. sayfa (sayfa sayisini asarsa basa doner). pages = toplam sayfa
string ZoneLabelTextEx(const SDZoneInfo &z,const int page,int &pages,const int maxLen)
  {
   string tp = LevelText(z,0,NLEV);
   int    pre = StringLen(tp) + (tp=="" ? 0 : 3);        // "tp.. ~ " on eki
   string it[];
   int    n  = ZoneInfoItems(z,it);

   string txt[];
   ArrayResize(txt,0);
   string cur = "";
   for(int i=0;i<n;i++)
     {
      if(cur!="" && pre+StringLen(cur)+1+StringLen(it[i])>maxLen)
        {
         int c = ArraySize(txt);
         ArrayResize(txt,c+1);
         txt[c] = cur;
         cur = it[i];
        }
      else
         cur += (cur=="" ? "" : "|") + it[i];
     }
   int c2 = ArraySize(txt);
   ArrayResize(txt,c2+1);
   txt[c2] = cur;
   pages = c2+1;

   string body = txt[((page%pages)+pages)%pages];
   string res  = tp + ((tp!="" && body!="") ? " ~ " : "") + body;
   if(StringLen(res)>maxLen)                               // guvenlik (normalde olmaz)
      res = StringSubstr(res,0,maxLen);
   return(res);
  }

//--- Ana grafik icin eski imza (davranis ayni: LBL_MAXLEN)
string ZoneLabelText(const SDZoneInfo &z,const int page,int &pages)
  {
   return(ZoneLabelTextEx(z,page,pages,LBL_MAXLEN));
  }

//--- Bolgenin tek yazisi: talep -> kutunun alti, arz -> kutunun ustu (sag kose)
void DrawZoneLabels(const SDZoneInfo &z,const datetime tStart,const datetime tEnd,const color bc)
  {
   string name  = ZObjName(z,"lb");
   int    pages = 1;
   string txt   = ZoneLabelText(z,gLabelPage,pages);
   double price = z.isDemand ? z.bottom : z.top;

   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_TEXT,0,tEnd,price))
         return;
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_COLOR,bc);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   else
      ObjectMove(0,name,0,tEnd,price);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
  }

//--- Tum bolgeler icindeki en buyuk sayfa sayisi ('A' dongusu icin)
int MaxLabelPages()
  {
   int mx = 1;
   for(int k=0;k<ArraySize(zones);k++)
     {
      int p = 1;
      ZoneLabelText(zones[k],0,p);
      if(p>mx)
         mx = p;
     }
   int hp = HtfMaxLabelPages();     // V1.45
   if(hp>mx)
      mx = hp;
   return(mx);
  }

//--- Sol altta hangi sayfanin acik oldugunu gosteren kucuk gosterge
void UpdateGroupLabel()
  {
   string n = prefix+"GRP_LBL";
   if(!ShowATRLabel)
     {
      ObjectDelete(0,n);
      return;
     }
   if(ObjectFind(0,n)<0)
     {
      if(!ObjectCreate(0,n,OBJ_LABEL,0,0,0))
         return;
      ObjectSetInteger(0,n,OBJPROP_CORNER,CORNER_LEFT_LOWER);
      ObjectSetInteger(0,n,OBJPROP_ANCHOR,ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0,n,OBJPROP_XDISTANCE,10);
      ObjectSetInteger(0,n,OBJPROP_YDISTANCE,8);
      ObjectSetString(0,n,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,n,OBJPROP_FONTSIZE,9);
      ObjectSetInteger(0,n,OBJPROP_COLOR,clrDarkGray);
      ObjectSetInteger(0,n,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,n,OBJPROP_HIDDEN,true);
     }
   ObjectSetString(0,n,OBJPROP_TEXT,"Yazi sayfasi "+IntegerToString(gLabelPage+1)+"   [A = sonraki sayfa]");
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

   if(ShowATRLabel)
      DrawZoneLabels(z,tStart,tEnd,bc);
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
#define TBL_W     315   // tablo / panel genisligi (piksel)
#define TBL_ROWH  18    // istatistik tablosu satir yuksekligi
#define TBL_H     (TBL_ROWH*(NLEV+2)+10)   // tablo yuksekligi: baslik + NLEV seviye + bilgi satiri
#define FLT_N     12    // aralik (min-max) filtresi sayisi

string fltName[FLT_N] = {"Genislik ATR","Uzaklasma ATR","BO","YP","BU","BD","BY","Ilk 3 Mum ATR","FVG Mum ATR","FVG+1 Mum ATR","FVG+2 Mum ATR","Acik FVG"};   // son ad OnInit'te N'e gore guncellenir
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
      case 11:
         v = (double)z.openFvg;      // V1.38: bolge olustugundaki acik FVG sayisi
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
//--- i. aralik filtresi z icin gecerli mi (filtre kapaliysa / sinirsizsa gecer)
bool FltValuePass(const SDZoneInfo &z,const int i)
  {
   if(!fltOn[i])
      return(true);
   if(!fltHasMin[i] && !fltHasMax[i])
      return(true);
   double v;
   if(!FltValue(z,i,v))
      return(false);                  // deger yok (temassiz bolge) -> filtre aciksa elenir
   if(fltHasMin[i] && v < NormalizeDouble(fltMin[i],2))
      return(false);
   if(fltHasMax[i] && v > NormalizeDouble(fltMax[i],2))
      return(false);
   return(true);
  }

//--- V1.50: bolge OZELLIGI filtreleri (Tip, ORJ, FFVGT, ARD, V + tum aralik filtreleri).
//--- Ana grafik bolgesinde bolgenin kendisine, giris sinyalinde sinyali ureten HTF bolgesine uygulanir.
bool ZonePropsPass(const SDZoneInfo &z,const bool skipWidth)
  {
   if(z.isDemand ? !fltDemand  : !fltSupply)  return(false);
   if(z.orj      ? !fltOrj     : !fltNorj)    return(false);
   if(z.ffvgt    ? !fltFfvgtY  : !fltFfvgtN)  return(false);
   if(z.seq      ? !fltSeqY    : !fltSeqN)    return(false);
   if(z.vbrk     ? !fltV       : !fltUV)      return(false);
   for(int i=0;i<FLT_N;i++)
     {
      if(i==0 && skipWidth)
         continue;
      if(!FltValuePass(z,i))
         return(false);
     }
   return(true);
  }

bool ZonePasses(const SDZoneInfo &z)
  {
   if(z.tfSec==0 && !fltMain)
      return(false);         // V1.47: ana grafik bolgeleri panelden kapatildi

   if(!fltActive)
      return(true);          // hicbir filtre aktif degil

   bool sg = (z.tfSec<0);    // V1.47: giris sinyali

   if(!sg)
     {
      if(!ZonePropsPass(z,false))
         return(false);
     }
   else
     {
      // V1.50: ozellik filtreleri sinyali ureten HTF bolgesine; bulunamazsa sinyalin kendisine
      SDZoneInfo pz;
      if(!SigParentGet(z,pz))
         pz = z;
      if(!ZonePropsPass(pz,EntryWidthOwn))
         return(false);
      if(EntryWidthOwn && !FltValuePass(z,0))
         return(false);
     }

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

//+------------------------------------------------------------------+
//| V1.29: Tarihi birim kadar kaydir. unit: 0=gun, 1=ay, 2=yil;        |
//| dir: -1 geri, +1 ileri. Ay/yil kaydirmada gun ay sonuna gore        |
//| kisitlanir. Gecerli aralik (1971..2100) disina cikarsa d degismez.  |
//+------------------------------------------------------------------+
datetime ShiftDate(const datetime d,const int unit,const int dir)
  {
   MqlDateTime dt;
   TimeToStruct(d,dt);
   if(unit==0)
     {
      datetime t = d + (datetime)(dir*86400);
      TimeToStruct(t,dt);
      if(dt.year<1971 || dt.year>2100)
         return(d);
      return(t);
     }
   if(unit==1)
     {
      int m = dt.mon-1+dir;
      int yAdd = (m<0) ? -1 : (m>11 ? 1 : 0);
      dt.year += yAdd;
      dt.mon   = m - yAdd*12 + 1;
     }
   else
      dt.year += dir;
   if(dt.year<1971 || dt.year>2100)
      return(d);
   dt.hour = 0; dt.min = 0; dt.sec = 0;
   int day = dt.day;
   for(; day>=1; day--)   // gun 28'den kucukse ilk denemede zaten gecerli; ay sonunda geriye kisitlanir
     {
      MqlDateTime c = dt;
      c.day = day;
      datetime t = StructToTime(c);
      MqlDateTime r;
      TimeToStruct(t,r);
      if(r.mon==dt.mon && r.year==dt.year)
         return(t);
     }
   return(d);
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
//--- V1.49: sinyal HTF / giris modeli acik mi (filtreden bagimsiz) ve filtreden de geciyor mu
bool SigEnabled(const SDZoneInfo &z)
  {
   if(z.sigState==3 || !entryOn)
      return(false);
   int sl = z.sigSlot;
   if(sl<0 || sl>=NHTF || !htfOn[sl] || !htfAvail[sl])
      return(false);
   if(z.sigState==2 && !entryCxl)
      return(false);
   return(true);
  }

bool SigShown(const SDZoneInfo &z)
  {
   return(SigEnabled(z) && ZonePasses(z));
  }

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

   // V1.47: ana grafik bolgeleri kapaliysa tablo GIRIS SINYALLERINI sayar (ikisi karistirilmaz)
   bool sigMode = !fltMain;
   if(sigMode)
     {
      ArrayInitialize(tp,0);
      ArrayInitialize(sl,0);
      int nSig = ArraySize(sigs);
      total = 0;
      pass = 0;
      passTouched = 0;
      for(int sk=0;sk<nSig;sk++)
        {
         if(!SigEnabled(sigs[sk]))
            continue;
         total++;
         if(!ZonePasses(sigs[sk]))
            continue;
         pass++;
         if(sigs[sk].sigState==1)
            passTouched++;
         for(int sq=0;sq<NLEV;sq++)
           {
            if(sigs[sk].out[sq]==1)
               tp[sq]++;
            else if(sigs[sk].out[sq]==2)
               sl[sq]++;
           }
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
   int x6 = TableX+272;   // V1.27: Profit Factor sutunu
   SetCell(prefix+"STAT_H6",x6,y0,"PF",clrBlack);

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
      // V1.27: Profit Factor = brut kar / brut zarar = (TP*n) / SL
      string pfTx = "-";
      color  pfc  = clrBlack;
      if(sl[q]>0)
        {
         double pf = (double)tp[q]*(q+1)/sl[q];
         pfTx = DoubleToString(pf,2);
         pfc  = (pf>1.0) ? clrGreen : (pf<1.0 ? clrRed : clrBlack);
        }
      else if(tp[q]>0)
        { pfTx = "inf"; pfc = clrGreen; }
      SetCell(prefix+"STAT_R"+id+"6",x6,y,pfTx,pfc);
     }

   SetCell(prefix+"STAT_INFO",x0,y0+rowH*(NLEV+1),
           (sigMode ? "Giris sinyali: " : "Bolge: ")+IntegerToString(pass)+"/"+IntegerToString(total)+(sigMode ? "  Girilen: " : "  Temasli: ")+IntegerToString(passTouched),
           clrDimGray);
  }

//+------------------------------------------------------------------+
//| V1.26 EKLEME: Excel butonu (filtre panelinin ustunde) ve            |
//| varsayilan filtre degerleri                                         |
//+------------------------------------------------------------------+
#define XLS_BTN_H 26    // Excel butonunun kapladigi yukseklik (panel bu kadar asagi iner)

void XlsBtn(string name,int x,int y,int w,string text)
  {
   if(ObjectFind(0,name)<0)
     {
      ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,clrDimGray);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrSeaGreen);
      ObjectSetInteger(0,name,OBJPROP_COLOR,clrWhite);
     }
   ObjectSetString(0,name,OBJPROP_TEXT,text);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,22);
  }

void DrawExcelButton()
  {
   int x  = TableX;
   int y  = TableY + (ShowStatsTable ? TBL_H+6 : 0);
   int bw = TBL_W/2 - 2;
   XlsBtn(prefix+"XLS_BTN", x,        y,bw,"Bolgeleri Kaydet (Excel)");
   XlsBtn(prefix+"XLS_BTN2",x+bw+4,   y,bw,"Tarih + Tablo Kaydet");
  }

//+------------------------------------------------------------------+
//| Baslangic (varsayilan) filtreleri: Genislik ATR min 0.3,           |
//| Tarih 02.01.2019 - 01.01.2020. OnInit'te ResetFilters'tan sonra     |
//| cagrilir. (Panelin 'Sifirla' dugmesi eskisi gibi hepsini temizler.) |
//+------------------------------------------------------------------+
void ApplyDefaultFilters()
  {
   fltOn[0]     = true;       // Genislik ATR
   fltHasMin[0] = true;
   fltMin[0]    = 0.3;

   datetime d;
   if(ParseDate("02.01.2019",d)) { fltDateHasS = true; fltDateS = d; }
   if(ParseDate("01.01.2020",d)) { fltDateHasE = true; fltDateE = d; }
   fltDateOn = (fltDateHasS || fltDateHasE);
   UpdateFilterActive();
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
//+------------------------------------------------------------------+
//| V1.29: [Bas|Bit] [< Gun][Gun >] [< Ay][Ay >] [< Yil][Yil >]        |
//| Dugme adi: R_DN_ + S/E + D/M/Y + P(geri)/N(ileri)                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| V1.44: Min/Max sardirma adimi. Sayi (tam) filtreleri 1, ATR        |
//| cinsinden olanlar 0.05 adimla gider.                               |
//+------------------------------------------------------------------+
double FltStep(const int i)
  {
   if(i==2 || i==3 || i==4 || i==5 || i==6 || i==11)   // BO, YP, BU, BD, BY, Acik FVG
      return(1.0);
   return(0.05);
  }

void DrawDateNavRow(const string fp,const int px,const int y,const string which,const string label)
  {
   FltLabel(fp+"R_DNL_"+which,px+8,y+4,label,clrDimGray);
   string un[3] = {"Gun","Ay","Yil"};
   string uc[3] = {"D","M","Y"};
   for(int u=0;u<3;u++)
     {
      int bx = px+40 + u*88;
      FltButton(fp+"R_DN_"+which+uc[u]+"P",bx,   y,42,"< "+un[u],false);
      FltButton(fp+"R_DN_"+which+uc[u]+"N",bx+44,y,42,un[u]+" >",false);
     }
  }

void DrawFilterPanel()
  {
   if(!ShowFilterPanel)
      return;

   string fp   = prefix + "FLT_";
   int    px   = TableX;
   DrawExcelButton();   // V1.26
   int    py   = TableY + (ShowStatsTable ? TBL_H+6 : 0) + XLS_BTN_H;
   int    step = 22;
   int    fullH = 30 + 16 + step*27 + 6;   // V1.29: +2 satir (tarih), V1.38: +1 satir (Acik FVG), V1.45: +1 satir (HTF)
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
   FltButton(fp+"H_OPT",px+216,py+5, 90,OptButtonText(),optRunning);   // V1.51

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

   // V1.45: ust zaman dilimi (HTF) bolge butonlari (acik olan, kendi talep rengiyle boyanir)
   for(int hh=0;hh<NHTF;hh++)
     {
      string hb = fp+"R_HTF_"+IntegerToString(hh);
      bool   ho = (htfOn[hh] && htfAvail[hh]);
      FltButton(hb,px+8+hh*50,y,46,htfName[hh],ho);
      if(ObjectFind(0,hb)>=0)
        {
         ObjectSetInteger(0,hb,OBJPROP_BGCOLOR,ho ? htfDemClr[hh] : clrGainsboro);
         ObjectSetInteger(0,hb,OBJPROP_COLOR,ho ? clrBlack : (htfAvail[hh] ? clrDimGray : clrSilver));
        }
     }
   y += step;

   // V1.47: ana grafik bolgeleri + giris modeli
   FltButton(fp+"R_M_ON",px+8,  y,100,"1dk bolge",   fltMain);
   FltButton(fp+"R_E_ON",px+112,y,100,"Giris modeli",entryOn);
   FltButton(fp+"R_E_CX",px+216,y, 90,"Iptal goster",entryCxl);
   y += step;
   FltButton(fp+"R_E_EN",px+8,  y, 70,"Engulf",    entryEng);
   FltButton(fp+"R_E_PI",px+82, y, 70,"Pinbar",    entryPin);
   FltButton(fp+"R_E_RR",px+156,y, 70,"Railroad",  entryRail);
   FltButton(fp+"R_E_KB",px+230,y, 76,"Kara Bulut",entryKb);
   y += step;

   for(int i=0;i<FLT_N;i++)
     {
      string id = IntegerToString(i);
      FltButton(fp+"R_L_"+id,  px+8,  y,100,fltName[i],fltOn[i]);
      // V1.44: [-] [min] [+]   [-] [max] [+]
      FltButton(fp+"R_VN_"+id+"_NM",px+112,y, 16,"-",false);
      FltEdit  (fp+"R_MIN_"+id,     px+130,y, 46,fltHasMin[i] ? FmtNum(fltMin[i]) : "",fltOn[i]);
      FltButton(fp+"R_VN_"+id+"_NP",px+178,y, 16,"+",false);
      FltButton(fp+"R_VN_"+id+"_XM",px+200,y, 16,"-",false);
      FltEdit  (fp+"R_MAX_"+id,     px+218,y, 46,fltHasMax[i] ? FmtNum(fltMax[i]) : "",fltOn[i]);
      FltButton(fp+"R_VN_"+id+"_XP",px+266,y, 16,"+",false);
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
   // V1.29: tarih ileri/geri sardirma butonlari (Bas = baslangic, Bit = bitis)
   DrawDateNavRow(fp,px,y,"S","Bas");
   y += step;
   DrawDateNavRow(fp,px,y,"E","Bit");
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
      ObjectDelete(0,ZObjName(z,"l3"));
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
   UpdateGroupLabel();
   if(zonesChanged || fltForce)
     {
      SyncObjects(true);
      HtfSync(true);          // V1.45
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
      else if(key=="H_OPT")   OptToggle();            // V1.51
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
      else if(key=="R_M_ON")  fltMain   = !fltMain;
      else if(key=="R_E_ON")
        {
         entryOn = !entryOn;
         if(entryOn)
            EntryUpdate();
        }
      else if(key=="R_E_CX")  entryCxl  = !entryCxl;
      else if(key=="R_E_EN")  { entryEng  = !entryEng;  EntryResetAll(); EntryUpdate(); }
      else if(key=="R_E_PI")  { entryPin  = !entryPin;  EntryResetAll(); EntryUpdate(); }
      else if(key=="R_E_RR")  { entryRail = !entryRail; EntryResetAll(); EntryUpdate(); }
      else if(key=="R_E_KB")  { entryKb   = !entryKb;   EntryResetAll(); EntryUpdate(); }
      else if(StringFind(key,"R_HTF_")==0)
        {
         // V1.45: HTF bolgelerini ac / kapa
         int hi2 = (int)StringToInteger(StringSubstr(key,6));
         if(hi2<0 || hi2>=NHTF || !htfAvail[hi2])
            return;
         HtfOnToggle(hi2);
         EntryUpdate();          // V1.47
        }
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
      else if(StringFind(key,"R_VN_")==0)
        {
         // V1.44: min/max sardirma: R_VN_ + indeks + _ + N/X (min/max) + M/P (eksi/arti)
         string rest = StringSubstr(key,5);
         int    us   = StringFind(rest,"_");
         if(us<=0 || StringLen(rest)!=us+3)
            return;
         int vi = (int)StringToInteger(StringSubstr(rest,0,us));
         if(vi<0 || vi>=FLT_N)
            return;
         bool   vMin = (StringGetCharacter(rest,us+1)=='N');
         int    vDir = (StringGetCharacter(rest,us+2)=='P') ? 1 : -1;
         bool   vHas = vMin ? fltHasMin[vi] : fltHasMax[vi];
         double vCur = vHas ? (vMin ? fltMin[vi] : fltMax[vi]) : 0.0;   // bos kutu: 0'dan basla
         double vNew = NormalizeDouble(vCur + vDir*FltStep(vi),2);
         if(vNew<0.0)
            vNew = 0.0;                                                // alt sinir 0
         if(vMin) { fltHasMin[vi] = true; fltMin[vi] = vNew; }
         else     { fltHasMax[vi] = true; fltMax[vi] = vNew; }
         fltOn[vi] = true;                                             // filtre otomatik acilir
        }
      else if(StringFind(key,"R_DN_")==0 && StringLen(key)==8)
        {
         // V1.29: tarih ileri/geri: R_DN_ + S/E + D/M/Y + P/N
         bool   isS  = (StringGetCharacter(key,5)=='S');
         ushort uch  = StringGetCharacter(key,6);
         int    unit = (uch=='D') ? 0 : (uch=='M' ? 1 : 2);
         int    dir  = (StringGetCharacter(key,7)=='P') ? -1 : 1;
         bool   has  = isS ? fltDateHasS : fltDateHasE;
         datetime cur = isS ? fltDateS : fltDateE;
         if(!has)
           {
            // bos kutu: diger tarihten, o da yoksa son bar gununden basla
            datetime other = isS ? fltDateE : fltDateS;
            bool     oHas  = isS ? fltDateHasE : fltDateHasS;
            datetime base  = oHas ? other : iTime(_Symbol,_Period,0);
            if(base<=0)
               base = TimeCurrent();
            cur = (datetime)((long)base - ((long)base % 86400));
           }
         datetime nd = ShiftDate(cur,unit,dir);
         if(isS) { fltDateHasS = true; fltDateS = nd; }
         else    { fltDateHasE = true; fltDateE = nd; }
         fltDateOn = true;
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
                     "BU"+sep+"BD"+sep+"BY"+sep+"V"+sep+"Ilk"+IntegerToString(gWinN)+"Mum_ATR"+sep+"FVG_Mum_ATR"+sep+"FVG1_Mum_ATR"+sep+"FVG2_Mum_ATR"+sep+"ARD"+sep+"AcikFVG"+"\r\n");

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
      line += sep + IntegerToString(z.openFvg);

      FileWriteString(h,line+"\r\n");
     }

   FileClose(h);
   string path = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"+fname;
   Print("SupplyDemand CSV yazildi (",total," bolge): ",path);
   Alert("CSV kaydedildi (",total," bolge): ",path);
  }

//+------------------------------------------------------------------+
//| V1.26 EKLEME: YALNIZCA filtreden gecen bolgeleri CSV'ye yaz        |
//| (Excel ile acilir). Sutunlar 'S' tusuyla yazilan CSV ile aynidir.   |
//+------------------------------------------------------------------+
void ExportFilteredCSV()
  {
   UpdateFilterActive();
   string sep = (StringLen(CsvSeparator)>0) ? CsvSeparator : ";";
   string tf  = EnumToString(_Period);
   StringReplace(tf,"PERIOD_","");
   string stamp = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
   StringReplace(stamp,".","");
   StringReplace(stamp,":","");
   StringReplace(stamp," ","_");
   string fname = "SDZ_FILTRE_"+_Symbol+"_"+tf+"_"+stamp+".csv";

   int h = FileOpen(fname,FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h==INVALID_HANDLE)
     {
      Alert("CSV acilamadi: ",fname," (hata ",GetLastError(),")");
      return;
     }

   FileWriteString(h,"Tip"+sep+"Bolge_Baslangic(1.mum)"+sep+"Bolge_Olusum(3.mum)"+sep+"Ilk_Temas"+sep+
                     "Ust"+sep+"Alt"+sep+"Genislik_ATR"+sep+"Uzaklasma_ATR"+sep+
                     "TP1"+sep+"TP2"+sep+"TP3"+sep+"TP4"+sep+"TP5"+sep+"TP6"+sep+"TP7"+sep+"TP8"+sep+"BO"+sep+"YP"+sep+"ORJ"+sep+"FFVGT"+sep+
                     "BU"+sep+"BD"+sep+"BY"+sep+"V"+sep+"Ilk"+IntegerToString(gWinN)+"Mum_ATR"+sep+"FVG_Mum_ATR"+sep+"FVG1_Mum_ATR"+sep+"FVG2_Mum_ATR"+sep+"ARD"+sep+"AcikFVG"+"\r\n");

   int total = ArraySize(zones);
   int saved = 0;
   for(int k=0;k<total;k++)
     {
      SDZoneInfo z;
      z = zones[k];
      if(!ZonePasses(z))
         continue;
      saved++;

      double width = (z.atr>0.0) ? (z.top-z.bottom)/z.atr : 0.0;
      double move  = z.isDemand ? MathMax(0.0,z.ext-z.top) : MathMax(0.0,z.bottom-z.ext);
      double mvAtr = (z.atr>0.0) ? move/z.atr : 0.0;
      if(!z.isDemand)
         mvAtr = -mvAtr;

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
      line += sep + IntegerToString(z.openFvg);

      FileWriteString(h,line+"\r\n");
     }

   FileClose(h);
   string path = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"+fname;
   Print("SupplyDemand FILTRELI CSV yazildi (",saved,"/",total," bolge): ",path);
   Alert("Filtre sonuclari kaydedildi (",saved," bolge): ",path);
  }

//+------------------------------------------------------------------+
//| V1.28: Ondalik ayraci varsayilan NOKTA. CsvDecimalComma=true ve      |
//| ayirac ';' ise ondalik ',' olur                                       |
//+------------------------------------------------------------------+
string CsvNum(double v,int digits,string sep)
  {
   string s = DoubleToString(v,digits);
   if(CsvDecimalComma && sep==";")
      StringReplace(s,".",",");
   return(s);
  }

//+------------------------------------------------------------------+
//| V1.27 EKLEME: Tarih bilgisi + sol ustteki tablo degerleri           |
//| (TP / SL / Net R / Ort R / Win% / Profit Factor) CSV'ye yazilir.    |
//| Bolge satiri YAZILMAZ; yalnizca ozet.                               |
//+------------------------------------------------------------------+
void ExportSummaryCSV()
  {
   UpdateFilterActive();
   string sep = (StringLen(CsvSeparator)>0) ? CsvSeparator : ";";
   string tf  = EnumToString(_Period);
   StringReplace(tf,"PERIOD_","");
   string stamp = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
   StringReplace(stamp,".","");
   StringReplace(stamp,":","");
   StringReplace(stamp," ","_");
   string fname = "SDZ_OZET_"+_Symbol+"_"+tf+"_"+stamp+".csv";

   int tp[NLEV], sl[NLEV];
   ArrayInitialize(tp,0);
   ArrayInitialize(sl,0);
   int total = ArraySize(zones);
   int pass = 0, passTouched = 0;
   datetime firstT = 0, lastT = 0;
   for(int k=0;k<total;k++)
     {
      if(!ZonePasses(zones[k]))
         continue;
      pass++;
      if(zones[k].touchIdx>=0)
         passTouched++;
      datetime tt = zones[k].timeForm;
      if(firstT==0 || tt<firstT) firstT = tt;
      if(tt>lastT)               lastT  = tt;
      for(int q=0;q<NLEV;q++)
        {
         if(zones[k].out[q]==1)
            tp[q]++;
         else if(zones[k].out[q]==2)
            sl[q]++;
        }
     }

   int h = FileOpen(fname,FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(h==INVALID_HANDLE)
     {
      Alert("CSV acilamadi: ",fname," (hata ",GetLastError(),")");
      return;
     }

   string dS = (fltDateOn && fltDateHasS) ? FmtDate(fltDateS) : "sinirsiz";
   string dE = (fltDateOn && fltDateHasE) ? FmtDate(fltDateE) : "sinirsiz";
   string rf = (fltTimeRef==0) ? "Olusum (3.mum)" : (fltTimeRef==1 ? "Baslangic (1.mum)" : "Ilk temas");

   FileWriteString(h,"Sembol"+sep+_Symbol+"\r\n");
   FileWriteString(h,"Zaman_Dilimi"+sep+tf+"\r\n");
   FileWriteString(h,"Filtre_Tarih_Baslangic"+sep+dS+"\r\n");
   FileWriteString(h,"Filtre_Tarih_Bitis"+sep+dE+"\r\n");
   FileWriteString(h,"Tarih_Referansi"+sep+rf+"\r\n");
   FileWriteString(h,"Ilk_Bolge_Olusum"+sep+CsvTime(firstT)+"\r\n");
   FileWriteString(h,"Son_Bolge_Olusum"+sep+CsvTime(lastT)+"\r\n");
   FileWriteString(h,"Bolge_Gecen"+sep+IntegerToString(pass)+"\r\n");
   FileWriteString(h,"Bolge_Toplam"+sep+IntegerToString(total)+"\r\n");
   FileWriteString(h,"Temasli"+sep+IntegerToString(passTouched)+"\r\n");
   FileWriteString(h,"Kayit_Zamani"+sep+TimeToString(TimeLocal(),TIME_DATE|TIME_MINUTES)+"\r\n");
   FileWriteString(h,"\r\n");
   FileWriteString(h,"Seviye"+sep+"TP"+sep+"SL"+sep+"Net_R"+sep+"Ort_R"+sep+"Win_%"+sep+"Profit_Factor"+"\r\n");

   for(int q2=0;q2<NLEV;q2++)
     {
      int    lv   = q2+1;
      int    netR = tp[q2]*lv - sl[q2];
      int    nTr  = tp[q2] + sl[q2];
      string avg  = (nTr>0) ? CsvNum((double)netR/nTr,2,sep) : "";
      string wr   = (nTr>0) ? CsvNum(100.0*tp[q2]/nTr,1,sep) : "";
      string pf   = "";
      if(sl[q2]>0)
         pf = CsvNum((double)tp[q2]*lv/sl[q2],2,sep);
      else if(tp[q2]>0)
         pf = "inf";
      FileWriteString(h,IntegerToString(lv)+sep+IntegerToString(tp[q2])+sep+IntegerToString(sl[q2])+sep+
                        IntegerToString(netR)+sep+avg+sep+wr+sep+pf+"\r\n");
     }

   FileClose(h);
   string path = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\"+fname;
   Print("SupplyDemand OZET CSV yazildi (",pass,"/",total," bolge): ",path);
   Alert("Tarih + tablo ozeti kaydedildi: ",path);
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
   ApplyDefaultFilters();   // V1.26
   fltCollapsed = false;
   //--- Adaptive Moving Average
   SetIndexBuffer(0,AMABuf,INDICATOR_DATA);
   ArraySetAsSeries(AMABuf,false);
   PlotIndexSetInteger(0,PLOT_DRAW_TYPE,ShowAMA ? DRAW_LINE : DRAW_NONE);
   PlotIndexSetInteger(0,PLOT_LINE_COLOR,AMAColor);
   PlotIndexSetInteger(0,PLOT_LINE_WIDTH,MathMax(1,AMAWidth));
   PlotIndexSetInteger(0,PLOT_DRAW_BEGIN,MathMax(1,AMAPeriod));
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetString(0,PLOT_LABEL,"AMA("+IntegerToString(AMAPeriod)+","+IntegerToString(AMAFastEMA)+","+IntegerToString(AMASlowEMA)+")");
   atrHandle = iATR(_Symbol,_Period,ATRPeriod);
   if(atrHandle==INVALID_HANDLE)
      return(INIT_FAILED);
   HtfInit();               // V1.45
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   OptShutdown();           // V1.51
   HtfDeinit();             // V1.45
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

   // V1.41: 'A' tusu -> bir sonraki yazi sayfasi (dongu)
   if(id==CHARTEVENT_KEYDOWN && lparam=='A')
     {
      gLabelPage = (gLabelPage+1) % MaxLabelPages();
      for(int k=0;k<ArraySize(zones);k++)
         zones[k].dirty = true;       // gorunen bolgelerin yazisi yeniden cizilsin
      SyncObjects(true);
      HtfMarkAllDirty();           // V1.45
      HtfSync(true);
      UpdateGroupLabel();
      ChartRedraw();
     }

   // V1.26: Excel butonu (yalnizca filtreden gecenleri kaydeder)
   if(id==CHARTEVENT_OBJECT_CLICK && sparam==prefix+"XLS_BTN")
     {
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      ExportFilteredCSV();
      ChartRedraw();
     }
   // V1.27: Tarih + tablo ozeti butonu
   if(id==CHARTEVENT_OBJECT_CLICK && sparam==prefix+"XLS_BTN2")
     {
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      ExportSummaryCSV();
      ChartRedraw();
     }

   // V1.20: kaydirma / zoom / boyut degisince nesne penceresini senkronla
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      bool sA = SyncObjects(false);
      bool sB = HtfSync(false);   // V1.45
      if(sA || sB)
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
//| V1.35: ARD penceresi (bar index'leri). SeqIncludeC2=true: 2. mum    |
//| (fvgIdx-1) ilk mum; false: FVG mumundan sonraki mum (fvgIdx+1).     |
//| Pencere SeqCandles mum uzunlugundadir.                             |
//+------------------------------------------------------------------+
int SeqFirstIdx(const SDZoneInfo &z)
  {
   return(SeqIncludeC2 ? z.fvgIdx-1 : z.fvgIdx+1);
  }

int SeqLastIdx(const SDZoneInfo &z)
  {
   return(SeqFirstIdx(z) + MathMax(1,SeqCandles) - 1);
  }

//+------------------------------------------------------------------+
//| V1.25: kapanmis mumlara gore (lastClosed'a kadar) mum ATR           |
//| degerlerini ve ARD'yi hesapla. Donus: bir sey degistiyse true.     |
//|  mum 0 = FVG mumu (fvgIdx), 1 = sonraki, 2 = onu izleyen.          |
//|  Mod 0: (high-low)/ATR | Mod 1: bolge kenarindan uzaklasma/ATR.     |
//|  ARD (V1.34): fvgIdx'ten sonraki SeqCandles mum ust uste ayni renk:|
//|  talepte hepsi yukselen (kapanis>acilis), arzda hepsi dusen.       |
//+------------------------------------------------------------------+
bool UpdateCandleInfo(SDZoneInfo &z,const double &open[],const double &high[],const double &low[],
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
      int sn      = MathMax(1,SeqCandles);
      int seqFrom = SeqFirstIdx(z);
      int seqTo   = SeqLastIdx(z);
      if(seqFrom>=0 && seqTo <= lastClosed)
        {
         // V1.28: SIZINTI KORUMASI - ilk temas ARD penceresinin icinde (veya
         // sonunda) olduysa, temas aninda tum kapanislar bilinemezdi -> ARD yok.
         bool ok = !(z.touchIdx>=0 && z.touchIdx<=seqTo);
         // V1.34/V1.35: penceredeki sn mumun HEPSI ayni renkte olmali
         //  talep: yukselen mum (kapanis > acilis) | arz: dusen mum (kapanis < acilis)
         for(int q=0;q<sn && ok;q++)
           {
            double o = open[seqFrom+q];
            double c = close[seqFrom+q];
            if(z.isDemand ? !(c > o) : !(c < o))
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
//| V1.45: UST ZAMAN DILIMI (HTF) BOLGELERI                           |
//| Her HTF icin bir motor (CHtfEngine). Motor, ana grafikteki        |
//| OnCalculate dongusunun AYNISINI (tespit, temas, TP/SL, ARD, AF..) |
//| o zaman diliminin mumlari uzerinde calistirir. Mantik degismedi.  |
//+------------------------------------------------------------------+

//--- WasSecondCandleOfZone / IsOriginalZone'un verilen bolge dizisi ile calisan esleri
bool WasSecondCandleOfZoneIn(const SDZoneInfo &zs[],int idx,bool wantDemand)
  {
   for(int m=ArraySize(zs)-1; m>=0; m--)
     {
      if(zs[m].baseIdx < idx-1)
         break;
      if(zs[m].baseIdx == idx-1 && zs[m].isDemand==wantDemand)
         return(true);
     }
   return(false);
  }

bool IsOriginalZoneIn(const SDZoneInfo &zs[],const double &high[],const double &low[],int newC1,bool isDemand,
                      double top,double bottom,int lookback)
  {
   for(int m=ArraySize(zs)-1; m>=0; m--)
     {
      if(zs[m].baseIdx < newC1-lookback)
         break;
      if(zs[m].baseIdx >= newC1 || zs[m].isDemand!=isDemand)
         continue;

      double aLow  = isDemand ? zs[m].bottom : zs[m].fvgFar;
      double aHigh = isDemand ? zs[m].fvgFar : zs[m].top;
      if(aLow > aHigh) { double t=aLow; aLow=aHigh; aHigh=t; }

      if(top >= aLow && bottom <= aHigh)
         return(false); // NORJ
     }
   return(true); // ORJ
  }

//+------------------------------------------------------------------+
//| V1.47: giris sinyali nesnelerini sil                               |
//+------------------------------------------------------------------+
void DeleteSignalObjects(const SDZoneInfo &z)
  {
   ObjectDelete(0,ZObjName(z,""));
   ObjectDelete(0,ZObjName(z,"lb"));
   ObjectDelete(0,ZObjName(z,"L0"));
   ObjectDelete(0,ZObjName(z,"T0"));
   ObjectDelete(0,ZObjName(z,"L9"));
   ObjectDelete(0,ZObjName(z,"T9"));
   for(int n=1;n<=NLEV;n++)
     {
      ObjectDelete(0,ZObjName(z,"L"+IntegerToString(n)));
      ObjectDelete(0,ZObjName(z,"T"+IntegerToString(n)));
     }
  }

//--- Bir HTF'ye ait tum sinyalleri sil (HTF yeniden kuruldugunda)
void EntryClearSlot(const int slot)
  {
   int n = ArraySize(sigs);
   for(int k=0;k<n;k++)
     {
      if(sigs[k].sigSlot!=slot || sigs[k].sigState==3)
         continue;
      if(sigs[k].hasObj)
         DeleteSignalObjects(sigs[k]);
      sigs[k].hasObj    = false;
      sigs[k].sigState  = 3;
      sigs[k].trackDone = true;
     }
  }

//+------------------------------------------------------------------+
class CHtfEngine
  {
public:
   ENUM_TIMEFRAMES tf;
   int        slot;
   int        tfSec;
   int        atrH;
   bool       built;        // HTF mum dizileri kuruldu mu
   bool       ready;        // son Update tam calisti mi (veri + ATR hazir)
   bool       anyObj;       // grafikte bu HTF'ye ait nesne olabilir mi
   int        total;        // HTF mum sayisi (index 0 = en eski)
   int        lastScanned;
   int        atrBase;
   datetime   tm[];
   double     op[];
   double     hi[];
   double     lo[];
   double     cl[];
   double     atrBuf[];
   SDZoneInfo zones[];
   int        active[];
   int        sgScan[];     // V1.47: her HTF bolgesi icin ana grafikte taranan son bar (-1 = baslamadi)
   int        sgT0[];       // V1.47: ana grafikte ilk temas bari (-1 = yok)
   int        sgFlag[];     // V1.47: bit0 = fiyat bolgeden uzaklasti, bit1 = bitti (sinyal bulundu / gecersiz)
   int        sgFrom;       // V1.47: bunun altindaki tum bolgeler bitmis

              CHtfEngine(void)
     {
      tf          = PERIOD_CURRENT;
      slot        = 0;
      tfSec       = 0;
      atrH        = INVALID_HANDLE;
      built       = false;
      ready       = false;
      anyObj      = false;
      total       = 0;
      lastScanned = -1;
      atrBase     = 0;
      sgFrom      = 0;
     }

             ~CHtfEngine(void)
     {
      if(atrH!=INVALID_HANDLE)
         IndicatorRelease(atrH);
      atrH = INVALID_HANDLE;
     }

   bool      Init(const int s,const ENUM_TIMEFRAMES t)
     {
      slot  = s;
      tf    = t;
      tfSec = PeriodSeconds(t);
      atrH  = iATR(_Symbol,t,ATRPeriod);
      return(atrH!=INVALID_HANDLE);
     }

   //--- bu motorun grafikteki tum nesnelerini sil (veri kalir)
   void      DeleteAllObjects()
     {
      int nz = ArraySize(zones);
      for(int k=0;k<nz;k++)
         if(zones[k].hasObj)
           {
            DeleteZoneObjects(zones[k]);
            zones[k].hasObj = false;
           }
      anyObj = false;
     }

   //--- HTF mumlarini yukle: ilk seferde hepsi, sonra yalnizca son mum + yeniler.
   //    false = veri henuz hazir degil (sonra tekrar denenir)
   bool      LoadData(bool &rebuilt)
     {
      rebuilt = false;
      int bars = iBars(_Symbol,tf);
      if(bars<10)
         return(false);
      MqlRates r[];
      ArraySetAsSeries(r,false);

      if(!built)
        {
         int cnt = (HtfMaxBars>0) ? MathMin(bars,HtfMaxBars) : bars;
         int got = CopyRates(_Symbol,tf,0,cnt,r);
         if(got<10)
            return(false);
         DeleteAllObjects();
         EntryClearSlot(slot);       // V1.47: bu HTF yeniden kuruluyor -> sinyalleri sil
         ArrayResize(sgScan,0);
         ArrayResize(sgT0,0);
         ArrayResize(sgFlag,0);
         sgFrom = 0;
         ArrayResize(zones,0);
         ArrayResize(active,0);
         ArrayResize(tm,got,4096);
         ArrayResize(op,got,4096);
         ArrayResize(hi,got,4096);
         ArrayResize(lo,got,4096);
         ArrayResize(cl,got,4096);
         for(int q=0;q<got;q++)
           {
            tm[q] = r[q].time;
            op[q] = r[q].open;
            hi[q] = r[q].high;
            lo[q] = r[q].low;
            cl[q] = r[q].close;
           }
         total       = got;
         lastScanned = 3;          // firstBar (4) - 1
         atrBase     = 0;
         built       = true;
         rebuilt     = true;
         return(true);
        }

      datetime tNew = iTime(_Symbol,tf,0);
      if(tNew<=0 || total<1)
         return(false);
      int got2 = CopyRates(_Symbol,tf,tm[total-1],tNew,r);
      if(got2<1)
         return(true);                       // yeni bir sey yok
      if(r[0].time!=tm[total-1])
        {
         built = false;                      // seri tutarsiz -> sonraki turda bastan kur
         return(false);
        }
      int newTotal = total-1+got2;
      if(newTotal>total)
        {
         ArrayResize(tm,newTotal,4096);
         ArrayResize(op,newTotal,4096);
         ArrayResize(hi,newTotal,4096);
         ArrayResize(lo,newTotal,4096);
         ArrayResize(cl,newTotal,4096);
        }
      for(int q2=0;q2<got2;q2++)
        {
         int idx = total-1+q2;
         tm[idx] = r[q2].time;
         op[idx] = r[q2].open;
         hi[idx] = r[q2].high;
         lo[idx] = r[q2].low;
         cl[idx] = r[q2].close;
        }
      bool grew = (newTotal!=total);
      total = newTotal;
      if(grew)
        {
         int expect = iBarShift(_Symbol,tf,tm[0],true)+1;
         if(expect!=total)
            built = false;                   // eksik / tutarsiz mum -> sonraki turda bastan kur
        }
      return(true);
     }

   //--- OnCalculate'in bolge tespiti + takip dongusu (HTF mumlari uzerinde). true = degisiklik var
   bool      Update()
     {
      ready = false;
      bool rebuilt = false;
      if(!LoadData(rebuilt))
         return(false);
      bool changed = rebuilt;
      int  rates_total = total;
      if(rates_total<3)
         return(changed);
      if(BarsCalculated(atrH)<rates_total)
         return(changed);

      int firstBar = 4;
      int lastBar  = WaitForCandleClose ? rates_total-2 : rates_total-1;
      if(lastBar<firstBar)
         return(changed);

      //--- ATR: yalnizca yeni taranacak barlar
      if(lastBar>lastScanned)
        {
         int atrFrom = lastScanned+1;
         int cnt     = rates_total-atrFrom;
         ArraySetAsSeries(atrBuf,false);
         if(CopyBuffer(atrH,0,0,cnt,atrBuf)<cnt)
            return(changed);
         atrBase = atrFrom;
        }

      //--- Yeni bolgeleri tespit et (her bar yalnizca bir kez islenir)
      for(int i=lastScanned+1;i<=lastBar;i++)
        {
         int c1 = i-2; // 1. mum
         int c2 = i-1; // 2. mum (FVG mumu)
         int c3 = i;   // 3. mum (dogrulayan mum)

         //--- Yukselis FVG -> Talep bolgesi
         if(ShowDemandZones && lo[c3]>hi[c1])
           {
            double zTop    = hi[c1];  // 1. mumun tepesi (her zaman)
            double zBottom = lo[c1];   // varsayilan: 1. mumun dibi

            // 1. mum kendisi ayri bir FVG'nin tamamlayici (3.) mumu MU,
            // VE 2. mum da kendisi ayri bir FVG'nin tamamlayici (3.) mumu MU?
            bool c1IsFVG = IsFVG(hi,lo,c1-2,c1,true);
            bool c2IsFVG = IsFVG(hi,lo,c1-1,c2,true);

            // YENI: su anki 1.mum, daha once olusmus bir TALEP bolgesinin
            // 2.mumu (displacement mumu) muydu?
            bool c1WasSecondOfDemand = WasSecondCandleOfZoneIn(zones,c1,true);

            if((c1IsFVG && c2IsFVG) || c1WasSecondOfDemand)
              {
               // Ozel durum: bolge = 1.mum tepesi ile 2.mum dibi arasi (kosulsuz)
               zBottom = lo[c2];
              }
            else
              {
               // Genel/eski kural: sadece 2.mum daha asagi dip yaptiysa oraya tasi
               if(lo[c2] < zBottom)
                  zBottom = lo[c2];
              }

            // V1.43: ust siniri FVG boslugunun ZoneFvgPct noktasina cek
            // (bosluk: 0 = 1. mum tepesi, 100 = 3. mum dibi)
            zTop = NormalizeDouble(zTop + FvgPctClamp()*(lo[c3]-hi[c1]),_Digits);

            SDZoneInfo z;
            z.baseIdx     = c1;
            z.fvgIdx      = c3;
            z.timeC1      = tm[c1];
            z.timeForm    = tm[c3];
            z.timeTouch   = 0;
            z.isDemand    = true;
            z.top         = zTop;
            z.bottom      = zBottom;
            z.touched     = false;
            z.lastChecked = c2;
            z.endIdx      = c3;
            z.timeEnd     = tm[c3];
            z.hasObj      = false;
            z.dirty       = true;
            z.tfSec       = tfSec;      // V1.45: HTF bolgesi
            z.atr         = atrBuf[c3-atrBase];
            z.fvgFar      = lo[c3];
            z.ext         = z.top;
            z.extN        = z.top;
            InitOutcome(z);
            z.bo          = CountBO(hi,lo,c1,z.top,z.bottom);
            z.yp          = CountYP(hi,lo,c1-1,YPLookback,z.top,z.bottom);
            z.orj         = IsOriginalZoneIn(zones,hi,lo,c1,z.isDemand,z.top,z.bottom,ORJLookback);
            z.swLevel     = FindSwingLevel(hi,lo,c1,z.isDemand,z.top,z.bottom,SwingStrength,SwingLookback);
            InitCandleInfo(z);
            z.openFvg     = CountOpenFVG(hi,lo,z.fvgIdx,OpenFvgLookback,z.isDemand,z.top,z.bottom);   // V1.38: bir kez
            UpdateCandleInfo(z,op,hi,lo,cl,rates_total-2);

            int n = ArraySize(zones);
            ArrayResize(zones,n+1,4096);
            zones[n] = z;
            int na = ArraySize(active);
            ArrayResize(active,na+1,4096);
            active[na] = n;
            changed = true;
           }

         //--- Dusus FVG -> Arz bolgesi
         if(ShowSupplyZones && hi[c3]<lo[c1])
           {
            double zBottom = lo[c1];   // 1. mumun dibi (her zaman)
            double zTop    = hi[c1];  // varsayilan: 1. mumun tepesi

            bool c1IsFVG = IsFVG(hi,lo,c1-2,c1,false);
            bool c2IsFVG = IsFVG(hi,lo,c1-1,c2,false);

            // YENI: su anki 1.mum, daha once olusmus bir ARZ bolgesinin
            // 2.mumu (displacement mumu) muydu?
            bool c1WasSecondOfSupply = WasSecondCandleOfZoneIn(zones,c1,false);

            if((c1IsFVG && c2IsFVG) || c1WasSecondOfSupply)
              {
               // Ozel durum: bolge = 1.mum dibi ile 2.mum tepesi arasi (kosulsuz)
               zTop = hi[c2];
              }
            else
              {
               // Genel/eski kural: sadece 2.mum daha yuksek tepe yaptiysa oraya tasi
               if(hi[c2] > zTop)
                  zTop = hi[c2];
              }

            // V1.43: alt siniri FVG boslugunun ZoneFvgPct noktasina cek
            // (bosluk: 0 = 1. mum dibi, 100 = 3. mum tepesi)
            zBottom = NormalizeDouble(zBottom - FvgPctClamp()*(lo[c1]-hi[c3]),_Digits);

            SDZoneInfo z;
            z.baseIdx     = c1;
            z.fvgIdx      = c3;
            z.timeC1      = tm[c1];
            z.timeForm    = tm[c3];
            z.timeTouch   = 0;
            z.isDemand    = false;
            z.top         = zTop;
            z.bottom      = zBottom;
            z.touched     = false;
            z.lastChecked = c2;
            z.endIdx      = c3;
            z.timeEnd     = tm[c3];
            z.hasObj      = false;
            z.dirty       = true;
            z.tfSec       = tfSec;      // V1.45: HTF bolgesi
            z.atr         = atrBuf[c3-atrBase];
            z.fvgFar      = hi[c3];
            z.ext         = z.bottom;
            z.extN        = z.bottom;
            InitOutcome(z);
            z.bo          = CountBO(hi,lo,c1,z.top,z.bottom);
            z.yp          = CountYP(hi,lo,c1-1,YPLookback,z.top,z.bottom);
            z.orj         = IsOriginalZoneIn(zones,hi,lo,c1,z.isDemand,z.top,z.bottom,ORJLookback);
            z.swLevel     = FindSwingLevel(hi,lo,c1,z.isDemand,z.top,z.bottom,SwingStrength,SwingLookback);
            InitCandleInfo(z);
            z.openFvg     = CountOpenFVG(hi,lo,z.fvgIdx,OpenFvgLookback,z.isDemand,z.top,z.bottom);   // V1.38: bir kez
            UpdateCandleInfo(z,op,hi,lo,cl,rates_total-2);

            int n = ArraySize(zones);
            ArrayResize(zones,n+1,4096);
            zones[n] = z;
            int na = ArraySize(active);
            ArrayResize(active,na+1,4096);
            active[na] = n;
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
         if(UpdateCandleInfo(zones[m],op,hi,lo,cl,rates_total-2))
           {
            zones[m].dirty = true;
            changed = true;
           }
        }

      //--- Aktif bolgeleri (temas bekleyen / TP-SL takibi suren) isle.
      //    Biten bolgeler listeden cikarilir; her tickte tum zones[] taranmaz.
      int nActive = ArraySize(active);
      int keep    = 0;
      for(int a=0;a<nActive;a++)
        {
         int k = active[a];

         if(zones[k].touched)
           {
            // temas edilmis bolgenin TP/SL sonucunu kapanmis mumlarla takip et
            if(!zones[k].trackDone && UpdateOutcome(zones[k],hi,lo,cl,rates_total-2))
              {
               zones[k].dirty = true;   // yazi (tp/sl) degisti
               changed = true;
              }
            if(!zones[k].trackDone)
               active[keep++] = k;
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
               if(lo[j] <= zones[k].top)
                 {
                  hit = true;
                  hitIndex = j;
                  break;
                 }
               // temas olmayan barlarda ulasilan en yuksek seviyeyi takip et
               if(hi[j] > zones[k].ext)
                 {
                  zones[k].ext    = hi[j];
                  zones[k].extIdx = j;   // BU: en uzak noktaya ulasilan bar
                 }
               // V1.22: yalnizca FVG mumu (fvgIdx) dahil ilk N mum icindeki en yuksek seviye
               if(j<=zones[k].fvgIdx+gWinN-1 && hi[j] > zones[k].extN)
                  zones[k].extN = hi[j];
               // FFVGT: ilk temastan once FVG'ye girip (lo < FVG ust) ustunde kapanis
               if(!zones[k].ffvgt && j<=rates_total-2 && j>zones[k].fvgIdx &&
                  lo[j] < zones[k].fvgFar && cl[j] > zones[k].fvgFar)
                  zones[k].ffvgt = true;
               // V: onceki swing hi, bolge olustuktan sonra (ilk temastan once) kapanisla kirildi mi
               if(!zones[k].vbrk && zones[k].swLevel>0.0 && j<=rates_total-2 && cl[j] > zones[k].swLevel)
                  zones[k].vbrk = true;
              }
            else
              {
               if(hi[j] >= zones[k].bottom)
                 {
                  hit = true;
                  hitIndex = j;
                  break;
                 }
               // temas olmayan barlarda ulasilan en dusuk seviyeyi takip et
               if(lo[j] < zones[k].ext)
                 {
                  zones[k].ext    = lo[j];
                  zones[k].extIdx = j;   // BU: en uzak noktaya ulasilan bar
                 }
               // V1.22: yalnizca FVG mumu (fvgIdx) dahil ilk N mum icindeki en dusuk seviye
               if(j<=zones[k].fvgIdx+gWinN-1 && lo[j] < zones[k].extN)
                  zones[k].extN = lo[j];
               // FFVGT: ilk temastan once FVG'ye girip (hi > FVG alt) altinda kapanis
               if(!zones[k].ffvgt && j<=rates_total-2 && j>zones[k].fvgIdx &&
                  hi[j] > zones[k].fvgFar && cl[j] < zones[k].fvgFar)
                  zones[k].ffvgt = true;
               // V: onceki swing lo, bolge olustuktan sonra (ilk temastan once) kapanisla kirildi mi
               if(!zones[k].vbrk && zones[k].swLevel>0.0 && j<=rates_total-2 && cl[j] < zones[k].swLevel)
                  zones[k].vbrk = true;
              }
           }

         if(hit)
           {
            zones[k].touched     = true;
            zones[k].lastChecked = hitIndex;
            zones[k].touchIdx    = hitIndex;      // sonuc takibi bu bardan baslar
            // V1.28: temas ARD penceresi bitmeden olduysa ARD sizinti olur -> iptal
            if(hitIndex <= SeqLastIdx(zones[k]))
               zones[k].seq = false;
            zones[k].timeTouch   = tm[hitIndex];
            zones[k].outLast     = hitIndex-1;
            UpdateOutcome(zones[k],hi,lo,cl,rates_total-2);
            zones[k].endIdx      = hitIndex;
            zones[k].timeEnd     = tm[hitIndex];
            zones[k].dirty       = true;
            changed = true;
            if(!zones[k].trackDone)
               active[keep++] = k;           // TP/SL takibi suruyor
           }
         else if(lastBar>=expiryIdx)
           {
            // Bolge yasini doldurdu, temas olmadi -> expiryIdx'te biter, bir daha cizilmez
            zones[k].touched     = true; // dongude tekrar islenmesin
            zones[k].trackDone   = true; // temas olmadi -> TP/SL takibi yok
            zones[k].lastChecked = expiryIdx;
            zones[k].endIdx      = expiryIdx;
            zones[k].timeEnd     = tm[expiryIdx];
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
               zones[k].timeEnd = tm[lastBar];
               zones[k].dirty   = true;
               changed = true;
              }
            active[keep++] = k;
           }
        }
      ArrayResize(active,keep);

      ready = true;
      return(changed);
     }
  };

CHtfEngine *g_htf[NHTF];

//--- V1.50: sinyali ureten HTF bolgesini ver (motor yeniden kurulduysa / yoksa false)
bool SigParentGet(const SDZoneInfo &z,SDZoneInfo &p)
  {
   int sl = z.sigSlot;
   if(sl<0 || sl>=NHTF || g_htf[sl]==NULL)
      return(false);
   if(z.sigZone<0 || z.sigZone>=ArraySize(g_htf[sl].zones))
      return(false);
   p = g_htf[sl].zones[z.sigZone];
   return(true);
  }

//+------------------------------------------------------------------+
//| V1.47: GIRIS MODELI                                               |
//+------------------------------------------------------------------+

//--- ana grafik aynasini guncelle (OnCalculate'in dizilerinden)
void MirrorUpdate(const int prev,const int total,const datetime &t[],const double &o[],
                  const double &h[],const double &l[],const double &c[])
  {
   int from = 0;
   if(prev>0 && mN>0 && prev<=mN && total>=prev)
      from = prev-1;                       // son (olusan) mumu da yeniden kopyala
   ArrayResize(mT,total,16384);
   ArrayResize(mO,total,16384);
   ArrayResize(mH,total,16384);
   ArrayResize(mL,total,16384);
   ArrayResize(mC,total,16384);
   int cnt = total-from;
   if(cnt>0)
     {
      ArrayCopy(mT,t,from,from,cnt);
      ArrayCopy(mO,o,from,from,cnt);
      ArrayCopy(mH,h,from,from,cnt);
      ArrayCopy(mL,l,from,from,cnt);
      ArrayCopy(mC,c,from,from,cnt);
     }
   mN = total;
  }

//--- zamani >= t olan ilk ana grafik bari (yoksa mN)
int EntryLowerBound(const datetime t)
  {
   int l = 0, r = mN-1, res = mN;
   while(l<=r)
     {
      int mid = (l+r)/2;
      if(mT[mid]>=t)
        { res = mid; r = mid-1; }
      else
         l = mid+1;
     }
   return(res);
  }

//+------------------------------------------------------------------+
//| j. mumda biten formasyonu ara. dem=true: talep bolgesi (yukselis    |
//| formasyonlari), false: arz (dusus). Donus 0 yok, 1 ENG, 2 PIN, 3 RR |
//| zb/zt = giris bolgesi, firstIdx = formasyonun ilk mumu              |
//+------------------------------------------------------------------+
int EntryPattern(const int j,const bool dem,double &zb,double &zt,int &firstIdx)
  {
   int p = j-1;
   if(p<0)
      return(0);
   double oj = mO[j], hj = mH[j], lj = mL[j], cj = mC[j];
   double op = mO[p], hp = mH[p], lp = mL[p], cp = mC[p];
   double rj = hj-lj, rp = hp-lp;
   double bj = MathAbs(cj-oj), bp = MathAbs(cp-op);
   double tol = MathMax(0,RailTolPct)/100.0;
   // yon: talepte onceki mum dusus, son mum yukselis (arzda tersi)
   bool dirOk = dem ? (cj>oj && cp<op) : (cj<oj && cp>op);

   //--- railroad track: iki ters, benzer boyda, birbirini kapatan govde
   if(entryRail && dirOk && rj>0.0 && rp>0.0 &&
      bj>=RailBodyPct/100.0*rj && bp>=RailBodyPct/100.0*rp)
     {
      double bmax = MathMax(bj,bp), bmin = MathMin(bj,bp);
      if(bmin>=(1.0-tol)*bmax && MathAbs(cj-op)<=tol*bp && MathAbs(oj-cp)<=tol*bp)
        {
         zb = MathMin(lj,lp);
         zt = MathMax(hj,hp);
         firstIdx = p;
         return(3);
        }
     }

   //--- engulf: son mumun govdesi onceki mumun govdesini tamamen yutar
   if(entryEng && dirOk && bj>bp)
     {
      bool eng = dem ? (oj<=cp && cj>=op) : (oj>=cp && cj<=op);
      if(eng)
        {
         zb = MathMin(oj,cj);
         zt = MathMax(oj,cj);
         firstIdx = p;
         return(1);
        }
     }

   //--- Kara Bulut: 1. mum guclu govdeli, 2. mum onun kapanisi civarinda/otesinde acilip govdesinin
   //    yarisinin otesinde kapanir (tamamen yutarsa ENG sayilir -> yukarida yakalanir)
   if(entryKb && dirOk && rp>0.0 && bp>=KbBodyPct/100.0*rp)
     {
      double ktol = MathMax(0,KbOpenTolPct)/100.0*bp;
      double mid  = (op+cp)/2.0;
      bool   kb   = dem ? (oj<=cp+ktol && cj>mid) : (oj>=cp-ktol && cj<mid);
      if(kb)
        {
         zb = MathMin(lj,lp);
         zt = MathMax(hj,hp);
         firstIdx = p;
         return(4);
        }
     }

   //--- pinbar: bolgeye dogru uzun fitil, karsi fitil kisa
   if(entryPin && rj>0.0)
     {
      double up = hj-MathMax(oj,cj);
      double dn = MathMin(oj,cj)-lj;
      double w  = PinWickPct/100.0*rj;
      double o2 = PinOppWickPct/100.0*rj;
      bool   pin = dem ? (dn>=w && up<=o2) : (up>=w && dn<=o2);
      if(pin)
        {
         zb = lj;
         zt = hj;
         firstIdx = j;
         return(2);
        }
     }
   return(0);
  }

//--- sinyal olustur (SDZoneInfo; sonuc takibi mevcut UpdateOutcome ile)
bool EntryAddSignal(const int slot,const int type,const bool dem,const double zb,const double zt,
                    const int firstIdx,const int j,const int zoneIdx)
  {
   if(zt-zb<=_Point)
      return(false);
   SDZoneInfo q;
   q.baseIdx     = firstIdx;
   q.fvgIdx      = j;
   q.isDemand    = dem;
   q.top         = zt;
   q.bottom      = zb;
   q.touched     = false;
   q.lastChecked = j;
   q.endIdx      = j;
   q.timeEnd     = mT[j];
   q.hasObj      = false;
   q.dirty       = true;
   q.atr         = 0.0;
   double ab[1];
   if(CopyBuffer(atrHandle,0,mN-1-j,1,ab)==1)
      q.atr = ab[0];
   q.ext         = dem ? zt : zb;
   q.extN        = q.ext;
   q.bo          = 0;
   q.yp          = 0;
   q.fvgFar      = dem ? zt : zb;
   q.orj         = true;
   q.timeC1      = mT[firstIdx];
   q.timeForm    = mT[j];
   q.timeTouch   = 0;
   q.cAtr[0]     = 0.0;
   q.cAtr[1]     = 0.0;
   q.cAtr[2]     = 0.0;
   q.cCnt        = 0;
   q.seq         = false;
   q.seqChk      = true;
   q.openFvg     = 0;
   q.tfSec       = -1;
   q.sigType     = type;
   q.sigSlot     = slot;
   q.sigZone     = zoneIdx;
   q.sigState    = 0;
   q.sigId       = ++gSigSeq;
   InitOutcome(q);
   q.outLast     = j;

   int n = ArraySize(sigs);
   ArrayResize(sigs,n+1,1024);
   sigs[n] = q;
   int na = ArraySize(sigActive);
   ArrayResize(sigActive,na+1,1024);
   sigActive[na] = n;
   return(true);
  }

//+------------------------------------------------------------------+
//| Bir HTF motorunun bolgelerini ana grafikte tara:                  |
//|  bolge olusunca (3. mum kapaninca) -> fiyat bolgeden uzaklasir ->   |
//|  ILK temas -> fiyat bolgenin icindeyken (temas mumu dahil)           |
//|  formasyon olusursa sinyal. Fiyat bolgeden cikarsa / karsi kenarda   |
//|  kapanis yaparsa / bolge yasi dolarsa o bolge icin is biter.         |
//+------------------------------------------------------------------+
bool EntryScanEngine(CHtfEngine *e,const int slot,const int lastClosed)
  {
   bool ch = false;
   int nz  = ArraySize(e.zones);
   int old = ArraySize(e.sgScan);
   if(old<nz)
     {
      ArrayResize(e.sgScan,nz,4096);
      ArrayResize(e.sgT0,nz,4096);
      ArrayResize(e.sgFlag,nz,4096);
      for(int q=old;q<nz;q++)
        {
         e.sgScan[q] = -1;
         e.sgT0[q]   = -1;
         e.sgFlag[q] = 0;
        }
     }
   while(e.sgFrom<nz && (e.sgFlag[e.sgFrom] & 2)!=0)
      e.sgFrom++;

   for(int k=e.sgFrom;k<nz;k++)
     {
      if((e.sgFlag[k] & 2)!=0)
         continue;
      double zt  = e.zones[k].top;
      double zb  = e.zones[k].bottom;
      bool   dem = e.zones[k].isDemand;

      if(e.sgScan[k]<0)
        {
         int st = EntryLowerBound((datetime)((long)e.zones[k].timeForm + e.tfSec));   // 3. mum kapandiktan sonraki ilk ana grafik mumu
         if(st>lastClosed)
            continue;
         e.sgScan[k] = st-1;
        }

      int expiryIdx = (MaxZoneAgeBars>0) ? e.zones[k].fvgIdx+MaxZoneAgeBars : INT_MAX;
      datetime tLimit = (expiryIdx<=e.total-1) ? (datetime)((long)e.tm[expiryIdx]+e.tfSec) : (datetime)4102444800;

      bool away = ((e.sgFlag[k] & 1)!=0);
      int  t0   = e.sgT0[k];
      bool done = false;
      int  j    = e.sgScan[k]+1;
      for(;j<=lastClosed;j++)
        {
         if(mT[j]>=tLimit)
           { done = true; break; }              // HTF bolgesinin yasi doldu

         bool ov = (mL[j]<=zt && mH[j]>=zb);    // mum bolgeye degiyor / icinde
         if(t0<0)
           {
            if(!ov)
              { away = true; continue; }        // fiyat bolgeden uzakta
            if(EntryNeedAway && !away)
              { done = true; break; }           // uzaklasmadan temas -> gecerli ilk temas yok
            t0 = j;                             // ILK TEMAS
           }
         else if(!ov)
           { done = true; break; }              // fiyat bolgeden cikti: ilk temas bitti

         bool brk = dem ? (mC[j]<zb) : (mC[j]>zt);
         if(brk)
           { done = true; break; }              // bolge kapanisla kirildi

         double eb = 0.0, et = 0.0;
         int    fi = j;
         int    pt = EntryPattern(j,dem,eb,et,fi);
         if(pt>0)
           {
            if(EntryAddSignal(slot,pt,dem,eb,et,fi,j,k))
               ch = true;
            done = true;
            break;
           }
        }
      e.sgT0[k]   = t0;
      e.sgFlag[k] = (away ? 1 : 0) | (done ? 2 : 0);
      e.sgScan[k] = done ? j : lastClosed;
     }
   return(ch);
  }

//+------------------------------------------------------------------+
//| Sinyal takibi: 0 = giris bekliyor -> seviyeye ulasinca girildi,     |
//| stop once vurulursa / sure dolarsa iptal; 1 = girildi -> TP/SL      |
//| (mevcut UpdateOutcome; giris mumunda SL oncelikli)                  |
//+------------------------------------------------------------------+
bool EntryTrack(const int lastClosed)
  {
   bool ch = false;
   int  na = ArraySize(sigActive);
   int  keep = 0;
   for(int a=0;a<na;a++)
     {
      int k = sigActive[a];
      if(sigs[k].sigState==3)
         continue;

      if(sigs[k].sigState==0)
        {
         int b = sigs[k].lastChecked+1;
         for(;b<=lastClosed;b++)
           {
            bool trig = sigs[k].isDemand ? (mH[b]>=sigs[k].top)    : (mL[b]<=sigs[k].bottom);
            bool stp  = sigs[k].isDemand ? (mL[b]<sigs[k].bottom)  : (mH[b]>sigs[k].top);
            sigs[k].lastChecked = b;
            if(trig)
              {
               sigs[k].sigState  = 1;
               sigs[k].touched   = true;
               sigs[k].touchIdx  = b;
               sigs[k].timeTouch = mT[b];
               sigs[k].outLast   = b-1;
               UpdateOutcome(sigs[k],mH,mL,mC,lastClosed);
               sigs[k].timeEnd   = mT[MathMax(b,sigs[k].outLast)];
               sigs[k].dirty     = true;
               ch = true;
               break;
              }
            if(stp || (b-sigs[k].fvgIdx)>=EntryMaxWaitBars)
              {
               sigs[k].sigState  = 2;
               sigs[k].trackDone = true;
               sigs[k].timeEnd   = mT[b];
               sigs[k].dirty     = true;
               ch = true;
               break;
              }
           }
         if(sigs[k].sigState==0)
           {
            datetime te = mT[MathMax(sigs[k].lastChecked,sigs[k].fvgIdx)];
            if(te!=sigs[k].timeEnd)
              {
               sigs[k].timeEnd = te;
               sigs[k].dirty   = true;
               ch = true;
              }
           }
        }
      else if(sigs[k].sigState==1 && !sigs[k].trackDone)
        {
         bool c = UpdateOutcome(sigs[k],mH,mL,mC,lastClosed);
         if(sigs[k].outLast>=0 && mT[sigs[k].outLast]!=sigs[k].timeEnd)
           {
            sigs[k].timeEnd = mT[sigs[k].outLast];
            c = true;
           }
         if(c)
           {
            sigs[k].dirty = true;
            ch = true;
           }
        }

      if(sigs[k].sigState==0 || (sigs[k].sigState==1 && !sigs[k].trackDone))
         sigActive[keep++] = k;
     }
   ArrayResize(sigActive,keep);
   return(ch);
  }

//--- Acik HTF'lerden yeni sinyalleri tara + sinyalleri takip et. true = degisiklik
bool EntryUpdate()
  {
   if(!entryOn || mN<10)
      return(false);
   int  lastClosed = mN-2;
   bool ch = false;
   for(int i=0;i<NHTF;i++)
     {
      if(!htfOn[i] || !htfAvail[i] || g_htf[i]==NULL)
         continue;
      if(!g_htf[i].built || g_htf[i].total<5)
         continue;
      if(EntryScanEngine(g_htf[i],i,lastClosed))
         ch = true;
     }
   if(EntryTrack(lastClosed))
      ch = true;
   return(ch);
  }

//--- Tum sinyalleri ve tarama durumlarini sifirla (formasyon secimi degisince / tam yeniden hesapta)
void EntryResetAll()
  {
   int n = ArraySize(sigs);
   for(int k=0;k<n;k++)
      if(sigs[k].hasObj)
         DeleteSignalObjects(sigs[k]);
   ArrayResize(sigs,0);
   ArrayResize(sigActive,0);
   for(int i=0;i<NHTF;i++)
     {
      if(g_htf[i]==NULL)
         continue;
      ArrayResize(g_htf[i].sgScan,0);
      ArrayResize(g_htf[i].sgT0,0);
      ArrayResize(g_htf[i].sgFlag,0);
      g_htf[i].sgFrom = 0;
     }
  }

//+------------------------------------------------------------------+
//| Sinyal cizimi: kutu (kenarlik) + yazi + giris/stop/TP1..TP8        |
//+------------------------------------------------------------------+
void EntryLine(const string name,const datetime t1,const datetime t2,const double price,
               const color col,const ENUM_LINE_STYLE style)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_TREND,0,t1,price,t2,price))
         return;
      ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,false);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
     }
   else
     {
      ObjectMove(0,name,0,t1,price);
      ObjectMove(0,name,1,t2,price);
     }
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetInteger(0,name,OBJPROP_STYLE,style);
  }

void EntryText(const string name,const datetime t,const double price,const string txt,const color col)
  {
   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_TEXT,0,t,price))
         return;
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,7);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   else
      ObjectMove(0,name,0,t,price);
   ObjectSetInteger(0,name,OBJPROP_COLOR,col);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
  }

void RenderSignal(const SDZoneInfo &z)
  {
   int      per  = PeriodSeconds(_Period);
   color    base = (z.sigState==2) ? clrGray : (z.isDemand ? EntryDemandColor : EntrySupplyColor);
   datetime t1   = z.timeC1;
   datetime t2   = (datetime)MathMax((long)z.timeEnd,(long)z.timeForm+per);

   //--- kutu (yalniz kenarlik)
   string nb = ZObjName(z,"");
   if(ObjectFind(0,nb)<0)
     {
      if(ObjectCreate(0,nb,OBJ_RECTANGLE,0,t1,z.top,t2,z.bottom))
        {
         ObjectSetInteger(0,nb,OBJPROP_FILL,false);
         ObjectSetInteger(0,nb,OBJPROP_BACK,false);
         ObjectSetInteger(0,nb,OBJPROP_WIDTH,1);
         ObjectSetInteger(0,nb,OBJPROP_STYLE,STYLE_SOLID);
         ObjectSetInteger(0,nb,OBJPROP_SELECTABLE,false);
         ObjectSetInteger(0,nb,OBJPROP_HIDDEN,true);
        }
     }
   else
     {
      ObjectMove(0,nb,0,t1,z.top);
      ObjectMove(0,nb,1,t2,z.bottom);
     }
   ObjectSetInteger(0,nb,OBJPROP_COLOR,base);

   //--- yazi: 'M15 ENG tp1|tp2|sl3 ~ 0.35ATR' (bekleyen: 'bekliyor', iptal: 'iptal', girilmis sonuc yok: 'giris')
   if(ShowATRLabel)
     {
      string tag = htfName[z.sigSlot] + " " + (z.sigType==1 ? "ENG" : (z.sigType==2 ? "PIN" : (z.sigType==3 ? "RR" : "KB"))) + " ";
      string st;
      if(z.sigState==0)
         st = "bekliyor";
      else if(z.sigState==2)
         st = "iptal";
      else
        {
         st = LevelText(z,0,NLEV);
         if(st=="")
            st = "giris";
        }
      string txt = tag + st;
      if(z.atr>0.0)
         txt += " ~ " + DoubleToString((z.top-z.bottom)/z.atr,2) + "ATR";
      if(StringLen(txt)>LBL_MAXLEN)
         txt = StringSubstr(txt,0,LBL_MAXLEN);
      string nl = ZObjName(z,"lb");
      double lp = z.isDemand ? z.bottom : z.top;
      if(ObjectFind(0,nl)<0)
        {
         if(ObjectCreate(0,nl,OBJ_TEXT,0,t2,lp))
           {
            ObjectSetString(0,nl,OBJPROP_FONT,"Arial");
            ObjectSetInteger(0,nl,OBJPROP_FONTSIZE,8);
            ObjectSetInteger(0,nl,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
            ObjectSetInteger(0,nl,OBJPROP_SELECTABLE,false);
            ObjectSetInteger(0,nl,OBJPROP_HIDDEN,true);
           }
        }
      else
         ObjectMove(0,nl,0,t2,lp);
      ObjectSetInteger(0,nl,OBJPROP_COLOR,base);
      ObjectSetString(0,nl,OBJPROP_TEXT,txt);
     }

   //--- giris / stop / TP1..TP8 (iptal edilenlerde cizilmez)
   if(EntryShowLevels && z.sigState!=2)
     {
      double h    = z.top-z.bottom;
      double pe   = z.isDemand ? z.top    : z.bottom;     // giris
      double ps   = z.isDemand ? z.bottom : z.top;        // stop
      datetime lt1 = z.timeForm;
      datetime lt2 = (datetime)MathMax((long)t2,(long)z.timeForm+10*per);
      datetime tx  = lt2+per;
      color    cE  = clrDimGray;
      color    cS  = clrCrimson;
      color    cT  = clrSeaGreen;

      EntryLine(ZObjName(z,"L0"),lt1,lt2,pe,cE,STYLE_SOLID);
      EntryText(ZObjName(z,"T0"),tx,pe,"GIRIS "+DoubleToString(pe,_Digits),cE);
      EntryLine(ZObjName(z,"L9"),lt1,lt2,ps,cS,STYLE_DASH);
      EntryText(ZObjName(z,"T9"),tx,ps,"STOP "+DoubleToString(ps,_Digits),cS);
      for(int n=1;n<=NLEV;n++)
        {
         double pt = z.isDemand ? z.top+n*h : z.bottom-n*h;
         // sonuclanmis TP'ler doygun, bekleyenler soluk cizgi
         color  cc = (z.out[n-1]==1) ? cT : clrSilver;
         EntryLine(ZObjName(z,"L"+IntegerToString(n)),lt1,lt2,pt,cc,STYLE_DOT);
         EntryText(ZObjName(z,"T"+IntegerToString(n)),tx,pt,"TP"+IntegerToString(n)+" "+DoubleToString(pt,_Digits),
                   (z.out[n-1]==1) ? cT : clrGray);
        }
     }
  }

//--- sinyal nesnelerini gorunen pencereye / filtreye gore senkronla
void EntrySync(const datetime tL,const datetime tR)
  {
   int n = ArraySize(sigs);
   for(int k=0;k<n;k++)
     {
      if(sigs[k].sigState==3)
         continue;
      bool want = false;
      if(SigShown(sigs[k]))
         want = (sigs[k].timeC1<=tR && (long)sigs[k].timeEnd+10*PeriodSeconds(_Period)>=(long)tL);
      if(want)
        {
         if(!sigs[k].hasObj || sigs[k].dirty)
           {
            RenderSignal(sigs[k]);
            sigs[k].hasObj = true;
            sigs[k].dirty  = false;
           }
        }
      else if(sigs[k].hasObj)
        {
         DeleteSignalObjects(sigs[k]);
         sigs[k].hasObj = false;
        }
     }
  }

//+------------------------------------------------------------------+
//| V1.51: KOMBINASYON TESTI                                          |
//| Veri: tabloyla ayni (1dk bolge acik: ana grafik bolgeleri, kapali: |
//| giris sinyalleri). Yalniz TP/SL takibi baslamis olanlar ve Tarih   |
//| filtresinden gecenler. Diger tum filtreler denenir.                |
//| Boyutlar: 0 Formasyon (alt kumeler), 1 Saat(4s), 2.. aralik         |
//| filtreleri (FLT_N adet). Tip / HTF / 1dk-giris / Tarih sabit.      |
//| DFS: her boyuttan en fazla bir secenek; bit-kume kesisimi.         |
//+------------------------------------------------------------------+
#define OPT_MAXD  4
#define OPT_NF    2      // islem basina kategorik ozellik: [0] formasyon biti, [1] saat dilimi
#define OPT_NFIX  (2+FLT_N)   // boyutlar: 0 Formasyon, 1 Saat(4s), 2.. aralik filtreleri

bool     optDone      = false;
bool     optSigMode   = false;
string   optStatus    = "";
int      optN         = 0;
int      optW         = 0;
int      optDepth     = 3;
int      optMinTr     = 30;
int      optMinOut    = 10;
int      optFile      = INVALID_HANDLE;
int      optMeta      = INVALID_HANDLE;
string   optSep       = ";";
string   optFileName  = "";
string   optMetaName  = "";
long     optNodes     = 0;
long     optRows      = 0;
uint     optT0        = 0;
uchar    optPc[];
double   optVal[];
uchar    optHas[];
int      optF[];
datetime optTime[];
ulong    optTp[];
ulong    optSl[];
ulong    optHalf[];
ulong    optMaskAt[];
ulong    optTmp[];
ulong    optMask[];
int      optNO        = 0;
int      optND        = 0;
int      optDimId[];
int      optDimFirst[];
int      optDimCnt[];
int      optOFix[];
string   optLbl[];
int      optOKind[];
double   optOMn[];
double   optOMx[];
bool     optOHMn[];
bool     optOHMx[];
int      optOCnt[];
int      optCntAt[OPT_MAXD+1];
int      optSp        = 0;
int      optNd[OPT_MAXD+1];
int      optNo[OPT_MAXD+1];
int      optCO[OPT_MAXD+1];
double   optTopE[10];
string   optTopTxt[10];
string   optDimName[OPT_NFIX];

int OptPop(const ulong x)
  {
   return((int)optPc[(int)(x & 0xFFFF)] + (int)optPc[(int)((x>>16) & 0xFFFF)] +
          (int)optPc[(int)((x>>32) & 0xFFFF)] + (int)optPc[(int)((x>>48) & 0xFFFF)]);
  }

//--- Tarih filtresi (ZonePasses'taki ile ayni; test boyunca tarih araligi sabit kalir)
bool OptDatePass(const SDZoneInfo &z)
  {
   if(!(fltDateOn && (fltDateHasS || fltDateHasE)))
      return(true);
   datetime td = (fltTimeRef==0) ? z.timeForm : (fltTimeRef==1 ? z.timeC1 : z.timeTouch);
   if(td==0)
      return(false);
   datetime day = td - (td % 86400);
   if(fltDateHasS && day < fltDateS)
      return(false);
   if(fltDateHasE && day > fltDateE)
      return(false);
   return(true);
  }

//--- bir islemi (bolge / sinyal) veri kumesine ekle. prop = ozellik filtrelerinin okundugu bolge
void OptPushItem(const SDZoneInfo &own,const SDZoneInfo &prop,const int slot,const int type)
  {
   int i = optN;
   ArrayResize(optVal,(i+1)*FLT_N,FLT_N*4096);
   ArrayResize(optHas,(i+1)*FLT_N,FLT_N*4096);
   ArrayResize(optF,(i+1)*OPT_NF,OPT_NF*4096);
   ArrayResize(optTime,i+1,4096);
   for(int v=0;v<FLT_N;v++)
     {
      double x = 0.0;
      bool ok;
      if(v==0 && slot>=0 && EntryWidthOwn)
         ok = FltValue(own,0,x);
      else
         ok = FltValue(prop,v,x);
      optHas[i*FLT_N+v] = ok ? 1 : 0;
      optVal[i*FLT_N+v] = ok ? x : 0.0;
     }
   datetime tt = (fltTimeRef==0) ? own.timeForm : (fltTimeRef==1 ? own.timeC1 : own.timeTouch);
   int hb = -1;
   if(tt>0)
     {
      MqlDateTime dt;
      TimeToStruct(tt,dt);
      hb = dt.hour/4;
     }
   optF[i*OPT_NF+0] = (type>=1 && type<=4) ? (1<<(type-1)) : 0;   // formasyon biti: ENG=1 PIN=2 RR=4 KB=8
   optF[i*OPT_NF+1] = hb;
   optTime[i] = own.timeForm;
   optN++;
  }

//--- sonuc dizileri (TP/SL maskeleri) icin ham sonuclar: gecici olarak optOutRaw'da tutulur
uchar optOutRaw[];

void OptPushOut(const SDZoneInfo &own)
  {
   int i = optN-1;
   ArrayResize(optOutRaw,(i+1)*NLEV,NLEV*4096);
   for(int l=0;l<NLEV;l++)
      optOutRaw[i*NLEV+l] = (uchar)own.out[l];
  }

//--- veri kumesini topla. false = veri yok
bool OptCollect()
  {
   optN = 0;
   ArrayResize(optVal,0);
   ArrayResize(optHas,0);
   ArrayResize(optF,0);
   ArrayResize(optTime,0);
   ArrayResize(optOutRaw,0);
   optSigMode = !fltMain;
   if(!optSigMode)
     {
      int nz = ArraySize(zones);
      for(int k=0;k<nz;k++)
        {
         if(zones[k].touchIdx<0 || !OptDatePass(zones[k]))
            continue;
         if(zones[k].isDemand ? !fltDemand : !fltSupply)
            continue;                      // TALEP / ARZ satiri panelde nasil ise (sabit)
         OptPushItem(zones[k],zones[k],-1,0);
         OptPushOut(zones[k]);
        }
     }
   else
     {
      int ns = ArraySize(sigs);
      for(int k=0;k<ns;k++)
        {
         if(!SigEnabled(sigs[k]) || sigs[k].sigState!=1 || !OptDatePass(sigs[k]))
            continue;                      // acik HTF / giris modeli / iptal-goster ve Tarih panelde nasil ise (sabit)
         if(sigs[k].isDemand ? !fltDemand : !fltSupply)
            continue;                      // TALEP / ARZ satiri panelde nasil ise (sabit)
         SDZoneInfo pz;
         if(!SigParentGet(sigs[k],pz))
            pz = sigs[k];
         OptPushItem(sigs[k],pz,sigs[k].sigSlot,sigs[k].sigType);
         OptPushOut(sigs[k]);
        }
     }
   return(optN>0);
  }

//--- secenek ekle: maske hesapla, az islemli / tekrar eden / hicbir seyi elemeyen secenekleri at
//--- kind 0 = kategorik (feat == tgt), kind 1 = aralik (vi = feat; mn/mx dahil)
bool OptAddOpt(const int fx,const int kind,const int feat,const int tgt,
               const double mn,const double mx,const bool hMn,const bool hMx,const string lbl)
  {
   int W = optW;
   ArrayInitialize(optTmp,0);
   for(int i=0;i<optN;i++)
     {
      bool ok;
      if(kind==0)
         ok = (optF[i*OPT_NF+feat]==tgt);
      else if(kind==2)
         ok = ((optF[i*OPT_NF+feat] & tgt)!=0);      // formasyon alt kumesi
      else
        {
         ok = (optHas[i*FLT_N+feat]!=0);
         if(ok)
           {
            double v = optVal[i*FLT_N+feat];
            if(hMn && v<NormalizeDouble(mn,2))
               ok = false;
            if(hMx && v>NormalizeDouble(mx,2))
               ok = false;
           }
        }
      if(ok)
         optTmp[i>>6] |= (((ulong)1)<<(i&63));
     }
   int cnt = 0;
   for(int w=0;w<W;w++)
      cnt += OptPop(optTmp[w]);
   if(cnt<optMinTr || cnt==optN)
      return(false);
   for(int o=optNO-1;o>=0 && optOFix[o]==fx;o--)       // ayni boyutta ayni kume zaten var mi
     {
      bool same = true;
      for(int w2=0;w2<W;w2++)
         if(optMask[o*W+w2]!=optTmp[w2])
           { same = false; break; }
      if(same)
         return(false);
     }
   if(optNO==0 || optOFix[optNO-1]!=fx)
     {
      ArrayResize(optDimId,optND+1,64);
      ArrayResize(optDimFirst,optND+1,64);
      ArrayResize(optDimCnt,optND+1,64);
      optDimId[optND]    = fx;
      optDimFirst[optND] = optNO;
      optDimCnt[optND]   = 0;
      optND++;
     }
   optDimCnt[optND-1]++;
   ArrayResize(optMask,(optNO+1)*W,64*W);
   for(int w3=0;w3<W;w3++)
      optMask[optNO*W+w3] = optTmp[w3];
   ArrayResize(optOFix,optNO+1,128);
   ArrayResize(optLbl,optNO+1,128);
   ArrayResize(optOKind,optNO+1,128);
   ArrayResize(optOMn,optNO+1,128);
   ArrayResize(optOMx,optNO+1,128);
   ArrayResize(optOHMn,optNO+1,128);
   ArrayResize(optOHMx,optNO+1,128);
   ArrayResize(optOCnt,optNO+1,128);
   optOFix[optNO]  = fx;
   optLbl[optNO]   = lbl;
   optOKind[optNO] = kind;
   optOMn[optNO]   = mn;
   optOMx[optNO]   = mx;
   optOHMn[optNO]  = hMn;
   optOHMx[optNO]  = hMx;
   optOCnt[optNO]  = cnt;
   optNO++;
   return(true);
  }

void OptAddRange(const int vi,const double mn,const double mx,const bool hMn,const bool hMx)
  {
   string lbl;
   if(hMn && hMx)
      lbl = FmtNum(mn) + ".." + FmtNum(mx);
   else if(hMn)
      lbl = ">=" + FmtNum(mn);
   else
      lbl = "<=" + FmtNum(mx);
   OptAddOpt(2+vi,1,vi,0,mn,mx,hMn,hMx,lbl);
  }

//--- tum secenekleri olustur (veriden hesaplanan aralik esikleriyle)
void OptBuildOptions()
  {
   optNO = 0;
   optND = 0;
   ArrayResize(optMask,0);
   ArrayResize(optDimId,0);
   ArrayResize(optDimFirst,0);
   ArrayResize(optDimCnt,0);
   ArrayResize(optOFix,0);
   ArrayResize(optLbl,0);
   ArrayResize(optOKind,0);
   ArrayResize(optOMn,0);
   ArrayResize(optOMx,0);
   ArrayResize(optOHMn,0);
   ArrayResize(optOHMx,0);
   ArrayResize(optOCnt,0);

   // Formasyon satiri: ENG / PIN / RR / KB'nin tum bos olmayan alt kumeleri (yalniz giris sinyali modunda;
   // yalnizca panelde acik formasyonlarla uretilmis sinyaller icinde secim yapar)
   if(optSigMode)
     {
      for(int sub=1;sub<=15;sub++)
        {
         string pl = "";
         if((sub & 1)!=0) pl += "ENG";
         if((sub & 2)!=0) pl += (pl=="" ? "" : "+") + "PIN";
         if((sub & 4)!=0) pl += (pl=="" ? "" : "+") + "RR";
         if((sub & 8)!=0) pl += (pl=="" ? "" : "+") + "KB";
         OptAddOpt(0,2,0,sub,0,0,false,false,pl);
        }
     }
   // Saat dilimi (4 saatlik 6 dilim; zaman referansi panelde nasil ise)
   for(int b=0;b<6;b++)
      OptAddOpt(1,0,1,b,0,0,false,false,StringFormat("%02d:00-%02d:59",b*4,b*4+3));

   for(int vi=0;vi<FLT_N;vi++)
     {
      double vals[];
      ArrayResize(vals,optN);
      int nv = 0;
      for(int i=0;i<optN;i++)
         if(optHas[i*FLT_N+vi]!=0)
            vals[nv++] = optVal[i*FLT_N+vi];
      if(nv<optMinTr)
         continue;
      ArrayResize(vals,nv);
      ArraySort(vals);
      double t33 = vals[(int)MathFloor(0.333*(nv-1))];
      double t50 = vals[(int)MathFloor(0.500*(nv-1))];
      double t67 = vals[(int)MathFloor(0.667*(nv-1))];
      OptAddRange(vi,0.0,t33,false,true);     // alt ucte bir
      OptAddRange(vi,t33,t67,true,true);      // orta ucte bir
      OptAddRange(vi,t67,0.0,true,false);     // ust ucte bir
      OptAddRange(vi,0.0,t50,false,true);     // alt yari
      OptAddRange(vi,t50,0.0,true,false);     // ust yari
     }
  }

string OptStamp()
  {
   string st = TimeToString(TimeLocal(),TIME_DATE|TIME_SECONDS);
   StringReplace(st,".","");
   StringReplace(st,":","");
   StringReplace(st," ","_");
   return(st);
  }

//--- DFS dugumunu CSV satiri olarak yaz (depth = secili filtre sayisi, nodeBase = maske konumu)
void OptRecord(const int depth,const int nodeBase,const int cnt)
  {
   int W = optW;
   int tp[8];
   int sl[8];
   for(int l=0;l<8;l++)
     {
      int a = 0, b = 0, lb = l*W;
      for(int w=0;w<W;w++)
        {
         ulong x = optMaskAt[nodeBase+w];
         a += OptPop(x & optTp[lb+w]);
         b += OptPop(x & optSl[lb+w]);
        }
      tp[l] = a;
      sl[l] = b;
     }
   // en iyi seviye: yeterli sonuclanmis islemi olan seviyeler arasinda en yuksek ortalama R
   int    best  = 0;
   double bestR = 0.0;
   bool   any   = false;
   for(int l2=0;l2<8;l2++)
     {
      int nt = tp[l2]+sl[l2];
      if(nt<optMinOut)
         continue;
      double avg = ((double)tp[l2]*(l2+1)-sl[l2])/nt;
      if(!any || avg>bestR)
        { any = true; best = l2; bestR = avg; }
     }
   if(!any)
     {
      int nt0 = tp[0]+sl[0];
      bestR = (nt0>0) ? ((double)tp[0]-sl[0])/nt0 : 0.0;
     }
   // zaman ikiye bolunmus: en iyi seviyede her yarinin ortalama R'i (asiri uyum kontrolu)
   int tpA = 0, slA = 0, tpB = 0, slB = 0, nA = 0, nB = 0;
   for(int w2=0;w2<W;w2++)
     {
      ulong x2 = optMaskAt[nodeBase+w2];
      ulong h  = optHalf[w2];
      ulong xa = x2 & h;
      ulong xb = x2 & (~h);
      nA  += OptPop(xa);
      nB  += OptPop(xb);
      tpA += OptPop(xa & optTp[best*W+w2]);
      slA += OptPop(xa & optSl[best*W+w2]);
      tpB += OptPop(xb & optTp[best*W+w2]);
      slB += OptPop(xb & optSl[best*W+w2]);
     }
   string avA = (tpA+slA>0) ? DoubleToString(((double)tpA*(best+1)-slA)/(tpA+slA),3) : "";
   string avB = (tpB+slB>0) ? DoubleToString(((double)tpB*(best+1)-slB)/(tpB+slB),3) : "";

   string cols[OPT_NFIX];
   for(int f=0;f<OPT_NFIX;f++)
      cols[f] = "-";
   string conds = "";
   for(int k=0;k<depth;k++)
     {
      int oi = optCO[k];
      cols[optOFix[oi]] = optLbl[oi];
      conds += (k>0 ? " + " : "") + optDimName[optOFix[oi]] + " " + optLbl[oi];
     }
   if(depth==0)
      conds = "(filtresiz)";

   string line = IntegerToString(depth) + optSep + conds;
   for(int f2=0;f2<OPT_NFIX;f2++)
      line += optSep + cols[f2];
   line += optSep + IntegerToString(cnt) + optSep + IntegerToString(nA) + optSep + IntegerToString(nB);
   for(int l3=0;l3<8;l3++)
     {
      int nt2  = tp[l3]+sl[l3];
      int netR = tp[l3]*(l3+1) - sl[l3];
      line += optSep + IntegerToString(tp[l3]) + optSep + IntegerToString(sl[l3]) + optSep + IntegerToString(netR) +
              optSep + (nt2>0 ? DoubleToString(100.0*tp[l3]/nt2,1) : "");
     }
   line += optSep + IntegerToString(best+1) + optSep + DoubleToString(bestR,3) + optSep + avA + optSep + avB;
   if(optFile!=INVALID_HANDLE)
      FileWriteString(optFile,line+"\r\n");
   optRows++;

   // en iyi 10 (derinligi >0, yeterli sonuclanmis islemi olanlar)
   if(depth>0 && any)
     {
      int pos = -1;
      for(int t=0;t<10;t++)
         if(optTopTxt[t]=="" || bestR>optTopE[t])
           { pos = t; break; }
      if(pos>=0)
        {
         for(int t2=9;t2>pos;t2--)
           { optTopE[t2] = optTopE[t2-1]; optTopTxt[t2] = optTopTxt[t2-1]; }
         optTopE[pos]   = bestR;
         optTopTxt[pos] = "TP" + IntegerToString(best+1) + " ortR=" + DoubleToString(bestR,3) +
                          " islem=" + IntegerToString(cnt) + "  [" + conds + "]";
        }
     }
  }

//--- bir DFS adimi: siradaki adayi (boyut, secenek) dene
void OptStepOne()
  {
   int sp = optSp;
   int d  = optNd[sp];
   if(d>=optND)
     {
      if(sp==0)
        { optDone = true; return; }
      optSp--;                       // bu seviye bitti, bir ust seviyeye don
      return;
     }
   int o  = optNo[sp];
   int oi = optDimFirst[d]+o;
   optNo[sp]++;
   if(optNo[sp]>=optDimCnt[d])
     { optNd[sp] = d+1; optNo[sp] = 0; }

   int W  = optW;
   int pb = sp*W, nb = (sp+1)*W, ob = oi*W;
   int cnt = 0;
   for(int w=0;w<W;w++)
     {
      ulong x = optMaskAt[pb+w] & optMask[ob+w];
      optMaskAt[nb+w] = x;
      cnt += OptPop(x);
     }
   optNodes++;
   if(cnt<optMinTr || cnt==optCntAt[sp])
      return;                        // az islem / ustten farksiz -> yaz ve derine inme
   optCO[sp]       = oi;
   optCntAt[sp+1]  = cnt;
   OptRecord(sp+1,nb,cnt);
   if(optRows>=OptMaxRows)
     { optDone = true; optStatus = "satir siniri"; return; }
   if(sp+1<optDepth)
     {
      optSp = sp+1;
      optNd[sp+1] = d+1;
      optNo[sp+1] = 0;
     }
  }

void OptWriteMetaLine(const string a,const string b)
  {
   if(optMeta!=INVALID_HANDLE)
      FileWriteString(optMeta,a+optSep+b+"\r\n");
  }

//--- testi bitir / iptal et: dosyalari kapat, ozet yaz
void OptFinish(const bool cancelled)
  {
   if(!optRunning)
      return;
   double secs = (GetTickCount()-optT0)/1000.0;
   if(optStatus=="")
      optStatus = cancelled ? "iptal edildi (kismi sonuc)" : "tamamlandi";
   OptWriteMetaLine("","");
   OptWriteMetaLine("Durum",optStatus);
   OptWriteMetaLine("Denenen kombinasyon (dugum)",IntegerToString((int)optNodes));
   OptWriteMetaLine("CSV'ye yazilan satir",IntegerToString((int)optRows));
   OptWriteMetaLine("Sure (sn)",DoubleToString(secs,1));
   if(optFile!=INVALID_HANDLE)
      FileClose(optFile);
   if(optMeta!=INVALID_HANDLE)
      FileClose(optMeta);
   optFile = INVALID_HANDLE;
   optMeta = INVALID_HANDLE;
   optRunning = false;
   optDone    = true;
   EventSetTimer(1);

   string bn = prefix+"FLT_H_OPT";
   if(ObjectFind(0,bn)>=0)
     {
      ObjectSetString(0,bn,OBJPROP_TEXT,"Kombinasyon");
      ObjectSetInteger(0,bn,OBJPROP_STATE,false);
     }
   string dir = TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL5\\Files\\";
   Print("SupplyDemand kombinasyon testi ",optStatus,": ",optNodes," dugum, ",optRows," satir, ",DoubleToString(secs,1)," sn");
   Print("  Sonuclar: ",dir,optFileName);
   Print("  Araliklar: ",dir,optMetaName);
   for(int t=0;t<10;t++)
      if(optTopTxt[t]!="")
         Print("  #",t+1," ",optTopTxt[t]);
   Alert("Kombinasyon testi ",optStatus,"\n",IntegerToString((int)optRows)," satir yazildi\n",dir,optFileName);

   ArrayFree(optVal);
   ArrayFree(optHas);
   ArrayFree(optF);
   ArrayFree(optTime);
   ArrayFree(optOutRaw);
   ArrayFree(optTp);
   ArrayFree(optSl);
   ArrayFree(optHalf);
   ArrayFree(optMaskAt);
   ArrayFree(optMask);
   ArrayFree(optTmp);
   ChartRedraw();
  }

//--- testi baslat
void OptStart()
  {
   optSep    = (StringLen(CsvSeparator)>0) ? CsvSeparator : ";";
   optMinTr  = MathMax(5,OptMinTrades);
   optDepth  = MathMin(OPT_MAXD,MathMax(1,OptMaxDepth));
   optMinOut = MathMax(10,optMinTr/2);
   optStatus = "";
   optNodes  = 0;
   optRows   = 0;
   for(int t=0;t<10;t++)
     { optTopE[t] = 0.0; optTopTxt[t] = ""; }

   if(!OptCollect())
     {
      Alert("Kombinasyon testi: veri yok (TP/SL takibi baslamis ",(fltMain ? "bolge" : "giris sinyali")," bulunamadi).");
      return;
     }
   if(optN<optMinTr)
     {
      Alert("Kombinasyon testi: yalnizca ",optN," islem var, OptMinTrades=",optMinTr," (input'tan dusurulebilir).");
      return;
     }
   optW = (optN+63)/64;

   // popcount tablosu
   ArrayResize(optPc,65536);
   optPc[0] = 0;
   for(int i=1;i<65536;i++)
      optPc[i] = (uchar)(optPc[i>>1] + (i&1));

   // sonuc maskeleri (seviye bazinda TP / SL), tum islemler maskesi, zaman yarisi maskesi
   ArrayResize(optTp,8*optW);
   ArrayResize(optSl,8*optW);
   ArrayResize(optHalf,optW);
   ArrayResize(optTmp,optW);
   ArrayInitialize(optTp,0);
   ArrayInitialize(optSl,0);
   ArrayInitialize(optHalf,0);
   datetime tsort[];
   ArrayResize(tsort,optN);
   for(int i2=0;i2<optN;i2++)
      tsort[i2] = optTime[i2];
   ArraySort(tsort);
   datetime med = tsort[optN/2];
   for(int i3=0;i3<optN;i3++)
     {
      ulong bit = ((ulong)1)<<(i3&63);
      int   wi  = i3>>6;
      for(int l=0;l<8;l++)
        {
         int oc = (int)optOutRaw[i3*NLEV+l];
         if(oc==1)
            optTp[l*optW+wi] |= bit;
         else if(oc==2)
            optSl[l*optW+wi] |= bit;
        }
      if(optTime[i3]<=med)
         optHalf[wi] |= bit;
     }

   OptBuildOptions();

   // dosyalar
   string tf = EnumToString(_Period);
   StringReplace(tf,"PERIOD_","");
   string stamp = OptStamp();
   optFileName = "SDZ_"+_Symbol+"_"+tf+"_"+stamp+"_KOMB.csv";
   optMetaName = "SDZ_"+_Symbol+"_"+tf+"_"+stamp+"_ARALIK.csv";
   optFile = FileOpen(optFileName,FILE_WRITE|FILE_TXT|FILE_ANSI);
   optMeta = FileOpen(optMetaName,FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(optFile==INVALID_HANDLE || optMeta==INVALID_HANDLE)
     {
      Alert("Kombinasyon testi: CSV acilamadi (hata ",GetLastError(),")");
      if(optFile!=INVALID_HANDLE) FileClose(optFile);
      if(optMeta!=INVALID_HANDLE) FileClose(optMeta);
      optFile = INVALID_HANDLE;
      optMeta = INVALID_HANDLE;
      return;
     }

   // boyut adlari
   optDimName[0] = "Formasyon";
   optDimName[1] = "Saat(4s)";
   for(int v=0;v<FLT_N;v++)
      optDimName[2+v] = fltName[v];

   // ---- ARALIK dosyasi: ayarlar + denenen secenekler
   OptWriteMetaLine("Sembol / TF",_Symbol+" "+tf);
   OptWriteMetaLine("Veri kaynagi",optSigMode ? "Giris sinyalleri (1dk bolge kapali)" : "Ana grafik bolgeleri");
   OptWriteMetaLine("Islem sayisi (TP/SL takibi baslamis)",IntegerToString(optN));
   string dtxt = "yok";
   if(fltDateOn && (fltDateHasS || fltDateHasE))
      dtxt = (fltDateHasS ? FmtDate(fltDateS) : "") + " - " + (fltDateHasE ? FmtDate(fltDateE) : "");
   OptWriteMetaLine("Tarih filtresi (sabit, denenmedi)",dtxt);
   OptWriteMetaLine("Zaman referansi",(fltTimeRef==0) ? "Olusum (3.mum)" : ((fltTimeRef==1) ? "Baslangic (1.mum)" : "Ilk temas"));
   OptWriteMetaLine("Sabit (panelde nasil ise uygulandi, denenmedi)","Tip: TALEP "+(fltDemand ? "acik" : "kapali")+" / ARZ "+(fltSupply ? "acik" : "kapali")+"; HTF satiri; 1dk bolge / giris modeli satiri; Tarih");
   OptWriteMetaLine("Denenen","Formasyon alt kumeleri (giris sinyali modunda), Saat dilimi, "+IntegerToString(FLT_N)+" aralik filtresi");
   OptWriteMetaLine("Filtre disi (ne uygulandi ne denendi)","TP1-TP8 / SL1-SL8 butonlari, ORJ/NORJ, FFVGT var/yok, ARD var/yok, V/UV");
   OptWriteMetaLine("Panelde girili aralik / saat filtreleri","bu testte yok sayildi (yerine denenen aralik / saat dilimleri kullanildi)");
   OptWriteMetaLine("OptMinTrades",IntegerToString(optMinTr));
   OptWriteMetaLine("OptMaxDepth",IntegerToString(optDepth));
   OptWriteMetaLine("Aralik tanimi","her filtre icin veriden: alt 1/3, orta 1/3, ust 1/3, alt yari, ust yari (iki uc dahil; panele ayni Min/Max yazilabilir)");
   OptWriteMetaLine("En iyi seviye","en az "+IntegerToString(optMinOut)+" sonuclanmis islemi olan seviyeler arasinda en yuksek ort R (TP=+nR, SL=-1R)");
   if(optSigMode)
     {
      string pat = "";
      if(entryEng)  pat += "ENG ";
      if(entryPin)  pat += "PIN ";
      if(entryRail) pat += "RR ";
      if(entryKb)   pat += "KB ";
      OptWriteMetaLine("Acik formasyonlar (sinyaller bunlarla uretildi)",pat);
      string hs = "";
      for(int h=0;h<NHTF;h++)
         if(htfOn[h] && htfAvail[h])
            hs += htfName[h] + " ";
      OptWriteMetaLine("Acik HTF",hs);
      OptWriteMetaLine("Genislik ATR kaynagi",EntryWidthOwn ? "sinyalin kendi bolgesi" : "sinyali ureten HTF bolgesi");
     }
   OptWriteMetaLine("","");
   FileWriteString(optMeta,"Boyut"+optSep+"Secenek"+optSep+"Min"+optSep+"Max"+optSep+"Islem_Sayisi\r\n");
   for(int fx=0;fx<OPT_NFIX;fx++)
     {
      bool has = false;
      for(int o=0;o<optNO;o++)
        {
         if(optOFix[o]!=fx)
            continue;
         has = true;
         string mn = (optOKind[o]==1 && optOHMn[o]) ? FmtNum(optOMn[o]) : "";
         string mx = (optOKind[o]==1 && optOHMx[o]) ? FmtNum(optOMx[o]) : "";
         FileWriteString(optMeta,optDimName[fx]+optSep+optLbl[o]+optSep+mn+optSep+mx+optSep+IntegerToString(optOCnt[o])+"\r\n");
        }
      if(!has)
         FileWriteString(optMeta,optDimName[fx]+optSep+"(denenmedi: yeterli islem yok / secenek yok)"+optSep+optSep+optSep+"\r\n");
     }

   // ---- KOMB dosyasi basligi
   string hdr = "Derinlik" + optSep + "Kosullar";
   for(int f=0;f<OPT_NFIX;f++)
      hdr += optSep + optDimName[f];
   hdr += optSep + "Islem" + optSep + "Ilk_Yari_Islem" + optSep + "Ikinci_Yari_Islem";
   for(int n=1;n<=8;n++)
     {
      string sn = IntegerToString(n);
      hdr += optSep + "TP"+sn + optSep + "SL"+sn + optSep + "NetR"+sn + optSep + "Win%_"+sn;
     }
   hdr += optSep + "EnIyi_Seviye" + optSep + "EnIyi_OrtR" + optSep + "EnIyi_IlkYari_OrtR" + optSep + "EnIyi_IkinciYari_OrtR";
   FileWriteString(optFile,hdr+"\r\n");

   // ---- DFS baslangici
   ArrayResize(optMaskAt,(OPT_MAXD+1)*optW);
   ArrayInitialize(optMaskAt,0);
   for(int i4=0;i4<optN;i4++)
      optMaskAt[i4>>6] |= (((ulong)1)<<(i4&63));
   optSp = 0;
   optNd[0] = 0;
   optNo[0] = 0;
   optCntAt[0] = optN;
   optDone = false;
   optT0 = GetTickCount();
   optRunning = true;

   OptRecord(0,0,optN);              // filtresiz taban satiri

   string bn = prefix+"FLT_H_OPT";
   if(ObjectFind(0,bn)>=0)
     {
      ObjectSetString(0,bn,OBJPROP_TEXT,"Iptal %0");
      ObjectSetInteger(0,bn,OBJPROP_STATE,true);
     }
   EventSetMillisecondTimer(100);
   Print("SupplyDemand kombinasyon testi basladi: ",optN," islem, ",optNO," secenek, ",optND," boyut, derinlik ",optDepth);
  }

void OptToggle()
  {
   if(optRunning)
      OptFinish(true);
   else
      OptStart();
  }

string OptButtonText()
  {
   return(optRunning ? "Iptal" : "Kombinasyon");
  }

//--- zamanlayici: her turda en fazla ~60 ms is yap (grafik donmasin)
void OptOnTimer()
  {
   if(!optRunning)
      return;
   uint t0 = GetTickCount();
   while(!optDone && GetTickCount()-t0<60)
     {
      for(int k=0;k<50 && !optDone;k++)
         OptStepOne();
     }
   if(optDone)
     {
      OptFinish(false);
      return;
     }
   double pr = 0.0;
   if(optNO>0 && optND>0)
     {
      int d = MathMin(optNd[0],optND-1);
      pr = 100.0*(optDimFirst[d]+optNo[0])/optNO;
     }
   string bn = prefix+"FLT_H_OPT";
   if(ObjectFind(0,bn)>=0)
      ObjectSetString(0,bn,OBJPROP_TEXT,"Iptal %"+IntegerToString((int)pr));
   ChartRedraw();
  }

//--- indikator kapanirken acik dosya kalmasin
void OptShutdown()
  {
   if(optRunning)
     {
      optStatus = "indikator kapandi (kismi sonuc)";
      OptFinish(true);
     }
  }

//+------------------------------------------------------------------+
//| Renk koyulastirma (HTF kenar / yazi rengi icin)                   |
//+------------------------------------------------------------------+
color HtfDarken(const color c,const double f)
  {
   uint cu = (uint)c;
   int  r  = (int)(cu & 0xFF);
   int  g  = (int)((cu>>8) & 0xFF);
   int  b  = (int)((cu>>16) & 0xFF);
   r = (int)(r*f);
   g = (int)(g*f);
   b = (int)(b*f);
   return((color)(r | (g<<8) | (b<<16)));
  }

//+------------------------------------------------------------------+
//| HTF kutusunun sag ucu (ana grafik zamani):                         |
//|  - temas yok: son HTF mumunun kapanisi (acilis + TF suresi)        |
//|  - temas var: temasin oldugu HTF mumu icinde, ana grafikte bolgeye |
//|    ILK degen mumun zamani (bulunamazsa HTF mumunun acilisi)        |
//+------------------------------------------------------------------+
datetime HtfRenderEnd(const SDZoneInfo &z)
  {
   datetime tEnd = z.timeEnd + z.tfSec;
   if(z.touchIdx>=0 && z.timeTouch>0)
     {
      tEnd = z.timeTouch;
      MqlRates r[];
      ArraySetAsSeries(r,false);
      int got = CopyRates(_Symbol,_Period,z.timeTouch,z.timeTouch+z.tfSec-1,r);
      for(int q=0;q<got;q++)
        {
         bool hit = z.isDemand ? (r[q].low <= z.top) : (r[q].high >= z.bottom);
         if(hit)
           {
            tEnd = r[q].time;
            break;
           }
        }
     }
   return(tEnd);
  }

//--- HTF bolge yazisi: 'M15 tp1|sl2 ~ 0.45ATR|...' (TF eki + ayni sayfali yazi)
void DrawZoneLabelHtf(const SDZoneInfo &z,const int slot,const datetime tEnd,const color tc)
  {
   string name  = ZObjName(z,"lb");
   string tag   = htfName[slot];
   int    pages = 1;
   string txt   = tag + " " + ZoneLabelTextEx(z,gLabelPage,pages,LBL_MAXLEN-StringLen(tag)-1);
   double price = z.isDemand ? z.bottom : z.top;

   if(ObjectFind(0,name)<0)
     {
      if(!ObjectCreate(0,name,OBJ_TEXT,0,tEnd,price))
         return;
      ObjectSetString(0,name,OBJPROP_FONT,"Arial");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_COLOR,tc);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,z.isDemand ? ANCHOR_RIGHT_UPPER : ANCHOR_RIGHT_LOWER);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
     }
   else
      ObjectMove(0,name,0,tEnd,price);
   ObjectSetString(0,name,OBJPROP_TEXT,txt);
  }

//--- HTF bolgesinin kutu / kenar / yazi nesnelerini ciz
void RenderZoneHtf(const SDZoneInfo &z,const int slot)
  {
   color    fill = z.isDemand ? htfDemClr[slot] : htfSupClr[slot];
   color    dk   = HtfDarken(fill,0.55);
   datetime tEnd = HtfRenderEnd(z);

   DrawZone(ZObjName(z,""),z.timeC1,tEnd,z.top,z.bottom,fill);

   if(ShowBorder)
     {
      string n = ZObjName(z,"bd");
      if(ObjectFind(0,n)<0)
        {
         if(ObjectCreate(0,n,OBJ_RECTANGLE,0,z.timeC1,z.top,tEnd,z.bottom))
           {
            ObjectSetInteger(0,n,OBJPROP_COLOR,dk);
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
         ObjectMove(0,n,0,z.timeC1,z.top);
         ObjectMove(0,n,1,tEnd,z.bottom);
        }
     }

   if(ShowATRLabel && HtfShowLabels)
      DrawZoneLabelHtf(z,slot,tEnd,dk);
  }

//--- Motoru (gerekirse) olustur
void HtfEnsure(const int i)
  {
   if(g_htf[i]!=NULL)
      return;
   g_htf[i] = new CHtfEngine();
   if(!g_htf[i].Init(i,htfTf[i]))
     {
      delete g_htf[i];
      g_htf[i] = NULL;
      htfOn[i] = false;
     }
  }

void HtfInit()
  {
   htfTf[0] = PERIOD_M5;   htfTf[1] = PERIOD_M15;  htfTf[2] = PERIOD_M30;
   htfTf[3] = PERIOD_H1;   htfTf[4] = PERIOD_H4;   htfTf[5] = PERIOD_D1;
   htfDemClr[0] = HtfM5DemandColor;   htfSupClr[0] = HtfM5SupplyColor;
   htfDemClr[1] = HtfM15DemandColor;  htfSupClr[1] = HtfM15SupplyColor;
   htfDemClr[2] = HtfM30DemandColor;  htfSupClr[2] = HtfM30SupplyColor;
   htfDemClr[3] = HtfH1DemandColor;   htfSupClr[3] = HtfH1SupplyColor;
   htfDemClr[4] = HtfH4DemandColor;   htfSupClr[4] = HtfH4SupplyColor;
   htfDemClr[5] = HtfD1DemandColor;   htfSupClr[5] = HtfD1SupplyColor;

   bool initOn[NHTF];
   initOn[0] = HtfShowM5;   initOn[1] = HtfShowM15;  initOn[2] = HtfShowM30;
   initOn[3] = HtfShowH1;   initOn[4] = HtfShowH4;   initOn[5] = HtfShowD1;

   // V1.47: giris modeli ve ana grafik gorunurlugu
   fltMain   = MainZonesVisible;
   entryOn   = EntryModelOn;
   entryEng  = EntryUseEngulf;
   entryPin  = EntryUsePinbar;
   entryRail = EntryUseRail;
   entryKb   = EntryUseKb;
   entryCxl  = EntryShowCancelled;
   gSigSeq   = 0;
   mN        = 0;
   ArrayResize(sigs,0);
   ArrayResize(sigActive,0);

   htfSyncValid = false;
   htfPending   = false;
   for(int i=0;i<NHTF;i++)
     {
      g_htf[i]    = NULL;
      htfAvail[i] = (PeriodSeconds(htfTf[i]) > PeriodSeconds(_Period));
      htfOn[i]    = (initOn[i] && htfAvail[i]);
     }
   for(int j=0;j<NHTF;j++)
      if(htfOn[j])
        {
         HtfEnsure(j);
         if(htfOn[j])
            htfPending = true;
        }
   EventSetTimer(1);
  }

void HtfDeinit()
  {
   EventKillTimer();
   for(int i=0;i<NHTF;i++)
      if(g_htf[i]!=NULL)
        {
         delete g_htf[i];
         g_htf[i] = NULL;
        }
  }

//--- Panel dugmesi: HTF ac / kapa (acilirken motor hemen kurulur / guncellenir)
void HtfOnToggle(const int i)
  {
   if(i<0 || i>=NHTF || !htfAvail[i])
      return;
   htfOn[i] = !htfOn[i];
   if(htfOn[i])
     {
      HtfEnsure(i);
      if(htfOn[i] && g_htf[i]!=NULL)
        {
         g_htf[i].Update();
         htfPending = true;
        }
     }
  }

//--- Acik HTF motorlarini guncelle. true = bolge verisi degisti (yeniden senkron gerek)
bool HtfUpdateAll()
  {
   bool ch      = false;
   bool pending = false;
   for(int i=0;i<NHTF;i++)
     {
      if(!htfOn[i] || !htfAvail[i] || g_htf[i]==NULL)
         continue;
      if(g_htf[i].Update())
         ch = true;
      if(!g_htf[i].ready)
         pending = true;
     }
   htfPending = pending;
   return(ch);
  }

//--- Veri / ATR gec hazir olan HTF'ler icin zamanlayici (tick gelmese de dener)
void HtfOnTimer()
  {
   if(!htfPending)
      return;
   bool ch = HtfUpdateAll();
   if(EntryUpdate())          // V1.47
      ch = true;
   if(ch)
     {
      RefreshTables(true);
      ChartRedraw();
     }
  }

void HtfMarkAllDirty()
  {
   for(int q=0;q<ArraySize(sigs);q++)       // V1.47
      sigs[q].dirty = true;
   for(int i=0;i<NHTF;i++)
     {
      if(g_htf[i]==NULL)
         continue;
      int nz = ArraySize(g_htf[i].zones);
      for(int k=0;k<nz;k++)
         g_htf[i].zones[k].dirty = true;
     }
  }

//--- ObjectsDeleteAll(prefix) calistiktan sonra: HTF nesne bayraklarini sifirla
void HtfOnFullCalc()
  {
   htfSyncValid = false;
   EntryResetAll();           // V1.47: ana grafik indeksleri degisebilir -> sinyaller bastan taranir
   for(int i=0;i<NHTF;i++)
     {
      if(g_htf[i]==NULL)
         continue;
      int nz = ArraySize(g_htf[i].zones);
      for(int k=0;k<nz;k++)
        {
         g_htf[i].zones[k].hasObj = false;
         g_htf[i].zones[k].dirty  = true;
        }
      g_htf[i].anyObj = false;
     }
  }

int HtfMaxLabelPages()
  {
   int mx = 1;
   for(int i=0;i<NHTF;i++)
     {
      if(g_htf[i]==NULL || !htfOn[i])
         continue;
      int nz = ArraySize(g_htf[i].zones);
      for(int k=0;k<nz;k++)
        {
         int p = 1;
         ZoneLabelTextEx(g_htf[i].zones[k],0,p,LBL_MAXLEN-4);
         if(p>mx)
            mx = p;
        }
     }
   return(mx);
  }

//+------------------------------------------------------------------+
//| HTF nesnelerini gorunen pencereye (+kenar payi) ve filtreye gore    |
//| senkronla (SyncObjects'in HTF versiyonu; pencere ZAMAN ile bakilir) |
//+------------------------------------------------------------------+
bool HtfSync(const bool force)
  {
   bool any = false;
   for(int i=0;i<NHTF;i++)
      if(g_htf[i]!=NULL)
        {
         any = true;
         break;
        }
   if(!any || gTotal<=0)
      return(false);

   int visL,visR;
   GetVisibleRange(visL,visR);
   int margin = MathMax(visR-visL+1,200);

   if(!force && htfSyncValid && visL>=htfSyncL+margin/2 && visR<=htfSyncR-margin/2)
      return(false);

   htfSyncValid = true;
   htfSyncL     = visL-margin;
   htfSyncR     = visR+margin;

   // ana grafik bar index'i -> zaman (sol kenar / sag kenar)
   datetime tL = 0;
   int shL = gTotal-1-htfSyncL;
   if(shL<=gTotal-1)
      tL = iTime(_Symbol,_Period,MathMax(0,shL));
   datetime tR = (datetime)4102444800;     // 2100: sag kenar son barin otesindeyse sinirsiz
   int shR = gTotal-1-htfSyncR;
   if(shR>=0)
     {
      tR = iTime(_Symbol,_Period,shR);
      if(tR<=0)
         tR = (datetime)4102444800;
     }

   for(int e=0;e<NHTF;e++)
     {
      CHtfEngine *en = g_htf[e];
      if(en==NULL)
         continue;
      bool on = (htfOn[e] && htfAvail[e]);
      if(!on && !en.anyObj)
         continue;

      int nz = ArraySize(en.zones);
      for(int k=0;k<nz;k++)
        {
         bool want = false;
         if(on)
           {
            want = (en.zones[k].timeC1<=tR && (en.zones[k].timeEnd+en.zones[k].tfSec)>=tL);
            if(want && HtfUseFilters && !ZonePasses(en.zones[k]))
               want = false;
           }
         if(want)
           {
            if(!en.zones[k].hasObj || en.zones[k].dirty)
              {
               RenderZoneHtf(en.zones[k],e);
               en.zones[k].hasObj = true;
               en.zones[k].dirty  = false;
              }
           }
         else if(en.zones[k].hasObj)
           {
            DeleteZoneObjects(en.zones[k]);
            en.zones[k].hasObj = false;
           }
        }
      en.anyObj = on;
     }
   EntrySync(tL,tR);          // V1.47: giris sinyalleri
   return(true);
  }

void OnTimer()
  {
   HtfOnTimer();
   OptOnTimer();       // V1.51
  }

//+------------------------------------------------------------------+
//| Kaufman Adaptive Moving Average                                  |
//|  ER  = |C[i]-C[i-n]| / sum(|C[k]-C[k-1]|, n bar)                  |
//|  SC  = (ER*(fastSC-slowSC)+slowSC)^2                             |
//|  AMA = AMA[onceki] + SC*(C[i]-AMA[onceki])                       |
//+------------------------------------------------------------------+
void CalcAMA(const int rates_total,const int prev_calculated,const double &close[])
  {
   int    per = MathMax(1,AMAPeriod);
   double fsc = 2.0/(MathMax(1,AMAFastEMA)+1.0);
   double ssc = 2.0/(MathMax(1,AMASlowEMA)+1.0);

   if(rates_total<=per)
     {
      for(int k=0;k<rates_total;k++)
         AMABuf[k] = EMPTY_VALUE;
      return;
     }

   int start;
   if(prev_calculated==0)
     {
      for(int k=0;k<per-1;k++)
         AMABuf[k] = EMPTY_VALUE;
      AMABuf[per-1] = close[per-1];
      start = per;
     }
   else
      start = MathMax(per,prev_calculated-1);

   for(int i=start;i<rates_total;i++)
     {
      double signal = MathAbs(close[i]-close[i-per]);
      double noise  = 0.0;
      for(int k=0;k<per;k++)
         noise += MathAbs(close[i-k]-close[i-k-1]);
      double er = (noise!=0.0) ? signal/noise : 0.0;
      double sc = er*(fsc-ssc)+ssc;
      sc = sc*sc;
      AMABuf[i] = AMABuf[i-1]+sc*(close[i]-AMABuf[i-1]);
     }
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

   CalcAMA(rates_total,prev_calculated,close);   // Adaptive Moving Average

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
      HtfOnFullCalc();         // V1.45: nesneler silindi -> HTF bayraklarini sifirla
     }

   //--- Son islenecek bar: mum kapanisi bekleniyorsa olusmakta olan mumu (rates_total-1) atla
   int lastBar = WaitForCandleClose ? rates_total-2 : rates_total-1;
   if(lastBar<firstBar)
      return(rates_total);

   gTotal = rates_total;
   MirrorUpdate(prev_calculated,rates_total,time,open,high,low,close);   // V1.47
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

         // V1.43: ust siniri FVG boslugunun ZoneFvgPct noktasina cek
         // (bosluk: 0 = 1. mum tepesi, 100 = 3. mum dibi)
         zTop = NormalizeDouble(zTop + FvgPctClamp()*(low[c3]-high[c1]),_Digits);

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
         z.tfSec       = 0;          // V1.45: ana grafik bolgesi
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
         z.openFvg     = CountOpenFVG(high,low,z.fvgIdx,OpenFvgLookback,z.isDemand,z.top,z.bottom);   // V1.38: bir kez
         UpdateCandleInfo(z,open,high,low,close,rates_total-2);

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

         // V1.43: alt siniri FVG boslugunun ZoneFvgPct noktasina cek
         // (bosluk: 0 = 1. mum dibi, 100 = 3. mum tepesi)
         zBottom = NormalizeDouble(zBottom - FvgPctClamp()*(low[c1]-high[c3]),_Digits);

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
         z.tfSec       = 0;          // V1.45: ana grafik bolgesi
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
         z.openFvg     = CountOpenFVG(high,low,z.fvgIdx,OpenFvgLookback,z.isDemand,z.top,z.bottom);   // V1.38: bir kez
         UpdateCandleInfo(z,open,high,low,close,rates_total-2);

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
      if(UpdateCandleInfo(zones[m],open,high,low,close,rates_total-2))
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
         if(!zones[k].trackDone && UpdateOutcome(zones[k],high,low,close,rates_total-2))
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
         // V1.28: temas ARD penceresi bitmeden olduysa ARD sizinti olur -> iptal
         if(hitIndex <= SeqLastIdx(zones[k]))
            zones[k].seq = false;
         zones[k].timeTouch   = time[hitIndex];
         zones[k].outLast     = hitIndex-1;
         UpdateOutcome(zones[k],high,low,close,rates_total-2);
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

   bool htfCh = HtfUpdateAll();   // V1.45: acik HTF motorlarini guncelle
   if(EntryUpdate())              // V1.47: giris sinyallerini tara / takip et
      htfCh = true;
   RefreshTables(changed || htfCh);

   return(rates_total);
  }
//+------------------------------------------------------------------+
