-- | The itinerary source of truth. Edit THIS file, then run
-- tools/apply-schedule.sh to regenerate the DAYS/NIGHTS blocks in
-- index.html (and bump the SW cache). Generated initially from the
-- page by tools/gen-schedule-hs.py; owned by hand from then on.
module Schedule (Card, Stay (..), days, nights, deadlines, stays) where

-- (field, value) pairs in page order: cls, label, label_ja, detail, detail_ja
type Card = [(String, String)]

days :: [(String, Card)]
days =
  [ ( "2026-07-27"
    , [ ("cls", "flight")
      , ("label", "DEPART BOS")
      , ("label_ja", "ボストン発")
      , ("detail", "13:15 JL007 Boston (Logan, Term. E) → Tokyo Narita. Arrive NRT 16:00 the next day (28th).")
      , ("detail_ja", "13:15 JL007 ボストン（ローガン空港 ターミナルE）→ 東京・成田。翌7/28 16:00 に成田着。")
      ] )
  , ( "2026-07-28"
    , [ ("cls", "tokyo")
      , ("label", "Arrive · Moti ✓")
      , ("label_ja", "到着・モティ✓")
      , ("detail", "<b>Purpose:</b> land + connect + sleep. JL007 → NRT T2 ~16:00 → Sakura → QR <b>698004</b> → Suica → do-c. <b>Foot / subway only</b> (no bike). Stay up to ~22–23:00. <b>Dinner: Moti 六本木 ✓</b> — keema mutter current + naan + mixed pickles (repeat) · mutton biryani amazing but too much solo · next: carrot dessert · default-dinner candidate. Sleep plan: ☰ Sleep / jet lag. <b>do-c gap:</b> out 11:00 / in 15:00 · bags at desk · cash+ID in Patagonia Atom sling.")
      , ("detail_ja", "<b>目的：</b>到着・回線。徒歩／地下鉄のみ。<b>夕食：モティ✓</b>（キーママター＋ナン＋ピクルス／ビリヤニ多め／次はキャロット）。do-c アウト11・イン15。")
      ] )
  , ( "2026-07-29"
    , [ ("cls", "tokyo")
      , ("label", "Akiba browse · Shinjuku mapo · Moti")
      , ("label_ja", "新宿麻婆·モティ（秋葉は下見）")
      , ("detail", "<b>Option C holds: browse today, buy tomorrow with bike + 50L.</b> <b>Remaining order:</b> MUJI, then Isetan last (closes 20:00), then Akiba browse, then Moti. <b>⚠ THE 50L IS IN AN EBISU STN COIN LOCKER</b> (in at the 11:00–15:00 do-c clean-out) — <b>collect it tonight</b>: lockers bill by calendar day, and the <b>09:30 bike pickup on 30 Jul depends on having it</b>. Buy-if-light OK: small MUJI detergent · light envelopes. Initial D mapo from <b>8/1</b> only. <b>Skip Asakusa today</b> — tail + Benizuru 7am shop tickets + Iyoshi.<br>① <b>Breakfast — West Georgia St. does not exist.</b> Walked to 恵比寿南2-3-15 OKA7ビル3F: no such shop. Treat as closed. <b>EBISU FOOD HALL instead ✓</b> — 恵比寿南1-1-9 シマヤビル1F · ~2 min from Ebisu Stn · from 9:00. <b>Would repeat</b> — food good not remarkable, but strong AC and a chill room, easy solo.<br>② <b>Dollar Ranger ✓ DONE</b> — foreign-currency exchange (not packing/sundries; that note was wrong). <b>160.55 JPY/USD · ¥802,750 for $5,000 · no commission.</b> Mid-market 161.8, so a 1.25 yen spread = <b>0.77%</b> — street counters run 2–4% and airports 5–8%. Best-rate reputation now <b>verified</b>, not repeated.<br>③ <b>Isetan ✓ DONE</b> — Diptyque browsed and <b>the mens scent is a yes</b>. <b>LOCKED: 8 bottles, bought 30 Jul</b> on the Shinjuku dinner return with the 50L (~3.5–4 kg, too heavy for tonight). <b>Mens wallets confirmed present ✓</b> — <b>closer look 30 Jul</b>, main building + 伊勢丹メンズ館. <b>Ask for 印傳屋 / 甲州印伝 by name</b>: Mitsukoshi-Isetan stocks Indenya including <b>Isetan-exclusive patterns</b>. Deerskin with lacquer, a Kofu craft — the answer to not wanting an expensive wallet for its own sake. 印傳屋 上原勇七 is the 総本家; 印傳の山本 is a different inden house, so name the maker.<br>④ <b>Kinokuniya — ERRAND FAILED ✗</b> okozukai / ポチ袋 <b>not stocked</b>, walked it. It is a bookstore; stationery is pens and notebooks. <b>Do not route here for envelopes.</b><br>⑤ <b>Kagaya ✓ DONE — and the taste test settled it: Seven Stars wins.</b> The Peace 10-pack was bought instead of the tin, tried, and <b>the tin is CANCELLED</b> — no return visit. Seven Stars is a konbini staple, buyable anywhere. The ¥600 test just saved a tin-sized mistake.<br>⑥ <b>MUJI confirmed: 無印良品 新宿通り</b> — 新宿3-17-1 いさみやビル B1-3F · <b>10:00–21:00 daily</b> · detergent is <b>B1, 掃除・洗濯用品</b> · same block as Kinokuniya (3-17-7). <b>NOT Lumine</b> (opens 11:00).<br>⑦ <b>Lunch ✓ DONE: 陳麻婆豆腐 新宿野村 B2F</b> — <b>very good, noteworthy.</b><br><b>Shoes CLOSED (was ⑨) ✗</b> — skipped, current shoes are fine; the real need was socks, <b>✓ done at the Akiba Uniqlo</b>. For the record: <b>GRAND STAGE ルミネエスト新宿</b> (east exit, 11:00–21:00) is the large-format branch that carries US12 ≈ JP30, should shoes ever come back.<br>⑧ <b>Akiba Yodobashi ✓ WALKED — both target items ABSENT.</b> <b>No SXC-1</b> and <b>no White Wings</b> in the store. The browse/buy split is therefore moot: there was nothing to defer. <b>Wins anyway:</b> the building has a <b>Daiso</b> (ポチ袋 <b>✓ DONE</b> — closes the envelope errand Kinokuniya failed) and a <b>Uniqlo</b> (<b>socks ✓ DONE</b>). <b>⚠ Consequence: tomorrow has no reason to return to Akiba</b> — see 30 Jul. If the two items are still wanted they need a different kind of shop: instruments (Ishibashi / Shimamura) for the Casio, a specialist hobby shop for the gliders. <b>Note the pattern</b> — West Georgia, Dollar Ranger and now these two all came from the same source.<br>⑩ <b>Dinner LOCKED: Moti 六本木</b> — <b>Hibiya Line runs Akihabara→Roppongi DIRECT, no transfer.</b> keema mutter + naan + mixed pickles · carrot dessert · <b>no other curries</b>.<br><b>Closed out:</b> <b>packing materials was never a real errand</b> — it was an artifact of the wrong \"cheap packing/sundries\" note on Dollar Ranger. Deleted, not re-homed. <b>ポチ袋: buy anywhere</b>, sold widely — no special trip, no Origami Kaikan detour. <b>Tonight the only hard item is the 50L from the Ebisu locker</b>; socks and everything else can slide.")
      , ("detail_ja", "<b>オプションC継続：今日は下見、明日 自転車+50Lで購入。</b> <b>残りの順序：</b>無印 → 伊勢丹（新宿最後・20時閉店）→ 秋葉下見 → モティ。<b>⚠ 50Lは恵比寿駅のコインロッカー</b>（11:00〜15:00の清掃時間で預入）— <b>今夜必ず回収</b>：ロッカーは暦日課金、かつ<b>7/30 09:30の自転車受取に必要</b>。<br>① 朝食：West Georgia St.は存在せず → <b>EBISU FOOD HALL ✓</b>（恵比寿南1-1-9・駅2分・9時〜）。再訪あり。<br>② <b>ダラーレンジャー ✓完了</b> — 外貨両替（梱包材の店ではない）。<b>160.55円/ドル・5,000ドルで802,750円・手数料なし</b>。仲値161.8に対しスプレッド1.25円＝<b>0.77%</b>（街中2〜4%・空港5〜8%）。好レートを<b>実地で確認</b>。<br>③ <b>伊勢丹 ✓完了</b> — ディプティックのメンズは好感触。<b>確定：8本を7/30に購入</b>（新宿夕食時・50L使用／約3.5〜4kg）。<b>紳士財布あり ✓</b> — 7/30に本腰（本館＋メンズ館）。<br>④ <b>紀伊國屋 ✗ 失敗</b> — ポチ袋の取扱なし（実地確認）。書店であり文具はペン・ノート。<b>ポチ袋目当てで来ない。</b><br>⑤ <b>かがや ✓完了 — 試し買いの結論：セブンスターの勝ち。</b>缶ピースは<b>中止</b>・再訪不要（セブンスターはコンビニで可）。10本入りの試し買いが正解だった。<br>⑥ <b>無印良品 新宿通り</b>（新宿3-17-1 いさみやビル B1-3F・10:00〜21:00）· 洗剤は<b>B1 掃除・洗濯用品</b>· 紀伊國屋と同ブロック。<b>ルミネ店ではない</b>（11時開店）。<br>⑦ <b>昼 ✓完了：陳麻婆豆腐 新宿野村 B2F</b> — <b>とても良い。</b><br><b>靴は完了扱い（旧⑨）✗</b> — 見送り・今の靴で十分。実需は靴下で<b>秋葉のユニクロで✓完了</b>。参考：GRAND STAGE ルミネエスト新宿（東口・11:00〜21:00）が30cm対応の大型店。<br>⑧ <b>秋葉ヨドバシ ✓実地 — 目当ての2点とも在庫なし</b>（SXC-1なし・ホワイトウイングスなし）。下見／購入の切り分けは無意味だった。<b>収穫：</b>同ビルの<b>ダイソー</b>でポチ袋 <b>✓完了</b>（紀伊國屋の失敗を解消）、<b>ユニクロ</b>で靴下 <b>✓完了</b>。<b>⚠ 明日、秋葉に戻る理由は消滅</b>。2点が必要なら楽器店（イシバシ／島村）・専門ホビー店へ。<br>⑩ <b>夕食確定：モティ六本木</b> — <b>日比谷線で秋葉原→六本木は直通・乗換なし。</b><br><b>整理：</b><b>梱包材はそもそも不要</b>（ダラーレンジャーの誤記述の名残・削除）。<b>ポチ袋はどこでも買える</b>ので専用の寄り道なし。<b>今夜の必須は恵比寿ロッカーの50Lのみ。</b>")
      ] )
  , ( "2026-07-30"
    , [ ("cls", "tokyo")
      , ("label", "Wallets ×8 done · loop cut (heat)")
      , ("label_ja", "財布×8完了・猛暑で一周中止")
      , ("detail", "<b>How it went:</b> the Yamanote loop was <b>cancelled for heat</b> (~35°C) — still ~40 km ridden across town on the Wabash, returned on time. <b>Wallets ✓ COMPLETE — final count 8, none for the owner</b> (8 relatives): Motherhouse <b>恵比寿メンズ 3</b> · <b>小田急新宿メンズ（ハルク2F）4</b> · <b>本店 1</b>. Laundry ✓ WASH&DRY 代官山, bag stored at do-c. Moti skipped — 7-11 dinner (natto · onigiri · umeboshi) and an early night for the <b>31 Jul Nozomi, Shinagawa 09:37</b>.")
      , ("detail_ja", "<b>実際：</b>猛暑（約35°C）で山手一周は<b>中止</b> — それでも都内を約40km走行し定刻返却。<b>財布 ✓ 完了 — 計8点（自分用なし）</b>：恵比寿メンズ3・小田急新宿メンズ（ハルク2F）4・本店1。洗濯 ✓ WASH&DRY代官山。モティは見送り、セブンイレブンの夕食（納豆・おにぎり・梅干し）で早めに就寝 — 翌朝はのぞみ品川9:37。")
      ] )
  , ( "2026-07-31"
    , [ ("cls", "cap")
      , ("label", "→ Hakata")
      , ("label_ja", "博多へ")
      , ("detail", "<b>Purpose:</b> Kyushu. <b>No bike.</b> Shinagawa · <b>Nozomi 21 09:37</b> → Hakata <b>14:30</b> · Car 16 (rear) Seat 3-C · <b>QR ticket — screenshot it before the gate</b>.<br>① <b>9h check-in first</b> (博多駅前3-22-2 · from 15:00) — <b>ask the desk where to park overnight</b> (最大料金 coin lot) · drop both bags: the small case from Uncle Kenji + the 50L · carry the Atom sling with <b>passport (landing stamp) · IDP · license</b>.<br>② <b>Toyota 15:30</b> — <b>⚠ confirm the reservation is 博多駅前店, 博多駅東1-12-8</b> (092-441-0100; two similarly named Hakata branches carry operator-change labels — do NOT go to 博多駅博多口店 at 博多駅前1-15-20) → drive straight back and <b>park near 9h</b> at the lot the desk named.<br>③ Shower at 9h if wanted → <b>subway to Tenjin</b> (空港線 · 5 min): eat there · <b>DIPTYQUE 福岡 walk-in</b> — 天神2-8-35 (天神住友生命FJビジネスセンター1F) · 11:00–20:00 · 092-406-0280 · <b>no set-aside call, taking the walk-in odds</b> · fallback: any Fukuoka day before 23 Aug → subway back to 9h.<br>④ Rest — the ~40 km ride in yesterday’s heat left some congestion: fluids + the 7-11 <b>ミネラルin gels</b> (Fe·Ca·Zn·Cu·Mg, some ~33% DV · ×3 bought · restock at Kyushu 7-11s). <i>Owner:</i> R9 Kanzaki free cancel ends <b>tonight 23:59</b>.<br><b>🚗 Parked ✓ — Kawasoe Parking (川添パーキング)</b> · <a href=\"https://maps.app.goo.gl/UUoHvRkuMWZsK15w8\" target=\"_blank\" rel=\"noopener\">map pin</a> · weekday 300¥/20 min · Sat/Sun/hol 200¥/30 min · <b>night 20:00–08:00 max ¥500</b> · pay at the central machine <b>before</b> getting in — flap lowers, then <b>exit within 3 min</b> (it re-locks) · parked >24 h → settle once mid-stay · lot takes no responsibility; breakdown: Autex 24 · 092-437-5611.")
      , ("detail_ja", "<b>目的：</b>九州へ。<b>自転車なし。</b>のぞみ21 09:37 → 博多14:30（16号車3-C・<b>QR乗車 — 事前にスクショ</b>）。<br>①まず<b>9hチェックイン</b>（博多駅前3-22-2・15時〜）— <b>夜間駐車場をフロントに相談</b>（最大料金のコインP）・荷物2つ（ケンジ叔父さんの小型ケース＋50L）を預け、アトムのスリングに<b>パスポート・国際免許・免許証</b>を携行。<br>②<b>トヨタ15:30</b>（⚠ 予約店舗は博多駅前店・博多駅東1-12-8。博多口店と間違えない）→ そのまま戻って<b>9h近くに駐車</b>。<br>③シャワー後、<b>地下鉄で天神へ</b>（空港線5分）：天神で食事＋<b>ディプティック福岡</b>（天神2-8-35・11〜20時・<b>電話なしで直接</b>・〜8/23の別日でも可）→ 9hへ戻る。<br>④休養 — 昨日の猛暑40kmで鼻づまり気味：水分＋セブンの<b>ミネラルinゼリー</b>（鉄・Ca・亜鉛・銅・Mg・×3購入、九州のセブンで補充）。<i>オーナー：</i>R9神埼の無料キャンセルは<b>今夜23:59まで</b>。<br><b>🚗 駐車済 — 川添パーキング</b>・<a href=\"https://maps.app.goo.gl/UUoHvRkuMWZsK15w8\" target=\"_blank\" rel=\"noopener\">地図</a>・平日300円/20分・土日祝200円/30分・<b>夜間20:00〜08:00 最大500円</b>・先に精算→フラップが下がったら<b>3分以内に出庫</b>（再ロック注意）・24時間超は途中精算・故障時: オーテックス24 092-437-5611。")
      ] )
  , ( "2026-08-01"
    , [ ("cls", "kanzaki")
      , ("label", "→ Mika’s")
      , ("label_ja", "Mika宅へ")
      , ("detail", "<b>~05:00 drive out</b> (Kawasoe Parking: pay at the machine first → flap lowers → out within 3 min; night max ¥500 covers to 08:00) → Kanzaki to meet Mika & Kentaro · <a href=\"https://maps.app.goo.gl/4LcQj1zo7k93ELn96\" target=\"_blank\" rel=\"noopener\">route</a>.<br>Drive rental car Hakata → Kanzaki. Stay at cousin Mika & husband Kentaro’s apartment (nights of 1–2 Aug). No night-game tournament conflict.<br><b>Pitch for the evening: 山茶花の湯 (Sazanka no Yu) with Kentaro</b> — best day-use onsen near Kanzaki, ~15 min via Rte 385 · open-air baths over the Saga plain · ¥830 · 10:00–23:00 · restaurant inside, free parking. If Kentaro has a local favorite, that wins.<br><b>Ramen for any Saga-side day: 来来亭 佐賀新栄店</b> — the rai-rai-tei from last trip (Kyoto-style shoyu · back fat · thin noodles) · 佐賀市新栄東1-4-2 · 11:00–24:00 · ~20–25 min west of Kanzaki.")
      , ("detail_ja", "<b>〜05:00出庫</b>（川添パーキング: 先に精算→3分以内に出庫・夜間最大500円）→ 神埼へ、Mika＆Kentaroと合流・<a href=\"https://maps.app.goo.gl/4LcQj1zo7k93ELn96\" target=\"_blank\" rel=\"noopener\">ルート</a>。<br>レンタカーで博多→神埼。いとこ Mika と夫 Kentaro のアパートに滞在（8/1〜2 の夜）。ナイトゲーム大会の予定なし。<br><b>夜の提案：Kentaroと山茶花の湯</b>（神埼から約15分・露天から佐賀平野・¥830・10〜23時・食事処あり）。地元のおすすめがあればそちら優先。<br><b>ラーメン（佐賀方面の日に）：来来亭 佐賀新栄店</b>（新栄東1-4-2・11〜24時・車で約20〜25分）。")
      ] )
  , ( "2026-08-02"
    , [ ("cls", "kanzaki")
      , ("label", "Kenji lunch")
      , ("label_ja", "健司さん昼食")
      , ("detail", "Lunch together at Uncle Kenji’s house (confirmed). Second night at Mika & Kentaro’s apartment.")
      , ("detail_ja", "叔父・健司さんの家で一緒に昼食（確定）。2泊目も Mika & Kentaro 宅。")
      ] )
  , ( "2026-08-03"
    , [ ("cls", "kanzaki")
      , ("label", "→ R9 Kanzaki")
      , ("label_ja", "R9 神埼へ")
      , ("detail", "Check in R9 The Yard Kanzaki — first of 5 nights (3–7 Aug). Hotel site: <a href=\"https://hotel-r9.jp/hotels/kanzaki/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/kanzaki</a><br><b>Base kit:</b> ファミリーマート神埼日の隈店 ~150 m from the door (24h · ATM at the 7-Eleven ~900 m east) · マルキョウ supermarket ~6 min drive (9:30–22) · 神埼駅 ~7 min (locals: Saga ~10 min · Hakata ~60–75 via Tosu). Cabin has a microwave, no restaurant.")
      , ("detail_ja", "R9 The Yard 神埼にチェックイン — 5泊の初日（8/3〜7）。ホテルサイト： <a href=\"https://hotel-r9.jp/hotels/kanzaki/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/kanzaki</a><br>目の前にファミマ・車6分でマルキョウ・神埼駅7分。")
      ] )
  , ( "2026-08-04"
    , [ ("cls", "kanzaki")
      , ("label", "Kanzaki")
      , ("label_ja", "神埼")
      , ("detail", "Saga — Kanzaki base (R9). Family: Kenji / Hitomi / Mika / Kentaro.<br><b>Solo fallback menu (family first — all ≤15 min):</b> 吉野ヶ里 Yayoi ruins 9:00–18:00 ¥460 · east gate · shadeless, go at 9 or after 16 · 山茶花の湯 onsen 10:00–23:00 ¥830 (open-air over the plain) · 仁比山公園 river shade + bridge ~5 min · Kanzaki somen: buy at 井上製麺 (9–17 · Wed closed · eat-in 百年庵 on hiatus) or somen set at the Yoshinogari park restaurant 10:30–16.")
      , ("detail_ja", "佐賀・神埼（R9）。家族：Kenji／Hitomi／Mika／Kentaro。<br>一人時間：吉野ヶ里・山茶花の湯・仁比山・神埼そうめん（井上製麺）。")
      ] )
  , ( "2026-08-05"
    , [ ("cls", "kanzaki")
      , ("label", "Kanzaki")
      , ("label_ja", "神埼")
      , ("detail", "Saga — Kanzaki base (R9). <i>Owner:</i> R9 Sagakashima free cancel ends <b>tonight 23:59</b> local (then cancel fee ¥10,800 of ¥74,700 stay).<br>Solo fallback → 8/4 menu.")
      , ("detail_ja", "佐賀・神埼（R9）。<i>管理者：</i>R9 佐賀鹿島の無料キャンセルは <b>今夜 23:59</b> まで（以降キャンセル料 ¥10,800／宿泊 ¥74,700）。")
      ] )
  , ( "2026-08-06"
    , [ ("cls", "kanzaki")
      , ("label", "Kanzaki")
      , ("label_ja", "神埼")
      , ("detail", "Saga — Kanzaki base (R9). Solo fallback → 8/4 menu · or a Fukuoka run: ~50–60 min by car via Rte 385 tunnel (toll), or train from 神埼駅.")
      , ("detail_ja", "佐賀・神埼（R9）。一人時間は8/4メニュー or 福岡へ（車60分／電車）。")
      ] )
  , ( "2026-08-07"
    , [ ("cls", "kanzaki")
      , ("label", "Kanzaki")
      , ("label_ja", "神埼")
      , ("detail", "Saga — Kanzaki base (R9). Last night of the R9 Kanzaki booking (checkout AM 8th). Backbone stays flexible.<br>Solo fallback → 8/4 menu.")
      , ("detail_ja", "佐賀・神埼（R9）。R9 神埼の最終泊（8日朝チェックアウト）。骨格は融通可。")
      ] )
  , ( "2026-08-08"
    , [ ("cls", "kashima")
      , ("label", "Mika day · flex")
      , ("label_ja", "Mikaと・融通日")
      , ("detail", "Mika took the day off — outing together (plan TBD). R9 Sagakashima is booked from tonight if useful; family backbone said Kanzaki area ~through 9th / Kashima ~from 9th — shuffle freely. Hotel: <a href=\"https://hotel-r9.jp/hotels/sagakashima/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/sagakashima</a><br><b>Kashima base kit:</b> スーパーモリナガ ~700 m (9:30–21) · 24h 7-Eleven + ATM ~5 min walk · 肥前鹿島駅 ~15 min walk — but only ~5 Kasasagi round trips/day to Hakata since the 2022 rerouting; the car is primary.")
      , ("detail_ja", "Mika が休み — 一緒に外出（行き先 TBD）。R9 佐賀鹿島はこの夜から予約あり。家族向け骨格は神埼〜9日／鹿島〜9日頃 — 自由にずらしてOK。ホテル： <a href=\"https://hotel-r9.jp/hotels/sagakashima/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/sagakashima</a><br>徒歩圏：モリナガ・セブン・肥前鹿島駅（本数少・車が基本）。")
      ] )
  , ( "2026-08-09"
    , [ ("cls", "kashima")
      , ("label", "Kashima ~")
      , ("label_ja", "鹿島〜")
      , ("detail", "Around here in the flexible backbone: Kashima window. Hope to see Akimasa & Yoko when it works. R9 Sagakashima base.<br>Anchor solo stop: 祐徳稲荷神社 ~10 min — one of the three great Inari, grounds open 24h (office 8:30–16:30), huge parking.")
      , ("detail_ja", "融通のきく骨格だとこのあたりから鹿島。都合のいいときにアキマサ・ようこに会えたらうれしい。拠点は R9 佐賀鹿島。<br>一人時間の軸：祐徳稲荷神社（境内24h）。")
      ] )
  , ( "2026-08-10"
    , [ ("cls", "kashima")
      , ("label", "Kashima")
      , ("label_ja", "鹿島")
      , ("detail", "Saga — Kashima base.<br><b>Solo menu:</b> 祐徳稲荷 (24h grounds · morning easiest) · 肥前浜宿 sake-brewery street ~8–10 min (info house 10–17, <b>Tue closed</b> · <b>tastings: Hizennya 光武 free walk-in 9:30–17</b> · <b>Nabeshima 鍋島 does NOT do public tastings</b> — auberge guests only, buy bottles at local shops) + 峰松うなぎ屋 next door (<b>takeaway kabayaki only — no rice, no set meals</b> · 8–18 · call 0954-62-3725 in the morning to reserve eels · grab rice from a konbini) · 道の駅鹿島 Ariake mudflats ~12 min (produce 9–18 · <b>mudflat experience ¥900, tide-slot dependent — check the calendar on michinoekikashima.jp</b> · desk 0954-60-5040 · individuals need no reservation in summer).")
      , ("detail_ja", "佐賀・鹿島に滞在。<br>一人メニュー：祐徳稲荷・肥前浜宿（試飲は光武の肥前屋・鍋島は一般試飲なし）＋峰松うなぎ（<b>持ち帰りかばやきのみ・ご飯なし</b>・午前電話予約）・道の駅鹿島（干潟体験900円・潮汐カレンダー要確認）。")
      ] )
  , ( "2026-08-11"
    , [ ("cls", "kashima")
      , ("label", "Kashima")
      , ("label_ja", "鹿島")
      , ("detail", "Saga — Kashima base. Solo menu → 8/10. Note: Hamashuku info house is closed Tuesdays (= today).")
      , ("detail_ja", "佐賀・鹿島に滞在。浜宿の案内所は火曜休（今日）。")
      ] )
  , ( "2026-08-12"
    , [ ("cls", "kashima")
      , ("label", "Kashima")
      , ("label_ja", "鹿島")
      , ("detail", "Saga — Kashima base. Solo menu → 8/10 · or an onsen run: シーボルトの湯 嬉野 ~30 min (6:00–22:00 · ¥450 · bicarbonate skin-water) / 武雄温泉 元湯 ~35–40 min (6:30–23:45 · ¥500 · oldest wooden bathhouse in Japan, 1876).")
      , ("detail_ja", "佐賀・鹿島に滞在。温泉：シーボルトの湯（嬉野）or 武雄温泉 元湯。")
      ] )
  , ( "2026-08-13"
    , [ ("cls", "kashima")
      , ("label", "Kashima · Obon")
      , ("label_ja", "鹿島・お盆")
      , ("detail", "Saga — Kashima. Obon begins. <i>Owner:</i> Obi free cancel ends <b>tonight 23:59</b> local (then full ¥36,720).<br><i>Owner:</i> before the 23:59 call, re-check Kumamoto quake recovery (7/28 M7.1 — see 8/15 card): <b>Obi House condition (ask the host directly — Higo Smile 096-223-7333, 9–18時, or Booking chat; it is a ~55-year-old wooden nagaya and its post-quake state was unverifiable online 7/29)</b> + water + roads. <b>Do not wait for 8/13 to ask — message the host well before the deadline.</b>")
      , ("detail_ja", "佐賀・鹿島。お盆の入り。<i>管理者：</i>Obi の無料キャンセルは <b>今夜 23:59</b> まで（以降全額 ¥36,720）。判断前に熊本の地震復旧（7/28 M7.1）を確認。")
      ] )
  , ( "2026-08-14"
    , [ ("cls", "kashima")
      , ("label", "Kashima · Obon")
      , ("label_ja", "鹿島・お盆")
      , ("detail", "Saga — Kashima. Obon. Last night before Kumamoto.<br>Obon peak: unagi sells out by noon, small family shops close · shrine grounds, michi-no-eki, supermarket stay open.")
      , ("detail_ja", "佐賀・鹿島に滞在。お盆。熊本へ移る前の最終日。うなぎは昼まで・小店は盆休みあり。")
      ] )
  , ( "2026-08-15"
    , [ ("cls", "kuma")
      , ("label", "→ Kumamoto")
      , ("label_ja", "熊本へ")
      , ("detail", "Drive to Kumamoto. Obi house B2 — check-in 15:00–18:00 (arrival ~15:00–16:00 approved). Smart Check-in: details arrive week-of. Narrow driveways if arriving by car. First of 8 nights (out 23 Aug AM).<br><b>⚠ Quake context (7/28 M7.1 · max 震度7 in Uki ~20 km S of the city):</b> before driving, check Obi host messages + NEXCO road info (Kyushu Expwy Ueki section was damaged) + JR app. <b>Obi contact: management Higo Smile 096-223-7333 (9:00–18:00)</b> or via Booking. Obon U-turn rush 8/15–16 — pad the drive.<br><b>Base kit:</b> 水前寺成趣園 walkable ~1.3 km · 7-Eleven 帯山4丁目 + ATM ~0.9 km (<b>⚠ 24h NOT guaranteed post-quake</b> — ~100 Kumamoto stores were closed 7/29; check Maps on arrival) · ゆめマート supermarket ~5 min drive (was quake-closed — check it reopened).")
      , ("detail_ja", "熊本へ。Obi house B2 — チェックイン 15:00〜18:00（到着 15:00〜16:00 承認済み）。スマートチェックイン：予約週に詳細が届く。車は細い道注意。8泊の初日（8/23 朝アウト）。<br><b>⚠ 7/28 地震（M7.1・宇城で震度7）</b>：出発前に Obi・道路（植木区間損傷）・JR を確認。お盆Uターン渋滞注意。")
      ] )
  , ( "2026-08-16"
    , [ ("cls", "kuma")
      , ("label", "Obon")
      , ("label_ja", "お盆")
      , ("detail", "Kumamoto base. Obon.<br><b>City menu (verify-first after the quake):</b> 水前寺成趣園 walkable · 8:30–17:00 · ¥500 · open 365 days (free in yukata this Aug) · <b>熊本城 CLOSED indefinitely</b> since the 7/28 quake — check the castle news page before going · 城彩苑 food village at the castle base 9–18 (likely open — call 096-288-5577) · ramen: 黒亭 本店 near Kumamoto Stn (<b>⚠ post-quake status unverified — call 096-352-1648 first</b>) / こむらさき 上通 11–16 LO15:30 & 18–22 LO21:30 (no closure found · 096-325-8972). 水前寺 reopened 7/30 after its safety check — reliable anchor.")
      , ("detail_ja", "熊本に滞在。お盆。<br>市内（要確認）：水前寺成趣園（徒歩圏）・<b>熊本城は当面閉園</b>・城彩苑・黒亭／こむらさき。")
      ] )
  , ( "2026-08-17"
    , [ ("cls", "kuma")
      , ("label", "Kumamoto")
      , ("label_ja", "熊本")
      , ("detail", "Kumamoto base. City menu → 8/16 · downtown arcades via tram (Suizenji-Koen stop ~1.2 km south of the house).")
      , ("detail_ja", "熊本に滞在。市内メニューは8/16参照。市電で繁華街へ。")
      ] )
  , ( "2026-08-18"
    , [ ("cls", "kuma")
      , ("label", "Day-trip*")
      , ("label_ja", "日帰り*")
      , ("detail", "Optional from Kumamoto (car, weather): <b>Aso</b> ~1.5h · <b>Kurokawa</b> ~2h · <b>Takachiho</b> ~2.5h · <b>Beppu</b> ~2–2.5h · <b>Miyazaki</b> ~3h each way (long day OK). Not booked.<br><b>⚠ Aso crater CLOSED</b> — volcanic alert Level 2 since 6/21 (1 km exclusion · toll road + shuttle suspended). Fallback trio verified 29 Jul: <b>Kusasenri</b> (free · lot ~¥500 · horse rides ~9:00–16:00, off in rain) · <b>Volcano Museum</b> (9:00–17:00, entry to 16:30 · ¥880 · open 365d · 0967-34-2111) · <b>Daikanbo</b> (free · 24h · teahouse 8:30–17:00 · ~15 min walk from parking). Morning-of: aso-volcano.jp + JMA typhoon page · skip mountain roads in any rain (quake-loosened slopes).")
      , ("detail_ja", "熊本から任意（車・天候）：<b>阿蘇</b> 約1.5h · <b>黒川</b> 約2h · <b>高千穂</b> 約2.5h · <b>別府</b> 約2〜2.5h · <b>宮崎</b> 片道約3h（ロングデー可）。未予約。<br><b>⚠ 阿蘇中岳は警戒レベル2で火口規制中</b>（代替3点は7/29確認済：草千里〈無料・駐車~500円・乗馬~16時〉・火山博物館〈9-17時・880円・年中無休〉・大観峰〈無料・茶店8:30-17時〉）。朝に aso-volcano.jp と台風情報を確認。")
      ] )
  , ( "2026-08-19"
    , [ ("cls", "kuma")
      , ("label", "Rest*")
      , ("label_ja", "休養*")
      , ("detail", "Flex / rest — or swap any day-trip from the menu (Aso / Kurokawa / Takachiho / Beppu / Miyazaki).")
      , ("detail_ja", "休養 or 日帰り候補の入れ替え（阿蘇／黒川／高千穂／別府／宮崎）。")
      ] )
  , ( "2026-08-20"
    , [ ("cls", "kuma")
      , ("label", "Day-trip*")
      , ("label_ja", "日帰り*")
      , ("detail", "Same optional menu. <i>Owner:</i> aim to submit <b>Sakura cancel</b> in My Page around now (by <b>25 Aug</b> for end 31 Aug).")
      , ("detail_ja", "同・日帰り候補。<i>管理者：</i>この頃に <b>Sakura 解約</b>申請（<b>8/25</b> まで → 8/31 終了）。")
      ] )
  , ( "2026-08-21"
    , [ ("cls", "kuma")
      , ("label", "Day-trip*")
      , ("label_ja", "日帰り*")
      , ("detail", "Optional long drive day (e.g. Miyazaki coast) or onsen (Kurokawa/Beppu). Weather-dependent — check the JMA typhoon page + quake road status before committing to mountain routes.")
      , ("detail_ja", "ロングドライブ（例：宮崎）or 温泉（黒川／別府）。天候次第 — 台風・道路状況を確認。")
      ] )
  , ( "2026-08-22"
    , [ ("cls", "kuma")
      , ("label", "Kumamoto")
      , ("label_ja", "熊本")
      , ("detail", "Repack — last night. <i>Owner:</i> last days for Sakura cancel-by-25 if not done.")
      , ("detail_ja", "荷造り — 最終泊。<i>管理者：</i>Sakura 解約 8/25 まで。")
      ] )
  , ( "2026-08-23"
    , [ ("cls", "cap")
      , ("label", "→ Hakata")
      , ("label_ja", "博多へ")
      , ("detail", "Check out AM → Hakata → return Toyota by <b>20:00</b>. Overnight 9h Hakata. Dinner flexible: Chinese, French, or shameless <b>Saizeriya — pinned branch: キャナルシティ博多 North Bldg 1F</b> (住吉1-2-1 · 10:00–23:00 · ~12–15 min walk from 9h · none inside Hakata Stn itself). Fukuoka has strong Chinese + yatai too.")
      , ("detail_ja", "午前アウト→博多→車20:00返却。9h 博多。夕食：中華・フレンチ or 本気の<b>サイゼリヤ（キャナルシティ博多ノースビル1F・10-23時・9hから徒歩12-15分・駅構内に店舗なし）</b>。")
      ] )
  , ( "2026-08-24"
    , [ ("cls", "tokyo")
      , ("label", "Wabash pickup 1/4")
      , ("label_ja", "Wabash受取 1/4")
      , ("detail", "<b>Purpose:</b> start res <b>2607-212</b> (4-day). Nozomi 18 → Shinagawa 14:25 → do-c → CycleTrip ~15:30–17:00. Same <b>WABASH RT L</b>. Bike ¥34,000 + <b>deposit ¥100,000</b> (cash refund faster). If train late vs 17:30, morning 25th.")
      , ("detail_ja", "<b>目的：</b>予約 2607-212 開始。品川14:25→do-c→CycleTrip。保証金 ¥100,000。")
      ] )
  , ( "2026-08-25"
    , [ ("cls", "tokyo")
      , ("label", "Wabash day 2/4")
      , ("label_ja", "Wabash 2/4")
      , ("detail", "<b>Purpose:</b> more Tokyo on the bike (front Yamanote already done 30 Jul). Optional second loop or easy miles. <b>Route ref:</b> <a href=\"https://maps.app.goo.gl/ZuNKJTLa8C9Rr5G8A\" target=\"_blank\" rel=\"noopener\">Maps</a>. Breakfast: Ivy Place / EBISU FOOD HALL / konbini (West Georgia St. does not exist — confirmed 29 Jul). Battery at do-c if removable.")
      , ("detail_ja", "<b>目的：</b>東京サイクリング（山手は7/30済）。任意で再一周。")
      ] )
  , ( "2026-08-26"
    , [ ("cls", "tokyo")
      , ("label", "Yokohama · errands")
      , ("label_ja", "横浜・用事")
      , ("detail", "<b>Purpose:</b> Yokohama Chinatown (bike or train). <b>⚠ 備深酒家 Bishin Shuka is CLOSED Wednesdays — 26 Aug is a Wednesday.</b> If the tofu-flower mapo matters, swap Yokohama onto 25 Aug instead; otherwise <b>must-try today: 丿貫 Hechikan</b> Kannai — shrimp-miso ultra-thick cold tsukemen · 11:00–15:00 / 17:00–22:00 · Maps: 丿貫 福富町. <b>Alt Chin:</b> 頭文字D collab mapo at 陳麻婆 みなとみらい (11:00–22:00) or 市役所ラクシス (¥1,680 · card · through 31 Oct). Also Tokki/Kyokarou if energy. Last full free day before Narita.")
      , ("detail_ja", "<b>目的：</b>横浜（自転車or電車）。<b>⚠ 備深酒家は水曜定休 — 8/26は水曜。</b>豆花麻婆が本命なら横浜は8/25に入替。今日は<b>丿貫（福富町）</b>のエビ味噌冷つけ（11〜15時/17〜22時）or <b>陳麻婆 頭文字Dコラボ</b>（みなとみらい11〜22時）。成田前最後の自由日。")
      ] )
  , ( "2026-08-27"
    , [ ("cls", "cap")
      , ("label", "Return bike · NRT")
      , ("label_ja", "返却・成田")
      , ("detail", "<b>Purpose:</b> return res <b>2607-212</b> by ~17:00–17:15 → dinner → 9h Narita. Deposit refund if bike OK. <b>Peace cans</b> already bought (26th) — pack sealed for cabin/checked per airline rules.")
      , ("detail_ja", "<b>目的：</b>2607-212 返却 ~17:00–17:15 → 夕食 → 成田9h。ピースは前日購入済みで梱包。")
      ] )
  , ( "2026-08-28"
    , [ ("cls", "flight")
      , ("label", "DEPART NRT")
      , ("label_ja", "成田発")
      , ("detail", "<b>Purpose:</b> fly home, no rush. 9h out 10:00. Security when ready → <b>JAL lounge</b> → <b>JL008 18:25</b> T2.")
      , ("detail_ja", "<b>目的：</b>帰国・急がない。10:00アウト → ラウンジ → JL008 18:25。")
      ] )
  ]

