・COREPLOT利用の為のライブラリの登録
　　cocoapodsをインストールする

      http://tnakamura.hatenablog.com/entry/20120923/cocoapods
      
      http://qiita.com/makoto_kw/items/edf758a67bd4c2ba5b7a

　　CorePlot 1.4を導入する。
　　project directoryにPodfileを作成

-----------------------------
    platform :ios

    workspace 'toeic_BI.xcworkspace'
    xcodeproj 'toeic_BI.xcodeproj'

    pod 'CorePlot', '~> 1.4'
    pod 'OCMock'
    
-----------------------------
・pod install

・toeic_BI.xcworkspaceをxcodeで開いて使う

・frameworkの追加

　　QuartzCoreを追加する

・BUILDの設定

　　OtherLinkerFlagsに、-ObjCと-all_loadと${inherited}を追加

・SQlite3の利用

　　サーバ側・・・PHPからSQLite3を利用するためにPHP.iniを変更する。
　　　　　　　　　sqlite3のモジュールのコメントアウト、
            　　エクステンションディレクトリの設定

　　　　　　　　　/prototype_sd/sqlite.phpにスクリプト記述。

　　Xcode・・・FMDBを使うので、グループフォルダを作ってプロジェクトにコピー
　　　　　　　　Build,linker等の設定変更は不要。

・lPodsのリンカーエラーになったらlibPods.aをfindしてarmv7sまでのパスをLibrary SearchPathsに設定する

・CodesigningのReleaseにDistributionの証明書を設定

　　INSTITUTIONAL INTERNATIONAL BUSINESS COMYUNICATION,THE

・BundleIdentifierはInfo.Plistで同じ値に揃える。---> jp.or.toeic

・ArchiveはReleaseを指定する。

・IN-HOUSEアプリとして作成する。

・archiveファイルが出来たらオーガナイザーが開くのでアーカイブファイルを指定してDistributeボタンをおす

・ProvisioningProfileは、myAppDistを指定

・Enterpriseの配布にチェックを入れる

・ダウンロードURLは、http://xxx.xxx.xxx.xxx/appdist/toeic_BI.ipa
　タイトルを、TOEIC申込状況表示アプリとする

・配布

　　出来たアーカイブファイル(toeic_BI.ipaとtoeic_BI.plist)を配布サーバのドキュメントルートにコピーする。

　　http://xxx.xxx.xxx.xxx/dlApp.html



◆このアプリの目的

 下記を目的としたiPhone/iPadで使える「公開試験の申込状況表示ツール」を開発し関係者に活用頂く

・協会の情報システムが正常に機能している事の見える化  及び受験者に提供しているシステムサービス障害の早期検知を目的とする
 
  公開試験の申込受付システムは最重要システムであり、当該サービスの   安定的提供度合いを、情報システムの健康状態を示す
  バロメータとする。サービスの安定提供は、公開テストの日別申込人数の推移・傾向で示す。
　システム障害が発生すると前年に比べて極端な申込件数の減少になって現れる。
  運用部署が気付かない隠れた障害でも翌日には異常に気づく事が可能になる。

  その為には多くの人に毎日必ず見てもらう必要がある。 
  
・損益予想や申込人数の予想にも役立つ情報を表示し、役員や事業責任者の  方々に日常的に利用して頂く事で、異常監視役になってもらう。 いつでも・どこでも使える事が重要要件でありiPhone/iPadのアプリとする。  
    事業運営及び経営層に対するキラーアプリであり、同時にシステム正常性確認と異常早期検知に役立つものを目ざす。

◆試験管理情報

試験種別
試験実施回
試験実施年月日
目標人数
前年試験実施回
申込受付開始年月日
申込受付終了年月日


◆試験受付サマリー情報

試験種別
試験実施回
決済年月日
当日申込人数
累計申込人数

◆サーバ側

　http://xxx.xxx.xxx.xxx:8080/protype_sd/dl.php

　　　dl.php?name=nnnnnn

    nnnnnnは、試験種別+実施回(ex:LR188,SW20140303)、各データベースにコネクトして試験受付サマリー情報を取得する

　http://xxx.xxx.xxx.xxx:8080/protype_sd/dlconf.php

　　　dlconf.php?name=TOEIC_TEST

　　　試験管理情報を起動時に取得する

　   TOEIC_TEST.confファイルは、./data_dirに存在する。

　http://xxx.xxx.xxx.xxx:8080/protype_sd/sqlite.php

    データベースは、./data_dir/TOEIC.DB
    データベースの初期作成とTESTCONFテーブルのクリエイトは、dbgen.phpを
    sqlite.exeから実行する。

　　sqlite.php?cmd=INIを実行すると、TOEIC_TEST.confをTESTCONFにロードする