-- (first night, last night, name EN, name JA)
nights :: [(String, String, String, String)]
nights =
  [ ("2026-07-28", "2026-07-30", "do-c Ebisu, Tokyo", "do-c 恵比寿（東京）")
  , ("2026-07-31", "2026-07-31", "9h Hakata", "9h 博多")
  , ("2026-08-01", "2026-08-02", "Mika & Kentaro's apartment, Kanzaki", "Mika & Kentaro 宅（神埼）")
  , ("2026-08-03", "2026-08-07", "R9 The Yard Kanzaki", "R9 The Yard 神埼")
  , ("2026-08-08", "2026-08-14", "R9 Sagakashima", "R9 佐賀鹿島")
  , ("2026-08-15", "2026-08-22", "Obi house, Kumamoto", "Obi house（熊本）")
  , ("2026-08-23", "2026-08-23", "9h Hakata", "9h 博多")
  , ("2026-08-24", "2026-08-26", "do-c Ebisu, Tokyo", "do-c 恵比寿（東京）")
  , ("2026-08-27", "2026-08-27", "9h Narita Airport", "9h 成田空港")
  ]

-- Hard deadlines: (date, "HH:MM" or "" for all-day, EN, JA).
-- The kernel validates them, Ics.hs exports them as calendar events
-- with phone alarms, and NowNext.hs surfaces today's + tomorrow's in
-- the Right now λ panel. Harvested from the day cards' Owner: notes;
-- keep in date order.
deadlines :: [(String, String, String, String)]
deadlines =
  [ ("2026-07-31", "23:59", "R9 Kanzaki free cancel ends", "R9神埼 無料キャンセル期限")
  , ("2026-08-05", "23:59", "R9 Sagakashima free cancel ends (then ¥10,800 fee)", "R9佐賀鹿島 無料キャンセル期限（以降¥10,800）")
  , ("2026-08-13", "23:59", "Obi minshuku free cancel ends (then full ¥36,720)", "民宿おび 無料キャンセル期限（以降全額¥36,720）")
  , ("2026-08-23", "20:00", "Return Toyota (Hakata-Ekimae) by 20:00", "トヨタレンタカー返却 20:00まで")
  , ("2026-08-25", "", "Sakura Mobile: submit cancel in My Page (for Aug 31 end)", "Sakura Mobile 解約申請（8/31解約分）")
  ]

-- The lodging table, typed. Rendered to the #lodging tbody (EN inline,
-- data-i18n attrs) plus a generated LODGING_I18N dict for the JA side —
-- see EmitLodging.hs. Row order must match `nights`; the kernel checks
-- the night counts agree. HTML in the prop/price cells is authored
-- content, emitted verbatim.
data Stay = Stay
  { stKey :: String -- i18n suffix: lo.dt<key> / lo.prop<key> / lo.pr<key>
  , stDatesEn, stDatesJa :: String
  , stNt :: Int
  , stPropEn, stPropJa :: String
  , stPhone :: Maybe String
  , stPriceEn, stPriceJa :: String -- owner-only cell
  }

stays :: [Stay]
stays =
  [ Stay
      { stKey = "1"
      , stDatesEn = "28–30 Jul"
      , stDatesJa = "7/28〜30"
      , stNt = 3
      , stPropEn = "<b>do-c Ebisu</b><br>1-8-1 Ebisu, Shibuya-ku, Tokyo<br><i>out 11:00 · in 15:00 · overnight bag store OK across a multi-night stay · <b>⚠ the 11:00–15:00 clean-out tightened (observed Jul 2026, unconfirmed): bags used to be fine parked anywhere outside a locker during the gap, now it reads as take-it-with-you. Working answer: collect the bag and use an Ebisu Stn coin locker for the gap (done 29 Jul)</b> · cash+ID on person (Patagonia Atom sling)</i>"
      , stPropJa = "<b>do-c 恵比寿</b><br>東京都渋谷区恵比寿1-8-1<br><i>アウト11:00 · イン15:00 · 連泊中の荷物保管は可 · <b>⚠ 11:00〜15:00の清掃時間の扱いが厳格化した様子（2026年7月・未確認）：以前はロッカー外に置いておけたが、現在は持ち出し案内に見える。対応：荷物を引き取り恵比寿駅コインロッカーへ（7/29実施）</b> · 現金・身分証は身につけ（Patagonia Atomスリング）</i>"
      , stPhone = Just "+81 50-1807-2324"
      , stPriceEn = "advance-pay"
      , stPriceJa = "事前決済"
      }
  , Stay
      { stKey = "2"
      , stDatesEn = "31 Jul"
      , stDatesJa = "7/31"
      , stNt = 1
      , stPropEn = "<b>9h nine hours Hakata</b><br>3-22-2 Hakataekimae, Hakata-ku, Fukuoka (Hakata Stn)<br><i>Toyota car pickup same day 15:30 — Hakata Station Shop, 1-12-8 Hakataeki Higashi</i><br><i>Overnight: coin parking Hakataekimae / Gion (no lot at 9h)</i>"
      , stPropJa = "<b>9h ナインアワーズ博多</b><br>福岡市博多区博多駅前3-22-2（博多駅そば）<br><i>同日 15:30 トヨタレンタカー博多駅店で受け取り — 博多駅東1-12-8</i><br><i>夜：博多駅前／祇園のコインパーキング（9h に駐車場なし）</i>"
      , stPhone = Just "+81 50-1807-3481"
      , stPriceEn = "Fri rate (low)"
      , stPriceJa = "金曜料金（安め）"
      }
  , Stay
      { stKey = "3"
      , stDatesEn = "1–2 Aug"
      , stDatesJa = "8/1〜2"
      , stNt = 2
      , stPropEn = "<b>Mika &amp; Kentaro’s apartment</b><br>Kanzaki area, Saga (address TBD)"
      , stPropJa = "<b>Mika &amp; Kentaro 宅</b><br>佐賀・神埼エリア（住所 未定）"
      , stPhone = Nothing
      , stPriceEn = "family stay"
      , stPriceJa = "家族宅"
      }
  , Stay
      { stKey = "3b"
      , stDatesEn = "3–7 Aug"
      , stDatesJa = "8/3〜7"
      , stNt = 5
      , stPropEn = "<b>R9 The Yard Kanzaki</b><br>4155-54 Osaki, Kanzaki-machi, Kanzaki, Saga<br><a href=\"https://hotel-r9.jp/hotels/kanzaki/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/kanzaki</a>"
      , stPropJa = "<b>R9 The Yard 神埼</b><br>佐賀県神埼市神埼町尾崎4155-54<br><a href=\"https://hotel-r9.jp/hotels/kanzaki/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/kanzaki</a>"
      , stPhone = Just "+81 952-20-3642"
      , stPriceEn = "✓ rebooked 3–7 Aug<br>free to <b>31 Jul 23:59</b> Kanzaki time<br>(then ¥6,237)"
      , stPriceJa = "✓ 8/3〜7 に変更済み<br><b>7/31 23:59</b> 神埼時間まで無料キャンセル<br>（以降 ¥6,237）"
      }
  , Stay
      { stKey = "4"
      , stDatesEn = "8–14 Aug"
      , stDatesJa = "8/8〜14"
      , stNt = 7
      , stPropEn = "<b>R9 The Yard Sagakashima</b><br>Nakamura 821-2, Kashima, Saga<br><a href=\"https://hotel-r9.jp/hotels/sagakashima/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/sagakashima</a><br><i>Family note: Kashima window ~9–14 Aug (flexible)</i>"
      , stPropJa = "<b>R9 The Yard 佐賀鹿島</b><br>佐賀県鹿島市中村821-2<br><a href=\"https://hotel-r9.jp/hotels/sagakashima/\" target=\"_blank\" rel=\"noopener\">hotel-r9.jp/hotels/sagakashima</a><br><i>家族向け：鹿島はだいたい 8/9〜14（融通可）</i>"
      , stPhone = Just "+81 954-69-0111"
      , stPriceEn = "¥74,700 stay<br>free to <b>5 Aug 23:59</b> local<br>(then cancel fee ¥10,800; no date changes)"
      , stPriceJa = "宿泊 ¥74,700<br><b>8/5 23:59</b> 現地まで無料<br>（以降キャンセル料 ¥10,800・日程変更不可）"
      }
  , Stay
      { stKey = "5"
      , stDatesEn = "15–22 Aug"
      , stDatesJa = "8/15〜22"
      , stNt = 8
      , stPropEn = "<b>Obi house B2</b><br>帯山1-24-24, Kumamoto · checkout <b>23 Aug</b> 08:00–11:00<br><i>in 15:00–18:00 · Smart Check-in (details week-of) · arrival ~15:00–16:00 approved · narrow car approach</i>"
      , stPropJa = "<b>Obi house B2</b><br>熊本市 帯山1-24-24 · チェックアウト <b>8/23</b> 08:00〜11:00<br><i>イン 15:00〜18:00 · スマートチェックイン（週中に詳細）· 到着 15:00〜16:00 承認済み · 車は細い道注意</i>"
      , stPhone = Just "+81 80-3981-4337"
      , stPriceEn = "¥36,720 stay (Genius −10%)<br>free to <b>13 Aug 23:59</b> local<br>(then <b>full</b> ¥36,720; no date changes)"
      , stPriceJa = "宿泊 ¥36,720（Genius −10%）<br><b>8/13 23:59</b> 現地まで無料<br>（以降は <b>全額</b> ¥36,720・日程変更不可）"
      }
  , Stay
      { stKey = "6"
      , stDatesEn = "23 Aug"
      , stDatesJa = "8/23"
      , stNt = 1
      , stPropEn = "<b>9h nine hours Hakata</b><br>3-22-2 Hakataekimae, Hakata-ku, Fukuoka (Hakata Stn)<br><i>Return Toyota car by 20:00 — Hakata Station Shop, 1-12-8 Hakataeki Higashi · 092-441-0100</i>"
      , stPropJa = "<b>9h ナインアワーズ博多</b><br>福岡市博多区博多駅前3-22-2（博多駅そば）<br><i>レンタカーは 20:00 までに返却 — トヨタ博多駅店 博多駅東1-12-8 · 092-441-0100</i>"
      , stPhone = Just "+81 50-1807-3481"
      , stPriceEn = "¥3,630 prepaid ✓"
      , stPriceJa = "¥3,630 前払い ✓"
      }
  , Stay
      { stKey = "7"
      , stDatesEn = "24–26 Aug"
      , stDatesJa = "8/24〜26"
      , stNt = 3
      , stPropEn = "<b>do-c Ebisu</b><br>1-8-1 Ebisu, Shibuya-ku, Tokyo<br><i>out 11:00 · in 15:00 · overnight bag store OK across a multi-night stay · <b>⚠ the 11:00–15:00 clean-out tightened (observed Jul 2026, unconfirmed): bags used to be fine parked anywhere outside a locker during the gap, now it reads as take-it-with-you. Working answer: collect the bag and use an Ebisu Stn coin locker for the gap (done 29 Jul)</b> · cash+ID on person (Patagonia Atom sling)</i>"
      , stPropJa = "<b>do-c 恵比寿</b><br>東京都渋谷区恵比寿1-8-1<br><i>アウト11:00 · イン15:00 · 連泊中の荷物保管は可 · <b>⚠ 11:00〜15:00の清掃時間の扱いが厳格化した様子（2026年7月・未確認）：以前はロッカー外に置いておけたが、現在は持ち出し案内に見える。対応：荷物を引き取り恵比寿駅コインロッカーへ（7/29実施）</b> · 現金・身分証は身につけ（Patagonia Atomスリング）</i>"
      , stPhone = Just "+81 50-1807-2324"
      , stPriceEn = "advance-pay<br><span class=\"tag-warn\">⚠</span> extend to 3 nt"
      , stPriceJa = "事前決済<br><span class=\"tag-warn\">⚠</span> 3泊に延長"
      }
  , Stay
      { stKey = "8"
      , stDatesEn = "27 Aug"
      , stDatesJa = "8/27"
      , stNt = 1
      , stPropEn = "<b>9h nine hours Narita</b><br>Narita T2 (landside)"
      , stPropJa = "<b>9h ナインアワーズ成田空港</b><br>成田 第2ターミナル（保安検査前）"
      , stPhone = Nothing
      , stPriceEn = "¥7,266<br>free to <b>26 Aug</b>"
      , stPriceJa = "¥7,266<br>8/26 まで無料キャンセル"
      }
  ]
